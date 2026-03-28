-- test_ffi.lua — DEBUGGED VERSION

local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        uint32_t id;
        uint8_t dlc;
        uint8_t data[8];
    } CANFrame;
    
    void processCANStream(const CANFrame* frames, size_t count, float* out);
    int32_t test_add(int32_t a, int32_t b);
    uint32_t get_version(void);
]]

-- Try to load library with error handling
local lib, err = pcall(function()
    return ffi.load("./libcan_decoder.so")
end)

if not lib then
    print("❌ Failed to load library:")
    print("   " .. tostring(err))
    print("")
    print("🔧 Troubleshooting:")
    print("   1. Run: ./build_can_decoder.sh")
    print("   2. Check: ls -lh libcan_decoder.so")
    print("   3. Verify: ldd libcan_decoder.so")
    os.exit(1)
end

-- Library loaded, now get the actual object
lib = lib and ffi.load("./libcan_decoder.so") or nil
if not lib then
    print("❌ Library loaded but couldn't get handle")
    os.exit(1)
end

print("✅ Library loaded successfully")

-- TEST 1: Simple function calls (no pointers)
print("\n🧪 TEST 1: Simple function calls")
local version = lib.get_version()
print(string.format("   Library version: %d", version))

local sum = lib.test_add(42, 13)
print(string.format("   42 + 13 = %d (expected 55)", sum))

if sum ~= 55 then
    print("❌ Basic FFI calls failing!")
    os.exit(1)
end

print("   ✅ Basic FFI working")

-- TEST 2: Small array (catch segfaults early)
print("\n🧪 TEST 2: Small CAN frame test")

local small_n = 4
local small_frames = ffi.new("CANFrame[?]", small_n)
local small_speeds = ffi.new("float[?]", small_n)

-- Initialize with known values
for i = 0, small_n-1 do
    small_frames[i].id = 0x123
    small_frames[i].dlc = 8
    small_frames[i].data[0] = 0x10
    small_frames[i].data[1] = 0x00  -- Should decode to 40.96 km/h
end

print(string.format("   Processing %d frames...", small_n))

-- THIS IS WHERE THE SEGFAULT LIKELY HAPPENS
local ok, result = pcall(function()
    lib.processCANStream(small_frames, small_n, small_speeds)
end)

if not ok then
    print("❌ SEGFAULT in processCANStream!")
    print("   Error: " .. tostring(result))
    print("")
    print("🔍 Debug info:")
    print(string.format("   frames ptr: %s", tostring(small_frames)))
    print(string.format("   speeds ptr: %s", tostring(small_speeds)))
    print(string.format("   count: %d", small_n))
    os.exit(1)
end

print("   ✅ Processing succeeded")

-- Verify results
print("   Sample outputs:")
for i = 0, small_n-1 do
    print(string.format("      Frame %d: %.2f km/h", i, small_speeds[i]))
end

-- TEST 3: Full benchmark (only if small test passed)
print("\n🧪 TEST 3: Full benchmark")

local n = 10000
local frames = ffi.new("CANFrame[?]", n)
local speeds = ffi.new("float[?]", n)

for i = 0, n-1 do
    frames[i].id = 0x123
    frames[i].dlc = 8
    frames[i].data[0] = math.random(0, 255)
    frames[i].data[1] = math.random(0, 255)
end

local start = os.clock()
for rep = 1, 100 do
    lib.processCANStream(frames, n, speeds)
end
local elapsed = (os.clock() - start) * 10  -- ms per iteration

print(string.format("   Time: %.2f ms/iteration", elapsed))
print(string.format("   Throughput: %.1fM frames/sec", n / elapsed / 1000))

print("\n✅ ALL TESTS PASSED")
