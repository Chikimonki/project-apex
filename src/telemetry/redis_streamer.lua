#!/usr/bin/env luajit
-- redis_streamer.lua — Real-time telemetry streaming via Redis

local ffi = require("ffi")
local redis = require("redis")
local cjson = require("cjson")

ffi.cdef[[
    typedef struct { float vx, vy, yaw_rate, slip_front, slip_rear, friction; } State;
    typedef struct { float fl, fr, rl, rr, steer, brake; } Measurement;
    typedef struct { State state; float P[36]; float Q[36]; float dt, wb, tw; } KalmanFilter;
    void kalman_init(KalmanFilter* kf, float dt);
    void kalman_predict(KalmanFilter* kf);
    void kalman_update(KalmanFilter* kf, const Measurement* z);
    void kalman_get_state(const KalmanFilter* kf, State* out);
]]

local lib = ffi.load("../core/libkalman.so")

print("╔════════════════════════════════════════════════╗")
print("║  APEX REDIS TELEMETRY STREAMER                 ║")
print("╚════════════════════════════════════════════════╝")
print()

-- Connect to Redis
local client = redis.connect('127.0.0.1', 6379)
print("✅ Connected to Redis (localhost:6379)")

-- Initialize Kalman filter
local kf = ffi.new("KalmanFilter")
lib.kalman_init(kf, 0.002)  -- 500 Hz
print("✅ Kalman filter initialized (500 Hz)")

-- Load F1 telemetry data
print("📊 Loading Monaco 2024 telemetry...")
local frames = {}
local file = io.open("../../examples/fastf1_demo/monaco_2024_verstappen.csv", "r")

if not file then
    print("❌ Error: Run FastF1 demo first!")
    print("   cd ../../examples/fastf1_demo")
    print("   python3 fetch_f1_telemetry.py")
    os.exit(1)
end

local first = true
for line in file:lines() do
    if first then 
        first = false
    else
        local t, fl, fr, rl, rr, throttle, brake, speed = 
            line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if t then
            table.insert(frames, {
                time = tonumber(t),
                fl = tonumber(fl),
                fr = tonumber(fr),
                rl = tonumber(rl),
                rr = tonumber(rr),
                throttle = tonumber(throttle),
                brake = tonumber(brake),
                speed = tonumber(speed)
            })
        end
    end
end
file:close()

print(string.format("✅ Loaded %d frames (%.1fs lap)", #frames, frames[#frames].time))
print()
print("🚀 Streaming started...")
print("   Channel: apex:telemetry")
print("   Rate: 500 Hz (real-time)")
print("   Press Ctrl+C to stop")
print()

local state = ffi.new("State")
local frame_idx = 1
local loop_count = 0
local total_published = 0

while true do
    local f = frames[frame_idx]
    
    -- Update Kalman filter
    local z = ffi.new("Measurement")
    z.fl = f.fl
    z.fr = f.fr
    z.rl = f.rl
    z.rr = f.rr
    z.steer = 0.0
    z.brake = f.brake
    
    lib.kalman_predict(kf)
    lib.kalman_update(kf, z)
    lib.kalman_get_state(kf, state)
    
    -- Build telemetry packet
    local packet = {
        timestamp = os.time(),
        lap_time = f.time,
        lap_number = loop_count + 1,
        speed_kmh = state.vx * 3.6,
        speed_ms = state.vx,
        yaw_rate = state.yaw_rate,
        slip_front = state.slip_front,
        slip_rear = state.slip_rear,
        friction = state.friction,
        wheels = {
            fl = f.fl * 3.6,
            fr = f.fr * 3.6,
            rl = f.rl * 3.6,
            rr = f.rr * 3.6
        },
        throttle = f.throttle,
        brake = f.brake,
        frame = frame_idx
    }
    
    -- Publish to Redis
    local json = cjson.encode(packet)
    client:publish("apex:telemetry", json)

    -- CACHE LATEST FOR HTTP POLLING (ADD THIS LINE)
    client:set("apex:latest", json)
    
    -- Also store in sorted set (time-series)
    client:zadd("apex:history", f.time, json)
    
    -- Keep only last 1000 frames in history
    client:zremrangebyrank("apex:history", 0, -1001)
    
    total_published = total_published + 1
    
    -- Progress output
    if frame_idx % 50 == 1 then
        print(string.format(
            "[Lap %d] Frame %4d/%4d | t=%5.1fs | %6.1f km/h | Slip: %+.4f | Published: %d",
            loop_count + 1,
            frame_idx,
            #frames,
            f.time,
            state.vx * 3.6,
            state.slip_front,
            total_published
        ))
    end
    
    -- Advance frame
    frame_idx = frame_idx + 1
    if frame_idx > #frames then
        frame_idx = 1
        loop_count = loop_count + 1
        print()
        print(string.format("🏁 Lap %d complete! Restarting...", loop_count))
        print()
    end
    
    -- Sleep to maintain real-time rate (500 Hz = 2ms per frame)
    -- Adjust based on actual F1 data rate (~8 Hz = 125ms)
    local sleep_time = 0.125  -- 8 Hz matching F1 telemetry
    os.execute("sleep " .. sleep_time)
end
