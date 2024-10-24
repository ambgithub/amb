#!/bin/bash
#amb.api.code.start
VERSION="@ambver=v0.3@"
# 定义一些变量
DAWN_PATH="/root/oasis"
VERSION_API="https://io.ues.cn/coin/index/updateoasis?ver="
DOWNLOAD_URL="https://raw.githubusercontent.com/ambgithub/amb/main/oasis"

# 检查 dawn 是否存在
if [[ ! -f "$DAWN_PATH" ]]; then
    echo "oasis 程序不存在，开始下载..."
    rm -rf /root/oasis_cache.txt
    curl -L -o $DAWN_PATH $DOWNLOAD_URL
    chmod +x $DAWN_PATH
    echo "oasis 程序已下载并赋予可执行权限。"
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
    rm -rf /root/oasis_cache.txt
    curl -L -o $DAWN_PATH $DOWNLOAD_URL
    chmod +x $DAWN_PATH
    echo "更新完成并赋予可执行权限。"
}

# 杀掉运行中的 dawn
kill_dawn() {
    DAWN_PID=$(pgrep -f $DAWN_PATH)
    if [[ ! -z "$DAWN_PID" ]]; then
        echo "杀掉正在运行的 oasis 进程..."
        kill -9 $DAWN_PID
    else
        echo "oasis 未在运行。"
    fi
}

# 运行 dawn
run_dawn() {
    echo "检查可执行权限..."
    chmod +x $DAWN_PATH  # 确保有可执行权限
    echo "启动 oasis..."
    nohup $DAWN_PATH --socket > /dev/null 2>&1 &
}

# 检测 dawn 是否运行中
check_dawn_running() {
    DAWN_PID=$(pgrep -f $DAWN_PATH)
    if [[ ! -z "$DAWN_PID" ]]; then
        echo "oasis 已在运行，PID: $DAWN_PID"
        return 1
    else
        echo "oasis 未在运行，准备启动..."
        return 0
    fi
}

# 主逻辑
kill_dawn

echo "脚本执行完成。"
#amb.api.code.end
