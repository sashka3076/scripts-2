if [[ $(id -u | grep -o '^0$') == "0" ]]; then
    SUDO=" "
else
    if sudo -n false 2>/dev/null; then
        printf "Запустите скрипт под пользователем SUDO \n"
    fi
    SUDO="sudo"
fi

install_apt(){
    eval $SUDO apt update -y $DEBUG_STD
    eval $SUDO DEBIAN_FRONTEND="noninteractive" apt install chromium-browser -y $DEBUG_STD


}

install_yum8x(){
    eval $SUDO yum groupinstall "Development Tools" -y $DEBUG_STD
    eval $SUDO yum install go chromium python3 python3-pip gcc cmake ruby git curl libpcap-dev wget zip python3-devel pv bind-utils libopenssl-devel libffi-devel libxml2-devel libxslt-devel zlib-devel nmap jq lynx tor medusa xorg-x11-server-xvfb prips -y $DEBUG_STD
}

install_yum7x(){
    eval $SUDO yum groupinstall "Development Tools" -y $DEBUG_STD
    eval $SUDO yum install go chromium python3 python3-pip gcc cmake ruby git curl libpcap-dev wget zip python3-devel pv bind-utils libopenssl-devel libffi-devel libxml2-devel libxslt-devel zlib-devel nmap jq lynx tor medusa xorg-x11-server-xvfb prips -y $DEBUG_STD
}

printf "${bblue} Начинаем обновление и установку програмного обеспечения $OS_VERSION ${reset}\n\n"

if [ -f /etc/debian_version ]; then 
    install_apt

if [ -f /etc/redhat-release ]; then
        CentOSVersion=$(cat /etc/redhat-release | grep "CentOS" | awk -F " " '{print $1, $4}')
        echo $CentOSVersion
        install_yum7x
fi