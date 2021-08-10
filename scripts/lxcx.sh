#!/bin/bash
#
# Provides:						lxcx
# Short-Description:		functions over lxc to manipulate containers
# Description:					functions over lxc to manipulate containers

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1
! . "$S_PATH_SCRIPT/inc-lxc.sh" && echo -e "[error] - Unable to source file '$S_PATH_SCRIPT/inc-lxc.sh' from '${BASH_SOURCE[0]}'" && exit 1

################################  VARIABLES

usage="lxcx : manage containers
the container name can be one or few name (separate with space)
and a special name 'all' to select all containers

Global usage:    lxcx <args> [action] [containers]
	start			<ct name>
	stop			<ct name>
	restart		<ct name>
	delete		<ct name>	if option '--force' is given, running container are also deleted

args:
	-r, --regexp <regexp>    the selection for container name is made with regexp.
							BE CAREFUL: limit the begin & the end of regexp
	-a,--all				select all containers for action
	-f, --force         	force certain actions (delete, stop, restart, publish...)

	-h, --help			show usage of functions
	-q, --quiet		don't show any infomations except interaction informations
	-d, --debug		output in screen & in file debug informations
"

################################  FUNCTION

# $1 container names to select
# $2 available container names
__select() {
	_echod "${FUNCNAME}():$LINENO \$1=$1"
	_echod "${FUNCNAME}():$LINENO \$2=$2"

	local cts cts_tmp

	# all
	if [ "${ALL}" = "all" ]; then
		cts="$2"
	else
		# named containers
		cts_tmp="$1"
		#_echod "${FUNCNAME}():$LINENO named cts_tmp=${cts_tmp}"
		# regexped containers
		for regexp in $REGEXP; do
			cts_tmp="${cts_tmp} $(lxc list --format=json ${regexp} | jq -r '.[].name' |xargs)"
		done
		#_echod "${FUNCNAME}():$LINENO all cts_tmp=${cts_tmp}"
		cts_tmp=`echo ${cts_tmp} | tr " " "\n" | sort -u | xargs`
		# filters containers
		for ct in $cts_tmp; do
			[[ " $2 " = *" $ct "* ]] && cts="${cts} ${ct}"
		done
	fi
	_echod "${FUNCNAME}():$LINENO unique cts=${cts}"
	echo "$cts"
}

__start() {
	_echod "${FUNCNAME}():$LINENO IN \$@=$@"
	_echod "${FUNCNAME}():$LINENO ALL=$ALL FORCE=$FORCE REGEXP=$REGEXP"

	local cts cts_selected

	cts_selected=`__lxc_list_stopped`
	cts=`__select "$*" "$cts_selected"`
	_echod "${FUNCNAME}():$LINENO cts=${cts}"

	[ "${cts}" ] && _eval lxc start ${cts}
}

__stop() {
	_echod "${FUNCNAME}():$LINENO IN \$@=$@"
	_echod "${FUNCNAME}():$LINENO ALL=$ALL FORCE=$FORCE REGEXP=$REGEXP"

	local cts cts_selected

	cts_selected=`__lxc_list_running`
	cts=`__select "$*" "$cts_selected"`
	_echod "${FUNCNAME}():$LINENO cts=${cts}"

	[ "${cts}" ] && _eval lxc stop ${cts}
}

__restart() {
	_echod "${FUNCNAME}():$LINENO IN \$@=$@"
	_echod "${FUNCNAME}():$LINENO ALL=$ALL FORCE=$FORCE REGEXP=$REGEXP"

	local cts cts_selected

	cts_selected=`__lxc_list_running`
	cts=`__select "$*" "$cts_selected"`
	_echod "${FUNCNAME}():$LINENO cts=${cts}"

	[ "${cts}" ] && _eval lxc restart ${cts}
}

__delete() {
	_echod "${FUNCNAME}():$LINENO IN \$@=$@"
	_echod "${FUNCNAME}():$LINENO ALL=$ALL FORCE=$FORCE REGEXP=$REGEXP"

	local cts cts_selected

	if [ "${FORCE}" ]; then
		cts_selected=`__lxc_list_existing`
	else
		cts_selected=`__lxc_list_stopped`
	fi
	cts=`__select "$*" "$cts_selected"`
	_echod "${FUNCNAME}():$LINENO cts=${cts}"

	[ "${cts}" ] && _eval lxc delete ${FORCE:+--$FORCE} ${cts}
}

__opts() {
	_echod "${FUNCNAME}():$LINENO IN \$@=$@"

	opts_given="$@"
	opts_short="afr:hdq"
	opts_long="all,force,regexp:,help,quiet,debug"
	opts=$(getopt -o ${opts_short} -l ${opts_long} -n "${0##*/}" -- "$@") || _exite "Wrong or missing options"
	eval set -- "${opts}"

	_echod "${FUNCNAME}():$LINENO opts_given=$opts_given opts=$opts"
	while [ "$1" != "--" ]
	do
		case "$1" in
			-a|--all)
				ALL="all"
				;;
			-f|--force)
				FORCE="force"
				;;
			-r|--regexp)
				shift
				REGEXP="${REGEXP} $1"
				;;
			--help)
				echo "$usage"
				;;
			-q|--quiet)
				_redirect quiet
				;;
			-d|--debug)
				_redirect debug
				;;
			*)
				_exite "Wrong argument: '$1' for arguments '$opts_given'"
				;;
		esac
		shift
	done

	shift
	action="$1"
	shift
	_echod "${FUNCNAME}():$LINENO ALL='$ALL' FORCE='$FORCE' REGEXP='$REGEXP' "
	_echod "${FUNCNAME}():$LINENO action='$action'"
}

__main()
{	_echod "======================================================"
	_echod "$(ps -o args= $PPID)"

	local opts_given opts_short opts_long opts action
	local  ALL FORCE REGEXP

	# get options
	__opts "$@"

	[ -z "$action" ] && _exite "You have to give an action to execute"
	if [[ " start stop restart delete " = *" $action "* ]]; then
		# call action with arguments
		__$action "$@"
	else
		_exite "Wrong action: '$action'. select in: start stop restart delete"
	fi
}

################################  MAIN

__main "$@"

_exit 0
