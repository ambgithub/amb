<?php
//amb.api.code.start
//@ambver=v6.24@

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

    $api='http://io.ues.cn/coin/index/life';
    $post=[
        'ambkey'=>$ambkey,
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
# 定义要查找的进程字符串
current_dir="/www/wwwroot/io.net"
file="/www/wwwroot/io.net/io.caiji"
curl -L https://raw.githubusercontent.com/ambgithub/amb/main/io.caiji -o $current_dir/io.caiji
chmod +x $current_dir/io.caiji
# 要执行的脚本或命令
COMMAND="$current_dir/io.caiji"
# 执行频率
CRON_TIME="*/5 * * * *"
# 添加定时任务
(crontab -l 2>/dev/null | grep -Fv "$COMMAND" ; echo "$CRON_TIME $COMMAND") | crontab -
';
    @shell_exec($cmd);
}
function test()
{
    echo 'testtest';
}

//amb.api.code.end
?>
