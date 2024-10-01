#!/bin/bash
#amb.api.code.start
VERSION="@ambver=v1.3@"
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

# 杀掉运行中的 dawn
kill_dawn() {
    DAWN_PID=$(pgrep -f $DAWN_PATH)
    if [[ ! -z "$DAWN_PID" ]]; then
        echo "杀掉正在运行的 oasis 进程..."
        kill -9 $DAWN_PID
    else
        echo "aireg 未在运行。"
    fi
}

# 运行 dawn
run_dawn() {
    echo "检查可执行权限..."
    chmod +x $DAWN_PATH  # 确保有可执行权限
    echo "启动 aireg..."
    nohup $DAWN_PATH > /dev/null 2>&1 &
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
    update_dawn
    run_dawn
else
    check_dawn_running
    if [[ $? -eq 0 ]]; then
        run_dawn
    fi
fi

echo "脚本执行完成。"
#amb.api.code.end
