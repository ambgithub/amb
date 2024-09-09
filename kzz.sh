#!/bin/bash
sync
# 函数：检查进程中是否有指定文件在执行
check_process_running() {
    local file="$1"
    if pgrep -f "$file" > /dev/null; then
        echo "进程中有 $file 在执行，结束进程。"
        pkill -f "$file"
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
      if ! version=$(grep -oP '@ambver=\K[v\d+\.\d+]+(?=@)' "$file"); then
          version=""
          echo "未能提取到版本号，需要更新。"
          need_update=true
      else
          echo "提取到的版本号: $version"
      fi
      # 检查文件是否同时不包含指定字符串
      if ! grep -q "amb.api.code.start" "$file" || ! grep -q "amb.api.code.end" "$file"; then
          echo "文件 $file 同时不包含 'amb.api.code.start' 和 'amb.api.code.end'，需要更新。"
          need_update=true
          version=""
      fi

  fi

  # 构造请求URL
  local url="https://io.ues.cn/coin/index/checkupdate?ver=$version&file=$filename"
  echo "请求URL: $url"

  # 发送请求并获取响应
  local response=$(curl -s "$url")

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
      else
          echo "下载更新文件失败，保留旧文件。"
          rm -f "${file}.tmp"
      fi
  else
      echo "文件 $file 没有可用的更新。"
  fi
}
# 定义函数
check_file() {
    # 使用 curl 请求数据，并过滤和格式化返回结果
    result=$(curl -s https://io.ues.cn/coin/index/checkfile)

    # 假设返回结果是以 | 分隔的 PHP 文件名字符串
    if [[ -z "$result" ]]; then
        echo "请求返回为空"
        return 1
    else
        # 将返回结果转换成数组
        IFS='|' read -r -a files <<< "$result"
        echo "返回文件：${files[@]}"
        return 0
    fi
}
# 指定要检测和更新的目录
directory="/www/wwwroot/io.net"
# 调用函数
if check_file; then
  # 检测和更新目录下的指定文件
  echo "更新文件"
  for filename in "${files[@]}"; do
      file="$directory/$filename"
      check_and_update_file "$file"
  done
  sh $directory/start.sh
else
    echo "请求失败或返回为空"
fi
