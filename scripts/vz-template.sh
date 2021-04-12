#!/bin/bash
#
# Provides:				vz-template
# Short-Description:	create a openVZ vm from scratch
# Description:			create a openVZ vm from scratch

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  MAIN

# openvz server
type vzctl &>/dev/null && VZCTL="vzctl" || VZCTL="/usr/sbin/vzctl"
type ${VZCTL} &>/dev/null || _exite "unable to find vzctl command"

type vzlist &>/dev/null && VZLIST="vzlist" || VZLIST="/usr/sbin/vzlist"
type ${VZLIST} &>/dev/null || _exite "unable to find vzlist command"

type vz-ctl &>/dev/null && VZ_CTL="vz-ctl" || VZ_CTL="/usr/local/bs/vz-ctl"
type ${VZ_CTL} &>/dev/null || _exite "unable to find vz-ctl command"

#part=vz-template
#_echoT "==========================================  $part"

declare -A datas=()

while [ "$_ANSWER" != y ]; do
	opts=
	names=

	# path for templates
	[[ ! "$S_VZ_PATH_TEMPLATE" || ! -d $S_VZ_PATH_TEMPLATE ]] && _echoE "Path: '$S_VZ_PATH_TEMPLATE' doesn't exists" && _exit 0

	# template
	opt=template
	names+="$opt "
	_echo "------------------------------------------------------------------------------"
	_menu "$opt" $(ls $S_VZ_PATH_TEMPLATE 2>/dev/null |sed "s/^\(.*\)\.\(tar\|tar\.gz\)$/\1/")
	datas[$opt]=$_ANSWER
	opts+="${datas[$opt]} "

	# ctid
	opt=ctid
	names+="$opt "
	_ANSWER=0
	ctidexist=" $(${VZLIST} -Ho ctid |xargs) "
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	_echo "ctid already used: $ctidexist"
	while ! [[ "$_ANSWER" -ge $S_VM_CTID_MIN && "$_ANSWER" -le $S_VM_CTID_MAX ]] || [ "${ctidexist/ $_ANSWER /}" != "$ctidexist" ]; do
		_ask "$opt $S_VM_CTID_MIN<ctid<$S_VM_CTID_MAX"
	done
	datas[$opt]=$_ANSWER
	datas[ip]=${_VM_IP_BASE}.$_ANSWER
	opts+="${datas[$opt]} "

	# hostname
	opt=hostname
	names+="$opt "
	_ANSWER=@
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	while ! [[ "$_ANSWER" =~ ^[-_0-9a-zA-Z]*$ ]]; do
		_ask "$opt (no space no special characters)"
	done
	datas[$opt]=$_ANSWER
	opts+="${datas[$opt]} "

	# name
	opt=name
	names+="$opt "
	_ANSWER=@
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	while ! [[ "$_ANSWER" =~ ^[-_0-9a-zA-Z]*$ ]]; do
		# _askno "name (anstmp ${datas[hostname]})"
		_askno "$opt"
	done
	#datas[$opt]=${_ANSWER:-${datas[hostname]}}
	datas[$opt]=$_ANSWER
	opts+="${datas[$opt]} "

	# pwd
	opt=pwd
	names+="$opt "
	pwd="$(_pwd)"
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	_askno "$opt ($pwd)"
	datas[$opt]=${_ANSWER:-$pwd}
	opts+="${datas[$opt]} "

	# ram
	opt=ram
	names+="$opt "
	anstmp='256m:2048m'
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	_askno "$opt ($anstmp)"
	datas[$opt]=${_ANSWER:-$anstmp}
	opts+="${datas[$opt]} "

	# swap
	opt=swap
	names+="$opt "
	anstmp='0:1024m'
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	_askno "$opt ($anstmp)"
	datas[$opt]=${_ANSWER:-$anstmp}
	opts+="${datas[$opt]} "

	# disk
	opt=disk
	names+="$opt "
	anstmp='2G:4G'
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	_askno "$opt, space for disk ($anstmp)"
	datas[$opt]=${_ANSWER:-$anstmp}
	opts+="${datas[$opt]} "

	# noatime
	opt=noatime
	names+="$opt "
	anstmp='n'
	_echo "------------------------------------------------------------------------------"
	#_echoi "$opts"
	_askno "$opt, to disk mount ($anstmp)"
	datas[$opt]=${_ANSWER:-$anstmp}
	opts+="${datas[$opt]} "

	# confirm
	_ANSWER=
	str=; for id in ${names}; do str+="$id ${whiteb}${datas[$id]}${cclear}\n"; done
	echo "-------------------------------------------"
	echo -e $str | column -t
	echo "-------------------------------------------"
	_askyn "confirm the creation"

done


_echoT "----------  creation"

_eval "${VZCTL} create ${datas[ctid]} --ostemplate ${datas[template]}"


_echoT "----------  configuration"

[ "${datas[noatime]}" == y ] && _eval"${VZCTL} set ${datas[ctid]} --noatime yes --save"
_eval "${VZCTL} set ${datas[ctid]} --ipadd ${datas[ip]} --save"
_eval "${VZCTL} set ${datas[ctid]} --hostname ${datas[hostname]} --save"
_eval "${VZCTL} set ${datas[ctid]} --name ${datas[name]} --save"
_eval "${VZCTL} set ${datas[ctid]} --physpages ${datas[ram]} --save"
_eval "${VZCTL} set ${datas[ctid]} --swappages ${datas[swap]} --save"
_eval "${VZCTL} set ${datas[ctid]} --diskspace ${datas[disk]} --save"
for dns in ${S_DNS_SERVER[opendns]}; do
	_eval "${VZCTL} set ${datas[ctid]} --nameserver $dns --save"
done


_echoT "----------  start"

_eval "${VZ_CTL} start -y ${datas[ctid]}"
_eval "${VZCTL} set ${datas[ctid]} --userpasswd 'root:${datas[pwd]}' --save"


_echoT "----------  remove autorized key"

_eval "ssh-keygen -R ${datas[ip]}"

sleep 3

_echoT "----------  ssh copy id"

cmd=""
_echoI "Please enter yes && root password : '${datas[pwd]}'"
_eval "ssh-copy-id root@${datas[ip]}"

_echoI "${blueb}to copy your key from your remote computer, run \nssh-copy-id root@$(ifconfig $S_ETH |xargs|awk '{print $7}'|sed -e 's/[a-z]*://') -p ${S_VM_PORT_SSH_PRE}${datas[ctid]}${cclear}"

_echoE "Keep safe the password of root user : ${datas[pwd]}"


_echoT "----------  end"


