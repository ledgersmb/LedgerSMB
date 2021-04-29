#!/bin/bash

mkdir -p /tmp/artifact/;

FILE=${1:-/tmp/artifact/memory-usage-actual.txt}
echo '"Time","CPU","Memory"' > $FILE

n_procs=2

read -rst5 cpu_usage0     </sys/fs/cgroup/cpu/cpuacct.usage
read -rst5 cstart         < <(date +"%s%N")

while true; do
    sleep 1;
    read -rst5 Memory_usage < <(free | grep Mem | awk '{print $3/$2 * 100.0}')
    read -rst5 cpu_usage    </sys/fs/cgroup/cpu/cpuacct.usage
    read -rst5 cstop        < <(date +"%s%N")
    read -rst5 Date         < <(date +"%FT%T.%3N")
    Cpu_usage=$(bc -l <<<"scale=2;100*($cpu_usage-$cpu_usage0)/($cstop-$cstart)/$n_procs")
    echo "$Date,$Cpu_usage,$Memory_usage";
    cpu_usage0=$cpu_usage;
    cstart=$cstop;
done >> $FILE;
