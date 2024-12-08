const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try calibration_sum(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calibration_sum(allocator, input_example) == 3749);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calibration_sum(allocator, input_full) == 2437272016585);
}

pub fn calibration_sum(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var calibration_equations = std.AutoHashMap(u64, []const u64).init(allocator);
    defer calibration_equations.deinit();
    var permutations = std.AutoHashMap(u64, []const []const Operand).init(allocator);
    defer permutations.deinit();
    var idx: u64 = 0;
    var tmp = std.ArrayList(u64).init(allocator);
    defer tmp.deinit();
    while (idx < input.len) {
        const number_idx = idx;
        const number_end_idx = std.mem.indexOfScalarPos(u8, input, number_idx, ':') orelse unreachable;
        const number = try std.fmt.parseInt(u64, input[number_idx..number_end_idx], 10);
        idx = number_end_idx + 2;
        const eol_idx = std.mem.indexOfScalarPos(u8, input, idx, '\n') orelse unreachable;
        while (idx < eol_idx) {
            const value_end_idx = std.mem.indexOfAnyPos(u8, input, idx, " \n") orelse unreachable;
            const value = try std.fmt.parseInt(u64, input[idx..value_end_idx], 10);
            try tmp.append(value);
            idx = value_end_idx + 1;
        }
        if (permutations.get(tmp.items.len - 1) == null) {
            const permutations_of_len = try operand_permutations_of_len(allocator, tmp.items.len - 1);
            try permutations.put(tmp.items.len - 1, permutations_of_len);
        }
        const owned_slice = try tmp.toOwnedSlice();
        try calibration_equations.put(number, owned_slice);
        tmp.clearRetainingCapacity();
    }

    var calibration_result: u64 = 0;
    var it_calibrations = calibration_equations.keyIterator();
    while (it_calibrations.next()) |result| {
        const values = calibration_equations.get(result.*) orelse unreachable;
        const operand_permutations = permutations.get(values.len - 1) orelse unreachable;
        const is_valid = try is_calculation_valid(result.*, values, operand_permutations);
        if (is_valid) {
            calibration_result += result.*;
        }
    }

    var it_permutations = permutations.valueIterator();
    while (it_permutations.next()) |permutations_of_len| {
        operand_permutations_deinit(allocator, permutations_of_len.*);
    }
    var it_calibration_values = calibration_equations.valueIterator();
    while (it_calibration_values.next()) |owned_slice| {
        allocator.free(owned_slice.*);
    }
    return calibration_result;
}

const Operand = enum { Add, Multiply };
pub fn is_calculation_valid(result: u64, values: []const u64, operand_permutations: []const []const Operand) !bool {
    operand_permutation: for (operand_permutations) |operands| {
        var idx: u64 = 0;
        var value_res: u64 = values[0];
        while (idx < operands.len) {
            if (value_res > result) {
                // permutation already invalid, operands only increase result
                continue :operand_permutation;
            }
            // use operand with current and next idx
            value_res = switch (operands[idx]) {
                Operand.Add => value_res + values[idx + 1],
                Operand.Multiply => value_res * values[idx + 1],
            };
            idx += 1;
        }

        if (value_res == result) {
            return true;
        }
    }
    return false;
}

pub fn operand_permutations_deinit(allocator: std.mem.Allocator, permutations: []const []const Operand) void {
    for (permutations) |sequence| {
        allocator.free(sequence);
    }
    allocator.free(permutations);
}

pub fn operand_permutations_of_len(allocator: std.mem.Allocator, permutation_len: u64) ![]const []const Operand {
    if (permutation_len == 0) {
        var result = std.ArrayList([]const Operand).init(allocator);
        defer result.deinit();
        const operands: []const Operand = &.{};
        try result.append(operands);
        return result.toOwnedSlice();
    }

    const shorter_sequences = try operand_permutations_of_len(allocator, permutation_len - 1);
    var result = std.ArrayList([]const Operand).init(allocator);
    defer result.deinit();
    for (shorter_sequences) |sequence| {
        var list_add = std.ArrayList(Operand).init(allocator);
        defer list_add.deinit();
        try list_add.appendSlice(sequence);
        try list_add.append(Operand.Add);
        var list_mul = std.ArrayList(Operand).init(allocator);
        defer list_mul.deinit();
        try list_mul.appendSlice(sequence);
        try list_mul.append(Operand.Multiply);
        const list_add_owned = try list_add.toOwnedSlice();
        const list_mul_owned = try list_mul.toOwnedSlice();
        try result.append(list_add_owned);
        try result.append(list_mul_owned);
    }

    operand_permutations_deinit(allocator, shorter_sequences);
    return result.toOwnedSlice();
}
