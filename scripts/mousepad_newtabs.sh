#!/bin/bash
#
# Provides:             mousepad_newtab
# Short-Description:    A wrapper with xdotool for mousepad. Open new tab with URI in last mousepad window
# Description:          A wrapper with xdotool for mousepad. Open new tab with URI in last mousepad window

################################  MAIN

for uri in $uris; do
    if [ -f "$uri" ]; then # test uri is file
        echo -n "$(date +"%d-%m-%Y %T") - $uri" >> "$file_log"

        wid=( $(xdotool search --desktop $(xdotool get_desktop) --class $app) )
        lastwid=${wid[*]: -1} # Get PID of newest active $app window.

        # if $wid is null launch app with filepath.
        if [ -z "$wid" ]; then
            echo -n "$(date +"%d-%m-%Y %T") - thunar $uri" >> "$file_log"
            $app "$uri" &
            sleep 0.5s

            wid=( $(xdotool search --desktop $(xdotool get_desktop) --class $app) )
            lastwid=${wid[*]: -1} # Get PID of newest active thunar window.

        # if app is already running, activate it and use shortcuts to paste filepath into path bar.
        else
	        xdotool windowactivate --sync $lastwid key --delay 200 ctrl+o ctrl+l # Activate pathbar
            sleep 0.2s
	        xdotool type --clearmodifiers "$uri" # "--delay 0" removes default 12ms between each keystroke
 	        xdotool key Return
        fi

        echo " - OK"  >> "$file_log"
    else
        echo "$(date +"%d-%m-%Y %T") - $uri - FAILED: not exists" >> "$file_log"
    fi
done

exit 0

