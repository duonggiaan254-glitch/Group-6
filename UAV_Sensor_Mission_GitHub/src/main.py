from uav_gateway import UAVGateway
from mission_management import MissionManager

def main():
    gateway = UAVGateway("GW01", "UAV-FARM-01")
    manager = MissionManager(gateway)
    manager.create_demo_mission()
    manager.run_mission("M001")

if __name__ == "__main__":
    main()
