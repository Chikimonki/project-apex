# ⚡ Formula Student APEX — Quickstart

## What This Is

500Hz real-time telemetry processing that runs on a Raspberry Pi.

**Proof:** [YouTube Demo](https://youtu.be/vf_isDZKpHU)

## Installation (30 seconds)

```bash
git clone https://github.com/Chikimonki/formula-student-apex
cd formula-student-apex
./build.sh
./run_demo.sh
```

## What You Get

- **CAN bus decoder** (Zig) — 1M frames/sec
- **Tire dynamics Kalman filter** (Zig + Julia) — 500 Hz
- **Real-time dashboard** (HTML/CSS + WebSockets)
- **Log file parser** (Perl) — handles MoTeC, AiM, custom formats

## Hardware Requirements

- Raspberry Pi 4 (2GB+) — **$35**
- MCP2515 CAN module — **$8**
- SD card — **$10**

**Total: $53**

## Comparison

| Feature | MoTeC M1 | **APEX** |
|---------|----------|----------|
| Cost | $15,000 | **$53** |
| Update rate | 100 Hz | **500 Hz** |
| Source code | ❌ Closed | **✅ Open** |
| Custom algorithms | $$$ consulting | **Free, modify yourself** |

## I'm A Formula Student Team — What Now?

Email me: [your email]

I'll send you a working demo with your car's CAN IDs in 24 hours.

Zero cost. No obligations. I just want real-world validation.

## License

MIT — Freely received, freely given.
