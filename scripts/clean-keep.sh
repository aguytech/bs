#!/bin/bash
#
# Provides:				clean-keep
# Short-Description:	clean all files ended with tile ~
# Description:			clean all files ended with tile ~

path='/'
str='*~'
[ "$USER" != root ] && sucmd='sudo ' || sucmd=

path=${1:-$path}
! [ -d "$path" ] && echo "'$path' doesn't exists !" && exit

count="$(${sucmd}find "$path" -not \( -regex '/\(proc\|run\|sys\)' -prune \) -not -type p -type f -name "$str" -exec echo "{}" \; -exec rm -f "{}" \; | wc -l)"

echo "$count file(s) '*~' are deleted"
