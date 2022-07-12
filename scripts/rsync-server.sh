#!/bin/bash
#
# Provides:                 rsync-server.sh
# Short-Description:        use rsync to specific usage
# Description:              use rsync to specific usage

######################## GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

########################  FUNCTION

__ip_name() {
	local ip name

	name=${1%:*}
	name=${name#*@}
	[ -n "$name" ] && ip=$(grep "$name" /etc/hosts | cut -f1)
	echo ${ip:-$name}
}
__port_name() {
	local port name

	name=${1%:*}
	name=${name#*@}
	[ -n "$name" ] && id=$(grep "$name" /etc/hosts | cut -f2)
	[ "$id" ] && port=`sed -n 's|.*port=\([^ ]\+\).*|\1|p' <<<${S_CLUSTER[$id]}`
	echo ${port:+"-e 'ssh -p $port' "}
}
__rsync() {
	_echod "${FUNCNAME}:${LINENO} cmd='${cmd}' from='${from}' to='${to}' exclude='${exclude}' excludefrom='${excludefrom}'"
	_echod "${FUNCNAME}:${LINENO} _IPTHIS='${_IPTHIS}' include='${include}' includefrom='${includefrom}'"
	_echod "${FUNCNAME}:${LINENO} delete='${delete}' dryrun='${dryrun}' archive='${archive}' verbose='${verbose}'"

	_opts="${opts}${archive}${verbose}${dryrun}" && _opts=${_opts:+" -${_opts}"}

	_delete=${delete:+" --delete"}

	ip_from=$(__ip_name ${from})
	ip_to=$(__ip_name ${to})
	# check origin
	[ "${ip_from}" = "${_IPTHIS}" ] && ! [ "${force}" ] && _askyn "This IP is the same as the origin, please confirm" && [ "${_ANSWER}" = "n" ] && exit 1
	# check destination
	[ "${ip_to}" = "${_IPTHIS}" ] && ! [ "${force}" ] && _askyn "This IP is the same as the destination, please confirm" && [ "${_ANSWER}" = "n" ] && exit 1

	for str in ${exclude}; do _exclude+="--exclude=\"${str}\""; done
	for str in ${excludefrom}; do _excludefrom+="--exclude-from=\"${str}\""; done
	for str in ${include}; do _include+="--include=\"${str}\""; done
	for str in ${includefrom}; do _includefrom+="--include-from=\"${str}\""; done

	#for str in ${exclude}; do _exclude+=""
	_eval "rsync${_opts}${_delete}${_exclude}${_excludefrom}${_include}${_includefrom} $(__port_name ${from})${from} $(__port_name ${to})${to}"
}

########################  VARIABLES

usage="rsync-server.sh : function over rsync to specific usage
rsync-server.sh --help

vzl [options] [ctids / all]
	ctids is a list combinating simple ids of containers and range. ex : '100 200-210'

	-a, --archive        archive mode; equals -rlptgoD (no -H,-A,-X)
	-v, --verbose        increase verbosity
	-n, --dry-run        perform a trial run with no changes made
	--delete             delete extraneous files from destination dirs
	--exclude PATTERN    exclude files matching PATTERN
	--exclude-from FILE  read exclude patterns from FILE
	--include PATTERN    don't exclude files matching PATTERN
	--include-from FILE  read include patterns from FILE

	-f, --force          don't ask confirmation (example: destination & origin IPs are the same)
	-d, --debug          output in screen & in file debug informations
"

########################  MAIN

# OUT: no options given
! [ "$*" ] && _echoE "no options given" && exit 1

cmd="__rsync"
bin_exclude="/usr/local/bs/conf/rs-bin.exc"
install_exclude="/usr/local/bs/conf/rs-install.exc"
dev_exclude="/usr/local/bs/conf/dev.exc"

ddate=`date +%s`
opts_given="$@"
opts_short="dafnvrlptogD"
opts_long="help,debug,archive,force,dry-run,verbose,delete,exclude:,exclude-from:,include:,include-from:"
opts=$(getopt -o ${opts_short} -l ${opts_long} -n "${0##*/}" -- "$@" 2>/tmp/${0##*/}-${ddate}) || _exite "$(</tmp/${0##*/}-${ddate})'"
eval set -- "${opts}"
opts=

# options
_echod "${FUNCNAME}:${LINENO} opts_given='${opts_given}' opts='${opts}'"
while true; do
	case "$1" in
		--help)
			_echo "$usage"; _exit
			;;
		-d|--debug)
			_redirect debug
			;;
		-a|--archive)
			archive="a"
			;;
		-f|--force)
			force="f"
			;;
		-n|--dry-run)
			dryrun="n"
			;;
		-v|--verbose)
			verbose="v"
			;;
		--delete)
			delete="delete"
			;;
		--exclude)
			shift
			exclude+="$1"
			;;
		--exclude-from)
			shift
			excludefrom+="$1"
			;;
		--include)
			shift
			include+="$1"
			;;
		--include-from)
			shift
			includefrom+="$1"
			;;
		-r|--recursive)
			opts+="r"
			;;
		-l|--links)
			opts+="l"
			;;
		-p|--perms)
			opts+="p"
			;;
		-t|--times)
			opts+="t"
			;;
		-o|--owner)
			opts+="o"
			;;
		-g|--group)
			opts+="g"
			;;
		-D)
			opts+="D"
			;;
		--)
			shift
			break
			;;
		*)
			_exite "Bad options: '$1' in '${opts_given}'"
			;;
	esac
	shift
