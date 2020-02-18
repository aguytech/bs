#!/bin/bash
#
# Provides:             .bash_functions
# Short-Description:    local functions with global scope
# Description:          local functions with global scope


###########################  GLOBAL

# connect to distant server or openvz contenairs inside
__sshd() (
	local ctid ctname files file id ips ipthis ports ip name user port fqdn vm

	__ssh() {
		if [ "$2" = "${ipthis}" ]; then _echoE "You try to connect to yourself"; return 1;
		else ssh -o ConnectTimeout=3 "$1"@"$2" -p"$3"
		fi
	}

	# required source
	files="$S_GLOBAL_CONF $S_GLOBAL_FUNCTIONS_LITE"
	for file in ${files}; do ! [ -f "${file}" ] && echo -e "\e[1;31munable to load file '${file}'\e[0;0m" && exit 1 || . "${file}"; done

	declare -A ips
	declare -A ports
	ipthis=$(ifconfig eth0 | sed -n 's|^[[:space:]]\+inet \(addr:\)\?\([0-9\.]\+\) .*|\2|p')

	# get server list
	for id in ${!S_CLUSTER[*]}; do
		eval ${S_CLUSTER[$id]}
		ips["$id"]="$ip"
		ports["$id"]="$port"

		# direct connection
		if [[ "$1" = "${id}" || "$1" = "$name}" ]]; then __ssh "$user" "$ip" "$port" && return || return 1; fi
		while read ctid ctname; do
			ips["${id}.${ctid}.${ctname}"]="$ip"
			ports["${id}.${ctid}.${ctname}"]="$S_VM_PORT_SSH_PRE${ctid}"
			# direct connection
			if [[ "$1" = "${id}.${ctid}" || "$1" = "${id}.${ctid}" ]]; then __ssh "$user" "$ip" "$S_VM_PORT_SSH_PRE${ctid}" && return ||return 1; fi
		done <<< "$(ssh -o ConnectTimeout=3 ${user}@${ip} 'vzlist -Ho ctid,hostname')"
	done

	_menu "Select a VM" $(tr " " "\n" <<< ${!ips[*]} | sort | xargs)
	__ssh "$S_VM_SSH_USER" "${ips[$_ANSWER]}" "${ports[$_ANSWER]}"
)

__rsync_del() {
	local file files sucmd sym

	! [ -d "$1" ] && echo "error - unable to find source '$1'"
	! [ -d "$2" ] && echo "error - unable to find destination '$2'"

	while read file; do
		[ -f "${2%/}/$file" ] && files+="$file\n"
	done <<<$(ls "$1")

	if [ -n "$files" ]; then
		if [ "${RSYNC}" = "y" ]; then
			sym="x"
		else
			sym="o"
			echo -e "\e[0;31mprepend the command with 'RSYNC=y' to apply command\e[0;0m"
		fi

		echo -e "\e[0;34mfor ${2%/}\e[0;0m"

		while read file; do
			echo "$sym '$file'"
			[ -x "${2%/}/$file" ] && sucmd="sudo "
			[ "${RSYNC}" = "y" ] && $sucmd rm "${2%/}/$file"
		done <<<$(echo -e $files)
	else
		echo "Nothing to do"
	fi
}

__du() {
	du --max-depth=${1:-0} ${2:-.} | column -t
}

_pwd() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c14; }
_pwd32() { < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32; }

__mysql-dump-all() {
	local path db_user
	db_user=root
	[ -z ${db_pwd} ] && echo -n 'db pwd: ' && read db_pwd
	mysql -u$db_user -p$db_pwd -e 'quit' || return 1

	path=/var/share/mariadb/default/dump-all-$(grep $HOSTNAME /etc/hosts|cut -d' ' -f1)-$(date +%s)
	! [ -d $path ] && mkdir $path || return 1
	echo -e "\e[0;33m$path\e[0;0m"
	mysqldump -uroot -p$db_pwd --no-data --all-databases > ${path}/all-dbs.sql
	mysqldump -uroot -p$db_pwd --no-create-info --all-databases | gzip -c > ${path}/all-dbs-data.sql.gz
	echo -e "\e[0;33m$path\e[0;0m"
	ls -al $path
}

