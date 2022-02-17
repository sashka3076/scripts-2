# немного настроек

DEBUG_STD="&> bitrix_install.log"

# парсим аргументы
function help(){
	echo ""
	echo " Usage: ./bitrix-correction.sh [options...] [-h, --help]> 
		-d <domain>, -mail <email adress>"
	echo ""
	echo "  -d,     Домен для установки сертификата "
	echo "  -mail,     Email адресс по дефолту admin@yur_daomain "
    echo "  -smtp-port,     smtp pord по дефолту 25 . "
	echo ""
	echo "  -v, --version		bitrix-correction.sh version "
	echo "  -h, --help 		bitrix-correction.sh help"
    echo ""
	exit
}

if [[ -z "$1" ]]
then
	help # вызывает справка
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in

    -h|--help)
    help="$2"
    shift # past argument
    shift # past value
    if [[ -z $help ]]; then
	    help
    fi
    ;;
    -d)
    domain_name="$2"
    shift # past argument
    shift # past value
    if [[ -z $hostname ]]; then
	    echo " -d, Введи имя домена для установки сертификата "
	    echo " -h, --help bitrix-correction.sh"
	    exit
    fi
    ;;
    -mail)
    mail_name="$2"
    shift # past argument
    shift # past value
    if [[ -z $mail_name ]]; then
	    echo " -mail, Введи свой Email для уведомлений Lets Ncrypt "
	    echo " -h, --help bitrix-correction.sh"
	    exit
    fi
    ;;
    -smtp-port)
    smtp_port="$2"
    shift # past argument
    shift # past value
    if [[ -z $smtp_port ]]; then
	    $smtp_port=25
	    exit
    fi
    ;;
esac
done
    
    # бьем по рукам за неправильные аргументы

    if [[ $domain_name == "" ]]; then
        echo "Домен должен быть указан -d "
        exit
    fi
    if [[ $mail_name == "" ]]; then
        mail_name=admin@$domain_name
    fi
    if [[ $smtp_port == "" ]]; then
        smtp_port=25
    fi



# проверяем мы root или нет
if [[ $(id -u | grep -o '^0$') == "0" ]]; then
    SUDO=" "
else
    if sudo -n false 2>/dev/null; then
        printf "Запустите скрипт под пользователем SUDO \n"
    fi
    SUDO="sudo"
fi


    # Превью установки (правильно ли все ввел юзер)

    echo ""
    echo "      Домен      $domain_name"
    echo "      Email      $mail_name"
    echo "      smtp port  $smtp_port"
    echo ""
    # подтверждаем установку


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
certbot certonly --standalone -d $domain_name -m $mail_name -n --agree-tos
systemctl start nginx


# добавляем сертики в nginx
# cp /etc/letsencrypt/live/pavel.kz/cert.pem /etc/nginx/ssl/$domain_name.bx.crt;
cp /etc/letsencrypt/live/pavel.kz/privkey.pem /etc/nginx/ssl/$domain_name.bx.key;
# cp /etc/letsencrypt/live/pavel.kz/chain.pem /etc/nginx/ssl/$domain_name.bx.chained.crt
cp /etc/letsencrypt/live/pavel.kz/fullchain.pem /etc/nginx/ssl/$domain_name.bx.fullchain.crt
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

echo "ssl_certificate      /etc/nginx/ssl/$domain_name.bx.fullchain.crt;" >> /etc/nginx/bx/conf/ssl.conf;
echo "ssl_certificate_key       /etc/nginx/ssl/$domain_name.bx.key;" >> /etc/nginx/bx/conf/ssl.conf;

echo 'ssl_dhparam         /etc/nginx/ssl/dhparam.pem;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'ssl_session_cache       shared:SSL:10m;' >> /etc/nginx/bx/conf/ssl.conf;
echo 'ssl_session_timeout     10m;' >> /etc/nginx/bx/conf/ssl.conf;

systemctl restart nginx.service

echo "Начинаем править почту"

touch /home/bitrix/.msmtprc
chmod 777 /home/bitrix/www/bitrix/.msmtprc
chown bitrix:bitrix /home/bitrix/.msmtprc

echo "account default" >> /home/bitrix/.msmtprc
echo "logfile /home/bitrix/msmtp_default.log" >> /home/bitrix/.msmtprc
echo "host mail.$domain_name" >> /home/bitrix/.msmtprc
echo "port $smtp_port" >> /home/bitrix/.msmtprc
echo "from $mail_name" >> /home/bitrix/.msmtprc
echo "keepbcc on" >> /home/bitrix/.msmtprc
echo "auth on" >> /home/bitrix/.msmtprc
echo "user $mail_name" >> /home/bitrix/.msmtprc
echo "password 122656789a" >> /home/bitrix/.msmtprc
echo "tls off" >> /home/bitrix/.msmtprc
echo "tls_certcheck off" >> /home/bitrix/.msmtprc


perl /opt/webdir/bin/bx-sites -o json -a email --smtphost=mail.$domain_name   --smtpuser="$mail_name" --password=122656789a   --email="$mail_name" --smtptls -s default

#Для подключения модуля необходимо добавить строку
#include_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/wsrubi.smtp/classes/general/wsrubismtp.php");
#в файл /bitrix/php_interface/init.php или /local/php_interface/init.php, если файл отсутствует то его необходимо создать


