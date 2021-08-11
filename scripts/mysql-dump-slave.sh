#!/bin/bash
#
# Provides:               mysql-dump-slave
# Short-Description:      dump 'one file per database' for mysql/mariadb database
# Description:            dump 'one file per database' for mysql/mariadb database

######################## GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

########################  FUNCTION

__rotate_files() {
	for file in $(ls -1t "${path2}" | grep "^${*}-" | sed 1,$((files_max*2))d); do
		rm "$path2/$file"
	done
}

########################  DATA

_echod "\$*=$*"

files_max=30
path2="/var/share/mariadb/save"
db_user="dump"
ddate="$(date +%Y%m%d_%H%M%S)"

# get values from $* : db_pwd path2
for opt in $*; do _evalq $opt; done

_echod "db_pwd=$db_pwd | path2=$path2"

db_names=$(mysql -u$db_user -p$db_pwd -e "SHOW SLAVE STATUS \G"|grep '^\s*Replicate_Do_DB'|sed 's/^\s*Replicate_Do_DB:\s*//;s/,/ /g')

[ -z "$db_pwd" ] && echo "error- dp_pwd not defined"
[ -z "$db_names" ] && echo "error- unable to found databases to dump"

########################  MAIN

_echod "db_names=$db_names"

! [ -d "$path2" ] && mkdir -p "$path2"

for db_name in $db_names; do
	__rotate_files "$db_name"

    file="${db_name}-$(date +%Y%m%d_%H%M%S)"
    echo "$db_name"
    _eval "mysqldump -u$db_user -p$db_pwd $db_name --dump-slave --no-data > '${path2}/${file}-struct.sql'"
    _eval "mysqldump -u$db_user -p$db_pwd $db_name --dump-slave --no-create-info | gzip -c > '${path2}/${file}.sql.gz'"
done
