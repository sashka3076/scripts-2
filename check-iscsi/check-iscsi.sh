#!/bin/bash

# скрипт для чеков на ошибки iscsi на стороне инициатора (не таргета)

# проверить на монтировавность диска
# если нет то примонтировать правильно
# Проверка свободного диска на примонтированном диске
# проверить можно ли создавать файлы
# чек доступности такргета
# Ошибки чтения записи
# файл логов

# Конфиги

ERROR_LOG=/var/log/check-isci/eror-isci.log
DEBUG_LOG=error_log=/var/log/check-isci/debug-isci.log
max_size_log_file=5 # 1000 строчек в файле последнии будут чистится

# конец настроек



# проверка на root права
if [[ $(id -u | grep -o '^0$') != "0" ]]; then
    echo "скрипт должен быть запущен от root!!!"
	echo "чтобы сохранить домашнюю диркторию запустить sudo -E"
	echo "запустить sudo -E ./check-iscsi.sh"
    exit
fi

# проверяем наличие директории для логов
if ! [ -d /var/log/check-isci/ ]; then
    mkdir /var/log/check-isci/ # если нет то создаем
fi

# пример проверки существования файла
#if ! [ -f /path/to/file ]; then
#echo 'No file'
#fi

# раздел функций эти запускаются поначалу

function check_size_log(){
    Error_File=$(cat $ERROR_LOG | wc -l)
    if [[ $Error_File >= "$max_size_log_file" ]]; then
        count=$($Error_File - $max_size_log_file)
        if [[ $count != "0" ]];then
            
            for i in $count;
            do
                sed'1d' $Error_File
            done
        fi
    fi
    
    Error_File2=$(cat $DEBUG_LOG | wc -l)
    if [[ $Error_File2 >= "$max_size_log_file" ]]; then
        count=$($Error_File2 - $max_size_log_file)
        if [[ $count != "0" ]];then
            
            for i in $count;
            do
                sed'1d' $Error_File2
            done
        fi
    fi
}


function Check_logSave(){

}

function start_mount(){

}

function Check_mount(){

}



function disk_size(){

}

function check_testfile(){

}

function check_target(){

}

function check_rw(){

}



function init(){

    check_size_log
    Check_mount
    disk_size
    check_testfile
    check_target
    check_rw

}