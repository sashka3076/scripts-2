#!/bin/bash

# скрипт для чеков на ошибки iscsi на стороне инициатора (не таргета)

# проверить на монтировавность диска
# если нет то примонтировать правильно
# Проверка свободного диска на примонтированном диске
# проверить можно ли создавать файлы
# чек доступности такргета
# Ошибки чтения записи
# файл логов

# ---------------------- Конфиги --------------------- #

ERROR_LOG="/var/log/check-isci/error-isci.log"
DEBUG_LOG="/var/log/check-isci/debug-isci.log"
max_size_log_file=5                                 # 1000 строчек в файле последнии будут чистится
FOLDER_MOUNT="/backup_isc"                          # примонтированная директория

# конец настроек



# ----- проверка на root права -------- #

if [[ $(id -u | grep -o '^0$') == "0" ]]; then
    SUDO=" "
else
    if sudo -n false 2>/dev/null; then
        printf "Запустите скрипт под пользователем SUDO \n"
    fi
    SUDO="sudo"
fi

# ------- проверяем наличие директории для логов -------- #
if ! [ -d /var/log/check-isci/ ]; then
    mkdir /var/log/check-isci/                      # если нет то создаем
fi
# ------- проверяем наличие лог файлов -------------------#
if ! [ -f $ERROR_LOG ]; then
    touch $ERROR_LOG # если нету создаем
fi
if ! [ -f $DEBUG_LOG ]; then
    touch $DEBUG_LOG
fi
# пример проверки существования файла #
#   if ! [ -f /path/to/file ]; then
#   echo 'No file'
#   fi

# -----------раздел функций эти запускаются поначалу--------#

function check_size_log(){
    echo $max_size_log_file
    if ! [ -f $ERROR_LOG ]; then                     # проверяем есть ли фай
        Error_File=$(cat $ERROR_LOG | wc -l)         # записываем в переменную количество строк в логе
        if [[ $Error_File >= $max_size_log_file ]]; then # если строк больше равно чем в настроках
            count=$($Error_File - $max_size_log_file) # считаем разницу
            if [[ $count != "0" ]];then               # если разнца не нулевая
                
                for i in $count;
                do
                    sed -i '1d' $Error_File            # удаляем разницу с начала файла
                done
            fi
        fi
    else
        touch $ERROR_LOG
    fi

    if ! [ -f $DEBUG_LOG ]; then
        Error_File2=$(cat $DEBUG_LOG | wc -l)
        if [[ $Error_File2 >= $max_size_log_file ]]; then
            count=$($Error_File2 - $max_size_log_file)
            if [[ $count != "0" ]];then
                
                for i in $count;
                do
                    sed -i '1d' $Error_File2
                done
            fi
        fi
    else
        touch $DEBUG_LOG
    fi

}

<< 'MULTILINE-COMMENT'
function logSave(){

}

function start_mount(){

}
MULTILINE-COMMENT

function Check_mount(){
    # проверяем есть ли конфиг iscsi /etc/iscsi/initiatorname.iscsi 
    if ! [ -f /etc/iscsi/initiatorname.iscsi ]; then
        # файла нет пишем ошибку в лог
        echo "Файла initiatorname.iscsi не существует!" >> $ERROR_LOG
    else # если есть берем от туда сесию
        . /etc/iscsi/initiatorname.iscsi
        echo "$InitiatorName"
    fi
}

	<< 'MULTILINE-COMMENT'


function disk_size(){

}

function check_testfile(){

}

function check_target(){

}

function check_rw(){

}

MULTILINE-COMMENT

check_size_log
Check_mount