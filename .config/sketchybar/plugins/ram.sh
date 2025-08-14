#!/bin/bash
TOTAL_MEMORY=$(sysctl -n hw.memsize)
USED_MEMORY=$(vm_stat | grep "Pages active\|Pages wired down\|Pages occupied by compressor" | awk '{sum += $NF} END {print sum * 4096}')
RAM_PERCENT="$(echo "$USED_MEMORY $TOTAL_MEMORY" | awk '{printf "%.0f\n", ($1 / $2) * 100}')"
sketchybar --set $NAME label="$RAM_PERCENT%"
