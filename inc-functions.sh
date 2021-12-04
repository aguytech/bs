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
		local options

		_ANSWER=
		options=" y n "
		while [ "${options/ $_ANSWER }" = "$options" ]; do
			#_echo_ -n "${yellowb}$* y/n ${cclear}"
			_echo_ -n "$* (y/n): "
			read _ANSWER
			_echod
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
		local anstmp
		anstmp=
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
		local ansmenu anstmp

		PS3="$1 (by toggling options): "
		shift
		ansmenu="valid $* "
		anstmp=
		while [ "$anstmp" != valid ]; do
			echo "——————————————————————"
			select anstmp in ${ansmenu}; do [ "${anstmp::2}" == -- ] && ansmenu=${ansmenu/ ${anstmp} / ${anstmp#--} } || ansmenu=${ansmenu/ ${anstmp} / --${anstmp} }; break; done
			_echod
		done
		ansmenu=${ansmenu#valid }
		_ANSWER=$(echo ${ansmenu}|tr ' ' '\n'|sed -n '/^--/ s|--||p')
	}

	##############  KEEP

	_keepcpts() {
		if [ -r "${1}" ]; then
			[[ -e "${1}" || -h "${1}" ]] && _evalrq cp -a "${1}" "${1}.$(date +%s)"
		else
			[[ -e "${1}" || -h "${1}" ]] && _evalrq sudo cp -a "${1}" "${1}.$(date +%s)"
		fi
	}
	_keepmvts() {
		if [ -r "${1}" ]; then
			[[ -e "${1}" || -h "${1}" ]] && _evalrq mv "${1}" "${1}.$(date +%s)"
		else
			[[ -e "${1}" || -h "${1}" ]] && _evalrq sudo mv "${1}" "${1}.$(date +%s)"
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
		[ "${_INSTALL}" ] && _PATH_LOG="${S_PATH_LOG_INSTALL:-/var/log/install}"
		[ -z "${_PATH_LOG}" ] && _PATH_LOG="${S_PATH_LOG_SERVER:-/var/log/server}"
		if ! [ -d "${_PATH_LOG}" ]; then
			if [ "${USER}" = root ]; then
				mkdir -p "${_PATH_LOG}"
			else
				sudo mkdir -p "${_PATH_LOG}"
				sudo chown :1000 "${_PATH_LOG}" && sudo chmod g+rw "${_PATH_LOG}"
				sudo find "${_PATH_LOG}" -type d -exec sudo chown :1000 "{}" \; -exec sudo chmod g+rw "{}" \;
			fi
		fi

		_SF_INF="${_PATH_LOG}/${_SCRIPT}.info"
		_SF_ERR="${_PATH_LOG}/${_SCRIPT}.err"
		_SF_BUG="${_PATH_LOG}/${_SCRIPT}.debug"

		opt=${1:-${S_TRACE}}
		opt=${opt:-${S_TRACEOPT}}
		opt=${opt:-info}

		# file descriptors
		case "$opt" in
			#					sdtout													stderror									info							debug
			#					1																2													4									6
			quiet)		exec 1>>${_SF_INF}						2> >(tee -a ${_SF_ERR})		4>>${_SF_INF}		6>/dev/null  ;;
			info)			exec 1> >(tee -a ${_SF_INF})		2> >(tee -a ${_SF_ERR})		4>>${_SF_INF}		6>/dev/null  ;;
			verbose)	exec 1> >(tee -a ${_SF_INF})		2> >(tee -a ${_SF_ERR})		4>&1							6>/dev/null  ;;
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
		[ -f "${file}" ] || touch "${file}"

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

	# $1 option
	_var_replace_vars() {
		local vars

		case $1 in
			apache)
				vars="S_VM_PATH_SHARE S_RSYSLOG_PTC S_RSYSLOG_PORT _DOM_FQDN _IPTHIS _IPS_AUTH _APA_PATH_WWW _APA_ADMIN _APA_SUB _CIDR_VM" ;;
			fail2ban)
				vars="S_DOM_FQDN S_EMAIL_TECH S_HOST_PATH_LOG _IPS_IGNORED _SSH_PORT" ;;
			haproxy)
				vars="S_RSYSLOG_PORT S_SERVICE[mail] S_EMAIL_ADMIN _SOMAXCONN _HPX_PATH_SSL _HPX_CERTBOT_PORT _HPX_STATS_PORT _HPX_STATS_2_PORT S_DOM_FQDN _HPX_CT_NAME _HPX_ACCESS_USER _HPX_ACCESS_PWD _HPX_ACCESS_URI _HPX_DNS_DEFAULT _SERVER_DEFAULT" ;;
			logrotate)
				vars="S_PATH_LOG S_HOST_PATH_LOG S_VM_PATH_LOG S_PATH_LOG_INSTALL S_PATH_LOG_SERVER" ;;
			mail)
				vars="S_SERVICE[mail] S_PATH_CONF S_DOM_FQDN S_EMAIL_TECH S_EMAIL_ADMIN _MEL_PATH_SQL _MEL_PATH_SSL _MEL_PATH_VMAIL _MEL_PATH_LOCAL _MEL_PATH_SIEVE _MEL_DB_HOST _MEL_DB_NAME _MEL_DB_USER _MEL_DB_PWD _MEL_SSL_SCHEME _MEL_DB_PFA_USER _MEL_DB_PFA_PWD _MEL_CIDR _IPS_CLUSTER _MEL_VMAIL_USER _MEL_VMAIL_UID" ;;
			rspamd)
				vars="S_RSPAMD_PORT[proxy] S_RSPAMD_PORT[normal] S_RSPAMD_PORT[controller] S_CACHE_PORT _MEL_CTS_RDS _IPS_CLUSTER _MEL_CIDR _MEL_PATH_SPAM _MEL_PATH_DKIM" ;;
			mariadb)
				vars="S_DB_MARIA_PORT _MDB_VM_PATH _MDB_PATH_BINLOG _MDB_PATH_LOG _MDB_MAX_BIN_SIZE _MDB_EXPIRE_LOGS_DAYS _MDB_MASTER_ID _MDB_SLAVE_ID _MDB_REPLICATE_EXCEPT _MDB_REPLICATE_ONLY" ;;
			php)
				vars="_PHP_SERVICE _PHP_FPM_SOCK _PHP_FPM_ADMIN_SOCK _IP_HOST_VM" ;;
			pma)
				vars="_APP_URI _PMA_HOST _APP_DB_PORT _APP_DB_USER _APP_DB_PWD _APP_BLOWFISH _APP_PATH_UP _APP_PATH_DW" ;;
			rsyslog)
				vars="S_SERVICE[log] S_SERVICE[mail] S_PATH_LOG S_HOST_PATH_LOG S_VM_PATH_LOG S_RSYSLOG_PORT S_RSYSLOG_PTC" ;;
			script)
				vars="S_PATH_SCRIPT" ;;
			*)
				_exite "${FUNCNAME} Group: '${opt}' are not implemented yet" ;;
		esac

		echo ${vars}
	}

	# replace values
	# 1 path
	# * group name of variables
	_var_replace() {
		local path opt var var2
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (2): $#"
		path=$1; shift

		for opt in $*; do
			for var in `_var_replace_vars ${opt}`; do
				var2="${var/[/\\[}"; var2="${var2/]/\\]}" 	#"\\]}"
				_echod var=${var} var2=${var2}
				grep -q "${var2}" -r ${path} && grep "${var2}" -rl ${path} | xargs sed -i "s|${var2}|${!var}|g"
				#_evalr "sed -i 's|${var/[/\\[}|${!var}|g' '${path}'"
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
			_evalr systemctl -q "${1}" "${2}.service"
		elif type service >/dev/null 2>&1; then
			_evalr service "${2%.*}" "${1}"
		elif type rc-service >/dev/null 2>&1; then
			_evalr service "${2%.*}" "${1}"
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
	# * cmds
	_lxc_exec() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} wrong parameters numbers (2): $#\nfor command: $*"
		local ct=$1; shift

		_echod "${FUNCNAME}:${LINENO} lxc exec ${ct} -- sh -c \"$*\""
		lxc exec ${ct} -- sh -c "$*"
	}

	# 1 ct name
	# * cmds
	_lxc_exec_e() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} wrong parameters numbers (2): $#\nfor command: $*"
		local ct=$1; shift

		_echod "${FUNCNAME}:${LINENO} lxc exec ${ct} -- sh -c \"$*\""
		lxc exec ${ct} -- sh -c "$*" || _exite "Unable to execute on ${ct}: $*"
	}

	# 1 ct name
	# * cmds
	_lxc_execq() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} wrong parameters numbers (2): $#\nfor command: $*"
		local ct=$1; shift

		_echod "${FUNCNAME}:${LINENO} lxc exec ${ct} -- sh -c \"$*\""
		lxc exec ${ct} -- sh -c "$*" >&4 || _exite "Unable to execute on ${ct}: $*"
	}

	# 1 ct name
	# 2 path to find variables in files
	# * group name of variables
	_lxc_var_replace() {
		[ "$#" -lt 3 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (3): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local ct path opt var var2
		ct=$1; shift
		path=$1; shift

		for opt in $*; do
			for var in `_var_replace_vars ${opt}`; do
				#_lxc_exec ${ct} "sed -i 's|${var/[/\\[}|${!var}|g' ${path}"
				var2="${var/[/\\[}"; var2="${var2/]/\\]}" 	#"\\]}"
				_lxc_exec ${ct} "grep -q '${var2}' -r ${path} && grep '${var2}' -rl ${path} | xargs sed -i 's|${var2}|${!var}|g'"
			done
		done
	}

	# 1 container
	# 2 tag
	_lxc_meta_get() {
		[ "$#" -lt 2 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (2): $#"
		_echod "${FUNCNAME}:${LINENO} $*"

		lxc config metadata show $1 | sed -n "s|^ *$2: \(.*\)|\1|p"
	}

	# 1 container
	# 2 tag
	# * values
	_lxc_meta_set() {
		[ "$#" -lt 3 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (3): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local ct tag
		ct=$1; shift
		tag=$1; shift

		#_echod "${FUNCNAME}:${LINENO} ct=${ct} tag=${tag} \$*=$*"
		if lxc config metadata show ${ct} | grep -q "^ *${tag}:"; then
			lxc config metadata show ${ct} | sed "/^ *${tag}:/ s|:.*$|: $*|" | lxc config metadata edit ${ct}
		else
			lxc config metadata show ${ct} | sed "/^properties:/a\ \ ${tag}: $*" | lxc config metadata edit ${ct}
		fi
		lxc config metadata show ${ct}|grep "^ *${tag}:"
	}

	# 1 container
	# 2 tag
	# * value
	_lxc_meta_add() {
		[ "$#" -lt 3 ] && _exite "${FUNCNAME}:${LINENO} Wrong parameters numbers (3): $#"
		_echod "${FUNCNAME}:${LINENO} $*"
		local file ct tag values value
		ct=$1; shift
		tag=$1; shift

		#_echod "${FUNCNAME}:${LINENO} ct=${ct} tag=${tag} \$*=$*"
		values=`_lxc_meta_get ${ct} ${tag}`
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
		local file ct tag values value
		ct=$1; shift
		tag=$1; shift

		#_echod "${FUNCNAME}:${LINENO} ct=${ct} tag=${tag} \$*=$*"
		values=`_lxc_meta_get ${ct} ${tag}`
		for value in $*; do 	values="${values// ${value} / }"; done
		_lxc_meta_set ${ct} ${tag} ${values}
	}

}

__data() {

	# colors
	white='\e[0;0m'; red='\e[0;31m'; green='\e[0;32m'; blue='\e[0;34m'; magenta='\e[0;95m'; yellow='\e[0;93m'; cyan='\e[0;96m';
	whiteb='\e[1;1m'; redb='\e[1;31m'; greenb='\e[1;32m'; blueb='\e[1;34m'; magentab='\e[1;95m'; yellowb='\e[1;93m'; cyanb='\e[1;96m'; cclear='\e[0;0m';

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

	[ -d "${S_PATH_CONF}" ] || mkdir -p ${S_PATH_CONF}
	for file in ${S_FILE_INSTALL_CONF} ${S_FILE_INSTALL_DONE}; do
		[ -f "${file}" ] || touch ${file}
	done
	. ${S_FILE_INSTALL_CONF} # for partial install

	if ! grep -q conf-init ${S_FILE_INSTALL_DONE}; then
		# get id of first called file
		first_id="${!BASH_SOURCE[*]}" && first_id="${first_id#* }"
		path_base=`dirname "$(readlink -e "${BASH_SOURCE[${first_id}]}")"`

		file="${path_base/install-desktop/install}/conf-init.install"
		! [ -f "${file}" ] && echo ":${LINENO}[error] Unable to find file: ${file}" && exit 1
		. "${file}"
	fi

	# env
	file=${S_PATH_SCRIPT}/conf/env
	! [ -f ${file} ] && echo ":${LINENO}[error] Unable to source properly file: '${file}'" && exit 1
	. ${file}
fi

# global configuration
S_GLOBAL_CONF="${S_GLOBAL_CONF:-/etc/server/server.conf}"
[ -f "${S_GLOBAL_CONF}" ] || echo -e ":${LINENO}[error] - Unable to find file '${S_GLOBAL_CONF}' from '${BASH_SOURCE[0]}'"
. "${S_GLOBAL_CONF}"

# set global data after sourcing S_GLOBAL_CONF
__data_post

_redirect
