#!/bin/bash
#
# Provides:             backup-server
# Short-Description:    backup server, vz & kvm files & configuration
# Description:          backup server, vz & kvm files & configuration

######################## GLOBAL FUNCTIONS
S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

########################  VARIABLES

usage="Usage: backup-server [arguments]

arguments:
    -a --all				backup all parts: conf scripts vz kvm
    --vz					call bakup vz
    --vz-dump		call bakup vz with dumping containers before backup
    --vz-cleanlog	call bakup vz with option to clean log before dumping
    --kvm				call bakup kvm
    -h, --help			show this
    -q, --quiet		don't show any infomations except interaction informations
    --debug			output in screen & in file debug informations

 Make a backup of server configuration files & server scripts. In options call backup-vz & backup-kvm
"

########################  _SCRIPT

# compress path
# $1 path base
# $2 sub path
__compress() {
	local path_from="$1"
	local path_subs="$2"
	local path_to="${path_from#/}"; path_to="${path_save}/${path_to//\//.}"; path_to="${path_to%/}"
	_echod "${FUNCNAME}::${LINENO} path_from='$path_from' paths_sub='$paths_sub' path_to='$path_to'"

	# wrong path
	! [ -d "$path_from" ] && _exite "Wrong path '$path_from' for calling '$*'"

	# create path
	! [ -d "$path_to" ] && mkdir -p "$path_to"

	cd "$path_from"
	_echoT "$PWD"

	for path_sub in $paths_sub; do
		path_sub=$(echo "$path_sub")
		if [ -d "$path_sub" ]; then
			file_to="${path_sub#/}"
			file_to="${file_to//\//.}"
			file_to="$path_to/${file_to%/}.$cmd_ext"

			_echo "compress $path_sub"
			_evalq "tar $cmd_opt $file_to $path_sub"
		else
			_echoE "wrong path '$path_sub'"
			_echod "${FUNCNAME}::${LINENO} wrong path '$path_sub'"
		fi
	done
}

__bc_conf() {
	_echoW "conf"
	path_from="/"
	paths_sub="boot/grub etc root"
	__compress "$path_from" "$paths_sub"
}

__bc_scripts() {
	_echoW "scripts"
	path_from="/"
	paths_sub="usr/local/bs"
	__compress "$path_from" "$paths_sub"
}

__main() {
	# conf
	__bc_conf

	# script
	__bc_scripts

	# vz
	if [ "$vz" ]; then
		_echoW "launch vz"
		_eval ${S_PATH_SCRIPT}/backup-vz ${vz_dump} ${vz_clean_log}
	fi

	# kvm
	if [ "$kvm" ]; then
		_echoW "launch kvm"
		_echo "Do nothing..."
		#backup-kvm
	fi
}

########################  MAIN

_echod "======================================================"
_echod "$(ps -o args= $PPID)"

path_save="$S_PATH_BACKUP/$_DATE"
cmd_opt=" --exclude='.cache' -czf"
cmd_ext=tgz

opts_given="$@"
opts_short="adq"
opts_long="all,vz,vz-dump,vz-cleanlog,help,debug,kvm,quiet"
opts=$(getopt -o $opts_short -l $opts_long -n "${0##*/}" -- "$@" 2>/tmp/${0##*/}) || _exite "wrong options '$(</tmp/${0##*/})'"
eval set -- "$opts"

if [ "${_CLUSTER_IPS/$_IPTHIS/}" == "${_CLUSTER_IPS}" ]; then
	_askyn "This server is not in S_CLUSTER, confirm"
	[ "$_ANSWER" == "n" ] && _exit
fi

_echod "${FUNCNAME}::${LINENO} opts_given='$opts_given' opts='$opts'"
while true; do
	case "$1" in
		--help)
			_echo "$usage"; _exit
			;;
		-d|--debug)
			_redirect debug
			;;
		-q|--quiet)
			_redirect quiet
			_echod "_redirect quiet"
			;;
		-a|--all)
			vz=v
			#kvm=k
			;;
		--vz)
			vz=v
			;;
		--vz-dump)
			vz_dump="--dump"
			;;
		--vz-cleanlog)
			vz_clean_log="--clean-log"
			;;
		--kvm)
			kvm=k
			;;
		--)
			shift
			break
			;;
		*)
			_exite "Bad options: '$1' in '$opts_given'"
			;;
	esac
	shift
done

_echod "${FUNCNAME}::${LINENO} conf='$conf' scripts='$scripts' kvm='$kvm' vz='$vz' \$*='$*'"

__main

_exit 0
