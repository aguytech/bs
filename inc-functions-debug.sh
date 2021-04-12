#!/bin/bash
#
# write by Aguy

################################  FUNCTION

__function_common() {

	##############  ECHO

	# echo
	_echo() {
		echo -e "$*">&1
	}
	_echo-() {
		echo -e $*>&1
	}
	_echod() {
		_echoD "$*"
		echo -e "$(date +"%Y%m%d %T") $*" >> "${_SF_INF}"
	}

	# debug
	_echoD() {
		echo "$(date +"%Y%m%d %T") $*">&1
	}
	# error
	_echoe() {
		echo -e "[error] ${red}${*}${cclear}" >&2
	}
	_echoE() {
		echo -e "[error] ${redb}${*}${cclear}" >&2
	}

	# information
	_echoi() {
		echo -e "${yellow}${*}${cclear}">&1
	}
	_echoI() {
		echo -e "${yellowb}${*}${cclear}">&1
	}

	# title
	_echot() {
		echo -e "${blue}${*}${cclear}">&1
	}
	_echoT() {
		echo -e "${blueb}${*}${cclear}">&1
	}

	# alert
	_echoa() {
		echo -e "${magenta}${*}${cclear}">&1
	}
	_echoA() {
		echo -e "[alert] ${magentab}${*}${cclear}">&1
	}

	# only color
	_echoW() {
		echo -e "${whiteb}${*}${cclear}">&1
	}
	_echoB() {
		echo -e "${blueb}${*}${cclear}">&1
	}

	##############  EXIT

	# exit
	_exit() {
		_echoD "exit - $*"
		[ "$*" ] && exit $* || exit
	}
	# exit, with default error 1
	_exite() {
		[ "$1" ] && _echoE "$1" || _echoE "error - ${_SCRIPTFILE}"
		_echoD "exit - $*"
		[ "$2" ] && exit $2 || exit 1
	}

	##############  EVAL

	_eval() {
		_echoD "${FUNCNAME}() $*"
		eval $* >&1
	}
	_evalq() {
		_echoD "${FUNCNAME}() $*"
		eval $*>&1
	}

	##############  SOURCE

	_source() {
		local file
		for file in $*; do
			if [ -f "${file}" ]; then
				_echoD "$FUNCNAME()  '${file}'"
				. "${file}"
			else
				_echoe "$FUNCNAME() Missing file, unable to source '$file'"
			fi
		done

		_FILECONF="${S_PATH_CONF}/${S_RELEASE}-${_PART}.conf"
	}
	_require() {
		local file
		[ -z "$*" ] && _exite "Unable to source nothing"
		for file in $*; do
			! [ -f "${file}" ] && _exite "Unable to find '$file'"
			. "${file}"
		done
	}

	##############  ASK

	# ask while not answer
	_ask() {
		_ANSWER=
		while [ -z "$_ANSWER" ]; do
			_echo- -n "$*: "
			read _ANSWER
		done
	}
	# ask one time & accept no _ANSWER
	_askno() {
		_ANSWER=
		_echo- -n "$*: "
		read _ANSWER
	}
	# ask until y or n is given
	_askyn() {
		_ANSWER=
		options=" y n "
		while [ "${options/ $_ANSWER }" = "$options" ]; do
			#_echo- -n "${yellowb}$* y/n ${cclear}"
			_echo- -n "$* y/n: "
			read _ANSWER
		done
	}
	# ask $1 until a valid options $* is given
	_asks() {
		_ANSWER=
		shift
		[ -z "$*" ] && _exite "invalid options '$*' for _asks()"
		options="$*"
		while [ "${options/$_ANSWER/}" = "$options" ]; do
			_echo- -n "$1: "
			read _ANSWER
		done
	}

	##############  MENU

	# make menu with question $1 & options $*
	_menu() {
		PS3="$1: "
		shift
		select _ANSWER in $*
			do [ "$_ANSWER" ] && break || echo -e "\nTry again"
		done
	}
	# make multiselect menu with question $1 & options $* with ++ to add options
	_menua() {
		PS3="$1 (by toggling options, q to quit): "
		shift
		answer_menu="q $* "
		local anstmp
		anstmp=
		while [ "$anstmp" != q ]; do
			echo "—————————————————————————————————————————"
			select anstmp in $answer_menu; do [ "${anstmp: -2}" == ++ ] && answer_menu=${answer_menu/ $anstmp / ${anstmp%++} } || answer_menu=${answer_menu/ $anstmp / ${anstmp}++ }; break; done
		done
		answer_menu=${answer_menu#q }
		_ANSWER=$(echo "$answer_menu" |sed 's|[^ ]\+[^+] ||g' |sed 's|++||g')
		_ANSWER=${_ANSWER%% }
	}
	# make multiselect menu with question $1 & options $* with -- to remove options
	_menur() {
		local answer_menu anstmp

		PS3="$1 (by toggling options, q to quit): "
		shift
		answer_menu="q $* "
		anstmp=
		while [ "$anstmp" != q ]; do
			echo
			select anstmp in $answer_menu; do [ "${anstmp: -2}" == -- ] && answer_menu=${answer_menu/ $anstmp / ${anstmp%--} } || answer_menu=${answer_menu/ $anstmp / ${anstmp}-- }; break; done
		done
		answer_menu=${answer_menu#q }
		_ANSWER=$(echo "$answer_menu" | sed 's|[^ ]\+-- ||g')
		_ANSWER=${_ANSWER%% }
	}

	##############  KEEP

	_keepcpts() {
		[[ -e "${1}" || -h "${1}" ]] && _evalq cp -a "${1}" "${1}.keep$(date +%s)"
	}
	_keepmvts() {
		[[ -e "${1}" || -h "${1}" ]] && _evalq mv "${1}" "${1}.keep$(date +%s)"
	}

	##############  PWD

	_pwd() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c14; }
	_pwd32() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32; }

	############## IP / CTID

	_get_ip() {
		local interface
		interface="${1:-$(ip -4 -o route show to default|cut -d' ' -f5|head -n1)}"
		#ifconfig $inter | sed -n 's|^\s\+inet \(addr:\)\?\([0-9\.]\+\) .*|\2|p'
		[ "${interface}" ] && ip -4 -o address show dev ${interface}|sed 's|.*inet\s\([0-9\.]\+\)/.*|\1|'
		#[ "${interface}" ] && ip -br -4 -o address show dev ${interface}|sed 's|.*\s\+\([0-9\.]\+\)/.*|\1|'
		# for ip version >= ss190107, with -j option
		#interface=`ip -4 -j route show to default|jq -r '.[0].dev'`
		#ip -4 -j address show dev ${interface}|jq -r '.[].addr_info[0].local|select(.!=null)'
	}

	_get_ipv6() {
		local interface
		interface="${1:-$(ip -6 -o route show to default|cut -d' ' -f5|head -n1)}"
		#ifconfig ${interface} | sed -n 's|^\s\+inet6 \(addr:\)\?\([0-9a-z\:]\+\) .*128.*|\2|p'
		[ "${interface}" ] && ip -6 -o address show dev ${interface}|sed -n 's|.*inet6\s\([0-9a-z:.]\+\)/128.*|\1|p'
		#[ "${interface}" ] && ip -br -6 -o address show dev ${interface}|sed 's|.*\s\+\([0-9a-z:]\+\)/128.*|\1|'
		# for ip version >= ss190107, with -j option
		#ip -6 -j address show dev ${interface}|jq -r '.[].addr_info[0].local|select(.!=null)'
	}

	# send email with mail command
	_mail() {
		# $1 from
		# $2 to
		# $3 subject
		# $4 body
		# $5 content type
		(
		echo "From: $1"
		echo "To: $2"
		echo "Subject: $3"
		echo "MIME-Version: 1.0"
		echo "Content-Type: $(! [ "$5" ] && echo "text/plain" || echo "$5"); charset=utf-8"
		echo -e "$4"
		) | sendmail -t
	}

	# return 0 if file descriptor is open
	_fd_isopen() {
		`2>/dev/null true >&$1`
	}

	##############  REDIRECT

	_redirect() {
		local opt

		# log path
		if [ -z "$_PATH_LOG" ]; then
			[ "${_PATH_BASE/$S_PATH_INSTALL}" != "${_PATH_BASE}" ] && _PATH_LOG="$S_PATH_LOG_INSTALL" || _PATH_LOG="$S_PATH_LOG_SERVER"
		fi
		! [ -d "$_PATH_LOG" ] && mkdir -p "$_PATH_LOG"

		_SF_INF="$_PATH_LOG/${_SCRIPT}.info"
		_SF_ERR="$_PATH_LOG/${_SCRIPT}.err"
		_SF_BUG="$_PATH_LOG/${_SCRIPT}.debug"
	}
}

