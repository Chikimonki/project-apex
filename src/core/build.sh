#!/bin/bash
set -e

echo "🏁 Building APEX telemetry stack..."
echo ""

# Build CAN decoder
echo "📦 Building CAN decoder..."
zig build-lib can_decoder.zig \
    -dynamic \
    -O ReleaseFast \
    -femit-bin=libcan_decoder.so

echo "✅ libcan_decoder.so built"

# Build Kalman filter library
echo "📦 Building Kalman filter..."
zig build-lib kalman_filter.zig \
    -dynamic \
    -O ReleaseFast \
    -femit-bin=libkalman.so

echo "✅ libkalman.so built"

# Build test harnesses
echo "🧪 Building tests..."
zig build-exe can_decoder_test.zig -O ReleaseFast -femit-bin=test_can
zig build-exe kalman_test.zig -O ReleaseFast -femit-bin=test_kalman

echo ""
echo "🔗 Exported symbols (CAN):"
nm -D libcan_decoder.so | grep " T " | head -5

echo ""
echo "🔗 Exported symbols (Kalman):"
nm -D libkalman.so | grep " T " | head -5

echo ""
echo "═══════════════════════════════"
echo "Running tests..."
echo "═══════════════════════════════"

./test_can
./test_kalman

echo ""
echo "✨ Build complete!"
