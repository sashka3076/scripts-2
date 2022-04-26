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
DISK_MOUNT="/dev/sda"

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

function Check_Size_Log(){
    
    if ! [ -f $ERROR_LOG ]; then                     # проверяем есть ли фай
        Error_File=$(cat $ERROR_LOG | wc -l)         # записываем в переменную количество строк в логе
        if [ $Error_File >= $max_size_log_file ]; then # если строк больше равно чем в настроках
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
        if [ $Error_File2 >= $max_size_log_file ]; then
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


function Check_Session(){
    # проверяем есть ли конфиг iscsi /etc/iscsi/initiatorname.iscsi 
    if ! [ -f /etc/iscsi/initiatorname.iscsi ]; then
        # файла нет пишем ошибку в лог
        echo "$(date +'%Y.%m.%d.%k') Файла initiatorname.iscsi не существует!" >> $ERROR_LOG
        echo "$(date +'%Y.%m.%d.%k') Файла initiatorname.iscsi не существует!"
    else # если есть берем от туда сесию
        . /etc/iscsi/initiatorname.iscsi
        # проверка на запуск сесии
        if [[ $InitiatorName != $(iscsiadm -m session -o show | grep -io "$InitiatorName") ]]; then # проверяем наличие сесии
            echo " $(date +'%Y.%m.%d.%k') Сесия прописанная в initiatorname.iscsi $InitiatorName не запущена" >> $ERROR_LOG
            echo " $(date +'%Y.%m.%d.%k') Сесия прописанная в initiatorname.iscsi $InitiatorName не запущена"
            eval service iscsi restart
            echo " $(date +'%Y.%m.%d.%k') Попытка перезапустить service iscsi restart " >> $ERROR_LOG
            echo " $(date +'%Y.%m.%d.%k') Попытка перезапустить service iscsi restart "
            sleep 5000 # спим 5 секунд
            if [[ $InitiatorName != $(iscsiadm -m session -o show | grep -io "$InitiatorName") ]]; then # проверяем наличие сесии
                echo " $(date +'%Y.%m.%d.%k') Неудача перезапуск не помог $InitiatorName не запущена" >> $ERROR_LOG
                echo " $(date +'%Y.%m.%d.%k') Неудача перезапуск не помог $InitiatorName не запущена"
        fi
        fi
    fi

    # чекаем примонтированн ли диск


}

function Check_Disk_Mount(){ #/proc/mounts

    Disk=$(lsblk | grep "$FOLDER_MOUNT$")

    if [[ $Disk == "" ]]; then
        echo " $(date +'%Y.%m.%d.%k') Похоже $FOLDER_MOUNT точка не примонтирована" >> $ERROR_LOG
        echo " $(date +'%Y.%m.%d.%k') Похоже $FOLDER_MOUNT точка не примонтирована"
         # начинаем монтирование
        if [[ $(cat /proc/mounts | grep -io "^$DISK_MOUNT") == $DISK_MOUNT ]]; then # проверяем есть ли вообще диск
            #echo "тут попытка монтирования"

            if ! [ -d $FOLDER_MOUNT ]; then
                echo " $(date +'%Y.%m.%d.%k') Похоже $FOLDER_MOUNT не существует автомонитрование не будет запущено" >> $ERROR_LOG
                echo " $(date +'%Y.%m.%d.%k') Похоже $FOLDER_MOUNT не существует автомонитрование не будет запущено"
            else
                # пытаемся все смотрировать
                echo "Запущено монтирование"
                eval mount $DISK_MOUNT $FOLDER_MOUNT >> $DEBUG_LOG

                sleep 5000
                if [[ $(cat /proc/mounts | grep -io "^$DISK_MOUNT") == $DISK_MOUNT ]]; then
                    echo " $(date +'%Y.%m.%d.%k') Похоже $FOLDER_MOUNT не существует автомонитрование не Удалось" >> $ERROR_LOG
                    echo " $(date +'%Y.%m.%d.%k') Похоже $FOLDER_MOUNT не существует автомонитрование не Удалось"
                fi
        fi
         else
            echo " $(date +'%Y.%m.%d.%k') Похоже диска не существует $DISK_MOUNT" >> $ERROR_LOG
            echo " $(date +'%Y.%m.%d.%k') Похоже диска не существует $DISK_MOUNT"
         fi
    else
        echo "$(date +'%Y.%m.%d.%k') Все примонтировано"    
    fi
}

	<< 'MULTILINE-COMMENT'



MULTILINE-COMMENT

Check_Size_Log
Check_Session
Check_Disk_Mount