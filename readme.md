
Birix AutoInstall to CentOS 7.* (environment check 98 - 100)

Script 1
```
wget https://raw.githubusercontent.com/solo10010/scripts/main/Bitrix/bitrix-env.sh && yum install -y ca-certificates && chmod +x bitrix-env.sh && sh bitrix-env.sh -s -p -H $HOSTNAME
```
Script 2
```
wget https://raw.githubusercontent.com/solo10010/scripts/main/Bitrix/bitrix-correction.sh && chmod +x bitrix-correction.sh && sh bitrix-correction.sh
```

если клиенты обращаются что после перехода с ISP  5 на 6  есть проблема при активации ключа https://disk.yandex.ru/i/gNq4y-4P5mBanA  решается так
```
wget https://raw.githubusercontent.com/solo10010/scripts/main/upgrade.ispmgr5.sh && sh upgrade.ispmgr5.sh

```
