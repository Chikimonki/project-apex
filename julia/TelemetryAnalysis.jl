# TelemetryAnalysis.jl
# F1 Telemetry Statistical Analysis

module TelemetryAnalysis

using DataFrames
using CSV
using Statistics
using Plots

export analyze_lap, compare_laps, plot_speed_trace, lap_statistics

"""
    analyze_lap(csv_path::String) -> DataFrame
    
Load and analyze a single lap from CSV file.
"""
function analyze_lap(csv_path::String)
    df = CSV.read(csv_path, DataFrame)
    
    println("📊 Lap Analysis")
    println("═" ^ 60)
    println("File: ", basename(csv_path))
    println("Total frames: ", nrow(df))
    
    return df
end

"""
    lap_statistics(df::DataFrame) -> Dict
    
Calculate comprehensive lap statistics.
"""
function lap_statistics(df::DataFrame)
    stats = Dict(
        "max_speed_kph" => maximum(df.speed_kph),
        "max_speed_mph" => maximum(df.speed_kph) * 0.621371,
        "avg_speed_kph" => mean(df.speed_kph),
        "max_rpm" => maximum(df.rpm),
        "avg_rpm" => mean(df.rpm),
        "max_throttle" => maximum(df.throttle_pct),
        "max_brake" => maximum(df.brake_pct),
        "lap_time" => maximum(df.timestamp),
        "total_distance_km" => sum(df.speed_kph ./ 3600 .* 0.05),  # 50ms intervals
    )
    
    # Print summary
    println("\n📈 Lap Statistics:")
    println("─" ^ 60)
    println("Lap Time:        $(round(stats["lap_time"], digits=2))s")
    println("Max Speed:       $(round(stats["max_speed_kph"], digits=1)) km/h ($(round(stats["max_speed_mph"], digits=1)) mph)")
    println("Avg Speed:       $(round(stats["avg_speed_kph"], digits=1)) km/h")
    println("Max RPM:         $(round(Int, stats["max_rpm"]))")
    println("Total Distance:  $(round(stats["total_distance_km"], digits=2)) km")
    
    return stats
end

"""
    plot_speed_trace(df::DataFrame, output_file::String="speed_trace.png")
    
Plot speed trace over time.
"""
function plot_speed_trace(df::DataFrame, output_file::String="speed_trace.png")
    p = plot(
        df.timestamp,
        df.speed_kph,
        label="Speed",
        xlabel="Time (s)",
        ylabel="Speed (km/h)",
        title="Lap Speed Trace",
        linewidth=2,
        color=:red,
        legend=:topright,
        size=(1200, 600)
    )
    
    # Add gear changes as vertical lines
    gear_changes = findall(diff(df.gear) .!= 0)
    for idx in gear_changes
        vline!([df.timestamp[idx]], label="", color=:gray, alpha=0.3, linestyle=:dash)
    end
    
    savefig(p, output_file)
    println("\n💾 Saved plot: $output_file")
    
    return p
end

"""
    compare_laps(csv_paths::Vector{String}) -> DataFrame
    
Compare multiple laps and return comparison table.
"""
function compare_laps(csv_paths::Vector{String})
    println("\n🏁 Comparing $(length(csv_paths)) Laps")
    println("═" ^ 60)
    
    results = DataFrame(
        Lap = String[],
        LapTime = Float64[],
        MaxSpeed = Float64[],
        AvgSpeed = Float64[],
        MaxRPM = Float64[]
    )
    
    for (i, path) in enumerate(csv_paths)
        df = CSV.read(path, DataFrame)
        stats = lap_statistics(df)
        
        push!(results, (
            "Lap $i",
            stats["lap_time"],
            stats["max_speed_kph"],
            stats["avg_speed_kph"],
            stats["max_rpm"]
        ))
    end
    
    println("\n📋 Comparison Table:")
    println(results)
    
    return results
end

"""
    find_braking_zones(df::DataFrame, threshold::Float64=50.0) -> Vector
    
Identify major braking zones (brake pressure > threshold).
"""
function find_braking_zones(df::DataFrame, threshold::Float64=50.0)
    braking = df.brake_pct .> threshold
    zones = []
    
    in_zone = false
    zone_start = 0
    
    for i in 1:nrow(df)
        if braking[i] && !in_zone
            zone_start = i
            in_zone = true
        elseif !braking[i] && in_zone
            push!(zones, (
                start_time = df.timestamp[zone_start],
                end_time = df.timestamp[i-1],
                entry_speed = df.speed_kph[zone_start],
                exit_speed = df.speed_kph[i-1],
                max_brake = maximum(df.brake_pct[zone_start:i-1])
            ))
            in_zone = false
        end
    end
    
    println("\n🔴 Braking Zones Found: $(length(zones))")
    for (i, zone) in enumerate(zones)
        println("  Zone $i: $(round(zone.start_time, digits=1))s | ",
                "$(round(zone.entry_speed, digits=0)) → $(round(zone.exit_speed, digits=0)) km/h | ",
                "Max brake: $(round(zone.max_brake, digits=0)) bar")
    end
    
    return zones
end

end  # module
