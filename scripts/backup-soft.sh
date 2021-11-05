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
	eclipse_java, eclipse_tools, smartgit, squirrel-sql, sublime_text, yed

Global usage:
backup-soft <args> <softwares>
backup-soft <args> -r/--restore [date] <softwares>

softwares:
	a list of 'nominal' software names
	if given, desactive option 'all'

args:
	-m,--menu		select options by menu
	-a,--all		select all softwares
	-f, --force         	delete existing files before restore
	-r, --restore [date]
				backup date of softwares in format : '+%Y%m%d-%s'
	-v, --version       	add given version to backup/restore

	-h, --help		show usage of functions
	-q, --quiet		don't show any infomations except interaction informations
	-d, --debug		output in screen & in file debug informations
"

########################  FUNCTION

# initialize default paths to backup
__init() {
	local theme

	[ -d ${PATH_BACKUP} ] || _exite "Unable to find path: ${PATH_BACKUP}"

	# connectors
	PATHS_SOFT["connectors"]="path_user=${HOME}
comp_path_opt=/opt/connectors"

	# archi
	PATHS_SOFT[archi]="path_user=${HOME}
comp_path_opt=/opt/archi
comp_path_conf=${HOME}/.archi4
comp_path_user=${HOME}/dev/archi
comp_file_desk=${HOME}/.local/share/applications/archi.desktop
comp_file_bin=/usr/bin/archi"

	# eclipse
	for theme in java tools; do
		PATHS_SOFT[eclipse_${theme}]="path_user=${HOME}
comp_path_opt=/opt/eclipse_${theme}
comp_path_conf=${HOME}/.eclipse_${theme}
comp_path_user=${HOME}/dev/eclipse-workspaces-${theme}
comp_file_desk=${HOME}/.local/share/applications/eclipse_${theme}.desktop
comp_file_bin=/usr/bin/eclipse_${theme}"
	done

	# mindmaster
	PATHS_SOFT[mindmaster]="path_user=${HOME}
comp_path_opt=/opt/mindmaster
comp_path_conf=${HOME}/Edraw/MindMaster
comp_file_desk=${HOME}/.local/share/applications/mindmaster.desktop
comp_file_bin=/usr/bin/mindmaster"

	# pipe
	PATHS_SOFT[pipe]="path_user=${HOME}
comp_path_opt=/opt/pipe
comp_file_desk=${HOME}/.local/share/applications/pipe.desktop
comp_file_bin=/usr/bin/pipe"

	# smargit
	PATHS_SOFT[smartgit]="path_user=${HOME}
comp_path_opt=/opt/smartgit
comp_path_conf=${HOME}/.config/smartgit
comp_file_desk=${HOME}/.local/share/applications/smartgit.desktop
comp_file_bin=/usr/bin/smartgit"

	# squirrel-sql
	PATHS_SOFT[squirrel-sql]="path_user=${HOME}
comp_path_opt=/opt/squirrel-sql
comp_path_conf=${HOME}/.squirrel-sql
comp_file_desk=${HOME}/.local/share/applications/squirrel-sql.desktop
comp_file_bin=/usr/bin/squirrel-sql"

	# sublime-text
	PATHS_SOFT[sublime_text]="path_user=${HOME}
comp_path_opt=/opt/sublime_text
comp_path_conf=${HOME}/.config/sublime-text-3
comp_path_user=${HOME}/.sublime-project
comp_file_desk=${HOME}/.local/share/applications/sublime-text.desktop
comp_file_bin=/usr/bin/sublime_text"

	# workcraft
	PATHS_SOFT[workcraft]="path_user=${HOME}
comp_path_opt=/opt/workcraft
comp_path_conf=${HOME}/.config/workcraft
comp_file_desk=${HOME}/.local/share/applications/workcraft.desktop
comp_file_bin=/usr/bin/workcraft"

	# yed
	PATHS_SOFT[yed]="path_user=${HOME}
comp_path_opt=/opt/yed
comp_path_conf=${HOME}/.yEd
comp_file_desk=${HOME}/.local/share/applications/yed.desktop
comp_file_bin=/usr/bin/yed"

	# zotero
	PATHS_SOFT[zotero]="path_user=${HOME}
comp_path_opt=/opt/zotero
comp_path_conf=${HOME}/.zotero
comp_path_user=/home/shared/Zotero
comp_file_desk=${HOME}/.local/share/applications/zotero.desktop
comp_file_bin=/usr/bin/zotero"

	#_echod "${FUNCNAME}::${LINENO} \${!PATHS_SOFT[@]}=${!PATHS_SOFT[@]}"
	#_echod "${FUNCNAME}::${LINENO} \${PATHS_SOFT[@]}=${PATHS_SOFT[@]}"
}

