#!/bin/bash

# command get short from to list $path_pkg
# command to list $path_pkg
__filter() {
	echo -n "filter ${NUM}: "
	NUM=$(($NUM + 1))
	[ -e ${files_del} ] && rm ${files_del}

	shorts=`eval $1`
	for short in ${shorts}; do
		files=`eval $2`
		for file in ${files}; do
			echo "${sudo} rm ${file}*" >> ${files_del}
		done
	done

	if [ -f "${files_del}" ]; then
		echo -e "\n$(date +"%Y%m%d %T") filter ${NUM}" >> ${files_log}
		cat ${files_del} >> ${files_log}
		. ${files_del}
	fi
	echo "$(cat ${files_del} 2>/dev/null|wc -l) files deleted"
}


########################  MAIN

[ -d /var/cache/pacman/pkg ] && path_pkg=/var/cache/pacman/pkg && os=manajro
[ -d /var/cache/apt/archives ] && path_pkg=/var/cache/apt/archives && os=ubuntu
[ "${path_pkg}" ] || echo "[error]${FUNCNAME}:${LINENO} Unable to find a path"

[ "${USER}" != "root" ] && sudo="sudo"
files_log="/var/log/server/clean-pkg.info"
files_del="/tmp/pkg-del"

# filter one

NUM=1

__filter "ls -1 ${path_pkg}|grep zst\$|sed 's|^\(.*\)-[0-9\.]\+-[0-9].*|\1|'|grep -v zst|sort -ur" "ls -r1 ${path_pkg}/\${short}-[0-9]*.zst|tail -n +2"
__filter "ls -1 ${path_pkg}|grep zst\$|sed 's|^\([a-z0-9-]\+\)-[0-9].*|\1|'|grep -v zst|sort -ur" "ls -r1 ${path_pkg}/\${short}-[0-9]*.zst|tail -n +2"
__filter "ls -1 ${path_pkg}|grep zst\$|sed 's|^\(.*\)-[0-9\.]\+-[0-9].*|\1|'|grep -v zst|sort -ur" "ls -r1 ${path_pkg}/\${short}-[0-9]*.zst|tail -n +2"
__filter "ls -1 ${path_pkg}|grep zst\$|sed 's|^\(.*\)-[0-9]:[0-9].*|\1|'|grep -v zst|sort -ur" "ls -r1 ${path_pkg}/\${short}-[0-9]:[0-9]*.zst|tail -n +2"

exit

<<KEEP
num=`wc -l $files_del 2>/dev/null|cut -d' ' -f1`
[ -z "${num}" ] && echo "No files to deleted" && exit

echo -n "${num} files to delete. Confirm (y)/n " && read answer
[ "${answer}" != n ] && . ${files_del} && "${num} files deleted"
KEEP