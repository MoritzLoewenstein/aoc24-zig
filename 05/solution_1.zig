const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try valid_print_queue_middle_sum(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try valid_print_queue_middle_sum(allocator, input_example) == 143);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try valid_print_queue_middle_sum(allocator, input_full) == 5639);
}

pub fn valid_print_queue_middle_sum(allocator: std.mem.Allocator, input: []const u8) !u32 {
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

    var middle_sum: u32 = 0;
    print_update: for (print_updates.items) |print_update| {
        for (0..print_update.len, print_update) |idx, number| {
            const dependants = number_to_dependants.get(number);
            if (dependants == null) continue;
            for (dependants.?.items) |dependant| {
                if (std.mem.indexOfScalar(u32, print_update[idx..], dependant) != null) {
                    // dependant is in print_update but after number
                    // continue with next print_update
                    continue :print_update;
                }
            }
        }
        const middle_idx = print_update.len / 2;
        middle_sum += print_update[middle_idx];
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
