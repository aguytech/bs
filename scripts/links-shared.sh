#!/bin/bash

cd ~

pth_to_init=/home/shared
echo "================ ${pth_to_init}"
pths="Books Desktop dev Documents Downloads .gse-radio Help .perso Pictures repo Templates .themes .tmux Zotero"
for pth in ${pths}; do
	pth_from=${pth}
	pth_to=${pth_to_init}/${pth}
	echo -n "${pth} "
	if [ -e ${pth_to} ]; then
		[ -e ${pth_from} ] && rm -fR ${pth_from}
		[ -h ${pth_from} ] && rm ${pth_from}
		ln -s ${pth_to} ${pth_from}
		echo "- ok"
	else
		echo "- *** skipped *** ${pth_to} is missing"
	fi
done

pth_to_init=/ext/shared
echo "================ ${pth_to_init}"
pths="android Archives Class Cnam Mooc Music Soft Videos"
for pth in ${pths}; do
	pth_from=${pth}
	pth_to=${pth_to_init}/${pth}
	echo -n "${pth} "
	if [ -e ${pth_to} ]; then
		[ -e ${pth_from} ] && rm -fR ${pth_from}
		[ -h ${pth_from} ] && rm ${pth_from}
		ln -s ${pth_to} ${pth_from}
		echo "- ok"
	else
		echo "- *** skipped *** ${pth_to} is missing"
	fi
done

pth_to_init=/vms
echo "================ ${pth_to_init}"
pths="virt virtualbox vmware"
for pth in ${pths}; do
	pth_from=${pth}
	pth_to=${pth_to_init}/${pth}
	echo -n "${pth} "
	if [ -e ${pth_to} ]; then
		[ -e ${pth_from} ] && rm -fR ${pth_from}
		[ -h ${pth_from} ] && rm ${pth_from}
		ln -s ${pth_to} ${pth_from}
		echo "- ok"
	else
		echo "- *** skipped *** ${pth_to} is missing"
	fi
done
