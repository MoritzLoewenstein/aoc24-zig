const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try ordered_invalid_print_queue_middle_sum(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try ordered_invalid_print_queue_middle_sum(allocator, input_example) == 123);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try ordered_invalid_print_queue_middle_sum(allocator, input_full) == 5273);
}

pub fn ordered_invalid_print_queue_middle_sum(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var number_to_dependants = std.AutoHashMap(u32, std.ArrayList(u32)).init(allocator);
    var print_updates = std.ArrayList([]const u32).init(allocator);
    defer print_updates.deinit();
    defer number_to_dependants.deinit();
    var it_line = std.mem.tokenizeScalar(u8, input, '\n');
    var tmp_numbers = std.ArrayList(u32).init(allocator);
    defer tmp_numbers.deinit();
    while (it_line.next()) |line| {
        if (line.len == 5) {
            // is page order rule
            var it_parts = std.mem.splitScalar(u8, line, '|');
            const a = try std.fmt.parseInt(u32, it_parts.next().?, 10);
            const b = try std.fmt.parseInt(u32, it_parts.next().?, 10);
            var arr_list = number_to_dependants.get(b) orelse std.ArrayList(u32).init(allocator);
            try arr_list.append(a);
            try number_to_dependants.put(b, arr_list);
        } else {
            // is print queue
            var it_numbers = std.mem.splitScalar(u8, line, ',');
            while (it_numbers.next()) |token| {
                const number = try std.fmt.parseInt(u32, token, 10);
                try tmp_numbers.append(number);
            }
            const slice_owned = try tmp_numbers.toOwnedSlice();
            try print_updates.append(slice_owned);
            tmp_numbers.clearRetainingCapacity();
        }
    }

    var print_updates_invalid_idx = std.ArrayList(u64).init(allocator);
    defer print_updates_invalid_idx.deinit();
    print_update: for (print_updates.items, 0..) |print_update, print_update_idx| {
        for (0..print_update.len, print_update) |idx, number| {
            const dependants = number_to_dependants.get(number);
            if (dependants == null) continue;
            if (std.mem.indexOfAny(u32, print_update[idx..], dependants.?.items) != null) {
                // at least one dependant is in print_update after number
                try print_updates_invalid_idx.append(print_update_idx);
                continue :print_update;
            }
        }
    }

    var middle_sum: u32 = 0;
    tmp_numbers.clearAndFree();
    for (print_updates_invalid_idx.items) |print_update_invalid_idx| {
        try tmp_numbers.appendSlice(print_updates.items[print_update_invalid_idx]);
        std.mem.sort(u32, tmp_numbers.items, number_to_dependants, print_queue_compare);
        const middle_idx = tmp_numbers.items.len / 2;
        middle_sum += tmp_numbers.items[middle_idx];
        tmp_numbers.clearRetainingCapacity();
    }

    var it_number_to_dependants = number_to_dependants.valueIterator();
    while (it_number_to_dependants.next()) |arr_list| {
        arr_list.deinit();
    }
    for (print_updates.items) |owned_slice| {
        allocator.free(owned_slice);
    }
    return middle_sum;
}

pub fn print_queue_compare(number_to_dependants: std.AutoHashMap(u32, std.ArrayList(u32)), a: u32, b: u32) bool {
    const a_dependants = number_to_dependants.get(a);
    if (a_dependants == null) return false;
    // if a_dependants contains b, we swap
    return std.mem.indexOfScalar(u32, a_dependants.?.items, b) != null;
}
