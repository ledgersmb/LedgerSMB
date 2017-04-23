#!/bin/bash

if ! declare -F Log >/dev/null; then # declare a local copy of the Log() function that only prints to screen
    function Log() {
        echo -e "$@"
    }
fi

echo "Running $0 as $USER"

Header='\n================================'

Grab_disk_stats() {
    echo -e "${Header}\nGrab Disk Stats:${Header}"
    df -h # grab disk usage stats
}
Grab_memory_stats() {
    echo -e "${Header}\nGrab Memory Stats:${Header}"
    free -m -t # grap memory usage stats
}
Grab_load_stats() {
    echo -e "${Header}\nGrab Load Stats:${Header}"
    cat /proc/loadavg  # grap some load info
    uptime # grab uptime and load info
}
Grab_swap_stats() {
    echo -e "${Header}\nGrab Swap Stats:${Header}"
    swapon -s
}

main() {
    Grab_disk_stats
    Grab_memory_stats
    Grab_load_stats
    Grab_swap_stats
}

Log "$(main)"

echo -e "\n"