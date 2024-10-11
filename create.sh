#!/bin/bash

# 定义快照名称、区域、实例规格和实例名称前缀
SNAPSHOT_NAME="amb20241011"
AVAILABILITY_ZONE="ap-southeast-1"  # 可用区 ap-southeast-1 的第一个可用区
BUNDLE_ID="nano_1_0"  # 实例类型，可根据需要选择 nano_2_0, micro_2_0 等
INSTANCE_PREFIX="gradient"  # 实例名称前缀

# 创建实例的数量
INSTANCE_COUNT=5

# 循环创建多个实例
for i in $(seq 1 $INSTANCE_COUNT); do
  INSTANCE_NAME="${INSTANCE_PREFIX}_${i}"
  
  # 调用 AWS CLI 创建实例
  aws lightsail create-instances-from-snapshot \
    --instance-snapshot-name "$SNAPSHOT_NAME" \
    --availability-zone "$AVAILABILITY_ZONE" \
    --bundle-id "$BUNDLE_ID" \
    --instance-names "$INSTANCE_NAME"

  echo "创建实例: $INSTANCE_NAME"
done
