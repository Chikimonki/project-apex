#!/bin/bash
echo "🔨 Building Zig optimizations..."
zig build-lib src/pipeline_fast.zig \
    -dynamic \
    -O ReleaseFast \
    -femit-bin=libpipeline_fast.so
echo "✅ Built libpipeline_fast.so"
