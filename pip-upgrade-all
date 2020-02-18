#!/bin/bash
#
# Provides:				pip-upgrade-all
# Short-Description:	update all packages which are outdated
# Description:			update all packages which are outdated

# sudo
# sudo pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo pip install -U
[ -x /usr/bin/pip3 ] && CMD="pip3" || CMD="pip"
$CMD list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo $CMD install -U

