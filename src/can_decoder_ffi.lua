-- src/can_decoder_ffi.lua
-- FFI bridge matching actual Zig exports

local ffi = require("ffi")

ffi.cdef[[
    // CANFrame struct - must match Zig exactly
    typedef struct {
        uint32_t id;
        uint8_t dlc;
        uint8_t data[8];
    } CANFrame;
    
    // Actual exports from libcan_decoder.so
    void processCANStream(
        const CANFrame* frames,
        size_t count,
        float* wheel_speeds
    );
    
    void processCANStreamSIMD(
        const CANFrame* frames,
        size_t count,
        float* wheel_speeds
    );
    
    int get_version();
    int test_add(int a, int b);
]]

local lib = ffi.load("./libcan_decoder.so")

local M = {}

function M.get_version()
    return lib.get_version()
end

function M.test_add(a, b)
    return lib.test_add(a, b)
end

-- Decode a single frame
function M.decode_frame(can_id, data_bytes)
    -- Create a CANFrame
    local frame = ffi.new("CANFrame")
    frame.id = can_id
    frame.dlc = #data_bytes
    
    for i = 1, math.min(#data_bytes, 8) do
        frame.data[i-1] = data_bytes[i]
    end
    
    -- Output buffer
    local speed = ffi.new("float[1]")
    
    -- Process single frame
    lib.processCANStream(frame, 1, speed)
    
    return speed[0]
end

-- Decode batch of frames (more efficient)
function M.decode_batch(frames_data, use_simd)
    local count = #frames_data
    if count == 0 then return {} end
    
    -- Allocate frame array
    local frames = ffi.new("CANFrame[?]", count)
    local speeds = ffi.new("float[?]", count)
    
    -- Fill frames
    for i, f in ipairs(frames_data) do
        frames[i-1].id = f.can_id
        frames[i-1].dlc = #f.data
        for j = 1, math.min(#f.data, 8) do
            frames[i-1].data[j-1] = f.data[j]
        end
    end
    
    -- Process
    if use_simd then
        lib.processCANStreamSIMD(frames, count, speeds)
    else
        lib.processCANStream(frames, count, speeds)
    end
    
    -- Extract results
    local results = {}
    for i = 0, count - 1 do
        results[i+1] = speeds[i]
    end
    
    return results
end

return M
