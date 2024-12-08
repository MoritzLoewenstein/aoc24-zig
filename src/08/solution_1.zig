const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");
const input_test_1 = @embedFile("input_test_1.txt");
const input_test_2 = @embedFile("input_test_2.txt");
const input_test_3 = @embedFile("input_test_3.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try antenna_antinode_count(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try antenna_antinode_count(allocator, input_example) == 14);
}

test "result test 1" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try antenna_antinode_count(allocator, input_test_1) == 2);
}

test "result test 2" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try antenna_antinode_count(allocator, input_test_2) == 4);
}

test "result test 3" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try antenna_antinode_count(allocator, input_test_3) == 4);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try antenna_antinode_count(allocator, input_full) == 249);
}

pub fn antenna_antinode_count(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var antenna_positions = std.AutoHashMap(u8, std.ArrayList(u64)).init(allocator);
    defer antenna_positions.deinit();
    var it_lines = std.mem.tokenizeScalar(u8, input, '\n');
    var row_idx: u64 = 0;
    var col_idx: u64 = 0;
    var col_max: u64 = 0;
    while (it_lines.next()) |line| {
        col_max = line.len;
        col_idx = 0;
        while (col_idx < line.len) {
            const char = line[col_idx];
            if (std.ascii.isAlphanumeric(char)) {
                var arraylist = antenna_positions.get(char) orelse std.ArrayList(u64).init(allocator);
                try arraylist.append(row_col_to_input_idx(row_idx, col_idx, line.len));
                try antenna_positions.put(char, arraylist);
            }
            col_idx += 1;
        }

        row_idx += 1;
    }

    var antinode_positions = std.AutoHashMap(u64, void).init(allocator);
    defer antinode_positions.deinit();
    var it_antenna_keys = antenna_positions.keyIterator();
    while (it_antenna_keys.next()) |antenna| {
        const positions = antenna_positions.get(antenna.*) orelse unreachable;
        if (positions.items.len < 2) continue;
        for (positions.items, 0..) |position, idx| {
            for (idx + 1..positions.items.len) |inner_idx| {
                const antenna_a = position;
                const antenna_b = positions.items[inner_idx];
                const antenna_a_col = antenna_a % (col_max + 1);
                const antenna_b_col = antenna_b % (col_max + 1);
                const col_delta = if (antenna_a_col > antenna_b_col) antenna_a_col - antenna_b_col else antenna_b_col - antenna_a_col;
                const delta = antenna_b - antenna_a;
                const col_increase = antenna_b_col > antenna_a_col;
                const has_previous_antinode = delta <= antenna_a and ((col_increase and antenna_a_col >= col_delta) or
                    (!col_increase and antenna_a_col + col_delta < col_max));
                if (has_previous_antinode and input[antenna_a - delta] != '\n') {
                    try antinode_positions.put(antenna_a - delta, {});
                }
                const has_next_antinode = (antenna_b + delta) < input.len and ((col_increase and antenna_b_col + col_delta < col_max) or
                    (!col_increase and antenna_b_col >= col_delta));
                if (has_next_antinode and input[antenna_b + delta] != '\n') {
                    try antinode_positions.put(antenna_b + delta, {});
                }
            }
        }
    }

    var it_antennas = antenna_positions.valueIterator();
    while (it_antennas.next()) |antenna_list| {
        antenna_list.*.deinit();
    }

    return antinode_positions.count();
}

pub fn row_col_to_input_idx(row_idx: u64, col_idx: u64, row_len: u64) u64 {
    return row_idx * (row_len + 1) + col_idx;
}
