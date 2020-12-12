#!/bin/bash
#
# Provides:				vz-dump-all
# Short-Description:	dump all vms, over vzdump
# Description:			dump all vms, over vzdump


# openvz server
type vz-dump &>/dev/null && VZDUMP="vz-dump" || VZDUMP="/usr/local/bs/vz-dump"
type ${VZDUMP} &>/dev/null || _exite "unable to find vz-dump command"

type vzlist &>/dev/null && VZLIST="vzlist" || VZLIST="/usr/sbin/vzlist"
type ${VZLIST} &>/dev/null || _exite "unable to find vzlist command"

blueb='\e[1;34m'; cclear='\e[0;0m'

echo -e "${blueb}start vzdump for all containers\n$(${VZLIST} -Ho ctid|xargs)${cclear}"

#vz-ctl stop -y all && ${VZDUMP} -cy 101-199 && ${VZDUMP} -cty 200-254 && vz-ctl start -y all
${VZDUMP} -cfy 101-199

# template
${VZDUMP} -cfty 200-254
