#!/bin/bash
SESSION="ferrari_488"
tmux kill-session -t $SESSION 2>/dev/null
tmux new-session -d -s $SESSION

# TF
tmux rename-window -t $SESSION:0 'TF'
tmux send-keys -t $SESSION:0 'cd ~/project-apex && source setup_env.sh && ros2 run f1_telemetry_publisher tf_publisher' C-m

# Visualizer Enhanced
tmux new-window -t $SESSION:1 -n 'Visualizer'
tmux send-keys -t $SESSION:1 'cd ~/project-apex && source setup_env.sh && sleep 1 && ros2 run f1_telemetry_publisher visualizer_enhanced' C-m

# rviz2
tmux new-window -t $SESSION:2 -n 'RViz'
tmux send-keys -t $SESSION:2 'cd ~/project-apex && source setup_env.sh && sleep 2 && QT_QPA_PLATFORM=xcb rviz2 -f f1_car' C-m

# Ferrari Pipeline
tmux new-window -t $SESSION:3 -n 'Ferrari-488'
tmux send-keys -t $SESSION:3 'cd ~/project-apex && source setup_env.sh && sleep 3 && luajit examples/run_ferrari_pipeline.lua | ros2 run f1_telemetry_publisher can_publisher' C-m

echo "🏎️  Ferrari 488 Challenge @ Monza launching..."
sleep 4
tmux attach-session -t $SESSION
