#!/bin/bash
#
# Provides:				logwatch-vm
# Short-Description:	launch logwatch per service for each virtual machine
# Description:			launch logwatch per service for each virtual machine

################################ GLOBAL FUNCTIONS
#S_TRACE=debug

S_GLOBAL_FUNCTIONS="${S_GLOBAL_FUNCTIONS:-/usr/local/bs/inc-functions.sh}"
! . "$S_GLOBAL_FUNCTIONS" && echo -e "[error] - Unable to source file '$S_GLOBAL_FUNCTIONS' from '${BASH_SOURCE[0]}'" && exit 1

################################  VARIABLES

declare -A ctids
declare -A logfiles
declare -A archifiles
declare -A details
declare -A ranges

declare -A variables


fileid=/tmp/$(cat /proc/sys/kernel/random/uuid |head -c 8)
ctidall=$(vzlist -Ho ctid)
dirhtml=/usr/share/logwatch/default.conf/html
logdir=/etc/logwatch/conf/logfiles

# define a list of service to treate
#services="zz-disk_space sshd dpkg http http-error mysql postfix"
services="sshd dpkg http http-error php mysql"
output=stdout
format=html

formatmail=$([ "$format" == "text" ] && echo "text/plain" || echo "text/html")

# zz-disk_space
ctids[zz-disk_space]=$ctidall
details[zz-disk_space]=10
#ranges[zz-disk_space]=yesterday

# sshd
ctids[sshd]=$ctidall
logfiles[sshd]='LogFile = /vz/node/$ctid/log/messages\nLogFile = /vz/node/$ctid/log/messages.1'
archifiles[sshd]='Archive = /vz/node/$ctid/log/messages.*.gz'
variables[sshd]='*OnlyService = sshd\n*RemoveHeaders'
details[sshd]=5
#ranges[sshd]=yesterday

# dpkg
ctids[dpkg]=$ctidall
logfiles[dpkg]='LogFile = /vz/node/$ctid/log/dpkg.log\nLogFile = /vz/node/$ctid/log/dpkg.log.1'
archifiles[dpkg]='Archive = /vz/node/$ctid/log/dpkg.log.*.gz'
variables[dpkg]=''
details[dpkg]=5
#ranges[dpkg]=yesterday

# http
ctids[http]=$(vzlist -Ho ctid,hostname |grep -E "php|apache" |sed "s/^ \+\([0-9]\{3\}\) .*$/\1/")
logfiles[http]='LogFile = /vz/node/$ctid/log/apache2/*access.log\nLogFile = /vz/node/$ctid/log/apache2/*access.log.1'
archifiles[http]='Archive = /vz/node/$ctid/log/apache2/*access.log.*.gz'
variables[http]='*ExpandRepeats\n *ApplyhttpDate'
details[http]=5
#ranges[http]=yesterday

# http-error
ctids[http-error]=$(vzlist -Ho ctid,hostname |grep -E "php|apache" |sed "s/^ \+\([0-9]\{3\}\) .*$/\1/")
logfiles[http-error]='LogFile = /vz/node/$ctid/log/apache2/*error.log\nLogFile = /vz/node/$ctid/log/apache2/*error.log.1'
archifiles[http-error]='Archive = /vz/node/$ctid/log/apache2/*error.log.*.gz'
variables[http-error]='*ExpandRepeats'
details[http-error]=10
#ranges[http-error]=yesterday

# php
ctids[php]=$(vzlist -h "*-php*" -Ho ctid)
logfiles[php]='LogFile = /vz/node/$ctid/log/php/*.log\nLogFile = /vz/node/$ctid/log/php/*.log.1'
archifiles[php]='Archive = /vz/node/$ctid/log/php/*.log.*.gz'
variables[php]=''
details[php]=10
#ranges[php]=yesterday

# mysql
ctids[mysql]=$(vzlist -h "*-maria*" -Ho ctid)
logfiles[mysql]='LogFile = /vz/node/$ctid/log/mysql/error.log\nLogFile = /vz/node/$ctid/log/mysql/error.log.1'
archifiles[mysql]='Archive = /vz/node/$ctid/log/mysql/error.log.*.gz'
variables[mysql]='*ExpandRepeats'
details[mysql]=10
#ranges[mysql]=yesterday

