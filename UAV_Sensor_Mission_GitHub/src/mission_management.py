from datetime import datetime
from db import get_connection
from uav_gateway import UAVGateway

class MissionManager:
    def __init__(self, gateway: UAVGateway):
        self.gateway = gateway

    def create_demo_mission(self):
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO missions (
                mission_id, mission_name, gateway_id, status, start_time, end_time
            )
            VALUES ('M001','Thu thap du lieu Zone A/B','GW01','READY',NULL,NULL)
            ON DUPLICATE KEY UPDATE
                mission_name=VALUES(mission_name),
                gateway_id=VALUES(gateway_id),
                status='READY',
                start_time=NULL,
                end_time=NULL
            """
        )

        waypoints = [
            ("WP001","M001",1,"S001",10.7626000,106.6601000,20.00),
            ("WP002","M001",2,"S002",10.7627100,106.6602100,15.00),
            ("WP003","M001",3,"S003",10.7629000,106.6604000,20.00),
        ]

        for wp in waypoints:
            cursor.execute(
                """
                INSERT INTO waypoints (
                    waypoint_id, mission_id, sequence_no, sensor_id,
                    latitude, longitude, altitude, status
                )
                VALUES (%s,%s,%s,%s,%s,%s,%s,'WAITING')
                ON DUPLICATE KEY UPDATE
                    sensor_id=VALUES(sensor_id),
                    latitude=VALUES(latitude),
                    longitude=VALUES(longitude),
                    altitude=VALUES(altitude),
                    status='WAITING'
                """,
                wp,
            )

        conn.commit()
        cursor.close()
        conn.close()

    def run_mission(self, mission_id: str):
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute(
            "UPDATE missions SET status='RUNNING', start_time=%s, end_time=NULL WHERE mission_id=%s",
            (datetime.now(), mission_id),
        )
        conn.commit()

        cursor.execute(
            """
            SELECT w.waypoint_id, w.sequence_no, w.sensor_id,
                   w.latitude, w.longitude, w.altitude, s.zone_name
            FROM waypoints w
            JOIN sensor_nodes s ON s.sensor_id=w.sensor_id
            WHERE w.mission_id=%s
            ORDER BY w.sequence_no
            """,
            (mission_id,),
        )
        waypoints = cursor.fetchall()

        print(f"\n=== START MISSION {mission_id} ===")

        for wp in waypoints:
            cursor.execute(
                "UPDATE waypoints SET status='IN_PROGRESS' WHERE waypoint_id=%s",
                (wp["waypoint_id"],),
            )
            conn.commit()

            record = self.gateway.collect_from_sensor(wp["sensor_id"], wp["zone_name"])

            cursor.execute(
                "UPDATE waypoints SET status='REACHED' WHERE waypoint_id=%s",
                (wp["waypoint_id"],),
            )
            cursor.execute(
                """
                INSERT INTO mission_logs(mission_id, waypoint_id, message)
                VALUES (%s,%s,%s)
                """,
                (
                    mission_id,
                    wp["waypoint_id"],
                    f"Collected {wp['sensor_id']}: {record['storage_status']}",
                ),
            )
            conn.commit()

            print(
                f"{wp['waypoint_id']} -> {wp['sensor_id']} | "
                f"Soil={record['soil_moisture']}% | "
                f"Temp={record['air_temperature']}C | "
                f"Humidity={record['air_humidity']}% | "
                f"Light={record['light_intensity']} lux | "
                f"pH={record['ph_value']} | "
                f"Water={record['water_level']}% | "
                f"Battery={record['battery_after_collection']}%"
            )

        cursor.execute(
            "UPDATE missions SET status='COMPLETED', end_time=%s WHERE mission_id=%s",
            (datetime.now(), mission_id),
        )
        conn.commit()
        cursor.close()
        conn.close()

        synced = self.gateway.sync_buffer()
        print(f"\n=== MISSION {mission_id} COMPLETED ===")
        print(f"Remaining battery: {self.gateway.battery}%")
        print(f"Offline records synchronized: {synced}")
