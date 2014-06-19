#! /bin/bash

#!/bin/bash -e
username='ymfoi'
passwd='ymf_ymf'

header_info="header.txt"
output_file="/dev/null"
site_ip=61.187.179.132
site_name=www.zybbs.org/JudgeOnline
site_addr="http://$site_name"
login_addr="$site_addr/login"
send_addr="$site_addr/send"
status_addr="$site_addr/status"

max_size=65536
src_addr="$site_addr/status?result=0&user_id=$username&size=$max_size"
status_addr="$site_addr/status"

cd /tmp

set -x
#curl "$login_addr"  -H "Host: $site_name" -e "$site_addr" -d "user_id1=$username&password1=$passwd&B1=login" -D "$header_info"
curl "$login_addr"  -d "user_id1=$username&password1=$passwd&action=login" -D "$header_info" 


curl "$src_addr" -b "$header_info"  > raw_src

cat /tmp/raw_src | grep '<tr align=center><td>[0-9]*<\/td><td><a href=userstatus' | sed 's/<tr align=center><td>\([0-9]*\)<\/td><td>.*<a href=showproblem?problem_id=[0-9]*>\([0-9]*\).*<td>\([0-9]*\)MS<\/td>.*<td>\([0-9-]\+\) \([0-9:]\+\).*/\1__p\2__\3ms__\4_\5/g' > formated_src

line_num=`wc formated_src -l | sed 's/\([0-9]\+\) .*/\1/g'`
for ((i=1;i<=$line_num;i++))
do
	line_text=`head formated_src -n $i | tail -1`
	rec_id=`echo $line_text | sed 's/\([0-9]*\).*/\1/g'`
	file_name=`echo $line_text | sed 's/[0-9]*__\(.*\)/\1/g'`
	curl "http://$site_name/showsource?solution_id=$rec_id" -b "$header_info" > raw_codes
	
	code_num=`wc raw_codes -l | sed 's/\([0-9]\+\) .*/\1/g'`
#	tail -n $(($code_num - 9)) raw_codes > raw_codes
	sed '1,9d' raw_codes > raw_codes2
	links -dump raw_codes2 >  "$file_name.cpp"
done
