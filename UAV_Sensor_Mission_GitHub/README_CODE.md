# UAV + Sensor + Mission Prototype

Phần code này chỉ dành cho 3 phần:
- Sensor Node
- UAV Gateway
- Mission Management

## Sensor Node
Mô phỏng 6 cảm biến:
1. Soil Moisture
2. Air Temperature
3. Air Humidity
4. Light Intensity
5. pH
6. Water Level

## UAV Gateway
Thu dữ liệu từ Sensor Node, lưu MySQL, lưu offline khi mất kết nối và đồng bộ lại khi có mạng.

## Mission Management
Tạo mission, waypoint, gắn sensor với waypoint và chạy mission theo thứ tự.

## Chạy
1. Chạy `sql/schema.sql` trong MySQL.
2. `pip install -r requirements.txt`
3. `cp .env.example .env`
4. Sửa `DB_PASSWORD` trong `.env`
5. Chạy `python src/main.py`
