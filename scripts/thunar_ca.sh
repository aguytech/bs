#!/bin/bash
#
# Provides:             thunar_ca
# Short-Description:    A wrapper for thunar Custom Actions. launch command from thunar Custom Action
# Description:          A wrapper for thunar Custom Actions. launch command from thunar Custom Action

file_log=/var/log/server/${0##*/}
file_tmp=/tmp/${0##*/}
args="$*"

_log() {
	# print in log file
	if [ "$2" ]; then
		opt="$1"
		shift
		echo $1 "$(date +"%d-%m-%Y %T") - $*"  >> "$file_log"
	else
		echo "$(date +"%d-%m-%Y %T") - $*"  >> "$file_log"
	fi
}

_log -n "$*"

# exit with no args
[ -z "$*" ] && _log "$args - FAILED no command" && exit 1

app="$1"
shift

# exit with no args
[ -z "$*" ] && _log "$args - FAILED no args for '$app'" && exit 1

arg1="$1"
shift

if [ "$app" = "meld" ]; then
	if [ "$arg1" = "add" ]; then
		# exit with no args for command
		[ -z "$*" ] && _log "$args - FAILED no args for '$app $arg1'" && exit 1

		echo "$*" > "$file_tmp"
		exit
	elif [ "$arg1" = "with" ]; then
		cmd="$app --newtab \"$(<$file_tmp)\" \"$*\""
	else
		cmd="$app --newtab \"$arg1\" \"$*\""
	fi
else
	cmd="$app \"$arg1\" \"$*\""
fi

# launch command
_log -n "$cmd"
if eval "$cmd"; then
	_log " - OK"
else
	_log " - FAILED"
fi
