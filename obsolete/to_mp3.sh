#!/bin/bash

ext=$1
if [ "$ext" == "" ]; then exit -1; fi
for src in *."$ext"
do
    if [ -f "$src" ]
    then
        fifo=`echo "$src"|sed -e "s/$ext$/wav/"`
        dest=`echo "$src"|sed -e "s/$ext$/mp3/"`

        rm -f "$fifo"
        mkfifo "$fifo"

        mplayer -vo null -vc dummy -af resample=44100 -ao pcm:waveheader \
            "$src" -ao pcm:file="$fifo" &
        lame --vbr-new "$fifo" "$dest"

        rm -f "$fifo"
    fi
done

