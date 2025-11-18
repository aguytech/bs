#!/bin/bash

pth_pck="/var/cache/pacman/pkg"
pth_base="/tmp"
# ls /var/cache/pacman/pkg/| sed 's|^\([-\.0-9a-z]\+\)-[0-9]\+\..*|\1| |sort -ur > /home/.tmp/pck_head_manjaro'
pth_pck_head="/home/shared/repo/install-desktop/xtra/pck_head_manjaro"
pth_pck_tmp="${pth_base}/pck_tmp"
pth_pck_del="${pth_base}/pck_del"
pth_pck_keep="${pth_base}/pck_keep"

! [ -f "${pth_pck_head}" ] && echo "Unable to find file: '${pth_pck_head}'" && exit

ls "${pth_pck}" | sort -ur > "${pth_pck_tmp}"
for file in "${pth_pck_keep}" "${pth_pck_del}" ; do
	[ -f "${file}" ] && rm "${file}"
done

cat ${pth_pck_head} | while read pck_var; do
	pcks=`grep "^${pck_var}" "${pth_pck_tmp}"`
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
	[ "${pck}"  ] && echo "${pck}" >> "${pth_pck_keep}"
	[ "${pcks_del}"  ] && echo "${pcks_del}" >> "${pth_pck_del}"

	# clean pth_pck_tmp
	for pck in ${pcks}; do
		sed -i "/^${pck}$/d" "${pth_pck_tmp}"
	done
done

# resume
echo
echo "- all packages : $(ls "${pth_pck}" | wc -l)"
echo
echo "- to keep : $(cat "${pth_pck_keep}" | wc -l)"
echo "${pth_pck_keep}"
echo
echo "- to delete : $(cat "${pth_pck_del}" | wc -l)"
echo "${pth_pck_del}"
echo
echo "sudo ls ${pth_pck} | wc -l; for file in \$(cat ${pth_pck_del}); do sudo rm ${pth_pck}/\$file; done"
