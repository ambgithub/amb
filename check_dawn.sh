#!/bin/bash
#amb.api.code.start
VERSION="@ambver=v3.7@"
VERSION_API="https://io.ues.cn/host/api/checkshell?type=run_app&ver="
DOWNLOAD_URL="https://raw.githubusercontent.com/ambgithub/amb/main/dawn"

check_app_exists() {
    if [[ ! -f "$1" ]]; then
        echo "$1 程序不存在，开始下载..."
        curl -L -o $1 $DOWNLOAD_URL
        chmod +x $1
        echo "$1 程序已下载并赋予可执行权限。"
    fi
}

check_update() {
    local app_path="$1"

    check_app_exists "$app_path"
    local current_version=$($app_path --version)
    local version_response=$(curl -s "${VERSION_API}${current_version}&file=${app_path}")

    if [[ $version_response == update* ]]; then
        local new_url=$(echo $version_response | cut -d'|' -f2)
        echo "有新版本，准备更新，下载地址为：$new_url"
        DOWNLOAD_URL="$new_url"
        return 1
    elif [[ $version_response == "ok" ]]; then
        echo "已是最新版本。"
        return 0
    else
        echo "检测版本失败，响应内容: $version_response"
        exit 1
    fi
}

# 更新二进制文件
update_app() {
    local app_path="$1"
    echo "正在下载新版本..."

    curl -f -L -o $app_path $DOWNLOAD_URL

    if [[ $? -ne 0 ]]; then
        echo "下载新版本失败。"
        exit 1
    fi

    if [[ ! -s "$app_path" ]]; then
        echo "下载的新版本文件无效。"
        exit 1
    fi

    chmod +x $app_path
    echo "更新完成并赋予可执行权限。"
}

kill_app() {
    local app_path="$1"

    pkill -f "$app_path"
    local pid=$(pgrep -f "$app_path")

    if [[ ! -z "$pid" ]]; then
        echo "尝试优雅地终止 $app_path 进程, PID: $pid"
        kill "$pid"

        sleep 3

        pid=$(pgrep -f "$app_path")
        if [[ ! -z "$pid" ]]; then
            echo "进程未终止，强制终止 $app_path 进程, PID: $pid"
            kill -9 "$pid"
            sleep 3

            pid=$(pgrep -f "$app_path")
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

run_app() {
    local app_path="$1"
    local app_param="$2"

    check_app_exists "$app_path"
    local pid=$(pgrep -f "$app_path $app_param")

    if [[ -z "$app_param" ]]; then
        pid=$(pgrep -f "$app_path")
    fi

    if [[ ! -z "$pid" ]]; then
        echo "$app_path $app_param 进程已经在运行 (PID: $pid)，无需重复启动。"
        return 0
    fi

    echo "启动 $app_path $app_param 进程..."
    if [[ -z "$app_param" ]]; then
        nohup $app_path > /dev/null 2>&1 &
    else
        nohup $app_path $app_param > /dev/null 2>&1 &
    fi

    sleep 1
    if [[ -z "$app_param" ]]; then
        pid=$(pgrep -f "$app_path")
    else
        pid=$(pgrep -f "$app_path $app_param")
    fi

    if [[ -z "$pid" ]]; then
        echo "启动 $app_path $app_param 失败。"
        return 1
    else
        echo "$app_path $app_param 已成功启动 (PID: $pid)。"
        return 0
    fi
}

check_app_running() {
    local app_path="$1"
    local app_param="$2"
    local pid=$(pgrep -f "$app_path $app_param")

    if [[ -z "$app_param" ]]; then
        pid=$(pgrep -f "$app_path")
    fi

    if [[ ! -z "$pid" ]]; then
        echo "$app_path $app_param 已在运行，PID: $pid"
        return 1
    else
        echo "$app_path $app_param 未在运行，准备启动..."
        return 0
    fi
}

check_app_runtime() {
    local app_path="$1"
    local app_param="$2"
    local pid=$(pgrep -f "$app_path $app_param")

    if [[ -z "$app_param" ]]; then
        pid=$(pgrep -f "$app_path")
    fi

    if [[ ! -z "$pid" ]]; then
        local runtime=$(ps -o etime= -p "$pid" | tr -d ' ')
        local days=0
        local hours=0
        local minutes=0
        local seconds=0

        if [[ $runtime == *-* ]]; then
            days=$(echo $runtime | cut -d'-' -f1 | tr -d ' ')
            runtime=$(echo $runtime | cut -d'-' -f2 | tr -d ' ')
        fi

        if [[ $runtime == *:*:* ]]; then
            IFS=: read -r hours minutes seconds <<< "$runtime"
        else
            IFS=: read -r minutes seconds <<< "$runtime"
        fi

        days=$((10#$days))
        hours=$((10#$hours))
        minutes=$((10#$minutes))
        seconds=$((10#$seconds))

        total_seconds=$(( 86400 * days + 3600 * hours + 60 * minutes + seconds ))

        if (( total_seconds > 3600 )); then
            echo "$app_path $app_param 运行超过 60 分钟，运行时间为: ${days}天 ${hours}小时 ${minutes}分钟 ${seconds}秒。准备终止..."
            return 1
        else
            echo "$app_path $app_param 运行时间正常，目前运行了: ${days}天 ${hours}小时 ${minutes}分钟 ${seconds}秒。"
            return 0
        fi
    else
        echo "$app_path $app_param 未在运行，无法检查运行时间。"
        return 2
    fi
}

main() {
    local app_path="$1"
    local app_param="$2"

    check_update "$app_path"
    if [[ $? -eq 1 ]]; then
        kill_app "$app_path"
        if [[ $? -ne 0 ]]; then
            echo "无法终止 $app_path $app_param，退出。"
            exit 1
        fi
        sleep 3

        update_app "$app_path"

        if [[ -f "$app_path" ]]; then
            echo "$app_path 更新成功，准备启动..."
            sleep 5
            run_app "$app_path" "$app_param"
        else
            echo "$app_path 更新失败，退出。"
            exit 1
        fi
    else
        check_app_running "$app_path" "$app_param"
        if [[ $? -eq 0 ]]; then
            run_app "$app_path" "$app_param"
        fi
    fi

    check_app_runtime "$app_path" "$app_param"
    if [[ $? -eq 1 ]]; then
        kill_app "$app_path"
        if [[ $? -ne 0 ]]; then
            echo "无法终止 $app_path $app_param，退出。"
            exit 1
        fi
        sleep 5
        run_app "$app_path" "$app_param"
    fi
}

main "/root/dawn" "--start"
echo "脚本执行完成。"
exit 0
#amb.api.code.end
