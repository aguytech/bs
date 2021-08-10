#!/bin/bash
#
# Provides:               mysql-pwd
# Short-Description:      change password for original users
# Description:            change password for original users

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

################################  VARIABLES

usage="mysql-pwd, modify password for users in database
mysql-pwd -h, --help

Options:
    --help         get usage of this command
    -d, --debug    output debugging in screen & file
    -f, --force    force command without prompting confirmation

    -h, --host     host address
    -u, --user     user name
    -p, --pwd      user password
    --percona      use pt-show-grants (from percona-toolkit) if available

Actions:
    update (users)          update passwords for only users passed in arguments
                            format list: user1 user2 ...
    update-up (user 'pwd')  update passwords for only users passed in arguments
                            with passwords given in arguments
                            format list: user1 pwd1 user2 pwd2 ... (no trailing score)
                            format list: user1 'pwd1' user2 'pwd2' ...
                            format list: 'user1' 'pwd1' 'user2' 'pwd2' ...
    update-all              update passwords for all users
    update-base             update passwords for only default 'init' users (initaly in template)

    reset (users)          reset passwords for only users passed in arguments
                           format list: user1 user2 ...
    reset-all              reset passwords for all users
    reset-base             reset passwords for only default 'init' users (initaly in template)
"

################################  FUNCTION

__connect() {
	_echod "$FUNCNAME:$LINENO db_host='${db_host}' db_user='${db_user}' db_pwd='${db_pwd}'"

	timeout 2 mysql -h${db_host} -u${db_user} -p${db_pwd} -e "" >/dev/null 2>&1
}

__exec() {
	# require argument
	_echod "$FUNCNAME:$LINENO \$*='$*'}"
	! [ "$*" ] && _exite "Internal error, function need arguments"

	# init
	file_sql="/tmp/${_SCRIPT}-$(_pwd)"
	> "$file_sql"
	declare -A users

	# get users list users_list
	__get_users "$*"

	# get users & passwords array users
	__get_pwds "$users_list"

	# get user, host , userhost
	sql_and="AND User IN ('${users_list// /\', \'}')"
	 __exec_sql "SELECT User, Host, CONCAT(QUOTE(User),'@',QUOTE(Host)) AS UserHost FROM mysql.user WHERE User <> 'debian-sys-maint' $sql_and ORDER BY User"
	while read user host user_host; do
		pwd="${users[$user]}"

		report="$report\n$user @ $host - $pwd"
		echo "SET PASSWORD FOR $user_host = PASSWORD('$pwd');" >> "$file_sql"
		_echod "$FUNCNAME:$LINENO user='$user' user_host='$user_host' pwd='$pwd'"
	done < <(echo -e "$results")

	# allow local access whitout password for innotop
	[ "${users_list/innotop/}" != "$users_list" ] && echo "SET PASSWORD FOR 'innotop'@'localhost' = PASSWORD('');" >> "$file_sql"
	#echo "FLUSH PRIVILEGES;" >> "$file_sql"

	# confirm
	cat "$file_sql"|column -t
	! $force && _askno "Confirm execution of requests, (n) to exit"
	# exit
	[ "$_ANSWER" == "n" ] && _exit

	# execute sql queries
	__exec_sql_file "$file_sql"

	# put password in mysql.user table
	__exec_add_percona

	# delete sql queries file
	rm "$file_sql"

	# report
	_echoI "$(echo -e "$report"|column -t)"
	_echoI "Keep safe above informations !"
}

__exec_add_percona() {
	! type pt-show-grants >/dev/null 2>&1 && _echo "Unable to find pt-show-grants (from percona-toolkit)" >&5 && return 1

	SQLperconaFILE="/tmp/${_SCRIPT}-percona-$(_pwd)"
	> "$SQLperconaFILE"

	# update root password with if new one exists
	[ "${users[${db_user}]}" ] && db_pwd="${users[${db_user}]}"
	_echod "$FUNCNAME:$LINENO db_pwd='${db_pwd}'"

	# update percona acces if new password
	[ "${users[percona]}" ] && _evalq "sed -i 's|^\(.*,p=\).*|\1${users[percona]}|' ~/.percona-toolkit.conf"

	# create sql file
	for user in $users_list; do
		pwd="${users[$user]}"
		_echod "$FUNCNAME:$LINENO user='$user' pwd='$pwd'"

		pt-show-grants --only $user| grep ' IDENTIFIED ' >> "$SQLperconaFILE"
	done

	# execute sql queries
	__exec_sql_file "$SQLperconaFILE" && RETURN=0 || RETURN=1

	# delete sql queries file
	rm "$SQLperconaFILE"

	return $RETURN
}

