#!/usr/bin/env luajit
-- Ferrari 488 simulator with PROPER VBOX encoding

package.path = "./src/?.lua;" .. package.path

local bit = require("bit")
local vbox = require("vbox_csv_parser")

io.stderr:write("🏎️  Ferrari 488 Challenge - Monza Lap (FIXED ENCODING)\n\n")

-- Load Ferrari database
local db_file = io.open("examples/data/Ferrari-488 Challenge (X710 Connector) 2020-_full.txt", "r")
local signals = vbox.parse_vbox_csv(db_file:read("*all"))
db_file:close()

-- Encode value into CAN message at correct bit position
local function encode_signal(signal, value)
    local data = {0, 0, 0, 0, 0, 0, 0, 0}
    
    -- Convert physical value to raw value
    local raw = math.floor((value - signal.offset) / signal.factor + 0.5)
    
    -- Clamp to valid range
    local max_val = bit.lshift(1, signal.length) - 1
    raw = math.max(0, math.min(raw, max_val))
    
    -- Encode based on byte order
    if signal.byte_order == "Motorola" then
        -- Big-endian (MSB first)
        local start_byte = math.floor(signal.start_bit / 8)
        local start_bit_in_byte = signal.start_bit % 8
        
        for i = signal.length - 1, 0, -1 do
            local b = bit.band(bit.rshift(raw, i), 1)
            local byte_pos = start_byte + math.floor((signal.length - 1 - i + start_bit_in_byte) / 8)
            local bit_pos = 7 - ((signal.length - 1 - i + start_bit_in_byte) % 8)
            
            if byte_pos <= 7 then
                data[byte_pos + 1] = bit.bor(data[byte_pos + 1], bit.lshift(b, bit_pos))
            end
        end
    end
    
    return data
end

-- Merge multiple signals into one CAN message
local function build_message(can_id, signal_values)
    local data = {0, 0, 0, 0, 0, 0, 0, 0}
    
    for name, value in pairs(signal_values) do
        if signals[name] and signals[name].can_id == can_id then
            local encoded = encode_signal(signals[name], value)
            for i = 1, 8 do
                data[i] = bit.bor(data[i], encoded[i])
            end
        end
    end
    
    return string.format("%02X%02X%02X%02X%02X%02X%02X%02X",
        data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8])
end

-- Lap profile
local profile = {
    {0,   0,   0,   0,  1,  0},
    {2,   80,  100, 0,  2,  0},
    {5,   180, 100, 0,  4,  0},
    {8,   280, 100, 0,  6,  0},
    {12,  340, 100, 0,  7,  0},
    {15,  280, 0,   80, 6, -15},
    {17,  120, 30,  50, 3, -30},
    {20,  200, 100, 0,  5,  0},
    {25,  260, 100, 0,  6,  0},
    {30,  320, 100, 0,  7,  0},
    {35,  150, 20,  70, 4, -25},
    {40,  280, 100, 0,  7,  0},
    {45,  160, 30,  50, 4, -30},
    {50,  280, 100, 0,  7,  0},
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

-- Generate lap
print("timestamp,can_id,data")

local t = 0
local frame = 0

while t <= 50 do
    local state = lerp(t, profile)
    local rpm = 1500 + (state.speed * 30 * state.gear)
    
    -- Build CAN messages with proper encoding
    local msg_200 = build_message(0x200, {
        Engine_Speed = rpm,
        Accelerator_Pedal_Position = state.throttle
    })
    
    local msg_20C = build_message(0x20C, {
        Indicated_Vehicle_Speed_kph = state.speed,
        Brake_Pressure = state.brake
    })
    
    local msg_204 = build_message(0x204, {
        Gear = state.gear
    })
    
    local msg_208 = build_message(0x208, {
        Steering_Angle = state.steering + 780  -- Offset for unsigned encoding
    })
    
    -- Output
    print(string.format("%.3f,0x200,%s", t, msg_200))
    print(string.format("%.3f,0x20C,%s", t, msg_20C))
    print(string.format("%.3f,0x204,%s", t, msg_204))
    print(string.format("%.3f,0x208,%s", t, msg_208))
    
    frame = frame + 1
    if frame % 100 == 0 then
        io.stderr:write(string.format("⏱️  %.1fs | 🏎️ %3.0f kph | ⚙️ %d | 🔴 %5.0f rpm\n",
            t, state.speed, state.gear, rpm))
    end
    
    t = t + 0.05
end

io.stderr:write(string.format("\n🏁 Generated %d frames\n", frame))
