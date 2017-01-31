#!/bin/bash
while true; do
    ssh home -NR 2334:localhost:22
    sleep 10
done
