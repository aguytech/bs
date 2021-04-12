#!/bin/bash
#
# Provides:             vz-dump
# Short-Description:    functions over vzdump
# Description:          functions over vzdump

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  FUNCTION

# save mounted device to path of extra dump
# $1 : CTID
# $2 : DATE
# $3 : HOSTNAMECT
__mount_dump() {
	CTID="$1"
	DATE="$2"
	HOSTNAMECT="$3"

	_echoD "$FUNCNAME:$LINENO \$*='$*'"
	_echoD "$FUNCNAME:$LINENO CTID='$CTID' DATE='$DATE' HOSTNAMECT='$HOSTNAMECT' \$*='$*'"
	[ ! "$CTID" ] && _exite "Missing ctid for calling '$0 $*'"
	[[ ! "$CTID" =~ ^[0-9]*$ && $CTID -ge $S_VM_CTID_MIN && $CTID -le $S_VM_CTID_MAX ]] && _exite "Wrong '$CTID' must be between 101-254"

	# file for mounted device exist
	if [ -e "$S_VZ_PATH_CT_CONF/$CTID.mount" ]; then

		# save configuration file
		_evalq cp "$S_VZ_PATH_CT_CONF/$CTID.conf" "$PATHDUMPXTRA/${CTID}_${HOSTNAMECT}_${DATE}.conf"
		# save configuration file for mounted device
		_evalq cp "$S_VZ_PATH_CT_CONF/$CTID.mount" "$PATHDUMPXTRA/${CTID}_${HOSTNAMECT}_${DATE}.mount"

		# save devices
		PATHSMOUNT="$(grep "^SRC=.*" "$S_VZ_PATH_CT_CONF/$CTID.mount"|sed "s/^SRC=\(.*\)/\1/"|xargs)"
		_echoD "$FUNCNAME:$LINENO PATHSMOUNT='$PATHSMOUNT'"
		for PATHMOUNT in $PATHSMOUNT; do
			PATHCHILD=${PATHMOUNT##*/}
			FILE="${CTID}_${HOSTNAMECT}_${DATE}.${PATHCHILD}.tgz"
			_echoD "$FUNCNAME:$LINENO FILE='$FILE' PATHMOUNT='$PATHMOUNT' PATHCHILD='$PATHCHILD'"
			_echoD "$FUNCNAME:$LINENO FILE='$FILE' HOSTNAMECT='$HOSTNAMECT' DATE='$DATE'"

			_evalq cd "$PATHMOUNT"
			# compress
			_evalq "tar czf "$PATHDUMPXTRA/$FILE" ."
		done
	fi

	return 0
}

# rename dump files if mounted devices existing
# $1 : CTID
# $2 : DATE
# $3 : HOSTNAMECT
__rename_dump() {
	CTID="$1"
	DATE="$2"
	HOSTNAMECT="$3"
	DATEINIT="$DATE"

	_echoD "$FUNCNAME:$LINENO CTID='$CTID' DATE='$DATE' HOSTNAMECT='$HOSTNAMECT' \$*='$*'"
	[ "$#" -lt 3 ] && _exite "Missing arguments for calling '$0 $*'"
	! [[ "$CTID" && "$CTID" =~ ^[0-9]*$ && $CTID -ge $S_VM_CTID_MIN && $CTID -le $S_VM_CTID_MAX ]] && _exite "Wrong '$CTID' must be between 101-254"

	if [ -e "$PATHDUMPXTRA/${CTID}_${HOSTNAMECT}_${DATE}.mount" ]; then
		# search file
		while [[ "$(ls $PATHDUMP/vzdump_${CTID}_${HOSTNAMECT}_*|grep ".*_${DATE}.*\.\(tar\|tgz\)$"|wc -l)" -lt 1 && "$DATE" ]]; do
			_echoD "$FUNCNAME:$LINENO search 'ls $PATHDUMP/vzdump_${CTID}_${HOSTNAMECT}_*|grep \".*_${DATE}.*\.\(tar\|tgz\)$\"|wc -l'"
			DATE=${DATE::-1}
		done

		FILE="$(ls $PATHDUMP/vzdump_${CTID}_${HOSTNAMECT}_*|grep ".*_${DATE}.*\.\(tar\|tgz\)$")"
		FILECOUNT="$(echo "$FILE"|wc -l)"
		if [ "$FILECOUNT" == 1 ]; then
			# rename file

			FILEFINAL="$(echo "$FILE"|sed "s|^\(.*_\)[0-9-]\+\(\..*\)$|\1$DATEINIT\2|")"
			if [ "$FILE" != "$FILEFINAL" ]; then
				_evalq mv "$FILE" "$FILEFINAL"
				_echoT "rename '${FILE#$PATHDUMP/}' to '${FILEFINAL#$PATHDUMP/}'"
				# log
				FILE="${FILE%.*}.log"
				FILEFINAL="${FILEFINAL%.*}.log"
				_evalq mv "$FILE" "$FILEFINAL"
				_echoT "rename '${FILE#$PATHDUMP/}' to '${FILEFINAL#$PATHDUMP/}'"
			fi

		# more than one file
		elif (( "$FILECOUNT" > 1 )); then
			_echoE "Unable to find a single good file to rename. Please correct the problem manualy with the followings files"
			ls $PATHDUMP/vzdump_${CTID}_${HOSTNAMECT}_*|grep ".*_${DATE}.*\.\(tar\|tgz\)$" >&4
		# no found
		else
			_echoE "Unable to find a good dumped device to rename it. May be a problem with dumping"
		fi

	fi
}

################################  VARIABLES

USAGE="vz-dump, function over vzdump, default selection is made only with stopped containers (use -a,all for all containers) and CONTAINER IS ALWAYS STOPPED FOR THE DUMPING except you use option --snapshot or --suspend
vz-dump --help

vz-dump [options] [ctids / all]
    ctids is a list combinating simple ids of containers and range. ex : '100 200-210'

options:
    -f, --force            force stop&start VM if running
    -R, --running          selection is made with only running containers
    -y, --confirm          confirm action without prompt
    -q, --quiet            don't show any infomations except interaction informations
    -d, --debug            output in screen & in file debug informations

    t, --template          store dumping files for template in S_VZ_PATH_DUMP_TEMPLATE

    --exclude VMID         exclude VMID (assumes --all)
    --exclude-path REGEX   exclude certain files/directories
    -x, --stdexcludes      exclude temorary files and logs

    -n, --newname          give a new name for the dump
    -c, --compress         compress dump file (gzip)
    --maxfiles N           maximal number of backup files per VM
    --script FILENAME      execute hook script
    --storage STORAGE_ID   store resulting files to STORAGE_ID (PVE only)
    --tmpdir DIR           store temporary files in DIR

    --mailto EMAIL         send notification mail to EMAIL.
    --quiet                be quiet.
    -u, --suspend          suspend/resume VM when running
    -o, --snapshot         use LVM snapshot when running
    --size MB              LVM snapshot size

    --node CID            only run on pve cluster node CID
    --lockwait MINUTES    maximal time to wait for the global lock
    --stopwait MINUTES    maximal time to wait until a VM is stopped
    --bwlimit KBPS        limit I/O bandwidth; KBytes per second
"

################################  MAIN

_echod "======================================================"
_echod "$(ps -o args= $PPID)"

# openvz server
type vzctl &>/dev/null && VZCTL="vzctl" || VZCTL="/usr/sbin/vzctl"
type ${VZCTL} &>/dev/null || _exite "unable to find vzctl command"

type vzdump &>/dev/null && VZDUMP="vzdump" || VZDUMP="/usr/sbin/vzdump"
type ${VZDUMP} &>/dev/null || _exite "unable to find vzdump command"

# openvz server
type vzlist &>/dev/null && VZLIST="vzlist" || VZLIST="/usr/sbin/vzlist"
type ${VZLIST} &>/dev/null || _exite "unable to find vzlist command"

_echoD "$_SCRIPT / $(date +"%d-%m-%Y %T : %N") ---- start"

CTIDSALL="$(${VZLIST} -aHo ctid 2>/dev/null|xargs)"
CTIDRUNALL="$(${VZLIST} -Ho ctid 2>/dev/null|xargs)"
CTIDSOPT="$(${VZLIST} -SHo ctid 2>/dev/null|xargs)"
PATHDUMP="$S_VZ_PATH_DUMP"
PATHDUMPXTRA="$PATHDUMP/$S_PATH_VZ_DUMP_REL_XTRA"

OPTSGIVEN="$@"
OPTSSHORT="dcfqnoRtuyx"
OPTSLONG="help,debug,compress,force,quiet,newname,snapshot,running,template,suspend,confirm,stdexcludes"
OPTSLONG+=",exclude:,exclude-path:,dumpdir:,maxfiles:,script:,storage:,tmpdir:,mailto:,size:,node:,lockwait:,stopwait:,bwlimit"
OPTS=$(getopt -o $OPTSSHORT -l $OPTSLONG -n "${0##*/}" -- "$@" 2>/tmp/${0##*/}) || _exite "wrong options '$(</tmp/${0##*/})'"
eval set -- "$OPTS"

_echoD "$FUNCNAME:$LINENO OPTSGIVEN='$OPTSGIVEN' OPTS='$OPTS'"
while true; do
	case "$1" in
		--help)
			_echo "$USAGE"; _exit
			;;
		-d|--debug)
			_redirect debug
			;;
		-c|--compress)
			OPTSCMD+=" --compress"
			;;
		-f|--force)
			FORCE=f
			CTIDSOPT="$CTIDSALL"
			;;
		-q|--quiet)
			_redirect quiet
			OPTSCMD+=" --quiet"
			;;
		-n|--newname)
			NEWNAME=n
			;;
		-o|--snapshot)
			SNAPSHOT=s
			PATHDUMP="$S_VZ_PATH_DUMP_SNAPSHOT"
			PATHDUMPXTRA="$PATHDUMP/$S_PATH_VZ_DUMP_REL_XTRA"
			OPTSCMD+=" --snapshot --dumpdir $PATHDUMP"
			;;
		-R|--running)
			RUNNING=R
			CTIDSOPT="$CTIDRUNALL"
			;;
		-t|--template)
			PATHDUMP="$S_VZ_PATH_DUMP_TEMPLATE"
			PATHDUMPXTRA="$PATHDUMP/$S_PATH_VZ_DUMP_REL_XTRA"
			OPTSCMD+=" --dumpdir $PATHDUMP"
			;;
		-u|--suspend)
			SUSPEND=s
			PATHDUMP="$S_VZ_PATH_DUMP_SUSPEND"
			PATHDUMPXTRA="$PATHDUMP/$S_PATH_VZ_DUMP_REL_XTRA"
			OPTSCMD+=" --suspend --dumpdir $PATHDUMP"
			;;
		-y|--confirm)
			CONFIRM=y
			;;
		-x|--stdexcludes)
			OPTSCMD+=" --stdexcludes"
			;;
		--exclude|--exclude-path|--dumpdir|--maxfiles|--script|--storage|--tmpdir|--mailto|--size|--node|--lockwait|--stopwait|--bwlimit)
			OPT="$1"
			shift
			OPTSCMD+=" --$OPT $1"
			;;
		--)
			shift
			break
			;;
		*)
			_exite "Bad options: '$1' in '$OPTSGIVEN'"
			;;
	esac
	shift
