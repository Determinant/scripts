#! /bin/bash
work_dir="/tmp"
site=$1
if [ -f "$work_dir/prev" ]; then rm "$work_dir/prev"; fi
while [ 1 ]
do
#	sleep 60
	wget "$site" -O "$work_dir/current"
	if [ -f "$work_dir/prev" ]; then
		diff "$work_dir/"{prev,current} &> /dev/null
		if [ "$?" != "0" ]; then
			notify-send "Something is updated"
			break;
		fi
	fi
	mv "$work_dir/"{current,prev}
done
