#!/bin/bash
set -e

cd ~/project-apex

# Source environment (ROS + venv)
source setup_env.sh

echo "🚀 Starting F1 Telemetry ROS 2 Pipeline"
echo "======================================="

# Start ROS 2 publisher with pipe
luajit examples/run_pipeline_streaming.lua | ros2 run f1_telemetry_publisher can_publisher
