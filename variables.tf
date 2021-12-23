# variable "efs_id" {}
variable "account" {}
variable "key_name" {}
variable "aws_region" {}
variable "ecs_subnet" {}
variable "cluster_sg" {}
variable "name_prefix" {}
variable "cluster_name" {}
variable "standard_tags" {}

variable "ebs_delete_on_termination" {
  default = true
}
variable "ebs_volume_size" {
  default = 200
}
variable "ebs_volume_type" {
  default = "gp2"
}
variable "ebs_encrypted" {
  default = true
}

variable "cluster_block_device_name_1" {
  default = "/dev/sde"
}
variable "cluster_block_device_name_2" {
  default = "/dev/sdd"
}
variable "cluster_block_device_name_3" {
  default = "/dev/sdc"
}
variable "cluster_block_device_name_4" {
  default = "/dev/xvda"
}

variable "cluster_min_size" {
  default = 0
}
variable "cluster_max_size" {
  default = 10
}
variable "cluster_desired_capacity" {
  default = 0
}
