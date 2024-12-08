const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try abs_distance(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try abs_distance(allocator, input_example) == 11);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try abs_distance(allocator, input_full) == 2904518);
}

pub fn abs_distance(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var it = std.mem.tokenizeAny(u8, input, " \n");
    var is_left = true;
    var numbers_left = std.ArrayList(i32).init(allocator);
    var numbers_right = std.ArrayList(i32).init(allocator);
    defer numbers_left.deinit();
    defer numbers_right.deinit();
    while (it.next()) |token| {
        const number = try std.fmt.parseInt(i32, token, 10);
        if (is_left) {
            try numbers_left.append(number);
        } else {
            try numbers_right.append(number);
        }
        is_left = !is_left;
    }

    std.mem.sort(i32, numbers_left.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, numbers_right.items, {}, comptime std.sort.asc(i32));

    var acc: u64 = 0;
    for (0..numbers_left.items.len) |i| {
        acc += @abs(numbers_right.items[i] - numbers_left.items[i]);
    }
    return acc;
}
