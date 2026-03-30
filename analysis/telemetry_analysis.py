#!/usr/bin/env python3
"""
🏎️ Project APEX - Telemetry Analysis
Python-based statistical analysis of F1 lap data
"""

import pandas as pd
import matplotlib.pyplot as plt
import json
import sys
from pathlib import Path

def load_lap_data(csv_path: str) -> pd.DataFrame:
    """Load telemetry data from CSV."""
    print(f"📂 Loading: {csv_path}")
    df = pd.read_csv(csv_path)
    print(f"   Loaded {len(df)} frames")
    return df

def lap_statistics(df: pd.DataFrame) -> dict:
    """Calculate comprehensive lap statistics."""
    
    stats = {
        "lap_time_s": float(df['timestamp'].max()),
        "max_speed_kph": float(df['speed_kph'].max()),
        "max_speed_mph": float(df['speed_kph'].max() * 0.621371),
        "avg_speed_kph": float(df['speed_kph'].mean()),
        "max_rpm": float(df['rpm'].max()),
        "avg_rpm": float(df['rpm'].mean()),
        "max_throttle_pct": float(df['throttle_pct'].max()),
        "max_brake_pct": float(df['brake_pct'].max()),
        "gear_changes": int((df['gear'].diff() != 0).sum()),
    }
    
    # Print summary
    print("\n📊 LAP STATISTICS")
    print("═" * 60)
    print(f"  Lap Time:        {stats['lap_time_s']:.2f}s")
    print(f"  Max Speed:       {stats['max_speed_kph']:.1f} km/h ({stats['max_speed_mph']:.1f} mph)")
    print(f"  Avg Speed:       {stats['avg_speed_kph']:.1f} km/h")
    print(f"  Max RPM:         {stats['max_rpm']:.0f}")
    print(f"  Avg RPM:         {stats['avg_rpm']:.0f}")
    print(f"  Max Throttle:    {stats['max_throttle_pct']:.1f}%")
    print(f"  Max Brake:       {stats['max_brake_pct']:.1f} bar")
    print(f"  Gear Changes:    {stats['gear_changes']}")
    print("═" * 60)
    
    return stats

def find_braking_zones(df: pd.DataFrame, threshold: float = 30.0) -> list:
    """Identify major braking zones."""
    
    braking = df['brake_pct'] > threshold
    zones = []
    
    in_zone = False
    zone_start = 0
    
    for i in range(len(df)):
        if braking.iloc[i] and not in_zone:
            zone_start = i
            in_zone = True
        elif not braking.iloc[i] and in_zone:
            zones.append({
                'start_time': float(df['timestamp'].iloc[zone_start]),
                'end_time': float(df['timestamp'].iloc[i-1]),
                'entry_speed': float(df['speed_kph'].iloc[zone_start]),
                'exit_speed': float(df['speed_kph'].iloc[i-1]),
                'max_brake': float(df['brake_pct'].iloc[zone_start:i].max()),
                'speed_lost': float(df['speed_kph'].iloc[zone_start] - df['speed_kph'].iloc[i-1])
            })
            in_zone = False
    
    print(f"\n🔴 BRAKING ZONES (threshold: {threshold} bar)")
    print("─" * 60)
    for i, zone in enumerate(zones, 1):
        print(f"  Zone {i}: {zone['start_time']:.1f}s | "
              f"{zone['entry_speed']:.0f} → {zone['exit_speed']:.0f} km/h | "
              f"Lost: {zone['speed_lost']:.0f} km/h | "
              f"Max brake: {zone['max_brake']:.0f} bar")
    
    return zones

def plot_speed_trace(df: pd.DataFrame, output_file: str = "analysis/speed_trace.png"):
    """Generate speed trace plot."""
    
    fig, axes = plt.subplots(4, 1, figsize=(14, 10), sharex=True)
    fig.suptitle('🏎️ Project APEX - Lap Telemetry Analysis', fontsize=14, fontweight='bold')
    
    # Speed
    axes[0].plot(df['timestamp'], df['speed_kph'], color='red', linewidth=1.5)
    axes[0].fill_between(df['timestamp'], df['speed_kph'], alpha=0.3, color='red')
    axes[0].set_ylabel('Speed (km/h)')
    axes[0].set_ylim(0, 400)
    axes[0].grid(True, alpha=0.3)
    axes[0].legend(['Speed'], loc='upper right')
    
    # RPM
    axes[1].plot(df['timestamp'], df['rpm'], color='green', linewidth=1.5)
    axes[1].fill_between(df['timestamp'], df['rpm'], alpha=0.3, color='green')
    axes[1].set_ylabel('RPM')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend(['RPM'], loc='upper right')
    
    # Throttle & Brake
    axes[2].plot(df['timestamp'], df['throttle_pct'], color='blue', linewidth=1.5, label='Throttle')
    axes[2].plot(df['timestamp'], df['brake_pct'], color='orange', linewidth=1.5, label='Brake')
    axes[2].set_ylabel('Pedals (%/bar)')
    axes[2].set_ylim(0, 110)
    axes[2].grid(True, alpha=0.3)
    axes[2].legend(loc='upper right')
    
    # Gear
    axes[3].step(df['timestamp'], df['gear'], color='purple', linewidth=2, where='post')
    axes[3].set_ylabel('Gear')
    axes[3].set_xlabel('Time (s)')
    axes[3].set_ylim(0, 8)
    axes[3].grid(True, alpha=0.3)
    axes[3].legend(['Gear'], loc='upper right')
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    print(f"\n📈 Saved plot: {output_file}")
    
    return fig

