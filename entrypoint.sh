#!/bin/sh
set -e
exec rtl_433 -M level -M protocol -M noise -F "mqtt://${MQTT_HOST}:${MQTT_PORT},retain=0,events=${MQTT_TOPIC_PREFIX}/json" "$@"
