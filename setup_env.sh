#!/bin/bash
# Setup script for project-apex (venv-first approach)

# Activate Python venv FIRST
source ~/project-apex/venv/bin/activate

# Source ROS 2 (will overlay on venv)
source /opt/ros/jazzy/setup.bash

# Source our workspace
if [ -d ~/project-apex/ros2_ws/install ]; then
    source ~/project-apex/ros2_ws/install/setup.bash
fi

# Set Python path
export PYTHONPATH=$VIRTUAL_ENV/lib/python3.12/site-packages:$PYTHONPATH

echo "✅ Environment ready (venv-first)!"
echo "   Python: $(which python3)"
echo "   Pip location: $(which pip)"
echo "   ROS 2: $ROS_DISTRO"
echo "   Workspace: ~/project-apex/ros2_ws"

# Suppress desktop notification errors (WSL/headless friendly)
export NO_AT_BRIDGE=1
