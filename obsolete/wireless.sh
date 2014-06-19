#!/bin/bash
if [ $(whoami) != 'root' ]; then
	echo 'Error: only root can do that'
	exit 1
fi

cd /tmp
#Change the working directory

echo 'Checking Wireless Device Status...'
if [ "$(ifconfig | grep 'wlan0')" == "" ]; then

	echo 'Wireless Device is down , Now trying to UP...'
	ifconfig wlan0 up
fi
#Check the status

echo 'Scanning for APs...'
iwlist scan 2>/dev/null > scan.log;
printf " ID |\t  Address \t|\tQuality\t|\tSignal\t |  Noise  | Enc |  ESSID" > wlan.log
egrep '(Cell|ESSID|Quality|Encryption)' scan.log | \
sed -e :a -e 'N;s/\n//;ta' | sed 's/Cell/\nAP/g' | sed 's/[ \t][ \t]\+/\t/g' | \
sed 's/AP \([0-9]\+\) - Address: \(.\+\)\tESSID:"\(.*\)"\tQuality:\(.\+\)\tSignal level:\(.\+\)\tNoise level:\(.\+\)\tEncryption key:\(.\+\)/ \1 | \2 |\t\4 \t|\t \5 | \6 | \7 | \3/g' >> wlan.log
#Scan and Text processing

echo 'Please Choose an AP available:'
cat wlan.log;
FLINENUM=$(wc -l wlan.log | sed 's/[^0-9]//g')
while [[ 1 ]]
do
	read K;
	KK=`printf %d $K`
	let KK++
	if [[ $KK -gt $FLINENUM || $KK -lt 2 ]]; then
		echo 'Error: ID out of range!'
	else
		break;
	fi
done
#Choose an AP

STR=$(head wlan.log -n $KK | tail -n 1)
$(echo $STR | sed "s/.*| \([0-9A-Z:]*\) |.*| \(.*\)/iwconfig wlan0 ap \1 essid \2 /g")

echo 'Trying to Associate...'
Cnt=0;
while iwconfig  wlan0 | grep -q 'Not-Associated'
do
#	set -x
	echo "Not Associated Yet.. $Cnt"
	let Cnt=$Cnt+1
	sleep 1;
done

echo 'Set connnection...'
killall dhcpcd -9 2>/dev/null
sudo dhcpcd wlan0
echo 'Done..'
