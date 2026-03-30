#!/usr/bin/env luajit
-- Stream decoded telemetry as JSON - LOOPS FOREVER

package.path = "./src/?.lua;" .. package.path

local can_decoder = require("can_decoder_ffi")
io.stderr:write("✅ Loaded CAN decoder v" .. can_decoder.get_version() .. "\n")

local function parse_csv_line(line)
    if not line or line == "" then return nil end
    local fields = {}
    for field in line:gmatch("([^,]+)") do
        table.insert(fields, field)
    end
    if #fields < 3 then return nil end
    local can_id_str = fields[2]:gsub("0x", ""):gsub("%s+", "")
    return {
        timestamp = tonumber(fields[1]) or 0,
        can_id = tonumber(can_id_str, 16) or 0,
        data = fields[3]:gsub("%s+", "")
    }
end

local function hex_to_bytes(hex_string)
    local bytes = {}
    for i = 1, #hex_string, 2 do
        local byte_str = hex_string:sub(i, i+1)
        local val = tonumber(byte_str, 16)
        if val then table.insert(bytes, val) end
    end
    return bytes
end

local function load_csv(path)
    local frames = {}
    local file = io.open(path, "r")
    if not file then return frames end
    
    local first_line = true
    for line in file:lines() do
        if first_line and not line:match("^%d") then
            first_line = false
        else
            first_line = false
            local frame = parse_csv_line(line)
            if frame then
                table.insert(frames, frame)
            end
        end
    end
    file:close()
    return frames
end

local function sleep(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do end
end

local function main(args)
    local input = args[1] or "examples/data/f1_lap_monza.csv"
    
    io.stderr:write("🚀 Loading from " .. input .. "\n")
    local frames = load_csv(input)
    io.stderr:write("   Loaded " .. #frames .. " frames\n")
    io.stderr:write("🔄 Looping forever (Ctrl+C to stop)\n\n")
    
    local count = 0
    local loop_num = 0
    
    while true do
        loop_num = loop_num + 1
        io.stderr:write("📦 Starting lap " .. loop_num .. "\n")
        
        for _, frame in ipairs(frames) do
            local data_bytes = hex_to_bytes(frame.data)
            local speed = can_decoder.decode_frame(frame.can_id, data_bytes)
            
            -- Simulate RPM, throttle based on speed
            local rpm = speed * 25
            local throttle = math.min(speed / 3, 100)
            local gear = math.min(math.floor(speed / 80) + 1, 8)
            
            local json_msg = string.format(
                '{"timestamp":%.3f,"can_id":%d,"speed":%.2f,"rpm":%.0f,"throttle":%.1f,"brake":0,"gear":%d,"steering_angle":0}',
                frame.timestamp, frame.can_id, speed, rpm, throttle, gear
            )
            
            print(json_msg)
            io.stdout:flush()
            
            count = count + 1
            if count % 20 == 0 then
                io.stderr:write(string.format("   📊 Frame %d | Speed: %.0f kph | RPM: %.0f | Gear: %d\n", 
                    count, speed, rpm, gear))
            end
            
            sleep(0.05)  -- 50ms between frames = 20 FPS
        end
        
        io.stderr:write("🏁 Lap " .. loop_num .. " complete!\n\n")
    end
end

main(arg)
