#!/bin/bash
#
# Provides:				clean-keep
# Short-Description:	clean all files ended with tile ~
# Description:			clean all files ended with tile ~

__clean_keep() {
	path="$1"
	str="$2"
	[ "$USER" != root ] && sudo='sudo ' || sudo=

	path=${1:-$path}
	! [ -d ${path} ] && echo "path do not do not exists: '${path}'" && exit

	count="$(${sudo}find ${path} -not \( -regex '/\(proc\|run\|sys\|var\/lib\/lxcfs\)' -prune \) -type f -name "$str" -exec echo "{}" \; -exec rm -f "{}" \; | wc -l)"

	echo "${count} file(s) '${str}' are deleted"
}

__clean_trash() {
	path="$1"
	str="$2"
	[ "$USER" != root ] && sudo='sudo ' || sudo=

	path=${1:-$path}
	! [ -d ${path} ] && echo "path do not do not exists: '${path}'" && exit

	count="$(${sudo}find ${path} -not \( -regex '/\(proc\|run\|sys\|var\/lib\/lxcfs\)' -prune \) -type d -name "$str" -exec echo {} \; -exec rm -f {} \; | wc -l)"

	echo "${count} file(s) '${str}' are deleted"
}

__clean_keep '/' '*~'
__clean_trash '/' '.Trash*'