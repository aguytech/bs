#!/bin/bash
#
# Provides:             backup-vz
# Short-Description:    backup vz configuration, dump & templates
# Description:          backup vz configuration, dump & templates

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

################################  VARIABLES

usage="Usage: backup-vz[arguments]
backup openvz elements: configuration, logs, dump containers & suspend, snapshot
with options dump containers before backup

arguments:
    --dump          	save only vz dumps
    -c, --clean-log	delete log before backup
    -h, --help       	show this
    -q, --quiet      	don't show any infomations except interaction informations
    -d, --debug    	output in screen & in file debug informations
"

################################################################  _SCRIPT

# compress path
# $1 path base
# $2 sub path
__compress() {
	local path_from="$1"
	local path_subs="$2"
	local path_to="${path_from#/}"; path_to="${path_save}/${path_to//\//.}"; path_to="${path_to%/}"
	_echoD "${FUNCNAME}():$LINENO path_from='$path_from' paths_sub='$paths_sub' path_to='$path_to'"

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
			_echoD "${FUNCNAME}():$LINENO wrong path '$path_sub'"
		fi
	done
}

# synchronize files
# $1 path base
# $2 sub path
# $3 exclude path
__sync() {
	local path_from="$1"
	local path_subs="$2"
	local excludes="lost+found $3"
	local path_to="${path_from#/}"

	path_to="${path_save}/${path_to//\//.}"; path_to="${path_to%/}"
	_echoD "${FUNCNAME}():$LINENO path_from='$path_from' path_subs='$path_subs' path_to='$path_to'"

	# wrong path
	! [ -d "$path_from" ] && _exite "Wrong path '$path_from' for calling '$*'"

	# create path
	! [ -d "$path_to" ] && mkdir -p "$path_to"

	cd "$path_to"
	_echoT "$PWD"

	path_subs=$(echo "$path_subs")
	_echoD "${FUNCNAME}():$LINENO path_subs='$path_subs'"
	for path_sub in $path_subs
	do
		if [ -d "$path_from/$path_sub" ]; then
			path_sub_to="${path_to}/${path_sub#/}"
			! [ -d "$path_sub_to" ] && mkdir -p "$path_sub_to"

			str=; for exclude in $excludes; do str+=" --exclude='$exclude'"; done
			_echo "sync $path_sub"
			_evalq "rsync -a $str $path_from/$path_sub/ $path_sub_to/"
		else
			_echoE "wrong path '$path_from/$path_sub'"
			_echoD "${FUNCNAME}():$LINENO ERROR| Wrong path '$path_from/$path_sub'"
		fi
	done
}

__comp_share() {
	local paths path

	# all paths except mariadb & www
	paths=`ls "${S_HOST_PATH_SHARE}"|grep -v mariadb|grep -v www`
	for path in ${paths}; do
		__compress "${S_HOST_PATH_SHARE}" "${path}"
	done
	# for mariadb & www
	_echoT "STOP CONTAINER FROM 101 to 199"
	${S_PATH_SCRIPT}/vz-ctl stop 101-199
	_echoT "Container stopped"
	for path in www mariadb; do
		[ -d "${S_HOST_PATH_SHARE}/${path}" ] && __compress "${S_HOST_PATH_SHARE}/${path}" "*"
	done
	_echoT "START CONTAINER FROM 101 to 199"
	${S_PATH_SCRIPT}/vz-ctl start 101-199
	_echoT "Container started"
}

__clean_log() {
	_eval "find ${S_HOST_PATH}/*/var/log/ -name *.gz -exec rm {} \;"
	_eval "find ${S_HOST_PATH}/*/var/log/ -name *.1 -exec rm {} \;"
}

__main() {

	# clean log
	[ "${clean_log}" ] && __clean_log

	# dump all containers, force to stop if not
	if [ "$dump" ]; then
		_echoT "force dumping to each containers"
		${S_PATH_SCRIPT}/vz-dump -cyf 101-199
	fi

	# conf
	__compress "/" "etc/vz etc root/.ssh root"

	# log
	__compress "$S_VZ_PATH_NODE" "*/log"

	# dump
	__sync "$S_HOST_PATH" "dump" "/suspend /snapshot /template"

	# template
	__sync "$S_VZ_PATH_DUMP" "template"

	# suspend
	__sync "$S_VZ_PATH_DUMP" "suspend"

	# snapshot
	__sync "$S_VZ_PATH_DUMP" "snapshot"

	# share
	__comp_share
}

################################  MAIN

_echod "======================================================"
_echod "$(ps -o args= $PPID)"

path_save="$S_PATH_BACKUP/$_DATE/vz"
comp_opt=czf
comp_ext=tgz

opts_given="$@"
opts_short="dchq"
opts_long="dump,clean-log,debug,help,quiet"
OPTS=$(getopt -o $opts_short -l $opts_long -n "${0##*/}" -- "$@" 2>/tmp/${0##*/}) || _exite "wrong options '$(</tmp/${0##*/})'"
eval set -- "$OPTS"

_echoD "${FUNCNAME}():$LINENO opts_given='$opts_given' OPTS='$OPTS'"
while true; do
	case "$1" in
		--dump)
			dump=true
			;;
		-h| --help)
			_echo "$usage"
			_exit
			;;
		-c| --clean-log)
			clean_log=true
			;;
		-d| --debug)
			_redirect debug
			;;
		-q|--quiet)
			_redirect quiet
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

# all options
# ; log=l
_echoD "${FUNCNAME}():$LINENO conf='$conf' template='$template' dump='$dump' suspend='$suspend' snapshot='$snapshot' share='$share' log='$log'"

__main

_exit 0
