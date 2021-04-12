#!/bin/bash
#
# Provides:				rsync-cluster
# Short-Description:	synchronisation for cluster
# Description:			special synchronistaion for cluster & container

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  VARIABLES

usage="rsync-cluster : special synchronistaion for cluster & container
rsync-cluster --help
rsync-cluster [command] ... <options>

command :
------------------------------------------------------------------
bin		synchronize files under /usr/local/bs from this server
		to container of this server & other servers in hosting cluster

vz		synchronize files under /vz/dump & /vz/template from this server
		to other servers in hosting cluster

backup	synchronize file under /save/backup to other servers in hosting cluster


options:
------------------------------------------------------------------
--help			get informations about usage
-y,  --confirm		confirm action without prompt
-q,  --quiet		don't show any infomations except interaction informations
     --debug		output in screen & in file debug informations

-v,  --verbose		increase verbosity
-a,  --archive		archive mode; equals -rlptgoD (no -H,-A,-X)
-n,  --dry-run		perform a trial run with no changes made
-d,  --delete		delete extraneous files from destination dirs
     --delete-before	receiver deletes before transfer, not during
     --delete-during	receiver deletes during the transfer
     --delete-delay	find deletions during, delete after
     --delete-after	receiver deletes after transfer, not during
     --delete-excluded	also delete excluded files from destination dirs
"

################################  FUNCTION

# confirmation
# $1 : command
# $2 : destination
# $3 : options for command
__confirm() {
	[ "$#" != 3 ] && _exite "Missing aguments for calling __confirm() : '$*'"
	_echoD "$FUNCNAME:$LINENO \$*=$*"

	_echo "-------------------------------------------------------------------------"
	#_echoW "rsync-cluster $1${cclear} ${blueb}$HOSTNAME${cclear} => ${blueb}$2"
	[ "$3" ] && _echoW "with options : ${cclear}${white}$3"
	_echoI -n "Please confirm : y(n) ? "
	read confirm >&4
	[ "$confirm" != "y" ] && _exit
}

