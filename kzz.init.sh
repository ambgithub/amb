#!/bin/bash
sync
# API URL
API_URL="https://io.ues.cn/host/api/getcrontab"
# 固定保留的任务
FIXED_CRONTAB="*/3 * * * * /root/kzz.init.sh"

# 函数：检查进程中是否有指定文件在执行
check_process_running() {
    local file="$1"
    if pgrep -f "$file" > /dev/null; then
        echo "进程中有 $file 在执行，结束进程。"
        pkill -f "$file"
    fi
}

# 处理 crontab 的函数
update_crontab() {
    local time="$1"
    local shell_script="$2"
    local check_url="$3"
    local version=""

    echo "时间: $time, 脚本: $shell_script, 检查 URL: $check_url"

    # 检查文件是否存在
    if [ ! -f "$shell_script" ]; then
        echo "文件 $shell_script 不存在，需要更新。"
    else
        version=$(grep -o '@ambver=[v0-9\.]*@' "$shell_script" | cut -d '=' -f2 | cut -d '@' -f1)
        if [ -z "$version" ]; then
            echo "未能提取到版本号，需要更新。"
        else
            echo "提取到的版本号: $version"
        fi

        if ! grep -q "amb.api.code.start" "$shell_script" || ! grep -q "amb.api.code.end" "$shell_script"; then
            echo "文件 $shell_script 不包含 'amb.api.code.start' 和 'amb.api.code.end'，需要更新。"
            version=""
        fi
    fi

    local url="https://io.ues.cn/host/api/checkshell?ver=$version&file=$shell_script"
    echo "请求URL: $url"

    local response=$(curl -fsSL "$url")

    if [[ "$response" == update\|* ]]; then
        check_process_running "$shell_script"
        local update_url=${response#update|}

        if curl -o "${shell_script}.tmp" "$update_url"; then
            mv "${shell_script}.tmp" "$shell_script"
            echo "文件 $shell_script 已更新。"
            chmod 755 "$shell_script"
            echo "文件 $shell_script 权限已设置为 755。"
        else
            echo "下载更新文件失败，保留旧文件。"
            rm -f "${shell_script}.tmp"
        fi
    else
        echo "文件 $shell_script 没有可用的更新。"
    fi

    (crontab -l 2>/dev/null | grep -v "$shell_script" | grep -v "$FIXED_CRONTAB"; echo "$time $shell_script"; echo "$FIXED_CRONTAB") | sort -u | crontab -
    echo "crontab 已更新: $time $shell_script"
}

# 删除特定的 crontab 任务
delete_crontab() {
    local shell_script="$1"

    (crontab -l 2>/dev/null | grep -v "$shell_script" | grep -v "$FIXED_CRONTAB"; echo "$FIXED_CRONTAB") | sort -u | crontab -
    echo "crontab 任务已删除: $shell_script"
}

# 删除所有 crontab，除了固定任务
delete_all_crontab() {
    (echo "$FIXED_CRONTAB") | crontab -
    echo "所有 crontab 任务已删除，保留固定任务。"
}

# 获取API响应
response=$(curl -fsSL "$API_URL")
echo "API 响应: $response"  # 添加调试信息
status=$(echo "$response" | jq -r '.status')
tasks=$(echo "$response" | jq -r '.task')

# 判断返回状态
if [ "$status" == "ok" ]; then
    echo "任务列表: $tasks"  # 添加调试信息
    if [ "$tasks" == "[]" ]; then
        delete_all_crontab
    else
        echo "$response" | jq -c '.task[]' | while read -r task; do
            version=$(echo "$task" | jq -r '.version')
            crontab_time=$(echo "$task" | jq -r '.crontab_time')
            crontab_shell=$(echo "$task" | jq -r '.crontab_shell')
            check_url=$(echo "$task" | jq -r '.check_url')
            open=$(echo "$task" | jq -r '.open')

            echo "处理任务: version=$version, crontab_time=$crontab_time, crontab_shell=$crontab_shell, open=$open"  # 调试信息

            if [ "$open" == "yes" ]; then
                update_crontab "$crontab_time" "$crontab_shell" "$check_url"
            else
                delete_crontab "$crontab_shell"
            fi
        done
    fi
else
    echo "错误：API 返回状态 '$status'。程序退出。"
    exit 1
fi
