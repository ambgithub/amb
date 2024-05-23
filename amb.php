<?php
function curls($url,$data = false,$type="get", &$err_msg = null, $timeout = 20, $cert_info = array())
{
    $type = strtoupper($type);
    if ($type == 'GET' && is_array($data)) {
        $data = http_build_query($data);
    }

    $option = array();

    if ( $type == 'POST' ) {
        $option[CURLOPT_POST] = 1;
    }
    if ($data) {
        if ($type == 'POST') {
            $option[CURLOPT_POSTFIELDS] = $data;
        } elseif ($type == 'GET') {
            $url = strpos($url, '?') !== false ? $url.'&'.$data :  $url.'?'.$data;
        }
    }

    $option[CURLOPT_URL]            = $url;
    $option[CURLOPT_FOLLOWLOCATION] = TRUE;
    $option[CURLOPT_MAXREDIRS]      = 4;
    $option[CURLOPT_RETURNTRANSFER] = TRUE;
    $option[CURLOPT_TIMEOUT]        = $timeout;

    //设置证书信息
    if(!empty($cert_info) && !empty($cert_info['cert_file'])) {
        $option[CURLOPT_SSLCERT]       = $cert_info['cert_file'];
        $option[CURLOPT_SSLCERTPASSWD] = $cert_info['cert_pass'];
        $option[CURLOPT_SSLCERTTYPE]   = $cert_info['cert_type'];
    }

    //设置CA
    if(!empty($cert_info['ca_file'])) {
        // 对认证证书来源的检查，0表示阻止对证书的合法性的检查。1需要设置CURLOPT_CAINFO
        $option[CURLOPT_SSL_VERIFYPEER] = 1;
        $option[CURLOPT_CAINFO] = $cert_info['ca_file'];
    } else {
        // 对认证证书来源的检查，0表示阻止对证书的合法性的检查。1需要设置CURLOPT_CAINFO
        $option[CURLOPT_SSL_VERIFYPEER] = 0;
    }

    $ch = curl_init();
    curl_setopt_array($ch, $option);
    $response = curl_exec($ch);
    $curl_no  = curl_errno($ch);
    $curl_err = curl_error($ch);
    curl_close($ch);

    // error_log
    if($curl_no > 0) {
        if($err_msg !== null) {
            $err_msg = '('.$curl_no.')'.$curl_err;
        }
    }
    return $response;
}
//心跳
function life($aws_id,$instance_id,$gpu_id)
{
    sleep(rand(1,15));
    global $cmd_ver;
    global $cloud_id;
    $api='http://io.ues.cn/coin/index/life';
    $post=[
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
            call_user_func_array($arr['shell'], $arr["data"]);
        }
    }
}

