const std = @import("std");
const input_example_1 = @embedFile("input_example_1.txt");
const input_example_2 = @embedFile("input_example_2.txt");
const input_example_3 = @embedFile("input_example_3.txt");
const input_example_4 = @embedFile("input_example_4.txt");
const input_example_5 = @embedFile("input_example_5.txt");

const input_full = @embedFile("input_full.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try garden_fence_cost(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example 1" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_1) == 80);
}

test "result example 2" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_2) == 436);
}

test "result example 3" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_3) == 1206);
}

test "result example 4" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_4) == 236);
}

test "result example 5" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_example_5) == 368);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try garden_fence_cost(allocator, input_full) == 911750);
}

const Side = enum(u4) { Top = 1, Bottom = 2, Left = 4, Right = 8 };
const Plot = struct { idx: u64, sides: u4 };
const Area = struct { char: u8, area: u64, plots: std.ArrayList(Plot) };
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
        var sides_fence: u4 = 0;
        if (row_idx > 0) {
            const top_idx = idx - col_max - 1;
            area_top = input[top_idx] == char;
            if (!area_top) {
                sides_fence |= @intFromEnum(Side.Top);
            }
        }
        if (row_idx + 1 < row_max) {
            const bottom_idx = idx + col_max + 1;
            if (input[bottom_idx] != char) {
                sides_fence |= @intFromEnum(Side.Bottom);
            }
        }
        if (col_idx > 0) {
            const left_idx = idx - 1;
            area_left = input[left_idx] == char;
            if (!area_left) {
                sides_fence |= @intFromEnum(Side.Left);
            }
        }
        if (col_idx + 1 < col_max) {
            const right_idx = idx + 1;
            if (input[right_idx] != char) {
                sides_fence |= @intFromEnum(Side.Right);
            }
        }

        if (col_idx == 0) {
            sides_fence |= @intFromEnum(Side.Left);
        } else if (col_idx == col_max - 1) {
            sides_fence |= @intFromEnum(Side.Right);
        }

        if (row_idx == 0) {
            sides_fence |= @intFromEnum(Side.Top);
        } else if (row_idx == row_max - 1) {
            sides_fence |= @intFromEnum(Side.Bottom);
        }

        if (area_top and area_left) {
            // we need to potentially merge areas here
            const top_idx = idx - col_max - 1;
            const left_idx = idx - 1;
            const area_top_idx = idx_to_area_idx.get(top_idx) orelse unreachable;
            const area_left_idx = idx_to_area_idx.get(left_idx) orelse unreachable;
            if (area_top_idx == area_left_idx) {
                // its the same area, just do the usual stuff
                areas.items[area_left_idx].area += 1;
                try areas.items[area_left_idx].plots.append(.{ .idx = idx, .sides = sides_fence });
                try idx_to_area_idx.put(idx, area_left_idx);
            } else {
                // merge left area with top area, remove left area
                for (areas.items[area_left_idx].plots.items) |plot| {
                    try idx_to_area_idx.put(plot.idx, area_top_idx);
                }
                areas.items[area_top_idx].area += areas.items[area_left_idx].area;
                try areas.items[area_top_idx].plots.appendSlice(areas.items[area_left_idx].plots.items);
                // just set area to 0 to remove left area, otherwise idx_to_area_idx will get invalid
                areas.items[area_left_idx].area = 0;
                areas.items[area_left_idx].plots.deinit();
                // add current area
                areas.items[area_top_idx].area += 1;
                try areas.items[area_top_idx].plots.append(.{ .idx = idx, .sides = sides_fence });
                try idx_to_area_idx.put(idx, area_top_idx);
            }
        } else if (area_top) {
            const top_idx = idx - col_max - 1;
            const area_idx = idx_to_area_idx.get(top_idx) orelse unreachable;
            areas.items[area_idx].area += 1;
            try areas.items[area_idx].plots.append(.{ .idx = idx, .sides = sides_fence });
            try idx_to_area_idx.put(idx, area_idx);
        } else if (area_left) {
            const left_idx = idx - 1;
            const area_idx = idx_to_area_idx.get(left_idx) orelse unreachable;
            areas.items[area_idx].area += 1;
            try areas.items[area_idx].plots.append(.{ .idx = idx, .sides = sides_fence });
            try idx_to_area_idx.put(idx, area_idx);
        } else {
            var plots = std.ArrayList(Plot).init(allocator);
            try plots.append(.{ .idx = idx, .sides = sides_fence });
            const area = Area{ .char = input[idx], .area = 1, .plots = plots };
            try areas.append(area);
            try idx_to_area_idx.put(idx, areas.items.len - 1);
        }
    }

    var fence_cost: u64 = 0;
    for (areas.items) |area| {
        if (area.area == 0) {
            // area was merged and plots are deinitialized
            continue;
        }

        if (area.area == 1) {
            // fast path for trivial case
            fence_cost += 4;
            area.plots.deinit();
            continue;
        }

        var sides: u64 = 0;
        sides += try plots_count_sides(allocator, area.plots.items, Side.Top, col_max);
        sides += try plots_count_sides(allocator, area.plots.items, Side.Bottom, col_max);
        sides += try plots_count_sides(allocator, area.plots.items, Side.Left, col_max);
        sides += try plots_count_sides(allocator, area.plots.items, Side.Right, col_max);

        fence_cost += area.area * sides;
        area.plots.deinit();
    }

    return fence_cost;
}

pub fn plots_count_sides(allocator: std.mem.Allocator, plots: []const Plot, side: Side, col_max: u64) !u64 {
    var plot_group = std.AutoHashMap(u64, std.ArrayList(Plot)).init(allocator);
    defer plot_group.deinit();

    for (plots) |plot| {
        if (plot.sides & @intFromEnum(side) == 0) {
            // plot does not have a fence on the side we are grouping by
            continue;
        }
        const group_idx = switch (side) {
            Side.Top, Side.Bottom => plot.idx / (col_max + 1),
            Side.Left, Side.Right => plot.idx % (col_max + 1),
        };
        var plot_list = plot_group.get(group_idx) orelse std.ArrayList(Plot).init(allocator);
        try plot_list.append(plot);
        try plot_group.put(group_idx, plot_list);
    }

    const idx_delta = switch (side) {
        Side.Top, Side.Bottom => 1,
        Side.Left, Side.Right => col_max + 1,
    };

    var it_plot_group = plot_group.valueIterator();
    var sides: u64 = 0;
    while (it_plot_group.next()) |plot_list| {
        std.mem.sort(Plot, plot_list.items, {}, plot_compare_idx);
        var prev_idx: u64 = plot_list.items[0].idx;
        sides += 1;
        for (plot_list.items[1..]) |plot| {
            if (plot.idx != prev_idx + idx_delta) {
                sides += 1;
            }
            prev_idx = plot.idx;
        }
        plot_list.*.deinit();
    }

    return sides;
}

pub fn plot_compare_idx(_: void, a: Plot, b: Plot) bool {
    return a.idx < b.idx;
}

pub fn row_col_to_input_idx(row_idx: u64, col_idx: u64, row_len: u64) u64 {
    return row_idx * (row_len + 1) + col_idx;
}
