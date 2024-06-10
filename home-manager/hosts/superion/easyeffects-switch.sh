#!/usr/bin/env bash

ICON=@icon@
NOTIFY_TITLE="EasyEffects"
PRESETS=$(easyeffects -p |grep ^Output |sed -e 's/^.*Presets: //')
COMMAS=${PRESETS//[^,]}
NUM_PRESETS=${#COMMAS}

if systemctl is-active --quiet --user easyeffects.service; then
  DMENU_MSG="Select preset"
  NOTIFY_MSG="Switched to preset"
  START_EE=0
else
  DMENU_MSG="Select preset (EasyEffects will be started)"
  NOTIFY_MSG="Started service and switched to preset"
  START_EE=1
fi

EE_PRESET=$(echo $PRESETS|sed -e 's/,$//' -e 's/,/\n/g' |rofi -dmenu -p "$DMENU_MSG" -no-fixed-num-lines -lines $NUM_PRESETS -theme-str 'window {width: 28%;}')

if [ $EE_PRESET ]; then
  if [ $START_EE ]; then
    systemctl start --user easyeffects.service
    sleep 0.5
  fi
  easyeffects -l $EE_PRESET
  notify-send --expire-time 2500 --icon $ICON "EasyEffects" "$NOTIFY_MSG $EE_PRESET"
fi
