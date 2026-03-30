#!/usr/bin/env luajit
-- Simulate Ferrari 488 Challenge lap - SIMPLIFIED

io.stderr:write("🏎️  Ferrari 488 Challenge - Monza Lap Simulator\n\n")

-- Lap profile keyframes
local profile = {
    -- time, speed, throttle, brake, gear, steering
    {0,   0,   0,   0,  1,  0},
    {2,   80,  100, 0,  2,  0},
    {5,   180, 100, 0,  4,  0},
    {8,   280, 100, 0,  6,  0},
    {12,  340, 100, 0,  7,  0},  -- Top speed
    {15,  280, 0,   80, 6, -15}, -- Braking
    {17,  120, 30,  50, 3, -30}, -- Turn 1
    {20,  200, 100, 0,  5,  0},
    {25,  260, 100, 0,  6,  0},
    {30,  320, 100, 0,  7,  0},
    {35,  150, 20,  70, 4, -25}, -- Chicane
    {40,  280, 100, 0,  7,  0},
    {45,  160, 30,  50, 4, -30}, -- Final turn
    {50,  280, 100, 0,  7,  0},  -- Finish
}

-- Linear interpolation
local function lerp(t, keyframes)
    for i = 1, #keyframes - 1 do
        local k1, k2 = keyframes[i], keyframes[i + 1]
        if t >= k1[1] and t <= k2[1] then
            local alpha = (t - k1[1]) / (k2[1] - k1[1])
            return {
                speed = k1[2] + (k2[2] - k1[2]) * alpha,
                throttle = k1[3] + (k2[3] - k1[3]) * alpha,
                brake = k1[4] + (k2[4] - k1[4]) * alpha,
                gear = math.floor(k1[5] + (k2[5] - k1[5]) * alpha + 0.5),
                steering = k1[6] + (k2[6] - k1[6]) * alpha,
            }
        end
    end
    local last = keyframes[#keyframes]
    return {speed = last[2], throttle = last[3], brake = last[4], gear = last[5], steering = last[6]}
end

-- Print CSV header
print("timestamp,can_id,data")

local t = 0
local dt = 0.05
local frame = 0

while t <= 50 do
    local state = lerp(t, profile)
    
    -- Calculate derived values
    local rpm = 1500 + (state.speed * 30 * state.gear)
    local long_g = (state.throttle - state.brake) / 100.0
    local lat_g = math.abs(state.steering) / 45.0 * 2.0
    
    -- Encode as simple hex (not proper CAN encoding, just for visualization)
    -- CAN ID 0x200: Engine + Throttle
    local engine_data = string.format("%04X%02X00000000",
        math.floor(rpm / 5),
        math.floor(state.throttle))
    
    -- CAN ID 0x20C: Speed + Brake
    local speed_data = string.format("0000%04X%04X00",
        math.floor(state.speed * 10),
        math.floor(state.brake))
    
    -- CAN ID 0x204: Gear
    local gear_data = string.format("00000000000000%02X",
        state.gear)
    
    -- CAN ID 0x208: Steering
    local steer_data = string.format("000000%04X0000",
        math.floor((state.steering + 780) * 2))  -- Offset for unsigned
    
    -- CAN ID 0x210: G-forces
    local g_data = string.format("0000%04X%04X00",
        math.floor((long_g + 40.9) * 10),
        math.floor((lat_g + 40.9) * 10))
    
    -- Output messages
    print(string.format("%.3f,0x200,%s", t, engine_data))
    print(string.format("%.3f,0x20C,%s", t, speed_data))
    print(string.format("%.3f,0x204,%s", t, gear_data))
    print(string.format("%.3f,0x208,%s", t, steer_data))
    print(string.format("%.3f,0x210,%s", t, g_data))
    
    frame = frame + 1
    if frame % 100 == 0 then
        io.stderr:write(string.format("⏱️  %.1fs | 🏎️ %3.0f kph | ⚙️ %d | 🔴 %3.0f rpm | 🟢 %3.0f%% | 🔵 %2.0f bar\n",
            t, state.speed, state.gear, rpm, state.throttle, state.brake))
    end
    
    t = t + dt
end

io.stderr:write(string.format("\n🏁 Generated %d frames for 50-second lap\n", frame))
