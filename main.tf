### This module creates ONE ECS (EC2) cluster with spots. You can specify instance types ###############

# -------------------------------------------------------------
#   TODO:
#   1. Add Queue management with SQS
#   2. Make ASG scale based on a number of messages in the Q
#   3. Add notifications to Slack: SQS + SNS + Lambda
# -------------------------------------------------------------

# -------------------------------------------------------------
#    ECS Cluster
# -------------------------------------------------------------
resource "aws_ecs_cluster" "cluster" {
  name               = var.cluster_name
  tags               = merge(var.standard_tags, tomap({ Name = var.cluster_name }))
  capacity_providers = [aws_ecs_capacity_provider.cluster_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.cluster_cp.name
  }

  lifecycle {
    create_before_destroy = true
  }

  # https://github.com/terraform-providers/terraform-provider-aws/issues/11409
  # We need to terminate all instances before the cluster can be destroyed.
  # (Terraform would handle this automatically if the autoscaling group depended
  # on the cluster, but we need to have the dependency in the reverse
  # direction due to the capacity_providers field above).
  provisioner "local-exec" {
    when    = destroy

    command = <<CMD
      # Get the list of capacity providers associated with this cluster
      CAP_PROVS="$(aws ecs describe-clusters --clusters "${self.arn}" \
        --query 'clusters[*].capacityProviders[*]' --output text"
      echo "${self.arn}: capacity: $CAP_PROVS"

      # Now get the list of autoscaling groups from those capacity providers
      for CAP_PROV in $CAP_PROVS
      do
        echo "${self.arn}: CAP_PROV: $CAP_PROV"
        ASG_ARNS="$(aws ecs describe-capacity-providers \
          --capacity-providers "$CAP_PROV" \
          --query 'capacityProviders[*].autoScalingGroupProvider.autoScalingGroupArn' \
          --output text"

        echo "${self.arn}: ASG_ARNS: $ASG_ARNS"

        if [ -n "$ASG_ARNS" ] && [ "$ASG_ARNS" != "None" ]
        then
          echo "${self.arn}: killing ASG: $ASG_ARNS"
          for ASG_ARN in $ASG_ARNS
          do
            ASG_NAME=$(echo $ASG_ARN | cut -d/ -f2-)
            echo "${self.arn}: killing ASG: name: $ASG_NAME"

            # Set the autoscaling group size to zero
            aws autoscaling update-auto-scaling-group \
              --auto-scaling-group-name "$ASG_NAME" \
              --min-size 0 --max-size 0 --desired-capacity 0"

            # Remove scale-in protection from all instances in the asg
            INSTANCES="$(aws autoscaling describe-auto-scaling-groups \
              --auto-scaling-group-names "$ASG_NAME" \
              --query 'AutoScalingGroups[*].Instances[*].InstanceId' \
              --output text"
            if [ -z "$INSTANCES" ]
            then
              echo "ASG: $ASG_NAME. No instances."
            else
              echo "ASG: $ASG_NAME. set-instance-protection"
              aws autoscaling set-instance-protection --instance-ids $INSTANCES \
              --auto-scaling-group-name "$ASG_NAME" \
              --no-protected-from-scale-in"
            fi
          done
        fi
      done
CMD
  }
}



# -------------------------------------------------------------
#    ASG: Auto Scaling Group
# -------------------------------------------------------------
resource "aws_autoscaling_group" "cluster_asg" {
  name                      = "${var.cluster_name}-ASG"
  max_size                  = var.cluster_max_size
  min_size                  = var.cluster_min_size
  desired_capacity          = var.cluster_desired_capacity
  protect_from_scale_in     = true
  vpc_zone_identifier       = var.ecs_subnet.*
  default_cooldown          = 300
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies      = ["DEFAULT"]
  service_linked_role_arn   = "arn:aws:iam::${var.account}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"

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
      on_demand_base_capacity  = 0
      spot_allocation_strategy = "lowest-price"
      spot_instance_pools      = 5
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cluster_lt.id
        version            = "$Latest"
      }
      ## TODO: Refactor
      override {
        instance_type = var.cluster_instance_type
      }
      override {
        instance_type = var.cluster_instance_type_2
      }
      override {
        instance_type = var.cluster_instance_type_3
      }
      override {
        instance_type = var.cluster_instance_type_4
      }
      override {
        instance_type = var.cluster_instance_type_5
      }
      override {
        instance_type = var.cluster_instance_type_6
      }
      override {
        instance_type = var.cluster_instance_type_7
      }
      override {
        instance_type = var.cluster_instance_type_8
      }
    }
  }
}



# -------------------------------------------------------------
#    Launch Template
# -------------------------------------------------------------
resource "aws_launch_template" "cluster_lt" {
  name                      = "${var.cluster_name}-launch-template"
  image_id                  = data.aws_ami.amazon_linux_ecs.id
  instance_type             = var.cluster_instance_type
  iam_instance_profile {
    arn                     = "arn:aws:iam::${var.account}:instance-profile/ecsInstanceRole"
  }
  key_name                  = var.key_name
  user_data                 = base64encode(templatefile("${path.module}/user-data.sh", { cluster_name = var.cluster_name }))

  ## TODO: Refactor
  block_device_mappings {
    device_name             = var.cluster_block_device_name_1
    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
      encrypted             = var.ebs_encrypted
      delete_on_termination = var.ebs_delete_on_termination
    }
  }

  block_device_mappings {
    device_name             = var.cluster_block_device_name_2
    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
      encrypted             = var.ebs_encrypted
      delete_on_termination = var.ebs_delete_on_termination
    }
  }

  block_device_mappings {
    device_name             = var.cluster_block_device_name_3
    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
      encrypted             = var.ebs_encrypted
      delete_on_termination = var.ebs_delete_on_termination
    }
  }

  block_device_mappings {
    device_name             = var.cluster_block_device_name_4
    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
      encrypted             = var.ebs_encrypted
      delete_on_termination = var.ebs_delete_on_termination
    }
  }

  network_interfaces {
    subnet_id       = var.ecs_subnet[0]
    security_groups = [var.cluster_sg]
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
