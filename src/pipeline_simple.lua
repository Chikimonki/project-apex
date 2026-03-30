-- src/pipeline_simple.lua
local ffi = require("ffi")

-- Try to load the real decoder
local can_decoder = nil
local use_real_decoder = false

local ok, err = pcall(function()
    package.path = "./src/?.lua;" .. package.path
    can_decoder = require("can_decoder_ffi")
    local version = can_decoder.get_version()
    use_real_decoder = true
    print(string.format("✅ Loaded CAN decoder (version: %d)", version))
    
    -- Quick sanity check
    local sum = can_decoder.test_add(2, 3)
    print(string.format("   Sanity check: 2 + 3 = %d", sum))
end)

if not use_real_decoder then
    print("⚠️  Using mock decoder: " .. tostring(err))
end

-- CSV parsing
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
        if val then
            table.insert(bytes, val)
        end
    end
    return bytes
end

-- Pipeline class
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new(input_csv, output_csv, config)
    local self = setmetatable({}, Pipeline)
    self.input_path = input_csv
    self.output_path = output_csv
    self.config = config or {}
    self.monitor_interval = config.monitor_interval or 1000
    self.use_simd = config.use_simd or false
    
    self.stats = {
        total_frames = 0,
        decoded_frames = 0,
        errors = 0,
        start_time = os.time()
    }
    
    return self
end

function Pipeline:decode_frame(can_id, data_bytes)
    if use_real_decoder then
        local speed = can_decoder.decode_frame(can_id, data_bytes)
        return {
            speed = speed,
            rpm = 0,
            throttle = 0,
            brake = 0,
            gear = 0,
            steering_angle = 0
        }
    else
        -- Mock decoder
        return {
            speed = (data_bytes[1] or 0) + (data_bytes[2] or 0) * 0.01,
            rpm = 0,
            throttle = 0,
            brake = 0,
            gear = 0,
            steering_angle = 0
        }
    end
end

function Pipeline:process()
    local input_file = io.open(self.input_path, "r")
    if not input_file then
        error("Cannot open input file: " .. self.input_path)
    end
    
    local output_file = io.open(self.output_path, "w")
    if not output_file then
        input_file:close()
        error("Cannot create output file: " .. self.output_path)
    end
    
    output_file:write("timestamp,can_id,speed_kph,rpm,throttle_pct,brake_pct,gear,steering_angle\n")
    
    print(string.format("🚀 Pipeline: %s → %s", self.input_path, self.output_path))
    print(string.rep("─", 70))
    
    local first_line = true
    for line in input_file:lines() do
        if first_line and not line:match("^%d") then
            first_line = false
        else
            first_line = false
            self:process_line(line, output_file)
        end
    end
    
    input_file:close()
    output_file:close()
    
    self:print_final_summary()
end

function Pipeline:process_line(line, output_file)
    self.stats.total_frames = self.stats.total_frames + 1
    
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
        
        output_file:write(string.format(
            "%.3f,%04X,%.2f,%.0f,%.1f,%.1f,%d,%.1f\n",
            frame.timestamp or 0,
            frame.can_id or 0,
            decoded.speed or 0,
            decoded.rpm or 0,
            decoded.throttle or 0,
            decoded.brake or 0,
            decoded.gear or 0,
            decoded.steering_angle or 0
        ))
        
        if self.stats.total_frames % self.monitor_interval == 0 then
            self:print_progress(decoded)
        end
    else
        self.stats.errors = self.stats.errors + 1
    end
end

function Pipeline:print_progress(last_decoded)
    print(string.format(
        "📊 Frame %d | Speed: %.2f kph",
        self.stats.total_frames,
        last_decoded.speed or 0
    ))
end

function Pipeline:print_final_summary()
    print(string.rep("─", 70))
    print("✅ Complete!")
    print(string.format("   Frames: %d | Decoded: %d | Errors: %d",
        self.stats.total_frames, self.stats.decoded_frames, self.stats.errors))
    print(string.format("   Output: %s", self.output_path))
end

return Pipeline
