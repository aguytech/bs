#!/bin/bash
#
# Provides:             vz-clean-files
# Short-Description:    clean files in vz by deleting ortphan files in paths: vz/dump & vz/template
# Description:          clean files in vz by deleting ortphan files in paths: vz/dump & vz/template

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  MAIN

_echoD "$_SCRIPT / $(date +"%d-%m-%Y %T : %N") ---- start"

path=$S_VZ_PATH_DUMP

_echoT "clean $path"
for str in $(ls -1 $path/xtra/*.conf| sed "s|.*_\([0-9]\+-[0-9]\+\)\.conf$|\1|"); do
	if ! [ "$(find $path -maxdepth 1 -name "*$str*")" ]; then
		find $path/xtra -name "*$str*"
		find $path/xtra -name "*$str*" -exec rm {} \;
	fi
done

path=$S_VZ_PATH_DUMP_TEMPLATE

_echoT "clean $path"
for str in $(ls -1 $path/xtra/*.conf| sed "s|.*_\([0-9]\+-[0-9]\+\)\.conf$|\1|"); do
	if ! [ "$(find $path -maxdepth 1 -name "*$str*")" ]; then
		find $path/xtra -name "*$str*"
		find $path/xtra -name "*$str*" -exec rm {} \;
	fi
done

