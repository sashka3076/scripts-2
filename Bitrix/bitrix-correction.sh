#!bin/bash

DEBUG_STD="&> bitrix-correction.log"

echo "Устанавливаем vim mc"

yum install vim mc -y $DEBUG_STD

echo "Начинаем править cron"

touch /etc/cron.d/bx_$HOSTNAME $DEBUG_STD
echo "*/1 * * * * /usr/bin/php -f /home/bitrix/www/bitrix/modules/main/tools/cron_events.php" > /etc/cron.d/bx_$HOSTNAME $DEBUG_STD
cat /etc/cron.d/bx_$HOSTNAME $DEBUG_STD

echo "Начинаем править почту"
