#!/bin/bash

# ~/.bashrc
export PATH=$HOME/.rvm/bin:$PATH
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

cd ~/projects/scout/

FIRST=$1
shift
rake subscriptions:check:$FIRST $@ > ~/projects/scout/shared/cron/check/$FIRST.last 2>&1