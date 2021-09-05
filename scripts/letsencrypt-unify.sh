#!/bin/sh
#
# For haproxy:
# unify certificate and private key
# & generates a file with list of unified files

path_pem=/etc/server/ssl/private
path=/etc/letsencrypt/live

# unify
for cert in `ls ${path}/*/ -d`; do
	cert=`basename ${cert}`
	cat ${path}/${cert}/fullchain.pem ${path}/${cert}/privkey.pem > ${path_pem}/${cert}.pem
done

# generate list of pem files
echo "$(ls -1 ${path_pem} | grep -v ^letsencrypt)" > ${path_pem}/letsencrypt.pem.lst

# rights
chmod 600 ${path_pem}/*