#!bin/bash
#change shadowsocks port



firewall-cmd --list-all
echo 'type your port which is not the above(example: 6666):'
read PORT
firewall-cmd --permanent --zone=public --add-port=${PORT}/tcp
firewall-cmd --reload
firewall-cmd --list-all


OLD_PORT=$(cat /etc/shadowsocks/config.json | grep 'server_port'  |cut -d ':' -f 2 | cut -d ',' -f 1 | awk '$1=$1')

echo 'old port'${OLD_PORT}
echo 'new port'${PORT}
sed -i "s|$OLD_PORT|$PORT|" /etc/shadowsocks/config.json

ssserver -c /etc/shadowsocks/config.json -d stop
ssserver -c /etc/shadowsocks/config.json -d start
