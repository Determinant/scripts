#! /bin/bash
des=`echo $1 |  sed "s/$2/$3/g"`
mv "$1" "$des"
