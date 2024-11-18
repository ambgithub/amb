for instance in $(aws lightsail get-instances --query 'instances[*].name' --output text); do
    if [[ "$instance" != "amb" ]]; then
        echo "正在重启实例: $instance"
        aws lightsail reboot-instance --instance-name "$instance"
    fi
done
