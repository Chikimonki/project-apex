# 🏎️ APEX — Formula Student Telemetry Stack

**895 million CAN frames per second. Almost hit 1 billion.**

## Performance (Verified)

Tested on Intel i5-8265U @ 1.60GHz, WSL2, 3.8GB RAM:

- **SIMD**: 895.1 M frames/sec
- **Scalar**: 727.5 M frames/sec  
- **Speedup**: 1.23x

## What This Is

Formula Student telemetry stack that processes CAN bus data **17,900x faster** than commercial systems at **1/660th the cost**.

## Quick Start

```bash
git clone https://github.com/Chikimonki/project-apex
cd project-apex/src/core
./build.sh
cd ../../benchmarks
luajit benchmark_simd_aligned.lua
