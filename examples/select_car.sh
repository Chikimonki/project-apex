#!/bin/bash
# Interactive car selector for Project APEX

clear
echo "🏎️  PROJECT APEX - Car Selector"
echo "═══════════════════════════════════════"
echo ""
echo "Select a car:"
echo ""
echo "  1. 🔴 Ferrari 488 Challenge"
echo "  2. 🔴 Ferrari F12 Berlinetta"
echo "  3. 🟠 McLaren P1"
echo "  4. 🔵 Porsche 911 GT3 Cup"
echo "  5. 🟡 Porsche Cayman GT4 Clubsport"
echo "  6. 🟢 Aston Martin V12 Zagato"
echo ""
echo "  0. Exit"
echo ""
read -p "Choice [1-6]: " choice

case $choice in
    1) CAR_NAME="Ferrari 488 Challenge" ;;
    2) CAR_NAME="Ferrari F12 Berlinetta" ;;
    3) CAR_NAME="McLaren P1" ;;
    4) CAR_NAME="Porsche 911 GT3 Cup" ;;
    5) CAR_NAME="Porsche Cayman GT4 Clubsport" ;;
    6) CAR_NAME="Aston Martin V12 Zagato" ;;
    0) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid choice!"; exit 1 ;;
esac

echo ""
echo "🏁 Launching $CAR_NAME..."
echo ""

# Kill any existing session
tmux kill-session -t apex 2>/dev/null
pkill -f "ros2" 2>/dev/null
pkill -f "rviz2" 2>/dev/null
sleep 1

# Create new session
SESSION="apex"
tmux new-session -d -s $SESSION

# Window 0: TF Publisher
tmux rename-window -t $SESSION:0 'TF'
tmux send-keys -t $SESSION:0 "cd ~/project-apex && source setup_env.sh && ros2 run f1_telemetry_publisher tf_publisher" C-m

# Window 1: Visualizer
tmux new-window -t $SESSION:1 -n 'Visualizer'
tmux send-keys -t $SESSION:1 "cd ~/project-apex && source setup_env.sh && sleep 2 && ros2 run f1_telemetry_publisher visualizer_enhanced" C-m

# Window 2: RViz
tmux new-window -t $SESSION:2 -n 'RViz'
tmux send-keys -t $SESSION:2 "cd ~/project-apex && source setup_env.sh && sleep 3 && QT_QPA_PLATFORM=xcb rviz2 -f f1_car" C-m

# Window 3: Pipeline
tmux new-window -t $SESSION:3 -n "$CAR_NAME"
tmux send-keys -t $SESSION:3 "cd ~/project-apex && source setup_env.sh && export CAR_NAME='$CAR_NAME' && sleep 4 && luajit examples/run_multicar_pipeline.lua | ros2 run f1_telemetry_publisher can_publisher" C-m

echo "🏎️ $CAR_NAME launching in tmux..."
echo ""
echo "Press any key to attach to session..."
read -n 1

tmux attach-session -t $SESSION
