FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends rtl-433 && \
    rm -rf /var/lib/apt/lists/*

ENV MQTT_HOST=mosquitto.default.svc.cluster.local
ENV MQTT_PORT=1883
ENV MQTT_TOPIC_PREFIX=rtl_433

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["/entrypoint.sh"]
