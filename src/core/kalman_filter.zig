const std = @import("std");

pub const State = extern struct {
    vx: f32,
    vy: f32,
    yaw_rate: f32,
    slip_front: f32,
    slip_rear: f32,
    friction: f32,
};

pub const Measurement = extern struct {
    wheel_speed_fl: f32,
    wheel_speed_fr: f32,
    wheel_speed_rl: f32,
    wheel_speed_rr: f32,
    steering_angle: f32,
    brake_pressure: f32,
};

pub const KalmanFilter = extern struct {
    state: State,
    P: [36]f32,
    Q: [36]f32,
    dt: f32,
    wheelbase: f32,
    track_width: f32,
};

pub export fn kalman_init(kf: *KalmanFilter, dt: f32) void {
    kf.state = State{
        .vx = 0.0,
        .vy = 0.0,
        .yaw_rate = 0.0,
        .slip_front = 0.0,
        .slip_rear = 0.0,
        .friction = 1.0,
    };
    for (&kf.P) |*p| p.* = 0.0;
    kf.P[0] = 1.0;
    kf.P[7] = 1.0;
    kf.P[14] = 0.1;
    kf.P[21] = 0.01;
    kf.P[28] = 0.01;
    kf.P[35] = 0.1;
    for (&kf.Q) |*q| q.* = 0.0;
    kf.Q[0] = 0.01;
    kf.Q[7] = 0.01;
    kf.Q[14] = 0.001;
    kf.dt = dt;
    kf.wheelbase = 1.55;
    kf.track_width = 1.20;
}

pub export fn kalman_predict(kf: *KalmanFilter) void {
    const dt = kf.dt;
    const r = kf.state.yaw_rate;
    kf.state.vx += dt * (kf.state.vy * r);
    kf.state.vy += dt * (-kf.state.vx * r);
    kf.state.yaw_rate *= 0.98;
    kf.state.slip_front *= 0.95;
    kf.state.slip_rear *= 0.95;
    for (0..36) |i| {
        kf.P[i] += kf.Q[i];
    }
}

pub export fn kalman_update(kf: *KalmanFilter, z: *const Measurement) void {
    const avg_front = (z.wheel_speed_fl + z.wheel_speed_fr) / 2.0;
    const avg_rear = (z.wheel_speed_rl + z.wheel_speed_rr) / 2.0;
    const K: f32 = 0.3;
    kf.state.vx += K * (avg_front - kf.state.vx);
    const yaw_from_wheels = (z.wheel_speed_fr - z.wheel_speed_fl) / kf.track_width;
    kf.state.yaw_rate += 0.2 * (yaw_from_wheels - kf.state.yaw_rate);
    const slip = (avg_front - avg_rear) / @max(avg_front, 0.1);
    kf.state.slip_front += 0.1 * (slip - kf.state.slip_front);
    kf.state.slip_rear += 0.1 * (-slip - kf.state.slip_rear);
    for (0..36) |i| {
        kf.P[i] *= 0.9;
    }
}

pub export fn kalman_get_state(kf: *const KalmanFilter, out: *State) void {
    out.* = kf.state;
}
