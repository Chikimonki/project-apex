#!/bin/bash
source ~/project-apex/setup_env.sh

# Launch rviz2 with f1_car as fixed frame
rviz2 -f f1_car -d ~/project-apex/ros2_ws/src/f1_telemetry_viz/config/f1_telemetry.rviz
