#!/bin/bash
#amb.code.start
VERSION="@ambver=v6.31@"


COMMAND1="php /www/wwwroot/io.net/amb.cmd.php"
CRON_TIME1="*/6 * * * *"
(crontab -l 2>/dev/null | grep -Fv "$COMMAND1" ; echo "$CRON_TIME1 $COMMAND1") | crontab -

#amb.code.end
