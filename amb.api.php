<?php
//amb.api.code.start
//@ambver=v6.20@

//检测虚拟机
function lxd()
{
    life();return;
    global $instance_id;
    global $path;
    $api='http://io.ues.cn/coin/index/lxdmb';
    $post=[
        'instance_id'=>$instance_id,
    ];
    $res=curls($api,$post);
    $arr=@json_decode($res,true);
    if (isset($arr["status"]) && $arr["status"]=="no") {
        $cmd='
#!/bin/bash
sudo mkdir /opt/dlami/nvme/data
generate_random_string() {
  local random_string=$(xxd -l 8 -p /dev/urandom)
  echo "i-$random_string"
}
start_stopped_containers() {
  local container_list=$(lxc list -c n --format csv)
  for container_name in $container_list; do
    if [ "$(lxc info "$container_name" | grep Status | awk \'{print $2}\')" == "Stopped" ]; then
      echo "容器 $container_name 已停止，正在启动..."
      lxc start "$container_name"
      if [ $? -eq 0 ]; then
        echo "容器 $container_name 启动成功。"
      else
        echo "容器 $container_name 启动失败。"
      fi
    fi
  done
}

# 定义导入 LXC 镜像的函数
import_lxc_image() {
  local image_path="$1"
  local image_alias="$2"
  local lock_file="/www/wwwroot/io.net/lxc_image_import.lock"

  # 检查是否已有其他导入操作在进行
  if [ -e "$lock_file" ]; then
    echo "另一导入操作正在进行，退出。"
    return 1
  fi

  # 创建锁文件
  touch "$lock_file"

  # 捕获函数退出时删除锁文件
  trap \'rm -f "$lock_file"\' EXIT

  # 检查镜像是否已存在
  if lxc image list | grep -q "$image_alias"; then
    echo "镜像 $image_alias 已存在。"
  else
    echo "镜像 $image_alias 不存在，开始导入镜像..."

    # 导入镜像
    lxc image import "$image_path" --alias "$image_alias"

    # 检查导入结果
    if [ $? -eq 0 ]; then
      echo "镜像导入成功。"
    else
      echo "镜像导入失败。"
      return 1
    fi
  fi
}
# 定义检查 IP 是否已被使用的函数
is_ip_in_use() {
  local ip_address="$1"

  # 获取所有容器的 IP 地址
  local ips=$(lxc list -c 4 --format csv | awk \'{print $1}\')

  for ip in $ips; do
    if [ "$ip" == "$ip_address" ]; then
      return 0
    fi
  done

  return 1
}

# 定义创建不低于 4 个容器的函数
ensure_minimum_containers() {
  local image_alias="$1"
  local min_containers=4
  local ip_prefix="10.100.0."
  local port_base=8081
  # 获取当前容器数量
  local container_count=$(lxc list -c n --format csv | wc -l)

  # 计算需要创建的容器数量
  if [ "$container_count" -lt "$min_containers" ]; then
    local containers_to_create=$((min_containers - container_count))
    echo "当前容器数量少于 $min_containers 个，正在创建 $containers_to_create 个新容器..."

    for i in $(seq 1 $containers_to_create); do
      # 生成唯一的容器名称

      local ip_suffix=$((10 + i))
      local ip_address="${ip_prefix}${ip_suffix}"
      local host_port=$((port_base + i - 1))

      # 检查 IP 是否已被使用
      if is_ip_in_use "$ip_address"; then
        echo "IP 地址 $ip_address 已被使用，跳过创建。"
        continue
      fi
      local container_name=$(generate_random_string)
      local container_name="${container_name}${host_port: -1}"
      lxc init "$image_alias" "$container_name" < /www/wwwroot/io.net/config.yaml
      lxc network attach lxdbr0 "$container_name" eth0
      lxc config device set "$container_name" eth0 ipv4.address "$ip_address"
      lxc start "$container_name"
      # 检查创建结果
      if [ $? -eq 0 ]; then
        echo "已创建并启动新容器: $container_name，IP 地址: $ip_address"
        # 设置端口转发
        lxc config device add "$container_name" myport${host_port} proxy listen=tcp:0.0.0.0:${host_port} connect=tcp:${ip_address}:13918
        echo "已设置端口转发: 主机端口 ${host_port} -> ${ip_address}:13918"
      else
        echo "创建容器 $container_name 失败。"
        return 1
      fi
    done
  else
    echo "当前容器数量已达到 $min_containers 个或更多，无需创建新容器。"
  fi
  return 0
}

IMAGE_PATH="/www/wwwroot/io.net/amb2024.tar.gz"
IMAGE_ALIAS="amb2024"
# 导入镜像
if import_lxc_image "$IMAGE_PATH" "$IMAGE_ALIAS"; then
 # 启动所有停止的容器
  start_stopped_containers
  # 确保容器数量不低于 4 个
  ensure_minimum_containers "$IMAGE_ALIAS"
fi
';
        life();
        @file_put_contents($path.'/lxc_create.sh',$cmd);
        @shell_exec('chmod -R 777 '.$path.'/lxc_create.sh');
        @shell_exec('sudo nohup '.$path.'/lxc_create.sh >> '.$path.'/lxc_create.log 2>&1 &');

    }
    else{
        echo $res;
    }
}

//心跳
function life()
{
    sleep(rand(1,15));
    global $cmd_ver;
    global $cloud_id;
    global $aws_id;
    global $instance_id;
    global $gpu_id;
    global $ambkey;

    $lxd_count=trim(@shell_exec('$(lxc list -c n --format csv | wc -l)'));
    $api='http://io.ues.cn/coin/index/life';
    $post=[
        'ambkey'=>$ambkey,
        'lxd_count'=>$lxd_count,
        'aws_id'=>$aws_id,
        'instance_id'=>$instance_id,
        'gpu_id'=>$gpu_id,
        'cmd_ver'=>$cmd_ver,
        'cloud_id'=>$cloud_id,
    ];
    $res=curls($api,$post);
    echo $res;
    $arr=@json_decode($res,true);
    if (isset($arr["status"]) && $arr["status"]=="ok")
    {
        if (isset($arr["shell"]) && $arr["shell"]!="")
        {
            if (isset($arr["data"]) && !empty($arr["data"]))
            {
                call_user_func_array($arr['shell'], $arr["data"]);
            }
            else{
                call_user_func($arr['shell']);
            }

        }
    }
}

//安装
function install_io($aws_id,$user_id,$device_id,$device_name,$instance_id,$install_token,$gpu_id,$cloud_id)
{
    global $path;
    global $cmd_ver;
    global $ambkey;
    $init_shell_url='https://raw.githubusercontent.com/ambgithub/amb/main/io_init.sh';
    if ($cloud_id=="lxd")
    {
        $init_shell_url='https://github.com/ionet-official/io-net-official-setup-script/raw/main/ionet-setup.sh';
    }
    $cmd='
#!/bin/bash
system="linux"
current_dir="'.$path.'"
aws_id="'.$aws_id.'"
user_id="'.$user_id.'"
device_id="'.$device_id.'"
device_name="'.$device_name.'"
instance_id="'.$instance_id.'"
token="'.$install_token.'"
gpu_id="'.$gpu_id.'"
cmd_ver="'.$cmd_ver.'"
cloud_id="'.$cloud_id.'"
ambkey="'.$ambkey.'"
init_shell_url="'.$init_shell_url.'"
wc=$(docker ps | grep -c "io-worker-monitor")
wv=$(docker ps | grep -c "io-worker-vc")
if [ $wc -eq 1 ] && [ $wv -eq 1 ]; then
    sleep 3
    curl "http://io.ues.cn/coin/index/isworking?ambkey=$ambkey&cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"

    sleep 3
    curl "http://io.ues.cn/coin/index/isworking?ambkey=$ambkey&cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
    echo "io.net is working"
else
    echo "STOP AND DELETE ALL CONTAINERS"
    sudo docker stop $(docker ps -aq) && docker kill $(docker ps -a -q)
    sudo docker rm -f $(docker ps -aq) && docker rmi -f $(docker images -q) 
    yes | docker system prune -a
    sudo rm -rf ionet_device_cache.json && sudo rm -rf /root/ionet_device_cache.json && sudo rm -rf $current_dir/ionet_device_cache.json
    echo "DOWNLOAD FILES FOR $system"
    curl -L $init_shell_url -o $current_dir/io_init.sh
    chmod +x $current_dir/io_init.sh
       
    sudo nohup sh $current_dir/io_init.sh >> $current_dir/io_init.log 2>&1 &
    
    curl -L https://github.com/ionet-official/io_launch_binaries/raw/main/io_net_launch_binary_linux -o $current_dir/io_net_launch_binary_linux
    chmod +x $current_dir/io_net_launch_binary_linux
    
    sleep 3
    curl "http://io.ues.cn/coin/index/installok?ambkey=$ambkey&cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
    
    $current_dir/io_net_launch_binary_linux --device_id=$device_id --user_id=$user_id --operating_system="Linux" --usegpus=true --device_name=$device_name --no_cache=true --no_warnings=true --token=$token
    # 安装完成回调
    
    sleep 3
    curl "http://io.ues.cn/coin/index/installok?ambkey=$ambkey&cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
    echo "install docker io.net is ok .running..."
fi
';
    @file_put_contents($path.'/install_io.sh',$cmd);
    @shell_exec('chmod -R 777 '.$path.'/install_io.sh');
    @shell_exec('sudo nohup '.$path.'/install_io.sh >> '.$path.'/install_io.log 2>&1 &');
}
//重新安装
function re_install_io()
{
    sleep(rand(1,15));
    global $cmd_ver;
    global $cloud_id;
    global $path;
    global $aws_id;
    global $instance_id;
    global $gpu_id;
    global $ambkey;

    $init_shell_url='https://raw.githubusercontent.com/ambgithub/amb/main/io_init.sh';
    if ($cloud_id=="lxd")
    {
        $init_shell_url='https://github.com/ionet-official/io-net-official-setup-script/raw/main/ionet-setup.sh';
    }

    $api='http://io.ues.cn/coin/index/installio';
    $post=[
        'ambkey'=>$ambkey,
        'aws_id'=>$aws_id,
        'instance_id'=>$instance_id,
        'gpu_id'=>$gpu_id,
        'cloud_id'=>$cloud_id,
        'cmd_ver'=>$cmd_ver,
    ];
    $res=curls($api,$post);
    echo $res;
    $arr=@json_decode($res,true);
    if (isset($arr["status"]) && $arr["status"]=="ok")
    {
        $user_id=$arr["data"]['user_id'];
        $device_id=$arr["data"]['device_id'];
        $device_name=$arr["data"]['device_name'];
        $install_token=$arr["data"]['install_token'];
        $cmd='
#!/bin/bash
system="linux"
current_dir="'.$path.'"
aws_id="'.$aws_id.'"
user_id="'.$user_id.'"
device_id="'.$device_id.'"
device_name="'.$device_name.'"
instance_id="'.$instance_id.'"
token="'.$install_token.'"
gpu_id="'.$gpu_id.'"
cmd_ver="'.$cmd_ver.'"
cloud_id="'.$cloud_id.'"
ambkey="'.$ambkey.'"
init_shell_url="'.$init_shell_url.'"
echo "STOP AND DELETE ALL CONTAINERS"
sudo docker stop $(docker ps -aq) && sudo docker kill $(docker ps -a -q)
sudo docker rm -f $(docker ps -aq) && sudo docker rmi -f $(docker images -q) 
yes | docker system prune -a
sudo rm -rf ionet_device_cache.json && sudo rm -rf /root/ionet_device_cache.json && sudo rm -rf $current_dir/ionet_device_cache.json
echo "DOWNLOAD FILES FOR $system"

curl -L $init_shell_url -o $current_dir/io_init.sh
chmod +x $current_dir/io_init.sh

sudo nohup sh $current_dir/io_init.sh >> $current_dir/io_init.log 2>&1 &

curl -L https://github.com/ionet-official/io_launch_binaries/raw/main/io_net_launch_binary_linux -o $current_dir/io_net_launch_binary_linux
chmod +x $current_dir/io_net_launch_binary_linux

sleep 3
curl "http://io.ues.cn/coin/index/installok?ambkey=$ambkey&cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"

$current_dir/io_net_launch_binary_linux --device_id=$device_id --user_id=$user_id --operating_system="Linux" --usegpus=true --device_name=$device_name --no_warnings=true --no_cache=true --token=$token
# 安装完成回调

sleep 3
curl "http://io.ues.cn/coin/index/installok?ambkey=$ambkey&cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
echo "install docker io.net is ok .running..."
';
        @file_put_contents($path.'/re_install_io.sh',$cmd);
        @shell_exec('chmod -R 777 '.$path.'/re_install_io.sh');
        @shell_exec('sudo nohup '.$path.'/re_install_io.sh >> '.$path.'/re_install_io.log 2>&1 &');
    }
}
//删除多余目录
function rm_file()
{
    $cmd='
#!/bin/bash
sudo rm -rf /usr/local/cuda-11.8
';
    @shell_exec($cmd);
}
function test()
{
    echo 'testtest';
}

//amb.api.code.end
?>
