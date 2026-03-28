#!/bin/bash
# build_can_decoder.sh — FINAL WORKING VERSION

set -e

echo "🏁 Building CAN decoder for Zig 0.15.2 nightly..."
echo ""

# Clean
rm -f libcan_decoder.so can_decoder_test *.o

# Build shared library (no main() function)
echo "📦 Building shared library..."
zig build-lib can_decoder.zig \
    -dynamic \
    -O ReleaseFast \
    -femit-bin=libcan_decoder.so

echo "✅ libcan_decoder.so built"
file libcan_decoder.so

# Build test harness (optional)
echo ""
echo "🧪 Building test harness..."
zig build-exe can_decoder_test.zig \
    -O ReleaseFast \
    -femit-bin=can_decoder_test

echo "✅ can_decoder_test built"

# Run standalone test
echo ""
echo "Running standalone test..."
./can_decoder_test

# Check exported symbols
echo ""
echo "🔗 Exported symbols:"
nm -D libcan_decoder.so 2>/dev/null | grep -E "test_add|get_version|processCANStream" || true

echo ""
echo "✨ Ready for LuaJIT FFI testing!"
