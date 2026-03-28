local ffi = require("ffi")

ffi.cdef[[
    typedef struct { float vx, vy, yaw_rate, slip_front, slip_rear, friction; } State;
    typedef struct { float fl, fr, rl, rr, steer, brake; } Measurement;
    typedef struct { State state; float P[36]; float Q[36]; float dt, wb, tw; } KalmanFilter;
    void kalman_init(KalmanFilter* kf, float dt);
    void kalman_predict(KalmanFilter* kf);
    void kalman_update(KalmanFilter* kf, const Measurement* z);
    void kalman_get_state(const KalmanFilter* kf, State* out);
]]

local lib = ffi.load("../../src/core/libkalman.so")

print("🏎️  VERSTAPPEN MONACO 2024")
print("══════════════════════════\n")

-- Read CSV instead (more reliable)
local frames = {}
local first = true
for line in io.lines("monaco_2024_verstappen.csv") do
    if first then 
        first = false  -- Skip header
    else
        local t, fl, fr, rl, rr, throttle, brake, speed = line:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        if t then
            table.insert(frames, {
                time = tonumber(t),
                fl = tonumber(fl),
                fr = tonumber(fr),
                rl = tonumber(rl),
                rr = tonumber(rr),
                brake = tonumber(brake),
                speed = tonumber(speed)
            })
        end
    end
end

print(string.format("📊 Loaded %d frames\n", #frames))

-- Initialize Kalman
local kf = ffi.new("KalmanFilter")
lib.kalman_init(kf, 0.125)

local state = ffi.new("State")
local max_speed = 0
local start = os.clock()

for i, f in ipairs(frames) do
    local z = ffi.new("Measurement")
    z.fl = f.fl
    z.fr = f.fr
    z.rl = f.rl
    z.rr = f.rr
    z.steer = 0
    z.brake = f.brake
    
    lib.kalman_predict(kf)
    lib.kalman_update(kf, z)
    lib.kalman_get_state(kf, state)
    
    local spd = state.vx * 3.6
    if spd > max_speed then max_speed = spd end
    
    if i % 50 == 1 then
        print(string.format("t=%5.1fs: %6.1f km/h, slip: %7.4f", f.time, spd, state.slip_front))
    end
end

local elapsed = os.clock() - start

print("\n📈 RESULTS")
print("══════════")
print(string.format("Frames: %d", #frames))
print(string.format("Time: %.4f sec (%.1f K/sec)", elapsed, #frames/elapsed/1000))
print(string.format("Max speed: %.1f km/h", max_speed))
print(string.format("Final slip: %.4f / %.4f", state.slip_front, state.slip_rear))
print("\n✅ MONACO LAP COMPLETE!")
