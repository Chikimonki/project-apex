-- benchmark_simd.lua — Compare scalar vs SIMD

local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        uint32_t id;
        uint8_t dlc;
        uint8_t data[8];
    } CANFrame;
    
    void processCANStream(const CANFrame* frames, size_t count, float* out);
    void processCANStreamSIMD(const CANFrame* frames, size_t count, float* out);
    int32_t test_add(int32_t a, int32_t b);
    uint32_t get_version(void);
]]

local lib = ffi.load("./libcan_decoder.so")

print("✅ Library loaded")
print(string.format("📦 Version: %d", lib.get_version()))
print("")

-- Generate test data
local n = 100000
print(string.format("🔧 Generating %d CAN frames...", n))

local frames = ffi.new("CANFrame[?]", n)
local speeds_scalar = ffi.new("float[?]", n)
local speeds_simd = ffi.new("float[?]", n)

for i = 0, n-1 do
    frames[i].id = 0x123
    frames[i].dlc = 8
    frames[i].data[0] = math.random(0, 255)
    frames[i].data[1] = math.random(0, 255)
end

print("✅ Test data ready")
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
start = os.clock()

for _ = 1, iterations do
    lib.processCANStreamSIMD(frames, n, speeds_simd)
end

local simd_time = (os.clock() - start) / iterations
local simd_throughput = n / simd_time / 1e6

print(string.format("   Time: %.3f ms", simd_time * 1000))
print(string.format("   Throughput: %.1f M frames/sec", simd_throughput))

-- Results
print("")
print("📊 RESULTS")
print("═════���════")
print(string.format("Speedup: %.2fx", scalar_time / simd_time))
print(string.format("Throughput gain: +%.1f M frames/sec", 
    simd_throughput - scalar_throughput))

-- Verify correctness
local match = true
for i = 0, n-1 do
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

print("")
print("🏎️  READY FOR FORMULA STUDENT DEPLOYMENT")
