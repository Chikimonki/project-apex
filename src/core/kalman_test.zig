const std = @import("std");
const kalman = @import("kalman_filter.zig");

pub fn main() void {
    std.debug.print("\n🏎️  Kalman Filter Test\n", .{});
    
    var kf: kalman.KalmanFilter = undefined;
    kalman.kalman_init(&kf, 0.002);
    std.debug.print("✅ Initialized at 500 Hz\n\n", .{});
    
    var state: kalman.State = undefined;
    var i: usize = 0;
    
    while (i < 500) : (i += 1) {
        const speed: f32 = @as(f32, @floatFromInt(i)) * 0.04;
        const z = kalman.Measurement{
            .wheel_speed_fl = speed + 0.1,
            .wheel_speed_fr = speed + 0.15,
            .wheel_speed_rl = speed - 0.05,
            .wheel_speed_rr = speed,
            .steering_angle = 0.0,
            .brake_pressure = 0.0,
        };
        kalman.kalman_predict(&kf);
        kalman.kalman_update(&kf, &z);
        if (i % 100 == 0) {
            kalman.kalman_get_state(&kf, &state);
            std.debug.print("t={d:.2}s: {d:.1} km/h\n", .{
                @as(f32, @floatFromInt(i)) * 0.002,
                state.vx * 3.6,
            });
        }
    }
    
    kalman.kalman_get_state(&kf, &state);
    std.debug.print("\n✅ Final: {d:.1} km/h\n", .{state.vx * 3.6});
}