__menu() {
	local comp_path_opt comp_path_conf comp_file_desk comp_file_bin

	_menu "Select an action" backup restore
	ACTION=${_ANSWER}

	_menu "Select a software to backup" $(echo ${!PATHS_SOFT[@]}|tr ' ' '\n'|sort)
	SOFTWARES=${_ANSWER}

	# set variables in "${PATHS_SOFT["${software}"]}"
	eval "${PATHS_SOFT[${SOFTWARES}]}"
	if [ "${ACTION}" = restore ]; then
		_menu "Select an action" $(ls -1r ${PATH_BACKUP}|sed -n "s|^${SOFTWARES}_\([0-9-]\+\)\.tar\.gz$|\1|p")
		DATEB=${_ANSWER}
	fi
}

# $1 list of softwares
__backup() {
	_echod "${FUNCNAME}::${LINENO} \$1=$1"

	local software

	# COMP PRE
	_echoT "BACKUP start"

	# COMP EXE
	for software in $1; do
		_echod "${FUNCNAME}::${LINENO} \$software=${software}"
		_echod "${FUNCNAME}::${LINENO} \${!PATHS_SOFT[@]}=${!PATHS_SOFT[@]}"

		if [ "${PATHS_SOFT[${software}]}" ]; then
			__backup_one "${software}" "${PATHS_SOFT[${software}]}"
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
	_echod "${FUNCNAME}::${LINENO} \$1=$1"
	_echod "${FUNCNAME}::${LINENO} \$2=$2"

	local path paths_comp
	local comp_path_opt comp_path_conf comp_file_desk comp_file_bin

	_echoT "--> backup '$1'"

	# set variables in "${PATHS_SOFT["${software}"]}"
	eval "$2"
	paths_comp=`echo "${PATHS_SOFT["$1"]}"|sed -n 's|^comp_.*=\(.*\)$|\1|p'|xargs`
	if [ -z "${comp_path_opt}" ]; then
		_echoE "backup skipped for '$1': 'comp_path_opt' is empty"
		return 1
	fi

	# check if paths_comp exists
	for path in ${paths_comp}; do
		if [ ! -e "${path}" ]; then
			_echoE "'$1' skipped: missing path '${path}'"
			return 1
		fi
	done

	version=${VERSION:+-${VERSION}}
	cmd="${COMP_CMD} '${PATH_BACKUP}/$1${version}_${DATE}.${COMP_EXT}' ${paths_comp} 2>&6"
	_eval ${cmd} || _echoE "executing '${cmd}'"
}

