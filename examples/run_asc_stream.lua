#!/usr/bin/env luajit
-- Stream .asc CAN data to ROS 2

package.path = "./src/?.lua;" .. package.path

local can_decoder = require("can_decoder_ffi")
local asc_parser = require("asc_parser")

io.stderr:write("✅ Loaded CAN decoder v" .. can_decoder.get_version() .. "\n")

local function sleep(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do end
end

local function main(args)
    local input = args[1] or "examples/data/f1_session.asc"
    
    io.stderr:write("🚀 Loading ASC file: " .. input .. "\n")
    local frames = asc_parser.load_asc_file(input)
    io.stderr:write("   Loaded " .. #frames .. " CAN frames\n")
    io.stderr:write("🔄 Looping forever (Ctrl+C to stop)\n\n")
    
    local count = 0
    local loop_num = 0
    
    while true do
        loop_num = loop_num + 1
        io.stderr:write("📦 Starting replay " .. loop_num .. "\n")
        
        for _, frame in ipairs(frames) do
            -- Only process frames with our target CAN ID
            if frame.can_id == 0x123 and #frame.data >= 2 then
                local speed = can_decoder.decode_frame(frame.can_id, frame.data)
                
                -- Derive other telemetry from speed
                local rpm = speed * 25
                local throttle = math.min(speed / 3, 100)
                local gear = math.min(math.floor(speed / 80) + 1, 8)
                local brake = (speed < 200) and ((300 - speed) / 2) or 0
                
                local json_msg = string.format(
                    '{"timestamp":%.6f,"can_id":%d,"speed":%.2f,"rpm":%.0f,"throttle":%.1f,"brake":%.1f,"gear":%d,"steering_angle":0}',
                    frame.timestamp, frame.can_id, speed, rpm, throttle, brake, gear
                )
                
                print(json_msg)
                io.stdout:flush()
                
                count = count + 1
                if count % 20 == 0 then
                    io.stderr:write(string.format(
                        "   📊 Frame %d | Time: %.3fs | Speed: %.0f kph | RPM: %.0f | Gear: %d\n",
                        count, frame.timestamp, speed, rpm, gear
                    ))
                end
                
                sleep(0.05)  -- 20 FPS
            end
        end
        
        io.stderr:write("🏁 Replay " .. loop_num .. " complete!\n\n")
    end
end

main(arg)
