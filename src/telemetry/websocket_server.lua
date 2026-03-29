#!/usr/bin/env luajit
-- websocket_server.lua — WebSocket server for real-time dashboard

local socket = require("socket")
local redis = require("redis")
local cjson = require("cjson")

print("╔════════════════════════════════════════════════╗")
print("║  APEX WEBSOCKET TELEMETRY SERVER               ║")
print("╚════════════════════════════════════════════════╝")
print()

-- Connect to Redis
local redis_client = redis.connect('127.0.0.1', 6379)
print("✅ Connected to Redis")

-- Create HTTP/WebSocket server
local server = socket.tcp()
server:bind("*", 8082)
server:listen(10)
server:settimeout(0.1)

print("✅ WebSocket server listening on http://localhost:8082")
print("   CORS enabled: *")
print("   Endpoint: /telemetry")
print()
print("🚀 Ready for connections...")
print()

local clients = {}
local frame_count = 0

-- Subscribe to Redis in non-blocking mode
local subscriber = redis.connect('127.0.0.1', 6379)
subscriber:subscribe("apex:telemetry")

while true do
    -- Accept new clients
    local client = server:accept()
    if client then
        client:settimeout(1)
        local request = client:receive()
        
        if request then
            -- Simple HTTP endpoint (not full WebSocket, but works for polling)
            if request:match("GET /telemetry") then
                -- Get latest telemetry from Redis
                local latest = redis_client:get("apex:latest")
                
                if not latest then
                    -- If no data yet, return empty
                    latest = cjson.encode({status = "waiting"})
                end
                
                local response = "HTTP/1.1 200 OK\r\n" ..
                               "Content-Type: application/json\r\n" ..
                               "Access-Control-Allow-Origin: *\r\n" ..
                               "Cache-Control: no-cache\r\n" ..
                               "Content-Length: " .. #latest .. "\r\n" ..
                               "\r\n" ..
                               latest
                
                client:send(response)
                frame_count = frame_count + 1
                
                -- Decode and show speed
                local ok, data = pcall(cjson.decode, latest)
                if ok and data.speed_kmh then
                    print(string.format("→ Client request #%d | Speed: %.1f km/h", 
                        frame_count, data.speed_kmh))
                end
            
            elseif request:match("GET /") then
                -- Serve simple test page
                local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>APEX Live Telemetry</title>
    <style>
        body { background: #0a0a0a; color: #00ff41; font-family: monospace; padding: 20px; }
        .metric { font-size: 48px; margin: 20px 0; }
        .label { font-size: 14px; opacity: 0.7; }
    </style>
</head>
<body>
    <h1>🏎️ APEX LIVE TELEMETRY</h1>
    <div class="metric" id="speed">--- km/h</div>
    <div class="label">SPEED</div>
    <div class="metric" id="slip">---</div>
    <div class="label">TIRE SLIP</div>
    <script>
        async function update() {
            const res = await fetch('/telemetry');
            const data = await res.json();
            if (data.speed_kmh) {
                document.getElementById('speed').textContent = data.speed_kmh.toFixed(1) + ' km/h';
                document.getElementById('slip').textContent = data.slip_front.toFixed(4);
            }
        }
        setInterval(update, 100);
        update();
    </script>
</body>
</html>
]]
                local response = "HTTP/1.1 200 OK\r\n" ..
                               "Content-Type: text/html\r\n" ..
                               "Content-Length: " .. #html .. "\r\n" ..
                               "\r\n" ..
                               html
                client:send(response)
            end
        end
        
        client:close()
    end
    
    -- Get latest from Redis and cache it
    local message = subscriber:get_message()
    if message and message.kind == "message" then
        redis_client:set("apex:latest", message.payload)
    end
    
    socket.sleep(0.01)  -- 100 Hz polling
end
