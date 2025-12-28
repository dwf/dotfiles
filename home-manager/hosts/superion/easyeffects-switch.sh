#!/usr/bin/env bash

ICON=@icon@
NOTIFY_TITLE="EasyEffects"
PRESETS=$(find "$HOME"/.local/share/easyeffects/output/ -name '*.json' | sed -e 's/^.*\///' -e 's/.json$//')
NEWLINES=${PRESETS//[^\n]}
NUM_PRESETS=${#NEWLINES}

if systemctl is-active --quiet --user easyeffects.service; then
  DMENU_MSG="Select preset"
  NOTIFY_MSG="Switched to preset"
  START_EE=0
else
  DMENU_MSG="Select preset (EasyEffects will be started)"
  NOTIFY_MSG="Started service and switched to preset"
  START_EE=1
fi

EE_PRESET=$(echo "$PRESETS" |sed -e 's/ /\n/g' |rofi -dmenu -p "$DMENU_MSG" -no-fixed-num-lines -lines "$NUM_PRESETS" -theme-str 'window {width: 28%;}')

if [ "$EE_PRESET" ]; then
  if [ $START_EE ]; then
    systemctl start --user easyeffects.service
    sleep 0.5
  fi
  easyeffects -l "$EE_PRESET"
  notify-send --expire-time 2500 "$NOTIFY_TITLE" "$NOTIFY_MSG $EE_PRESET" --icon "$ICON"
fi
