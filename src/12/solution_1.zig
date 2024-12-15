const std = @import("std");
const input_example_1 = @embedFile("input_example_1.txt");
const input_example_2 = @embedFile("input_example_2.txt");
const input_example_3 = @embedFile("input_example_3.txt");
const input_full = @embedFile("input_full.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try garden_fence_cost(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example 1" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_1) == 140);
}

test "result example 2" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_2) == 772);
}

test "result example 3" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_3) == 1930);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_full) == 1488414);
}

const Area = struct { char: u8, perimeter: u64, area: u64, plots: std.ArrayList(u64) };
pub fn garden_fence_cost(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const col_max: u64 = std.mem.indexOfScalar(u8, input, '\n') orelse 0;
    const row_max: u64 = std.mem.count(u8, input, "\n");

    if (col_max == 0 or row_max == 0) {
        return 0;
    }

    var idx_to_area_idx = std.AutoHashMap(u64, u64).init(allocator);
    defer idx_to_area_idx.deinit();
    var areas = std.ArrayList(Area).init(allocator);
    defer areas.deinit();

    var row_idx: u64 = 0;
    for (input, 0..) |char, idx| {
        if (char == '\n') {
            row_idx += 1;
            continue;
        }
        const col_idx = idx % (col_max + 1);
        var area_top = false;
        var area_left = false;
        var perimeter_score: u3 = 0;
        if (row_idx > 0) {
            const top_idx = idx - row_max - 1;
            area_top = input[top_idx] == char;
            if (!area_top) {
                perimeter_score += 1;
            }
        }
        if (col_idx > 0) {
            const left_idx = idx - 1;
            area_left = input[left_idx] == char;
            if (!area_left) {
                perimeter_score += 1;
            }
        }
        if (col_idx + 1 < col_max) {
            const right_idx = idx + 1;
            if (input[right_idx] != char) {
                perimeter_score += 1;
            }
        }
        if (row_idx + 1 < row_max) {
            const bottom_idx = idx + col_max + 1;
            if (input[bottom_idx] != char) {
                perimeter_score += 1;
            }
        }

        if (col_idx == 0 or col_idx == col_max - 1) {
            perimeter_score += 1;
        }
        if (row_idx == 0 or row_idx == row_max - 1) {
            perimeter_score += 1;
        }

        if (area_top and area_left) {
            // we need to potentially merge areas here
            const top_idx = idx - row_max - 1;
            const left_idx = idx - 1;
            const area_top_idx = idx_to_area_idx.get(top_idx) orelse unreachable;
            const area_left_idx = idx_to_area_idx.get(left_idx) orelse unreachable;
            if (area_top_idx == area_left_idx) {
                // its the same area, just do the usual stuff
                areas.items[area_left_idx].area += 1;
                areas.items[area_left_idx].perimeter += perimeter_score;
                try areas.items[area_left_idx].plots.append(idx);
                try idx_to_area_idx.put(idx, area_left_idx);
            } else {
                // merge left area with top area, remove left area
                for (areas.items[area_left_idx].plots.items) |plot_idx| {
                    try idx_to_area_idx.put(plot_idx, area_top_idx);
                }
                areas.items[area_top_idx].area += areas.items[area_left_idx].area;
                areas.items[area_top_idx].perimeter += areas.items[area_left_idx].perimeter;
                try areas.items[area_top_idx].plots.appendSlice(areas.items[area_left_idx].plots.items);
                // just set area to 0 to remove left area, otherwise idx_to_area_idx will get invalid
                areas.items[area_left_idx].area = 0;
                // add current area
                areas.items[area_top_idx].area += 1;
                areas.items[area_top_idx].perimeter += perimeter_score;
                try areas.items[area_top_idx].plots.append(idx);
                try idx_to_area_idx.put(idx, area_top_idx);
            }
        } else if (area_top) {
            const top_idx = idx - row_max - 1;
            const area_idx = idx_to_area_idx.get(top_idx) orelse unreachable;
            areas.items[area_idx].area += 1;
            areas.items[area_idx].perimeter += perimeter_score;
            try areas.items[area_idx].plots.append(idx);
            try idx_to_area_idx.put(idx, area_idx);
        } else if (area_left) {
            const left_idx = idx - 1;
            const area_idx = idx_to_area_idx.get(left_idx) orelse unreachable;
            areas.items[area_idx].area += 1;
            areas.items[area_idx].perimeter += perimeter_score;
            try areas.items[area_idx].plots.append(idx);
            try idx_to_area_idx.put(idx, area_idx);
        } else {
            var plots = std.ArrayList(u64).init(allocator);
            try plots.append(idx);
            const area = Area{ .char = input[idx], .perimeter = perimeter_score, .area = 1, .plots = plots };
            try areas.append(area);
            try idx_to_area_idx.put(idx, areas.items.len - 1);
        }
    }

    var fence_cost: u64 = 0;
    for (areas.items) |area| {
        if (area.area > 0) {
            fence_cost += area.area * area.perimeter;
            //std.debug.print("char: {c}, area: {any}, perimeter: {any}, plots: {any}\n", .{ area.char, area.area, area.perimeter, area.plots.items });
        }
        area.plots.deinit();
    }

    return fence_cost;
}

pub fn row_col_to_input_idx(row_idx: u64, col_idx: u64, row_len: u64) u64 {
    return row_idx * (row_len + 1) + col_idx;
}