# $1 list of softwares
__restore() {
	_echod "${FUNCNAME}::${LINENO} \$1=$1"

	local software

	# UNCOMP PRE
	_echoT "RESTORE start"

	# UNCOMP EXE
	for software in $1; do
		_echod "${FUNCNAME}::${LINENO} \$software=${software}"
		_echod "${FUNCNAME}::${LINENO} \${!PATHS_SOFT[@]}=${!PATHS_SOFT[@]}"

		if [ "${PATHS_SOFT["${software}"]}" ]; then
			__restore_one "${software}" "${PATHS_SOFT["${software}"]}"
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
	_echod "${FUNCNAME}::${LINENO} \$1=$1"
	_echod "${FUNCNAME}::${LINENO} \$2=$2"

	local paths_comp path path_from path_to file_back
	local comp_path_opt comp_path_conf comp_file_desk comp_file_bin

	# set variables in "${PATHS_SOFT["${software}"]}"
	eval "$2"
	version=${VERSION:+-${VERSION}}

	file_back=`ls "${PATH_BACKUP}/$1${version}_${DATEB}.${COMP_EXT}"`
	# file not found
	if ! ls "${file_back}" 1>/dev/null 2>&1; then
		_echoE "'$1' skipped: unable to find '${file_back}'"
		return 1
	fi

	_echod "${FUNCNAME}::${LINENO} \$DATEB=$DATEB"
	# existing paths
	paths_comp=`echo "${PATHS_SOFT["$1"]}"|sed -n 's|^comp_.*=\(.*\)$|\1|p'|xargs`
	# check if paths_comp exists
	for path in ${paths_comp}; do
		if [ -e "${path}" ]; then
			if [ -z "${FORCE}" ]; then
				_echoE "'$1' skipped: path exists '${path}', to delete it use option '--force'"
				return 1
			else
				[ -w "${path}" ] && cmd="sudo rm -fR '${path}'"
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
		path_from=${path_tmp}/${path#/}
		path_to=${path%/}
		cmd="sudo mv '${path_from}' '${path_to}'"
		_eval ${cmd} || _echoE "executing '${cmd}'"
	done
}

__opts() {
	_echod "${FUNCNAME}::${LINENO} IN \$@=$@"

	local opts_given="$@"
	local opts_short="afmr:v:hdq"
	local opts_long="all,force,menu,restore:,version:,help,quiet,debug"
	local opts=$(getopt -o ${opts_short} -l ${opts_long} -n "${0##*/}" -- "$@") || _exite "Wrong or missing options"
	eval set -- "${opts}" || exit 1

	_echod "${FUNCNAME}::${LINENO} opts_given=${opts_given} opts=${opts}"
	while [ "$1" != "--" ]
	do
		case "$1" in
			-a|--all)				SOFTWARES="${!PATHS_SOFT[@]}"  ;;
			-f|--force)		FORCE="force"  ;;
			-r|--restore)
				shift
				ACTION=restore
				DATEB="$1"
				;;
			-m|--menu)		MENU="menu"  ;;
			-v|--version)
				shift
				VERSION="$1"
				;;
			-h|--help)			echo "${USAGE}" && _exit 0  ;;
			-d|--debug)		_redirect debug  ;;
			*)							_exite "Wrong argument: '$1' for arguments '$opts_given'"  ;;
		esac
		shift
	done

	shift
	[ "$@" ] && SOFTWARES="$@"

	# menu
	[ "${MENU}" ] && __menu
	# no softwares
	[ -z "${SOFTWARES}" ] && _exite "You have to give softwares or the option 'all'"
	# default action
	[ -z "${ACTION}" ] && ACTION=backup

	_echod "${FUNCNAME}::${LINENO} MENU='${MENU}' FORCE='${FORCE}' REGEXP='${REGEXP}' "
	_echod "${FUNCNAME}::${LINENO} ACTION='${ACTION}' SOFTWARES='${SOFTWARES}' DATEB='${DATEB}'"
}

__main() {
	_echod "======================================================"
	_echod "$(ps -o args= $PPID)"

	local PATH_BACKUP DATEB ACTION SOFTWARES

	# array for softwares definition
	declare -A PATHS_SOFT
	# path to backup/resore
	[ -d ${HOME}/Soft/multi ] && PATH_BACKUP=${HOME}/Soft/multi/backup || PATH_BACKUP=/ext/shared/Soft/multi/backup
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
	__${ACTION} "${SOFTWARES}"
}

########################  MAIN

__main "$@"
_exit 0
