-- src/motec_ref_parser.lua
-- Parser for MoTeC .REF reference files

local M = {}

function M.parse_ref_file(path)
    local file = io.open(path, "r")
    if not file then
        error("Cannot open .REF file: " .. path)
    end
    
    local signals = {}
    local current_signal = nil
    
    io.stderr:write("📖 Parsing MoTeC .REF file: " .. path .. "\n")
    
    for line in file:lines() do
        -- Remove leading/trailing whitespace
        line = line:match("^%s*(.-)%s*$")
        
        -- Skip empty lines and comments
        if line ~= "" and not line:match("^//") then
            -- New signal definition
            if line:match("^%[.*%]$") then
                local signal_name = line:match("%[(.+)%]")
                current_signal = {
                    name = signal_name,
                    channel = "",
                    id = 0,
                    start_bit = 0,
                    length = 0,
                    byte_order = "MSB",
                    value_type = "Unsigned",
                    factor = 1.0,
                    offset = 0.0,
                    min = 0,
                    max = 0,
                    unit = "",
                    comment = ""
                }
                signals[signal_name] = current_signal
                io.stderr:write("  Found signal: " .. signal_name .. "\n")
                
            -- Parse key-value pairs
            elseif current_signal and line:match("=") then
                local key, value = line:match("(.+)%s*=%s*(.+)")
                if key and value then
                    key = key:match("^%s*(.-)%s*$")
                    value = value:match("^%s*(.-)%s*$")
                    
                    if key == "Channel" then
                        current_signal.channel = value
                    elseif key == "ID" then
                        current_signal.id = tonumber(value:gsub("0x", ""), 16) or tonumber(value)
                    elseif key == "StartBit" then
                        current_signal.start_bit = tonumber(value)
                    elseif key == "Length" then
                        current_signal.length = tonumber(value)
                    elseif key == "ByteOrder" then
                        current_signal.byte_order = value
                    elseif key == "ValueType" then
                        current_signal.value_type = value
                    elseif key == "Factor" then
                        current_signal.factor = tonumber(value) or 1.0
                    elseif key == "Offset" then
                        current_signal.offset = tonumber(value) or 0.0
                    elseif key == "Min" then
                        current_signal.min = tonumber(value) or 0
                    elseif key == "Max" then
                        current_signal.max = tonumber(value) or 0
                    elseif key == "Unit" then
                        current_signal.unit = value:gsub('"', '')
                    elseif key == "Comment" then
                        current_signal.comment = value:gsub('"', '')
                    end
                end
            end
        end
    end
    
    file:close()
    
    io.stderr:write("✅ Parsed " .. M.count_signals(signals) .. " signals\n")
    
    return signals
end

function M.count_signals(signals)
    local count = 0
    for _ in pairs(signals) do count = count + 1 end
    return count
end

-- Print signal definitions
function M.print_signals(signals)
    io.stderr:write("\n📊 Signal Definitions:\n")
    io.stderr:write(string.rep("─", 80) .. "\n")
    
    for name, sig in pairs(signals) do
        io.stderr:write(string.format(
            "%-25s | CAN ID: 0x%03X | Bits: %2d-%2d | Scale: %.4f | Unit: %s\n",
            name, sig.id, sig.start_bit, sig.start_bit + sig.length - 1,
            sig.factor, sig.unit
        ))
    end
end

return M
