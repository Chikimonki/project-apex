#!/bin/bash
SESSION="f1_dramatic"
tmux kill-session -t $SESSION 2>/dev/null
tmux new-session -d -s $SESSION

tmux rename-window -t $SESSION:0 'TF'
tmux send-keys -t $SESSION:0 'cd ~/project-apex && source setup_env.sh && ros2 run f1_telemetry_publisher tf_publisher' C-m

tmux new-window -t $SESSION:1 -n 'Visualizer'
tmux send-keys -t $SESSION:1 'cd ~/project-apex && source setup_env.sh && sleep 1 && ros2 run f1_telemetry_publisher visualizer_enhanced' C-m

tmux new-window -t $SESSION:2 -n 'RViz'
tmux send-keys -t $SESSION:2 'cd ~/project-apex && source setup_env.sh && sleep 2 && QT_QPA_PLATFORM=xcb rviz2 -f f1_car' C-m

tmux new-window -t $SESSION:3 -n 'Dramatic'
tmux send-keys -t $SESSION:3 'cd ~/project-apex && source setup_env.sh && sleep 3 && luajit examples/run_dramatic_pipeline.lua | ros2 run f1_telemetry_publisher can_publisher' C-m

echo "🏎️💨 DRAMATIC Ferrari 488 launching!"
sleep 4
tmux attach-session -t $SESSION
