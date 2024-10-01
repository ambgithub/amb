#!/bin/bash
#amb.api.code.start
VERSION="@ambver=v6.35@"

COMMAND="sh /www/wwwroot/io.net/aleo_check.sh"
# 执行频率
CRON_TIME="*/5 * * * *"
# 添加定时任务
(crontab -l 2>/dev/null | grep -Fv "$COMMAND" ; echo "$CRON_TIME $COMMAND") | crontab -
#amb.code.end



COMMAND2="sh /www/wwwroot/io.net/dawn_check.sh"
# 执行频率
CRON_TIME2="*/6 * * * *"
# 添加定时任务
(crontab -l 2>/dev/null | grep -Fv "$COMMAND2" ; echo "$CRON_TIME2 $COMMAND2") | crontab -

COMMAND3="sh /www/wwwroot/io.net/oasis_check.sh"
# 执行频率
CRON_TIME3="*/7 * * * *"
# 添加定时任务
(crontab -l 2>/dev/null | grep -Fv "$COMMAND3" ; echo "$CRON_TIME3 $COMMAND3") | crontab -

COMMAND4="sh /www/wwwroot/io.net/aireg_check.sh"
# 执行频率
CRON_TIME4="*/10 * * * *"
# 添加定时任务
(crontab -l 2>/dev/null | grep -Fv "$COMMAND4" ; echo "$CRON_TIME4 $COMMAND4") | crontab -


#amb.api.code.end