__bin() {
	local optgiven usage ip path

	path=$S_PATH_SCRIPT

	usage="rsync-cluster bin : synchronize files under '$path' from this server
	to container of this server & other servers in hosting cluster
rsync-cluster bin <options>

options:
------------------------------------------------------------------
--help			get informations about usage
-y,  --confirm		confirm action without prompt
-q,  --quiet		don't show any infomations except interaction informations
     --debug		output in screen & in file debug informations

-v,  --verbose		increase verbosity
-a,  --archive		archive mode; equals -rlptgoD (no -H,-A,-X)
-n,  --dry-run		perform a trial run with no changes made
-d,  --delete		delete extraneous files from destination dirs
     --delete-before	receiver deletes before transfer, not during
     --delete-during	receiver deletes during the transfer
     --delete-delay	find deletions during, delete after
     --delete-after	receiver deletes after transfer, not during
     --delete-excluded	also delete excluded files from destination dirs
"

	[[ "$S_SERVER_TYPE" != "ovh" && "$S_SERVER_TYPE" != "home" ]] && _exite "You can only run this command from ovh hosting server"

	# options
	optgiven="$*"
	optlist="--exclude-from=${S_PATH_INSTALL_XTRA}/rsync/$FUNCNAME-exclude "
	confirm=
	quiet=
	debug=

	_echoD "$FUNCNAME:$LINENO optgiven='$optgiven'"
	while [[ "$1" =~ ^(-[0-9a-zA-Z]*|--[a-z]+[-a-z]+)$ ]]; do

		if [[ "$1" =~ ^-[0-9a-zA-Z]*$ ]]; then
			opts=${1#-}; opt=${opts:0:1}; optgrp=1
		else
			opts=${1#--}; opt=$opts; optgrp=
		fi

		while [ "$opts" ]; do

			_echoD "$FUNCNAME:$LINENO IN opt='$opt' | optgrp='$optgrp' | opts='$opts' | \$1='$1' | \$*='$*'"
			_echoD "$FUNCNAME:$LINENO opt='$opt' | opts='$opts'"
			case "$opt" in
				help)
					_echo "$usage"; _exit
					;;
				y|confirm)
					confirm=y
					;;
				q|quiet)
					quiet=q
					_redirect quiet
					;;
				debug)
					debug=d
					_redirect debug
					;;
				v|verbose)
					optlist+="--verbose "
					;;
				a|archive)
					optlist+="--archive "
					;;
				n|dry-run)
					optlist+="--dry-run "
					;;
				d|delete)
					optlist+="--delete "
					;;
				delete-before|delete-after|delete-excluded|delete-during|delete-delay)
					optlist+="--$opt "
					;;
				*)
					_exite "Bad options '$opt' for call '$optgiven'"
					;;
			esac

			# options group
			[ "$optgrp" ] && opts=${opts:1} && opt=${opts:0:1} || opts=
			_echoD "$FUNCNAME:$LINENO OUT opt='$opt' | optgrp='$optgrp' | opts='$opts' | \$1='$1' | \$*='$*'"
		done

		shift
	done
	_echoD "$FUNCNAME:$LINENO opts='$opts'"

	ips=${_CLUSTER_IPS/$_IPTHIS/}
	ids=${!S_CLUSTER[*]}
	ids=${ids/$HOSTNAME/}

	_echoT "$HOSTNAME / ${S_CLUSTER[$HOSTNAME]}"
	_echo "-> cluster"
	for id in $ids; do
		_echo "       $id / ${S_CLUSTER[$id]}"
	done

	# vz
	if [ "$S_HOSTING_TYPE" == vz ]; then
		ctrun=$(vzlist -Ho ctid,hostname)
		ctstop=$(vzlist -SHo ctid|xargs)
		for ctid in $(vzlist -Ho ctid|xargs); do ips+=" $_VM_IP_BASE.$ctid";done
	# lxc
	elif [ "$S_HOSTING_TYPE" == lxd ]; then
		ctrun=$(lxc list --format=json | jq -r '.[] | select(.status == "Running") .name')
		ctstop=$(lxc list --format=json | jq -r '.[] | select(.status == "Stopped") .name')
		ips+=" $(lxc list --format=json | jq -r '.[] | select(.status == "Running").state.network.eth0.addresses[0].address')"
	fi
	_echo "-> containers"
	_echo "$ctrun"
	[ "$ctstop" ] && _echo "containers skipped (stopped) : $ctstop"

	# confirm
	[[ ! "$confirm" ]] && __confirm "$action" "$ids $ctrun" "$optlist"

	# execute
	for ip in ${ips}
	do
		_echoT "-> ${ip##*$_VM_IP_BASE}."
		_eval "rsync ${optlist} ${path}/ -e 'ssh -p${S_SSH_PORT}' root@${ip}:${path}/"
	done

}


