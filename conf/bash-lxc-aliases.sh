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
alias nanoc='nano -wY conf'
alias grep='grep --color'
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

