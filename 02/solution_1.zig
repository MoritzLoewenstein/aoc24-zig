const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub const Error = error{NotSupported};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try report_count_safe(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try report_count_safe(allocator, input_example) == 2);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try report_count_safe(allocator, input_full) == 402);
}

pub fn report_count_safe(allocator: std.mem.Allocator, input: []const u8) !u16 {
    var it_lines = std.mem.tokenizeScalar(u8, input, '\n');
    var report_safe_cnt: u16 = 0;
    while (it_lines.next()) |token_row| {
        var it_row = std.mem.tokenizeScalar(u8, token_row, ' ');
        var numbers_row = std.ArrayList(i16).init(allocator);
        defer numbers_row.deinit();
        while (it_row.next()) |token_number| {
            const number = try std.fmt.parseInt(i16, token_number, 10);
            try numbers_row.append(number);
        }
        if (try is_report_safe(numbers_row.items)) {
            report_safe_cnt += 1;
        }
    }

    return report_safe_cnt;
}

pub fn is_report_safe(numbers: []const i16) !bool {
    if (numbers.len < 2) {
        return error.NotSupported;
    }
    const is_ascending = numbers[0] < numbers[1];
    for (0..numbers.len - 1) |i| {
        // we already check for equal numbers here, equal numbers violate the second condition
        const consistent_sort = if (is_ascending) numbers[i] < numbers[i + 1] else numbers[i] > numbers[i + 1];
        if (!consistent_sort) {
            return false;
        }

        const abs_diff = @abs(numbers[i] - numbers[i + 1]);
        if (abs_diff > 3) {
            return false;
        }
    }
    return true;
}
