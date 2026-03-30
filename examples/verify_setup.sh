#!/bin/bash

echo "🔍 Verifying project structure..."
echo ""

check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ $1 (missing)"
    fi
}

check_file "src/pipeline_simple.lua"
check_file "src/pipeline_fast.zig"
check_file "src/pipeline_fast.lua"
check_file "examples/run_pipeline.lua"
check_file "examples/data/sample_canbus.csv"
check_file "build_fast.sh"

echo ""
echo "🚀 Ready to run!"
echo "   ./build_fast.sh       # Build Zig optimizations"
echo "   make pipeline         # Run the pipeline"
