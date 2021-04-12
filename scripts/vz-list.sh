#!/bin/bash
#
# Provides:             vz-list
# Short-Description:    functions over vzlist
# Description:          functions over vzlist

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  FUNCTION

__ctid_filter() {
	for CTID in $1; do
		[ "$ctids_all" != "${ctids_all/$CTID/}" ] && ctids_list+=" $CTID"
	done
	ctids_list=${ctids_list% }
}

################################  VARIABLES

usage="vz-list: function over vzlist, add range of ips for selecting containers id
vz-list --help

vz-list [options] [CTIDs / all]
    CTIDs is a list combinating simple ids of containers and range. ex : '100 200-210'

    -a,--all          list all available containers with missing containers
    -S, --stopped     list stopped containers
    -H, --no-header   suppress columns header
    -j, --json        output in JSON format
    -t, --no-trim     do not trim long values
    -L, --list        get possible field names
    -d, --debug       output in screen & in file debug informations

    -h, --hostname    filter CTs by hostname pattern
    -s, --sort        sort by the specified field
                      ('-field' to reverse sort order)
    -o, --output      output only specified fields

    -O, --outfield    output fields & his derivated :
        .m, maxheld
        .b, barrier
        .l, limit
        .f, fail counter
                      for diskquota : diskspace & diskinodes
        .s, soft limit
        .h, hard limit

    CTID              kmemsize
    private           lockedpages
    mount_opts        privvmpages
    origin_sample     shmpages
    hostname          numproc
    name              physpages
    smart_name        vmguarpages
    description       oomguarpages
    ostemplate        numtcpsock
    ip                numflock
    nameserver        numpty
    searchdomain      numsiginfo
    status            tcpsndbuf
    laverage          tcprcvbuf
    uptime            othersockbuf
    cpulimit          dgramrcvbuf
    cpuunits          numothersock
    cpus              dcachesize
    ioprio            numfile
    iolimit           numiptent
    iopslimit         swappages
    onboot
    bootorder         diskspace
    layout            diskinodes
    features
    vswap
    disabled
"

################################  MAIN

# openvz server
type vzlist &>/dev/null && VZLIST="vzlist" || VZLIST="/usr/sbin/vzlist"
type ${VZLIST} &>/dev/null || _exite "unable to find vzlist command"

_echoD "$FUNCNAME:$LINENO $_SCRIPT / $(date +"%d-%m-%Y %T : %N") ---- start"

ctids_all="$(${VZLIST} -aHo ctid | xargs)"
ctids_run="$(${VZLIST} -Ho ctid 2>/dev/null | xargs)"
fields_list="bootorder cpulimit cpus cpuunits CTID description disabled features hostname iolimit ioprio iopslimit ip laverage layout mount_opts name nameserver onboot origin_sample ostemplate private root searchdomain smart_name status uptime veid vm_overcommit vpsid vswap"

opts_given="$@"
opts_short="daHjLSth:s:o:O:"
opts_long="help,debug,all,no-header,json,list,stopped,no-trim,name:,sort:,output:,outfield:"
opts=$(getopt -o $opts_short -l $opts_long -n "${0##*/}" -- "$@" 2>/tmp/${0##*/}) || _exite "wrong options '$(</tmp/${0##*/})'"
eval set -- "$opts"

_echoD "$FUNCNAME:$LINENO opts_given='$opts_given' opts='$opts'"
while true; do
	case "$1" in
		--help)
			_echo "$usage"; _exit
			;;
		-d|--debug)
			_redirect debug
			;;
		-a|--all)
			opts_cmd+="-a "
			ALL=all
			;;
		-H|--no-header)
			opts_cmd+="-H "
			;;
		-j|--json)
			opts_cmd+="-j "
			;;
		-L|--list)
			opts_cmd+="-L "
			;;
		-S|--stopped)
			opts_cmd+="-S "
			;;
		-t|--no-trim)
			opts_cmd+="-t "
			;;
		-h|--name)
			shift
			opts_cmd+="-h \"$1\" "
			;;
		-s|--sort)
			shift
			opts_cmd+="-s $1 "
			;;
		-o|--output)
			shift
			opts_cmd+="-o $1 "
			;;
		-O|--outfield)
			shift
			opts_cmd+="-o ctid"
			for opt in ${1//,/ }; do
				if [[ $opt =~ ^disk.* ]]; then opts_cmd+=",$opt,$opt.s,$opt.h"
				elif [ "$fieldlist" != "${fieldlist/$opt/}" ]; then opts_cmd+=",$opt"
				else opts_cmd+=",$opt,$opt.m,$opt.b,$opt.l,$opt.f"
				fi
			done
			opts_cmd+=" "
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
opts_cmd=${opts_cmd% }
_echoD "$FUNCNAME:$LINENO opts_cmd='$opts_cmd' \$*='$*'"

# ctids in options
if [ "$*" ]; then
	 [ "$*" == "all" ] && ALL=all && ctids_list="$ctids_all" || __ctid_filter "$(_vz_ctids_clean "$*")"
fi
_echoD "$FUNCNAME:$LINENO ctids_list='$ctids_list'"

# no ctids
#[ ! "$ALL" ] && [ ! "$ctids_list" ] && _exite "no containers found for your selection: $opts_given"

# command
_eval "${VZLIST} ${opts_cmd}${ctids_list}|column -t"

_exit 0
