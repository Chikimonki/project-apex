const std = @import("std");

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
            // 64‑byte alignment (2^6)
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
