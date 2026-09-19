import json
from pathlib import Path
from typing import Dict

from db import get_connection
from sensor_node import SensorNode

BUFFER_FILE = Path(__file__).resolve().parent.parent / "gateway_buffer.jsonl"

class UAVGateway:
    def __init__(self, gateway_id="GW01", uav_name="UAV-FARM-01"):
        self.gateway_id = gateway_id
        self.uav_name = uav_name
        self.battery = 100.0

    def collect_from_sensor(self, sensor_id: str, zone_name: str) -> Dict:
        record = SensorNode(sensor_id, zone_name).read_all()
        record["storage_status"] = self.save_or_buffer(record)
        self.battery = max(0.0, self.battery - 3.0)
        self.update_gateway_status()
        record["battery_after_collection"] = self.battery
        return record

    def save_or_buffer(self, record: Dict) -> str:
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO sensor_measurements (
                    sensor_id, soil_moisture, air_temperature, air_humidity,
                    light_intensity, ph_value, water_level, collected_at, source
                )
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,'UAV_GATEWAY')
                """,
                (
                    record["sensor_id"], record["soil_moisture"],
                    record["air_temperature"], record["air_humidity"],
                    record["light_intensity"], record["ph_value"],
                    record["water_level"], record["collected_at"],
                ),
            )
            conn.commit()
            cursor.close()
            conn.close()
            return "SAVED_TO_MYSQL"
        except Exception as exc:
            with BUFFER_FILE.open("a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
            print(f"[Gateway] MySQL unavailable -> buffered locally: {exc}")
            return "BUFFERED_OFFLINE"

    def sync_buffer(self) -> int:
        if not BUFFER_FILE.exists():
            return 0

        lines = BUFFER_FILE.read_text(encoding="utf-8").splitlines()
        remaining = []
        synced = 0

        for line in lines:
            record = json.loads(line)
            try:
                conn = get_connection()
                cursor = conn.cursor()
                cursor.execute(
                    """
                    INSERT INTO sensor_measurements (
                        sensor_id, soil_moisture, air_temperature, air_humidity,
                        light_intensity, ph_value, water_level, collected_at, source
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,'UAV_GATEWAY_SYNC')
                    """,
                    (
                        record["sensor_id"], record["soil_moisture"],
                        record["air_temperature"], record["air_humidity"],
                        record["light_intensity"], record["ph_value"],
                        record["water_level"], record["collected_at"],
                    ),
                )
                conn.commit()
                cursor.close()
                conn.close()
                synced += 1
            except Exception:
                remaining.append(line)

        if remaining:
            BUFFER_FILE.write_text("\n".join(remaining) + "\n", encoding="utf-8")
        else:
            BUFFER_FILE.unlink(missing_ok=True)

        return synced

    def update_gateway_status(self):
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.execute(
                """
                UPDATE uav_gateways
                SET battery=%s, status=%s
                WHERE gateway_id=%s
                """,
                (
                    self.battery,
                    "LOW_BATTERY" if self.battery < 20 else "AVAILABLE",
                    self.gateway_id,
                ),
            )
            conn.commit()
            cursor.close()
            conn.close()
        except Exception:
            pass
