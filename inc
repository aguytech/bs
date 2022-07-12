#!/bin/bash
#
# write by Aguy

########################  FUNCTION

__function_common() {

	##############  ECHO

	# echo
	_echo() {
		echo -e "$*"
	}
	_echO() {
		echo -e "${whiteb}$*${cclear}"
	}
	_echo_() {
		echo -e $*
	}
	_echO_() {
		echo -e ${whiteb}$*${cclear}
	}
	# debug
	_echod() {
		echo "$(date +"%Y%m%d %T") $*" >&6
	}
	# alert
	_echoa() {
		echo -e "${yellow}$*${cclear}"
	}
	_echoA() {
		echo -e "${yellowb}$*${cclear}"
	}
	# warnning
	_echow() {
		echo -e "${magenta}$*${cclear}"
	}
	_echoW() {
		echo -e "${magentab}$*${cclear}"
	}
	# error
	_echoe() {
		echo -e "${red}$*${cclear}" >&2
	}
	_echoE() {
		echo -e "${redb}$*${cclear}" >&2
	}
	# information
	_echoi() {
		echo -e "$*" >&4
	}
	_echoI() {
		echo -e "${yellowb}$*${cclear}" >&4
	}
	# title
	_echot() {
		echo -e "${cyan}$*${cclear}" >&4
	}
	_echoT() {
		echo -e "${cyanb}$*${cclear}" >&4
	}

	# only color
	_echoB() {
		echo -e "${blueb}$*${cclear}" >&4
	}

	##############  EXIT

	# exit
	_exit() {
		_echod "${FUNCNAME}:${LINENO} exit - $*"
		[ "$*" ] && exit $* || exit
	}
	# exit, with default error 1
	_exite() {
		[ "$1" ] && _echoE "$1" || _echoE "[error] ${_SCRIPTFILE}"
		_echod "${FUNCNAME}:${LINENO} exit - $*"
		[ "$2" ] && exit $2 || exit 1
	}

	##############  EVAL

	_eval() {
		_echod "${FUNCNAME}:${LINENO} $*"
		eval "$*"
	}
	_evalq() {
		_echod "${FUNCNAME}:${LINENO} $*"
		eval "$*" >&4
	}
	_evalr() {
		_echod "${FUNCNAME}:${LINENO} $*"
		[ "${USER}" = root ] && eval $* || eval sudo "$*"
	}
	_evalrq() {
		_echod "${FUNCNAME}:${LINENO} $*"
		[ "${USER}" = root ] && eval "$*" >&4 || eval sudo "$*" >&4
	}

	##############  SOURCE

	_touch() {
		local file
		for file in $*; do
			! [ -f "${file}" ] && _evalq "${file}"
		done
	}
	_touchr() {
		local file
		for file in $*; do
			! [ -f "${file}" ] && _evalrq "${file}"
		done
	}
	_source() {
		local file
		for file in $*; do
			[ -f "${file}" ] || _exite "${FUNCNAME}: Unable to find file: ${file}"
			_echod "${FUNCNAME}:${LINENO} . ${file}"
			. "${file}" || _exite "Error during ${file} \nSee log file"
		done
	}
	_require() {
		local file
		[ -z "$*" ] && _exite "No arguments to source"
		for file in $*; do
			! [ -f "${file}" ] && _exite "${FUNCNAME}: Missing file, unable to find file '${file}'"
		done
	}
	_requirep() {
		local file
		[ -z "$*" ] && _exite "No arguments to source"
		for file in $*; do
			! [ -d "${file}" ] && _exite "${FUNCNAME}: Missing file, unable to find path '${file}'"
		done
	}

	##############  ASK

	# ask while not answer
	_ask() {
		_ANSWER=
		while [ -z "${_ANSWER}" ]; do
			_echo_ -n "$*: "
			read _ANSWER
			_echod
		done
	}
	# ask one time & accept no _ANSWER
	_askno() {
		_ANSWER=
		_echo_ -n "$*: "
		read _ANSWER
			_echod
	}
	# ask until y or n is given
	_askyn() {
		_ANSWER=
		local options=" y n "
		while [ "${options/ ${_ANSWER} }" = "${options}" ]; do
			#_echo_ -n "${yellowb}$* y/n ${cclear}"
			_echo_ -n "$* (y/n): "
			read _ANSWER
			_echod
		done
	}
	# ask $1 until a valid options $* is given
	_asks() {
		local str=$1
		shift
		_ANSWER=
		[ -z "$*" ] && _exite "invalid options '$*' for _asks()"
		local options=" $* "
		while [ "${options/ ${_ANSWER} }" = "${options}" ]; do
			_echo_ -n "${str} ($*): "
			read _ANSWER
			_echod
		done
	}

	##############  MENU

	# make menu with question $1 & options $*
	_menu() {
		PS3="$1: "
		shift
		echo "——————————————————————"
		select _ANSWER in $*; do
			[ "${_ANSWER}" ] && break || echo -e "\nTry again"
		done
		_echod
	}
	# make multiselect menu with question $1 & options $* with ++ to add options
	_menua() {
		PS3="$1 (by toggling options): "
		shift
		ansmenu="valid $* "
		local anstmp=
		while [ "${anstmp}" != valid ]; do
			echo "——————————————————————"
			select anstmp in ${ansmenu}; do [ "${anstmp::2}" == ++ ] && ansmenu=${ansmenu/ ${anstmp} / ${anstmp#++} } || ansmenu=${ansmenu/ ${anstmp} / ++${anstmp} }; break; done
			_echod
		done
		ansmenu=${ansmenu#valid }
		_ANSWER=$(echo ${ansmenu}|tr ' ' '\n'|sed -n '/^++/ s|++||p')
	}
	# make multiselect menu with question $1 & options $* with -- to remove options
	_menur() {
		PS3="$1 (by toggling options): "
		shift
		local ansmenu="valid $* "
		local anstmp=
		while [ "${anstmp}" != valid ]; do
			echo "——————————————————————"
			select anstmp in ${ansmenu}; do [ "${anstmp::2}" == -- ] && ansmenu=${ansmenu/ ${anstmp} / ${anstmp#--} } || ansmenu=${ansmenu/ ${anstmp} / --${anstmp} }; break; done
			_echod
		done
		ansmenu=${ansmenu#valid }
		_ANSWER=$(echo ${ansmenu}|tr ' ' '\n'|sed -n '/^--/ s|--||p')
	}

	##############  KEEP

	_keepcp() {
		local _su=
		[ -r "$1" ] || _su=sudo
		( ${_su} [ -e "$1" ] || ${_su} [ -h "$1" ] )  \
		&& ! ( ${_su} [ -e "$1.keep" ] || ${_su} [ -h "$1.keep" ] ) \
		&& _evalrq ${_su} cp -a "$1" "$1.keep"
	}
	_keepmv() {
		local _su=
		[ -w "$1" ] || _su=sudo
		( ${_su} [ -e "$1" ] || ${_su} [ -h "$1" ] )  \
		&& ! ( ${_su} [ -e "$1.keep" ] || ${_su} [ -h "$1.keep" ] ) \
		&& _evalrq ${_su} mv "$1" "$1.keep"
		( ${_su} [ -e "$1" ] || ${_su} [ -h "$1" ] ) && _evalrq  ${_su} rm -fR "$1"
	}

	_keepcpts() {
		local _su=
		[ -r "$1" ] || _su=sudo
		( ${_su} [ -e "$1" ] || ${_su} [ -h "$1" ] ) && _evalrq ${_su} cp -a "$1" "$1.$(date +%s)"
	}
	_keepmvts() {
		local _su=
		[ -w "$1" ] || _su=sudo
		( ${_su} [ -e "$1" ] || ${_su} [ -h "$1" ] )  && _evalrq ${_su} mv "$1" "$1.$(date +%s)"
	}

	##############  PWD

	_pwd() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c14; }
	_pwd32() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32; }

	############## IP / CTID

	_get_ip() {
		local interface="${1:-$(ip -4 -o route show to default|cut -d' ' -f5|head -n1)}"
		#ifconfig $inter | sed -n 's|^\s\+inet \(addr:\)\?\([0-9\.]\+\) .*|\2|p'
		[ "${interface}" ] && ip -4 -o address show dev ${interface}|sed 's|.*inet\s\([0-9\.]\+\)/.*|\1|'
		#[ "${interface}" ] && ip -br -4 -o address show dev ${interface}|sed 's|.*\s\+\([0-9\.]\+\)/.*|\1|'
		# for ip version >= ss190107, with -j option
		#interface=`ip -4 -j route show to default|jq -r '.[0].dev'`
		#ip -4 -j address show dev ${interface}|jq -r '.[].addr_info[0].local|select(.!=null)'
	}

	_get_ipv6() {
		local interface="${1:-$(ip -6 -o route show to default|cut -d' ' -f5|head -n1)}"
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
		[ "${_REDIRECTED}" ] && _echod "${FUNCNAME}:${LINENO} Already redirected" && return 1

		local file_info="${_PATH_LOG}/${_SCRIPT%.*}.info"
		local file_err="${_PATH_LOG}/${_SCRIPT%.*}.err"
		local file_debug="${_PATH_LOG}/${_SCRIPT%.*}.debug"

		local opt=${_TRACE:-info}

		# file descriptors
		case "${opt}" in
			#				sdtout											stderror							info							debug
			#				1													2										4								6
			quiet)		exec 1>>${file_info}					2> >(tee -a ${file_err})		4>>${file_info}		6>/dev/null  ;;
			info)			exec 1> >(tee -a ${file_info})		2> >(tee -a ${file_err})		4>>${file_info}		6>/dev/null  ;;
			verbose)	exec 1> >(tee -a ${file_info})		2> >(tee -a ${file_err})		4>&1						6>/dev/null  ;;
			debug)
				exec 1> >(tee -a ${file_info} ${file_debug})
				exec 2> >(tee -a ${file_err})
				exec 4>&1
				exec 6>>${file_debug}
				;;
		esac

		# singleton
		_REDIRECTED=true
	}
}

