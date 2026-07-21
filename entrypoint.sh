#!/bin/sh
set -e
exec rtl_433 -F "mqtt://${MQTT_HOST}:${MQTT_PORT},retain=0,devices=${MQTT_TOPIC_PREFIX}/[model]/[id]" -F kv "$@"
