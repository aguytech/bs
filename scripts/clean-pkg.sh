#!/bin/bash

path="/var/cache/pacman/pkg"
files_all="/tmp/all"
files_del="/tmp/del"

# clean partialy downloaded files
sudo rm $path/*.part

files=`ls -r1 $path`
#files=`ls -r1 /var/cache/pacman/pkg|sed 's|^\(.*\)-[0-9\.]\+-[0-9].*|\1|'`
files_all="/tmp/all"
files_del="/tmp/del"
echo > $files_all
echo > $files_del

for file in $files; do
	file_short=`echo $file|sed 's|^\(.*\)-[0-9\.]\+-[0-9].*|\1|'`
	#file_short=`echo $file|sed 's|^\(.*\)-[0-9\.]\+-.*|\1|'`
	echo "$file | $file_short"
	if grep "^${file_short}$" $files_all; then
		echo $file >> $files_del
	else
		echo $file_short >> $files_all
	fi
done

# clean empty line
sed -i '/^$/d' $files_all
sed -i '/^$/d' $files_del

echo
echo "--------------------------------"
echo
echo "`wc -l $files_all|cut -f1 -d' '` files to keep"
echo "`wc -l $files_del|cut -f1 -d' '` files to delete"
echo
echo "to delete files use:"
echo "for file in \$(cat $files_del); do echo rm  \${file}; sudo rm /var/cache/pacman/pkg/\${file}; done"

echo
echo "to deeply clean packages use:"
echo "clean-pkg |grep [0-9]:[0-9]"
