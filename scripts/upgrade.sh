#!/bin/bash
#
# Provides:				upgrade
# Short-Description:	Upgrade & clean packages
# Description:			Upgrade & clean packages

whiteb="\e[1;1m"; redb="\e[1;31m"; greenb="\e[1;32m"; blueb="\e[1;34m"; magentab="\e[1;35m";cclear="\e[0;m"

FILE_RELEASE="/etc/os-release"

####  manjaro
if grep -qi manjaro "${FILE_RELEASE}"; then
	cmd="sudo pacman"

	echo -e "${whiteb}pacman update${cclear}"
	${cmd} -Syu  --noconfirm

	echo -e "${whiteb}pacman clean orphans${cclear}"
	pcks="$(pacman -Qdtq)"
	[ "${pcks}" ] && ${cmd} -R ${pcks}

	echo -e "${whiteb}pacman clear cache${cclear}"
	${cmd} -Sc --noconfirm

	echo -e "${whiteb}yay update${cclear}"
	yay -Syu

	 echo -e "${whiteb}yay clean orphans${cclear}"
	yay -Rs

	echo -e "${whiteb}pacman clear cache${cclear}"
	yay -Sc --noconfirm
	rm -fR ~/.cache/yay

####  ubuntu / debian
elif grep -qiE 'debian|ubuntu' "${FILE_RELEASE}"; then

	grep -qiE 'jessie|xenial|trusty' "${FILE_RELEASE}" && cmd="apt-get" || cmd="apt"
	[[ $USER != root ]] && cmd="sudo ${cmd}"

	echo -e "${whiteb}update${cclear}"
	${cmd} update

	echo -e "${whiteb}upgrade${cclear}"
	${cmd} -y upgrade

	echo -e "${whiteb}autoremove${cclear}"
	${cmd} -y autoremove

	echo -e "${whiteb}clean${cclear}"
	${cmd} -y clean

	echo -e "${whiteb}autoclean${cclear}"
	${cmd} -y autoclean

####  alpine
elif grep -qiE 'alpine' "${FILE_RELEASE}"; then

	cmd="apk"

	echo -e "${whiteb}update${cclear}"
	${cmd} update

	echo -e "${whiteb}upgrade${cclear}"
	${cmd} upgrade

	echo -e "${whiteb}clean${cclear}"
	${cmd} cache clean

####  centos
elif grep -qiE 'centos' "${FILE_RELEASE}"; then

	cmd="yum"

	echo -e "${whiteb}update${cclear}"
	${cmd} -y update

	echo -e "${whiteb}upgrade${cclear}"
	${cmd} -y upgrade

	echo -e "${whiteb}clean${cclear}"
	${cmd} -y clean all

fi
