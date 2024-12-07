const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try calc_guard_loop_positions_len(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_guard_loop_positions_len(allocator, input_example) == 6);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_guard_loop_positions_len(allocator, input_full) == 2162);
}

const Guard_Direction = enum {
    Unkown,
    Up,
    Down,
    Left,
    Right,
};
const Guard = struct {
    row_idx: i32 = 0,
    col_idx: i32 = 0,
    direction: Guard_Direction = Guard_Direction.Unkown,
    pub fn next(self: *Guard) void {
        switch (self.direction) {
            Guard_Direction.Up => {
                self.row_idx -= 1;
            },
            Guard_Direction.Down => {
                self.row_idx += 1;
            },
            Guard_Direction.Left => {
                self.col_idx -= 1;
            },
            Guard_Direction.Right => {
                self.col_idx += 1;
            },
            else => unreachable,
        }
    }
    pub fn previous(self: *Guard) void {
        switch (self.direction) {
            Guard_Direction.Up => {
                self.row_idx += 1;
            },
            Guard_Direction.Down => {
                self.row_idx -= 1;
            },
            Guard_Direction.Left => {
                self.col_idx += 1;
            },
            Guard_Direction.Right => {
                self.col_idx -= 1;
            },
            else => unreachable,
        }
    }
    pub fn turn(self: *Guard) void {
        self.direction = switch (self.direction) {
            Guard_Direction.Up => Guard_Direction.Right,
            Guard_Direction.Right => Guard_Direction.Down,
            Guard_Direction.Down => Guard_Direction.Left,
            Guard_Direction.Left => Guard_Direction.Up,
            else => unreachable,
        };
    }
    pub fn clone(self: Guard) Guard {
        return Guard{ .row_idx = self.row_idx, .col_idx = self.col_idx, .direction = self.direction };
    }
};

pub fn calc_guard_loop_positions_len(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var guard = Guard{};
    var row_len: i32 = 0;
    var it_lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (it_lines.next()) |line| {
        row_len = @intCast(line.len);
        if (guard.direction == Guard_Direction.Unkown) {
            if (std.mem.indexOfAny(u8, line, "^<>V")) |pos| {
                guard.direction = switch (line[pos]) {
                    '^' => Guard_Direction.Up,
                    '<' => Guard_Direction.Left,
                    '>' => Guard_Direction.Right,
                    'V' => Guard_Direction.Down,
                    else => unreachable,
                };
                guard.col_idx = @intCast(pos);
            } else {
                guard.row_idx += 1;
            }
        }
    }

    if (guard.direction == Guard_Direction.Unkown) {
        unreachable;
    }

    const GUARD_INITIAL = guard.clone();

    // get possible obstacle positions by following initial path without additional obstacle
    var obstacle_positions_possible = std.ArrayList(u32).init(allocator);
    defer obstacle_positions_possible.deinit();
    while (true) {
        guard.next();
        if (is_pos_oob(guard.row_idx, guard.col_idx, row_len, input.len)) {
            break;
        }

        const input_idx = row_col_to_input_idx(guard.row_idx, guard.col_idx, row_len);
        const char = input[input_idx];
        if (char != '#') {
            if (std.mem.indexOfScalar(u32, obstacle_positions_possible.items, input_idx) == null) {
                try obstacle_positions_possible.append(input_idx);
            }
            continue;
        }

        guard.previous();
        guard.turn();
    }

    const Guard_Turn = struct { row_idx: i32, col_idx: i32, direction: Guard_Direction };
    var turn_log = std.ArrayList(Guard_Turn).init(allocator);
    defer turn_log.deinit();
    var loop_count: u32 = 0;
    for (obstacle_positions_possible.items) |obstacle_pos| {
        guard = GUARD_INITIAL;
        turn_log.clearRetainingCapacity();
        guard_walk: while (true) {
            guard.next();
            if (is_pos_oob(guard.row_idx, guard.col_idx, row_len, input.len)) {
                break :guard_walk;
            }

            const input_idx = row_col_to_input_idx(guard.row_idx, guard.col_idx, row_len);
            const char = input[input_idx];
            if (char != '#' and input_idx != obstacle_pos) {
                continue;
            }

            guard.previous();
            const turn_entry = Guard_Turn{ .row_idx = guard.row_idx, .col_idx = guard.col_idx, .direction = guard.direction };
            if (last_index_of_scalar_struct(Guard_Turn, turn_log.items, turn_entry) != null) {
                // guard loop
                loop_count += 1;
                break :guard_walk;
            }

            try turn_log.append(turn_entry);
            guard.turn();
        }
    }

    return loop_count;
}

pub fn is_pos_oob(row_idx: i32, col_idx: i32, row_len: i32, input_len: u64) bool {
    if (row_idx < 0 or col_idx < 0) {
        return true;
    }
    if (col_idx >= row_len) {
        return true;
    }
    const input_idx = row_col_to_input_idx(row_idx, col_idx, row_len);
    return input_idx >= input_len;
}

pub inline fn row_col_to_input_idx(row_idx: i32, col_idx: i32, row_len: i32) u32 {
    const idx = row_idx * (row_len + 1) + col_idx;
    return @intCast(idx);
}

pub fn last_index_of_scalar_struct(comptime T: type, slice: []const T, value: T) ?usize {
    if (slice.len == 0) return null;
    var i: usize = slice.len;
    while (i > 0) {
        i -= 1;
        if (std.meta.eql(slice[i], value)) {
            return i;
        }
    }
    return null;
}
