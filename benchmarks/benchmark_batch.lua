local ffi = require("ffi")
local mylib = ffi.load("combined")   -- adjust path if needed
local os = require("os")

ffi.cdef[[
    void init_pool(size_t num_buffers, size_t buffer_size);
    void* acquire_buffer(size_t size);
    void release_buffer(void* ptr);
    void process_frames(const uint8_t* input, size_t num_frames, uint8_t* output);
]]

local frames_per_batch = 100000
local batch_bytes = frames_per_batch * 8
local iterations = 100   -- total frames = frames_per_batch * iterations

mylib.init_pool(4, batch_bytes * 2)  -- enough for input and output buffers

local input_buf = mylib.acquire_buffer(batch_bytes)
local output_buf = mylib.acquire_buffer(batch_bytes)

-- Initialize input data (dummy)
local input_ptr = ffi.cast("uint8_t*", input_buf)
for i = 0, frames_per_batch - 1 do
    local base = i * 8
    for j = 0, 7 do
        input_ptr[base + j] = j
    end
end

local start = os.clock()
for i = 1, iterations do
    mylib.process_frames(input_buf, frames_per_batch, output_buf)
end
local elapsed = os.clock() - start

local total_frames = frames_per_batch * iterations
local frames_per_sec = total_frames / elapsed
print(string.format("Processed %d frames in %.3f seconds => %.2f million frames/sec",
                    total_frames, elapsed, frames_per_sec / 1e6))

mylib.release_buffer(input_buf)
mylib.release_buffer(output_buf)
