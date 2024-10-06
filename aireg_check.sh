#!/bin/bash
#amb.api.code.start
# 获取当前用户
USER=$(whoami)

# 当前文件描述符限制
echo "当前软限制 (nofile): $(ulimit -n)"
echo "当前硬限制 (nofile): $(ulimit -Hn)"
echo "系统全局文件描述符限制: $(cat /proc/sys/fs/file-max)"

# 临时设置当前会话的软硬限制为 100000
echo "临时设置文件描述符限制为 100000..."
ulimit -n 100000
ulimit -Hn 100000
echo "当前软限制 (nofile): $(ulimit -n)"
echo "当前硬限制 (nofile): $(ulimit -Hn)"

# 永久修改 /etc/security/limits.conf
LIMITS_CONF="/etc/security/limits.conf"
echo "正在修改 $LIMITS_CONF..."
if grep -q "$USER soft nofile" $LIMITS_CONF; then
    sudo sed -i "s/$USER soft nofile.*/$USER soft nofile 100000/" $LIMITS_CONF
else
    echo "$USER soft nofile 100000" | sudo tee -a $LIMITS_CONF
fi

if grep -q "$USER hard nofile" $LIMITS_CONF; then
    sudo sed -i "s/$USER hard nofile.*/$USER hard nofile 100000/" $LIMITS_CONF
else
    echo "$USER hard nofile 100000" | sudo tee -a $LIMITS_CONF
fi

echo "文件 $LIMITS_CONF 已修改。"

# 永久修改系统级别的文件描述符限制
SYSCTL_CONF="/etc/sysctl.conf"
echo "正在修改 $SYSCTL_CONF..."
if grep -q "fs.file-max" $SYSCTL_CONF; then
    sudo sed -i "s/fs.file-max.*/fs.file-max = 100000/" $SYSCTL_CONF
else
    echo "fs.file-max = 100000" | sudo tee -a $SYSCTL_CONF
fi

# 应用 sysctl 配置
echo "应用 sysctl 设置..."
sudo sysctl -p

echo "优化完成！以下是最终设置："
echo "当前软限制 (nofile): $(ulimit -n)"
echo "当前硬限制 (nofile): $(ulimit -Hn)"
echo "系统全局文件描述符限制: $(cat /proc/sys/fs/file-max)"



VERSION="@ambver=v4.7@"
# 定义一些变量
DAWN_PATH="/root/aireg"
VERSION_API="https://io.ues.cn/coin/index/updateaireg?ver="
DOWNLOAD_URL="https://raw.githubusercontent.com/ambgithub/amb/main/aireg"

# 检查 dawn 是否存在
if [[ ! -f "$DAWN_PATH" ]]; then
    echo "aireg 程序不存在，开始下载..."
    curl -L -o $DAWN_PATH $DOWNLOAD_URL
    chmod +x $DAWN_PATH
    echo "aireg 程序已下载并赋予可执行权限。"
fi

# 获取当前 dawn 版本
CURRENT_VERSION=$($DAWN_PATH --version)

# 检测版本是否为最新版
check_update() {
    VERSION_RESPONSE=$(curl -s "${VERSION_API}${CURRENT_VERSION}")

    if [[ $VERSION_RESPONSE == update* ]]; then
        echo "有新版本，准备更新..."
        return 1
    elif [[ $VERSION_RESPONSE == "ok" ]]; then
        echo "已是最新版本。"
        return 0
    else
        echo "检测版本失败，响应内容: $VERSION_RESPONSE"
        exit 1
    fi
}

# 更新 dawn 二进制文件
update_dawn() {
    echo "正在下载新版本..."
    curl -L -o $DAWN_PATH $DOWNLOAD_URL
    chmod +x $DAWN_PATH
    echo "更新完成并赋予可执行权限。"
}

# 优化后的杀掉运行中的 dawn 进程函数
kill_dawn() {
    pkill aireg
    # 获取 dawn 进程的 PID
    DAWN_PID=$(pgrep -f "$DAWN_PATH")
    # 最大重试次数
    max_attempts=5
    attempt=0
    DAWN_PID2=$(pgrep -f $DAWN_PATH)
    if [[ ! -z "$DAWN_PID2" ]]; then
        echo "杀掉正在运行的 dawn 进程..."
        kill -9 $DAWN_PID2
    else
        echo "dawn 未在运行。"
    fi
    # 如果进程存在，则尝试杀掉进程
    if [[ ! -z "$DAWN_PID" ]]; then
        echo "尝试杀掉正在运行的 dawn 进程 (PID: $DAWN_PID)..."

        # 循环检查进程是否已经结束
        while [[ ! -z "$DAWN_PID" ]] && [[ $attempt -lt $max_attempts ]]; do
            # 强制结束进程
            kill -9 $DAWN_PID
            # 等待 1 秒
            sleep 1
            # 重新获取 PID 以检查进程是否还存在
            DAWN_PID=$(pgrep -f "$DAWN_PATH")
            attempt=$((attempt + 1))
            echo "重试 $attempt 次..."
        done

        # 最后检查进程是否已成功结束
        if [[ -z "$DAWN_PID" ]]; then
            echo "dawn 进程已成功结束。"
        else
            echo "dawn 进程未能成功结束，达到最大尝试次数。"
        fi
    else
        echo "dawn 进程未在运行。"
    fi
}

# 启动 dawn 进程的函数
run_dawn() {
    # 检查 DAWN_PATH 是否为空或无效
    if [[ ! -x "$DAWN_PATH" ]]; then
        echo "错误: $DAWN_PATH 不存在或没有可执行权限"
        return 1
    fi

    # 检查进程是否已经在运行
    DAWN_PID=$(pgrep -f "$DAWN_PATH")
    if [[ ! -z "$DAWN_PID" ]]; then
        echo "dawn 进程已经在运行 (PID: $DAWN_PID)，无需重复启动。"
        return 0
    fi

    echo "检查可执行权限..."
    chmod +x "$DAWN_PATH"  # 确保有可执行权限

    echo "启动 dawn..."

    # 使用 nohup 后台启动，并将输出重定向到 /dev/null
    nohup $DAWN_PATH --socket > /dev/null 2>&1 &
    # 检查是否成功启动
    sleep 1
    DAWN_PID=$(pgrep -f "$DAWN_PATH")
    if [[ -z "$DAWN_PID" ]]; then
        echo "启动 dawn 失败。"
        return 1
    else
        echo "dawn 已成功启动 (PID: $DAWN_PID)。"
        return 0
    fi
}


# 检测 dawn 是否运行中
check_dawn_running() {
    DAWN_PID=$(pgrep -f $DAWN_PATH)
    if [[ ! -z "$DAWN_PID" ]]; then
        echo "aireg 已在运行，PID: $DAWN_PID"
        return 1
    else
        echo "aireg 未在运行，准备启动..."
        return 0
    fi
}

# 主逻辑
check_update
if [[ $? -eq 1 ]]; then
    kill_dawn
    sleep 3
    update_dawn

    sleep 5
    run_dawn
else
    check_dawn_running
    if [[ $? -eq 0 ]]; then
        run_dawn
    fi
fi

echo "脚本执行完成。"
exit 0
#amb.api.code.end
