#! /bin/bash

touchpad_status=$(synclient | grep TouchpadOff | sed 's/.*= \(.\)/\1/g')
if [ "$touchpad_status" == "0" ]; then
    synclient TouchpadOff=1
else
    synclient TouchpadOff=0
fi