def generate_html_report(df: pd.DataFrame, stats: dict, zones: list, output_file: str = "analysis/report.html"):
    """Generate HTML report."""
    
    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>🏎️ Project APEX - Lap Analysis</title>
    <style>
        body {{ font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #e0e0e0; padding: 2rem; }}
        .header {{ text-align: center; margin-bottom: 2rem; }}
        .header h1 {{ color: #e94560; }}
        .stats-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; }}
        .stat-card {{ background: #16213e; padding: 1.5rem; border-radius: 8px; text-align: center; }}
        .stat-value {{ font-size: 2rem; color: #e94560; font-weight: bold; }}
        .stat-label {{ color: #888; margin-top: 0.5rem; }}
        .section {{ background: #16213e; padding: 1.5rem; border-radius: 8px; margin: 2rem 0; }}
        .section h2 {{ color: #e94560; margin-top: 0; }}
        table {{ width: 100%; border-collapse: collapse; }}
        th, td {{ padding: 0.8rem; text-align: left; border-bottom: 1px solid #333; }}
        th {{ color: #e94560; }}
        img {{ max-width: 100%; border-radius: 8px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🏎️ Project APEX</h1>
        <p>Lap Telemetry Analysis Report</p>
    </div>
    
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-value">{stats['lap_time_s']:.2f}s</div>
            <div class="stat-label">Lap Time</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{stats['max_speed_kph']:.0f}</div>
            <div class="stat-label">Max Speed (km/h)</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{stats['max_rpm']:.0f}</div>
            <div class="stat-label">Max RPM</div>
        </div>
        <div class="stat-card">
            <div class="stat-value">{stats['gear_changes']}</div>
            <div class="stat-label">Gear Changes</div>
        </div>
    </div>
    
    <div class="section">
        <h2>📈 Speed Trace</h2>
        <img src="speed_trace.png" alt="Speed Trace">
    </div>
    
    <div class="section">
        <h2>🔴 Braking Zones</h2>
        <table>
            <tr><th>Zone</th><th>Time</th><th>Entry</th><th>Exit</th><th>Speed Lost</th><th>Max Brake</th></tr>
            {''.join(f"<tr><td>{i+1}</td><td>{z['start_time']:.1f}s</td><td>{z['entry_speed']:.0f} km/h</td><td>{z['exit_speed']:.0f} km/h</td><td>{z['speed_lost']:.0f} km/h</td><td>{z['max_brake']:.0f} bar</td></tr>" for i, z in enumerate(zones))}
        </table>
    </div>
</body>
</html>
"""
    
    with open(output_file, 'w') as f:
        f.write(html)
    
    print(f"📄 Saved report: {output_file}")

def main():
    print("🏎️  Project APEX - Telemetry Analysis")
    print("═" * 60)
    
    # Get CSV file
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
    else:
        csv_file = "examples/data/decoded_output.csv"
        print(f"ℹ️  No file specified, using: {csv_file}")
    
    if not Path(csv_file).exists():
        print(f"❌ File not found: {csv_file}")
        sys.exit(1)
    
    # Load data
    df = load_lap_data(csv_file)
    
    # Calculate statistics
    stats = lap_statistics(df)
    
    # Find braking zones
    zones = find_braking_zones(df)
    
    # Generate plots
    print("\n📊 Generating visualizations...")
    plot_speed_trace(df)
    
    # Save stats to JSON
    with open("analysis/lap_stats.json", 'w') as f:
        json.dump(stats, f, indent=2)
    print("💾 Saved stats: analysis/lap_stats.json")
    
    # Generate HTML report
    generate_html_report(df, stats, zones)
    
    print("\n✅ Analysis complete!")
    print("   📈 Plot: analysis/speed_trace.png")
    print("   📄 Report: analysis/report.html")
    print("   💾 Stats: analysis/lap_stats.json")

if __name__ == "__main__":
    main()
