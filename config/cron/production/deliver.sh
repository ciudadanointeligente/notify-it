#!/bin/bash

#~/.bashrc
export PATH=$HOME/.rvm/bin:$PATH
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

cd /home/ubuntu/notify-it/

echo "Hello! We're at deliver.sh"

rake deliver:$1 > /home/ubuntu/notify-it/shared/cron/deliver/$1.last 2>&1
