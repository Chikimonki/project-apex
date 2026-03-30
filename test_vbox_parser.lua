#!/usr/bin/env luajit

package.path = "./src/?.lua;" .. package.path

local vbox = require("vbox_csv_parser")

-- Load decompressed CSV
local file = io.open("examples/data/Ferrari-488 Challenge (X710 Connector) 2020-_full.txt", "r")
local csv_text = file:read("*all")
file:close()

print("🏎️  Ferrari 488 Challenge CAN Database\n")
print(string.rep("=", 80))

local signals = vbox.parse_vbox_csv(csv_text)

print("\n📊 Key Signals for Visualization:")
print(string.rep("-", 80))

for _, key in ipairs({"Engine_Speed", "Indicated_Vehicle_Speed_kph", "Accelerator_Pedal_Position", 
                      "Brake_Pressure", "Gear", "Steering_Angle"}) do
    if signals[key] then
        local s = signals[key]
        print(string.format("%-35s | CAN ID: 0x%03X | Unit: %s", key, s.can_id, s.unit))
    end
end

-- Test decoding
print("\n🧪 Test Decode (simulated data):")
local test_data = {0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0}
local decoded = vbox.decode_message(signals, 512, test_data)

for name, value in pairs(decoded) do
    print(string.format("  %s = %.2f", name, value))
end
