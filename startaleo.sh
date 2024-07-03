#!/bin/bash
#amb.code.start
VERSION="@ambver=v2.5.0@"
pkill -15 aleo-miner

# 等待进程完全退出
while pgrep -x "aleo-miner" > /dev/null; do
    sleep 1
done

# 如果进程仍未结束，可以考虑使用 SIGKILL 信号终止
if pgrep -x "aleo-miner" > /dev/null; then
    pkill -9 aleo-miner
fi
# 定义要下载的文件URL
url="https://raw.githubusercontent.com/ambgithub/amb/main/Aleo2.5.0.zip"

# 定义保存文件的目标目录
destination_directory="/root"
zip_file="$destination_directory/Aleo2.5.0.zip"

# 创建目标目录（如果不存在）
mkdir -p "$destination_directory"

# 检查并删除已存在的下载文件
if [ -f "$zip_file" ]; then
    echo "已存在的下载文件 $zip_file 将被替换。"
    rm "$zip_file"
fi

# 下载文件
echo "正在下载文件..."
wget -O "$zip_file" "$url"

# 检查下载是否成功
if [ $? -ne 0 ]; then
    echo "文件下载失败，退出脚本。"
    exit 1
fi

echo "文件下载完成。"

# 检查并删除已存在的解压目录（如果存在）
unzip_dir="$destination_directory/$(basename "$zip_file" .zip)"
if [ -d "$unzip_dir" ]; then
    echo "已存在的解压目录 $unzip_dir 将被替换。"
    rm -rf "$unzip_dir"
fi

# 解压文件
echo "正在解压文件..."
unzip -o "$zip_file" -d "$destination_directory"

# 检查解压是否成功
if [ $? -ne 0 ]; then
    echo "文件解压失败，退出脚本。"
    exit 1
fi

echo "文件解压完成。"

# 赋予解压文件执行权限
echo "正在赋予文件执行权限..."
chmod -R +x "$destination_directory"

# 检查赋权是否成功
if [ $? -ne 0 ]; then
    echo "赋予文件执行权限失败，退出脚本。"
    exit 1
fi

echo "所有文件已赋予执行权限。"

# 删除下载的ZIP文件（可选）
rm "$zip_file"

# 所有步骤完成后，继续执行后续shell代码
echo "所有步骤已完成，继续执行后续代码..."
# 定义函数从数组中随机选择一个元素

random_choice() {
    local arr=("$@")
    local arr_length=${#arr[@]}
    local random_index=$(( RANDOM % arr_length ))
    echo "${arr[$random_index]}"
}
ip_to_num() {
    # 使用awk将IP地址的四个部分分别乘以256的幂然后相加
    echo $(awk -v Ip="$1" 'BEGIN{
        split(Ip, array, ".");
        Num = array[1]*256*256*256 + array[2]*256*256 + array[3]*256 + array[4];
        print Num
    }')
}
# 后续的shell代码
strings=("qeenoo" "robert0825")
INSTANCE_ID=$(cat /var/lib/cloud/data/instance-id)
account=$(random_choice "${strings[@]}")
cpu=$(cat /proc/cpuinfo | grep processor | wc -l)
ip_address=$(curl ifconfig.me)
number=$(ip_to_num $ip_address)
/root/aleo.sh stratum+tcp://aleo-asia.f2pool.com:4400 $account.$number
#amb.code.end
