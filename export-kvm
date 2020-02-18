#!/bin/bash
#
# Provides:				export-kvm
# Short-Description:	export virtual machine, configuration && dd for kvm
# Description:			export virtual machine, configuration && dd for kvm

dirbase='/var/lib/libvirt'
dirin=$dirbase'/images'
dirout=$dirbase'/export'
dirconf='/etc/libvirt'
vmcon="qemu:///system"


# ----------------------------- DO NOT TOUCH AFTER -----------------------------

_exportvm() {
	echo "---------- VM on $vmcon"

	for vm in $1
	do
		echo "- export "$vm
		virsh dumpxml $vm > "$dirout/$vm.xml"
		virsh dumpxml --migratable $vm > "$dirout/$vm-migr.xml"
	done
	cd "$dirout"
	tar cvzf vms.xml.tgz *.xml
}

_exportdd() {
	echo "---------- DD in $dirin"

	for dd in $1
	do
		if [ -f $dirin/$dd ]
		then
			echo "- compress "$dd
			gzip -c $dirin/$dd > $dirout/$dd'.gz'
		else
			echo "- Not find '$dd' to compress !"
		fi
	done
}

_exportcf() {
	echo "---------- CF on $vmcon"

	cd /etc
	sudo tar cvzf libvirt.tgz $dirconf
	sudo mv libvirt.tgz $dirout
}


#####################  START

echo

sudo chown .1000 -R $dirbase
sudo chmod g+rw -R $dirbase

if ! [ -d $dirout ]; then mkdir $dirout; fi

#####################  PARAMS

echo "Connection to qemu"
virsh connect $vmcon

if [ "$1" ]
then
	# VM
	if [ "$( virsh list --all --name | grep "$1" )" ]
	then
		_exportvm "$1"
	else
		echo "- Failed to find VM named : "$1""
	fi

	# DD
	ddList="$( ls "$dirin" | grep "$1\..*" )"
	if [ "$ddList" ]
	then
		_exportdd "$ddList"
	else
		echo "- Failed to find DD named : "$1""
	fi
else
	_exportvm "$( virsh list --all --name )"
	_exportdd "$( ls $dirin | grep "^.*\..*[^g][^z]$" )"
	_exportcf
fi

sudo chown .1000 -R $dirbase
sudo chmod g+rw -R $dirbase
