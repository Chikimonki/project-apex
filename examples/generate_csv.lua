#!/usr/bin/env luajit
-- Generate proper CSV for analysis

local profile = {
    {0,    0,   100, 0,   1,  0},
    {1,    100, 100, 0,   2,  0},
    {2,    180, 100, 0,   3,  0},
    {3,    250, 100, 0,   5,  0},
    {4,    300, 100, 0,   6,  0},
    {5,    330, 100, 0,   7,  0},
    {6,    340, 100, 0,   7,  0},
    {7,    340, 80,  0,   7,  0},
    {8,    280, 0,   100, 6, -25},
    {9,    150, 0,   100, 4, -40},
    {10,   100, 50,  30,  3, -30},
    {11,   130, 100, 0,   4,  0},
    {13,   220, 100, 0,   5,  0},
    {15,   300, 100, 0,   7,  0},
    {17,   340, 100, 0,   7,  0},
    {19,   340, 70,  0,   7, -10},
    {20,   250, 0,   90,  5, -35},
    {21,   120, 30,  40,  3,  30},
    {22,   140, 80,  0,   4, -20},
    {24,   240, 100, 0,   6,  0},
    {26,   320, 100, 0,   7,  0},
    {28,   340, 100, 0,   7,  0},
    {29,   280, 0,   80,  6, -30},
    {30,   180, 40,  40,  4, -45},
    {31,   150, 80,  0,   4, -20},
    {33,   250, 100, 0,   6,  0},
    {35,   320, 100, 0,   7,  0},
    {37,   340, 100, 0,   7,  0},
    {38,   340, 100, 0,   7,  0},
}

local function lerp(t, kf)
    for i = 1, #kf - 1 do
        local k1, k2 = kf[i], kf[i + 1]
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
    local last = kf[#kf]
    return {speed = last[2], throttle = last[3], brake = last[4], gear = last[5], steering = last[6]}
end

-- CSV header
print("timestamp,speed_kph,rpm,throttle_pct,brake_pct,gear,steering_angle")

local t = 0
while t <= 38 do
    local state = lerp(t, profile)
    local rpm = 2000 + (state.speed * 25 * math.max(state.gear, 1))
    
    print(string.format("%.3f,%.1f,%.0f,%.0f,%.0f,%d,%.1f",
        t, state.speed, rpm, state.throttle, state.brake, state.gear, state.steering))
    
    t = t + 0.05
end
