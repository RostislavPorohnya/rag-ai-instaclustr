
terraform {
  required_version = ">= 0.12"
  required_providers {
    instaclustr = {
      source  = "instaclustr/instaclustr"
      version = ">= 2.0.0, < 3.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.49.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    opensearch = {
      source = "opensearch-project/opensearch"
      version = "2.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
}
}