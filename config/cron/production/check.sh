#!/bin/bash

# ~/.bashrc
export PATH=$HOME/.rvm/bin:$PATH
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

cd /home/ubuntu/notify-it/

FIRST=$1
shift
rake subscriptions:check:$FIRST $@ > /home/ubuntu/notify-it/shared/cron/check/$FIRST.last 2>&1
