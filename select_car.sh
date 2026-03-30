#!/bin/bash
# Interactive car selector for Project APEX

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
    1)
        CAR_NAME="Ferrari 488 Challenge"
        CAR_FILE="Ferrari-488 Challenge (X710 Connector) 2020-"
        CAR_COLOR="0.8,0.1,0.1"
        ;;
    2)
        CAR_NAME="Ferrari F12 Berlinetta"
        CAR_FILE="Ferrari-F12berlinetta"
        CAR_COLOR="0.8,0.0,0.2"
        ;;
    3)
        CAR_NAME="McLaren P1"
        CAR_FILE="McLaren-P1"
        CAR_COLOR="1.0,0.5,0.0"
        ;;
    4)
        CAR_NAME="Porsche 911 GT3 Cup"
        CAR_FILE="Porsche-911 (991) GT3 Cup Gen1 - Bosch Connector"
        CAR_COLOR="0.0,0.4,0.8"
        ;;
    5)
        CAR_NAME="Porsche Cayman GT4 Clubsport"
        CAR_FILE="Porsche-Cayman (981) GT4 Clubsport"
        CAR_COLOR="0.9,0.9,0.0"
        ;;
    6)
        CAR_NAME="Aston Martin V12 Zagato"
        CAR_FILE="Aston Martin-V12 Zagato"
        CAR_COLOR="0.0,0.5,0.3"
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "🏁 Launching $CAR_NAME..."
echo ""

# Export for tmux session
export CAR_NAME CAR_FILE CAR_COLOR

# Launch tmux session
SESSION="apex_${choice}"
tmux kill-session -t $SESSION 2>/dev/null
tmux new-session -d -s $SESSION

tmux rename-window -t $SESSION:0 'TF'
tmux send-keys -t $SESSION:0 "cd ~/project-apex && source setup_env.sh && ros2 run f1_telemetry_publisher tf_publisher" C-m

tmux new-window -t $SESSION:1 -n 'Visualizer'
tmux send-keys -t $SESSION:1 "cd ~/project-apex && source setup_env.sh && sleep 1 && ros2 run f1_telemetry_publisher visualizer_enhanced" C-m

tmux new-window -t $SESSION:2 -n 'RViz'
tmux send-keys -t $SESSION:2 "cd ~/project-apex && source setup_env.sh && sleep 2 && QT_QPA_PLATFORM=xcb rviz2 -f f1_car" C-m

tmux new-window -t $SESSION:3 -n "$CAR_NAME"
tmux send-keys -t $SESSION:3 "cd ~/project-apex && source setup_env.sh && sleep 3 && echo 'Car: $CAR_NAME' && luajit examples/run_dramatic_pipeline.lua | ros2 run f1_telemetry_publisher can_publisher" C-m

tmux attach-session -t $SESSION
