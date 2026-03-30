// src/pipeline_fast.zig
// Hot path optimization for CSV parsing and hex conversion

const std = @import("std");

// Fast hex string to bytes conversion
export fn hex_to_bytes_fast(hex_str: [*:0]const u8, out_bytes: [*]u8, len: usize) usize {
    var i: usize = 0;
    var out_idx: usize = 0;
    
    while (i < len and hex_str[i] != 0) : (i += 2) {
        const high = hex_char_to_nibble(hex_str[i]);
        const low = hex_char_to_nibble(hex_str[i + 1]);
        
        if (high == 0xFF or low == 0xFF) continue; // Skip invalid
        
        out_bytes[out_idx] = (high << 4) | low;
        out_idx += 1;
    }
    
    return out_idx;
}

inline fn hex_char_to_nibble(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => 0xFF,
    };
}

// Fast CSV line parser - returns field count
export fn parse_csv_fast(line: [*:0]const u8, fields: [*][*:0]const u8, max_fields: usize) usize {
    var field_count: usize = 0;
    var field_start: usize = 0;
    var i: usize = 0;
    
    var temp_buf = std.mem.zeroes([256]u8);
    var buf_idx: usize = 0;
    
    while (line[i] != 0 and field_count < max_fields) : (i += 1) {
        if (line[i] == ',' or line[i] == '\n' or line[i] == '\r') {
            temp_buf[buf_idx] = 0;
            // Note: This is simplified - in production you'd need proper memory management
            field_count += 1;
            buf_idx = 0;
        } else {
            temp_buf[buf_idx] = line[i];
            buf_idx += 1;
        }
    }
    
    if (buf_idx > 0) {
        temp_buf[buf_idx] = 0;
        field_count += 1;
    }
    
    return field_count;
}

// Batch processing buffer
const BatchBuffer = struct {
    frames: [1024]Frame,
    count: usize,
    
    const Frame = struct {
        timestamp: f64,
        can_id: u32,
        data: [8]u8,
        data_len: u8,
    };
};

export fn create_batch_buffer() *BatchBuffer {
    const allocator = std.heap.c_allocator;
    const buf = allocator.create(BatchBuffer) catch unreachable;
    buf.count = 0;
    return buf;
}

export fn destroy_batch_buffer(buf: *BatchBuffer) void {
    const allocator = std.heap.c_allocator;
    allocator.destroy(buf);
}

// Stats tracking
export fn compute_stats(values: [*]const f64, count: usize, out_mean: *f64, out_max: *f64) void {
    if (count == 0) return;
    
    var sum: f64 = 0;
    var max_val: f64 = values[0];
    
    var i: usize = 0;
    while (i < count) : (i += 1) {
        sum += values[i];
        if (values[i] > max_val) max_val = values[i];
    }
    
    out_mean.* = sum / @as(f64, @floatFromInt(count));
    out_max.* = max_val;
}
