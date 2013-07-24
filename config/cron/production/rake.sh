#!/bin/bash

# ~/.bashrc

export PATH=$HOME/.rvm/bin:$PATH
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

cd ~/projects/scout/

echo "We're at the rake.sh file now!"

FIRST=$1
shift
rake $FIRST $@ > ~/projects/scout/shared/cron/$FIRST.last 2>&1