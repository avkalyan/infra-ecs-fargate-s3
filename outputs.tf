output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = var.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for deploying tasks"
  value       = var.subnet_ids
}

output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "ECS task role ARN (for application)"
  value       = aws_iam_role.ecs_task_role.arn
}

output "nginx_task_definition_arn" {
  description = "Nginx task definition ARN"
  value       = aws_ecs_task_definition.nginx.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "deploy_nginx_command" {
  description = "Command to deploy nginx sample app"
  value = <<-EOT
    aws ecs run-task \
      --cluster ${aws_ecs_cluster.main.name} \
      --launch-type FARGATE \
      --task-definition ${aws_ecs_task_definition.nginx.family} \
      --network-configuration "awsvpcConfiguration={subnets=[${join(",", var.subnet_ids)}],securityGroups=[${aws_security_group.ecs_tasks.id}],assignPublicIp=ENABLED}" \
      --region ${var.aws_region}
  EOT
}

output "list_tasks_command" {
  description = "Command to list running tasks"
  value       = "aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name} --region ${var.aws_region}"
}

output "view_logs_command" {
  description = "Command to view CloudWatch logs"
  value       = "aws logs tail ${aws_cloudwatch_log_group.ecs.name} --follow --region ${var.aws_region}"
}
