#!bin/bash

LIMIT_MEM=10000000
while true
do  
    FREE_MEM=$(cat /proc/meminfo | grep -i MemFree | awk '{print $2}')
    echo $FREE_MEM
    if [ "$FREE_MEM" -le "$LIMIT_MEM" ]
    then
        sync
        echo 3 > /proc/sys/vm/drop_caches
    fi
    sleep 300
done
