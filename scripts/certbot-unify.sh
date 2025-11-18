#!/bin/sh
#
# For haproxy:
# unify certificate and private key
# & generates a file with list of unified files

pth_ssl_mail=/var/share/ssl/mail
pth_ssl=/var/share/ssl/haproxy
pth_letsencrypt=/var/share/ssl/letsencrypt
pth_live=/etc/letsencrypt/live

# unify
for domain in `ls ${pth_live}/*/ -d 2>/dev/null`; do
	domain=`basename ${domain}`

	[ "${domain#mail.}" = "${domain}" ] && pth=${pth_ssl} || pth=${pth_ssl_mail}
	if [ -d "${pth}" ]; then
		cp -prL ${pth_live}/${domain}/fullchain.pem ${pth}/certs/${domain}-fullchain.pem
		cp -prL ${pth_live}/${domain}/privkey.pem ${pth}/private/${domain}-privkey.pem
		chmod g=,o= -R ${pth}/private

		cat ${pth_live}/${domain}/fullchain.pem ${pth_live}/${domain}/privkey.pem > ${pth_ssl}/haproxy/${domain}.pem
	fi
done

# generate list of pem files
ls -1 ${pth_ssl}/haproxy/*.pem > ${pth_ssl}/certbot.pem.lst
