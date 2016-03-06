#!/bin/bash
case "$1" in
    on)
        sudo hda-verb /dev/snd/hwC1D0 0x21 SET_PIN_WID 0x40
        ;;
    off)
        sudo hda-verb /dev/snd/hwC1D0 0x21 SET_PIN_WID 0x00
        ;;
    *)
        echo "invalid action $1"
        exit 1
esac
