#!/bin/sh
#
# Provides:               php-switch
# Short-Description:      modify environnement parameters to switch between dev/pro platform & debugger
# Description:            modify environnement parameters to switch between dev/pro platform & debugger

########################  FUNCTION

# reload php-fpm or apache service
__reload() {
	if [ $RELEASE = alpine ]; then
		_eval rc-service ${phpfpm_service} reload
	else
		_eval systemctl reload ${phpfpm_service}.service
	fi
}

# restart php-fpm or apache service
__restart() {
	if [ $RELEASE = alpine ]; then
		_eval rc-service ${phpfpm_service} restart
	else
		_eval systemctl restart ${phpfpm_service}.service
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
	echo -n "conf $action"
	sch='error_reporting';         str='E_ALL';        sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='display_errors';          str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='display_startup_errors';  str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='log_errors';              str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='log_errors_max_len';      str='1024';         sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='report_zend_debug';       str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='track_errors';            str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='html_errors';             str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='session\.gc_maxlifetime'; str='14400';        sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='session.use_strict_mode'; str='0';            sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	echo " - ok"

	__phpinf "on"

	__cache_worker "on"

	case "$*" in
		on|restart ) __restart ;;
		off ) ;;
		*|reload ) __reload ;;
	esac
}

__pro() {
	echo -n "conf $action"
	sch='error_reporting';         str='E_ALL \& ~E_DEPRECATED \& ~E_STRICT';        sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='display_errors';          str='Off';          sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='display_startup_errors';  str='Off';          sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='log_errors';              str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='log_errors_max_len';      str='1024';         sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='report_zend_debug';       str='Off';          sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='track_errors';            str='Off';          sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='html_errors';             str='On';           sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='session\.gc_maxlifetime'; str='1800';         sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	sch='session.use_strict_mode'; str='1';            sed -i "s|^.\?\($sch\s*=\).*|\1 $str|" "$php_conf"
	echo " - ok"

	__phpinf "off"

	__cache_worker "off"

	case "$*" in
		on|restart ) __restart ;;
		off ) ;;
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
			for debuguer in $debuguers; do __phpdismod $debuguer; done
			__phpenmod "$1"
			;;
		off|* )
			for debuguer in $debuguers; do __phpdismod $debuguer; done
			;;
	esac

	# restart
	[ "$2" != "off" ] && __restart
}

########################  INIT

! type php >/dev/null 2>&1 && _exite "Unable to find php on this computer"

########################  VARIABLES

php_ver=$(php -v |xargs |sed "s/^PHP \([0-9]\.[0-9]\).*/\1/")
if [ $RELEASE = alpine ]; then
	phpfpm_service=`rc-service --list|grep php`
	php_conf="/etc/php7/php.ini"
else
	phpfpm_service="php${php_ver}-fpm"
	php_conf="/etc/php/${php_ver}/fpm/php.ini"
fi


# WARNNING: let space before & after debugger names
debuguers=" xdebug zend_debugger "


usage="php-switch : modify environnement parameters to switch between dev/pro platform & debugger
php-switch <command> <options>
php-switch --help

php-switch dev <on/off>            configure php for
                                       - developper environnement
                                       - active catch_workers_output in php-fpm pool definition
                                       - switch on phpinf
                                   on/off: restart or not service (php or apache)
php-switch pro <on/off>            configure php for
                                       - production environnement
                                       - desactive catch_workers_output in php-fpm pool definition
                                       - switch off phpinf
                                   on/off: restart or not service (php or apache)
php-switch phpinf <on/off>         activate or desactivate phpinf.php (switch to phpinf.php.keep)
php-switch debug <debugger> <off>  switch to selected debugger : xdebug / zend_debugger
                                   on/off: restart or not service (php or apache)
"

########################  MAIN
#_clean && _redirect debug

action="$1"
case "$1" in
	help|--help )
		echo "$usage"
		exit
		;;
	dev )
		shift
		__$action "$@"
		;;
	pro )
		shift
		__$action "$@"
		;;
	debug )
		shift
		__$action "$@"
		;;
	phpinf )
		shift
		__$action "$@"
		;;
	* )
esac
