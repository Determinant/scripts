#! /bin/bash -e
while [ 1 ]
do
    echo "Phase I"
    utimer --countdown $1
    mplayer -endpos 10 ~/multimedia/music/chateau.mp3 &> /dev/null
    echo "Phase II"
    utimer --countdown $2
    mplayer -endpos 10 ~/multimedia/sound_clips/nuclear_meltdown.mp3 &> /dev/null
done
