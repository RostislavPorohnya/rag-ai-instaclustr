variable "api_key" {
  type = string
  default = "6b4ff36da2547a5f91434ac5aec05c37"
}

variable "instaclustr_username" {
  type = string
  default = "rostyslp"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "default CIDR range of the VPC"
}
variable "aws_region" {
  default = "us-east-1"
  description = "aws region"
}

variable "fsxname" {
  default     = "bedrockfsxn"
  description = "default fsx name"
}

variable "collection_name" {
  default     = "fsxnragvector"
  description = "default collection name"
  
}

