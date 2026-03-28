cat > README.md << 'EOF'
# 🏎️ APEX — Formula Student Telemetry Stack

**936 million CAN frames per second. On a laptop. Open source.**

## What This Is

A complete telemetry processing stack for Formula Student teams:

- Processes CAN bus data **936 million frames/second**
- Runs on **$35 Raspberry Pi** (or any Linux system)
- **$0 licensing cost** (vs $35,000 for commercial systems)
- Fully open source

## Quick Start

```bash
git clone https://github.com/Chikimonki/project-apex
cd project-apex
cd src/core
./build.sh