__exec_percona() {
	# require argument
	_echod "$FUNCNAME:$LINENO \$*='$*'}"
	! [ "$*" ] && _exite "Internal error, function need arguments"

	# init
	file_sql="/tmp/${_SCRIPT}-$(_pwd)"
	> "$file_sql"
	declare -A users

	# get users list users_list
	__get_users "$*"

	# get users & passwords array users
	__get_pwds "$users_list"

	for user in $users_list; do
		pwd="${users[$user]}"

		echo "-- $user - $pwd" >> "$file_sql"
		pt-show-grants --only $user|grep ' IDENTIFIED '|sed "s|^\(.* TO '$user'@'.\+' IDENTIFIED BY\) PASSWORD '.\+'\(.*\)$|\1 '$pwd'\2|" >> "$file_sql"

		_echod "$FUNCNAME:$LINENO user='$user' user_host='$user_host' pwd='$pwd'"
	done

	report="$(sed "s|.* TO '\(.\+\)'@'\(.\+\)' IDENTIFIED BY '\(.\+\)'[ |;].*|\1 @ \2 - \3|" "$file_sql"|grep ' @ '|sort|column -t)"

	# confirm
	cat "$file_sql"
	! $force && _askno "--------------------------------------------\nConfirm execution of requests, 'n' to exit"
	# exit
	[ "$_ANSWER" == "n" ] && _exit

	# execute sql queries
	 __exec_sql_file "$file_sql"

	# update percona acces if new password
	[ "${users[percona]}" ] && _evalq "sed -i 's|^\(.*,p=\).*|\1${users[percona]}|' ~/.percona-toolkit.conf"

	# delete sql queries file
	rm "$file_sql"

	# report
	_echoI "$report"
	_echoI "Keep safe above informations !"
}

__exec_sql() {
	_echod "$FUNCNAME:$LINENO \$1='$1' \$*='$*'"

	results="$(_evalq "mysql -Ns -h${db_host} -u${db_user} -p${db_pwd} -e \"$*\"|tr '\t' ' '")"
}

__exec_sql_file() {
	local ERROR
	_echod "$FUNCNAME:$LINENO \$1='$1' \$*='$*'"

	for FILE in $*; do
		if [ -f "$FILE" ]; then
			! _evalq "mysql -Ns -h${db_host} -u${db_user} -p${db_pwd} < '$FILE'" && _echoE "Error during executing sql file '$file_sql'"
		else
			ERROR="$FILE\n$ERROR"
		fi
	done

	[ "$ERROR" ] && _echoE "Following files are not available" && _echo "$ERROR"
}

__get_users() {
	_echod "$FUNCNAME:$LINENO \$1='$1' \$*='$*'"

	# get users from sgbd
	if [ "$*" == "*" ]; then
		 __exec_sql "SELECT DISTINCT User FROM mysql.user WHERE User <> 'debian-sys-maint' ORDER BY User"
		users_list="$(echo "$results"|xargs)"
	else
		users_list="$*"
	fi
	_echod "$FUNCNAME:$LINENO users_list='$users_list'"
	_echod "$FUNCNAME:$LINENO sql_and='$sql_and'"
}

