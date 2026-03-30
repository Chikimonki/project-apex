cat > src/pipeline_fast.lua << 'EOF'
-- src/pipeline_fast.lua
-- FFI bindings for Zig optimizations

local ffi = require("ffi")

ffi.cdef[[
    size_t hex_to_bytes_fast(const char* hex_str, uint8_t* out_bytes, size_t len);
    void compute_stats(const double* values, size_t count, double* out_mean, double* out_max);
]]

-- Load the library
local lib = ffi.load("./libpipeline_fast.so")

local M = {}

function M.hex_to_bytes(hex_string)
    local bytes = ffi.new("uint8_t[?]", #hex_string / 2)
    local count = lib.hex_to_bytes_fast(hex_string, bytes, #hex_string)
    
    local result = {}
    for i = 0, count - 1 do
        result[i + 1] = bytes[i]
    end
    return result
end

function M.compute_batch_stats(values)
    local n = #values
    local c_values = ffi.new("double[?]", n)
    for i = 1, n do
        c_values[i-1] = values[i]
    end
    
    local mean = ffi.new("double[1]")
    local max_val = ffi.new("double[1]")
    
    lib.compute_stats(c_values, n, mean, max_val)
    
    return mean[0], max_val[0]
end

return M
