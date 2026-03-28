#!/usr/bin/env python3
"""
Compare multiple drivers on the same lap with FastF1 + Pandas + Matplotlib
"""

import fastf1
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import cm
import numpy as np

fastf1.Cache.enable_cache('./fastf1_cache')

print("🏎️  MONACO 2024 DRIVER COMPARISON")
print("═" * 60)

# Load session
print("\n📡 Loading Monaco 2024 Qualifying...")
session = fastf1.get_session(2024, 'Monaco', 'Q')
session.load()
print("✅ Session loaded\n")

# Select drivers to compare
drivers = ['VER', 'LEC', 'HAM']  # Verstappen, Leclerc, Hamilton
colors = {'VER': '#1E41FF', 'LEC': '#DC0000', 'HAM': '#00D2BE'}
names = {'VER': 'Verstappen', 'LEC': 'Leclerc', 'HAM': 'Hamilton'}

# Get fastest laps for each driver
driver_data = {}

for driver in drivers:
    try:
        laps = session.laps.pick_driver(driver)
        fastest = laps.pick_fastest()
        
        # Get telemetry with distance
        tel = fastest.get_telemetry()
        tel = tel.add_distance()  # Add distance column
        
        driver_data[driver] = {
            'telemetry': tel,
            'lap_time': fastest['LapTime'],
            'fastest': fastest
        }
        
        print(f"✅ {names[driver]:12s} | Lap: {fastest['LapTime']} | Max: {tel['Speed'].max():.1f} km/h")
        
    except Exception as e:
        print(f"❌ {names[driver]:12s} | Data not available")
        drivers.remove(driver)

print(f"\n📊 Comparing {len(driver_data)} drivers\n")

# Create figure
fig = plt.figure(figsize=(16, 10))
fig.patch.set_facecolor('#0a0a0a')

# Title
fig.suptitle('MONACO 2024 QUALIFYING — DRIVER COMPARISON', 
             fontsize=20, color='white', weight='bold', y=0.98)

# ═══════════════════════════════════════════════════════════════
# PLOT 1: Speed vs Distance
# ═══════════════════════════════════════════════════════════════
ax1 = plt.subplot(3, 2, 1)
ax1.set_facecolor('#111111')

for driver in driver_data:
    tel = driver_data[driver]['telemetry']
    ax1.plot(tel['Distance'], tel['Speed'], 
             color=colors[driver], 
             linewidth=2, 
             label=names[driver])

ax1.set_xlabel('Distance (m)', color='white')
ax1.set_ylabel('Speed (km/h)', color='white')
ax1.set_title('Speed Trace', color='white', fontsize=14)
ax1.legend(facecolor='#111111', edgecolor='white', labelcolor='white')
ax1.grid(True, alpha=0.2)
ax1.tick_params(colors='white')

# ═══════════════════════════════════════════════════════════════
# PLOT 2: Throttle vs Distance
# ═══════════════════════════════════════════════════════════════
ax2 = plt.subplot(3, 2, 2)
ax2.set_facecolor('#111111')

for driver in driver_data:
    tel = driver_data[driver]['telemetry']
    ax2.plot(tel['Distance'], tel['Throttle'], 
             color=colors[driver], 
             linewidth=2, 
             label=names[driver],
             alpha=0.8)

ax2.set_xlabel('Distance (m)', color='white')
ax2.set_ylabel('Throttle (%)', color='white')
ax2.set_title('Throttle Application', color='white', fontsize=14)
ax2.legend(facecolor='#111111', edgecolor='white', labelcolor='white')
ax2.grid(True, alpha=0.2)
ax2.tick_params(colors='white')
ax2.set_ylim(0, 105)

# ═══════════════════════════════════════════════════════════════
# PLOT 3: Brake vs Distance
# ═══════════════════════════════════════════════════════════════
ax3 = plt.subplot(3, 2, 3)
ax3.set_facecolor('#111111')

for driver in driver_data:
    tel = driver_data[driver]['telemetry']
    # Brake is boolean, convert to 0/100
    brake = tel['Brake'].astype(int) * 100
    ax3.plot(tel['Distance'], brake, 
             color=colors[driver], 
             linewidth=2, 
             label=names[driver],
             alpha=0.8)

ax3.set_xlabel('Distance (m)', color='white')
ax3.set_ylabel('Brake (on/off)', color='white')
ax3.set_title('Braking Zones', color='white', fontsize=14)
ax3.legend(facecolor='#111111', edgecolor='white', labelcolor='white')
ax3.grid(True, alpha=0.2)
ax3.tick_params(colors='white')
ax3.set_ylim(-5, 105)

