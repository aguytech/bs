########################  GLOBAL
alias l='ls -CF --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias llm='ls -AhlF --block-size=M'
alias lsm='ls -AhlF --block-size=M'
alias lsblku='lsblk -o name,maj:min,size,type,mountpoint,uuid,label'
alias df='df -h'
alias dfs="df -h -x tmpfs -x devtmpfs|grep -v /dev/.*loop"
alias st='sublime-text'
alias watch='watch --color'
alias nanoc='nano -wY conf'
alias grep='grep --color'
alias ced='clean-files trash'
alias histg='history|grep'
alias histgs="history|sed 's|^ \+[0-9]\+ \+||'|grep"
alias du0="du -hd0"
alias du1="du -hd1"

########################  GIT
# status
alias gita='echo "git add *? " && read str && git add * && git status '
# commit
alias gitcim='git commit -m'
# branch
alias gitbrv='git branch -v'
# merge
alias gitcm='git branch -v && echo -n "push -> master? " && read str && git co master && git merge - && git co - && git branch -v'
alias gitcd='git branch -v && echo -n "push -> dev? " && read str && git co dev && git merge - && git co - && git branch -v'
# push
alias gitpa='git branch -v && echo -n "push all? " && read str && git push --all && git push --tag && git branch -v'

########################  GH

########################  SSH
alias sshs='ssh-server'
alias sshs1='ssh-server node1'
alias sshs2='ssh-server node2'
alias sshs3='ssh-server node3'
alias sshpi='ssh root@pi -p2002'
alias sshcw='ssh coworkinur@ssh.cluster026.hosting.ovh.net'
alias sshvz='ssh-vz'
alias sshvx='ssh-lxd'
alias sshvk='ssh-kvm'
alias sshkr='ssh-keygen -R'

########################  IPTABLES
alias iptl='iptables -nvL --line-number'
alias iptln='iptables -nvL -t nat --line-number'
alias iptls='iptables -S'
alias iptlsn='iptables -S -t nat'
alias iptlm='iptables -nvL -t mangle --line-number'
alias iptla='iptables -nvL --line-number; iptables -nvL -t nat --line-number'

########################  LXC
## ct
alias lxc1="lxc start"
alias lxc0="lxc stop"
alias lxc^="lxc restart"
alias lxcd="lxc delete --force"
alias lxcs="lxc shell"
# list
alias lxcl="lxc list -c nsf4tSc"
alias lxclp="lxc list -c nsP4tSc"
alias lxcln="lxc list -f csv -c n"
alias lxclb="lxc list -f csv -c nf|tr ',' '\t'"
alias lxclf="lxc list -c nsf4"
alias lxclr="lxc list -c nsbDmMuNl"
alias lxcla="lxc list -f csv -c n" # "lxc list -f json | jq -r '.[].name' "
alias lxcl0="lxc list status=Stopped -f csv -c n" # "lxc list -f json | jq -r '.[] | select(.status == \"Stopped\").name' "
alias lxcl1="lxc list status=Running -f csv -c n" # "lxc list -f json | jq -r '.[] | select(.status == \"Running\").name' "
## config
alias lxccs="lxc config show"
alias lxcce="lxc config edit"
alias lxccms="lxc config metadata show"
alias lxccme="lxc config metadata edit"
## copy
alias lxcc="lxc copy"
## image
alias lxcid="lxc image delete"
alias lxcil="lxc image list -c Lfptsu" # Lfpdtsu
alias lxcilf="lxc image list -c Lfpts" # Lfpdtsu
alias lxciln="lxc image list -f csv -c l"
alias lxcila="lxc image list -f csv -c L" # "lxc image list -f json | jq -r '.[].aliases[].name'"
alias lxcilb="lxc image list -f csv -c f" # "lxc image list -f json | jq -r '.[].fingerprint | .[:12]'"
alias lxcilF="lxc image list -f csv -c F" # "lxc image list -f json | jq -r '.[].fingerprint'"
## network
alias lxcnl="lxc network list"
alias lxcns="lxc network show"
## storage
alias lxcsl="lxc storage list"
alias lxcss="lxc storage show"
## profile
alias lxcpl="lxc profile list"
alias lxcpln="lxc profile list -f csv|grep -o '^[^,]\+'"
alias lxcpd="lxc profile delete"
alias lxcps="lxc profile show"
## others
alias lxcal="lxc alias list"
alias lxcrl="lxc remote list"

alias lxc.r="rsync /usr/local/bs/ /tmp/bs --exclude=.git* -a && for ct in \$(lxc list status=Running -f csv -c n); do echo \$ct; lxc exec \$ct -- rm -fR /usr/local/bs; lxc file push -qr /tmp/bs \$ct/usr/local/; done"

########################  LXCX
alias lxcxl="lxcx list"
alias lxcxl1="lxcx list -1"

