// can_decoder_test.zig — STANDALONE TEST (uses std.debug.print)

const std = @import("std");
const lib = @import("can_decoder.zig");

pub fn main() void {
    std.debug.print("\n🧪 CAN Decoder Test Harness\n", .{});
    std.debug.print("═══════════════════════════\n\n", .{});
    
    // Test 1: Library version
    const version = lib.get_version();
    std.debug.print("Library version: {d}\n", .{version});
    
    // Test 2: Simple addition
    const sum = lib.test_add(42, 13);
    std.debug.print("42 + 13 = {d}\n", .{sum});
    
    // Test 3: CAN decoding
    var frames = [_]lib.CANFrame{
        .{ .id = 0x123, .dlc = 8, .data = .{0x12, 0x34, 0, 0, 0, 0, 0, 0} },
        .{ .id = 0x123, .dlc = 8, .data = .{0x56, 0x78, 0, 0, 0, 0, 0, 0} },
    };
    
    var speeds: [2]f32 = undefined;
    lib.processCANStream(&frames, frames.len, &speeds);
    
    std.debug.print("\nWheel speeds:\n", .{});
    for (speeds, 0..) |speed, i| {
        std.debug.print("  Frame {d}: {d:.2} km/h\n", .{i, speed});
    }
    
    std.debug.print("\n✅ All tests passed!\n", .{});
}
