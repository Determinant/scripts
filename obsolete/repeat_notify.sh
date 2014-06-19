#!/bin/bash 
for ((i=1; i<=10; i++)) 
do
	notify-send -u critical "$1"; 
done

