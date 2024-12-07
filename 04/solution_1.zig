const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

const WORD = "XMAS";

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try count_word_any_direction(allocator, input_full, WORD);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try count_word_any_direction(allocator, input_example, WORD) == 18);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try count_word_any_direction(allocator, input_full, WORD) == 2370);
}

pub fn count_word_any_direction(allocator: std.mem.Allocator, input: []const u8, word: []const u8) !u64 {
    const word_reverse = try allocator.dupe(u8, word);
    std.mem.reverse(u8, word_reverse);
    defer allocator.free(word_reverse);

    const count_forwards: u64 = std.mem.count(u8, input, word);
    const count_backwards: u64 = std.mem.count(u8, input, word_reverse);
    const count_vertical: u64 = try count_word_vertical(allocator, input, word);
    const count_diagonal: u64 = try count_word_diagonal(allocator, input, word);

    // revert the line order in the input, so we can count the diagonals in the other direction
    var it_line = std.mem.tokenizeScalar(u8, input, '\n');
    var input_line_order_reverse = std.ArrayList(u8).init(allocator);
    defer input_line_order_reverse.deinit();
    while (it_line.next()) |line| {
        // insert newline for every line except the last one
        if (true or input_line_order_reverse.items.len != 0) {
            try input_line_order_reverse.insert(0, '\n');
        }
        try input_line_order_reverse.insertSlice(0, line);
    }
    const count_diagonal_reverse: u64 = try count_word_diagonal(allocator, input_line_order_reverse.items, word);

    return count_forwards + count_backwards + count_vertical + count_diagonal + count_diagonal_reverse;
}

pub fn count_word_vertical(allocator: std.mem.Allocator, input: []const u8, word: []const u8) !u64 {
    const word_reverse = try allocator.dupe(u8, word);
    std.mem.reverse(u8, word_reverse);
    defer allocator.free(word_reverse);
    // we assume input is square (same amount of columns and lines)
    const side_length = std.mem.indexOf(u8, input, "\n").?;

    var tmp = std.ArrayList(u8).init(allocator);
    defer tmp.deinit();
    var count: u64 = 0;
    for (0..side_length) |col_idx| {
        for (0..side_length) |row_idx| {
            const idx = col_idx + row_idx * side_length + row_idx;
            try tmp.append(input[idx]);
        }
        count += std.mem.count(u8, tmp.items, word);
        count += std.mem.count(u8, tmp.items, word_reverse);
        tmp.clearRetainingCapacity();
    }
    return count;
}

pub fn count_word_diagonal(allocator: std.mem.Allocator, input: []const u8, word: []const u8) !u64 {
    const word_reverse = try allocator.dupe(u8, word);
    std.mem.reverse(u8, word_reverse);
    defer allocator.free(word_reverse);
    // we assume input is square (same amount of columns and lines)
    // find out the line length based on that assumption
    const side_length = std.mem.indexOf(u8, input, "\n").?;

    var tmp = std.ArrayList(u8).init(allocator);
    defer tmp.deinit();
    var count: u64 = 0;
    // diagonal bottom left to top right
    // skip first rows because diagonal is too short to contain word
    for (word.len - 1..side_length) |row_idx| {
        const diagonal_word_length = row_idx + 1;
        for (0..diagonal_word_length) |char_idx| {
            const idx = row_idx * side_length + row_idx - (side_length * char_idx);
            try tmp.append(input[idx]);
        }
        count += std.mem.count(u8, tmp.items, word);
        count += std.mem.count(u8, tmp.items, word_reverse);
        tmp.clearRetainingCapacity();
    }
    // the previous loop does not cover the diagonals after the first column at the last row
    // skip last cols because they are too short to contain word
    for (1..side_length - word.len + 1) |col_idx| {
        const diagonal_word_length = side_length - col_idx;
        for (0..diagonal_word_length) |char_idx| {
            const idx = side_length * side_length + side_length - diagonal_word_length - char_idx * side_length - 1;
            try tmp.append(input[idx]);
        }
        count += std.mem.count(u8, tmp.items, word);
        count += std.mem.count(u8, tmp.items, word_reverse);
        tmp.clearRetainingCapacity();
    }

    return count;
}
