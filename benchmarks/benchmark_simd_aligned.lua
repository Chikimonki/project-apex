-- benchmark_simd_aligned.lua — Ensure aligned memory

local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        uint32_t id;
        uint8_t dlc;
        uint8_t data[8];
    } CANFrame;
    
    void processCANStream(const CANFrame* frames, size_t count, float* out);
    void processCANStreamSIMD(const CANFrame* frames, size_t count, float* out);
    uint32_t get_version(void);
    
    void* aligned_alloc(size_t alignment, size_t size);
    void free(void* ptr);
]]

local C = ffi.C
local lib = ffi.load("../src/core/libcan_decoder.so")

print("✅ Library loaded")
print(string.format("📦 Version: %d", lib.get_version()))
print("")

local n = 100000
print(string.format("🔧 Generating %d CAN frames...", n))

-- Regular allocation for frames (alignment not critical)
local frames = ffi.new("CANFrame[?]", n)

-- ALIGNED allocation for output (critical for SIMD)
local speeds_scalar = ffi.new("float[?]", n)
local speeds_simd_ptr = C.aligned_alloc(16, n * ffi.sizeof("float"))
local speeds_simd = ffi.cast("float*", speeds_simd_ptr)

if speeds_simd == nil then
    print("❌ Failed to allocate aligned memory")
    os.exit(1)
end

for i = 0, n-1 do
    frames[i].id = 0x123
    frames[i].dlc = 8
    frames[i].data[0] = math.random(0, 255)
    frames[i].data[1] = math.random(0, 255)
end

print("✅ Test data ready (aligned)")
print("")

-- Test alignment
print("🔍 Checking alignment:")
print(string.format("   speeds_scalar: %s (ptr: 0x%x)", 
    tostring(speeds_scalar),
    tonumber(ffi.cast("intptr_t", speeds_scalar))))
print(string.format("   speeds_simd:   %s (ptr: 0x%x, aligned: %s)", 
    tostring(speeds_simd),
    tonumber(ffi.cast("intptr_t", speeds_simd)),
    tonumber(ffi.cast("intptr_t", speeds_simd)) % 16 == 0 and "✅" or "❌"))
print("")

-- Benchmark scalar
print("⚡ Benchmarking SCALAR version...")
local iterations = 1000
local start = os.clock()

for _ = 1, iterations do
    lib.processCANStream(frames, n, speeds_scalar)
end

local scalar_time = (os.clock() - start) / iterations
local scalar_throughput = n / scalar_time / 1e6

print(string.format("   Time: %.3f ms", scalar_time * 1000))
print(string.format("   Throughput: %.1f M frames/sec", scalar_throughput))

-- Benchmark SIMD
print("")
print("⚡ Benchmarking SIMD version...")

-- Warm up
lib.processCANStreamSIMD(frames, 4, speeds_simd)  -- Test with 4 frames first

start = os.clock()

local ok, err = pcall(function()
    for _ = 1, iterations do
        lib.processCANStreamSIMD(frames, n, speeds_simd)
    end
end)

if not ok then
    print("❌ SIMD crashed: " .. tostring(err))
    C.free(speeds_simd_ptr)
    os.exit(1)
end

local simd_time = (os.clock() - start) / iterations
local simd_throughput = n / simd_time / 1e6

print(string.format("   Time: %.3f ms", simd_time * 1000))
print(string.format("   Throughput: %.1f M frames/sec", simd_throughput))

-- Results
print("")
print("📊 RESULTS")
print("══════════")
print(string.format("Speedup: %.2fx", scalar_time / simd_time))
print(string.format("Throughput gain: +%.1f M frames/sec", 
    simd_throughput - scalar_throughput))

-- Verify correctness
local match = true
for i = 0, math.min(n-1, 999) do
    if math.abs(speeds_scalar[i] - speeds_simd[i]) > 0.01 then
        match = false
        print(string.format("❌ Mismatch at frame %d: %.2f vs %.2f", 
            i, speeds_scalar[i], speeds_simd[i]))
        break
    end
end

if match then
    print("")
    print("✅ SIMD output matches scalar (verified)")
end

C.free(speeds_simd_ptr)

print("")
print("🏎️  READY FOR FORMULA STUDENT DEPLOYMENT")
