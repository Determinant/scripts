#!/bin/bash
while true; do
    ssh mantou -NR 2335:localhost:22
    sleep 10
done
