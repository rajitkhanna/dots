#!/bin/bash
sketchybar --add item wifi right \
           --set wifi update_freq=1500 \
                     script="$PLUGIN_DIR/wifi.sh" \
           --subscribe wifi wifi_change system_woke
