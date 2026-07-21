#!/bin/sh
set -e
exec rtl_433 -F "mqtt://${MQTT_HOST}:${MQTT_PORT},retain=0,events=${MQTT_TOPIC_PREFIX}/json/" "$@"
