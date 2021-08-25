#!/bin/sh
#
# Provides:             upgrade
# Short-Description:    Upgrade & clean packages
# Description:          Upgrade & clean packages

color='\e[1;34m'; cclear='\e[0;0m'

file_release="/etc/os-release"
[ ${USER} != root ] && pre="sudo"

########################  MANJARO
if grep -qi manjaro "${file_release}"; then
	cmd="${pre} pacman"

	echo -e "${color}pacman update${cclear}"
	${cmd} -Syu  --noconfirm

	echo -e "${color}pacman clean orphans${cclear}"
	pcks="$(pacman -Qdtq)"
	[ "${pcks}" ] && ${cmd} -R ${pcks}

	echo -e "${color}pacman clear cache${cclear}"
	${cmd} -Sc --noconfirm

	echo -e "${color}yay update${cclear}"
	yay -Syu

	 echo -e "${color}yay clean orphans${cclear}"
	yay -Rs

	echo -e "${color}pacman clear cache${cclear}"
	yay -Sc --noconfirm
	rm -fR ~/.cache/yay

########################  UBUNTU / DEBIAN
elif grep -qiE 'debian|ubuntu' "${file_release}"; then

	cmd="${pre} apt"

	echo "${color}update${cclear}"
	${cmd} update

	echo "${color}upgrade${cclear}"
	${cmd} -y upgrade

	echo "${color}autoremove${cclear}"
	${cmd} -y autoremove

	echo "${color}clean${cclear}"
	${cmd} -y clean

	echo "${color}autoclean${cclear}"
	${cmd} -y autoclean

########################  ALPINE
elif grep -qiE 'alpine' "${file_release}"; then

	cmd="apk"

	echo -e "${color}update${cclear}"
	${cmd} update

	echo -e "${color}upgrade${cclear}"
	${cmd} upgrade

	#echo -e "${color}clean${cclear}"
	#${cmd} cache clean

########################  CENTOS
elif grep -qiE 'centos' "${file_release}"; then

	cmd+="yum"

	echo -e "${color}update${cclear}"
	${cmd} -y update

	echo -e "${color}upgrade${cclear}"
	${cmd} -y upgrade

	echo -e "${color}clean${cclear}"
	${cmd} -y clean all

fi
