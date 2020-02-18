#!/bin/bash
#
# Provides:               snap-purge
# Short-Description:      purge all outdated snap packages
# Description:            purge all outdated snap packages

set -eu

sudo snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        CMD="sudo snap remove \"$snapname\" --revision=\"$revision\""
        echo $CMD
        eval $CMD
    done
