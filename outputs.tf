output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "cluster_capacity_provider" {
  value = aws_ecs_capacity_provider.cluster_cp.name
}
