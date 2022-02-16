#!bin/bash

DEBUG_STD="&> bitrix-correction.log"

echo "Устанавливаем vim mc"

yum install vim mc certbot -y $DEBUG_STD

echo "Начинаем править cron"

touch /etc/cron.d/bx_$HOSTNAME $DEBUG_STD
echo "*/1 * * * * /usr/bin/php -f /home/bitrix/www/bitrix/modules/main/tools/cron_events.php" > /etc/cron.d/bx_$HOSTNAME $DEBUG_STD
/usr/bin/php -f /home/bitrix/www/bitrix/modules/main/tools/cron_events.php $DEBUG_STD
cat /etc/cron.d/bx_$HOSTNAME $DEBUG_STD


echo "ставим сертификат"

systemctl stop nginx
certbot certonly --standalone -d pavel.kz -m admin@pavel.kz -n --agree-tos
systemctl start nginx


# добавляем сертики в nginx
# cp /etc/letsencrypt/live/pavel.kz/cert.pem /etc/nginx/ssl/pavel.kz.bx.crt;
cp /etc/letsencrypt/live/pavel.kz/privkey.pem /etc/nginx/ssl/pavel.kz.bx.key;
# cp /etc/letsencrypt/live/pavel.kz/chain.pem /etc/nginx/ssl/pavel.kz.bx.chained.crt
cp /etc/letsencrypt/live/pavel.kz/fullchain.pem /etc/nginx/ssl/pavel.kz.bx.fullchain.crt
# создаем файл конфигурации
cp /etc/nginx/bx/conf/ssl.conf /etc/nginx/bx/conf/ssl.conf.back

# заполняем файл конфигурации
echo '' > /etc/nginx/bx/conf/ssl.conf;
echo 'error_page 497 https://$host$request_uri;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'keepalive_timeout       70;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'keepalive_requests      150;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'ssl_protocols TLSv1.2 TLSv1.3;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA3820-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'ssl_prefer_server_ciphers off;' >> /etc/nginx/bx/conf/ssl.conf;
echo '' >> /etc/nginx/bx/conf/ssl.conf;

echo "ssl_certificate      /etc/nginx/ssl/pavel.kz.bx.fullchain.crt;" >> /etc/nginx/bx/conf/ssl.conf;
echo "ssl_certificate_key       /etc/nginx/ssl/pavel.kz.bx.key;" >> /etc/nginx/bx/conf/ssl.conf;

echo 'ssl_dhparam         /etc/nginx/ssl/dhparam.pem;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'ssl_session_cache       shared:SSL:10m;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'ssl_session_timeout     10m;' >> /etc/nginx/bx/conf/ssl.conf;

systemctl restart nginx.service

echo "Начинаем править почту"

touch /home/bitrix/.msmtprc
chmod 755 /home/bitrix/www/bitrix/.msmtprc
chown bitrix:bitrix /home/bitrix/.msmtprc

# account default
# logfile /home/bitrix/msmtp_default.log
# host mail.pavel.kz
# port 25
# from bx@pavel.kz
# keepbcc on
# auth on
# user bx@pavel.kz
# password 122656789a
# tls on
# tls_certcheck on


bash /opt/webdir/bin/bx-sites -o json -a email --smtphost=smtp.hoster.kz   --smtpuser='bx@pavel.kz' --password=122656789a   --email='ivan@pavel.kz' --smtptls -s alice