done
_echoD "$FUNCNAME:$LINENO OPTSCMD='$OPTSCMD' \$*='$*'"
_echoD "$FUNCNAME:$LINENO PATHDUMP='$PATHDUMP' PATHDUMPXTRA='$PATHDUMPXTRA'"

# options for final command
[ "${OPTSCMD/ --tmpdir/}" == "$OPTSCMD" ] && OPTSCMD+=" --tmpdir $S_VZ_PATH_TMP"
_echoD "$FUNCNAME:$LINENO OPTSCMD='$OPTSCMD' \$*='$*'"

# argument missing
[ ! "$*" ] && _exite "Missing arguments"

# list initialize
[ "$*" == all ] && CTIDSELECT="$CTIDSALL" || CTIDSELECT="$(_vz_ctids_clean "$*")"

_echoD "$FUNCNAME:$LINENO CTIDSOPT='$CTIDSOPT' CTIDSELECT='$CTIDSELECT'"

if [ "$CTIDSELECT" == "$CTIDSOPT" ]; then
    CTIDCMD="$CTIDSOPT"
else
    # select final list
    for CTID in $CTIDSELECT; do
	    if [ "$CTIDSOPT" != "${CTIDSOPT/$CTID/}" ]; then
		    [ "$CTIDRUNALL" != "${CTIDRUNALL/$CTID/}" ] && (! [ "$RUNNING" ] && ! [ "$FORCE" ]) && CTIDRUN+="$CTID " || CTIDCMD+="$CTID "
	    else
		    CTIDSKIP+="$CTID "
	    fi
    done
