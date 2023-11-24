#!/bin/bash

TODAY=$(date)
MYSQLCMD=$(which mysql)
FIGLET=$(which figlet)
TS=$(date +'%Y-%m-%d_%Hh%Mm%Ss')
LOGFILE="${PWD}/diag_${TS}.txt"

# PUrGE
RETENTION=4
find . -name "diag_*.txt" -mtime +${RETENTION} -exec rm -f {} \;

[[ -f ~/.bash_profile ]] &&  . ~/.bash_profile || . ~/.profile

printBanner()
{
        BANNER=$1
        topbanner="# ============================================================================"
        bottombanner="# ----------------------------------------------------------------------------"
        echo " "
        echo $topbanner
        [[ -z ${FIGLET} ]] && echo ${BANNER} || {
                echo ${BANNER} | figlet -w255
        }
        echo $bottombanner
        echo " "
        return 0
}

printSection()
{
        SECTION="$1"
        topbanner="# ============================================================================"
        bottombanner="# ----------------------------------------------------------------------------"
        echo " "
        echo $topbanner
        echo "${SECTION}"
        echo $bottombanner
        echo " "
        return 0
}

clear

# OS Config
HOSTNAME=$(hostname)
OSRELEASE=$(lsb_release -a)
NBCPU=$(grep -c 'cpu MHz' /proc/cpuinfo)
MODELCPU=$(grep '^model name' /proc/cpuinfo | head -1)
MEMINFO=$(grep -E 'MemTotal|MemFree|MemAvailable|Buffers|SwapTotal|SwapFree' /proc/meminfo)
ETHINFO=$(/sbin/ifconfig -a)
VOLUMEINFO=$(df -h)
IOTOP=(which iotop)

printBanner "${HOSTNAME}"               | tee -a $LOGFILE
printSection "${TODAY}"                 | tee -a $LOGFILE
printBanner "OS CONFIG"                 | tee -a $LOGFILE
printSection "${OSRELEASE}"             | tee -a $LOGFILE
printSection "${NBCPU} x ${MODELCPU}"   | tee -a $LOGFILE
printSection "${MEMINFO}"               | tee -a $LOGFILE
printSection "${ETHINFO}"               | tee -a $LOGFILE
printSection "${VOLUMEINFO}"            | tee -a $LOGFILE


printBanner "UPTIME"                    | tee -a $LOGFILE
UPTIME=$(uptime)
printSection "${UPTIME}"                | tee -a $LOGFILE


printBanner "CPU USAGE"                 | tee -a $LOGFILE
CPUUSAGE=$(top -b -d 2 -n 10 | grep '^%Cpu(s)')
printSection "${CPUUSAGE}"              | tee -a $LOGFILE

printBanner "MEMORY USAGE"              | tee -a $LOGFILE
MEMUSAGE=$(free -h)
printSection "${MEMUSAGE}"              | tee -a $LOGFILE


printBanner "VMSTAT USAGE"              | tee -a $LOGFILE
VMSTATUSAGE=$(vmstat 5 5)
printSection "${VMSTATUSAGE}"           | tee -a $LOGFILE


printBanner "PROCESS CPU%"              | tee -a $LOGFILE
PROCESSCPU=$(ps aux --sort -%cpu | head -50)
printSection "${PROCESSCPU}"            | tee -a $LOGFILE

printBanner "PROCESS MEM%"              | tee -a $LOGFILE
MEMCPU=$(ps aux --sort -%mem | head -50)
printSection "${MEMCPU}"                | tee -a $LOGFILE

printBanner "FILESYSTEMS"               | tee -a $LOGFILE
DFUSAGE=$(df -h)
printSection "${DFUSAGE}"               | tee -a $LOGFILE

if [ ! -z ${IOTOP} ]
then
        printBanner "IO ACTIVITY"               | tee -a $LOGFILE
        IOACTIVITY=$(${IOTOP} -b -n 5 -d 5 | grep -E '^Total DISK READ|^Current DISK READ')
        printSection "${IOACTIVITY}"            | tee -a $LOGFILE
fi

printBanner "SYSTEM ERRORS"             | tee -a $LOGFILE
DMESG=$(dmesg --ctime --level emerg,alert,crit,err)
printSection "${DMESG}"                 | tee -a $LOGFILE

printBanner "NET PORTS USAGE"           | tee -a $LOGFILE
PORTSTATS=$(ss -pl)
printSection "${PORTSTATS}"             | tee -a $LOGFILE

printBanner "NETWORK STATS"             | tee -a $LOGFILE
NETSTATS=$(ip -s link)
printSection "${NETSTATS}"              | tee -a $LOGFILE

printBanner "FIN"                       | tee -a $LOGFILE