__vz() {
	local optgiven usage ip path

	paths="$S_VZ_PATH_DUMP $S_HOSTING_PATH_SHARE"

	usage="rsync-cluster vz : synchronize file under '$paths' to other servers in hosting cluster
rsync-cluster vz <options>

options:
------------------------------------------------------------------
--help			get informations about usage
-y,  --confirm		confirm action without prompt
-q,  --quiet		don't show any infomations except interaction informations
     --debug		output in screen & in file debug informations

-v,  --verbose		increase verbosity
-a,  --archive		archive mode; equals -rlptgoD (no -H,-A,-X)
-n,  --dry-run		perform a trial run with no changes made
-d,  --delete		delete extraneous files from destination dirs
     --delete-before	receiver deletes before transfer, not during
     --delete-during	receiver deletes during the transfer
     --delete-delay	find deletions during, delete after
     --delete-after	receiver deletes after transfer, not during
     --delete-excluded	also delete excluded files from destination dirs
"

	[[ "$S_SERVER_TYPE" != "ovh" ]] && _exite "You can only run this command from ovh hosting server"

	# options
	optgiven="$*"
	optlist="--exclude-from=${S_PATH_INSTALL_XTRA}/rsync/$FUNCNAME-exclude "
	confirm=
	quiet=
	debug=

	_echoD "$FUNCNAME:$LINENO optgiven='$optgiven'"
	while [[ "$1" =~ ^(-[0-9a-zA-Z]*|--[a-z]+[-a-z]+)$ ]]; do

		if [[ "$1" =~ ^-[0-9a-zA-Z]*$ ]]; then
			opts=${1#-}; opt=${opts:0:1}; optgrp=1
		else
			opts=${1#--}; opt=$opts; optgrp=
		fi

		while [ "$opts" ]; do

			_echoD "$FUNCNAME:$LINENO IN opt='$opt' | optgrp='$optgrp' | opts='$opts' | \$1='$1' | \$*='$*'"
			_echoD "$FUNCNAME:$LINENO opt='$opt' | opts='$opts'"
			case "$opt" in
				help)
					_echo "$usage"; _exit
					;;
				y|confirm)
					confirm=y
					;;
				q|quiet)
					quiet=q
					_redirect quiet
					;;
				debug)
					debug=d
					_redirect debug
					;;
				v|verbose)
					optlist+="--verbose "
					;;
				a|archive)
					optlist+="--archive "
					;;
				n|dry-run)
					optlist+="--dry-run "
					;;
				d|delete)
					optlist+="--delete "
					;;
				delete-before|delete-after|delete-excluded|delete-during|delete-delay)
					optlist+="--$opt "
					;;
				*)
					_exite "Bad options '$opt' for call '$optgiven'"
					;;
			esac

			# options group
			[ "$optgrp" ] && opts=${opts:1} && opt=${opts:0:1} || opts=
			_echoD "$FUNCNAME:$LINENO OUT opt='$opt' | optgrp='$optgrp' | opts='$opts' | \$1='$1' | \$*='$*'"
		done

		shift
	done
	_echoD "$FUNCNAME:$LINENO opts='$opts'"

	# server id list
	ids=${!S_CLUSTER[*]}
	ctidsstop="$(vzlist -SHo ctid|xargs)"
	_echoT "$HOSTNAME / ${S_CLUSTER[$HOSTNAME]}"
	_echo "-> cluster"
	for id in ${ids/$HOSTNAME/}; do
		_echo "       $id / ${S_CLUSTER[$id]}"
	done

	# confirm
	[[ ! "$confirm" ]] && __confirm "$action" "${ids/$HOSTNAME/}" "$optlist"

	# execute
	for path in $paths; do
		eval ${S_CLUSTER[$id]}

		_echoT "---------  $path"
		for id in ${ids/$HOSTNAME/}; do
			_echoT "-> $id / ${S_CLUSTER[$id]}"
			_eval  "rsync ${optlist} ${path}/ -e 'ssh -p${port}' ${user}@${ip}:${path}/"
		done
	done

}