fi

# list empty
[ ! "$CTIDCMD" ] && _exite "No valid containers for your selection '$*'"

# synthesis
_echoD "$FUNCNAME:$LINENO CTIDSKIP='$CTIDSKIP' CTIDRUN='$CTIDRUN' CTIDCMD='$CTIDCMD'"
#[ "$CTIDSKIP" ] && _echo "Containers skipped        : $CTIDSKIP"
[ "$CTIDRUN" ] && _echoE "Containers skipped (running) : $CTIDRUN"

# confirm
if [ ! "$CONFIRM" ]; then
	_echoW "Containers to dump        : ${cclear}${blueb}$CTIDCMD"
	_echoW "with options : ${cclear}${blueb}$OPTSCMD"
	_askyn "confirm ?" && [ "$_ANSWER" == "n" ] && _exit
fi

# commands
for CTID in $CTIDCMD
do
	DATE="$(date "+%Y%m%d-%H%M%S")"
	HOSTNAMECT="$(${VZLIST} -Ho hostname $CTID)"

	_echoD "$FUNCNAME:$LINENO SNAPSHOT='$SNAPSHOT' SUSPEND='$SUSPEND' all='$all' FORCE='$FORCE'"
	if ! [[ $SNAPSHOT || $SUSPEND ]]; then
        # newname
        if [ "$NEWNAME" ]; then
            HOSTNAMECTKEEP=$HOSTNAMECT
            _ask "Please give the new hostname of containers to dump ($HOSTNAMECT)"
            HOSTNAMECT=${_ANSWER:-$HOSTNAMECT}

	        _eval "${VZCTL} set $CTID --hostname $HOSTNAMECT --save"
            REHOSTNAMECT=1
        fi

        # stop
		if  ! [ "$(${VZLIST} -SH $CTID)" ]; then
			# stop containers
			_echoT "stop $CTID"
			_eval "${VZCTL} stop $CTID"
			start=1
		fi

		# dump mount
		_echoT "save device mounted"
		_eval "__mount_dump $CTID $DATE $HOSTNAMECT"
		RENAME=1
	fi

	# compact
	_echoT "compact $CTID"
	_eval "${VZCTL} compact $CTID"

	# dump
	_echoT "dump $CTID"
	_eval "${VZDUMP} $OPTSCMD $CTID"

	# rename files
	[ "$RENAME" ] && _eval "__rename_dump $CTID $DATE $HOSTNAMECT"

	# rename hostname
	[ "$REHOSTNAMECT" ] && _eval "${VZCTL} set $CTID --hostname $HOSTNAMECTKEEP --save"

	# start containers
	[ "$start" ] && _eval "${VZCTL} start $CTID"

done

_exit 0
