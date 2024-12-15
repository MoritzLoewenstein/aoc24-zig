const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try trail_score_sum(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try trail_score_sum(allocator, input_example) == 81);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try trail_score_sum(allocator, input_full) == 1058);
}

pub fn trail_score_sum(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var it_lines = std.mem.tokenizeScalar(u8, input, '\n');
    var row_idx: u64 = 0;
    var col_idx: u64 = 0;
    var col_max: u64 = 0;
    col_idx += 1;
    var trailheads = std.ArrayList(u64).init(allocator);
    defer trailheads.deinit();
    while (it_lines.next()) |line| {
        col_max = line.len;
        col_idx = 0;
        while (col_idx < line.len) : (col_idx += 1) {
            if (line[col_idx] == '0') {
                try trailheads.append(row_col_to_input_idx(row_idx, col_idx, line.len));
            }
        }
        row_idx += 1;
    }

    var trailhead_score_sum: u64 = 0;
    for (trailheads.items) |trailhead| {
        trailhead_score_sum += try trailhead_score(input, trailhead, row_idx, col_max);
    }
    return trailhead_score_sum;
}

pub fn trailhead_score(input: []const u8, start_idx: u64, row_max: u64, col_max: u64) !u64 {
    if (input[start_idx] == '9') {
        return 1;
    }

    var score: u64 = 0;
    const start_idx_col = start_idx % (col_max + 1);
    if (start_idx >= row_max + 1) {
        const top_idx = start_idx - row_max - 1;
        if (input[top_idx] == input[start_idx] + 1) {
            score += try trailhead_score(input, top_idx, row_max, col_max);
        }
    }
    if (start_idx_col + 1 < col_max) {
        const right_idx = start_idx + 1;
        if (input[right_idx] == input[start_idx] + 1) {
            score += try trailhead_score(input, right_idx, row_max, col_max);
        }
    }
    if (start_idx_col > 0) {
        const left_idx = start_idx - 1;
        if (input[left_idx] == input[start_idx] + 1) {
            score += try trailhead_score(input, left_idx, row_max, col_max);
        }
    }
    if (start_idx + col_max + 1 < input.len) {
        const bottom_idx = start_idx + col_max + 1;
        if (input[bottom_idx] == input[start_idx] + 1) {
            score += try trailhead_score(input, bottom_idx, row_max, col_max);
        }
    }
    return score;
}

pub fn row_col_to_input_idx(row_idx: u64, col_idx: u64, row_len: u64) u64 {
    return row_idx * (row_len + 1) + col_idx;
}
