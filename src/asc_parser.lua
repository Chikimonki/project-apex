-- src/asc_parser.lua
-- Parser for Vector .asc (ASCII) CAN log files

local M = {}

-- Parse a single ASC log line
-- Format: timestamp channel_id can_id dir flags dlc data0 data1 ... data7
function M.parse_asc_line(line)
    -- Skip comments and metadata
    if line:match("^//") or line:match("^date") or line:match("^base") or 
       line:match("^internal") or line:match("^Begin") or line:match("^End") or
       line:match("^%s*$") then
        return nil
    end
    
    -- Parse: "0.100000 1  123  Rx   d 8 12 34 00 00 00 00 00 00"
    local parts = {}
    for part in line:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts < 7 then return nil end
    
    local timestamp = tonumber(parts[1])
    local channel = tonumber(parts[2])
    local can_id_hex = parts[3]
    local direction = parts[4]  -- Rx or Tx
    local flags = parts[5]      -- d = data frame
    local dlc = tonumber(parts[6])
    
    if not timestamp or not can_id_hex or not dlc then
        return nil
    end
    
    -- Parse data bytes
    local data_bytes = {}
    for i = 1, math.min(dlc, 8) do
        local byte_hex = parts[6 + i]
        if byte_hex then
            table.insert(data_bytes, tonumber(byte_hex, 16))
        end
    end
    
    return {
        timestamp = timestamp,
        channel = channel,
        can_id = tonumber(can_id_hex, 16),
        direction = direction,
        dlc = dlc,
        data = data_bytes
    }
end

-- Load entire .asc file
function M.load_asc_file(path)
    local frames = {}
    local file = io.open(path, "r")
    
    if not file then
        error("Cannot open .asc file: " .. path)
    end
    
    for line in file:lines() do
        local frame = M.parse_asc_line(line)
        if frame then
            table.insert(frames, frame)
        end
    end
    
    file:close()
    
    return frames
end

return M
