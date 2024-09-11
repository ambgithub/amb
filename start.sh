#!/bin/bash
#amb.code.start
VERSION="@ambver=v6.32@"

COMMAND="sh /www/wwwroot/io.net/aleo_check.sh"
# 执行频率
CRON_TIME="*/5 * * * *"
# 添加定时任务
(crontab -l 2>/dev/null | grep -Fv "$COMMAND" ; echo "$CRON_TIME $COMMAND") | crontab -
#amb.code.end
