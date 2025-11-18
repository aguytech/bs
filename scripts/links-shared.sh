#!/bin/bash

cd ~

path_to_init=/home/shared
echo "================ ${path_to_init}"
paths="Books Desktop dev Documents Downloads .gse-radio Help .perso Pictures repo Templates .themes .tmux Zotero"
for path in ${paths}; do
	path_from=${path}
	path_to=${path_to_init}/${path}
	echo -n "${path} "
	if [ -e ${path_to} ]; then
		[ -e ${path_from} ] && rm -fR ${path_from}
		[ -h ${path_from} ] && rm ${path_from}
		ln -s ${path_to} ${path_from}
		echo "- ok"
	else
		echo "- *** skipped *** ${path_to} is missing"
	fi
done

path_to_init=/ext/shared
echo "================ ${path_to_init}"
paths="android Archives Class Cnam Mooc Music Soft Videos"
for path in ${paths}; do
	path_from=${path}
	path_to=${path_to_init}/${path}
	echo -n "${path} "
	if [ -e ${path_to} ]; then
		[ -e ${path_from} ] && rm -fR ${path_from}
		[ -h ${path_from} ] && rm ${path_from}
		ln -s ${path_to} ${path_from}
		echo "- ok"
	else
		echo "- *** skipped *** ${path_to} is missing"
	fi
done

path_to_init=/vms
echo "================ ${path_to_init}"
paths="virt virtualbox vmware"
for path in ${paths}; do
	path_from=${path}
	path_to=${path_to_init}/${path}
	echo -n "${path} "
	if [ -e ${path_to} ]; then
		[ -e ${path_from} ] && rm -fR ${path_from}
		[ -h ${path_from} ] && rm ${path_from}
		ln -s ${path_to} ${path_from}
		echo "- ok"
	else
		echo "- *** skipped *** ${path_to} is missing"
	fi
done
