resource "aws_cloudwatch_log_group" "cluster_log_group" {
    name = "/ecs/${var.cluster_name}"
    tags = var.standard_tags
}
