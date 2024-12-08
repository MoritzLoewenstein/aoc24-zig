const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

const WORD = "MAS";

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try count_x_any_direction(allocator, input_example, WORD);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try count_x_any_direction(allocator, input_example, WORD) == 9);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try count_x_any_direction(allocator, input_full, WORD) == 1908);
}

pub fn count_x_any_direction(allocator: std.mem.Allocator, input: []const u8, word: []const u8) !u64 {
    if (word.len % 2 != 1) {
        return error.OutOfRange;
    }

    const positions_diagonal = try word_positions_diagonal(allocator, input, word, false);
    defer allocator.free(positions_diagonal);

    const positions_diagonal_reverse = try word_positions_diagonal(allocator, input, word, true);
    defer allocator.free(positions_diagonal_reverse);

    var cnt: u64 = 0;
    for (positions_diagonal) |pos| {
        if (std.mem.indexOfScalar(u64, positions_diagonal_reverse, pos) != null) {
            cnt += 1;
        }
    }
    return cnt;
}

pub fn word_positions_diagonal(allocator: std.mem.Allocator, input: []const u8, word: []const u8, reverse_input: bool) ![]const u64 {
    const input_ordered = try ordered_input(allocator, input, reverse_input);
    defer allocator.free(input_ordered);
    const word_reverse = try allocator.dupe(u8, word);
    std.mem.reverse(u8, word_reverse);
    defer allocator.free(word_reverse);
    // we assume input is square (same amount of columns and lines)
    const side_length = std.mem.indexOf(u8, input, "\n").?;

    var word_positions = std.ArrayList(u64).init(allocator);
    defer word_positions.deinit();
    var tmp = std.ArrayList(u8).init(allocator);
    defer tmp.deinit();
    // diagonal bottom left to top right
    // skip first rows because diagonal is too short to contain word
    const INPUT_END = side_length * side_length + side_length;
    for (word.len - 1..side_length) |row_idx| {
        const diagonal_word_length = row_idx + 1;
        for (0..diagonal_word_length) |char_idx| {
            const idx = row_idx * side_length + row_idx - (side_length * char_idx);
            try tmp.append(input_ordered[idx]);
        }

        var slice_idx: u64 = 0;
        while (std.mem.indexOfPos(u8, tmp.items, slice_idx, word)) |pos| {
            // index of char in current diagonal sequence
            const char_idx = pos + word.len / 2;
            const idx = row_idx * side_length + row_idx - (side_length * char_idx);
            if (reverse_input) {
                const idx_reverse = map_idx_to_reverse_lines(idx, side_length);
                try word_positions.append(idx_reverse);
            } else {
                try word_positions.append(idx);
            }
            slice_idx = pos + word.len;
        }

        slice_idx = 0;
        while (std.mem.indexOfPos(u8, tmp.items, slice_idx, word_reverse)) |pos| {
            // index of char in current diagonal sequence
            const char_idx = pos + word.len / 2;
            const idx = row_idx * side_length + row_idx - (side_length * char_idx);
            if (reverse_input) {
                const idx_reverse = map_idx_to_reverse_lines(idx, side_length);
                try word_positions.append(idx_reverse);
            } else {
                try word_positions.append(idx);
            }
            slice_idx = pos + word.len;
        }
        tmp.clearRetainingCapacity();
    }
    // the previous loop does not cover the diagonals after the first column at the last row
    // skip last cols because they are too short to contain word
    for (1..side_length - word.len + 1) |col_idx| {
        const diagonal_word_length = side_length - col_idx;
        for (0..diagonal_word_length) |char_idx| {
            const idx = INPUT_END - diagonal_word_length - char_idx * side_length - 1;
            try tmp.append(input_ordered[idx]);
        }
        var slice_idx: u64 = 0;
        while (std.mem.indexOfPos(u8, tmp.items, slice_idx, word)) |pos| {
            const char_idx = pos + word.len / 2;
            const offset = diagonal_word_length + char_idx * side_length + 1;
            const idx = if (reverse_input) map_idx_to_reverse_lines(INPUT_END - offset, side_length) else INPUT_END - offset;
            try word_positions.append(idx);
            slice_idx = pos + word.len;
        }

        slice_idx = 0;
        while (std.mem.indexOfPos(u8, tmp.items, slice_idx, word_reverse)) |pos| {
            const char_idx = pos + word.len / 2;
            const offset = diagonal_word_length + char_idx * side_length + 1;
            const idx = if (reverse_input) map_idx_to_reverse_lines(INPUT_END - offset, side_length) else INPUT_END - offset;
            try word_positions.append(idx);
            slice_idx = pos + word.len;
        }
        tmp.clearRetainingCapacity();
    }
    return word_positions.toOwnedSlice();
}

pub fn ordered_input(allocator: std.mem.Allocator, input: []const u8, reverse_order: bool) ![]const u8 {
    var input_arr = std.ArrayList(u8).init(allocator);
    if (!reverse_order) {
        try input_arr.appendSlice(input);
        return input_arr.toOwnedSlice();
    }
    var it_line = std.mem.tokenizeScalar(u8, input, '\n');
    defer input_arr.deinit();
    while (it_line.next()) |line| {
        try input_arr.insert(0, '\n');
        try input_arr.insertSlice(0, line);
    }
    return input_arr.toOwnedSlice();
}

pub fn map_idx_to_reverse_lines(idx: u64, side_length: usize) u64 {
    const row = side_length - idx / (side_length + 1) - 1;
    const col = idx % (side_length + 1) - 1;
    const idx_unordered = row * (side_length + 1) + col + 1;
    return idx_unordered;
}
