#!/bin/bash

# . /projects/scout/.bashrc
cd ~/projects/scout/

FIRST=$1
shift
rake subscriptions:check:$FIRST $@ > ~/projects/scout/shared/cron/check/$FIRST.last 2>&1