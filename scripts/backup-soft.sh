#!/bin/bash
#
# Provides:						backup-soft
# Short-Description:		backup / restore selected and installed softwares in /opt
# Description:					backup / restore selected and installed softwares in /opt

######################## GLOBAL FUNCTIONS
S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

########################  VARIABLES

declare USAGE="backup-soft : backup softwares from /opt
default softwares are define in the script in this list:
	eclipse*
	smartgit
	squirrel-sql
	sublime_text
	yed

Global usage:
backup-soft <args> <softwares>
backup-soft <args> -r/--restore [date] <softwares>

softwares:
	a list of 'nominal' software names
	if given, desactive option 'all'

args:
	-a,--all				select all softwares
	-f, --force         	delete existing files before restore
	-r, --restore [date]
							 backup date of softwares in format : '+%Y%m%d-%s'

	-h, --help			show usage of functions
	-q, --quiet		don't show any infomations except interaction informations
	-d, --debug		output in screen & in file debug informations
"

########################  FUNCTION

# initialize default paths to backup
__init() {
	local version release

	# connectors
	PATHS_SOFT["connectors"]="path_user=$HOME
file_soft=connectors
comp_path_opt=/opt/connectors"
	
	# sublime-text
	PATHS_SOFT["sublime_text"]="path_user=$HOME
file_soft=sublime_text
comp_path_opt=/opt/sublime-text
comp_path_conf=$HOME/.config/sublime-text-3
comp_path_user=$HOME/.sublime-project
comp_file_desk=$HOME/.local/share/applications/sublime-text.desktop"
	PATHS_EXE["sublime_text"]="/opt/sublime-text/sublime_text"

	# eclipse
	for version in java tools; do
		release=`ls /opt/ | sed -n "s|^eclipse.${version}.\(.*\)$|\1|p"`
		PATHS_SOFT["eclipse_${version}"]="path_user=$HOME
file_soft=eclipse_${version}_${release}
comp_path_opt=/opt/eclipse_${version}_${release}
comp_path_conf=$HOME/.eclipse_${version}
comp_path_user=$HOME/dev/eclipse-workspaces-${version}
comp_file_desk=$HOME/.local/share/applications/eclipse_${version}.desktop"
		PATHS_EXE["eclipse_${version}"]="/opt/eclipse_${version}_${release}/eclipse"
	done

	# squirrel-sql
	release=`ls /opt/ | sed -n 's|^squirrel-sql.\(.*\)$|\1|p'`
	PATHS_SOFT["squirrel-sql"]="path_user=$HOME
file_soft=squirrel-sql_${release}
comp_path_opt=/opt/squirrel-sql-${release}
comp_path_conf=$HOME/.squirrel-sql
comp_file_desk=$HOME/.local/share/applications/squirrel-sql.desktop"
	PATHS_EXE["squirrel-sql"]="/opt/squirrel-sql-${release}/squirrel-sql.sh"

	# smargit
	release=`ls /opt/ | sed -n 's|^smartgit.\(.*\)$|\1|p'`
	PATHS_SOFT["smartgit"]="path_user=$HOME
file_soft=smartgit_${release}
comp_path_opt=/opt/smartgit_${release}
comp_path_conf=$HOME/.config/smartgit
comp_file_desk=$HOME/.local/share/applications/smartgit.desktop"
	PATHS_EXE["smartgit"]="/opt/smartgit_${release}/bin/smartgit.sh"

	# yed
	release=`ls /opt/ | sed -n 's|^yed.\(.*\)$|\1|p'`
	PATHS_SOFT["yed"]="path_user=$HOME
file_soft=yed_${release}
comp_path_opt=/opt/yed-${release}
comp_path_conf=$HOME/.yEd
comp_file_desk=$HOME/.local/share/applications/yed.desktop"
	PATHS_EXE["yed"]="/opt/yed-${release}/yed.jar"

	#_echod "${FUNCNAME}():$LINENO \${!PATHS_SOFT[@]}=${!PATHS_SOFT[@]}"
	#_echod "${FUNCNAME}():$LINENO \${PATHS_SOFT[@]}=${PATHS_SOFT[@]}"
}

# $1 list of softwares
__backup() {
	_echod "${FUNCNAME}():$LINENO \$1=$1"

	local software
	
	# COMP PRE
	_echoT "BACKUP start"
	
	# COMP EXE
	for software in $1; do
		_echod "${FUNCNAME}():$LINENO \$software=$software"
		_echod "${FUNCNAME}():$LINENO \${!PATHS_SOFT[@]}=${!PATHS_SOFT[@]}"
		
		if [ "${PATHS_SOFT["${software}"]}" ]; then
			__backup_one "$software" "${PATHS_SOFT["${software}"]}"
		else
			_echoE "backup skipped: unable to find '${software}' in existing softwares configuration"
		fi
	done

	# COMP POST
	_echoT "BACKUP end"
}

# $1 software
# $2 string of paths definitions
__backup_one() {
	_echod "${FUNCNAME}():$LINENO \$1=$1"
	_echod "${FUNCNAME}():$LINENO \$2=$2"

	local paths_comp
	local path_user file_soft comp_path_opt comp_path_conf comp_file_desk

	_echoT "--> backup '$1'"

	# set variables in "${PATHS_SOFT["${software}"]}"
	eval "$2"
	paths_comp=`echo "${PATHS_SOFT["$1"]}"|sed -n 's|^comp_.*=\(.*\)$|\1|p'|xargs`
	if [ -z "${comp_path_opt}" ]; then
		_echoE "backup skipped for '${software}': 'comp_path_opt' is empty"
		return 1
	fi
	
	# check if paths_comp exists
	for path in ${paths_comp}; do
		if [ ! -e "${path}" ]; then
			_echoE "'$1' skipped: missing path '${path}'"
			return 1
		fi
	done

	cmd="${COMP_CMD} '${PATH_BACKUP}/${file_soft}_${DATE}.${COMP_EXT}' ${paths_comp} 2>&6"
	_eval ${cmd} || _echoE "executing '${cmd}'"
}

