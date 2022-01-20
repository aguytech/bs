#!/bin/sh

[ -z "$1" ] && { echo "error no host given in arguments"; exit 1; }
host="$1"
opts="-e 'ssh -p2002'"

script="$(basename "$0")"
file=/var/log/server/${script}.log
file_out=/var/log/server/${script}-out.log
_log() { echo "$(date +%D-%H%M%S) $*" >> ${file}; }
_exe() { _log "$*"; eval "$*" >> ${file_out}; }
_rsync() {
    [ -d "$1" ] || mkdir -p $1
    _exe $2
}

_log "[begin] ${script}"
for path in ${file%/*} ${file_out%/*}; do
    [ -d "${path}" ] || mkdir -p ${path}
done

# share
_rsync /vm/share "rsync ${opts} root@${host}:/vm/share/ /vm/share/ -av --delete --exclude /log"
# cloud
_rsync /vm/cloud "rsync ${opts} root@${host}:/vm/cloud/ /vm/cloud/ -av --delete"

# save
_rsync /save/${host}/save "rsync ${opts} root@${host}:/save/${host}/ /save/${host}/save/ -av"
# vm
_rsync /save/${host}/vm/save "rsync ${opts} root@${host}:/vm/save/ /save/${host}/vm/save/ -av"
_rsync /save/${host}/vm/trans "rsync ${opts} root@${host}:/vm/trans/ /save/${host}/vm/trans/ -av"

_log "[end] ${script}"
