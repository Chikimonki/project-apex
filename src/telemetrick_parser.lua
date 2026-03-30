-- src/telemetrick_parser.lua
-- Parser for Assetto Corsa Telemetrick CSV exports

local M = {}

function M.load_telemetrick_csv(path)
    local frames = {}
    local file = io.open(path, "r")
    if not file then
        error("Cannot open file: " .. path)
    end
    
    -- Read header to get column indices
    local header = file:read("*line")
    local columns = {}
    local idx = 1
    for col in header:gmatch("([^,]+)") do
        columns[col:lower():gsub("%s+", "_")] = idx
        idx = idx + 1
    end
    
    io.stderr:write("📋 Found columns: ")
    for k, v in pairs(columns) do
        io.stderr:write(k .. " ")
    end
    io.stderr:write("\n")
    
    -- Parse data rows
    for line in file:lines() do
        local values = {}
        for val in line:gmatch("([^,]+)") do
            table.insert(values, tonumber(val) or 0)
        end
        
        if #values > 0 then
            table.insert(frames, {
                timestamp = values[columns["time"] or columns["lap_time"] or 1] or 0,
                speed = values[columns["speed"] or columns["speedkmh"] or 2] or 0,
                rpm = values[columns["rpm"] or columns["engine_rpm"] or 3] or 0,
                throttle = values[columns["throttle"] or columns["gas"] or 4] or 0,
                brake = values[columns["brake"] or 5] or 0,
                gear = values[columns["gear"] or 6] or 0,
                steering = values[columns["steer"] or columns["steering"] or 7] or 0,
            })
        end
    end
    
    file:close()
    return frames
end

return M
