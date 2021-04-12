#!/bin/bash
#
# Provides:                 ssh-vz
# Short-Description:        connect with ssh protocol to openvz containers
# Description:              connect with ssh protocol to openvz containers

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  FUNCTION

__ssh() {
    ssh -o ConnectTimeout=3 "$S_VM_SSH_USER"@"$1" -p"$S_VM_SSH_PORT"
    exit
}


################################  MAIN

# direct connection
[ "$1" ] && __ssh "$_VM_IP_BASE.$1"

while read ctid name; do
    menu+="$ctid.$name "
done <<< "$(vzlist -Ho ctid,hostname)"

_menu "Select a VM" ${menu%* }
__ssh "$_VM_IP_BASE.${_ANSWER%%.*}"
