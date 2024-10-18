aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --targets "$(aws ssm describe-instance-information --query 'InstanceInformationList[*].InstanceId' --output json | jq -r '.[] | "Key=instanceIds,Values=" + .')" \
    --parameters commands="curl -o /root/kzz.init.sh https://raw.githubusercontent.com/ambgithub/amb/main/kzz.init.sh && sudo chmod +x /root/kzz.init.sh && sudo /root/kzz.init.sh" \
    --comment "Running script on all managed instances" \
    --region ap-southeast-1
