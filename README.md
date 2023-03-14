# Archer C7 V2 AutoReboot for FW 3.15.3 Build 180308 Rel.37724n
TP-Link Archer C7 V2 AutoReboot - cross-utility (x86_64/aarch64, linux/darwin/windows) for using in Scheduler or Cron. If remote IP not respond then utility restart router. Support official/native FW 3.15.3 Build 180308 Rel.37724n (RU, EN, and other localizations)

```shell
--w, --watch    Remote IP address for ping, default "8.8.8.8"
--r, --router   Router local IP address, default "192.168.0.1"
--u, --user     Router Username, default "admin"
--p, --pass     Router Password, default "admin"
--c, --cmd      Router reboot command (Depends on localization), default "Перезагрузить"
--t, --test     Only for test, without reboot router

Examples:
ArcherC7V2AutoReboot --watch=8.8.8.8 --router=192.168.0.1 --user=admin --pass=admin --cmd=Перезагрузить
ArcherC7V2AutoReboot --watch=8.8.8.8 --router=192.168.0.1 --user=admin --pass=admin --cmd=reboot --test
ArcherC7V2AutoReboot --w=8.8.8.8 --r=192.168.0.1 --u=admin --p=admin --c=1 --t
ArcherC7V2AutoReboot --u=admin --p=admin
```

**Cron example:**

```shell
sudo crontab -e
```

```bash
# ПЕРЕЗАГРУЗКА РОУТЕРА С ВЕДЕНИЕМ ЛОГА
# Rebooting router with log
0,15,30,45 * * * * /home/jonyrh/ArcherC7V2AutoReboot --u=admin --p=password >> /var/log/ArcherC7V2AutoReboot.log 2>&1
```

(c) Jony Rh, 2023

http://www.jonyrh.ru
