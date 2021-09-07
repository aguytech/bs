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
	_echo-() {
		echo -e $*
	}

	# debug
	_echod() {
		echo "$(date +"%Y%m%d %T") $*" >&6
	}

	# alert
	_echoa() {
		echo -e "${magenta}$*${cclear}" >&2
	}
	_echoA() {
		echo -e "[alert] ${magentab}$*${cclear}" >&2
	}

	# error
	_echoe() {
		echo -e "[error] ${red}$*${cclear}" >&2
	}
	_echoE() {
		echo -e "[error] ${redb}$*${cclear}" >&2
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
		echo -e "${blue}$*${cclear}" >&4
	}
	_echoT() {
		echo -e "${blueb}$*${cclear}" >&4
	}

	# only color
	_echoW() {
		echo -e "${whiteb}$*${cclear}" >&4
	}
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
		[ "$1" ] && _echoE "$1" || _echoE "${_SCRIPTFILE}"
		_echod "${FUNCNAME}:${LINENO} exit - $*"
		[ "$2" ] && exit $2 || exit 1
	}

	##############  EVAL

	_eval() {
		_echod "${FUNCNAME}:${LINENO} $*"
		eval "$*"
	}
	_evalr() {
		_echod "${FUNCNAME}:${LINENO} $*"
		[ "${USER}" = root ] && eval $* || eval sudo "$*"
	}
	_evalq() {
		_echod "${FUNCNAME}:${LINENO} $*"
		eval "$*" >&4
	}
	_evalqr() {
		_echod "${FUNCNAME}:${LINENO} $*"
		[ "${USER}" = root ] && eval "$*" >&4 || eval sudo "$*" >&4
	}

	##############  SOURCE

	_source() {
		local file
		for file in $*; do
			if [ -f "${file}" ]; then
				_echod "${FUNCNAME}:${LINENO}  '${file}'"
				. "${file}"
			else
				_exite "${FUNCNAME}: Missing file, unable to source '${file}'"
			fi
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
		local options

		_ANSWER=
		options=" y n "
		while [ "${options/ $_ANSWER }" = "$options" ]; do
			#_echo- -n "${yellowb}$* y/n ${cclear}"
			_echo- -n "$* (y/n): "
			read _ANSWER
		done
	}
	# ask $1 until a valid options $* is given
	_asks() {
		local options str

		str=$1
		shift
		_ANSWER=
		[ -z "$*" ] && _exite "invalid options '$*' for _asks()"
		options=" $* "
		while [ "${options/ ${_ANSWER} }" = "$options" ]; do
			_echo- -n "${str} ($*): "
			read _ANSWER
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
	}
	# make multiselect menu with question $1 & options $* with ++ to add options
	_menua() {
		PS3="$1 (by toggling options): "
		shift
		ansmenu="valid $* "
		local anstmp
		anstmp=
		while [ "${anstmp}" != valid ]; do
			echo "——————————————————————"
			select anstmp in ${ansmenu}; do [ "${anstmp::2}" == ++ ] && ansmenu=${ansmenu/ ${anstmp} / ${anstmp#++} } || ansmenu=${ansmenu/ ${anstmp} / ++${anstmp} }; break; done
		done
		ansmenu=${ansmenu#valid }
		_ANSWER=$(echo ${ansmenu}|tr ' ' '\n'|sed -n '/^++/ s|++||p')
	}
	# make multiselect menu with question $1 & options $* with -- to remove options
	_menur() {
		local ansmenu anstmp

		PS3="$1 (by toggling options): "
		shift
		ansmenu="valid $* "
		anstmp=
		while [ "$anstmp" != valid ]; do
			echo "——————————————————————"
			select anstmp in ${ansmenu}; do [ "${anstmp::2}" == -- ] && ansmenu=${ansmenu/ ${anstmp} / ${anstmp#--} } || ansmenu=${ansmenu/ ${anstmp} / --${anstmp} }; break; done
		done
		ansmenu=${ansmenu#valid }
		_ANSWER=$(echo ${ansmenu}|tr ' ' '\n'|sed -n '/^--/ s|--||p')
	}

	##############  KEEP

	_keepcpts() {
		if [ "${USER}" = root ]; then
			[[ -e "${1}" || -h "${1}" ]] && _evalqr cp -a "${1}" "${1}.keep$(date +%s)"
		else
			[[ -e "${1}" || -h "${1}" ]] && _evalqr sudo cp -a "${1}" "${1}.keep$(date +%s)"
		fi
	}
	_keepmvts() {
		if [ "${USER}" = root ]; then
			[[ -e "${1}" || -h "${1}" ]] && _evalqr mv "${1}" "${1}.keep$(date +%s)"
		else
			[[ -e "${1}" || -h "${1}" ]] && _evalqr sudo mv "${1}" "${1}.keep$(date +%s)"
		fi
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

		# preserve sourcing directly from bash
	 	[ "${0%*bash}" != "$0" ] && echo "No file descriptors are instancied (preserving from direct bash sourcing)" >&2 && return

	 	[ "$S_REDIRECTED" ] && _echod "${FUNCNAME}:${LINENO} Already redirected" && return

		# log path
		[ "${_INSTALL}" ] && _PATH_LOG="${S_PATH_LOG_INSTALL}"
		[ -z "$_PATH_LOG" ] && _PATH_LOG="${S_PATH_LOG_SERVER}"
		if ! [ -d "${_PATH_LOG}" ]; then
			if [ "${USER}" = root ]; then
				mkdir -p "${_PATH_LOG}"
			else
				sudo mkdir -p "${_PATH_LOG}"
				sudo chown :1000 "${_PATH_LOG}" && sudo chmod g+rw "${_PATH_LOG}"
				sudo find "${_PATH_LOG}" -type d -exec sudo chown :1000 "{}" \; -exec sudo chmod g+rw "{}" \;
			fi
		fi

		_SF_INF="$_PATH_LOG/${_SCRIPT}.info"
		_SF_ERR="$_PATH_LOG/${_SCRIPT}.err"
		_SF_BUG="$_PATH_LOG/${_SCRIPT}.debug"

		opt=${1:-${S_TRACE}}
		opt=${opt:-${S_TRACEOPT}}
		opt=${opt:-info}

		# file descriptors
		case "$opt" in
			#				sdtout											stderror								info							debug
			#				1													2											4								6
			quiet)		exec 1>>${_SF_INF}					2> >(tee -a ${_SF_ERR})		4>>${_SF_INF}		6>/dev/null  ;;
			info)			exec 1> >(tee -a ${_SF_INF})		2> >(tee -a ${_SF_ERR})		4>>${_SF_INF}		6>/dev/null  ;;
			verbose)	exec 1> >(tee -a ${_SF_INF})		2> >(tee -a ${_SF_ERR})		4>&1						6>/dev/null  ;;
			debug)
				exec 1> >(tee -a ${_SF_INF} ${_SF_BUG})
				exec 2> >(tee -a ${_SF_ERR})
				exec 4>&1
				exec 6>>${_SF_BUG}
				;;
		esac

		# singleton
		S_REDIRECTED=true
	}
}

__function_install() {

	##############  CONF

	# 1 variable name
	# 2 optionnal file name
	_confhave() {
		local file
		file="${2:-${S_FILE_INSTALL_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		grep -q "^$1=.*" "${file}"
	}

	# 1 array name
	# 2 key name
	# 3 optionnal file name
	_confhave_array() {
		local file
		file="${3:-${S_FILE_INSTALL_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		grep -q "^${1}\[${2}\]=.*" "${file}"
	}

	# 1 variable name
	# 2 optionnal file name
	_confget() {
		local file
		file="${2:-${S_FILE_INSTALL_CONF}}"file=
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		#! [ -f "${file}" ] && return 1

		_confhave "$1" "${file}" && sed -n "s|^${1}=||p" ${file} | sed 's/"//g'
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confset() {
		local file
		file="${3:-${S_FILE_INSTALL_CONF}}"
		#! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		! [ -f "${file}" ] && touch "${file}"

		if _confhave "$1" "${file}"; then
			sed -i "\|^$1=| c${1}=${2:+\"$2\"}" "${file}"
		else
			echo "${1}=${2:+\"$2\"}" >> "${file}"
		fi
	}

	# 1 array name
	# 2 key name
	# 3 value
	# 4 optionnal file name
	_confset_array() {
		local file
		file="${4:-${S_FILE_INSTALL_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"

		if _confhave_array "$1" "$2" "${file}"; then
			sed -i "\|^${1}\[${2}\]=| c${1}\[${2}\]=${3:+\"$3\"}" "${file}"
		else
			echo "${1}[${2}]=${3:+\"$3\"}" >> "${file}"
		fi
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_havevalue() {
		local file
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"
		file="${3:-${S_FILE_INSTALL_CONF}}"

		[[ " $(_confget "$1" "${file}") " = *" $2 "* ]]
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_add() {
		local file str
		file="${3:-${S_FILE_INSTALL_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"

		_confmulti_havevalue "$1" "$2" "${file}" && return 0
		str="$(tr ' ' '\n' <<<"$(_confget "$1" "${file}") $2" | sort | xargs)"
		sed -i "\|^${1}=| c${1}=\"${str}\"" "${file}"
	}

	# 1 variable name
	# 2 variable value
	# 3 optionnal file name
	_confmulti_remove() {
		local file str
		file="${3:-${S_FILE_INSTALL_CONF}}"
		! [ -f "${file}" ] && _exite "unable to find '${file}' from ${FUNCNAME}"

		_confmulti_havevalue "$1" "$2" "${file}" || return 0
		str=`sed "y/ /\n/;s/^${2}$//M" <<<"$(_confget "$1" "${file}")" | xargs`
		sed -i "\|^${1}=| c${1}=\"${str}\"" "${file}"
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

	##############  VALUE

	# unset variables
	# $1 scope: part server
	# $2 quoted variables list or '*' for all
	_var_unset() {
		local values value
		# wrong parameters number
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (2): $#"

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
	# 1 file
	# * group name of variables
	_var_replace() {
		local file opt vars var
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (2): $#"
		file=$1; shift

		for opt in $*; do

			case ${opt} in
				apache)
					vars="_DOMAIN_FQDN S_RSYSLOG_PTC S_RSYSLOG_PORT _IPTHIS _IPS_AUTH _APA_PATH_WWW _SUBDOMAIN _PATH_DOMAIN _CIDR_VM" ;; #  S_VM_PATH_SHARE
				haproxy)
					vars="S_RSYSLOG_PORT S_PATH_CONF_SSL _HPX_LCRYPT_PORT _HPX_STATS_PORT _HPX_STATS_2_PORT _SOMAXCONN S_DOMAIN_FQDN _DOMAIN_2_FQDN _HPX_CT_NAME _HPX_CT_2_NAME _HPX_ACCESS_USER _HPX_ACCESS_PWD _HPX_ACCESS_URI _HPX_DNS_DEFAULT _SERVER_DEFAULT" ;;
				logrotate)
					vars="S_PATH_LOG S_HOST_PATH_LOG S_VM_PATH_LOG S_PATH_LOG_INSTALL S_PATH_LOG_SERVER" ;;
				mariadb)
					vars="S_DB_MARIA_PORT _MDB_VM_PATH _MDB_PATH_BINLOG _MDB_PATH_LOG _MDB_MAX_BIN_SIZE _MDB_EXPIRE_LOGS_DAYS _MDB_MASTER_ID _MDB_SLAVE_ID _MDB_REPLICATE_EXCEPT _MDB_REPLICATE_ONLY" ;;
				php)
					vars="_PHP_SERVICE _PHP_FPM_SOCK _PHP_FPM_ADMIN_SOCK _IP_HOST_VM" ;;
				pma)
					vars="_APP_URI _PMA_HOST _APP_DB_PORT _APP_DB_USER _APP_DB_PWD _APP_BLOWFISH _APP_PATH_UP _APP_PATH_DW" ;;
				rsyslog)
					vars="S_SERVICE[log] S_PATH_LOG S_HOST_PATH_LOG S_VM_PATH_LOG S_RSYSLOG_PORT S_RSYSLOG_PTC" ;;
				script)
					vars="S_PATH_SCRIPT" ;;
				*)
					_exite "${FUNCNAME} Group: '${opt}' are not implemented yet" ;;
			esac

			for var in ${vars}; do
				_evalr "sed -i 's|${var/[/\\[}|${!var}|g' '${file}'"
				#'\\]}"
			done

		done
	}

	##############  SERVICE

	# use service or systemctl
	# $1 action
	# $2 service name
	_service() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} Internal error, missing parameters: $#"

		if type systemctl >/dev/null 2>&1; then
			_evalqr systemctl "${1}" "${2}.service"
		elif type service >/dev/null 2>&1; then
			_evalqr service "${2%.*}" "${1}"
		elif type rc-service >/dev/null 2>&1; then
			_evalqr service "${2%.*}" "${1}"
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
			pcks="${pcks/ redis-client / redis }"
			_evalr pacman -S --noconfirm --needed $pcks
		else
			_exite "${FUNCNAME}:${LINENO} Not yet implemented"
		fi
	}

	##############  OTHERS

	# clear password in installation files
	_clear_conf_pwd() {
		local file
		file="${1:-S_FILE_INSTALL_CONF}"
		sed -i 's|^\(_[^=]*PWD[^=]*=\).*|\1""|g' "${file}"
	}
}

