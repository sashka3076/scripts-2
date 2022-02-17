Мануал по пользованию скриптов (Протестировано на CentOS 7.9)

Первым делом установим битрикс окружение этим скриптом.
```
wget https://raw.githubusercontent.com/solo10010/scripts/main/Bitrix/bitrix-env.sh && yum install -y ca-certificates && chmod +x bitrix-env.sh && sh bitrix-env.sh -s -p -H $HOSTNAME
```
После устанавливаем сам сайт. затем для исправления всех проверок запускаем скрипт ниже (измените ключии) Внимание! до запуска домен должен быть уже привязан к серверу.
```
wget https://raw.githubusercontent.com/solo10010/scripts/main/Bitrix/bitrix-correction.sh && chmod +x bitrix-correction.sh && sh bitrix-correction.sh -d pavel.kz -mail bx@pavel.kz -smtp-port 25
```
