#!/bin/bash

__usage() {
	echo "
${script} [options] <mount/umount> <file>
Mounts disk file"
	exit
}
__mod_nbd() {
	# no module nbd
	if ! modinfo nbd >/dev/null 2>&1; then
		echo "Unable to find module nbd" >&2
		exit 1
	fi
	lsmod | grep -q ^nbd || modprobe nbd
}

__mount_nbd() {
	# already mounted
	if grep -q "${_FILE}$" ${_NBD_FILE}; then
		echo "${_FILE} already mounted in $(grep "${_FILE}$" ${_NBD_FILE} | cut -f1)" >&2
		return
	fi

	for block in $(ls -d /sys/class/block/nbd[0-9] | sort) ; do 
		if [ $(cat ${block}/size) = 0 ]; then
			if qemu-nbd -c /dev/${block##*/} "${_FILE}"; then
				echo -e "/dev/${block##*/}\t${_FILE}" >> ${_NBD_FILE}
				sleep 0.2
			else
				echo "Unable to mount ${_FILE} in /dev/${block##*/}" >&2
				exit 1
			fi
			break
		fi
	done
}

__umount_nbd() {
	nbd=$(grep "${_FILE}$" ${_NBD_FILE} | cut -f1)

	if [ "${nbd}" ] && [ $(cat /sys/class/block/${nbd#/dev/}/size) -gt 0 ]; then
		if qemu-nbd -d ${nbd}; then
			sed -i "\|${_FILE}$|d" ${_NBD_FILE}
		fi
	fi
}

__mount_dev() {
	nbd_base=$(grep "${_FILE}$" ${_NBD_FILE} | cut -f1)
	[ -z "${nbd_base}" ] && return

	for nbd in $(ls -d1 ${nbd_base}p* ); do
		pth="${_PATH_NBD}/${_FILE_NAME%.*}-${nbd#/dev/}"
		[ -d "${pth}" ] || mkdir -p ${pth}
		if grep -q ${nbd} /proc/mounts; then
			echo "${nbd} already mounted"
		else
			mount ${nbd} ${pth}
			echo "${nbd} mounted"
		fi
	done
}

__umount_dev() {
	nbd_base=$(grep "${_FILE}$" ${_NBD_FILE} | cut -f1)
	[ -z "${nbd_base}" ] && return

	for nbd in $(ls -d1 ${nbd_base}p* ); do
		pth="${_PATH_NBD}/${_FILE_NAME%.*}-${nbd#/dev/}"
		if grep -q ${nbd} /proc/mounts && umount ${pth}; then
			echo "${nbd} unmounted"
		fi
		[ -d "${pth}" ] && rmdir ${pth}
	done
}

__file() {
	[ -z "$1" ] && echo -e "No file given" >&2 && __usage
	! [ -f "$1" ] && echo "'$1' is not a file" >&2 && __usage
	_FILE="$1"
	_FILE_NAME="${1##*/}"
}

__init() {
	# variables
	script=${0##*/}
	_NBD_FILE=/tmp/${script}

	# nbd path
	! [ -d "${_PATH_NBD}" ] && echo "Unable to find path: _PATH_NBD=${_PATH_NBD}" >&2 && exit 1
	# nbd file
	[ -f "${_NBD_FILE}" ] || touch ${_NBD_FILE}
	# root privileges
	[ "${USER}" != root  ] && echo "Root privileges are needed" >&2 && __usage
	# Wrong parameters numbers
	[ "$#" -lt 2 ] && echo "Wrong parameters numbers: $#" >&2 && __usage

	# log
	pth_log=/var/log/${script}
	[ -d "${pth_log}" ] || mkdir -p ${pth_log}
	exec 1> >( tee -a ${pth_log}/${script}.log )    2> >( tee -a ${pth_log}/${script}.err )
	echo -e "\n### $( date "+%Y%m%d-%H:%M:%S" )" | tee -a ${pth_log}/${script}.log > tee -a ${pth_log}/${script}.err
}

_PATH_NBD=

__init $*

case $1 in
	mount)
		__file "$2"
		__mod_nbd
		__mount_nbd
		__mount_dev
	;;
	umount)
		__file "$2"
		__mod_nbd
		__umount_dev
		__umount_nbd
	;;
	*)
		echo "Wrong command given to ${script}"
		__usage
	;;
esac
