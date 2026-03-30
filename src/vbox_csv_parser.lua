-- src/vbox_csv_parser.lua
-- Parser for decompressed VBOX CAN database CSV

local bit_lib = require("bit")
local M = {}

function M.parse_vbox_csv(csv_text)
    local signals = {}
    
    local field_count = 0
    local current_pos = 1
    
    while current_pos < #csv_text do
        local fields = {}
        
        for i = 1, 12 do
            local comma_pos = csv_text:find(",", current_pos)
            if not comma_pos then break end
            
            local field = csv_text:sub(current_pos, comma_pos - 1)
            table.insert(fields, field)
            current_pos = comma_pos + 1
        end
        
        if #fields >= 12 then
            local name = fields[1]
            local can_id = tonumber(fields[2])
            local unit = fields[3]
            local start_bit = tonumber(fields[4])
            local length = tonumber(fields[5])
            local offset = tonumber(fields[6])
            local factor = tonumber(fields[7])
            
            if name ~= "" and can_id then
                signals[name] = {
                    name = name,
                    can_id = can_id,
                    unit = unit,
                    start_bit = start_bit,
                    length = length,
                    offset = offset,
                    factor = factor,
                    byte_order = fields[11],
                    dlc = tonumber(fields[12])
                }
                
                field_count = field_count + 1
                io.stderr:write(string.format(
                    "  %-35s | ID: %3d (0x%03X) | %2d bits @ %2d | Scale: %6.3f | %s\n",
                    name, can_id, can_id, length, start_bit, factor, unit
                ))
            end
        else
            break
        end
    end
    
    io.stderr:write(string.format("\n✅ Parsed %d signals\n", field_count))
    
    return signals
end

-- Decode a CAN message using signal definitions
function M.decode_message(signals, can_id, data_bytes)
    local result = {}
    
    for name, sig in pairs(signals) do
        if sig.can_id == can_id then
            local value = M.extract_signal(data_bytes, sig.start_bit, sig.length, sig.byte_order)
            local scaled = (value * sig.factor) + sig.offset
            result[name] = scaled
        end
    end
    
    return result
end

-- Extract signal from CAN data bytes
function M.extract_signal(data_bytes, start_bit, length, byte_order)
    if #data_bytes == 0 then return 0 end
    
    local value = 0
    
    if byte_order == "Motorola" then
        -- Big-endian (MSB first)
        local start_byte = math.floor(start_bit / 8)
        local bit_offset = start_bit % 8
        
        for i = 0, length - 1 do
            local byte_idx = start_byte + math.floor((bit_offset + i) / 8)
            local bit_in_byte = (bit_offset + i) % 8
            
            if data_bytes[byte_idx + 1] then
                local b = bit_lib.band(bit_lib.rshift(data_bytes[byte_idx + 1], 7 - bit_in_byte), 1)
                value = bit_lib.bor(bit_lib.lshift(value, 1), b)
            end
        end
    else
        -- Intel (LSB first)
        for i = 0, length - 1 do
            local byte_idx = math.floor((start_bit + i) / 8)
            local bit_in_byte = (start_bit + i) % 8
            
            if data_bytes[byte_idx + 1] then
                local b = bit_lib.band(bit_lib.rshift(data_bytes[byte_idx + 1], bit_in_byte), 1)
                value = bit_lib.bor(value, bit_lib.lshift(b, i))
            end
        end
    end
    
    return value
end

return M
