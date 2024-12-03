const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example_1.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try calc_corrupted_mul(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_corrupted_mul(allocator, input_example) == 161);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_corrupted_mul(allocator, input_full) == 180233229);
}

const State = enum { initial, letter_m, letter_u, letter_l, opening_brace, mul_read_a, argument_separator, mul_read_b };
pub fn calc_corrupted_mul(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var state_previous = State.initial;
    var state_current = State.initial;
    var tmp = std.ArrayList(u8).init(allocator);
    defer tmp.deinit();
    var num_a: u32 = 0;
    var num_b: u32 = 0;
    var mul_acc: u32 = 0;
    for (input) |char| {
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
                    //std.debug.print("mul({any},{any})\n", .{ num_a, num_b });
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
        //std.debug.print("state_transition: {any} -> {any}, char: {any}, tmp: {any}, num_a: {any}, num_b: {any}\n", .{ state_previous, state_current, char, tmp.items, num_a, num_b });
        // reset tmp if necessary
        if (state_current == State.initial and tmp.items.len > 0) {
            tmp.clearAndFree();
        }
    }

    return mul_acc;
}