__mysql-dump-dbs() {
	local path db_user db_name $opt
	db_user=root
	[ -z ${db_pwd} ] && echo -n 'db pwd: ' && read db_pwd
	mysql -u$db_user -p$db_pwd -e 'quit' || return 1

	path=/var/share/mariadb/default/dump-dbs-$(grep $HOSTNAME /etc/hosts|cut -d' ' -f1)-$(date +%s)
	! [ -d $path ] && mkdir $path || return 1
	echo -e "\e[0;33m$path\e[0;0m"
	for db_name in $(mysql -u$db_user -p$db_pwd -Bse "SHOW SCHEMAS"); do
		[[ $db_name =~ _schema$ ]] && opt='--skip-lock-tables' || opt=
		echo "$db_name"
		mysqldump -uroot -p$db_pwd $db_name --no-data $opt > ${path}/${db_name}.sql
		mysqldump -uroot -p$db_pwd $db_name --no-create-info $opt | gzip -c > ${path}/${db_name}-data.sql.gz
	done
	echo -e "\e[0;33m$path\e[0;0m"
	ls -al $path
}

__mysql-dump-tbs() {
	local path db_user db_name tb_name
	db_user=root
	[ -z ${db_pwd} ] && echo -n 'db pwd: ' && read db_pwd
	[ -z ${db_name} ] && echo -n 'db name: ' && read db_name
	mysql -u$db_user -p$db_pwd $db_name -e 'quit' || return 1

	path=/var/share/mariadb/default/dump-tbs-$(grep $HOSTNAME /etc/hosts|cut -d' ' -f1)-$(date +%s)
	! [ -d $path ] && mkdir $path || return 1
	echo -e "\e[0;33m$db_name - $path\e[0;0m"
	for tb_name in $(mysql -u$db_user -p$db_pwd $db_name -Bse "SHOW TABLES"); do
		echo "$tb_name"
		mysqldump -uroot -p$db_pwd $db_name $tb_name --no-data > ${path}/${db_name}-${tb_name}.sql
		mysqldump -uroot -p$db_pwd $db_name $tb_name --no-create-info | gzip -c > ${path}/${db_name}-${tb_name}-data.sql.gz
	done
	echo -e "\e[0;33m$path\e[0;0m"
	ls -al $path
}

###########################  OPENVZ

# ssh on Openvz
__svz() (
	! type vzlist >/dev/null 2>&1 && echo "Missing command vzlist" && return 1
	local files file ctid ctname timeout

	timeout=3

	 # required source
	files="$S_GLOBAL_CONF $S_GLOBAL_FUNCTIONS_LITE"
	for file in ${files}; do ! [ -f "${file}" ] && echo -e "\e[1;31munable to load file '${file}'\e[0;0m" && return 1 || . "${file}"; done

	if [ "$1" ]; then ssh -o ConnectTimeout=$timeout root@$_VM_IP_BASE.$1; return 0; fi
	while read ctid ctname; do
		menu+="${ctid}.${ctname} "
	done <<< "$(vzlist -Ho ctid,hostname)"

	_menu "Select a VM" ${menu%* }
	ssh -o ConnectTimeout=$timeout $S_VM_SSH_USER@$_VM_IP_BASE.${_ANSWER%%.*} -p$S_VM_SSH_PORT
)

#rsync host with all running VMs
__rsynchv() (
	! type vzlist >/dev/null 2>&1 && echo "Missing command vzlist" && return 1
	opts="--exclude=/install/xtra/conf/ssl --exclude=/install/xtra/conf/ssh -av --delete"
	for ctid in $(vzlist -Ho ctid|xargs); do
		echo "${ctid}"
		rsync /usr/local/bs/ root@10.0.0.${ctid}:/usr/local/bs/ $opts
	done
)
__rsynchvn() (
	! type vzlist >/dev/null 2>&1 && echo "Missing command vzlist" && return 1
	opts="--exclude=/install/xtra/conf/ssl --exclude=/install/xtra/conf/ssh -av --delete -n"
	for ctid in $(vzlist -Ho ctid|xargs); do
		echo "${ctid}"
		#rsync /usr/local/bs/ root@10.0.0.${ctid}:/usr/local/bs/ --exclude=/install/xtra/conf/ssl -av --delete -n
		rsync /usr/local/bs/ /vm/root/${ctid}/usr/local/bs/ $opts
	done
)