//安装
function install_io($aws_id,$user_id,$device_id,$device_name,$instance_id,$install_token,$gpu_id)
{
    global $path;
    global $cmd_ver;
    global $cloud_id;
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
wc=$(docker ps | grep -c "io-worker-monitor")
wv=$(docker ps | grep -c "io-worker-vc")
if [ $wc -eq 1 ] && [ $wv -eq 1 ]; then
    echo "io.net is working"
else
    echo "STOP AND DELETE ALL CONTAINERS"
    docker rm -f $(docker ps -aq) && docker rmi -f $(docker images -q) 
    yes | docker system prune -a
    echo "DOWNLOAD FILES FOR $system"
    
    curl -L https://raw.githubusercontent.com/ambgithub/amb/main/io_init.sh -o $current_dir/io_init.sh
    chmod +x $current_dir/io_init.sh
    
    curl -L https://github.com/ionet-official/io_launch_binaries/raw/main/io_net_launch_binary_linux -o $current_dir/io_net_launch_binary_linux
    chmod +x $current_dir/io_net_launch_binary_linux
   
    sh $current_dir/io_init.sh
    
    $current_dir/io_net_launch_binary_linux --device_id=$device_id --user_id=$user_id --operating_system="Linux" --usegpus=true --device_name=$device_name --no_cache=true --no_warnings=true --token=$token
    # 安装完成回调
    sleep 3
    curl "http://io.ues.cn/coin/index/installok?cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
    sleep 3
    curl "http://io.ues.cn/coin/index/installok?cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
    echo "install docker io.net is ok .running..."
fi
';
    @file_put_contents($path.'/install_io.sh',$cmd);
    @shell_exec('chmod -R 777 '.$path.'/install_io.sh');
    @shell_exec('nohup '.$path.'/install_io.sh > '.$path.'/install_io.log 2>&1 &');
}
//重新安装
function re_install_io($aws_id,$instance_id,$gpu_id,$path)
{
    sleep(rand(1,15));
    global $cmd_ver;
    global $cloud_id;
    $api='http://io.ues.cn/coin/index/installio';
    $post=[
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

echo "STOP AND DELETE ALL CONTAINERS"
docker rm -f $(docker ps -aq) && docker rmi -f $(docker images -q) 
yes | docker system prune -a
echo "DOWNLOAD FILES FOR $system"

curl -L https://raw.githubusercontent.com/ambgithub/amb/main/io_init.sh -o $current_dir/io_init.sh
chmod +x $current_dir/io_init.sh

curl -L https://github.com/ionet-official/io_launch_binaries/raw/main/io_net_launch_binary_linux -o $current_dir/io_net_launch_binary_linux
chmod +x $current_dir/io_net_launch_binary_linux

sh $current_dir/io_init.sh

$current_dir/io_net_launch_binary_linux --device_id=$device_id --user_id=$user_id --operating_system="Linux" --usegpus=true --device_name=$device_name --no_warnings=true --no_cache=true --token=$token
# 安装完成回调
sleep 3
curl "http://io.ues.cn/coin/index/installok?cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
sleep 3
curl "http://io.ues.cn/coin/index/installok?cloud_id=$cloud_id&cmd_ver=$cmd_ver&gpu_id=$gpu_id&instance_id=$instance_id&aws_id=$aws_id&user_id=$user_id&device_id=$device_id&device_name=$device_name&token=$token"
echo "install docker io.net is ok .running..."
';
        @file_put_contents($path.'/re_install_io.sh',$cmd);
        @shell_exec('chmod -R 777 '.$path.'/re_install_io.sh');
        @shell_exec('nohup '.$path.'/re_install_io.sh > '.$path.'/re_install_io.log 2>&1 &');
    }
}
function update_amb()
{
    global $path;

    $cmd='
#!/bin/bash
current_dir="'.$path.'"
echo "update amb.php file...."
curl -L https://raw.githubusercontent.com/ambgithub/amb/main/amb.php -o $current_dir/amb.php
chmod -R 777 $current_dir/amb.php
';
    @shell_exec($cmd);
}
function rm_file()
{
    $cmd='
#!/bin/bash
sudo rm -rf /usr/local/cuda-11.8
';
    @shell_exec($cmd);
}


$path='/www/wwwroot/io.net';

$cmd_ver='5.3';
$cloud_id=trim(@shell_exec('cloud-id'));

$account_info=json_decode(trim(@shell_exec('sudo aws sts get-caller-identity 2>&1')),true);
$aws_id=isset($account_info['Account'])?$account_info['Account']:'';
$instance_id=trim(@shell_exec('cat /var/lib/cloud/data/instance-id'));
$gpuinfo=@shell_exec('nvidia-smi --query-gpu=uuid --format=csv');
$pattern = '/GPU(.*)/si';
$gpu_id="";
if (@preg_match($pattern, $gpuinfo, $matches)) {
    $gpu_id = isset($matches[0]) ? trim($matches[0]) : "";
}
if (php_sapi_name() === 'cli') {
    if ($aws_id!="" && $instance_id!="" && $gpu_id!="") {
        life($aws_id,$instance_id,$gpu_id);
    }
} else {
    $act=isset($_REQUEST['act'])?$_REQUEST['act']:"";
    switch ($act)
    {
        case "reinstall":
            if ($aws_id!="" && $instance_id!="" && $gpu_id!="") {
                re_install_io($aws_id,$instance_id,$gpu_id,$path);
            }
            break;
        case "test":
           print_r($aws_id.'__'.$instance_id.'__'.$gpu_id.'__'.$path.'__'.$cloud_id);
            break;
        case "reboot":
            @shell_exec('sudo reboot');
            break;
        case "update":
            //更新php文件
            update_amb();
            break;
        case "rmfile":
            //更新php文件
            rm_file();
            break;

        default:break;
    }
    echo 'ok';
}
