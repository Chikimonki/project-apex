#!/usr/bin/env julia

# Add project path
push!(LOAD_PATH, @__DIR__)

using TelemetryAnalysis
using DataFrames
using CSV

function main()
    println("🏎️  Project APEX - Julia Telemetry Analysis")
    println("═" ^ 70)
    println()
    
    # Check if CSV file provided
    if length(ARGS) < 1
        csv_file = "../examples/data/decoded_output.csv"
        println("ℹ️  No file specified, using default: $csv_file")
    else
        csv_file = ARGS[1]
    end
    
    if !isfile(csv_file)
        println("❌ File not found: $csv_file")
        exit(1)
    end
    
    # Load and analyze
    df = analyze_lap(csv_file)
    stats = lap_statistics(df)
    
    # Find braking zones
    zones = find_braking_zones(df, 50.0)
    
    # Generate plots
    println("\n📊 Generating visualizations...")
    plot_speed_trace(df, "julia/speed_trace.png")
    
    # Save statistics to JSON
    using JSON
    open("julia/lap_stats.json", "w") do f
        JSON.print(f, stats, 2)
    end
    
    println("\n✅ Analysis complete!")
    println("   Speed trace: julia/speed_trace.png")
    println("   Statistics:  julia/lap_stats.json")
end

main()
