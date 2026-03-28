#!/usr/bin/env python3
"""
Fetch real F1 telemetry and convert to APEX format
"""

import fastf1
import numpy as np
import struct

# Enable cache to speed up subsequent runs
fastf1.Cache.enable_cache('/tmp/fastf1_cache')

print("🏎️  FastF1 → APEX Telemetry Converter")
print("═" * 50)

# Load 2024 Monaco GP, Max Verstappen's fastest lap
print("\n📡 Loading 2024 Monaco GP Qualifying...")
session = fastf1.get_session(2024, 'Monaco', 'Q')
session.load()

print("✅ Session loaded")

# Get fastest lap
laps = session.laps.pick_driver('VER')
fastest_lap = laps.pick_fastest()

print(f"\n🏁 Fastest lap: {fastest_lap['LapTime']}")
print(f"   Driver: {fastest_lap['Driver']}")
print(f"   Speed: {fastest_lap['SpeedST']} km/h")

# Get telemetry
telemetry = fastest_lap.get_telemetry()

print(f"\n📊 Telemetry data:")
print(f"   Samples: {len(telemetry)}")
print(f"   Frequency: ~{len(telemetry) / fastest_lap['LapTime'].total_seconds():.0f} Hz")

# Extract data
time = telemetry['Time'].dt.total_seconds().values
speed = telemetry['Speed'].values  # km/h
throttle = telemetry['Throttle'].values  # 0-100
brake = telemetry['Brake'].values  # boolean
rpm = telemetry['RPM'].values
gear = telemetry['nGear'].values

print(f"\n📈 Data ranges:")
print(f"   Speed: {np.min(speed):.1f} - {np.max(speed):.1f} km/h")
print(f"   Throttle: {np.min(throttle):.1f} - {np.max(throttle):.1f} %")
print(f"   RPM: {np.min(rpm):.0f} - {np.max(rpm):.0f}")

# Convert to APEX CAN format (simulated wheel speeds)
# F1 cars have ~660mm diameter tires, so:
# wheel_speed (m/s) = vehicle_speed (km/h) / 3.6

can_frames = []
for i in range(len(telemetry)):
    # Convert speed to m/s
    speed_ms = speed[i] / 3.6
    
    # Simulate wheel speeds (add small variations for realism)
    fl = speed_ms + np.random.normal(0, 0.1)
    fr = speed_ms + np.random.normal(0, 0.1)
    rl = speed_ms + np.random.normal(0, 0.1)
    rr = speed_ms + np.random.normal(0, 0.1)
    
    # Pack as CAN frame (simplified: just wheel speeds)
    frame = {
        'time': time[i],
        'wheel_speed_fl': fl,
        'wheel_speed_fr': fr,
        'wheel_speed_rl': rl,
        'wheel_speed_rr': rr,
        'throttle': throttle[i] / 100.0,  # Normalize to 0-1
        'brake': float(brake[i]),
        'speed_kmh': speed[i],
    }
    can_frames.append(frame)

# Save to binary format for Zig/LuaJIT processing
print(f"\n💾 Saving {len(can_frames)} frames to binary...")

with open('monaco_2024_verstappen.bin', 'wb') as f:
    # Header: number of frames
    f.write(struct.pack('I', len(can_frames)))
    
    # Data: each frame as 7 floats (time, 4 wheels, throttle, brake)
    for frame in can_frames:
        f.write(struct.pack('f', frame['time']))
        f.write(struct.pack('f', frame['wheel_speed_fl']))
        f.write(struct.pack('f', frame['wheel_speed_fr']))
        f.write(struct.pack('f', frame['wheel_speed_rl']))
        f.write(struct.pack('f', frame['wheel_speed_rr']))
        f.write(struct.pack('f', frame['throttle']))
        f.write(struct.pack('f', frame['brake']))

# Also save as CSV for inspection
import csv
with open('monaco_2024_verstappen.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=can_frames[0].keys())
    writer.writeheader()
    writer.writerows(can_frames)

print(f"✅ Saved to:")
print(f"   monaco_2024_verstappen.bin (binary)")
print(f"   monaco_2024_verstappen.csv (human-readable)")

# Summary stats
total_time = time[-1] - time[0]
avg_speed = np.mean(speed)
max_speed = np.max(speed)

print(f"\n📊 Lap summary:")
print(f"   Duration: {total_time:.2f} seconds")
print(f"   Avg speed: {avg_speed:.1f} km/h")
print(f"   Max speed: {max_speed:.1f} km/h")
print(f"   Data rate: {len(can_frames) / total_time:.0f} Hz")

print("\n✅ Ready for APEX processing!")
