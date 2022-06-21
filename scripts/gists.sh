#!/bin/bash
#!/bin/bash

__usage() {
	echo "
${script} [options] <clone/pull/push> [gist]
Manage gists with token privileges
    Without given [gist] option do for all existing"
	exit
}
__mod_origin() {
	cd "$1"

	origin=$( git config remote.origin.url )
	origin="https://${token}@${origin#https://}"
	git config remote.origin.url ${origin}

	cd ..
}

__select() {
	gists_list=$( gh gist list -L ${gist_limit} | sed -n "s|^\(.\+\)\t\[\(.\+\)\].*|\1 \2|p" )
	if [ "$*" ]; then
		for  i in $*; do
			gists="${gists}\n$( grep "^$i " <<< ${gists_list} )"
		done
		gists=$( echo -e "${gists}" | grep -v ^$ )
	else
		gists=${gists_list}
	fi
}

__valid() {
	read -p "validate to ${action} $(wc -l <<<${gists}) gists Y/n: " _ANSWER
	! [[ "${_ANSWER}" =~ ^([yY]|)$ ]] && exit
}

__clone() {
	path_in=$(pwd)
	cd "${path_gists}" 

	while read i n; do
		echo "- ${n} ${i}"
		if ! [ -d "${n}" ]; then
			git clone -q https://gist.github.com/aguytech/${i}
			__mod_origin ${i}
			mv $i "${n}:${i}"
		fi
	done <<< ${gists}

	cd ${path_in}
}

__cmd() {
	path_in=$(pwd)
	cd ${path_gists}

	while read id name; do
		cd ${name}:${id}
			echo -e "${yellow}- ${name} ${id}${cclear}"
			git $*
		cd ..
	done <<< ${gists}

	cd ${path_in}
}

__init() {
	gist_limit=1000
	# variables
	script=${0##*/}
	# gh
	! command gh >/dev/null 2>&1 && echo "Unable to find gist github client: 'gh''" && exit 1
	# token file
	tokenfile=${HOME}/.perso/.gittoken
	! [ -f "${tokenfile}" ] && echo "Unable to find token file: '${tokenfile}'" && exit 1
	# token file
	token=$(grep '^# gist' $tokenfile -A1|sed 1d)
	[ -z "${token}" ] && echo "Unable to find token file: '${tokenfile}'" && exit 1
	# gists path
	path_gists=${HOME}/repo/gists
	! [ -d "${path_gists}" ] && echo "Unable to find gists path: '${path_gists}'" && exit 1
	# initialize gists
	gists=

	[ "$#" -lt 1 ] && echo "Wrong parameters numbers: $#" && __usage

	yellow='\e[0;93m'; cclear='\e[0;0m';
}

__init $*
action=$1 && shift
__select $*
__valid

case ${action} in
	clone)   __clone ;;
	pull)     __cmd pull --all ;;
	push)   __cmd push --all ;;
	status)   __cmd status ;;
	*)
		echo "No good command given to ${script}"
		__usage
	;;
esac
