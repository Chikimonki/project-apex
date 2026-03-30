-- src/pipeline_ros2.lua
-- Pipeline with JSON output for ROS 2

package.path = "./src/?.lua;" .. package.path

local Pipeline = require("pipeline_simple")
local json = require("json") or require("cjson") -- Try both

-- Override to add JSON streaming
local PipelineROS2 = setmetatable({}, {__index = Pipeline})

function PipelineROS2:process_line(line, output_file)
    self.stats.total_frames = self.stats.total_frames + 1
    
    local parse_csv_line = function(l)
        if not l or l == "" then return nil end
        local fields = {}
        for field in l:gmatch("([^,]+)") do
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
    
    local hex_to_bytes = function(hex_string)
        local bytes = {}
        for i = 1, #hex_string, 2 do
            local byte_str = hex_string:sub(i, i+1)
            local val = tonumber(byte_str, 16)
            if val then table.insert(bytes, val) end
        end
        return bytes
    end
    
    local frame = parse_csv_line(line)
    if not frame then
        self.stats.errors = self.stats.errors + 1
        return
    end
    
    local data_bytes = hex_to_bytes(frame.data)
    if #data_bytes == 0 then
        self.stats.errors = self.stats.errors + 1
        return
    end
    
    local decoded = self:decode_frame(frame.can_id, data_bytes)
    
    if decoded then
        self.stats.decoded_frames = self.stats.decoded_frames + 1
        
        -- Write CSV
        output_file:write(string.format(
            "%.3f,%04X,%.2f,%.0f,%.1f,%.1f,%d,%.1f\n",
            frame.timestamp, frame.can_id,
            decoded.speed, decoded.rpm, decoded.throttle,
            decoded.brake, decoded.gear, decoded.steering_angle
        ))
        
        -- Output JSON to stdout for ROS 2
        local json_data = {
            timestamp = frame.timestamp,
            can_id = frame.can_id,
            speed = decoded.speed,
            rpm = decoded.rpm,
            throttle = decoded.throttle,
            brake = decoded.brake,
            gear = decoded.gear,
            steering_angle = decoded.steering_angle
        }
        
        if json then
            print(json.encode(json_data))
            io.stdout:flush()
        end
        
        if self.stats.total_frames % self.monitor_interval == 0 then
            io.stderr:write(string.format(
                "📊 Frame %d | Speed: %.2f kph\n",
                self.stats.total_frames, decoded.speed
            ))
        end
    end
end

return PipelineROS2
