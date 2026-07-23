# Radio → Database Message Flow

How a 433 MHz sensor reading gets from the air to Postgres, spanning this repo
(`kubernetes-rtl-433-sender`) and `kubernetes-mosquito`.

```mermaid
flowchart LR
    S1["433 MHz sensors<br/>(weather / temp / wind)"]

    subgraph SENDER["kubernetes-rtl-433-sender"]
        DONGLE["RTL-SDR USB dongle"]
        RTL433["rtl_433 CLI<br/>-M level -M protocol -M noise"]
        DONGLE --> RTL433
    end

    subgraph BROKER["kubernetes-mosquito"]
        MQ[["Mosquitto broker<br/>topic: rtl_433/#"]]
        READER["mqtt-reader<br/>reader.py"]
        CRON["reading-age-updater<br/>CronJob · every 1 min"]
        MQ -- "subscribe rtl_433/#" --> READER
    end

    subgraph DB["PostgreSQL · sdr433"]
        RECENT[("recent_readings<br/>1 row per unit")]
        ALLR[("all_readings<br/>append-only history")]
    end

    S1 -- "RF signal" --> DONGLE
    RTL433 -- "JSON over MQTT<br/>rtl_433/json" --> MQ
    READER -- "UPSERT by unit" --> RECENT
    READER -- "INSERT, on conflict do nothing" --> ALLR
    CRON -- "UPDATE reading_age_minutes,<br/>local_time" --> RECENT
```

## Hop by hop

| Stage | Component | Detail |
| --- | --- | --- |
| Capture | RTL-SDR + `rtl_433` | USB dongle picks up 433 MHz RF from wireless sensors; the `rtl_433` CLI (run via `entrypoint.sh`) demodulates and decodes it into JSON. |
| Publish | `rtl_433` → MQTT | Decoded readings are published as JSON to `rtl_433/json` on the broker, unretained. |
| Broker | Mosquitto 2 | Single-replica broker, anonymous access, in-cluster at `mosquitto.default.svc.cluster.local:1883`. |
| Consume | `mqtt-reader` | Subscribes to `rtl_433/#`, parses each payload, and writes two records per message. |
| Persist | PostgreSQL (`sdr433`) | `prod-postgres-rw`, credentials from the `sdr433-role-credentials` secret. |
| Enrich | `reading-age-updater` | Minutely CronJob recomputes reading age and local time on `recent_readings`. |

## The two tables `mqtt-reader` writes

- **`recent_readings`** — latest snapshot per device, one row per `unit`
  (model + sensor type + id/channel), upserted on every message. Refreshed
  with `reading_age_minutes` and `local_time` every minute.
- **`all_readings`** — full append-only history: `timestamp, model, id,
  channel, reading`. Duplicate inserts are silently dropped (`on conflict
  do nothing`).
