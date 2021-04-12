#!/bin/bash
#
# Provides:               ssh-kvm
# Short-Description:      connect with ssh to kvm server & vm inside
# Description:            connect with ssh to kvm server & vm inside


# settings
UserD=root # default user
PortD=22 # default port
CertD= # default certificat

dirBase="/etc/libvirt/qemu"
dirNet="$dirBase/networks"

#declare -A Ip=(   [lucid-web]='192.168.100.100'  [lucid-sgbd]='192.168.100.110'  [tuleap]='192.168.100.120'  )

#Name=( lucid-web                lucid-sgbd               tuleap          )
#Ip=(   10.1.1.100               10.1.1.110               10.1.1.120      )
#User=( root                     root                     root            )
#Port=( 22                       22                       22              )
#Cert=( ''                       ''                       ''              )

# manual settings
#Name=( [lucid-web]='lucid-web'        [lucid-sgbd]='lucid-sgbd'       [tuleap]='tuleap'           )
#Ip=(   [lucid-web]='10.1.1.100'       [lucid-sgbd]='10.1.1.110'       [tuleap]='10.1.1.120'       )
#User=( [lucid-web]=$UserD             [lucid-sgbd]=$UserD             [tuleap]=$UserD             )
#Port=( [lucid-web]=$PortD             [lucid-sgbd]=$PortD             [tuleap]=$PortD             )
#Cert=( [lucid-web]=''                 [lucid-sgbd]=''                 [tuleap]=''                 )

###################################### Do not touch after this

# conf
declare -A Ip; declare -A User; declare -A Port; declare -A Cert
red='\e[31m';

if ! [ -d $dirBase ]; then echo -e "${redb}path '$dirBase' doesn't exists${resetb}" exit 1; fi
if ! [ "$(ls $dirBase/*.xml)" ]; then echo -e "${redb}No xml files in '$dirBase'${resetb}" exit 1; fi

# auto settings from reserved IPs by qemu DHCP
Macs=$(sudo grep "<mac address=" $dirBase/*.xml | sed  "s/^.*<mac address='\(.*\)'.*$/\1/")
for Mac in $Macs
do
	line=$(sudo grep $Mac $dirNet/*.xml )
	if [ "$line" ]
	then
		name=$(echo $line | sed "s/^.*name='\(.*\)' ip.*$/\1/")
		Ip[$name]=$(echo $line | sed "s/^.*ip='\(.*\)'.*$/\1/")
		User[$name]=$UserD
		Port[$name]=$PortD
		Cert[$name]=$CertD
	fi
done

select opt in $(printf '%s\n' "${!Ip[@]}" | sort -s)
do
	if [ "$opt" ]
	then
		Command="ssh "$(if [ "${Cert[$opt]}" ]; then echo "-i ${Cert[$opt]} "; fi)
		Command+="${User[$opt]}@${Ip[$opt]} -p${Port[$opt]}"
		
		echo $Command
		eval $Command
	else
		echo -e "\nVeuillez saisir une option valide en recommençant"
	fi
break
done

exit 0
