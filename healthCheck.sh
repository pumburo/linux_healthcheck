#!/bin/bash

# Linux healthcheck script by Mahmut Gür <a.mahmutgur@gmail.com>



function dPrint(){
	echo "####################" $1 "####################"
}

function aPrint(){
	echo "********************" $1 "********************"
}

function newPart(){
	echo ""
	echo "-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-0-"
	echo ""
}

# check user

if [ $USER != root ]; then
	echo "This script must run as root."
	exit 0
fi

if [ -f /etc/os-release ]; then
	dPrint "OS information"
	cat /etc/os-release
fi
if [ ! -z $(command -v vmstat) ]; then
	newPart
	dPrint "VMSTAT"
	vmstat 1 5
fi
newPart
dPrint "Uptime"
echo "Uptime:$(uptime)"
newPart
dPrint "Mounted points storage usage"
df -Th
critStorage=$(df -h | awk '0+$5 >= 80 {print}' | awk '{ print $6 }')
if [ ! -z "$critStorage" ]; then
	aPrint "This mount point uses more than %80 storage"
	echo "$critStorage"
else
	aPrint "There is no high storage usage"
fi
dPrint "Mounted points inode usage"
df -i
critInode=$(df -h | awk '0+$5 >= 80 {print}' | awk '{ print $6 }')
if [ ! -z "$critInode" ]; then
	aPrint "This mount point uses more than %80 inode"
	echo "$critInode"
else
	aPrint "There is no high inode usage"
fi
newPart
dPrint "Ram and Swap usage"
free -m
aPrint "Percentage of memory and swap usage"
ramUsage=$(free | grep -i mem | awk '{print $3/$2 * 100.0}')
swapUsage=$(free | grep -i swap | awk '{print $3/$2 * 100.0}')
echo "Ram usage: %${ramUsage}"
echo "Swap usage: %${swapUsage}"
newPart
dPrint "Cpu check"
aPrint "Number of cpu"
echo "CPU count:" $(cat /proc/cpuinfo | grep processor | wc -l)
aPrint "Load avarage"
cat /proc/loadavg

if [ ! -z $(command -v sar) ]; then
	dPrint "Sar output"
	sar
else
	dPrint "Sar command not found"
fi
newPart
dPrint "Zombie proccess check"
ps -eo stat | grep -w Z 1>&2 > /dev/null
if [ $? -eq 0 ]; then
	aPrint "Zombie proccesses found"
	echo "Number of zombie proccess:" $(ps -eo stat | grep -w Z | wc -l)
	aPrint "Zombie proccess details;"
	zombieProccesses=$(ps -eo stat,pid | grep -w Z | awk '{ print $2 }')
	for pid in $(ps -eo stat,pid | grep -w Z | awk '{ print $2 }'); do
		ps -o pid,ppid,user,stat,args -p $pid
	done
else
	aPrint "There is no zombie proccess"
fi
newPart
dPrint "Top 5 memory resource hog proccesses"
ps -eo pmem,pid,ppid,user,stat,args --sort=-pmem | grep -v $$ | head -6 | sed 's/$/\n/'
dPrint "Top 5 cpu resource hog proccesses"
ps -eo pcpu,pid,ppid,user,stat,args --sort=-pcpu|grep -v $$|head -6|sed 's/$/\n/'

