#!/bin/sh
#
# Provides:               php-switch
# Short-Description:      modify environnement parameters to switch between dev/pro platform & debugger
# Description:            modify environnement parameters to switch between dev/pro platform & debugger

########################  FUNCTION


__init() {
	php_ver=$(php -v |xargs |sed "s/^PHP \([0-9]\.[0-9]\).*/\1/")

	if type rc-service >/dev/null 2>&1; then
		_RELEASE=alpine
		_FPM_SERVICE=`rc-service --list|grep php`
		_FPM_CONF="/etc/php7/php.ini"

	elif type systemctl >/dev/null 2>&1; then
		_RELEASE=debian
		_FPM_SERVICE="php${php_ver}-fpm"
		_FPM_CONF="/etc/php/${php_ver}/fpm/php.ini"

	else
		echo "[error] plateform not implemented" && exit 1
	fi
}

# reload php-fpm or apache service
__reload() {
	if [ ${RELEASE} = alpine ]; then
		rc-service ${_FPM_SERVICE} reload
	else
		systemctl reload ${_FPM_SERVICE}.service
	fi
}

# restart php-fpm or apache service
__restart() {
	if [ ${RELEASE} = alpine ]; then
		rc-service ${_FPM_SERVICE} restart
	else
		systemctl restart ${_FPM_SERVICE}.service
	fi
}

# active or desactive phpinf.php files
__phpinf() {
	case "$1" in
		on )
			for line in `find /var/www -name phpinf.php.keep`; do mv $line ${line%.keep}; done ;;
		off|* )
			for line in `find /var/www -name phpinf.php.keep`; do mv $line ${line}.keep; done ;;
	esac
}

# active or desactive catch_workers_output in php-fpm pool definition
__cache_worker() {
	case "$1" in
		on )
			grep catch_workers_output /etc/php* -rl | xargs sed -i "s|^;\?\(catch_workers_output =\).*|\1 yes|" ;;
		off|* )
			grep catch_workers_output /etc/php* -rl | xargs sed -i "s|^;\?\(catch_workers_output =\).*|\1 no|" ;;
	esac
}

__dev() {
	echo -n "conf ${action}"
	while read str val; do
		sed -i "s|^.\?\(${str}\s*=\).*|\1 ${val}|" "${_FPM_CONF}"
	done <<< "error_reporting E_ALL
display_errors  On
display_startup_errors  On
log_errors  On
report_zend_debug  On
track_errors  On
html_errors  On
session.gc_maxlifetime  14400
session.use_strict_mode  0"
	echo ok

	__phpinf on

	__cache_worker on

	case "$*" in
		on|restart ) __restart ;;
		off) ;;
		*|reload ) __reload ;;
	esac
}

__pro() {
	echo -n "conf ${action}"
	while read str val; do
		sed -i "s|^.\?\(${str}\s*=\).*|\1 ${val}|" "${_FPM_CONF}"
	done <<< "error_reporting E_ALL \& ~E_DEPRECATED \& ~E_STRICT
display_errors  Off
display_startup_errors  Off
log_errors  On
report_zend_debug  Off
track_errors  Off
html_errors  On
session.gc_maxlifetime  1800
session.use_strict_mode  1"
	echo ok

	__phpinf off

	__cache_worker off

	case "$*" in
		on|restart ) __restart ;;
		off) ;;
		*|reload ) __reload ;;
	esac
}

__phpenmod () {
	grep "$1" /etc/php* -rl | xargs sed -i "/^;zend_extension/ s|^;||"
}

__phpdismod () {
	grep "$1" /etc/php* -rl | xargs sed -i "/^zend_extension/ s|^|;|"
}

__debug() {

	case "$1" in
		xdebug|zend_debugger )
			for debug in ${_DEBUGS}; do __phpdismod ${debug}; done
			__phpenmod "$1"
			;;
		off|* )
			for debug in ${_DEBUGS}; do __phpdismod ${debug}; done
			;;
	esac

	case "$*" in
		on|restart ) __restart ;;
		off) ;;
		*|reload ) __reload ;;
	esac
}

########################  DATA

# WARNNING: let space before & after debugger names
_DEBUGS=" xdebug zend_debugger "


usage="php-switch : modify environnement parameters to switch between dev/pro platform & debugger
php-switch <command> <options>
php-switch --help

php-switch <dev/pro> <restart/reload/on/off>
	dev
        - developper environnement
        - active catch_workers_output in php-fpm pool definition
        - switch on phpinf.php
	pro
        - production environnement
        - desactive catch_workers_output in php-fpm pool definition
        - switch off phpinf.php

    restart/on               restart php & apache
    reload/(nothing)    reload or not service (php or apache)
    off                           do nothing

php-switch phpinf <on/off>
    on                           enable phpinf.php
    off                           disable phpinf.php

php-switch debug <debugger> <restart/reload/on/off>
	xdebug                  select xdebug
	zend_debugger    select zend_debugger

    restart/on               restart php & apache
    reload/(nothing)    reload or not service (php or apache)
    off                           do nothing
"

########################  MAIN

! type php >/dev/null 2>&1 && echo "[error] Unable to find php in this computer" && exit 1

__init

action="$1"
case "$1" in
	help|--help )
		echo "$usage"; exit  ;;
	* )
		shift; __${action} "$@"  ;;
esac
