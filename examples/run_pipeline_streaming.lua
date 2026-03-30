#!/usr/bin/env luajit
-- Stream decoded telemetry as JSON to ROS 2
-- ONLY outputs JSON to stdout, status goes to stderr

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

local function main(args)
    local input = args[1] or "examples/data/sample_canbus.csv"
    local file = io.open(input, "r")
    
    if not file then
        io.stderr:write("❌ Cannot open: " .. input .. "\n")
        os.exit(1)
    end
    
    io.stderr:write("🚀 Streaming from " .. input .. "\n")
    
    local count = 0
    local first_line = true
    
    for line in file:lines() do
        if first_line and not line:match("^%d") then
            first_line = false
        else
            first_line = false
            local frame = parse_csv_line(line)
            
            if frame then
                local data_bytes = hex_to_bytes(frame.data)
                local speed = can_decoder.decode_frame(frame.can_id, data_bytes)
                
                -- Output ONLY valid JSON to stdout
                local json_msg = string.format(
                    '{"timestamp":%.3f,"can_id":%d,"speed":%.2f,"rpm":0,"throttle":0,"brake":0,"gear":0,"steering_angle":0}',
                    frame.timestamp, frame.can_id, speed
                )
                
                print(json_msg)
                io.stdout:flush()
                
                count = count + 1
                if count % 5 == 0 then
                    io.stderr:write(string.format("📊 Sent %d frames | Speed: %.2f kph\n", count, speed))
                end
                
                -- Simulate real-time (100ms between frames)
                local t = os.clock() + 0.1
                while os.clock() < t do end
            end
        end
    end
    
    file:close()
    io.stderr:write("✅ Streaming complete: " .. count .. " frames\n")
end

main(arg)
