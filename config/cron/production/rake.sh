#!/bin/bash

# ~/.bashrc

export PATH=$HOME/.rvm/bin:$PATH
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

cd /home/ubuntu/notify-it/

echo "We're at the rake.sh file now!"

FIRST=$1
shift
rake $FIRST $@ > /home/ubuntu/notify-it/shared/cron/$FIRST.last 2>&1
