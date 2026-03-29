-- process_csv.lua
local ffi = require("ffi")
local mylib = ffi.load("combined")

ffi.cdef[[
    void init_pool(size_t num_buffers, size_t buffer_size);
    void* acquire_buffer(size_t size);
    void release_buffer(void* ptr);
    void process_frames(const uint8_t* input, size_t num_frames, uint8_t* output);

    typedef struct {
        uint32_t id;
        uint8_t dlc;
        uint8_t padding[3];
        uint8_t data[8];
    } FrameIn;

    typedef struct {
        uint32_t id;
        uint8_t dlc;
        uint8_t data[8];
        float speed;
    } FrameOut;
]]

-- Constants
local FRAMES_PER_BATCH = 10000   -- adjust based on memory
local FRAME_IN_SIZE = ffi.sizeof("FrameIn")   -- 16
local FRAME_OUT_SIZE = ffi.sizeof("FrameOut") -- ~20
local BATCH_BYTES_IN = FRAMES_PER_BATCH * FRAME_IN_SIZE
local BATCH_BYTES_OUT = FRAMES_PER_BATCH * FRAME_OUT_SIZE

-- Initialize pool (use max size)
local POOL_SIZE = math.max(BATCH_BYTES_IN, BATCH_BYTES_OUT)
mylib.init_pool(2, POOL_SIZE)

-- Open CSV file
local filename = "path/to/your/file.csv"
local file = io.open(filename, "r")
if not file then
    print("Cannot open " .. filename)
    return
end

-- Allocate input buffer
local input_buf = mylib.acquire_buffer(BATCH_BYTES_IN)
if not input_buf then
    print("Failed to acquire input buffer")
    file:close()
    return
end

-- Output buffer
local output_buf = mylib.acquire_buffer(BATCH_BYTES_OUT)
if not output_buf then
    mylib.release_buffer(input_buf)
    file:close()
    print("Failed to acquire output buffer")
    return
end

local frames_in_batch = 0
local total_frames = 0
local in_ptr = ffi.cast("FrameIn*", input_buf)

-- Helper to parse a line and fill the next frame
local function parse_line(line)
    -- Example: "123,8,1,2,3,4,5,6,7,8"
    -- Adapt to your format
    local id_str, dlc_str, data_strs = line:match("^(%d+),(%d+),(.*)$")
    if not id_str then return false end
    local id = tonumber(id_str)
    local dlc = tonumber(dlc_str)
    local data = {}
    for b in data_strs:gmatch("[^,]+") do
        table.insert(data, tonumber(b))
    end
    if #data ~= dlc then
        -- pad with zeros if needed
        while #data < 8 do table.insert(data, 0) end
    end
    -- Write into current frame in input buffer
    local frame = in_ptr + frames_in_batch
    frame.id = id
    frame.dlc = dlc
    for i = 0, 7 do
        frame.data[i] = data[i+1] or 0
    end
    frames_in_batch = frames_in_batch + 1
    return true
end

-- Process lines
for line in file:lines() do
    if parse_line(line) then
        if frames_in_batch == FRAMES_PER_BATCH then
            -- Process batch
            mylib.process_frames(input_buf, frames_in_batch, output_buf)
            -- Do something with output (e.g., write to file)
            local out_ptr = ffi.cast("FrameOut*", output_buf)
            for i = 0, frames_in_batch - 1 do
                local out = out_ptr + i
                -- Example: print speed if ID=0x123
                if out.id == 0x123 then
                    print(string.format("Frame %d: speed=%.2f m/s", total_frames + i, out.speed))
                end
            end
            total_frames = total_frames + frames_in_batch
            frames_in_batch = 0
            -- Reset pointer (we reuse the same buffer; no need to clear)
        end
    end
end

-- Process any remaining frames
if frames_in_batch > 0 then
    mylib.process_frames(input_buf, frames_in_batch, output_buf)
    local out_ptr = ffi.cast("FrameOut*", output_buf)
    for i = 0, frames_in_batch - 1 do
        local out = out_ptr + i
        if out.id == 0x123 then
            print(string.format("Frame %d: speed=%.2f m/s", total_frames + i, out.speed))
        end
    end
    total_frames = total_frames + frames_in_batch
end

file:close()
mylib.release_buffer(input_buf)
mylib.release_buffer(output_buf)

print("Processed", total_frames, "frames")
