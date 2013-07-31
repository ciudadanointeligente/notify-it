#!/bin/bash

#~/.bashrc
export PATH=$HOME/.rvm/bin:$PATH
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

cd ~/projects/notify-it/

echo "Hello! We're at deliver.sh"

rake deliver:$1 > ~/projects/notify-it/shared/cron/deliver/$1.last 2>&1