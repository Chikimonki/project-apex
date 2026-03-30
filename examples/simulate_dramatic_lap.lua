#!/usr/bin/env luajit
-- DRAMATIC Ferrari 488 lap - fast acceleration, hard braking!

io.stderr:write("🏎️  DRAMATIC Ferrari 488 Challenge Lap!\n\n")

-- DRAMATIC lap profile - 0-340 kph in 6 seconds!
local profile = {
    {0,    0,   100, 0,   1,  0},     -- LAUNCH!
    {1,    100, 100, 0,   2,  0},     -- Flying start
    {2,    180, 100, 0,   3,  0},
    {3,    250, 100, 0,   5,  0},
    {4,    300, 100, 0,   6,  0},
    {5,    330, 100, 0,   7,  0},
    {6,    340, 100, 0,   7,  0},     -- TOP SPEED!
    {7,    340, 80,  0,   7,  0},
    {8,    280, 0,   100, 6, -25},    -- HARD BRAKING!
    {9,    150, 0,   100, 4, -40},    -- TURN IN!
    {10,   100, 50,  30,  3, -30},    -- APEX
    {11,   130, 100, 0,   4,  0},     -- EXIT
    {13,   220, 100, 0,   5,  0},
    {15,   300, 100, 0,   7,  0},
    {17,   340, 100, 0,   7,  0},     -- FLAT OUT
    {19,   340, 70,  0,   7, -10},
    {20,   250, 0,   90,  5, -35},    -- CHICANE BRAKING
    {21,   120, 30,  40,  3,  30},    -- CHICANE LEFT
    {22,   140, 80,  0,   4, -20},    -- CHICANE RIGHT
    {24,   240, 100, 0,   6,  0},
    {26,   320, 100, 0,   7,  0},
    {28,   340, 100, 0,   7,  0},
    {29,   280, 0,   80,  6, -30},    -- FINAL CORNER
    {30,   180, 40,  40,  4, -45},    -- HAIRPIN!
    {31,   150, 80,  0,   4, -20},
    {33,   250, 100, 0,   6,  0},
    {35,   320, 100, 0,   7,  0},     -- FINISH STRAIGHT
    {37,   340, 100, 0,   7,  0},
    {38,   340, 100, 0,   7,  0},     -- CROSS THE LINE!
}

local function lerp(t, keyframes)
    for i = 1, #keyframes - 1 do
        local k1, k2 = keyframes[i], keyframes[i + 1]
        if t >= k1[1] and t <= k2[1] then
            local a = (t - k1[1]) / (k2[1] - k1[1])
            return {
                speed = k1[2] + (k2[2] - k1[2]) * a,
                throttle = k1[3] + (k2[3] - k1[3]) * a,
                brake = k1[4] + (k2[4] - k1[4]) * a,
                gear = math.floor(k1[5] + (k2[5] - k1[5]) * a + 0.5),
                steering = k1[6] + (k2[6] - k1[6]) * a,
            }
        end
    end
    local last = keyframes[#keyframes]
    return {speed = last[2], throttle = last[3], brake = last[4], gear = last[5], steering = last[6]}
end

print("timestamp,can_id,data")

local t = 0
local frame = 0

while t <= 38 do
    local state = lerp(t, profile)
    local rpm = 2000 + (state.speed * 25 * math.max(state.gear, 1))
    
    -- Output JSON directly (skip hex encoding complexity)
    local json = string.format(
        '{"timestamp":%.3f,"speed":%.1f,"rpm":%.0f,"throttle":%.0f,"brake":%.0f,"gear":%d,"steering":%.1f}',
        t, state.speed, rpm, state.throttle, state.brake, state.gear, state.steering
    )
    print(json)
    
    frame = frame + 1
    if frame % 50 == 0 then
        io.stderr:write(string.format(
            "🏎️  %.1fs | %3.0f km/h (%3.0f mph) | G%d | %5.0f RPM | THR:%3.0f%% | BRK:%2.0f bar | STR:%+.0f°\n",
            t, state.speed, state.speed * 0.621371, state.gear, rpm, 
            state.throttle, state.brake, state.steering
        ))
    end
    
    t = t + 0.05
end

io.stderr:write(string.format("\n🏁 DRAMATIC lap complete! %d frames\n", frame))
