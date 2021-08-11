#!/bin/bash
#
# Provides:                 backup-user
# Short-Description:        export current user paths to backup path
# Description:              export current user paths to backup path

######################## GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "${S_GLOBAL_FUNCTIONS}" && echo -e "[error] - Unable to source file '${S_GLOBAL_FUNCTIONS}' from '${BASH_SOURCE[0]}'" && exit 1

########################  DATA

# paths to compress
declare -A paths_comp
# paths to exclude of paths_comp
declare -A paths_comp_exc
# paths to compress
declare -A paths_sync
# paths to exclude of paths_sync
declare -A paths_sync_exc

path_backup_base="/ext/backups"

# COMPRESS: sub level to compress
paths_comp["/"]="etc"
paths_comp["/home"]="$USER" # option 'all' take all /home subdirectories
paths_comp["$HOME"]=".config
.eclipse
.FreeCAD
.squirrel-sql
.ssh
.sublime-project
.tmux
.webclipse" # .gitkraken

#paths_comp["/home/shared"]=".aMule Desktop dev Documents Downloads .gse-radio Help kdenlive keep .local .perso Pictures Public .rsync .themes Work www"
paths_comp["/home/shared"]="*"
paths_comp["/opt"]="*" # option 'all' take all /opt subdirectories

paths_comp_exc["/home/shared"]=".torrent
Archives
Downloads
Class
Cnam
Mooc
tmp
virtualbox
vmware"

# SYNC: sub level to synchronize
#paths_sync["/var/lib/libvirt"]="export"
paths_sync["/var/lib/lxd"]="export"

tar_opt=" --exclude='.cache' -czf"
tar_ext="tar.gz"
sync_opt="-av --delete --exclude=.snapshots --exclude=.cache"

ddate=$(date +%Y%m%d)

# define desktop environment
[ -d "/etc/xdg/xfce4" ] && env="xfce"
[ -d "/etc/gdm" ] && env="gnome"

if [ -z "$env" ]; then
	path_backup=${path_backup_base}/${HOSTNAME}/export-${HOSTNAME}-${USER}-${S_RELEASE_NAME}-${ddate}
else
	path_backup=${path_backup_base}/${HOSTNAME}/export-${HOSTNAME}-${USER}-${S_RELEASE_NAME}-${env}-${ddate}
fi


########################  FUNCTION

_compress() {
	local path

	_echoT "======> compress from $1"

	# create path_to
	path_to="${path_backup}/${1##*/}"
	path_to="${path_to%/}"
	if ! [ -d "${path_to}" ]; then
		mkdir -p "${path_to}" || _exite "unable to create directory '${path_to}'"
	fi

	# define subpaths
	cd "$1"
	if [ "${paths_comp[$1]}" = "*" ]; then
		paths="$(ls -I. -I.. -a1)"
	else
		paths="${paths_comp[$1]}"
	fi

	while read path; do
		if [ -e "${path}" ]; then
			# step excluding paths
			if [[ ${paths_comp_exc["$1"]} = *${path}* ]]; then
				#echo "exclude ${path}"
				continue
			fi

			echo "=> $path"
			file_to="${path_to}/${path}.${tar_ext}"
			[ -e "$file_to" ] && _echoa "warning - overwrite file $file_to"
			cmd="sudo tar ${tar_opt} '$file_to' '${path}'"
			eval $cmd || _exite "executing '$cmd'"
			sudo chown ${USER}:${USER} "${file_to}"
		else
			_echoa "warning - skipped, unable to find '${1}/${path%/}'"
		fi
	done <<< ${paths}
}

_rsync() {
	_echoT "------> sync from $1"

	# create path_to
	path_to="${path_backup}/${1##*/}"
	path_to="${path_to%/}"
	if ! [ -d "${path_to}" ]; then
		mkdir -p "${path_to}" || _exite "unable to create directory '${path_to}'"
	fi

	# define subpaths
	if [ "${paths_sync[$1]}" = "*" ]; then
		paths="$(ls -I. -I.. -a1)"
	else
		paths="${paths_sync[$1]}"
	fi

	while read path; do
		if [ -e "${path_to}}/${path}" ]; then
			# step excluding paths
			if [[ ${paths_sync_exc["$1"]} = *${path}* ]]; then
				#echo "exclude ${path}"
				continue
			fi

			echo "-> $path"
			cmd="sudo rsync $sync_opt '${1}/${path%/}/' '${path_to}/${path%/}/'"
			eval $cmd || _exite "while executing '$cmd'"
		else
			_echoa "warning - skipped, unable to find '${1}/${path%/}'"
		fi
	done <<< ${paths}
}


########################  MAIN


_echoT "########################
EXPORT to ${path_backup}\n"

if ! [ -d ${path_backup} ]; then
	(sudo mkdir -p ${path_backup} && sudo chown 1000:1000 ${path_backup}) || _exite "unable to create/modify rights to directory '${path_backup}'"
fi


# CLEAN
_echoT "------------------ clean"
#path=~/.cache && [ -d $path ] && rm -fR $path/*
path=~/.local/share/Trash
[ -d $path ] && sudo rm -fR $path
# find trashes
sudo find / -not \( -regex "\(/proc\|/sys\|/run/user\)" -prune \) -not -type p -name .Trash* -exec sudo rm -fR "{}" \;


_echoT "------------------ compress"

# COMP EXE
for path_comp in ${!paths_comp[*]}; do
	if [ -e "$path_comp" ]; then
		_compress "$path_comp" "${paths_comp[$path_comp]}"
	else
		_echoa "warning - skipped unable to find '$path_comp'"
	fi
done

# COMP POST


_echoT "------------------ synchronize"

<<KEEP
# SYNC PRE
if [ "$(ls /var/lib/libvirt/)" ]; then
	_echoT "------------------ KVM"
	_echoT "- rights"
	${path_cmd}/kvm-rights

	_echoT "- export"
	${path_cmd}/kvm-export
	_echoT "------------------ END"
fi
KEEP

# SYNC EXE
for path_sync in ${!paths_sync[*]}; do
	if [ -e "$path_sync" ]; then
		_rsync "$path_sync" "${paths_sync[$path_sync]}"
	else
		_exite "warning - skipped unable to find '$path_comp'"
	fi
done

# SYNC POST

_echoT "END
########################"

<<KEEP
# virt-manager
#VirtBase="/home/shared/.virt-manager"
#VirtFrom="$VirtFrom/export"
#VirtTo="${path_backup}/.virt-manager-"$"ddate
#if ! [ -d "$VirtTo"" ]; then mkdir "$VirtTo"; fi
#sudo chown .1000 -R "$VirtBase"
#sudo chmod g+rw -R "$VirtBase"
#echo "---> copy virt-manager"
#sudo cp -R "$VirtFrom/*" "$VirtTo"

# var
#paths="/var"
#pathssub="svn www"
#_compress "$(expr "$paths" : '.*\(/.*\)')" "$pathssub"

# ext/stock
#paths="/ext/stock"
#pathssub="Dev Help"
#_compress "$(expr "$paths" : '.*\(/.*\)')" "$pathssub"
KEEP
