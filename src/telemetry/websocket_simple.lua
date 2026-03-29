#!/usr/bin/env luajit
-- websocket_simple.lua — Simple HTTP telemetry server

local socket = require("socket")
local io = require("io")

print("╔════════════════════════════════════════════════╗")
print("║  APEX SIMPLE TELEMETRY SERVER                  ║")
print("╚════════════════════════════════════════════════╝")
print()

-- Create server
local server = socket.tcp()
local ok, err = server:bind("*", 8082)

if not ok then
    print("❌ Failed to bind port 8082: " .. tostring(err))
    print("   Port might be in use. Try: sudo lsof -i :8082")
    os.exit(1)
end

server:listen(10)
server:settimeout(0.1)

print("✅ Server listening on http://localhost:8082")
print("   Access from browser: http://localhost:8082")
print()
print("🚀 Waiting for connections...")
print()

local request_count = 0

-- Get latest telemetry from Redis using CLI
local function get_latest_telemetry()
    local handle = io.popen("redis-cli GET apex:latest 2>/dev/null")
    local result = handle:read("*a")
    handle:close()
    
    if result and #result > 2 then
        return result
    else
        return '{"status":"waiting","speed_kmh":0,"slip_front":0}'
    end
end

while true do
    local client = server:accept()
    
    if client then
        client:settimeout(1)
        local request = client:receive()
        
        if request then
            request_count = request_count + 1
            
            if request:match("GET /telemetry") then
                -- Serve telemetry JSON
                local data = get_latest_telemetry()
                
                local response = "HTTP/1.1 200 OK\r\n" ..
                               "Content-Type: application/json\r\n" ..
                               "Access-Control-Allow-Origin: *\r\n" ..
                               "Cache-Control: no-cache\r\n" ..
                               "Content-Length: " .. #data .. "\r\n" ..
                               "\r\n" ..
                               data
                
                client:send(response)
                
                -- Extract speed for display
                local speed = data:match('"speed_kmh":([0-9.]+)')
                if speed then
                    print(string.format("→ Request #%d | Speed: %s km/h", 
                        request_count, speed))
                end
            
            elseif request:match("GET /") or request:match("GET / HTTP") then
                -- Serve HTML page
                local html = [[
<!DOCTYPE html>
<html>
<head>
    <title>APEX Live Telemetry</title>
    <style>
        body { 
            background: #0a0a0a; 
            color: #00ff41; 
            font-family: 'Courier New', monospace; 
            padding: 40px;
            text-align: center;
        }
        h1 { font-size: 32px; border-bottom: 2px solid #00ff41; padding-bottom: 10px; }
        .metric { font-size: 64px; margin: 30px 0; font-weight: bold; }
        .label { font-size: 16px; opacity: 0.7; margin-bottom: 40px; }
        .status { font-size: 12px; opacity: 0.5; margin-top: 50px; }
    </style>
</head>
<body>
    <h1>🏎️ APEX LIVE TELEMETRY</h1>
    
    <div class="metric" id="speed">---.--</div>
    <div class="label">SPEED (km/h)</div>
    
    <div class="metric" id="slip">----</div>
    <div class="label">TIRE SLIP (FRONT)</div>
    
    <div class="status" id="status">Connecting...</div>
    
    <script>
        let updateCount = 0;
        
        async function update() {
            try {
                const res = await fetch('/telemetry');
                const data = await res.json();
                
                if (data.speed_kmh !== undefined) {
                    document.getElementById('speed').textContent = data.speed_kmh.toFixed(1);
                    document.getElementById('slip').textContent = data.slip_front.toFixed(4);
                    updateCount++;
                    document.getElementById('status').textContent = 
                        `Live • Updates: ${updateCount} • Lap time: ${data.lap_time.toFixed(1)}s`;
                } else {
                    document.getElementById('status').textContent = 'Waiting for data...';
                }
            } catch (e) {
                document.getElementById('status').textContent = 'Connection error: ' + e;
            }
        }
        
        setInterval(update, 200);  // 5 Hz refresh
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
                print(string.format("→ Served HTML page (request #%d)", request_count))
            end
        end
        
        client:close()
    end
    
    socket.sleep(0.01)
end
