#!/bin/bash

# variables: SHOW_DIFF

prog=$1
complete_test=$2

if [ -z "$TIME_LIMIT" ]; then
	TIME_LIMIT=60 # in seconds
fi

if [ -z "$prog" ]
then
	echo "Which problem do you want to test?"
	exit
fi

source_found=0
compliation_succeed=0

suffix=("cpp" "c" "pas")
compile_cmd=("g++ %s -O3 -o %s -Wall -Wextra -pthread" "gcc %s -o %s -Wall" "fpc %s -o%s")
for i in {0..2}
do
	suf=${suffix[$i]}
	cmd=${compile_cmd[$i]}
	prog=`echo $prog | sed -e "s/\.$suf$//g"`
	if [ -f "$prog.$suf" ]
	then
		source_found=1
		echo "Source code file $prog.$suf found."
		echo "Compiling ... "
		`printf "$cmd" $prog.$suf $prog`
		if [ "x$?" == "x0" ]; then
			echo "Compilation succeed."
			compliation_succeed=1
			break
		fi
	fi
done

if [ "$source_found" == 0 ]
then
	echo "No source file found."
	exit
fi

if [ "$compliation_succeed" == 0 ]
then
	echo "Compilation failed";
	exit
fi
total=0
ac=0

function Verify
{
	#./$prog_checker $prog.in $prog.out $prog.ans
	if [ -z "$SHOW_DIFF" -o  "x$SHOW_DIFF" == "x0" ]; then
		diff -bc $prog.out $prog.ans > /dev/null
	else
		diff -bc $prog.out $prog.ans
	fi
}

echo "start testing. maximum running time is set to $TIME_LIMIT s"

data_dir=../../data/$prog/
input_file_list=`find $data_dir -regex '.*\.in[.0-9]*'`
total_time=0
available_data_found=0
for input_file in $input_file_list
do
	echo "current file $input_file"
	for suf in {"out","ans","ou"}
	do
		output_file=`echo $input_file | sed -e "s/\.in/\.$suf/g"`
		if [ -e $output_file ]
		then
			echo "Output file $output_file found."
			available_data_found=1
			break
		fi
	done

	cp $input_file $prog.in
	#ln -sv $input_file $prog.in
	cp $output_file $prog.ans
	#ln -sv $output_file $prog.ans

	used_time=`{ time timeout $TIME_LIMIT ./$prog; } 2>&1 | grep real | sed -e 's/real\t//g'`
	min=`echo $used_time | sed -e 's/\([^m]*\).*/\1/g'`
	sec=`echo $used_time | sed -e 's/.*m\([^s]*\).*/\1/g'`
	let used_time=`python -c "print int($min*60*1000+$sec*1000)"`
	echo "Used time: $used_time ms"
	let total_time=$total_time+$used_time

	Verify

	if [ "x$?" != "x0" ]
	then
		let total=$total+1
		echo "Wrong on case $total: `basename $input_file`"
		if [ -z $complete_test ]
		then
			exit
		fi
	else
		let total=$total+1
		let ac=$ac+1
		echo "Accepted"
	fi

	echo '---------------------------------------------------';
done
if [ "x$available_data_found" == "x1" ]; then
	echo "Total used time: $total_time ms"
	echo "Total case(s): $total"
	echo "Accepted case(s): $ac"
else
	echo "No valid data found."
fi
