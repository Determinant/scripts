#! /bin/bash

cmd=$1
path=$2
prompt='reindexed_contestant_'

die() {

	echo >&2 "$@"
	exit 1
}

function reindex() {

	[ ! -f "$logfile" ] || die "Log file already exists, please clean it first!"
	index=0
	find $path/* -maxdepth 1 -type d | while read contestant
	do
		echo "$contestant" >> "$logfile"
		mv "$contestant" "$prompt""$index"
		let index++
	done
}

function clean() {

	cat /dev/null > "$logfile"
}

function recover() {

	index=0
	cat "$logfile" | while read contestant
	do
		mv "$prompt""$index" "$contestant" &> /dev/null
		let index++
	done
#	rm "$logfile"
}

[ ! "$#" -lt 1 ] || die "At least one arugment is required!"

if [ "$#" -lt 2 ]; then path=$(pwd); fi
[ -d "$path" ] || die "The specified directory does not exist!"


logfile="$path"/".reindex.log"

case $cmd in 
	reindex) reindex ;;
	recover) recover ;;
	clean)   clean ;;
	*) die "Invalid command!" ;;
esac