########################  BTRFS
# subvolume
alias bfs='btrfs subvolume'
alias bfsl='btrfs subvolume list --sort=path -t'
alias bfslo='btrfs subvolume list --sort=path -to'
alias bfsc='btrfs subvolume create'
alias bfsd='btrfs subvolume delete'
alias bfss='btrfs subvolume snapshot'
alias bfssr='btrfs subvolume snapshot -r'
# filesystem
alias bff='btrfs filesystem'
alias bffs='btrfs filesystem show'
alias bffu='btrfs filesystem usage'
alias bffdf='btrfs filesystem df'
alias bffd='btrfs filesystem defragment'
alias bffl='btrfs filesystem label'
# property
alias bfp='btrfs property -t s'

########################  ZFS
# zpool
alias zpl='zpool list'
alias zplv='zpool list -v'
alias zpga='zpool get all'
alias zpg1='zpool get size,capacity,free,health,guid zroot'
# zfs
alias zfsl='zfs list -o name,used,available,mountpoint,mounted -r'
alias zfsga='zfs get all'
alias zfsg1='zfs get -o property,value creation,used,available,referenced,compressratio,mounted,readonly,quota'
alias zfsd='zfs destroy'

########################  RSYNC
# dev
alias rsddn1='rsync-server -av --delete ddn1'
alias rsdn1d='rsync-server -av --delete dn1d'
alias rsddn2='rsync-server -av --delete ddn2'
alias rsdn2d='rsync-server -av --delete dn2d'
alias rsddn="for i in $(seq 1 ${#S_CLUSTER[*]}|xargs); do rsync-server -av --delete ddn\${i}; done"
alias rsdnd="for i in $(seq 1 ${#S_CLUSTER[*]}|xargs); do rsync-server -av --delete dn\${i}d; done"
# install server
alias rsidn1='rsync-server -av --delete idn1'
alias rsin1d='rsync-server -av --delete in1d'
alias rsidn2='rsync-server -av --delete idn2'
alias rsin2d='rsync-server -av --delete in2d'
alias rsidn="for i in $(seq 1 ${#S_CLUSTER[*]}|xargs); do rsync-server -av --delete idn\${i}; done"
alias rsind="for i in $(seq 1 ${#S_CLUSTER[*]}|xargs); do rsync-server -av --delete in\${i}d; done"
# bs
alias rsbdn1='rsync-server -av --delete bdn1'
alias rsbn1d='rsync-server -av --delete bn1d'
alias rsbdn2='rsync-server -av --delete bdn2'
alias rsbn2d='rsync-server -av --delete bn2d'
alias rsbdn="for i in $(seq 1 ${#S_CLUSTER[*]}|xargs); do rsync-server -av --delete bdn\${i}; done"
alias rsbnd="for i in $(seq 1 ${#S_CLUSTER[*]}|xargs); do rsync-server -av --delete bn\${i}d; done"
# command in .bash_functions
alias rsynchv='__rsynchv'
alias rsynchvn='__rsynchvn'

########################  SERVER
# global
alias shutn='shutdown -h now'
alias chw='chown www-data.www-data'
alias chwr='chown -R www-data.www-data'
alias a2ctl='apache2ctl'
alias a2ctls='apache2ctl status'
alias a2ctlfs='apache2ctl fullstatus'
alias a2ctlc='apache2ctl configtest'
# systemd
if type systemctl >/dev/null 2>&1;then
	# apache
	alias sc0a='systemctl stop apache2.service'
	alias sc1a='systemctl start apache2.service'
	alias scrsa='systemctl restart apache2.service'
	alias scrla='systemctl reload apache2.service'
	alias scsa='systemctl status apache2.service'
	# php
	alias scp0="systemctl stop php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias sc1p="systemctl start php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias scrsp="systemctl restart php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias scrlp="systemctl reload php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias scsp="systemctl status php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	# mariadb
	alias sc0m='systemctl stop mariadb.service'
	alias sc1m='systemctl start mariadb.service'
	alias scrsm='systemctl restart mariadb.service'
	alias scrsm='systemctl restart mariadb.service'
	alias scsm='systemctl status mariadb.service'
# rc-service
elif type rc-service >/dev/null 2>&1;then
	# apache
	alias sc0a='rc-service apache2 stop'
	alias sc1a='rc-service apache2 start'
	alias scrsa='rc-service apache2 restart'
	alias scrla='rc-service apache2 reload'
	alias scsa='rc-status default|grep apache2'
	# php
	alias scp0="rc-service \$(rc-service -l|grep ^php) stop"
	alias sc1p="rc-service \$(rc-service -l|grep ^php) start"
	alias scrsp="rc-service \$(rc-service -l|grep ^php) restart"
	alias scrlp="rc-service \$(rc-service -l|grep ^php) reload"
	alias scsp='rc-status default|grep php'
	# mariadb
	alias sc0m='rc-service mysql stop'
	alias sc1m='rc-service mysql start'
	alias scrsm='rc-service mysql restart'
	alias scrlm='rc-service mysql reload'
	alias scsm='rc-status default|grep mysql'
fi

########################  OTHERS
# Monitor logs
# alias tsys='tail -100f /var/log/syslog'
# alias tmsg='tail -100f /var/log/messages'

# Keep 1000 lines in .bash_history (default is 500)
#export HISTSIZE=2000
#export HISTFILESIZE=2000
