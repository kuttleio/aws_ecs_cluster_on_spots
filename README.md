# aws_ecs_cluster_on_spots
Creates ECS-ECS2 cluster with only spot instances

## This module creates ONE ECS (EC2) cluster with spots. You can specify instance types ###############

## TODO:
1. Add dynamic instance types
2. Add dynamic volumes
3. Add Queue management with SQS
4. Make ASG scale based on a number of messages in the Q
5. Add notifications to Slack: SQS + SNS + Lambda