done

_echod "${FUNCNAME}:${LINENO} \$*='$*'"
case "$1" in
	# dev
	ddn1|dev-desktop-node1)
		from="/home/shared/repo/"
		to="root@node1:/save/sync/dev/"
		excludefrom+="${dev_exclude}"
		;;
	dn1d|dev-node1-desktop)
		from="root@node1:/save/sync/dev/"
		to="/home/shared/repo/"
		excludefrom+="${dev_exclude}"
		;;
	ddn2|dev-desktop-node2)
		from="/home/shared/repo/"
		to="root@node2:/save/sync/dev/"
		excludefrom+="${dev_exclude}"
		;;
	dn2d|dev-node2-desktop)
		from="root@node2:/save/sync/dev/"
		to="/home/shared/repo/"
		excludefrom+="${dev_exclude}"
		;;
	# install server
	idn1|install-desktop-node1)
		from="/home/shared/repo/install/"
		to="root@node1:/usr/local/bs/install/"
		excludefrom+="${install_exclude}"
		;;
	in1d|install-node1-desktop)
		from="root@node1:/usr/local/bs/install/"
		to="/home/shared/repo/install/"
		excludefrom+="${install_exclude}"
		;;
	idn2|install-desktop-node2)
		from="/home/shared/repo/install/"
		to="root@node2:/usr/local/bs/install/"
		excludefrom+="${install_exclude}"
		;;
	in2d|install-node2-desktop)
		from="root@node2:/usr/local/bs/install/"
		to="/home/shared/repo/install/"
		excludefrom+="${install_exclude}"
		;;
	# bs
	bdn1|bin-desktop-node1)
		from="/usr/local/bs/"
		to="root@node1:/usr/local/bs/"
		excludefrom+="${bin_exclude}"
		;;
	bn1d|bin-node1-desktop)
		from="root@node1:/usr/local/bs/"
		to="/usr/local/bs/"
		excludefrom+="${bin_exclude}"
		;;
	bdn2|bin-desktop-node2)
		from="/usr/local/bs/"
		to="root@node2:/usr/local/bs/"
		excludefrom+="${bin_exclude}"
		;;
	bn2d|bin-node2-desktop)
		from="root@node2:/usr/local/bs/"
		to="/usr/local/bs/"
		excludefrom+="${bin_exclude}"
		;;
	*)
		_exite "wrong command: '$1' in '${opts_given}'"
		;;
esac
shift

# OUT: no command found
[ -z ${cmd} ] && _echoE "no command found in '${opts_given}'" && exit 1
# rest options
[ "$*" ] && _echoE "malformed command or too long, rest '$*' in '${opts_given}'" && exit 1

# call command
_eval ${cmd}

_echod "${FUNCNAME}:${LINENO} $0 END"