__get_pwds() {
	_echod "$FUNCNAME:$LINENO \$1='$1' \$*='$*'"

	users_list="$*"

	# initalize user passwords
	if [ "${action##*-}" == "up" ]; then
		while read user; read pwd; do
			users[${user//\'/}]=${pwd//\'/}
		done < <(echo -e "${users_list// /\\n}")
		users_list=${!users[*]}
	else
		while read user; do
			# update or reset
			[ "${action%-*}" == "reset" ] && users[${user//\'/}]= || users[${user//\'/}]="$(_pwd)"
		done < <(echo -e "${users_list// /\\n}")
		users_list=${!users[*]}
	fi
	_echod "$FUNCNAME:$LINENO users_list='$users_list'"
	_echod "$FUNCNAME:$LINENO !users[*]=${!users[*]}"
	_echod "$FUNCNAME:$LINENO users[*]=${users[*]}"

}

__init() {
	_echod "$FUNCNAME:$LINENO db_host='${db_host}' db_user='${db_user}' db_pwd='${db_pwd}'"

	_askno "Give DB server address (${db_host})" && db_host=${_ANSWER:-${db_host}}
	_askno "Give DB user name (${db_user})" && db_user=${_ANSWER:-${db_user}}
	_askno "Give DB user password (${db_pwd})" && db_pwd=${_ANSWER:-${db_pwd}}
}


################################  DATA

db_host='127.0.0.1'
db_user="root"
db_pwd="?"
percona=false
force=false

! type mysql >/dev/null 2>&1 && _exite "mysql client is required !"


################################  MAIN
#_clean && _redirect debug

_echod "$FUNCNAME:$LINENO $_SCRIPT / $(date +"%d-%m-%Y %T : %N") ---- start"

opts_given="$@"
opts_short="dfh:u:p:"
opts_long="help,debug,force,percona,host:,user:,pwd:"
opts="$(getopt -o $opts_short -l $opts_long -n "${0##*/}" -- $* 2>/tmp/${0##*/})" || _exite "Bad options '$(</tmp/${0##*/})'"
eval set -- $opts

_echod "$FUNCNAME:$LINENO opts='$opts' opts_given='$opts_given'"
while true; do
	_echod "$FUNCNAME:$LINENO \$1='$1' \$*='$*'"
	case "$1" in
		--help)
			_echo "$usage"; _exit
			;;
		-d|--debug)
			_redirect debug
			;;
		-f|--force)
			force=true
			;;
		--percona)
			! type pt-show-grants >/dev/null 2>&1 && _exite "Unable to find pt-show-grants (from percona-toolkit)"

			percona=true
			;;
		-h|--host)
			shift
			( ! [ "$1" ] || [ "$1" == "--" ] ) && _exite "host requires an arguments\n${cclear}Use '$_SCRIPT --help' for help"
			db_host="$1"
			;;
		-u|--user)
			shift
			( ! [ "$1" ] || [ "$1" == "--" ] ) && _exite "user requires an arguments\n${cclear}Use '$_SCRIPT --help' for help"
			db_user="$1"
			;;
		-p|--pwd)
			shift
			( ! [ "$1" ] || [ "$1" == "--" ] ) && _exite "pwd requires an arguments\n${cclear}Use '$_SCRIPT --help' for help"
			db_pwd="$1"
			;;
		--)
			;;
		update|update-up)
			action="$1"
			shift
			! [ "$*" ] && _exite "Action '$action' needs options\n${cclear}Use '$_SCRIPT -h' for help"
			$percona && cmd="__exec_percona" || cmd="__exec"
			args="$*"
			break
			;;
		update-all)
			action="$1"
			$percona && cmd="__exec_percona" || cmd="__exec"
			args="*"
			break
			;;
		update-base)
			action="$1"
			$percona && cmd="__exec_percona" || cmd="__exec"
			args="dev http innotop percona root rootadmin roothost rootremote"
			break
			;;
		reset)
			action="$1"
			shift
			! [ "$*" ] && _exite "Action '$action' needs options\n${cclear}Use '$_SCRIPT -h' for help"
			$percona && cmd="__exec_percona" || cmd="__exec"
			args="$*"
			break
			;;
		reset-all)
			action="$1"
			$percona && cmd="__exec_percona" || cmd="__exec"
			args="*"
			break
			;;
		reset-base)
			action="$1"
			$percona && cmd="__exec_percona" || cmd="__exec"
			args="dev http innotop percona root rootadmin roothost rootremote"
			break
			;;
		*)
			[ "$1" ] && _echoE "Bad options: '$1'" && _exite "${cclear}Use '$_SCRIPT -h' for help"
			_echo "$usage" && _exit
			;;
	esac
	shift
done
_echod "$FUNCNAME:$LINENO db_host='${db_host}' db_user='${db_user}' db_pwd='${db_pwd}'"

while ! __connect; do __init; done

${cmd} "${args}"

_exit 0
