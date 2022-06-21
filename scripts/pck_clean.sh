#!/bin/bash

path_pck="/var/cache/pacman/pkg"
path_base="/tmp"
# ls /var/cache/pacman/pkg/| sed 's|^\([-\.0-9a-z]\+\)-[0-9]\+\..*|\1| |sort -ur > /home/.tmp/pck_head_manjaro'
path_pck_head="/home/shared/repo/install-desktop/xtra/pck_head_manjaro"
path_pck_tmp="${path_base}/pck_tmp"
path_pck_del="${path_base}/pck_del"
path_pck_keep="${path_base}/pck_keep"

! [ -f "${path_pck_head}" ] && echo "Unable to find file: '${path_pck_head}'" && exit

ls "${path_pck}" | sort -ur > "${path_pck_tmp}"
for file in "${path_pck_keep}" "${path_pck_del}" ; do
	[ -f "${file}" ] && rm "${file}"
done

cat ${path_pck_head} | while read pck_var; do
	pcks=`grep "^${pck_var}" "${path_pck_tmp}"`
	pcks_count=`echo "$pcks" |wc -l`

	# unique
	if [ "${pcks_count}" = 1 ]; then
		pck="${pcks}"
		pcks_del=
	else
		pck=`echo "${pcks}"  | head -n1`
		pcks_del=`echo "${pcks}" | sed 1d`
		echo "${pcks_del}"
	fi

	# add to files
	[ "${pck}"  ] && echo "${pck}" >> "${path_pck_keep}"
	[ "${pcks_del}"  ] && echo "${pcks_del}" >> "${path_pck_del}"

	# clean path_pck_tmp
	for pck in ${pcks}; do
		sed -i "/^${pck}$/d" "${path_pck_tmp}"
	done
done

# resume
echo
echo "- all packages : $(ls "${path_pck}" | wc -l)"
echo
echo "- to keep : $(cat "${path_pck_keep}" | wc -l)"
echo "${path_pck_keep}"
echo
echo "- to delete : $(cat "${path_pck_del}" | wc -l)"
echo "${path_pck_del}"
echo
echo "sudo ls ${path_pck} | wc -l; for file in \$(cat ${path_pck_del}); do sudo rm ${path_pck}/\$file; done"