# ═══════════════════════════════════════════════════════════════
# PLOT 4: Speed Delta (vs fastest driver)
# ═══════════════════════════════════════════════════════════════
ax4 = plt.subplot(3, 2, 4)
ax4.set_facecolor('#111111')

# Find fastest lap
fastest_driver = min(driver_data.keys(), 
                     key=lambda d: driver_data[d]['lap_time'])

reference_tel = driver_data[fastest_driver]['telemetry']

for driver in driver_data:
    if driver == fastest_driver:
        continue
    
    tel = driver_data[driver]['telemetry']
    
    # Interpolate to match distances
    common_dist = np.linspace(0, 
                              min(tel['Distance'].max(), reference_tel['Distance'].max()),
                              500)
    
    ref_speed = np.interp(common_dist, reference_tel['Distance'], reference_tel['Speed'])
    drv_speed = np.interp(common_dist, tel['Distance'], tel['Speed'])
    
    delta = drv_speed - ref_speed
    
    ax4.fill_between(common_dist, 0, delta,
                     where=(delta >= 0),
                     color='green',
                     alpha=0.3,
                     label=f"{names[driver]} faster")
    ax4.fill_between(common_dist, 0, delta,
                     where=(delta < 0),
                     color='red',
                     alpha=0.3,
                     label=f"{names[driver]} slower")
    ax4.plot(common_dist, delta, 
             color=colors[driver], 
             linewidth=2,
             label=names[driver])

ax4.set_xlabel('Distance (m)', color='white')
ax4.set_ylabel('Speed Delta (km/h)', color='white')
ax4.set_title(f'Speed vs {names[fastest_driver]} (Reference)', color='white', fontsize=14)
ax4.axhline(y=0, color='white', linestyle='--', linewidth=1, alpha=0.5)
ax4.legend(facecolor='#111111', edgecolor='white', labelcolor='white')
ax4.grid(True, alpha=0.2)
ax4.tick_params(colors='white')

# ═══════════════════════════════════════════════════════════════
# PLOT 5: RPM Comparison
# ═══════════════════════════════════════════════════════════════
ax5 = plt.subplot(3, 2, 5)
ax5.set_facecolor('#111111')

for driver in driver_data:
    tel = driver_data[driver]['telemetry']
    ax5.plot(tel['Distance'], tel['RPM'], 
             color=colors[driver], 
             linewidth=2, 
             label=names[driver],
             alpha=0.7)

ax5.set_xlabel('Distance (m)', color='white')
ax5.set_ylabel('RPM', color='white')
ax5.set_title('Engine RPM', color='white', fontsize=14)
ax5.legend(facecolor='#111111', edgecolor='white', labelcolor='white')
ax5.grid(True, alpha=0.2)
ax5.tick_params(colors='white')

# ═══════════════════════════════════════════════════════════════
# PLOT 6: Lap Time Comparison (Bar chart)
# ═══════════════════════════════════════════════════════════════
ax6 = plt.subplot(3, 2, 6)
ax6.set_facecolor('#111111')

lap_times = [driver_data[d]['lap_time'].total_seconds() for d in driver_data]
driver_names = [names[d] for d in driver_data]
driver_colors = [colors[d] for d in driver_data]

bars = ax6.barh(driver_names, lap_times, color=driver_colors)

# Add time labels
for i, (bar, time) in enumerate(zip(bars, lap_times)):
    mins = int(time // 60)
    secs = time % 60
    ax6.text(time + 0.05, i, f"{mins}:{secs:05.2f}", 
             va='center', color='white', fontsize=12)

ax6.set_xlabel('Lap Time (seconds)', color='white')
ax6.set_title('Lap Time Comparison', color='white', fontsize=14)
ax6.tick_params(colors='white')
ax6.invert_yaxis()
ax6.grid(True, alpha=0.2, axis='x')

# ═══════════════════════════════════════════════════════════════
# Footer
# ═══════════════════════════════════════════════════════════════
footer = f"APEX Telemetry Stack | FastF1 Data Analysis | github.com/Chikimonki/project-apex"
plt.figtext(0.5, 0.01, footer, ha='center', fontsize=10, color='gray')

plt.tight_layout(rect=[0, 0.02, 1, 0.96])

# Save
output_file = 'monaco_2024_comparison.png'
plt.savefig(output_file, dpi=200, facecolor='#0a0a0a')
print(f"✅ Saved: {output_file}")

plt.show()

print("\n🏁 Comparison complete!")
