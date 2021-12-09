#!/bin/sh
#
# For haproxy:
# unify certificate and private key
# & generates a file with list of unified files

path_ssl_mail=/var/share/ssl/mail
path_ssl=/var/share/ssl/haproxy
path_letsencrypt=/var/share/ssl/letsencrypt
path_live=/etc/letsencrypt/live

# unify
for domain in `ls ${path_live}/*/ -d 2>/dev/null`; do
	domain=`basename ${domain}`

	[ "${domain#mail.}" = "${domain}" ] && path=${path_ssl} || path=${path_ssl_mail}
	if [ "${path}" ]; then
		cp -prL ${path_live}/${domain}/fullchain.pem ${path}/certs/${domain}-fullchain.pem
		cp -prL ${path_live}/${domain}/privkey.pem ${path}/private/${domain}-privkey.pem
		chmod g=,o= -R ${path}/private
	fi
	
	cat ${path_live}/${domain}/fullchain.pem ${path_live}/${domain}/privkey.pem > ${path_ssl}/haproxy/${domain}.pem
done

# generate list of pem files
ls -1 ${path_ssl}/haproxy/*.pem > ${path_ssl}/certbot.pem.lst
