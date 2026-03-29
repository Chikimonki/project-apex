// can_decoder.zig — ACTUAL SIMD IMPLEMENTATION

const std = @import("std");

pub const CANFrame = extern struct {
    id: u32,
    dlc: u8,
    data: [8]u8,
};

pub fn decodeWheelSpeed(frame: CANFrame) f32 {
    if (frame.id == 0x123) {
        const raw = (@as(u16, frame.data[0]) << 8) | frame.data[1];
        return @as(f32, @floatFromInt(raw)) * 0.01;
    }
    return 0.0;
}

pub export fn decode_can_frame(input: [*]u8, input_len: usize, output: [*]u8, output_len: usize) usize {
    frames: [*]const CANFrame,
    count: usize,
    wheel_speeds: [*]f32,
) void {
    if (count == 0) return;
    
    var i: usize = 0;
    while (i < count) : (i += 1) {
        wheel_speeds[i] = decodeWheelSpeed(frames[i]);
    }
}

// TRUE SIMD: Vectorize the actual computation
pub export fn processCANStreamSIMD(
    frames: [*]const CANFrame,
    count: usize,
    wheel_speeds: [*]f32,
) void {
    if (count == 0) return;
    
    const Vec4u16 = @Vector(4, u16);
    const Vec4f32 = @Vector(4, f32);
    const scale: Vec4f32 = @splat(0.01);
    
    var i: usize = 0;
    
    // Process 4 frames at a time with TRUE vectorization
    while (i + 4 <= count) : (i += 4) {
        // Check all 4 frames have the right ID (branch once for 4 frames)
        const all_match = 
            frames[i+0].id == 0x123 and
            frames[i+1].id == 0x123 and
            frames[i+2].id == 0x123 and
            frames[i+3].id == 0x123;
        
        if (all_match) {
            // VECTORIZED: Extract 4 u16 values at once
            var raw_values: Vec4u16 = undefined;
            inline for (0..4) |j| {
                const byte0 = @as(u16, frames[i + j].data[0]);
                const byte1 = @as(u16, frames[i + j].data[1]);
                raw_values[j] = (byte0 << 8) | byte1;
            }
            
            // VECTORIZED: Convert to f32 and scale (SIMD mul)
            const raw_f32: Vec4f32 = @floatFromInt(raw_values);
            const speeds = raw_f32 * scale;
            
            // VECTORIZED STORE: Write all 4 at once
            @memcpy(wheel_speeds[i..i+4], @as([4]f32, speeds)[0..4]);
        } else {
            // Fallback to scalar for mismatched IDs
            inline for (0..4) |j| {
                wheel_speeds[i + j] = decodeWheelSpeed(frames[i + j]);
            }
        }
    }
    
    // Handle remainder with scalar
    while (i < count) : (i += 1) {
        wheel_speeds[i] = decodeWheelSpeed(frames[i]);
    }
}

pub export fn test_add(a: i32, b: i32) i32 {
    return a + b;
}

pub export fn get_version() u32 {
    return 101;  // Bump version for true SIMD
}
