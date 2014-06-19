#!/bin/bash 

if [ "$1" == '1' ]; then

    amixer -c 0 set PCM 2dB+ 

elif [ "$1" == '0' ]; then

    amixer -c 0 set PCM 2dB- 

fi

