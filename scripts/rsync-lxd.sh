#!/bin/bash
#
# sync install bs & install path to LXD containers


######################## GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

########################  VARIABLES

usage="rsync-lxd, sync files between host and LXD containers
rsync-lxd -h, --help

options:
    -h, --help		Print usage of this command
    -q, --quiet	Don't print
    -p, --create-dirs   Create any directories necessary
    -r, --recursive	Recursively transfer files
    -d, --delete	Delete files before pushing

    --bs		sync only the path ${S_PATH_SCRIPT}
    --install		sync only the path ${S_PATH_INSTALL}
"

########################  FUNCTION

# check enabled configuration files
__push() {
	_echod "${FUNCNAME}::${LINENO} IN \$@=$@"
	local path path_to path_from path_tmp ct

	# path
	paths_sel="${paths_sel:-${S_PATH_SCRIPT} ${S_PATH_INSTALL}}"

	# cts_sel
	cts_sel="${cts_sel:-`lxc list -f csv -c n status=Running`}"

	for path in ${paths_sel}; do

		path_to="${path//${S_PATH_INSTALL}/\/usr/\local\/install}" # for desktop host
		path="${path//-desktop/}" # for desktop host

		path_from="/tmp/${path##*/}"
		[ -d "${path_from}" ] && _eval rm -fR ${path_from}
		_eval cp -a ${path} ${path_from}
		[ -d "${path_from}/.git" ] && _eval rm -fR "${path_from}/.git"

		for ct in ${cts_sel}; do
			_echo "${path} -> ${ct}"

			[ "${delete}" ] && _lxc_exec ${ct} "[ -d ${path_to} ] && rm -fR ${path_to}"
			_eval lxc file push ${args} ${path_from} $ct${path_to%/*}
		done
	done
}

__opts() {
	_echod "${FUNCNAME}::${LINENO} IN \$@=$@"

	opts_short="hqrpd"
	opts_long="help,quiet,recursive,create-dirs,delete,bs,install"
	opts=$(getopt -o ${opts_short} -l ${opts_long} -n "${0##*/}" -- "$@") || _exit 1
	eval set -- ${opts}
	_echod "${FUNCNAME}::${LINENO} opts=${*}"

	while [ "$1" != "--" ]; do
		case "$1" in
			-h|--help)			echo "${usage}" && exit ;;
			-q|--quiet)			args+=" --quiet"  ;;
			-r|--recursive)		args+=" --recursive"  ;;
			-p|--create-dirs)	args+=" --create-dirs"  ;;
			-d|--delete)			delete=y  ;;
			--bs)						paths_sel+=" ${S_PATH_SCRIPT}"  ;;
			--install)				paths_sel+=" ${S_PATH_INSTALL}"  ;;
		esac
		shift
	done
	shift
	cts_sel=$*
	_echod "${FUNCNAME}::${LINENO} cts_sel=${cts_sel}"
}

__main() {
	_echod "======================================================"
	_echod "$(ps -o args= $PPID)"
	local opts_short opts_long opts
	local paths_sel args delete cts_sel

	! type lxc >/dev/null 2>&1 && _exite "LXC command not found !"

	__opts "$@"
	__push
}

########################  MAIN

__main "$@"
