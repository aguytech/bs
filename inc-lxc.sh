#!/bin/bash
#
# Provides:						inc-lxc.sh
# Short-Description:		tools functions to manipulate container, to be sourced by commands & scripts
# Description:					tools functions to manipulate container, to be sourced by commands & scripts

########################  GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

########################  CONTAINER

#######  LIST

__lxc_list_existing() {
	lxc list --format=json | jq -r '.[].name' |xargs
}

__lxc_list_stopped() {
	lxc list --format=json | jq -r '.[] | select(.status == "Stopped").name' | xargs
}

__lxc_list_running() {
	lxc list --format=json | jq -r '.[] | select(.status == "Running").name'| xargs
}

#######  INFO

__lxc_exist() {
	#test `lxc image list --format json | jq -r ".[].aliases[] | select(.name == \"$1\").name"`
	`lxc list --format json | jq -re "any(.[]; .name == \"$1\")"` || return 1
}

__lxc_is_stopped() {
	`lxc list --format json | jq -re "any(.[] | select(.status == \"Stopped\"); .name == \"$1\")"` || return 1
}

__lxc_is_runnig() {
	_echod "${FUNCNAME}() \$1=$1"
	`lxc list --format json | jq -re "any(.[] | select(.status == \"Running\"); .name == \"$1\")"` || return 1
}

__lxc_get_status() {
	lxc list --format=json | jq -r ".[] | select(.name == \"$1\").status"
}

########################  IMAGE

__lxc_image_exist() {
	#test `lxc image list --format json | jq -r ".[].aliases[] | select(.name == \"$1\").name"`
	`lxc image list --format json | jq -re "any(.[].aliases[]; .name == \"$1\")"` || return 1
}

########################  PROFILE

__lxc_profile_exist() {
	`lxc profile list --format json | jq -re "any(.[]; .name == \"$1\")"` || return 1
}

__lxc_has_profile() {
	`lxc list --format=json | jq -re "any(.[] | select (.profiles | any(. == \"$2\")); .name == \"$1\")"` || return 1
}

########################  EXEC

__lxc_exec() {
	_echod "${FUNCNAME}() CMD -----------------"
	echo "$*" >&6
	_echod "${FUNCNAME}() EXE -----------------"
	lxc exec ${CTNAME} -- sh -c "$*" >&4
	_echod "${FUNCNAME}() OUT -----------------"
}

