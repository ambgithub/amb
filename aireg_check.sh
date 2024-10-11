#!/bin/bash
#amb.api.code.start
VERSION="@ambver=v6.1@"
kill_app() {
    local app_path="$1"

    pkill -f "^$app_path[[:space:]]*$"
    local pid=$(pgrep -f "^$app_path[[:space:]]*$")

    if [[ ! -z "$pid" ]]; then
        echo "尝试优雅地终止 $app_path 进程, PID: $pid"
        kill "$pid"

        sleep 3

        pid=$(pgrep -f "^$app_path[[:space:]]*$")
        if [[ ! -z "$pid" ]]; then
            echo "进程未终止，强制终止 $app_path 进程, PID: $pid"
            kill -9 "$pid"
            sleep 3

            pid=$(pgrep -f "^$app_path[[:space:]]*$")
            if [[ ! -z "$pid" ]]; then
                echo "$app_path 进程仍未能终止"
                return 1
            fi
        fi
        echo "$app_path 进程已终止"
        return 0
    else
        echo "没有找到 $app_path 进程"
        return 0
    fi
}

main() {
    local app_path="$1"
    local app_param="$2"

    kill_app "$app_path"
    if [[ $? -ne 0 ]]; then
        echo "无法终止 $app_path $app_param，退出。"
        exit 1
    fi
}

main "/root/aireg" "--socket"
echo "脚本执行完成。"
exit 0
#amb.api.code.end
