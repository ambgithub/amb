#!/bin/bash
#amb.code.start
VERSION="@ambver=v6.32@"


COMMAND1="sh /root/task.sh"
CRON_TIME1="*/6 * * * *"
(crontab -l 2>/dev/null | grep -Fv "$COMMAND1" ; echo "$CRON_TIME1 $COMMAND1") | crontab -



COMMAND="/root/aleo_check.sh"
# 执行频率
CRON_TIME="*/5 * * * *"
# 添加定时任务
(crontab -l 2>/dev/null | grep -Fv "$COMMAND" ; echo "$CRON_TIME $COMMAND") | crontab -


#amb.code.end
