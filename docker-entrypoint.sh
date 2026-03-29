#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════╗"
echo "║  APEX TELEMETRY STACK - DOCKER                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Start Redis in background
echo "🔧 Starting Redis..."
redis-server --daemonize yes --protected-mode no
sleep 2

# Check Redis is up
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis running"
else
    echo "❌ Redis failed to start"
    exit 1
fi

# Start telemetry streamer in background
echo "🚀 Starting telemetry streamer..."
cd /app/src/telemetry
luajit redis_streamer.lua &
STREAMER_PID=$!
sleep 2

# Start WebSocket server (foreground)
echo "🌐 Starting WebSocket server..."
echo "   Access dashboard at: http://localhost:8082"
echo ""
luajit websocket_simple.lua

# Cleanup on exit
trap "kill $STREAMER_PID; redis-cli shutdown" EXIT
