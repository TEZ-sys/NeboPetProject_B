terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

# Address, token and certificate settings come from the environment:
# VAULT_ADDR, VAULT_TOKEN and VAULT_CACERT (or VAULT_SKIP_VERIFY for a lab).
provider "vault" {
  skip_child_token = true # the read-only policy cannot create child tokens
}

locals {
  redis_name = "${var.resource_owner["name"]}-redis"
}

# Redis password. Create it with:
#   vault kv put secret/pet_2/redis password="$(openssl rand -hex 16)"
data "vault_kv_secret_v2" "tf_pet_project2" {
  mount = "secret"
  name  = "pet_2/redis"
}

module "nosql" {
  source         = "./modules/nosql"
  resource_owner = var.resource_owner
}

module "iam" {
  source = "./modules/iam"

  dynamo_metric_arn = module.nosql.dynamo_metric_arn
  dynamo_table_name = module.nosql.dynamo_table_name
  resource_owner    = var.resource_owner
}

module "lambda" {
  source = "./modules/lambda"

  role_arn       = module.iam.collector_role_arn
  role_name      = module.iam.collector_role_name
  table_name     = module.nosql.dynamo_table_name
  targets        = var.monitor_targets
  lambda_runtime = var.lambda_runtime
  resource_owner = var.resource_owner
}

module "network" {
  source              = "./modules/network"
  vpc_cidr            = var.vpc_cidr
  aws_region          = var.aws_region
  instance_tenancy    = var.instance_tenancy
  create_vpc_endpoint = var.create_vpc_endpoint
  resource_owner      = var.resource_owner

  create_public_subnet = var.create_test_client
}

module "cloudwatch" {
  source             = "./modules/cloudwatch"
  name               = local.redis_name
  num_cache_clusters = var.num_cache_clusters
  log_retention_days = var.log_retention_days
  resource_owner     = var.resource_owner
}

module "elastic_cache" {
  source                     = "./modules/elastic_cache"
  name                       = local.redis_name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.subnet_ids
  allowed_security_group_ids = concat(var.redis_allowed_security_group_ids, module.redis_client[*].security_group_id)
  num_cache_clusters         = var.num_cache_clusters
  node_type                  = var.node_type
  engine_version             = var.engine_version
  redis_port                 = var.redis_port
  snapshot_retention_days    = var.snapshot_retention_days
  auth_token                 = data.vault_kv_secret_v2.tf_pet_project2.data["password"]
  slow_log_group_name        = module.cloudwatch.slow_log_group_name
  engine_log_group_name      = module.cloudwatch.engine_log_group_name
  resource_owner             = var.resource_owner
}

# Temporary test host for the Redis evidence. Set create_test_client = true to
# build it and false (or destroy) when you are done.
module "redis_client" {
  count  = var.create_test_client ? 1 : 0
  source = "./modules/redis_client"

  name           = local.redis_name
  vpc_id         = module.network.vpc_id
  subnet_id      = module.network.public_subnet_ids[0]
  redis_host     = module.elastic_cache.primary_endpoint_address
  redis_port     = var.redis_port
  instance_type  = var.test_client_instance_type
  resource_owner = var.resource_owner
}
