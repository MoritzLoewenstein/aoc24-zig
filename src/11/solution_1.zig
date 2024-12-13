const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try stone_count_after_blinks(allocator, input_full, 25);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try stone_count_after_blinks(allocator, input_example, 25) == 55312);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try stone_count_after_blinks(allocator, input_full, 25) == 228668);
}

pub fn stone_count_after_blinks(allocator: std.mem.Allocator, input: []const u8, blinks: u64) !u64 {
    var stone_list = std.ArrayList(u64).init(allocator);
    defer stone_list.deinit();
    var it = std.mem.tokenizeAny(u8, input, " \n");
    while (it.next()) |token| {
        const number = try std.fmt.parseInt(u64, token, 10);
        try stone_list.append(number);
    }

    var blink: u64 = 0;
    while (blink < blinks) : (blink += 1) {
        var stone_list_idx: u64 = 0;
        while (stone_list_idx < stone_list.items.len) {
            const stone_number = stone_list.items[stone_list_idx];
            if (stone_number == 0) {
                stone_list.items[stone_list_idx] = 1;
                stone_list_idx += 1;
                continue;
            }

            const stone_number_digits = digits_of_number_table(stone_number);
            if (stone_number_digits % 2 == 0) {
                const stone_left = stone_number / std.math.pow(u64, 10, stone_number_digits / 2);
                const stone_right = stone_number - (stone_left * std.math.pow(u64, 10, stone_number_digits / 2));
                stone_list.items[stone_list_idx] = stone_left;
                try stone_list.insert(stone_list_idx + 1, stone_right);
                stone_list_idx += 2;
            } else {
                stone_list.items[stone_list_idx] = stone_number * 2024;
                stone_list_idx += 1;
            }
        }
    }

    return stone_list.items.len;
}

pub fn digits_of_number(number: u64) u32 {
    if (number == 0) return 1;
    const number_float: f64 = @floatFromInt(number);
    const result = @floor(@log10(number_float)) + 1;
    return @intFromFloat(result);
}

pub fn digits_of_number_table(number: u64) u64 {
    return switch (number) {
        0...9 => 1,
        10...99 => 2,
        100...999 => 3,
        1_000...9_999 => 4,
        10_000...99_999 => 5,
        100_000...999_999 => 6,
        1_000_000...9_999_999 => 7,
        10_000_000...99_999_999 => 8,
        100_000_000...999_999_999 => 9,
        1_000_000_000...9_999_999_999 => 10,
        10_000_000_000...99_999_999_999 => 11,
        100_000_000_000...999_999_999_999 => 12,
        else => unreachable,
    };
}
