#!/usr/bin/env luajit
-- examples/run_pipeline.lua
-- MUST be run from project root: cd ~/project-apex && luajit examples/run_pipeline.lua

-- Add src/ to package path
package.path = "./src/?.lua;" .. package.path

local Pipeline = require("pipeline_simple")

local function main(args)
    local input = args[1] or "examples/data/sample_canbus.csv"
    local output = args[2] or "examples/data/decoded_output.csv"
    
    local config = {
        monitor_interval = 5,
    }
    
    local pipeline = Pipeline.new(input, output, config)
    
    local success, err = pcall(function()
        pipeline:process()
    end)
    
    if not success then
        print("❌ Pipeline failed: " .. tostring(err))
        os.exit(1)
    end
end

main(arg)
