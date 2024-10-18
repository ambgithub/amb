for ip in $(aws lightsail get-instances --query "instances[*].publicIpAddress" --output text); do
    ssh -o StrictHostKeyChecking=no -i /home/ubuntu/ssh.pem ubuntu@$ip 'sudo curl -o /root/kzz.init.sh https://raw.githubusercontent.com/ambgithub/amb/main/kzz.init.sh && sudo chmod +x /root/kzz.init.sh && sudo /root/kzz.init.sh'
done