_SCRIPT=${0##*/}; _SCRIPT=${_SCRIPT%.*}
white='\e[0;0m'; red='\e[0;31m'; green='\e[0;32m'; blue='\e[0;34m'; magenta='\e[0;35m'
whiteb='\e[1;1m'; redb='\e[1;31m'; greenb='\e[1;32m'; blueb='\e[1;34m'; magentab='\e[1;35m';cclear='\e[0;m'

################################  COMMON

_mail() {
	(
	echo "From: logwatch@$HOSTNAME";
	echo "To: $S_DOMAIN_EMAIL_TECH";
	echo "Subject: $1";
	echo "MIME-Version: 1.0";
	echo "Content-Type: $formatmail; charset=iso-8859-1";
	cat "$2";
	) | sendmail -t
}

[ -e $dirhtml/header.html ] && mv $dirhtml/header.html $dirhtml/header.html.tmp
[ -e $dirhtml/footer.html ] && mv $dirhtml/footer.html $dirhtml/footer.html.tmp
touch $dirhtml/header.html
touch $dirhtml/footer.html

# select only ctid in production
ctidprod=
for ctid in $ctidall; do [ $ctid -lt 200 ] && ctidprod+=" $ctid"; done

for ctid in $ctidprod
#for ctid in 101 120
do

	servicesmade=

	echo "> $ctid"
	for service in $services
	do
		ctidtmp=${ctids[$service]}

		if [ "$ctidtmp" != "${ctidtmp/$ctid/}" ]; then
			servicesmade+=" $service"

			if [ "${logfiles[$service]}" ]
			then
				file=$logdir/$service.conf
				[ -e $file ] && mv $file $file.tmp

				str="echo -e \"# Logfile definition for $service / container $ctid\n########################################################\nTitle = $service\nLogFile =\nArchive =\n"
				[ "${logfiles[$service]}" ] && str+="${logfiles[$service]}\n"
				[ "${archifiles[$service]}" ] && str+="${archifiles[$service]}\n"
				[ "${variables[$service]}" ] && str+="${variables[$service]}\n"
				str+="\" > $file"
				eval $str
				cp $file $logdir/$service-$ctid.conf

			fi

			cmd="logwatch --service $service --output $output --format $format"
			[ "${details[$service]}" ] && cmd+=" --detail ${details[$service]}"
			[ "${ranges[$service]}" ] && cmd+=" --range ${ranges[$service]}"
			cmd+=" $*"
			cmd+=" $* >> $fileid-$ctid"
			#echo $cmd
			eval $cmd

			[ -e $file.tmp ] && mv $file.tmp $file

		fi

	done

	if [ -e $fileid-$ctid ]
	then

		cat $dirhtml/header.html.tmp $fileid-$ctid $dirhtml/footer.html.tmp > $fileid-$ctid-tmp
		mv $fileid-$ctid-tmp $fileid-$ctid
		sed -i "s|^\( *td .* font-size: \).*\(; }\)$|\11em\2|" $fileid-$ctid

		sed -i '/.*<li><a href="#1">LOGWATCH Summary<\/a>.*/d' $fileid-$ctid
		sed -i '/.*<h2><a name="1">LOGWATCH Summary<\/a><\/h2>.*/d' $fileid-$ctid
		sed -i '/.*Logwatch Ended.*/d' $fileid-$ctid

		str=

		#echo "servicesmade : $servicesmade"
		for servicemade in $servicesmade
		do
			str+="<li><a href=\"#$servicemade\">$servicemade</a>\n"
			[ "$servicemade" == "sshd" ]	&& sed -i "s|^\(.*<li><a href=\"#\).\(\">$servicemade<\/a>.*\)$|\1$servicemade\2|" $fileid-$ctid \
							|| sed -i "/.*<li><a href=\"#.\">$servicemade<\/a>.*/d" $fileid-$ctid
			sed -i "s|^\(.*<h2><a name=\"\).\(\">$servicemade</a></h2>.*\)$|\1$servicemade\2|" $fileid-$ctid
		done

		sed -i "s|^\(.*<li><a href=\"#sshd\">sshd</a>.*\)$|$str|" $fileid-$ctid

		_mail "[Logwatch] $HOSTNAME - $ctid" "$fileid-$ctid" "text/plain"
	fi

done

[ -e $dirhtml/header.html.tmp ] && mv $dirhtml/header.html.tmp $dirhtml/header.html
[ -e $dirhtml/footer.html.tmp ] && mv $dirhtml/footer.html.tmp $dirhtml/footer.html

exit
