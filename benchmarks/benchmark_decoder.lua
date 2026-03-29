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

-- Configuration
local frames_per_batch = 100000
local frame_in_size = ffi.sizeof("FrameIn")    -- 16
local frame_out_size = ffi.sizeof("FrameOut")  -- 20 (due to alignment)
local batch_bytes_in = frames_per_batch * frame_in_size
local batch_bytes_out = frames_per_batch * frame_out_size

-- Initialize pool (2 buffers of each type)
mylib.init_pool(2, batch_bytes_in)   -- for input
mylib.init_pool(2, batch_bytes_out)  -- for output (we'll need separate pools, but here we just reuse the same global pool; better to have separate pools. For simplicity, we'll use one pool with large buffers.)
-- Actually, let's use one pool with large enough buffers to hold either input or output.
-- We'll just allocate two buffers manually.

local input_buf = mylib.acquire_buffer(batch_bytes_in)
if input_buf == nil then
    print("Failed to acquire input buffer")
    return
end
local output_buf = mylib.acquire_buffer(batch_bytes_out)
if output_buf == nil then
    mylib.release_buffer(input_buf)
    print("Failed to acquire output buffer")
    return
end

-- Fill input buffer with test frames (ID=0x123, DLC=2, speed data)
local input_ptr = ffi.cast("FrameIn*", input_buf)
for i = 0, frames_per_batch - 1 do
    local frame = input_ptr + i
    frame.id = 0x123
    frame.dlc = 2
    frame.data[0] = 100   -- high byte of speed (e.g., 10000 raw)
    frame.data[1] = 0     -- low byte
    frame.data[2] = 0
    frame.data[3] = 0
    frame.data[4] = 0
    frame.data[5] = 0
    frame.data[6] = 0
    frame.data[7] = 0
    -- padding already zero
end

-- Warm-up
mylib.process_frames(input_buf, frames_per_batch, output_buf)

-- Benchmark
local start = os.clock()
local iterations = 100
for _ = 1, iterations do
    mylib.process_frames(input_buf, frames_per_batch, output_buf)
end
local elapsed = os.clock() - start

local total_frames = frames_per_batch * iterations
local frames_per_sec = total_frames / elapsed
print(string.format("Processed %d frames in %.3f seconds => %.2f million frames/sec",
                    total_frames, elapsed, frames_per_sec / 1e6))

-- Verify first few output frames
local output_ptr = ffi.cast("FrameOut*", output_buf)
print("First 5 output frames:")
for i = 0, math.min(4, frames_per_batch - 1) do
    local out = output_ptr + i
    print(string.format("  ID=0x%x, speed=%.2f m/s", out.id, out.speed))
end

-- Release
mylib.release_buffer(input_buf)
mylib.release_buffer(output_buf)