__backup() {
	local optgiven usage ip path

	path=$S_PATH_SAVE_BACKUP

	usage="rs backup : synchronize file under '$path' to other servers in hosting cluster
rs backup <options>

options:
------------------------------------------------------------------
--help			get informations about usage
-y,  --confirm		confirm action without prompt
-q,  --quiet		don't show any infomations except interaction informations
     --debug		output in screen & in file debug informations

-v,  --verbose		increase verbosity
-a,  --archive		archive mode; equals -rlptgoD (no -H,-A,-X)
-n,  --dry-run		perform a trial run with no changes made
-d,  --delete		delete extraneous files from destination dirs
     --delete-before	receiver deletes before transfer, not during
     --delete-during	receiver deletes during the transfer
     --delete-delay	find deletions during, delete after
     --delete-after	receiver deletes after transfer, not during
     --delete-excluded	also delete excluded files from destination dirs
"

	[ "$S_SERVER_TYPE" != "ovh" ] && _exite "You can only run this command from ovh or home"

	# options
	optgiven="$*"
	optlist="--exclude-from=${S_PATH_INSTALL_XTRA}/rsync/$FUNCNAME-exclude "
	confirm=
	quiet=
	debug=

	_echoD "$FUNCNAME:$LINENO optgiven='$optgiven'"
	while [[ "$1" =~ ^(-[0-9a-zA-Z]*|--[a-z]+[-a-z0-9=\/]+)$ ]]; do

		if [[ "$1" =~ ^-[0-9a-zA-Z]*$ ]]; then
			opts=${1#-}; opt=${opts:0:1}; optgrp=1
		else
			opts=${1#--}; opt=$opts; optgrp=
		fi

		while [ "$opts" ]; do

			_echoD "$FUNCNAME:$LINENO IN opt='$opt' | optgrp='$optgrp' | opts='$opts' | \$1='$1' | \$*='$*'"
			_echoD "$FUNCNAME:$LINENO opt='$opt' | opts='$opts'"
			case "$opt" in
				help)
					_echo "$usage"; _exit
					;;
				y|confirm)
					confirm=y
					;;
				q|quiet)
					quiet=q
					_redirect quiet
					;;
				debug)
					debug=d
					_redirect debug
					;;
				v|verbose)
					optlist+="--verbose "
					;;
				a|archive)
					optlist+="--archive "
					;;
				n|dry-run)
					optlist+="--dry-run "
					;;
				d|delete)
					optlist+="--delete "
					;;
				exclude=*)
					optlist+="--$opt "
					;;
				delete-before|delete-after|delete-excluded|delete-during|delete-delay)
					optlist+="--$opt "
					;;
				*)
					_exite "Bad options '$opt' for call '$optgiven'"
					;;
			esac

			# options group
			[ "$optgrp" ] && opts=${opts:1} && opt=${opts:0:1} || opts=
			_echoD "$FUNCNAME:$LINENO OUT opt='$opt' | optgrp='$optgrp' | opts='$opts' | \$1='$1' | \$*='$*'"
		done

		shift
	done
	_echoD "$FUNCNAME:$LINENO opts='$opts'"

	# server id list
	ids=${!S_CLUSTER[@]}
	ctidsstop="$(vzlist -SHo ctid|xargs)"
	_echoT "$HOSTNAME / ${S_CLUSTER[$HOSTNAME]}"
	_echo "-> cluster"
	for id in ${ids/$HOSTNAME/}; do
		_echo "       $id / ${S_CLUSTER[$id]}"
	done

	# confirm
	[[ ! "$confirm" ]] && __confirm "$action" "${ids/$HOSTNAME/}" "$optlist"

	# execute
	for id in ${ids/$HOSTNAME/}; do
		eval ${S_CLUSTER[$id]}
		_echoT "-> $id / $name / $ip}"
		_eval "rsync ${optlist} ${path}/ -e 'ssh -p${port}' ${user}@${$ip}:/save/${HOSTNAME}/"
	done

}


################################  MAIN

_echoD "$_SCRIPT / $(date +"%d-%m-%Y %T : %N") ---- start"

optgiven="$*"

# action
action="$1"
shift

_echoD "$FUNCNAME:$LINENO action='$action' | \$*='$*'"

case "$action" in
	--help)
		_echo "$usage"; _exit
		;;
	bin)
		__bin "$@"
		;;
	vz)
		__vz "$@"
		;;
	backup)
		__backup "$@"
		;;
	* )
		_exite "'$action' for your call '$optgiven'"
		_echo "Usage: $_SCRIPT {bin|save|vz}"
		;;
esac

_exit 0

