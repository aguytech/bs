#!/bin/bash
#
# Provides:             .bash-aliases
# Short-Description:    global aliases
# Description:          global aliases

# global
alias l='ls -CF --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias df='df -h'
alias st='sublime-text'
alias watch='watch --color'

# alias nano='nano -w'
alias nanoc='nano -wY conf'
alias grep='grep --color'
alias etrash='sudo find / -not \( -regex "\(/proc\|/sys\|/run/user\)" -prune \) -not -type p -name .Trash* -exec echo "{}" \; -exec sudo rm -fR "{}" \;'
alias ced='clean-keep && etrash'
alias histg='history|grep'
alias histgs="history|sed 's|^ \+[0-9]\+ \+||'|grep"
alias du0="__du 0"
alias du1="__du 1"
alias du2="__du 2"
alias dfs="df -x tmpfs -x devtmpfs | grep -v /dev/ploop"

# server
alias hatop='hatop -s /run/haproxy/admin.sock'
alias shutn='shutdown -h now'
alias chw='chown www-data.www-data'
alias chwr='chown -R www-data.www-data'
alias a2ctl='apache2ctl'
alias a2ctls='apache2ctl status'
alias a2ctlfs='apache2ctl fullstatus'
alias a2ctlc='apache2ctl configtest'
if type systemctl >/dev/null 2>&1;then
	alias sc='systemctl'
	alias scs='systemctl status'
	alias scst='systemctl start'
	alias scsp='systemctl stop'
	alias scrs='systemctl restart'

	alias sc0a='systemctl stop apache2.service'
	alias sc1a='systemctl start apache2.service'
	alias scsa='systemctl status apache2.service'
	alias scrsa='systemctl restart apache2.service'
	alias scrla='systemctl reload apache2.service'

	alias scp0="systemctl stop php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias sc1p="systemctl start php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias scsp="systemctl status php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias scrsp="systemctl restart php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"
	alias scrlp="systemctl reload php\$(php --version|sed -n 's/^PHP \([0-9]\.[0-9]\).*/\1/;1p')-fpm.service"

	alias sc0m='systemctl stop mariadb.service'
	alias sc1m='systemctl start mariadb.service'
	alias scsm='systemctl status mariadb.service'
	alias scrsm='systemctl restart mariadb.service'
	alias scrsm='systemctl restart mariadb.service'

	alias sc0f='service firewall stop'
	alias sc1f='service firewall start'
	alias scsf='service firewall status'
	alias scrsf='service firewall restart'
	alias scrnf='service firewall restartnat'

	alias sc0h='systemctl stop haproxy'
	alias sc1h='systemctl start haproxy'
	alias scsh='systemctl status haproxy'
	alias scrsh='systemctl restart haproxy'
	alias scrlh='systemctl reload haproxy'

	alias sc0r='systemctl stop rsyslog'
	alias sc1r='systemctl start rsyslog'
	alias scsr='systemctl status rsyslog'
	alias scrrs='systemctl restart rsyslog'
	alias scrrl='systemctl reload rsyslog'
else
	alias sc0a='service apache2 stop'
	alias sc1a='service apache2 start'
	alias scsa='service apache2 status'
	alias scrsa='service apache2 restart'
	alias scrla='service apache2 reload'

	alias sc0m='service mysql stop'
	alias sc1m='service mysql start'
	alias scsm='service mysql status'
	alias scrsm='service mysql restart'
	alias scrlm='service mysql reload'

	alias sc0f='service firewall stop'
	alias sc1f='service firewall start'
	alias scsf='service firewall status'
	alias scrsf='service firewall restart'
	alias scrnf='service firewall restartnat'

	alias sc0h='service haproxy stop'
	alias sc1h='service haproxy start'
	alias scsh='service haproxy status'
	alias scrsh='service haproxy restart'
	alias scrlh='service haproxy reload'

	alias sc0r='service rsyslog stop'
	alias sc1r='service rsyslog start'
	alias scsr='service rsyslog status'
	alias scrrs='service rsyslog restart'
	alias scrrl='service rsyslog reload'
fi

# rsync
alias rsyncg='rsync --exclude .git'

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

# ssh
alias sshs='ssh-server'
alias sshs1='ssh-server node1'
alias sshs2='ssh-server node2'
alias sshpi='ssh root@pi -p2002'
alias sshcw='ssh coworkinur@ssh.cluster026.hosting.ovh.net'
alias sshvz='ssh-vz'
alias sshvx='ssh-lxd'
alias sshvk='ssh-kvm'
alias sshkr='ssh-keygen -R'

alias _sshd1='__sshd ambau1'

# iptables
alias iptl='iptables -nvL --line-number'
alias iptln='iptables -nvL -t nat --line-number'
alias iptls='iptables -S'
alias iptlsn='iptables -S -t nat'
alias iptlm='iptables -nvL -t mangle --line-number'
alias iptla='iptables -nvL --line-number; iptables -nvL -t nat --line-number'

###########################################  LXC
alias lxc1="lxc start"
alias lxc0="lxc stop"
alias lxc^="lxc restart"

# list
alias lxcla="lxc list --format=json | jq -r '.[].name' "
alias lxcl0="lxc list --format=json | jq -r '.[] | select(.status == \"Stopped\").name' "
alias lxcl1="lxc list --format=json | jq -r '.[] | select(.status == \"Running\").name' "
alias lxcl="lxc list -c nsP4tSc"

