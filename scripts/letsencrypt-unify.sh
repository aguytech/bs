#!/bin/sh
#
# For haproxy:
# unify certificate and private key
# & generates a file with list of unified files

path_share=/var/share/ssl
path_priv=/etc/server/ssl/private
path_live=/etc/letsencrypt/live

# unify
for domain in `ls ${path_live}/*/ -d 2>/dev/null`; do
	domain=`basename ${domain}`

	# shared
	[ "${domain#mail.}" = "${domain}" ] && path=${path_share}/${domain} || path=${path_share}/mail
	if [[ "${domain#mail.}" = "${domain}" && -d ${path} ]] || [ "${domain#mail.}" != "${domain}" ]; then
		cp -prL ${path_live}/${domain}/fullchain.pem ${path}/${domain}-fullchain.pem
		cp -prL ${path_live}/${domain}/privkey.pem ${path}/${domain}-privkey.pem
	fi
	
	# local
	if [ "${domain#mail.}" = "${domain}" ]; then
		cp -prL ${path_live}/${domain}/fullchain.pem ${path_priv}/${domain}-fullchain.pem
		cp -prL ${path_live}/${domain}/privkey.pem ${path_priv}/${domain}-privkey.pem
		cat ${path_live}/${domain}/fullchain.pem ${path_live}/${domain}/privkey.pem > ${path_priv}/${domain}.pem
	fi
done

# local: generate list of pem files
if [ "${domain#mail.}" = "${domain}" ]; then
	echo "$(ls -1 ${path_priv} | grep -v ^letsencrypt | grep -v '\-privkey.pem')" > ${path_priv}/letsencrypt.pem.lst
	# rights
	chmod 600 -R ${path_priv}
fi
