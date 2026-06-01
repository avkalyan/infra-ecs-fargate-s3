# ECS Fargate Cluster with S3 Bucket

Fast-provisioning container infrastructure using AWS ECS Fargate and S3 bucket.

**⚡ Provisions in 3-5 minutes** - Perfect for demos and rapid development!

## What Gets Created

- **VPC**: Custom VPC with 2 public subnets across 2 availability zones
- **ECS Cluster**: Fargate-enabled cluster with Container Insights
- **Security Group**: Allow HTTP/HTTPS traffic to containers
- **IAM Roles**: Task execution and task roles with S3 access
- **S3 Bucket**: Encrypted bucket with versioning (accessible by ECS tasks)
- **Sample Task**: Nginx container ready to deploy
- **CloudWatch Logs**: Centralized logging for containers

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.9.0

## Quick Start

### 1. Initialize Terraform

```bash
cd infra-ecs-fargate-s3
terraform init
```

### 2. Review and Apply

```bash
terraform plan
terraform apply -auto-approve
```

**⏱️ Provisioning time: ~3-5 minutes**

### 3. Deploy Sample Nginx App

After infrastructure is created, deploy the sample nginx container:

```bash
# Get the deploy command from outputs
terraform output -raw deploy_nginx_command | bash
```

### 4. Verify Deployment

```bash
# List running tasks
aws ecs list-tasks --cluster kv-ecs-fargate-demo --region us-east-1

# Get task details and find public IP
TASK_ARN=$(aws ecs list-tasks --cluster kv-ecs-fargate-demo --region us-east-1 --query 'taskArns[0]' --output text)

aws ecs describe-tasks \
  --cluster kv-ecs-fargate-demo \
  --tasks $TASK_ARN \
  --region us-east-1 \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text | xargs -I {} aws ec2 describe-network-interfaces \
  --network-interface-ids {} \
  --region us-east-1 \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text

# Access the app (use the IP from above)
curl http://<PUBLIC_IP>
```

### 5. View Logs

```bash
# Tail CloudWatch logs
terraform output -raw view_logs_command | bash
```

## Customization

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
aws_region      = "us-east-1"
cluster_name    = "my-ecs-cluster"
s3_bucket_name  = "my-unique-bucket-name"
environment     = "production"
```

## Deploy Your Own Application

### Option 1: Run a Task Directly

```bash
aws ecs run-task \
  --cluster kv-ecs-fargate-demo \
  --launch-type FARGATE \
  --task-definition kv-ecs-fargate-demo-nginx \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --region us-east-1
```

### Option 2: Create a Service (Auto-scaling)

```bash
aws ecs create-service \
  --cluster kv-ecs-fargate-demo \
  --service-name my-service \
  --task-definition kv-ecs-fargate-demo-nginx \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --region us-east-1
```

### Option 3: Deploy Custom Container

Create a new task definition:

```bash
cat > custom-task.json <<EOF
{
  "family": "my-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "$(terraform output -raw task_execution_role_arn)",
  "taskRoleArn": "$(terraform output -raw task_role_arn)",
  "containerDefinitions": [
    {
      "name": "my-app",
      "image": "your-docker-image:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "$(terraform output -raw cloudwatch_log_group)",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "my-app"
        }
      }
    }
  ]
}
EOF

# Register the task definition
aws ecs register-task-definition --cli-input-json file://custom-task.json

# Run it
aws ecs run-task \
  --cluster kv-ecs-fargate-demo \
  --launch-type FARGATE \
  --task-definition my-app \
  --network-configuration "awsvpcConfiguration={subnets=[$(terraform output -json public_subnet_ids | jq -r 'join(","))],securityGroups=[$(terraform output -raw security_group_id)],assignPublicIp=ENABLED}" \
  --region us-east-1
```

## Accessing S3 from Containers

Your containers automatically have access to the S3 bucket via IAM role. The bucket name is available as an environment variable:

```bash
# Inside container
echo $S3_BUCKET

# Upload file
aws s3 cp myfile.txt s3://$S3_BUCKET/

# Download file
aws s3 cp s3://$S3_BUCKET/myfile.txt .
```

## Useful Commands

```bash
# List all tasks
aws ecs list-tasks --cluster kv-ecs-fargate-demo --region us-east-1

# Stop a task
aws ecs stop-task --cluster kv-ecs-fargate-demo --task <task-arn> --region us-east-1

# View task details
aws ecs describe-tasks --cluster kv-ecs-fargate-demo --tasks <task-arn> --region us-east-1

# List services
aws ecs list-services --cluster kv-ecs-fargate-demo --region us-east-1

# View CloudWatch logs
aws logs tail /ecs/kv-ecs-fargate-demo --follow --region us-east-1

# List files in S3
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/
```

## Cost Considerations

- **ECS Fargate**: ~$0.04/vCPU/hour + ~$0.004/GB/hour
  - 0.25 vCPU, 0.5 GB = ~$0.012/hour = ~$9/month per task
- **VPC**: ~$0.045/hour for NAT Gateway (not used in this config)
- **S3 Bucket**: Pay for storage and requests (typically < $1/month for demos)
- **Data Transfer**: First 100 GB/month free

**Estimated cost: ~$10-15/month if running 1 task continuously**

For demos: Destroy after use to avoid charges!

## Cleanup

```bash
# Stop all running tasks first
aws ecs list-tasks --cluster kv-ecs-fargate-demo --region us-east-1 | \
  jq -r '.taskArns[]' | \
  xargs -I {} aws ecs stop-task --cluster kv-ecs-fargate-demo --task {} --region us-east-1

# Destroy infrastructure
terraform destroy -auto-approve
```

**⏱️ Destroy time: ~2-3 minutes**

## Comparison with EKS

| Feature | ECS Fargate | EKS |
|---------|-------------|-----|
| Provision Time | 3-5 min ✅ | 18-23 min ❌ |
| Destroy Time | 2-3 min ✅ | 15-20 min ❌ |
| Complexity | Low ✅ | High ❌ |
| Cost | ~$10-15/month | ~$130/month |
| Kubernetes API | ❌ No | ✅ Yes |
| Best For | Containers, demos | K8s workloads |

## Demo Script

Perfect for customer demos:

```bash
# 1. Provision (3-5 min before demo)
terraform apply -auto-approve

# 2. During demo - deploy app (30 seconds)
terraform output -raw deploy_nginx_command | bash

# 3. Show resources (instant)
terraform output
aws ecs list-tasks --cluster kv-ecs-fargate-demo --region us-east-1
aws s3 ls | grep kv-ecs-fargate

# 4. After demo - cleanup (2-3 min)
terraform destroy -auto-approve
```

**Total demo time: < 1 minute (after initial provision)**

## Security Features

- Private VPC with public subnets for Fargate tasks
- S3 bucket encryption enabled
- S3 versioning enabled
- Public access blocking for S3 bucket
- IAM roles with least-privilege access
- Container logs sent to CloudWatch
- Security groups restrict inbound to HTTP/HTTPS only
