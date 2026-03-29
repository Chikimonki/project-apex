local ffi = require("ffi")
local mylib = ffi.load("buffer_pool")

ffi.cdef[[
    void init_pool(size_t, size_t);
    void* acquire_buffer(size_t);
    void release_buffer(void*);
]]

mylib.init_pool(2, 1024*1024) -- two 1 MB buffers

local buf1 = mylib.acquire_buffer(1024) -- get a 1 KB buffer
assert(buf1 ~= nil, "failed to acquire")
print("acquired buffer 1")

local buf2 = mylib.acquire_buffer(1024)
assert(buf2 ~= nil, "acquired buffer 2")

local buf3 = mylib.acquire_buffer(1024) -- should fail because pool is full
assert(buf3 == nil, "unexpected buffer")

mylib.release_buffer(buf1)
buf1 = nil

local buf4 = mylib.acquire_buffer(1024) -- should succeed now
assert(buf4 ~= nil, "should succeed after release")
print("OK")
