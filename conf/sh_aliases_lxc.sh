#!/bin/sh

# global
alias l='ls -CF --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias df='df -h'
alias nanoc='nano -wY conf'
alias ced='clean-keep && etrash'
alias histg='history|grep'
alias histgs="history|sed 's|^ \+[0-9]\+ \+||'|grep"
alias dfs="df -x tmpfs -x devtmpfs | grep -v /dev/ploop"

########################  SERVER
# global
alias chn='chown nobody:nobody'
alias chnr='chown -R nobody:nobody'
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
	# haproxy
	alias sc0h='rc-service haproxy stop'
	alias sc1h='rc-service haproxy start'
	alias scrsh='rc-service haproxy restart'
	alias scrlh='rc-service haproxy reload'
	alias scsh='rc-status default|grep haproxy'
	# rsyslog
	alias sc0r='rc-service rsyslog stop'
	alias sc1r='rc-service rsyslog start'
	alias scrsr='rc-service rsyslog restart'
	alias scrlr='rc-service rsyslog reload'
	alias scsr='rc-status default|grep rsyslog'
fi
