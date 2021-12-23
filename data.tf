data "aws_region" "current" {}

data "aws_ami" "amazon_linux_ecs" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name   = "name"
        values = ["amzn-ami-*-amazon-ecs-optimized"]
    }
    filter {
        name   = "owner-alias"
        values = ["amazon"]
    }
}

# data "aws_efs_file_system" "by_id" {
#     file_system_id = var.efs_id[0]
# }
