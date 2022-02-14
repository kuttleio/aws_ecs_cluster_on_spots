# -------------------------------------------------------------
#    ECS Cluster
# -------------------------------------------------------------
resource "aws_ecs_cluster" "cluster" {
  name               = var.cluster_name
  tags               = merge(var.standard_tags, tomap({ Name = var.cluster_name }))
  capacity_providers = [aws_ecs_capacity_provider.cluster_cp.name]

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.cluster_cp.name
  }

  lifecycle {
    create_before_destroy = true
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.cluster_log_group.name
      }
    }
  }
}


# -------------------------------------------------------------
#    ASG: Auto Scaling Group
# -------------------------------------------------------------
resource "aws_autoscaling_group" "cluster_asg" {
  name                      = "${var.cluster_name}-ASG"
  min_size                  = var.cluster_min_size
  desired_capacity          = var.cluster_desired_capacity
  max_size                  = var.cluster_max_size  
  protect_from_scale_in     = true
  vpc_zone_identifier       = var.ecs_subnet.*
  default_cooldown          = 300
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies      = ["DEFAULT"]
  # service_linked_role_arn   = aws_iam_role.ecs_service_role.arn

  tag {
    key                 = "AmazonECSManaged"
    value               = "Yes"
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cluster_lt.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type       = override.key
          weighted_capacity   = override.value
        }
      }
    }
  }
}


# -------------------------------------------------------------
#    Launch Template
# -------------------------------------------------------------
resource "aws_launch_template" "cluster_lt" {
  name                      = "${var.cluster_name}-LT"
  image_id                  = data.aws_ami.amazon_linux_ecs.id
  instance_type             = "t3a.small"
  key_name                  = var.key_name
  user_data                 = base64encode(templatefile("${path.module}/user-data.sh", { cluster_name = var.cluster_name }))
  
  iam_instance_profile {
    name                    = aws_iam_instance_profile.ecs_node.name
  }

  dynamic "block_device_mappings" {
    for_each = var.ebs_disks
    content {
      device_name = block_device_mappings.key
      ebs {
        volume_size           = block_device_mappings.value
        volume_type           = var.ebs_volume_type
        encrypted             = var.ebs_encrypted
        delete_on_termination = var.ebs_delete_on_termination
      }
    }
  }  

  network_interfaces {
    subnet_id       = var.ecs_subnet[0]
    security_groups = var.cluster_sg
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.standard_tags, tomap({ Name = var.cluster_name }))
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.standard_tags, tomap({ Name = var.cluster_name }))
  }
}


# -------------------------------------------------------------
#    Capacity Providers
# -------------------------------------------------------------
resource "aws_ecs_capacity_provider" "cluster_cp" {
  name = var.cluster_name
  
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.cluster_asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size    = 1000
      minimum_scaling_step_size    = 1
      status                       = "ENABLED"
      target_capacity              = 100
    }
  }
}


# -------------------------------------------------------------
#    CloudWatch Log Group
# -------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cluster_log_group" {
    name = "/ecs/${var.cluster_name}"
    tags = var.standard_tags
}
