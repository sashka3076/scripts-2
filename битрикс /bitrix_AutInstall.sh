# немного настроек

DEBUG_STD="&> bitrix_install.log"

# парсим аргументы
function help(){
	echo ""
	echo " Usage: ./bitrix_Autinstall.sh [options...] [-h, --help]> 
		-p, -H, -F, -I, -M, -m 5.7, -m 8.0 "
	echo ""
	echo "  -p,     Создать пул после установки окружения (Create pool after installation of bitrix-env).  "
	echo "  -H,     Имя хоста (Hostname for for pool creation procedure). "
    echo "  -F,     Будет использоваться в качестве файрвола firewalld. . "
    echo "  -I,     Будет использоваться в качестве файрвола iptables (по умолчанию). . "
    echo "  -M,     Пароль root для MySQL (Mysql password for root user). . "
    echo "  -m 5.7, установить MySQL 5.7."
    echo "  -m 8.0, установить MySQL 8.0 (по умолчанию)."
	echo ""
	echo "  -v, --version		bitrix_Autinstall version "
	echo "  -h, --help 		help bitrix_Authinsatll"
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

    -h|--help) # Создать пул после установки окружения (Create pool after installation of bitrix-env).
    help="$2"
    shift # past argument
    shift # past value
    if [[ -z $help ]]; then
	    help
    fi
    ;;
    -H) # Имя хоста (Hostname for for pool creation procedure).
    hostname="$2"
    shift # past argument
    shift # past value
    if [[ -z $hostname ]]; then
	    echo " -H, Имя хоста (Hostname for for pool creation procedure). "
	    echo " -h, --help help bitrix_Authinsatll"
	    exit
    fi
    ;;
    -M) # Пароль root для MySQL (Mysql password for root user).
    mysql_passwd="$2"
    shift # past argument
    shift # past value
    if [[ -z $mysql_passwd ]]; then
	    echo " -M, Пароль root для MySQL (Mysql password for root user). "
	    echo " -h, --help help bitrix_Authinsatll"
	    exit
    fi
    ;;
    -m) # установить MySQL 5.7 (по умолчанию).
    mysql_version="$2"
    shift # past argument
    shift # past value
    if [[ -z $mysql_version ]]; then
	    $mysql_version=5.7
	    exit
    fi
    ;;
    -F) # Будет использоваться в качестве файрвола firewalld.
    firewald="$2"
    firewall=firewalld
    shift # past argument
    ;;
    -I) # Будет использоваться в качестве файрвола iptables (по умолчанию). .
    firewal_iptables="$2"
    firewall=iptables
    shift # past argument
    ;;
    -p) # Создать пул после установки окружения (Create pool after installation of bitrix-env).
    pull="$2"
    echo $pull
    pull=true
    shift # past argument
    ;;
esac
done

    # бьем по рукам за неправильные аргументы

    if [[ $firewall == "" ]]; then
        firewall=iptables
    fi
    if [[ $mysql_version == "" ]]; then
        mysql_version=5.8
    fi
    if [[ $pull == "" ]]; then
        pull=true
    fi
    if [[ $hostname == "" ]]; then
        echo "Хост должен быть указан -H "
        exit
    fi
    if [[ $mysql_passwd == "" ]]; then
        echo "Пароль для MySql должен быть указан -M "
        exit
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
    echo "      Создать пул после установки окружения      $pull"
    echo "      Имя сервера                                $hostname"
    echo "      Будет установлен firewall                  $firewall"
    echo "      Будет установлена версия Mysql             $mysql_version"
    echo "      Пароль Mysql                               $mysql_passwd"
    echo ""
    # подтверждаем установку
    read -e -p "для подтверждения введите (y/yes) или (no/n) для отмены: " USERREAD
    if [[ $USERREAD == "yes" || $USERREAD == "YES" || $USERREAD == "y" || $USERREAD == "Y" ]]; then
        echo "$USERREAD"
    else
        echo ""
        echo "Установка отменена"
        exit
    fi


# предварительные ласки

install_apt(){ # дебиан ублюнту
    eval $SUDO apt update -y $DEBUG_STD
    eval $SUDO apt install wget -y $DEBUG_STD


}

install_yum8x(){ # CentOS >= 8
   
    eval $SUDO yum groupinstall "Development Tools" -y $DEBUG_STD
    eval $SUDO yum install wget -y $DEBUG_STD
}

install_yum7x(){ # CentOS < 8
    
    eval $SUDO yum groupinstall "Development Tools" -y $DEBUG_STD
    eval $SUDO yum install wget -y $DEBUG_STD
    #eval $SUDO wget --no-check-certificate https://repos.1c-bitrix.ru/yum/bitrix-env.sh && chmod +x bitrix-env.sh && ./bitrix-env.sh -s -p -H server1 -F -m 8.0 -M '111111'
}


# чекаем OS


    printf "${bblue} Начинаем обновление и установку програмного обеспечения $OS_VERSION ${reset}\n\n"

    if [ -f /etc/debian_version ]; then 
        install_apt
    fi

    if [ -f /etc/redhat-release ]; then

        CentOSVersion=$(cat /etc/redhat-release | grep "CentOS" | awk -F " " '{print $1, $4}' | grep -o "7.9")

            if [ $CentOSVersion > "8.0" ]; then
                install_yum7x
            else
                install_yum8x
            fi
    fi


