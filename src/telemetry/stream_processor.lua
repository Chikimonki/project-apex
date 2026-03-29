local ffi = require("ffi")
local mylib = ffi.load("combined")   -- adjust path if needed
local os = require("os")

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
local FRAMES_PER_BATCH = 100000
local FRAME_IN_SIZE = ffi.sizeof("FrameIn")    -- 16
local FRAME_OUT_SIZE = ffi.sizeof("FrameOut")  -- likely 20 (due to alignment)
local BATCH_BYTES_IN = FRAMES_PER_BATCH * FRAME_IN_SIZE
local BATCH_BYTES_OUT = FRAMES_PER_BATCH * FRAME_OUT_SIZE

-- The output buffer is larger, so we initialize the pool with that size.
-- (Input buffers are smaller and will fit.)
local POOL_BUFFER_SIZE = math.max(BATCH_BYTES_IN, BATCH_BYTES_OUT)
mylib.init_pool(2, POOL_BUFFER_SIZE)   -- two buffers, each large enough for either input or output

-- Helper: simulate incoming frames (replace with real data source)
local function get_next_frames(buf, max_frames)
    local frames = ffi.cast("FrameIn*", buf)
    for i = 0, max_frames - 1 do
        local frame = frames + i
        frame.id = 0x123
        frame.dlc = 2
        frame.data[0] = 100   -- speed high byte
        frame.data[1] = 0     -- low byte
        -- rest zeros (padding and data[2..7] are already zero)
    end
    return max_frames
end

-- Main loop
local total_processed = 0
while true do
    -- Acquire input buffer (size may be less than POOL_BUFFER_SIZE, but that's fine)
    local input_buf = mylib.acquire_buffer(BATCH_BYTES_IN)
    if input_buf == nil then
        print("No input buffer available, waiting...")
        os.execute("sleep 0.001")
        goto continue
    end

    local num_frames = get_next_frames(input_buf, FRAMES_PER_BATCH)
    if num_frames == 0 then break end

    -- Acquire output buffer (exact size needed)
    local output_buf = mylib.acquire_buffer(num_frames * FRAME_OUT_SIZE)
    if output_buf == nil then
        mylib.release_buffer(input_buf)
        print("No output buffer available, waiting...")
        os.execute("sleep 0.001")
        goto continue
    end

    -- Process
    mylib.process_frames(input_buf, num_frames, output_buf)

    -- Use output (example: print every 1000th frame)
    local out_ptr = ffi.cast("FrameOut*", output_buf)
    for i = 0, num_frames - 1 do
        local out = out_ptr + i
        if total_processed % 1000 == 0 then
            print(string.format("Frame %d: ID=0x%x, speed=%.2f m/s",
                                total_processed, out.id, out.speed))
        end
        total_processed = total_processed + 1
    end

    -- Release buffers
    mylib.release_buffer(input_buf)
    mylib.release_buffer(output_buf)

    ::continue::
end
