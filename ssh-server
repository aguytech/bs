#!/bin/bash
#
# Provides:               ssh-server
# Short-Description:      connect with ssh to cluster server & containers inside
# Description:            connect with ssh to cluster server & containers inside

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  FUNCTION

# connect to server
__ssh() {
    if [ "$2" == "$_IPTHIS" ]; then
    	_exite "You try to connect to yourself"
    else
    	ssh -o ConnectTimeout=$timeout "$1"@"$2" -p"$3"
    fi
    exit
}

# test type of containers
__typect() {
    if [ "$2" == "$_IPTHIS" ]; then _echoE "You try to connect to yourself"; exit 1
    else ssh -o ConnectTimeout=$timeout "$1"@"$2" -p"$3"
    fi
    exit
}

################################  INIT

declare -A ips
declare -A ports
declare -A users
timeout=3

################################  MAIN

# containers access
for id in ${!S_CLUSTER[*]}; do
	eval ${S_CLUSTER[$id]}
	ips[$id]="$ip"
	ports[$id]="$port"
	users[$id]="$user"

	# direct connection
	if [[ "$1" = "$name" || "$1" = "$ip" ]]; then
		__ssh "$user" "$id" "$port"
		_exit
	fi

	if ssh -o ConnectTimeout=3 -p ${port} ${user}@${ip} 'type vzctl >/dev/null 2>&1'; then

		while read ctid ctname; do
			if [[ "${ctid}" && "${ctname}" ]]; then
				ips[${id}.${name}.${ctid}]="${ip}"
				ports[${id}.${name}.${ctid}]="$S_VM_PORT_SSH_PRE${ctid}"
				users[${id}.${name}.${ctid}]="$S_VM_PORT_SSH_PRE${ctid}"
			fi

			# direct connection to server
			if [[ "$1" = "${name}.${ctid}" || "$1" = "${id}.${ctid}" ]]; then __ssh "$user" "${ip}" "${S_VM_PORT_SSH_PRE}${ctid}"; fi
		done <<< "$(ssh -o ConnectTimeout=3 -p ${port} ${user}@${ip} 'vzlist -Ho ctid,hostname')"

	fi

done

_menu "Select a VM" $(tr " " "\n" <<<${!ips[*]}|sort|xargs) || _exite

__ssh "${users[$_ANSWER]}" "${ips[$_ANSWER]}" "${ports[$_ANSWER]}"
