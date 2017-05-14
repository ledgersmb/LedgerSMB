#!/bin/bash

if ! declare -F Log >/dev/null; then # declare a local copy of the Log() function that only prints to screen
    function Log() {
        echo -e "$@"
    }
fi

echo "Running $0 as $USER"

Header='\n================================'

HasRecentlyRun() {
    if [[ -f /tmp/system-resources.t.hasrun ]]; then
        tstamp=`stat --printf='%Y' /tmp/system-resources.t.hasrun`
        now=`date "+%s"`
        (( last_run_delta = now - tstamp ))
        (( last_run_delta_minutes = last_run_delta /60 ))
        (( last_run_delta_seconds = last_run_delta - (last_run_delta_minutes*60) ))
        if (( (tstamp + 600) > now )); then
            echo "Skipping $1 as it's already been run ($last_run_delta_minutes minutes and $last_run_delta_seconds seconds ago).";
            return 0;
        else
            echo "/tmp/system-resources.t.hasrun is stale (older than 10 miutes) removing it";
            rm /tmp/system-resources.t.hasrun
            return 1;
        fi
    else
        return 1; # It can't have been run as the flag file doesn't exist yet
    fi
}


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
Grab_cpuinfo() {
    HasRecentlyRun "Grab_cpuinfo" && return 0
    echo -e "${Header}\nGrab CPU Info:${Header}"
    while read -t1 L; do
        if [[ -z "$L" ]]; then skip=true; fi
        ${skip:=false} || Log "$L"
        if [[ "$L" =~ processor ]]; then max_processor_line="$L"; cpucount="${L##* }"; fi
    done < /proc/cpuinfo
    (( cpucount ++ ));
    echo -e "\n****\nCPU Count\t: $cpucount\n****";
}
Grab_VM_stats() {
    echo -e "${Header}\nGrab VM Stats:${Header}"
    vmstat -f
    vmstat -s
    vmstat -D
}

main() {
    Grab_cpuinfo
    Grab_VM_stats
    Grab_disk_stats
    Grab_memory_stats
    Grab_load_stats
    Grab_swap_stats
}

Log "$(main)"

echo -e "\n"

touch /tmp/system-resources.t.hasrun