__function_lxc() {

	# 1 ct name
	# 2 cmds
	_lxc_exec() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} wrong parameters numbers (2): $#\nfor command: $*"
		_echod "${FUNCNAME}:${LINENO} lxc exec ${1} -- sh -c \"$2\""

		lxc exec ${1} -- sh -c "$2"
	}

	# 1 ct name
	# 2 cmds
	_lxc_execq() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} wrong parameters numbers (2): $#\nfor command: $*"
		_echod "${FUNCNAME}:${LINENO} lxc exec ${1} -- sh -c \"$2\""

		lxc exec ${1} -- sh -c "$2" >&4
	}

	# 1 ct name
	# 2 path to find variables in file
	# * group name of variables
	_lxc_var_replace() {
		[ "$#" -lt 3 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (3): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local file opt vars var ct
		ct=$1; shift; file=$1; shift;

		for opt in $*; do

			case ${opt} in
				apache)
					vars="_DOMAIN_FQDN S_RSYSLOG_PTC S_RSYSLOG_PORT _IPTHIS _IPS_AUTH _APA_PATH_WWW _SUBDOMAIN _PATH_DOMAIN _CIDR_VM" ;; #  S_VM_PATH_SHARE
				haproxy)
					vars="S_RSYSLOG_PORT S_PATH_CONF_SSL _HPX_LCRYPT_PORT _HPX_STATS_PORT _HPX_STATS_2_PORT _SOMAXCONN S_DOMAIN_FQDN _DOMAIN_2_FQDN _HPX_CT_NAME _HPX_CT_2_NAME _HPX_ACCESS_USER _HPX_ACCESS_PWD _HPX_ACCESS_URI _HPX_DNS_DEFAULT _SERVER_DEFAULT" ;;
				logrotate)
					vars="S_PATH_LOG S_HOST_PATH_LOG S_VM_PATH_LOG S_PATH_LOG_INSTALL S_PATH_LOG_SERVER" ;;
				mariadb)
					vars="S_DB_MARIA_PORT _MDB_VM_PATH _MDB_PATH_BINLOG _MDB_PATH_LOG _MDB_MAX_BIN_SIZE _MDB_EXPIRE_LOGS_DAYS _MDB_MASTER_ID _MDB_SLAVE_ID _MDB_REPLICATE_EXCEPT _MDB_REPLICATE_ONLY" ;;
				php)
					vars="_PHP_SERVICE _PHP_FPM_SOCK _PHP_FPM_ADMIN_SOCK _IP_HOST_VM" ;;
				pma)
					vars="_APP_URI _PMA_HOST _APP_DB_PORT _APP_DB_USER _APP_DB_PWD _APP_BLOWFISH _APP_PATH_UP _APP_PATH_DW" ;;
				rsyslog)
					vars="S_SERVICE[log] S_PATH_LOG S_HOST_PATH_LOG S_VM_PATH_LOG S_RSYSLOG_PORT S_RSYSLOG_PTC" ;;
				script)
					vars="S_PATH_SCRIPT" ;;
				*)
					_exite "${FUNCNAME} Group: '${opt}' are not implemented yet" ;;
			esac

			for var in ${vars}; do
				#_lxc_exec ${ct} "sed -i 's|${var/[/\\[}|${!var}|g' ${file}"
				var2="${var/[/\\[}"; var2="${var2/]/\\]}" 	#"\\]}"
				_lxc_exec ${ct} "grep -q '${var2}' -r ${file} && grep '${var2}' -rl ${file} | xargs sed -i 's|${var2}|${!var}|g'"
			done

		done
	}

	# 1 ct
	__lxc_meta_path() {
		#_echod "${FUNCNAME}:${LINENO} $*"

		[ -d /lxd ] && file=/lxd/containers/$1/metadata.yaml
		if [ -z "${file}" ]; then
			[ -d "${_LXD_PATH_ROOT}" ] && file=${_LXD_PATH_ROOT}/containers/$1/metadata.yaml || _exite "Unable to find path /lxd or _LXD_PATH_ROOT"
		fi
		_evalr [ -f "${file}" ] || _exite "Unable to find file: ${file}"
	}

	# 1 container
	# 2 tag
	_lxc_meta_get() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (2): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local file

		# get file
		__lxc_meta_path $1

		_evalr "sed -n 's|^ *${2}: \(.*\)|\1|p' ${file}" | tr ',' ' '
	}

	# 1 container
	# 2 tag
	# * value
	_lxc_meta_set() {
		[ "$#" -lt 3 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (3): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local file ct tag path
		ct=$1 && shift
		tag=$1 && shift

		# get file
		__lxc_meta_path ${ct}

		if _evalr grep -q "${tag}:" ${file}; then
			_evalr "sed -i '/${tag}:/ s|:.*|: $*|' ${file}"
		else
			_evalr "sed -i '/^properties:/a\ \ ${tag}: $*' ${file}"
		fi
	}

	# 1 container
	# 2 tag
	# * value
	_lxc_meta_add() {
		[ "$#" -lt 3 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (3): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local file ct tag path values value
		ct=$1 && shift
		tag=$1 && shift

		# get file
		__lxc_meta_path ${ct}

		values=" $(_lxc_meta_get ${ct} ${tag}) "
		for value in $*; do 	values+=" ${value}"; done
		values=`echo ${values}|tr ' ' '\n'|sort -u`

		_lxc_meta_set ${ct} ${tag} ${values}
	}

	# 1 container
	# 2 tag
	# * value
	_lxc_meta_remove() {
		[ "$#" -lt 3 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (3): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local file ct tag path values value
		ct=$1 && shift
		tag=$1 && shift

		# get file
		__lxc_meta_path ${ct}

		values=" $(_lxc_meta_get ${ct} ${tag}) "
		for value in $*; do 	values="${values// ${value} / }"; done

		_lxc_meta_set ${ct} ${tag} ${values}
	}

}

__data() {

	# colors
	white='\e[0;0m'; red='\e[0;31m'; green='\e[0;32m'; blue='\e[0;34m'; magenta='\e[0;35m'; yellow='\e[0;33m'
	whiteb='\e[1;1m'; redb='\e[1;31m'; greenb='\e[1;32m'; blueb='\e[1;34m'; magentab='\e[1;35m'; yellowb='\e[1;33m'; cclear='\e[0;0m'

	# date
	_DATE=`date "+%Y%m%d"`
	_SDATE=`date +%s`

	# defines script & path names
	if  [ "${0%*bash}" = "$0" ]; then
		_SCRIPTFILE="$0"
		_SCRIPT="$(basename "$0")"
		if readlink -e / 1>/dev/null 2>&1; then
			[ -z "$_PATH_BASE" ] && _PATH_BASE=`dirname $(readlink -e "$0")`
		else
			[ -z "$_PATH_BASE" ] && _PATH_BASE=`dirname $(readlink -f "$0")`
		fi
		_PATH_BASE_SUB="$_PATH_BASE/sub"
	fi

	# IP server
	_IPTHIS=`_get_ip`
	_IPTHISV6=`_get_ipv6`
}

__data_post() {

	# cluster
	_CIDR_VM=`sed -n 's|.* s_cidr=\([^ ]*\).*|\1|p' <<<${S_HOST_VM_ETH[default]}`
	_IPS_CLUSTER=`tr ' ' '\n' <<<${S_CLUSTER[*]} | sed -n 's|^s_ip=\([^ ]*\)|\1|p' | xargs`
	_IPS_AUTH=`printf "%q\n" ${S_IPS_ADMIN} ${S_IPS_DEV} | sort -u | xargs`

}

########################  MAIN

# init functions
__function_common
__function_install
__function_lxc

# set global data
__data

# initialization for installation
if [ "${_INSTALL}" ]; then

	S_PATH_CONF=/etc/server
	S_GLOBAL_CONF=${S_PATH_CONF}/server.conf
	S_FILE_INSTALL_CONF=${S_PATH_CONF}/install.conf
	S_FILE_INSTALL_DONE=${S_PATH_CONF}/install.done
	S_PATH_SCRIPT=/usr/local/bs

	if ! [ -f ${S_FILE_INSTALL_DONE} ] || ! grep -q conf-init ${S_FILE_INSTALL_DONE}; then
		# get id of first called file
		first_id="${!BASH_SOURCE[*]}" && first_id="${first_id#* }"
		path_base=`dirname "$(readlink -e "${BASH_SOURCE[${first_id}]}")"`

		file="${path_base}/conf-init.install"
		! [ -f "${file}" ] && echo ":${LINENO}[error] Unable to find file '${file}'" && exit 1
		. "${file}"
	fi

	# env
	file=${S_PATH_SCRIPT}/conf/env
	! [ -f ${file} ] &&  echo ":${LINENO}[error] Unable to source properly file '${file}'" && exit 1
	. ${file}
fi

# global configuration
S_GLOBAL_CONF="${S_GLOBAL_CONF:-/etc/server/server.conf}"
[ -f "${S_GLOBAL_CONF}" ] || echo -e ":${LINENO}[error] - Unable to find file '${S_GLOBAL_CONF}' from '${BASH_SOURCE[0]}'"
. "${S_GLOBAL_CONF}"

# set global data after sourcing S_GLOBAL_CONF
__data_post

_redirect
