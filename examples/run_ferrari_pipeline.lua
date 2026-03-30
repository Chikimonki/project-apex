#!/usr/bin/env luajit
-- Stream Ferrari 488 telemetry to ROS 2 using real CAN database

package.path = "./src/?.lua;" .. package.path

local vbox = require("vbox_csv_parser")

io.stderr:write("🏎️  Ferrari 488 Challenge Pipeline\n\n")

-- Load Ferrari CAN database
local db_file = io.open("examples/data/Ferrari-488 Challenge (X710 Connector) 2020-_full.txt", "r")
local db_text = db_file:read("*all")
db_file:close()

local signals = vbox.parse_vbox_csv(db_text)
io.stderr:write("\n")

-- Parse CSV line
local function parse_csv_line(line)
    if not line or line == "" or line:match("^timestamp") then return nil end
    
    local fields = {}
    for field in line:gmatch("([^,]+)") do
        table.insert(fields, field)
    end
    
    if #fields < 3 then return nil end
    
    return {
        timestamp = tonumber(fields[1]),
        can_id = tonumber(fields[2]:gsub("0x", ""), 16),
        data = fields[3]
    }
end

-- Hex to bytes
local function hex_to_bytes(hex_string)
    local bytes = {}
    for i = 1, #hex_string, 2 do
        local byte_str = hex_string:sub(i, i+1)
        table.insert(bytes, tonumber(byte_str, 16) or 0)
    end
    return bytes
end

-- Main loop
local function main()
    local input = "examples/data/ferrari_488_monza_lap.csv"
    local file = io.open(input, "r")
    
    if not file then
        error("Cannot open: " .. input)
    end
    
    io.stderr:write("🚀 Streaming from " .. input .. "\n")
    io.stderr:write("🔄 Looping forever (Ctrl+C to stop)\n\n")
    
    local frames = {}
    for line in file:lines() do
        local frame = parse_csv_line(line)
        if frame then
            table.insert(frames, frame)
        end
    end
    file:close()
    
    io.stderr:write("   Loaded " .. #frames .. " CAN messages\n\n")
    
    local loop = 0
    local state = {
        speed = 0,
        rpm = 0,
        throttle = 0,
        brake = 0,
        gear = 0,
        steering = 0
    }
    
    while true do
        loop = loop + 1
        io.stderr:write("🏁 Lap " .. loop .. "\n")
        
        for i, frame in ipairs(frames) do
            local data_bytes = hex_to_bytes(frame.data)
            
            -- Decode using Ferrari database
            local decoded = vbox.decode_message(signals, frame.can_id, data_bytes)
            
            -- Update state
            for name, value in pairs(decoded) do
                if name == "Engine_Speed" then state.rpm = value
                elseif name == "Indicated_Vehicle_Speed_kph" then state.speed = value
                elseif name == "Accelerator_Pedal_Position" then state.throttle = value
                elseif name == "Brake_Pressure" then state.brake = value
                elseif name == "Gear" then state.gear = value
                elseif name == "Steering_Angle" then state.steering = value - 780
                end
            end
            
            -- Output JSON for ROS 2
            local json = string.format(
                '{"timestamp":%.3f,"can_id":%d,"speed":%.2f,"rpm":%.0f,"throttle":%.1f,"brake":%.1f,"gear":%d,"steering_angle":%.1f}',
                frame.timestamp, frame.can_id,
                state.speed, state.rpm, state.throttle,
                state.brake, state.gear, state.steering
            )
            
            print(json)
            io.stdout:flush()
            
            if i % 500 == 0 then
                io.stderr:write(string.format(
                    "   ⏱️ %.1fs | 🏎️ %3.0f kph | ⚙️ %d | 🔴 %5.0f rpm | 🟢 %3.0f%% | 🔵 %2.0f bar\n",
                    frame.timestamp, state.speed, state.gear, state.rpm, state.throttle, state.brake
                ))
            end
            
            -- Simulate real-time (50ms between messages)
            local t = os.clock() + 0.01
            while os.clock() < t do end
        end
        
        io.stderr:write("   🏁 Lap complete!\n\n")
    end
end

main()
