#!/bin/bash

# $1: file name
__get_file() {
	if [ "$os" = "ubuntu" ]; then
		echo $1|sed 's|^\([^_]\+_\).*|\1|'
	else
		echo $1|sed 's|^\(.*-\)[0-9\.]\+-[0-9].*|\1|'
		#echo $1|sed 's|^\([^-]\+-\)[0-9\.]\+-[0-9].*|\1|'
		#file_short=`echo $file|sed 's|^\(.*\)-[0-9\.]\+-.*|\1|'`
	fi
}

[ "${USER}" != "root" ] && sudo = "sudo"
os="$1"
path_pkg="/var/cache/pacman/pkg"
files_all="/tmp/pkg-all"
files_del="/tmp/pkg-del"

[ "${os}" = "ubuntu" ] && path_pkg="/var/cache/apt/archives"

# clean partialy downloaded files
${sudo} rm ${path_pkg}/*.part

files=`ls -r1 ${path_pkg}`
#files=`ls -r1 /var/cache/pacman/pkg|sed 's|^\(.*\)-[0-9\.]\+-[0-9].*|\1|'`
echo > ${files_all}
echo > ${files_del}

for file in $files; do
	file_short=`__get_file "${file}"`

	echo "${file} | ${file_short}"
	if grep "^${file_short}$" ${files_all}; then
		echo ${file} >> ${files_del}
	else
		echo $file_short >> ${files_all}
	fi
done

# clean empty line
sed -i '/^$/d' ${files_all}
sed -i '/^$/d' ${files_del}

echo
echo "--------------------------------"
echo
echo "`wc -l ${files_all}|cut -f1 -d' '` files to keep"
echo "`wc -l ${files_del}|cut -f1 -d' '` files to delete"
echo
echo "to delete files use:"
echo "for file in \$(cat ${files_del}); do echo rm  \${file}; ${sudo} rm ${path_pkg}/\${file}; done"

echo
echo "to deeply clean packages use:"
echo "grep "^.*-[0-9]" ${files_all}"
