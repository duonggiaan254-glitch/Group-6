from dataclasses import dataclass
from datetime import datetime
import random

@dataclass
class SensorNode:
    sensor_id: str
    zone_name: str

    def read_all(self) -> dict:
        return {
            "sensor_id": self.sensor_id,
            "zone_name": self.zone_name,
            "soil_moisture": round(random.uniform(25.0, 85.0), 2),
            "air_temperature": round(random.uniform(20.0, 38.0), 2),
            "air_humidity": round(random.uniform(45.0, 95.0), 2),
            "light_intensity": round(random.uniform(500.0, 80000.0), 2),
            "ph_value": round(random.uniform(5.0, 7.5), 2),
            "water_level": round(random.uniform(10.0, 100.0), 2),
            "collected_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }

if __name__ == "__main__":
    print(SensorNode("S001", "Zone A").read_all())