__function_install() {

	##############  CONF

	# 1 variable name
	# 2 optionnal file name
	_confhave() {
		local file="${2:-${_FILE_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		grep -q "^$1=.*" "${file}"
	}

	# 1 array name
	# 2 key name
	# 3 optionnal file name
	_confhave_array() {
		local file="${3:-${_FILE_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		grep -q "^$1\[$2\]=.*" "${file}"
	}

	# 1 variable name
	# 2 optionnal file name
	_confget() {
		local file="${2:-${_FILE_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		#! [ -f "${file}" ] && return 1

		_confhave "$1" "${file}" && sed -n "s|^$1=||p" ${file} | sed 's/"//g'
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confset() {
		local file="${3:-${_FILE_CONF}}"
		#! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		[ -f "${file}" ] || touch "${file}"

		if _confhave "$1" "${file}"; then
			sed -i "\|^$1=| c$1=${2:+\"$2\"}" "${file}"
		else
			echo "$1=${2:+\"$2\"}" >> "${file}"
		fi
	}

	# 1 array name
	# 2 key name
	# 3 value
	# 4 optionnal file name
	_confset_array() {
		local file="${4:-${_FILE_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"

		if _confhave_array "$1" "$2" "${file}"; then
			sed -i "\|^$1\[$2\]=| c$1\[$2\]=${3:+\"$3\"}" "${file}"
		else
			echo "$1[$2]=${3:+\"$3\"}" >> "${file}"
		fi
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_havevalue() {
		local file="${3:-${_FILE_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"

		[[ " $(_confget "$1" "${file}") " = *" $2 "* ]]
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_add() {
		local file="${3:-${_FILE_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"

		_confmulti_havevalue "$1" "$2" "${file}" && return 0
		local str="$(tr ' ' '\n' <<<"$(_confget "$1" "${file}") $2" | sort | xargs)"
		sed -i "\|^$1=| c$1=\"${str}\"" "${file}"
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_remove() {
		local file="${3:-${_FILE_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"

		_confmulti_havevalue "$1" "$2" "${file}" || return 0
		local str=`sed "y/ /\n/;s/^$2$//M" <<<"$(_confget "$1" "${file}")" | xargs`
		sed -i "\|^$1=| c$1=\"${str}\"" "${file}"
	}

	##############  PART

	# test idf part $1 exists in file $2
	_parthave() {
		! [ -f "$2" ] && touch "$2"
		grep -q "^$1$" "$2" || return 1
	}
	# add part $1 in conf file $2
	_partadd() {
		_echod "${FUNCNAME}:${LINENO} echo "$1" >> "$2""
		! _parthave "$1" "$2" && echo "$1" >> "$2" || return 0
	}

	##############  SERVICE

	# use service or systemctl
	# $1 action
	# $2 service name
	_service() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} Internal error, missing parameters: $#"

		if type systemctl >/dev/null 2>&1; then
			_evalr systemctl $1 ${2%.service}.service
		elif type service >/dev/null 2>&1; then
			_evalr service ${2%.*} $1
		elif type rc-service >/dev/null 2>&1; then
			_evalr service ${2%.*} $1
		else
			_exite "${FUNCNAME}:${LINENO} Not yet implemented"
		fi
	}

	# use adjusted installer
	# $1 packages
	_install() {
		[ "$#" -lt 1 ] && _exite "${FUNCNAME}:${LINENO} Internal error, missing parameters: $#"
		local pcks=" $* "
		# wrong number of parameters

		if type apt >/dev/null 2>&1; then
			_evalr apt install -y $*
		elif type pacman >/dev/null 2>&1; then
			pcks="${pcks/ mariadb-client / mariadb-clients }"
			pcks="${pcks/ redis-tools / redis }"
			[ "$(pacman -Ss redis|grep installed)" ] || _evalr pacman -S --noconfirm --needed ${pcks}
		else
			_exite "${FUNCNAME}:${LINENO} Not yet implemented"
		fi
	}

	_source_sub() {
		# skip perso if not found
		[ "$1" = perso ] && ! [ -f ${_PATH_BASE}/perso/perso ] && return

		if ! grep -q ^$1 ${_FILE_DONE}; then
			_echoA "\n> $1"
			local file="${_PATH_BASE}/sub/$1"
			! [ -f "${file}" ] && _exite "Unable to find file: ${file}"
			if . "${file}"; then
				echo $1 >> ${_FILE_DONE}
				_echoA "< $1\n"
				_askno "Validate to continue"
			else
				_echoE "See file log $1 for errors"
				exit
			fi
		fi
	}

}

__data() {
	# colors
	white='\e[0;0m'; red='\e[0;31m'; green='\e[0;32m'; blue='\e[0;34m'; magenta='\e[0;95m'; yellow='\e[0;93m'; cyan='\e[0;96m';
	whiteb='\e[1;1m'; redb='\e[1;31m'; greenb='\e[1;32m'; blueb='\e[1;34m'; magentab='\e[1;95m'; yellowb='\e[1;93m'; cyanb='\e[1;96m'; cclear='\e[0;0m';

	# date
	_DATE=$(date "+%Y%m%d")
	_SDATE=$(date +%s)
	_SCRIPTFILE="$( readlink -e / >/dev/null 2>&1 && readlink -e "$0" || readlink -f "$0" )"
	_SCRIPT="$(basename "$0")"
	_PATH_BS="/usr/local/bs"
	[ -d "/ext/shared/Soft/linux" ] && _PATH_SOFT=/ext/shared/Soft/linux
	[ -d "${HOME}/Soft/linux" ] && _PATH_SOFT="${HOME}/Soft/linux"
	[ -d "${_PATH_SOFT}" ] && _PATH_SOFT_BACKUP=${_PATH_SOFT}/backup
	_FILE_CONF=${_FILE_CONF:-${_PATH_CONF}/install.conf}
	_FILE_DONE=${_FILE_DONE:-${_PATH_CONF}/install.done}
	_FILE_PCK=${_PATH_CONF}/install.pck

	PATH="${HOME}/.local/bin:${PATH}"
}

########################  MAIN

# preserve sourcing directly from bash
[ "${0%*bash}" != "$0" ] && echo "No file descriptors are instancied (preserving from direct bash sourcing)" >&2 && return 1
# no root user
[ "${USER}" = root ] && echo "Do not use root user for installation" >&2 && exit 1

__function_common
__function_install
__data

for path in ${_PATH_CONF} ${_PATH_LOG}; do
	if ! [ -d "${path}" ]; then
		sudo mkdir -p ${path}
		sudo chown ${USER}:${USER} ${path}
	fi
done

for file in ${_FILE_CONF} ${_FILE_DONE}; do
	[ -f "${file}" ] || touch ${file}
done

. ${_FILE_CONF} # for partial install

# print major variables
echo > ${_PATH_CONF}/vars
while read var; do echo "${var}=\"${!var}\"" >> ${_PATH_CONF}/vars; done <<<$( compgen -v |grep '^_[A-Z]' )

_redirect
