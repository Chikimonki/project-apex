-- test_buffer_pool.lua
local ffi = require("ffi")

-- Adjust the library name based on your OS and build output.
-- On Linux, it will be "libbuffer_pool.so".
-- On macOS, "libbuffer_pool.dylib".
-- On Windows, "buffer_pool.dll".
local mylib = ffi.load("buffer_pool")  -- assumes the library is in a directory Lua searches

ffi.cdef[[
    void init_pool(size_t num_buffers, size_t buffer_size);
    void* acquire_buffer(size_t size);
    void release_buffer(void* ptr);
]]

-- Initialize with 2 buffers of 1 MB each
local num_buffers = 2
local buffer_size = 1024 * 1024
mylib.init_pool(num_buffers, buffer_size)

print("Pool initialized with", num_buffers, "buffers of", buffer_size, "bytes")

-- Acquire two buffers (should succeed)
local buf1 = mylib.acquire_buffer(1024)   -- request 1 KB
assert(buf1 ~= nil, "Failed to acquire buffer 1")
print("Acquired buffer 1:", ffi.cast("uint8_t*", buf1))

local buf2 = mylib.acquire_buffer(1024)
assert(buf2 ~= nil, "Failed to acquire buffer 2")
print("Acquired buffer 2:", ffi.cast("uint8_t*", buf2))

-- Third acquisition should fail because pool is full
local buf3 = mylib.acquire_buffer(1024)
assert(buf3 == nil, "Acquired a third buffer unexpectedly")
print("Third acquisition correctly returned nil")

-- Release first buffer
mylib.release_buffer(buf1)
print("Released buffer 1")

-- Now we can acquire again
local buf4 = mylib.acquire_buffer(1024)
assert(buf4 ~= nil, "Failed to acquire after release")
print("Acquired buffer 4 after release:", ffi.cast("uint8_t*", buf4))

-- Clean up
mylib.release_buffer(buf2)
mylib.release_buffer(buf4)

print("Test passed!")
