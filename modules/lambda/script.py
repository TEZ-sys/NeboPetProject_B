"""Scheduled metrics collector Lambda.

Triggered by an EventBridge schedule. For every configured target it measures
availability and latency, stores one item per target per time bucket in
DynamoDB, and emits CloudWatch custom metrics through the Embedded Metric
Format (EMF), which needs no cloudwatch:PutMetricData permission.

Environment variables
    TABLE_NAME         DynamoDB table (partition key "host", sort key "ts")  [required]
    TARGETS            JSON list, e.g. [{"name": "api", "url": "https://example.com/health"}]
    INTERVAL_SECONDS   Schedule interval, used to build the time bucket (default 300)
    TTL_DAYS           Days before DynamoDB expires an item (default 30)
    REQUEST_TIMEOUT    Per-target HTTP timeout in seconds (default 3)
    METRIC_NAMESPACE   CloudWatch namespace (default "MetricsCollector")
    LOG_LEVEL          Python log level (default INFO)
"""

import json
import logging
import os
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

TABLE_NAME = os.environ["TABLE_NAME"]
INTERVAL_SECONDS = int(os.environ.get("INTERVAL_SECONDS", "300"))
TTL_DAYS = int(os.environ.get("TTL_DAYS", "30"))
REQUEST_TIMEOUT = float(os.environ.get("REQUEST_TIMEOUT", "3"))
METRIC_NAMESPACE = os.environ.get("METRIC_NAMESPACE", "MetricsCollector")

# Created once per container, reused across warm invocations.
_table = boto3.resource(
    "dynamodb",
    config=Config(retries={"max_attempts": 3, "mode": "standard"}),
).Table(TABLE_NAME)


def _load_targets():
    try:
        targets = json.loads(os.environ.get("TARGETS", "[]"))
    except json.JSONDecodeError:
        logger.error("TARGETS is not valid JSON")
        return []
    valid = []
    for t in targets:
        if t.get("name") and str(t.get("url", "")).startswith(("http://", "https://")):
            valid.append(t)
        else:
            logger.warning("Skipping invalid target: %s", json.dumps(t))
    return valid


def _time_bucket(event):
    """Floor the event time to the interval so retries write the same key."""
    raw = (event or {}).get("time")
    if raw:
        now = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    else:
        now = datetime.now(timezone.utc)
    epoch = int(now.timestamp())
    return datetime.fromtimestamp(epoch - epoch % INTERVAL_SECONDS, tz=timezone.utc)


def check_target(target):
    """Return availability and latency for one target. Never raises."""
    started = time.perf_counter()
    status_code = 0
    error = None
    try:
        req = urllib.request.Request(target["url"], method="GET")
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:  # nosec B310
            status_code = resp.status
    except urllib.error.HTTPError as exc:
        status_code = exc.code
        error = f"HTTP {exc.code}"
    except Exception as exc:  # timeouts, DNS errors, connection refused
        error = type(exc).__name__
    latency_ms = round((time.perf_counter() - started) * 1000, 2)
    up = 1 if 200 <= status_code < 400 else 0
    return {
        "name": target["name"],
        "status_code": status_code,
        "latency_ms": latency_ms,
        "up": up,
        "error": error,
    }


def _emit_metric(dimensions, metrics, values, extra=None):
    """Write one EMF record to stdout; CloudWatch turns it into metrics."""
    record = {
        "_aws": {
            "Timestamp": int(time.time() * 1000),
            "CloudWatchMetrics": [
                {
                    "Namespace": METRIC_NAMESPACE,
                    "Dimensions": [list(dimensions.keys())],
                    "Metrics": metrics,
                }
            ],
        },
        **dimensions,
        **values,
        **(extra or {}),
    }
    print(json.dumps(record))


def handler(event, context):
    started = time.perf_counter()
    targets = _load_targets()
    if not targets:
        logger.warning("No valid targets configured, nothing to do")
        return {"checked": 0, "down": 0}

    bucket = _time_bucket(event)
    ts = bucket.isoformat()
    expires_at = int(bucket.timestamp()) + TTL_DAYS * 86400

    results = [check_target(t) for t in targets]

    # Same (host, ts) key on every retry makes the write idempotent.
    # Failures here are raised on purpose so Lambda retries and then
    # routes the event to the dead-letter queue.
    with _table.batch_writer(overwrite_by_pkeys=["host", "ts"]) as batch:
        for r in results:
            batch.put_item(
                Item={
                    "host": r["name"],
                    "ts": ts,
                    "up": r["up"],
                    "status_code": r["status_code"],
                    "latency_ms": Decimal(str(r["latency_ms"])),
                    "expires_at": expires_at,
                }
            )

    for r in results:
        _emit_metric(
            {"Target": r["name"]},
            [
                {"Name": "LatencyMs", "Unit": "Milliseconds"},
                {"Name": "Up", "Unit": "Count"},
            ],
            {"LatencyMs": r["latency_ms"], "Up": r["up"]},
        )
        logger.info(
            json.dumps(
                {
                    "msg": "target_checked",
                    "target": r["name"],
                    "up": r["up"],
                    "status_code": r["status_code"],
                    "latency_ms": r["latency_ms"],
                    "error": r["error"],
                    "request_id": getattr(context, "aws_request_id", None),
                }
            )
        )

    down = sum(1 for r in results if not r["up"])
    duration_ms = round((time.perf_counter() - started) * 1000, 2)
    _emit_metric(
        {"Service": "collector"},
        [
            {"Name": "TargetsChecked", "Unit": "Count"},
            {"Name": "TargetsDown", "Unit": "Count"},
            {"Name": "RunDurationMs", "Unit": "Milliseconds"},
        ],
        {"TargetsChecked": len(results), "TargetsDown": down, "RunDurationMs": duration_ms},
    )
    return {"checked": len(results), "down": down, "bucket": ts}