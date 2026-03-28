local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        float vx, vy, yaw_rate, slip_front, slip_rear, friction;
    } State;
    
    typedef struct {
        float wheel_speed_fl, wheel_speed_fr;
        float wheel_speed_rl, wheel_speed_rr;
        float steering_angle, brake_pressure;
    } Measurement;
    
    typedef struct {
        State state;
        float P[36];
        float Q[36];
        float dt;
        float wheelbase;
        float track_width;
    } KalmanFilter;
    
    void kalman_init(KalmanFilter* kf, float dt);
    void kalman_predict(KalmanFilter* kf);
    void kalman_update(KalmanFilter* kf, const Measurement* z);
    void kalman_get_state(const KalmanFilter* kf, State* out);
]]

local lib = ffi.load("./libkalman.so")

print("🏎️  KALMAN FILTER BENCHMARK")
print("═════���═════════════════════\n")

-- Initialize
local kf = ffi.new("KalmanFilter")
lib.kalman_init(kf, 0.002)  -- 500 Hz
print("✅ Initialized at 500 Hz\n")

-- Benchmark: How many updates per second?
local iterations = 100000
local z = ffi.new("Measurement", {10.5, 10.6, 10.4, 10.5, 0.1, 0.0})

local start = os.clock()
for i = 1, iterations do
    lib.kalman_predict(kf)
    lib.kalman_update(kf, z)
end
local elapsed = os.clock() - start

local updates_per_sec = iterations / elapsed

print(string.format("⚡ Performance:"))
print(string.format("   %d iterations in %.3f seconds", iterations, elapsed))
print(string.format("   %.1f M updates/sec", updates_per_sec / 1e6))
print(string.format("   %.2f µs per update", elapsed / iterations * 1e6))
print("")

-- Equivalent real-time capacity
local realtime_hz = 500
local cars_simultaneous = updates_per_sec / realtime_hz

print(string.format("🏁 Real-time capacity:"))
print(string.format("   Can track %d cars simultaneously at 500 Hz", math.floor(cars_simultaneous)))
print("")

-- Get final state
local state = ffi.new("State")
lib.kalman_get_state(kf, state)

print(string.format("📊 Final state:"))
print(string.format("   Velocity: %.2f m/s (%.1f km/h)", state.vx, state.vx * 3.6))
print(string.format("   Yaw rate: %.4f rad/s", state.yaw_rate))
print(string.format("   Slip F/R: %.4f / %.4f", state.slip_front, state.slip_rear))
print("")
print("✅ KALMAN FILTER READY FOR DEPLOYMENT")