__function_install() {

	##############  CONF

	# 1 variable name
	# 2 optionnal file name
	_confhave() {
		local file
		file="${2:-$S_FILE_INSTALL_CONF}"
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"
		grep -q "^$1=.*" "$file"
	}

	# 1 array name
	# 2 key name
	# 3 optionnal file name
	_confhave_array() {
		local file
		file="${3:-$S_FILE_INSTALL_CONF}"
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"
		grep -q "^${1}\['${2}'\]=.*" "$file"
	}

	# 1 variable name
	# 2 optionnal file name
	_confget() {
		local file
		file="${2:-$S_FILE_INSTALL_CONF}"file=
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"

		_confhave "$1" "$file" && sed -n "s|^${1}=||p" $file | sed 's/"//g'
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confset() {
		local file
		file="${3:-$S_FILE_INSTALL_CONF}"
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"

		if _confhave "$1" "$file"; then
			sed -i "\|^$1=| c${1}=${2:+\"$2\"}" "$file"
		else
			echo "${1}=${2:+\"$2\"}" >> "$file"
		fi
	}

	# 1 array name
	# 2 key name
	# 3 value
	# 4 optionnal file name
	_confset_array() {
		local file
		file="${4:-$S_FILE_INSTALL_CONF}"
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"

		if _confhave_array "$1" "$2" "$file"; then
			sed -i "\|^${1}\['${2}'\]=| c${1}\['${2}'\]=${3:+\"$3\"}" "$file"
		else
			echo "${1}['${2}']=${3:+\"$3\"}" >> "$file"
		fi
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_havevalue() {
		local file
		file="${3:-$S_FILE_INSTALL_CONF}"
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"

		[[ " $(_confget "$1" "$file") " = *" $2 "* ]]
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_add() {
		local file str
		file="${3:-$S_FILE_INSTALL_CONF}"
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"

		_confmulti_havevalue "$1" "$2" "$file" && return 0
		str="$(tr ' ' '\n' <<<"$(_confget "$1" "$file") $2" | sort | xargs)"
		sed -i "\|^${1}=| c${1}=\"${str}\"" "$file"
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_remove() {
		local file str
		file="${3:-$S_FILE_INSTALL_CONF}"
		! [ -f "$file" ] && _exite "unable to find '$file' from $FUNCNAME"

		_confmulti_havevalue "$1" "$2" "$file" || return 0
		str=`sed "y/ /\n/;s/^${2}$//M" <<<"$(_confget "$1" "$file")" | xargs`
		sed -i "\|^${1}=| c${1}=\"${str}\"" "$file"
	}

	##############  PART

	# test idf part $1 exists in file $2
	_parthave() {
		[ -f "$2" ] && grep -q "^$1$" "$2" || (touch "$2"; return 1)
	}
	# add part $1 in conf file $2
	_partadd() {
		! _parthave "$1" "$2" && echo "$1" >> "$2" || return 0
	}

	##############  VALUE

	# unset variables
	# $1 scope: part server
	# $2 quoted variables list or '*' for all
	_var_unset() {
		local values value
		# wrong parameters number
		[ "$#" -lt 2 ] && _exite "$FUNCNAME:$LINENO Internal error, wrong parameters numbers (2): '$#'"

		case "$1" in
			part)
				[ "$*" != "*" ] && values="$(set -o posix; set|grep '^_[a-zA-Z09_-]\+' -o)"
				;;
			server)
				[ "$*" != "*" ] && values="$(set -o posix; set|grep '^S_[a-zA-Z09_-]\+' -o)"
				;;
			*)
			_exite "Bad options: '$1' in '$*'"
			;;
		esac

		for value in values; do
			unset $value
		done
	}

	# replace values
	_var_replace_www() {
		local strs str
		# wrong parameters number
		[ "$#" -lt 1 ] && _exite "$FUNCNAME:$LINENO Internal error, wrong parameters numbers (1): '$#'"

		strs="_MYDOMAIN _SUBDOMAIN _PATH_WWW S_LOG_IPV4 S_RSYSLOG_PTC S_RSYSLOG_PORT S_PATH_LOG S_HOSTING_PATH_LOG S_HOST_IPV6"
		for str in $strs; do
			_evalq "sed -i 's|$str|${!str}|g' '$1'"
		done

		# put right VM IP
		sed -i "s|_VM_IP_BASE|${_VM_IP_BASE.//\./\\\\.}|g" "$1"
		# put right host IP
		sed -i "s|S_HOST_IPV4|${S_HOST_IPV4//\./\\\\.}|g" "$1"
	}

	_var_replace() {
		local strs str
		[ "$#" -lt 1 ] && _exite "$FUNCNAME:$LINENO Internal error, wrong parameters numbers (1): '$#'"

		strs="_MYDOMAIN _SUBDOMAIN _PATH_WWW S_LOG_IPV4 S_RSYSLOG_PTC S_RSYSLOG_PORT S_PATH_LOG S_HOSTING_PATH_LOG _VM_IP_BASE S_HOST_IPV4 S_HOST_IPV6"
		for str in $strs; do
			_evalq "sed -i 's|$str|${!str}|g' '$1'"
		done
	}

	_sed_php1() {
		[ -f "$3" ]	&& sed -i "s|^;\?\(${1}\s*=\)\(.*\)$|\1 ${2} ;\2|" "$3"
	}

	_sed_maria1() {
		[ -f "$3" ]	&& sed -i "s|^#\?\(${1}\s*=\)\(.*\)$|\1 ${2} #\2|" "$3"
	}

	##############  SERVICE

	# use service or systemctl
	# $1 action
	# $2 service
	_service() {
		# wrong number of parameters
		[ "$#" -lt 2 ] && _exite "$FUNCNAME:$LINENO Internal error, missing parameters: '$#'"

	    if type systemctl >/dev/null 2>&1; then
			_evalq systemctl "${1}" "${2}.service"
	    elif type service >/dev/null 2>&1; then
	        _evalq service "${2%.*}" "${1}"
	    else
	        _exite "unable to load service"
	    fi
	}

	##############  OTHERS

	# clear password in installation files
	_clear_conf_pwd() {
		local file
		file="${1:-S_FILE_INSTALL_CONF}"
		sed -i 's|^\(_[^=]*PWD[^=]*=\).*|\1""|g' "$file"
	}
}

__function_openvz() {

	##############  OPENVZ

	_get_ctid() {
		local inter
		inter=${1:-$S_ETH}
		ifconfig $inter  | sed -n 's|^[[:space:]]\+inet \(addr:\)\?[0-9\.]\+\.\([0-9]\+\) .*|\2|p'
	}

	_vz_ctids_clean()
	{
		local ctids ctid

		for ctid in $*; do
			# test arguments
			! [[ "$ctid" =~ ^[0-9]*-[0-9]*$ || "$ctid" =~ ^[0-9]*$ ]] && return

			if [[ "$ctid" = *"-"* ]]; then
				ctids+="$(seq ${ctid%-*} ${ctid#*-} | xargs) "
			else
				ctids+="$ctid "
			fi
		done

		ctids=$(echo $ctids | tr " " "\n" | sort -nu | xargs)
		echo ${ctids/% }
	}

	_vz_ctids_inter() {
		local ctids ctid

		[ $# != 2 ] && _exite "$FUNCNAME:$LINENO missing arguments $#"
		for ctid in $2; do
			[[ " $1 " = *" $ctid "* ]] && ctids+="$ctid "
		done
		echo ${ctids/% }
	}
}

__function_obsolete() {

	_reenter() {
			local str
			str="Please exit & re-enter in the server"
			[ "$S_SERVER_TYPE" == vz ] && str="Please exit & re-enter in container '$(awk '{print $1}' < /proc/vz/veinfo)'$*"
			[ "$S_SERVER_TYPE" == kvm ] && str="Please exit & re-enter in the vm '$(ifconfig "$S_ETH" |xargs|awk '{print $7}'|sed -e 's/[a-z]*://')'$*"
			_echoI "$str"
		}

	# remove color characters
	_rmchar() {
		local str
		str=${1//\\e\[[0-1];[0-9][0-9]m/}
		echo "${str//\\e\[[0-1];[0-9]m/}"
	}

}

__data() {

	# colors
	white='\e[0;0m'; red='\e[0;31m'; green='\e[0;32m'; blue='\e[0;34m'; magenta='\e[0;35m'; yellow='\e[0;33m'
	whiteb='\e[1;1m'; redb='\e[1;31m'; greenb='\e[1;32m'; blueb='\e[1;34m'; magentab='\e[1;35m'; yellowb='\e[1;33m'; cclear='\e[0;0m'

	# defines script & path names
	if  [ "${0%*bash}" = "$0" ]; then
		_SCRIPTFILE="$0"
		_SCRIPT="$(basename "$0")"
		[ -z "$_PATH_BASE" ] && _PATH_BASE=`dirname $(readlink -e "$0")`
		_PATH_BASE_SUB="$_PATH_BASE/sub"
	fi

	# date
	_DDATE=`date "+%Y%m%d"`
	_SDDATE=`date +%s`

	# installation
	S_FILE_INSTALL_DONE="${S_PATH_CONF}/install.done"
	S_FILE_INSTALL_CONF="${S_PATH_CONF}/install.conf"

	# cluster
	_CLUSTER_IPS=`sed 'y/ /\n/' <<<${S_CLUSTER[*]} | sed -n 's/^ip=\([^ ]\?\)/\1/p' | xargs`
	_IPS_AUTH=`printf "%q\n" ${S_IPS_ADMIN} ${S_IPS_DEV} | sort -u | xargs`

	# server type
	[ ${S_SERVER_TYPE} != 'vz' ] && _IPTHIS=`_get_ip` || _IPTHIS=`_get_ip ${S_ETH}`
	[ ${S_SERVER_TYPE} != 'vz' ] && _IPTHISV6=`_get_ipv6`

	# IPs
	if [[ " lxc vz docker " = *" $S_SERVER_TYPE "* ]]; then
		_VM_IP_BASE="${_IPTHIS%.*}}"
	else
		_VM_IP_BASE=`sed -n 's|.*base=\([^ ]\+\).*|\1|p' <<<${S_ETH_VM['default']}`
	fi

	# openvz
	[ "$S_SERVER_TYPE" = "vz" ] && _CTIDTHIS=`_get_ctid`

}

################################  MAIN

if [ -z $S_INC_FUNCTIONS ]; then

	# global configuration
	S_GLOBAL_CONF="${S_GLOBAL_CONF:-/etc/server/server.conf}"
	! . "$S_GLOBAL_CONF" && echo -e "[error] - Unable to source file '$S_GLOBAL_CONF' from '${BASH_SOURCE[0]}'" && echo 1

	# init functions
	__function_common
	__function_install
	__function_openvz
	__function_obsolete

	# set global data
	__data

	# preserve sourcing directly from bash
	 [ "${0%*bash}" = "$0" ] && _redirect
fi

# singleton
S_INC_FUNCTIONS="true"
