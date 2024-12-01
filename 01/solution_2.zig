const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try similarity_score(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try similarity_score(allocator, input_example) == 31);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try similarity_score(allocator, input_full) == 18650129);
}

pub fn similarity_score(allocator: std.mem.Allocator, input: []const u8) !u128 {
    var it = std.mem.tokenizeAny(u8, input, " \n");
    var is_left = true;
    var numbers_left = std.ArrayList(u32).init(allocator);
    var numbers_right = std.ArrayList(u32).init(allocator);
    defer numbers_left.deinit();
    defer numbers_right.deinit();
    while (it.next()) |token| {
        const number = try std.fmt.parseInt(u32, token, 10);
        if (is_left) {
            try numbers_left.append(number);
        } else {
            try numbers_right.append(number);
        }
        is_left = !is_left;
    }

    var numbers_right_frequency_map = std.AutoHashMap(u32, u8).init(allocator);
    defer numbers_right_frequency_map.deinit();
    for (numbers_right.items) |number| {
        const count = numbers_right_frequency_map.get(number);
        const count_new: u8 = if (count == null) 1 else count.? + 1;
        try numbers_right_frequency_map.put(number, count_new);
    }

    var similarity_score_cnt: u128 = 0;
    for (numbers_left.items) |number| {
        const frequency = numbers_right_frequency_map.get(number);
        if (frequency == null) {
            continue;
        }

        similarity_score_cnt = similarity_score_cnt + number * frequency.?;
    }
    return similarity_score_cnt;
}
