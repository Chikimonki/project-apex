const std = @import("std");

// ---------- Buffer Pool ----------
pub const Buffer = struct {
    ptr: [*]u8,
    size: usize,
    in_use: bool,
};

pub const BufferPool = struct {
    buffers: []Buffer,
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex = .{},

    pub fn init(allocator: std.mem.Allocator, num_buffers: usize, buffer_size: usize) !BufferPool {
        const pool = BufferPool{
            .buffers = try allocator.alloc(Buffer, num_buffers),
            .allocator = allocator,
        };
        errdefer allocator.free(pool.buffers);

        for (pool.buffers, 0..) |*buf, i| {
            const alignment = @as(std.mem.Alignment, @enumFromInt(6));
            const ptr = try allocator.alignedAlloc(u8, alignment, buffer_size);
            errdefer {
                for (pool.buffers[0..i]) |b| {
                    allocator.free(b.ptr[0..b.size]);
                }
            }
            buf.* = .{
                .ptr = ptr.ptr,
                .size = buffer_size,
                .in_use = false,
            };
        }
        return pool;
    }

    pub fn deinit(self: *BufferPool) void {
        for (self.buffers) |buf| {
            self.allocator.free(buf.ptr[0..buf.size]);
        }
        self.allocator.free(self.buffers);
    }

    pub fn acquire(self: *BufferPool, requested_size: usize) ?[*]u8 {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.buffers) |*buf| {
            if (!buf.in_use and buf.size >= requested_size) {
                buf.in_use = true;
                return buf.ptr;
            }
        }
        return null;
    }

    pub fn release(self: *BufferPool, ptr: [*]u8) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.buffers) |*buf| {
            if (buf.ptr == ptr) {
                buf.in_use = false;
                return;
            }
        }
    }
};

var global_pool: BufferPool = undefined;

export fn init_pool(num_buffers: usize, buffer_size: usize) void {
    global_pool = BufferPool.init(std.heap.c_allocator, num_buffers, buffer_size) catch
        @panic("failed to initialize buffer pool");
}

export fn acquire_buffer(size: usize) ?[*]u8 {
    return global_pool.acquire(size);
}

export fn release_buffer(ptr: [*]u8) void {
    global_pool.release(ptr);
}

const FrameIn = extern struct {
    id: u32,
    dlc: u8,
    padding: [3]u8,
    data: [8]u8,
};

const FrameOut = extern struct {
    id: u32,
    dlc: u8,
    data: [8]u8,
    speed: f32,
};

export fn process_frames(input: [*]u8, num_frames: usize, output: [*]u8) void {
    // Cast to pointers with the required alignment
    const in_aligned: [*]align(@alignOf(FrameIn)) u8 = @alignCast(input);
    const out_aligned: [*]align(@alignOf(FrameOut)) u8 = @alignCast(output);
    const in_frames = @as([*]FrameIn, @ptrCast(in_aligned));
    const out_frames = @as([*]FrameOut, @ptrCast(out_aligned));

    for (0..num_frames) |i| {
        const in_frame = in_frames[i];
        var out_frame = FrameOut{
            .id = in_frame.id,
            .dlc = in_frame.dlc,
            .data = in_frame.data,
            .speed = 0.0,
        };
        if (in_frame.id == 0x123) {
            const raw_speed = @as(u16, @bitCast([2]u8{ in_frame.data[0], in_frame.data[1] }));
            out_frame.speed = @as(f32, @floatFromInt(raw_speed)) / 100.0;
        }
        out_frames[i] = out_frame;
    }
}
