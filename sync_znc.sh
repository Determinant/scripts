#!/bin/bash
rsync -avP do:~/.znc/ ~/rec/irc/ --exclude='znc.pem'
