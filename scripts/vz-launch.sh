#!/bin/bash
#
# write by salem Aguemoun

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  VARIABLES

usage="vz-launch Usage:
launch command(s) in containers with ssh protocol

  vz-launch ([options]) [commands] [ctids]

  commands are a string with list of commands to execute

  -h|--help    help
  -y|--confirm no asking for confirmation
  -c|--command [file] use commands contained in file
  -s|--server  [file]  user ctid contained in file
  -o|--options give options for bash execute
"

################################  MAIN

# openvz server
type vzlist &>/dev/null && VZLIST="vzlist" || VZLIST="/usr/sbin/vzlist"
type ${VZLIST} &>/dev/null || _exite "unable to find vzlist command"

ctids_run="$(${VZLIST} -Ho ctid | xargs)"
ctids_all="$(${VZLIST} -aHo ctid | xargs)"

# OUT: no options given
[ -z "$*" ] && _echoE "no options given" && exit 1

optsgiven="$@"
optsshort="hyo:c:s:"
optslong="help,options:,command:,file:"
opts=$(getopt -o ${optsshort} -l ${optslong} -n "${0##*/}" -- "$@" 2>/tmp/${0##*/}) || _exite "$(</tmp/${0##*/})'"
eval set -- "${opts}"
opts=

# options
while true; do
	case "$1" in
		-h|--help)
			_echo "$usage"; _exit
			;;
		-y|--confirm)
			confirm="y"
			;;
		-o|--options)
			shift
			options="$1"
			;;
		-c|--command)
			shift
			cmds_file="$1"
			;;
		-s|--server)
			shift
			ctids_file="$1"
			;;
		--)
			shift
			break
			;;
		*)
			_exite "Bad options: '$1' in '${optsgiven}'"
			;;
	esac
	shift
done
_echoD "\$*='$*' |  cmds_file='$cmds_file' | ctids_file='$ctids_file' | confirm='$confirm'"

# commands
if [ "$cmds_file" ]; then
	[ -f "$cmds_file" ] || _exite "unable to find '$cmds_file'"
	cmds="$(<$cmds_file)"
	cmd="ssh -p${S_VM_SSH_PORT} ${S_VM_SSH_USER}@${_VM_IP_BASE}.\${ctid} bash${options:+ -$options} < \"$cmds_file\""
else
	[ -z "$1" ] && _exite "you have to give commands if you don't give a string for it"
	cmds="$1"
	cmd="ssh -p${S_VM_SSH_PORT} ${S_VM_SSH_USER}@${_VM_IP_BASE}.\${ctid} bash${options:+ -$options} <<<\"$1\""
	shift
fi

# ctids
if [ -n "$ctids_file" ]; then
	! [ -f "$ctids_file" ] && _exite "unable to find '$ctids_file'"
	ctids=$(<$ctids_file)
else
	[ -z "$*" ] && _exite "you have to give ctids if you don't give a string for it"
	ctids="$*"
fi
[ "$ctids" = "all" ] && ctids=$ctids_all || ctids=$(_vz_ctids_clean $ctids)
ctids_inter=$(_vz_ctids_inter "$ctids" "$ctids_run")


################################  EXECUTE

if [ -z "$confirm" ]; then
	_echoT "$cmds"
	_echo "on containers:"
	_echoT "$ctids_inter"
	_askyn
fi

if [ -n "$confirm" ] || [ "$_ANSWER" = "y" ]; then
	for ctid in $ctids_inter; do
		_echoT "$ctid"
		_eval $cmd
	done
fi

_exit
