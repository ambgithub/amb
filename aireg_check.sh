#!/bin/bash
#amb.api.code.start
VERSION="@ambver=v5.1@"
VERSION_API="https://io.ues.cn/coin/index/updateaireg?ver="
DOWNLOAD_URL="https://raw.githubusercontent.com/ambgithub/amb/main/aireg"

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
    local current_version=$($app_path --version)
    local version_response=$(curl -s "${VERSION_API}${current_version}")

    if [[ $version_response == update* ]]; then
        echo "有新版本，准备更新..."
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

    # 使用 curl 的 -f 选项，确保如果下载失败，脚本会返回非 0 状态
    curl -f -L -o $app_path $DOWNLOAD_URL

    # 检查 curl 命令是否执行成功
    if [[ $? -ne 0 ]]; then
        echo "下载新版本失败。"
        exit 1
    fi

    # 检查文件是否存在且非空
    if [[ ! -s "$app_path" ]]; then
        echo "下载的新版本文件无效。"
        exit 1
    fi

    chmod +x $app_path
    echo "更新完成并赋予可执行权限。"
}


# 杀掉运行中的进程
# 杀掉运行中的进程
kill_app() {
    local app_path="$1"
    local app_param="$2"

    pkill -f "$app_path $app_param"
    # 获取进程 PID
    local pid=$(pgrep -f "$app_path $app_param")

    if [[ ! -z "$pid" ]]; then
        echo "尝试优雅地终止 $app_path $app_param 进程, PID: $pid"
        kill "$pid"

        sleep 3

        pid=$(pgrep -f "$app_path $app_param")
        if [[ ! -z "$pid" ]]; then
            echo "进程未终止，强制终止 $app_path $app_param 进程, PID: $pid"
            kill -9 "$pid"
            sleep 3

            pid=$(pgrep -f "$app_path $app_param")
            if [[ ! -z "$pid" ]]; then
                echo "$app_path $app_param 进程仍未能终止"
                return 1  # 进程终止失败
            fi
        fi
        echo "$app_path $app_param 进程已终止"
        return 0  # 进程成功终止
    else
        echo "没有找到 $app_path $app_param 进程"
        return 0  # 没有进程在运行，视为成功
    fi
}

run_app() {
    local app_path="$1"
    local app_param="$2"

    check_app_exists "$app_path"
    local pid=$(pgrep -f "$app_path $app_param")
    if [[ ! -z "$pid" ]]; then
        echo "$app_path $app_param 进程已经在运行 (PID: $pid)，无需重复启动。"
        return 0
    fi

    echo "启动 $app_path $app_param 进程..."
    nohup $app_path $app_param > /dev/null 2>&1 &

    sleep 1
    pid=$(pgrep -f "$app_path $app_param")
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
    if [[ ! -z "$pid" ]]; then
        echo "$app_path $app_param 已在运行，PID: $pid"
        return 1
    else
        echo "$app_path $app_param 未在运行，准备启动..."
        return 0
    fi
}

# 修改后的时间检查函数，避免冒号问题
check_app_runtime() {
    local app_path="$1"
    local app_param="$2"

    local pid=$(pgrep -f "$app_path $app_param")
    if [[ ! -z "$pid" ]]; then
        local runtime=$(ps -o etime= -p "$pid" | tr -d ' ')  # 获取进程运行时间
        # 转换运行时间为秒
        local days=0
        local hours=0
        local minutes=0
        local seconds=0

        if [[ $runtime == *-* ]]; then
            days=$(echo $runtime | cut -d'-' -f1 | tr -d ' ')  # 去除空格
            runtime=$(echo $runtime | cut -d'-' -f2 | tr -d ' ')  # 去除空格
        fi

        # 如果运行时间是"hh:mm:ss"格式
        if [[ $runtime == *:*:* ]]; then
            IFS=: read -r hours minutes seconds <<< "$runtime"
        else
            # 如果运行时间是"mm:ss"格式
            IFS=: read -r minutes seconds <<< "$runtime"
        fi

        # 强制将时间单位解析为十进制数
        days=$((10#$days))
        hours=$((10#$hours))
        minutes=$((10#$minutes))
        seconds=$((10#$seconds))

        total_seconds=$(( 86400 * days + 3600 * hours + 60 * minutes + seconds ))

        if (( total_seconds > 3600 )); then
            echo "$app_path $app_param 运行超过 1 小时，运行时间为: ${days}天 ${hours}小时 ${minutes}分钟 ${seconds}秒。准备终止..."
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




# 主逻辑
# 主逻辑
main() {
    local app_path="$1"
    local app_param="$2"

    # 检查更新
    check_update "$app_path"
    if [[ $? -eq 1 ]]; then
        kill_app "$app_path" "$app_param"
        if [[ $? -ne 0 ]]; then
            echo "无法终止 $app_path $app_param，退出。"
            exit 1
        fi
        sleep 3

        update_app "$app_path"

        # 检查更新是否成功
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

    # 检查应用程序运行时间并处理
    check_app_runtime "$app_path" "$app_param"
    if [[ $? -eq 1 ]]; then
        kill_app "$app_path" "$app_param"
        if [[ $? -ne 0 ]]; then
            echo "无法终止 $app_path $app_param，退出。"
            exit 1
        fi
        sleep 3
        run_app "$app_path" "$app_param"
    fi
}

main "/root/aireg" "--socket"
sleep 10
main "/root/aireg" "--reg"
echo "脚本执行完成。"
exit 0

#amb.api.code.end