# $1 list of softwares
__restore() {
	_echod "${FUNCNAME}():$LINENO \$1=$1"

	local software
	
	# UNCOMP PRE
	_echoT "RESTORE start"
	
	# UNCOMP EXE
	for software in $1; do
		_echod "${FUNCNAME}():$LINENO \$software=$software"
		_echod "${FUNCNAME}():$LINENO \${!PATHS_SOFT[@]}=${!PATHS_SOFT[@]}"
		
		if [ "${PATHS_SOFT["${software}"]}" ]; then
			__restore_one "$software" "${PATHS_SOFT["${software}"]}"
		else
			_echoE "restore skipped: unable to find '${software}' in existing softwares configuration"
		fi
	done

	# UNCOMP POST
	_echoT "RESTORE end"
}

# $1 software
# $2 string of paths definitions
__restore_one() {
	_echod "${FUNCNAME}():$LINENO \$1=$1"
	_echod "${FUNCNAME}():$LINENO \$2=$2"

	local paths_comp path path_from path_to file_back release
	local path_user file_soft comp_path_opt comp_path_conf comp_file_desk

	# set variables in "${PATHS_SOFT["${software}"]}"
	eval "$2"
	
	file_back=`ls "${PATH_BACKUP}/${file_soft}"*"_${DATEB}.${COMP_EXT}"`
	# file not found 
	if ! ls "${file_back}" 1>/dev/null 2>&1; then
		_echoE "'$1' skipped: unable to find '${file_back}'"
		return 1
	fi
	release=`ls "${file_back}"|sed "s|${PATH_BACKUP}/${file_soft}\(.*\)_${DATEB}.${COMP_EXT}|\1|"`

	_echod "${FUNCNAME}():$LINENO \$DATEB=$DATEB"
	_echod "${FUNCNAME}():$LINENO \$release=$release"
	# existing paths
	paths_comp=`echo "${PATHS_SOFT["$1"]}"|sed -n 's|^comp_.*=\(.*\)$|\1|p'|xargs`
	# check if paths_comp exists
	for path in ${paths_comp}; do
		if [ -e "${path}" ]; then
			if [ -z "$FORCE" ]; then
				_echoE "'$1' skipped: path exists '${path}', to delete it use option '--force'"
				return 1
			else
				cmd="rm -fR '${path}'"
				_eval ${cmd} || _echoE "executing '${cmd}'"
			fi
		fi
	done

	# delete temporary path
	path_tmp="/tmp/backup-${DATE}"
	[ -d '${path_tmp}' ] && rm -fR "${path_tmp}"
	mkdir -p "${path_tmp}"

	cmd="${UNCOMP_CMD} '${file_back}' -C '${path_tmp}' 2>&6"
	_eval ${cmd} || _echoE "executing '${cmd}'"
	for path in ${paths_comp}; do
		[ "${path#/opt/}" != "${path}" ] && path="${path}${release}"
		path_from=${path_tmp}/${path#/}
		path_to=${path%/}
		# rename path
		#[ -n "$path_user" ] && path_to=${path/#$path_user/$HOME}
		cmd="mv '${path_from}' '${path_to}'"
		_eval ${cmd} || _echoE "executing '${cmd}'"
	done
}

__opts() {
	_echod "${FUNCNAME}():$LINENO IN \$@=$@"

	opts_given="$@"
	opts_short="afr:hdq"
	opts_long="all,force,restore:,help,quiet,debug"
	opts=$(getopt -o ${opts_short} -l ${opts_long} -n "${0##*/}" -- "$@") || _exite "Wrong or missing options"
	eval set -- "${opts}" || exit 1

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
			-r|--restore)
				shift
				action="restore"
				DATEB="$1"
				;;
			--help)
				echo "$USAGE"
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
	[ "$@" ] && softwares="$@"
	
	[ -z "${action}" ] && action="backup"
	[ -z "$ALL" ] && [ -z "$softwares" ] && _exite "You have to select option 'all' or give 'softwares'"
	if [ "$ALL" ]; then
		[ "$softwares" ] && _exite "You have to give 'softwares' or option '--all' not both"
		softwares="${!PATHS_SOFT[@]}"
	fi

	_echod "${FUNCNAME}():$LINENO ALL='$ALL' FORCE='$FORCE' REGEXP='$REGEXP' "
	_echod "${FUNCNAME}():$LINENO action='${action}' softwares='${softwares}' DATEB='${DATEB}'"
}

__main() {
	_echod "======================================================"
	_echod "$(ps -o args= $PPID)"

	local opts_given opts_short opts_long opts action DATEB

	# array for softwares definition
	declare -A PATHS_SOFT
	declare -A PATHS_EXE
	# path to backup/resore
	local PATH_BACKUP="$HOME/Soft/multi"
	# date for files
	local DATE=`date +%Y%m%d-%s`
	# compress command options
	local COMP_CMD="tar --exclude='.cache' -czf"
	local UNCOMP_CMD="tar -xzf"
	local COMP_EXT="tar.gz"
	
	# initialize variables for each softwares
	__init
	
	# get options
	__opts "$@"

	# call action with arguments
	__${action} "${softwares}"
}

########################  MAIN

__main "$@"

_exit 0

