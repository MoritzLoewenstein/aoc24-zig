const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example_2.txt");
const input_test = @embedFile("input_test.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try calc_corrupted_mul(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_corrupted_mul(allocator, input_example) == 48);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_corrupted_mul(allocator, input_full) == 95411583);
}

const State = enum { initial, letter_m, letter_u, letter_l, opening_brace, mul_read_a, argument_separator, mul_read_b };
pub fn calc_corrupted_mul(allocator: std.mem.Allocator, input: []const u8) !u32 {
    const input_valid = try remove_disabled_instructions(allocator, input);
    defer allocator.free(input_valid);
    var state_previous = State.initial;
    var state_current = State.initial;
    var tmp = std.ArrayList(u8).init(allocator);
    defer tmp.deinit();
    var num_a: u32 = 0;
    var num_b: u32 = 0;
    var mul_acc: u32 = 0;
    for (input_valid) |char| {
        state_previous = state_current;
        state_current = switch (state_current) {
            State.initial => switch (char) {
                'm' => State.letter_m,
                else => State.initial,
            },
            State.letter_m => switch (char) {
                'u' => State.letter_u,
                else => State.initial,
            },
            State.letter_u => switch (char) {
                'l' => State.letter_l,
                else => State.initial,
            },
            State.letter_l => switch (char) {
                '(' => State.opening_brace,
                else => State.initial,
            },
            State.opening_brace => opening_brace: {
                // no leading zero
                if (!std.ascii.isDigit(char) or char == '0') {
                    break :opening_brace State.initial;
                }

                try tmp.append(char);
                break :opening_brace State.mul_read_a;
            },
            State.mul_read_a => mul_read_a: {
                if (tmp.items.len > 0 and char == ',') {
                    num_a = try std.fmt.parseInt(u32, tmp.items, 10);
                    tmp.clearAndFree();
                    break :mul_read_a State.argument_separator;
                }

                if (!std.ascii.isDigit(char)) {
                    break :mul_read_a State.initial;
                }

                if (tmp.items.len == 3) {
                    break :mul_read_a State.initial;
                } else {
                    try tmp.append(char);
                    break :mul_read_a State.mul_read_a;
                }
            },
            State.argument_separator => argument_separator: {
                // no leading zero
                if (!std.ascii.isDigit(char) or char == '0') {
                    break :argument_separator State.initial;
                }

                try tmp.append(char);
                break :argument_separator State.mul_read_b;
            },
            State.mul_read_b => mul_read_b: {
                if (tmp.items.len > 0 and char == ')') {
                    num_b = try std.fmt.parseInt(u32, tmp.items, 10);
                    mul_acc += num_a * num_b;
                    break :mul_read_b State.initial;
                }

                if (!std.ascii.isDigit(char)) {
                    break :mul_read_b State.initial;
                }

                if (tmp.items.len == 3) {
                    break :mul_read_b State.initial;
                } else {
                    try tmp.append(char);
                    break :mul_read_b State.mul_read_b;
                }
            },
        };
        // reset tmp if necessary
        if (state_current == State.initial and tmp.items.len > 0) {
            tmp.clearAndFree();
        }
    }

    return mul_acc;
}

pub fn remove_disabled_instructions(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var input_arr = std.ArrayList(u8).init(allocator);
    defer input_arr.deinit();
    try input_arr.appendSlice(input);
    var dont_index = std.mem.indexOf(u8, input_arr.items, "don't()");
    if (dont_index == null) return input;
    while(dont_index != null) {
        var dont_index_val = dont_index.?;
        var do_index = std.mem.indexOf(u8, input_arr.items, "do()");
        // remove do() if index smaller then dont()
        while(do_index != null and do_index.? < dont_index_val) {
            try input_arr.replaceRange(do_index.?, 4, &.{});
            do_index = std.mem.indexOf(u8, input_arr.items, "do()");
            // dont_index decreased by the length of do()
            dont_index_val -= 4;
        }

        if(do_index == null) {
            // there is no do() after don't(), remove everything after don't()
            try input_arr.replaceRange(dont_index_val, input_arr.items.len - dont_index_val, &.{});
            return input_arr.toOwnedSlice();
        } else {
            try input_arr.replaceRange(dont_index_val, do_index.? + 4 - dont_index_val, &.{});
        }
        dont_index = std.mem.indexOf(u8, input_arr.items, "don't()");
    }
    return input_arr.toOwnedSlice();
}
