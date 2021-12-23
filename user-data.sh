#!/bin/bash
sudo yum -y install mdadm
sudo mdadm --create --verbose /dev/md0 --level=0 --name=MY_RAID0 --raid-devices=3 /dev/sdc /dev/sdd /dev/sde
sudo mkfs.ext4 -L MY_RAID0 /dev/md0
sudo mkdir -p /datadir/tmp
sudo mount LABEL=MY_RAID0 /datadir

# ECS config
echo ECS_CLUSTER="${cluster_name}" >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config

start ecs

echo "Done"
