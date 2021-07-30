#!/bin/sh

# PS1
if [ $USER = root ]; then
	PS1="\e[1;38;5;214m\h\e[1;37m\W\e[1;31m#\e[0;0m"
else
	PS1="\e[1;38;5;214m\u\e[1;37m@\e[1;38;5;214m\h\e[1;37m:\W\e[1;38;5;214m$\e[0;0m"
fi

# RELEASE
export RELEASE=`sed -n '/^ID=/ s|.*=||p' /etc/os-release`

# path
[ -d /usr/local/bs ] && export PATH=${PATH}:/usr/local/bs

