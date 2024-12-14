const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try stone_count_after_blinks(allocator, input_full, 75);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try stone_count_after_blinks(allocator, input_example, 25) == 55312);
}

test "result full 25" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try stone_count_after_blinks(allocator, input_full, 25) == 228668);
}

test "result full 75" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try stone_count_after_blinks(allocator, input_full, 75) == 270673834779359);
}

const Stone = struct { number: u64, blinks: u64 };
const StoneContext = struct {
    pub fn hash(_: StoneContext, key: Stone) u32 {
        var hasher = std.hash.Fnv1a_32.init();
        std.hash.autoHash(&hasher, key.number);
        std.hash.autoHash(&hasher, key.blinks);
        return hasher.final();
    }

    pub fn eql(_: StoneContext, a: Stone, b: Stone, _: usize) bool {
        return a.number == b.number and a.blinks == b.blinks;
    }
};
pub fn stone_count_after_blinks(allocator: std.mem.Allocator, input: []const u8, blinks: u64) !u64 {
    var stone_list = std.ArrayList(u64).init(allocator);
    defer stone_list.deinit();
    var it = std.mem.tokenizeAny(u8, input, " \n");
    while (it.next()) |token| {
        const number = try std.fmt.parseInt(u64, token, 10);
        try stone_list.append(number);
    }

    var stone_cache = std.ArrayHashMap(Stone, u64, StoneContext, true).init(allocator);
    defer stone_cache.deinit();
    var stone_len: u64 = 0;
    for (stone_list.items) |stone| {
        stone_len += try blink_number_rec(allocator, stone, blinks, &stone_cache);
    }

    return stone_len;
}

pub fn blink_number_rec(allocator: std.mem.Allocator, number: u64, blinks: u64, stone_cache: *std.ArrayHashMap(Stone, u64, StoneContext, true)) !u64 {
    if (blinks == 0) {
        return 1;
    }
    if (stone_cache.*.get(.{ .number = number, .blinks = blinks })) |result| {
        return result;
    }

    if (number == 0) {
        const result = try blink_number_rec(allocator, 1, blinks - 1, stone_cache);
        try stone_cache.*.put(.{ .number = number, .blinks = blinks }, result);
        return result;
    }

    const stone_number_digits = digits_of_number(number);
    if (stone_number_digits % 2 != 0) {
        const result = try blink_number_rec(allocator, number * 2024, blinks - 1, stone_cache);
        try stone_cache.*.put(.{ .number = number, .blinks = blinks }, result);
        return result;
    }

    const stone_left = number / std.math.pow(u64, 10, stone_number_digits / 2);
    const stone_right = number - (stone_left * std.math.pow(u64, 10, stone_number_digits / 2));
    var result: u64 = 0;
    result += try blink_number_rec(allocator, stone_left, blinks - 1, stone_cache);
    result += try blink_number_rec(allocator, stone_right, blinks - 1, stone_cache);
    try stone_cache.*.put(.{ .number = number, .blinks = blinks }, result);
    return result;
}

pub fn digits_of_number(number: u64) u32 {
    if (number == 0) return 1;
    const number_float: f64 = @floatFromInt(number);
    const result = @floor(@log10(number_float)) + 1;
    return @intFromFloat(result);
}
