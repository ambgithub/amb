#!/bin/bash

# 自动获取所有实例的名称
INSTANCES=$(aws lightsail get-instances --query "instances[*].name" --output text)

# 循环删除每个实例
for INSTANCE_NAME in $INSTANCES; do
  # 去除名称前后的空格
  INSTANCE_NAME=$(echo "$INSTANCE_NAME" | xargs)

  # 调试输出，确保实例名称正确
  echo "处理实例: $INSTANCE_NAME"

  # 跳过不想删除的实例
  if [ "$INSTANCE_NAME" = "amb" ] || [ "$INSTANCE_NAME" = "bbc" ]; then
    echo "跳过实例: $INSTANCE_NAME"
    continue
  fi

  # 删除实例
  aws lightsail delete-instance --instance-name "$INSTANCE_NAME"

  if [ $? -eq 0 ]; then
    echo "成功删除实例: $INSTANCE_NAME"
  else
    echo "删除实例 $INSTANCE_NAME 失败"
  fi
done
