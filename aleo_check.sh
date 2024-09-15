#!/bin/bash
#amb.api.code.start
VERSION="@ambver=v2.9.4@"
sync
# 函数：检查进程中是否有指定文件在执行
check_process_running() {
    local file="$1"
    if pgrep -f "$file" > /dev/null; then
        echo "进程中有 $file 在执行，结束进程。"
        pkill -f "$file"
        pkill -9 aleo_prover
    fi
}

# 函数：检测和更新文件
check_and_update_file() {
  local file="$1"
  local version=""
  local filename=$(basename "$file")
  local need_update=false

  # 检查文件是否存在
  if [ ! -f "$file" ]; then
      echo "文件 $file 不存在，需要更新。"
      need_update=true
  else
      # 调试信息：显示文件内容

      # 尝试提取版本号
      if ! version=$(grep -oP '@ambver=\K[v\d+\.\d+\.\d+]+(?=@)' "$file"); then
          version=""
          echo "未能提取到版本号，需要更新。"
          need_update=true
      else
          echo "提取到的版本号: $version"
      fi
      # 检查文件是否同时不包含指定字符串
      if ! grep -q "amb.code.start" "$file" || ! grep -q "amb.code.end" "$file"; then
          echo "文件 $file 同时不包含 'amb.code.start' 和 'amb.code.end'，需要更新。"
          need_update=true
          version=""
      fi
  fi

  # 构造请求URL
  local INSTANCE_ID=$(cat /var/lib/cloud/data/instance-id)
  local url="https://io.ues.cn/coin/index/updatealeo?ver=$version&file=$filename&instance_id=$INSTANCE_ID"

  echo "请求URL: $url"
  # 发送请求并获取响应
  local response=$(curl -s "$url")
  echo $response;
  # 检查响应是否以 update| 开头
  if [[ "$response" == update\|* ]]; then
      # 检查进程中是否有文件在执行
      check_process_running "$file"
      # 提取更新文件的URL
      local update_url=${response#update|}
      # 下载更新文件，并添加错误处理
      if curl -o "${file}.tmp" "$update_url"; then
          mv "${file}.tmp" "$file"
          echo "文件 $file 已更新。"
          # 设置文件权限为 777
          sudo chmod 777 "$file"
          echo "文件 $file 权限已设置为 777。"
          echo "aleo_prover 进程不存在，尝试启动..."
          # 这里替换成aleo-miner的启动命令

          pkill -9 aleo_prover
          bash /root/startaleo.sh
      else
          echo "下载更新文件失败，保留旧文件。"
          rm -f "${file}.tmp"
      fi
  else
      echo "文件 $file 没有可用的更新。"
      # 定义要检查的进程名和文件路径
      process_name="aleo_prover"
      file_path="/root/startaleo.sh"
      # 检查进程是否不存在
      if ! pgrep -f "$process_name" > /dev/null; then
          echo "进程 $process_name 不存在。"

          # 检查文件是否存在
          if [ -f "$file_path" ]; then
              echo "文件 $file_path 存在。"
              pkill -9 aleo-miner
              bash /root/startaleo.sh

          else
              echo "文件 $file_path 不存在。"
          fi
      else
          echo "进程 $process_name 存在。"
      fi
  fi
}
# 指定要检测和更新的目录
directory="/root"
# 定义要检测和更新的文件列表
filename="startaleo.sh"
file="$directory/$filename"
check_and_update_file "$file"
#amb.api.code.end
