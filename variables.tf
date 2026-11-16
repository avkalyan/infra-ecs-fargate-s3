variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "kv-ecs-fargate-demo"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-0bb2874364a88e59c"
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
  default     = ["subnet-0a29a48072b5aa7b1", "subnet-0f6c4a79f5eaacf24"]
}

variable "security_group_id" {
  description = "Security Group ID for ECS tasks"
  type        = string
  default     = "sg-0df0234a9267c8981"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  default     = "kv-ecs-fargate-s3-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "demo"
    Project     = "infra-ecs-fargate-s3"
  }
}
