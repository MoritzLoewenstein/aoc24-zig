const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");
const input_edgecase = @embedFile("input_edgecase.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try report_count_safe(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try report_count_safe(allocator, input_example) == 4);
}

test "result edgecases" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try report_count_safe(allocator, input_edgecase) == 12);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try report_count_safe(allocator, input_full) == 455);
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
        if (try is_report_safe(allocator, numbers_row.items, false)) {
            report_safe_cnt += 1;
        }
    }

    return report_safe_cnt;
}

pub fn is_report_safe(allocator: std.mem.Allocator, number_slice: []const i16, has_removed_level: bool) !bool {
    var numbers = std.ArrayList(i16).init(allocator);
    defer numbers.deinit();
    try numbers.appendSlice(number_slice);
    if (numbers.items.len < 2) {
        return true;
    }
    const is_ascending = numbers.items[0] < numbers.items[1];
    for (0..numbers.items.len - 1) |i| {
        // we already check for equal numbers here, equal numbers violate the second condition
        const consistent_sort = if (is_ascending) numbers.items[i] < numbers.items[i + 1] else numbers.items[i] > numbers.items[i + 1];
        if (has_removed_level and !consistent_sort) {
            return false;
        }

        const abs_diff_valid = @abs(numbers.items[i] - numbers.items[i + 1]) <= 3;
        if (has_removed_level and !abs_diff_valid) {
            return false;
        }

        if (consistent_sort and abs_diff_valid) {
            continue;
        }

        // has_removed_level is false and current report is invalid
        // try to remove an element

        if (!consistent_sort and i == 1) {
            // edgecase: 25 24 27 28 30
            // the order of the first element is "always" correct
            // check without first element when sort constraint fails at index = 1
            const previous_element = numbers.orderedRemove(i - 1);
            const is_safe_without_previous = try is_report_safe(allocator, numbers.items, true);
            if (is_safe_without_previous) {
                return true;
            }
            try numbers.insert(i - 1, previous_element);
        }

        const current_element = numbers.orderedRemove(i);
        const is_safe_without_current = try is_report_safe(allocator, numbers.items, true);
        if (is_safe_without_current) {
            return true;
        }

        try numbers.insert(i, current_element);
        _ = numbers.orderedRemove(i + 1);
        return is_report_safe(allocator, numbers.items, true);
    }
    return true;
}
