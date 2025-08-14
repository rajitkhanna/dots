#!/bin/bash
# Get WiFi interface name (usually en0 on Macs)
WIFI_INTERFACE="en0"

# Check if WiFi is connected
WIFI_STATUS=$(networksetup -getairportpower $WIFI_INTERFACE | awk '{print $4}')

if [ "$WIFI_STATUS" = "On" ]; then
  # Get WiFi name if connected
  WIFI_SSID=$(networksetup -getairportnetwork $WIFI_INTERFACE | cut -d ':' -f2 | sed 's/^[ \t]*//')
  
  # Create a temporary file for caching results
  CACHE_FILE="/tmp/networkquality_cache.txt"
  
  # Check if the cache file exists and is less than 5 minutes old
  if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE"))) -lt 300 ]; then
    # Use cached results
    NETWORK_QUALITY=$(cat "$CACHE_FILE")
  else
    # Run networkquality and cache the results
    NETWORK_QUALITY=$(networkquality | grep -E 'Uplink capacity|Downlink capacity')
    echo "$NETWORK_QUALITY" > "$CACHE_FILE"
  fi
  
  # Extract download and upload speeds (in Mbps)
  DOWNLOAD=$(echo "$NETWORK_QUALITY" | grep "Downlink capacity" | grep -oE '[0-9]+\.[0-9]+')
  UPLOAD=$(echo "$NETWORK_QUALITY" | grep "Uplink capacity" | grep -oE '[0-9]+\.[0-9]+')
  
  # Check if we got valid speed values
  if [ -z "$DOWNLOAD" ] || [ -z "$UPLOAD" ]; then
    sketchybar --set $NAME icon="􀙇" label="$WIFI_SSID"
    exit 0
  fi
  
  # Format speeds with one decimal place
  DOWNLOAD_SPEED=$(printf "%.1f" $DOWNLOAD)
  UPLOAD_SPEED=$(printf "%.1f" $UPLOAD)
  
  # Display the WiFi name, download, and upload speeds
  sketchybar --set $NAME icon="􀙇" label="↓${DOWNLOAD_SPEED}Mb ↑${UPLOAD_SPEED}Mb"
else
  # WiFi is turned off
  sketchybar --set $NAME icon="􀙈" label="Off"
fi
