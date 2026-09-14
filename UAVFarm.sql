-- Tạo Database
CREATE DATABASE IF NOT EXISTS UAVFarmDB
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE UAVFarmDB;

-- 1. Role
CREATE TABLE Role(
    RoleID VARCHAR(20) PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE
);

-- 2. User
CREATE TABLE `User`(
    UserID VARCHAR(20) PRIMARY KEY,
    RoleID VARCHAR(20) NOT NULL,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName VARCHAR(100),
    Status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    LastLoginAt DATETIME NULL,

    FOREIGN KEY(RoleID) REFERENCES Role(RoleID)
);

-- 3. Farm
CREATE TABLE Farm(
    FarmID VARCHAR(20) PRIMARY KEY,
    FarmName VARCHAR(100) NOT NULL,
    Description TEXT,
    Address VARCHAR(255),
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Status VARCHAR(20) DEFAULT 'Active',
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 4. Zone
CREATE TABLE Zone(
    ZoneID VARCHAR(20) PRIMARY KEY,
    FarmID VARCHAR(20) NOT NULL,
    ZoneName VARCHAR(100) NOT NULL,
    Description TEXT,
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Status VARCHAR(20) DEFAULT 'Active',

    FOREIGN KEY(FarmID) REFERENCES Farm(FarmID)
);

-- 5. SensorType
CREATE TABLE SensorType(
    SensorTypeID VARCHAR(20) PRIMARY KEY,
    TypeName VARCHAR(50) NOT NULL UNIQUE,
    Unit VARCHAR(20),
    Description TEXT
);

-- 6. SensorNode
CREATE TABLE SensorNode(
    SensorID VARCHAR(20) PRIMARY KEY,
    ZoneID VARCHAR(20) NOT NULL,
    SensorCode VARCHAR(50) NOT NULL UNIQUE,
    SerialNumber VARCHAR(50) NOT NULL UNIQUE,
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    BatteryLevel DECIMAL(5,2),
    Status VARCHAR(20) DEFAULT 'Active',
    RegisteredAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    LastSeenAt DATETIME NULL,

    FOREIGN KEY(ZoneID) REFERENCES Zone(ZoneID),

    CHECK(BatteryLevel IS NULL OR
          (BatteryLevel >= 0 AND BatteryLevel <= 100))
);

-- 7. SensorData
CREATE TABLE SensorData(
    DataID VARCHAR(20) PRIMARY KEY,
    SensorID VARCHAR(20) NOT NULL,
    SensorTypeID VARCHAR(20) NOT NULL,
    MeasuredValue DECIMAL(10,2) NOT NULL,
    MeasuredAt DATETIME NOT NULL,
    CollectionSource VARCHAR(30),
    SyncStatus VARCHAR(20) DEFAULT 'Pending',
    CollectedAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(SensorID) REFERENCES SensorNode(SensorID),
    FOREIGN KEY(SensorTypeID) REFERENCES SensorType(SensorTypeID),

    UNIQUE(SensorID, SensorTypeID, MeasuredAt)
);

-- 8. UAV
CREATE TABLE UAV(
    UAVID VARCHAR(20) PRIMARY KEY,
    UAVCode VARCHAR(50) NOT NULL UNIQUE,
    SerialNumber VARCHAR(50) NOT NULL UNIQUE,
    Model VARCHAR(100),
    BatteryLevel DECIMAL(5,2),
    Status VARCHAR(20) DEFAULT 'Available',
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    CHECK(BatteryLevel IS NULL OR
          (BatteryLevel >= 0 AND BatteryLevel <= 100))
);

-- 9. MobileGateway
CREATE TABLE MobileGateway(
    GatewayID VARCHAR(20) PRIMARY KEY,
    UAVID VARCHAR(20) NOT NULL,
    GatewayCode VARCHAR(50) NOT NULL UNIQUE,
    SerialNumber VARCHAR(50) NOT NULL UNIQUE,
    ConnectivityStatus VARCHAR(20),
    BatteryLevel DECIMAL(5,2),
    StorageStatus VARCHAR(20),
    LastSyncAt DATETIME NULL,

    FOREIGN KEY(UAVID) REFERENCES UAV(UAVID),

    CHECK(BatteryLevel IS NULL OR
          (BatteryLevel >= 0 AND BatteryLevel <= 100))
);

-- 10. Mission
CREATE TABLE Mission(
    MissionID VARCHAR(20) PRIMARY KEY,
    FarmID VARCHAR(20) NOT NULL,
    UAVID VARCHAR(20) NOT NULL,
    GatewayID VARCHAR(20) NOT NULL,
    CreatedBy VARCHAR(20) NOT NULL,
    MissionName VARCHAR(100) NOT NULL,
    Status VARCHAR(20) DEFAULT 'Planned',
    StartTime DATETIME NULL,
    EndTime DATETIME NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(FarmID) REFERENCES Farm(FarmID),
    FOREIGN KEY(UAVID) REFERENCES UAV(UAVID),
    FOREIGN KEY(GatewayID) REFERENCES MobileGateway(GatewayID),
    FOREIGN KEY(CreatedBy) REFERENCES `User`(UserID)
);

-- 11. MissionSensor
CREATE TABLE MissionSensor(
    MissionID VARCHAR(20) NOT NULL,
    SensorID VARCHAR(20) NOT NULL,

    PRIMARY KEY(MissionID, SensorID),

    FOREIGN KEY(MissionID) REFERENCES Mission(MissionID),
    FOREIGN KEY(SensorID) REFERENCES SensorNode(SensorID)
);

-- 12. Waypoint
CREATE TABLE Waypoint(
    WaypointID VARCHAR(20) PRIMARY KEY,
    MissionID VARCHAR(20) NOT NULL,
    SequenceNo INT NOT NULL,
    Latitude DECIMAL(10,8) NOT NULL,
    Longitude DECIMAL(11,8) NOT NULL,
    Altitude DECIMAL(8,2),
    Status VARCHAR(20) DEFAULT 'Pending',
    ReachedAt DATETIME NULL,

    FOREIGN KEY(MissionID) REFERENCES Mission(MissionID),

    UNIQUE(MissionID, SequenceNo)
);

-- 13. MissionCollection
CREATE TABLE MissionCollection(
    CollectionID VARCHAR(20) PRIMARY KEY,
    MissionID VARCHAR(20) NOT NULL,
    SensorID VARCHAR(20) NOT NULL,
    CollectedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Status VARCHAR(20) DEFAULT 'Success',
    ErrorReason TEXT,
    RetryCount INT DEFAULT 0,

    FOREIGN KEY(MissionID) REFERENCES Mission(MissionID),
    FOREIGN KEY(SensorID) REFERENCES SensorNode(SensorID),

    CHECK(RetryCount >= 0)
);

-- 14. Threshold
CREATE TABLE Threshold(
    ThresholdID VARCHAR(20) PRIMARY KEY,
    SensorTypeID VARCHAR(20) NOT NULL,
    ZoneID VARCHAR(20) NOT NULL,
    MinValue DECIMAL(10,2),
    `MaxValue` DECIMAL(10,2),
    TimeoutMinutes INT,
    LowBatteryLevel DECIMAL(5,2),
    IsActive BOOLEAN DEFAULT TRUE,

    FOREIGN KEY(SensorTypeID) REFERENCES SensorType(SensorTypeID),
    FOREIGN KEY(ZoneID) REFERENCES Zone(ZoneID),

    CHECK(
        MinValue IS NULL
        OR `MaxValue` IS NULL
        OR MinValue <= `MaxValue`
    ),

    CHECK(
        LowBatteryLevel IS NULL
        OR (LowBatteryLevel >= 0 AND LowBatteryLevel <= 100)
    )
);
-- 15. Alert
CREATE TABLE Alert(
    AlertID VARCHAR(20) PRIMARY KEY,
    SensorID VARCHAR(20) NOT NULL,
    ClosedBy VARCHAR(20),
    AlertType VARCHAR(50) NOT NULL,
    Message VARCHAR(255),
    Severity VARCHAR(20),
    TriggeredValue DECIMAL(10,2),
    TriggeredAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(20) DEFAULT 'Open',
    ClosedAt DATETIME NULL,

    FOREIGN KEY(SensorID) REFERENCES SensorNode(SensorID),
    FOREIGN KEY(ClosedBy) REFERENCES `User`(UserID)
);

-- 16. Notification
CREATE TABLE Notification(
    NotificationID VARCHAR(20) PRIMARY KEY,
    AlertID VARCHAR(20) NOT NULL,
    UserID VARCHAR(20) NOT NULL,
    NotificationType VARCHAR(20) NOT NULL,
    Message VARCHAR(255),
    SentAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(20) DEFAULT 'Pending',

    FOREIGN KEY(AlertID) REFERENCES Alert(AlertID),
    FOREIGN KEY(UserID) REFERENCES `User`(UserID)
);

-- 17. AlertHandling
CREATE TABLE AlertHandling(
    HandlingID VARCHAR(20) PRIMARY KEY,
    AlertID VARCHAR(20) NOT NULL,
    HandledBy VARCHAR(20) NOT NULL,
    Action VARCHAR(100),
    Note TEXT,
    HandledAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(AlertID) REFERENCES Alert(AlertID),
    FOREIGN KEY(HandledBy) REFERENCES `User`(UserID)
);

-- 18. MissionNote
CREATE TABLE MissionNote(
    NoteID VARCHAR(20) PRIMARY KEY,
    MissionID VARCHAR(20) NOT NULL,
    UserID VARCHAR(20) NOT NULL,
    NoteContent TEXT NOT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(MissionID) REFERENCES Mission(MissionID),
    FOREIGN KEY(UserID) REFERENCES `User`(UserID)
);

-- Kiểm tra các bảng đã tạo
SHOW TABLES;