alias lxcil="lxc image list -c Lfptsu" # Lfpdtsu

#alias lxcln="lxc list --format=json | jq -r '.[] | select(.name | contains(\"'$name'\")) .name'"
#alias lxclp="lxc list --format=json | jq '.[] | select(.profiles | any(contains(\"'$profile'\"))) .name'"

#alias lxci='lxc info'
#alias lxcpl='lxc profile list'
#alias lxcps='lxc profile show'
#alias lxccl='lxc config trust list'
#alias lxc1='lxc start'
#alias lxc0='lxc stop'
#alias lxc^='lxc restart'
#alias lxc-='lxc delete'
#alias lxc-f='lxc delete --force'
#alias lxce='lxc exec'
#alias lxcil='lxc image list'
#alias lxcii='lxc image info'
#alias lxci-='lxc image delete'

#alias lxcxi='lxcx init'
#alias lxcxid='lxcx init debian8'
#alias lxcx1='lxcx start'
#alias lxcx0='lxcx stop'
#alias lxcx^='lxcx restart'
#alias lxcx-='lxcx delete'
#alias lxcx-f='lxcx -f delete'
#alias lxcxp='lxcx publish'
#alias lxcxpf='lxcx --force publish'

###########################################  BTRFS
alias btrfsf='btrfs filesystem'
alias btrfss='btrfs subvolume'
alias btrfssl='btrfs subvolume list -to'
#alias btrfssl1='btrfs subvolume list . |column -t |sort -k 9'
#alias btrfssc='btrfs subvolume create'
#alias btrfssd='btrfs subvolume delete'
#alias btrfsss='btrfs subvolume snapshot'
#alias btrfsfs='btrfs filesystem show'
#alias btrfsfu='btrfs filesystem usage'
#alias btrfsfdf='btrfs filesystem df'
#alias btrfsfd='btrfs filesystem defragment'
#alias btrfsfl='btrfs filesystem label'
#alias btrfsp='btrfs property -t s'

###########################################  ZFS
alias zpl='zpool list'
alias zplv='zpool list -v'
alias zpga='zpool get all'
alias zpg1='zpool get size,capacity,free,health,guid zroot'

alias zfsl='zfs list'
alias zfsga='zfs get all'
alias zfsg1='zfs get -o property,value creation,used,available,referenced,compressratio,mounted,readonly,quota'

###########################################  SNAPPER
#alias snapl='for i in $(snapper list-configs |sed -n "3,\$p" |awk "{print \$1}" |xargs); do echo -e "\e[1;34m\n$i\e[0;0m"; snapper -c $i list; done'
#alias snaplc='snapper list-configs'

###########################################  KVM
#alias kvmexp='export-kvm'
#alias slvr='/etc/init.d/libvirt-bin restart'

###########################################  PERSO
# Monitor logs
# alias syslog='tail -100f /var/log/syslog'
# alias messages='tail -100f /var/log/messages'

# Keep 1000 lines in .bash_history (default is 500)
#export HISTSIZE=2000
#export HISTFILESIZE=2000

###########################################  OPENVZ
alias nanoser='nano /etc/server/server.conf'
alias nanofir='nano /etc/server/firewall.conf'

# vz-list
alias vzl='vz-list -o ctid,numproc,status,hostname,name,ip'
alias vzla='vz-list -ao ctid,numproc,status,hostname,name,ip'
alias vzlS='vz-list -So ctid,numproc,status,hostname,name,ip'
alias vzld='vz-list -O diskspace,diskinodes'
alias vzlm='vz-list -O kmemsize,physpages,swappages'
alias vzlm2='vz-list -O oomguarpages,vmguarpages'
alias vzlcr='vz-list -Ho ctid|xargs'

# vz-clean
alias vzc='vz-clean'

# vz-ctl
#alias vz+='vz-ctl create'
#alias vz+t='vz-ctl create --tutorial'
alias vz-='vz-ctl destroy'
alias vz1='vz-ctl start -y'
alias vz0='vz-ctl stop -y'
alias vz^='vz-ctl restart -y'

# vz-iptables
alias vziptl='vz-iptables list'
alias vziptla='vz-iptables list -a'
alias vziptlS='vz-iptables list -S'
alias vzipt+='vz-iptables add'
alias vzipt-='vz-iptables del'

# vz-ip
alias vzipl='vz-ip list'
alias vzipla='vz-ip list -a'
alias vziplS='vz-ip list -S'
alias vzip+='vz-ip add'
alias vzip-='vz-ip del'

# vz-dump
alias vzd='vz-dump'
#alias vzd1='vz-dump -y --compress'
#alias vzd1t='vz-dump -y --compress --template'
#alias vzd2='vz-dump -y --compress --force'
#alias vzd2t='vz-dump -y --compress --template'

# vz-dump-all
#alias vzdall='vz-dump-all'

# vz-restore
alias vzr='vz-restore'
alias vzrl='vz-restore --list'
#alias vzrla='vz-restore --list --all'
#alias vzr1='vz-restore --menu'
#alias vzr2='vz-restore --menu --template'

# vz-launch
#alias vzlaunchup='vz-launch -v upgrade all'

