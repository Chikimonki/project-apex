#!/usr/bin/env luajit
-- Decompress VBOX .REF files (zlib compressed)

local ffi = require("ffi")
local zlib = require("zlib")

ffi.cdef[[
    unsigned long compressBound(unsigned long sourceLen);
    int uncompress(uint8_t *dest, unsigned long *destLen,
                   const uint8_t *source, unsigned long sourceLen);
]]

local function decompress_vbox(input_path, output_path)
    local file = io.open(input_path, "rb")
    if not file then
        error("Cannot open: " .. input_path)
    end
    
    local data = file:read("*all")
    file:close()
    
    -- Skip VBOX header (find zlib magic bytes 0x78DA)
    local zlib_start = data:find("\x78\xDA")
    if not zlib_start then
        print("No zlib data found")
        return
    end
    
    print("Found zlib data at offset: " .. zlib_start)
    
    -- Extract compressed portion
    local compressed = data:sub(zlib_start)
    
    -- Decompress using LuaJIT's zlib
    local stream = zlib.inflate()
    local decompressed = stream(compressed)
    
    -- Write output
    local out = io.open(output_path, "w")
    out:write(decompressed)
    out:close()
    
    print("✅ Decompressed to: " .. output_path)
end

-- Run
local input = arg[1] or "Ferrari-488 Challenge (X710 Connector) 2020-.REF"
local output = input:gsub("%.REF$", "_decompressed.txt")

decompress_vbox(input, output)
