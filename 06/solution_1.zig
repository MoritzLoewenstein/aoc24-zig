const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try calc_guard_positions_len(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_guard_positions_len(allocator, input_example) == 41);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try calc_guard_positions_len(allocator, input_full) == 5329);
}

const Guard_Direction = enum { Unkown, Up, Down, Left, Right };
pub fn calc_guard_positions_len(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var col_idx: i32 = 0;
    var row_idx: i32 = 0;
    var row_len: i32 = 0;
    var guard_dir: Guard_Direction = Guard_Direction.Unkown;
    var it_lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (it_lines.next()) |line| {
        row_len = @intCast(line.len);
        if (guard_dir == Guard_Direction.Unkown) {
            if (std.mem.indexOfAny(u8, line, "^<>V")) |pos| {
                guard_dir = switch (line[pos]) {
                    '^' => Guard_Direction.Up,
                    '<' => Guard_Direction.Left,
                    '>' => Guard_Direction.Right,
                    'V' => Guard_Direction.Down,
                    else => unreachable,
                };
                col_idx = @intCast(pos);
            } else {
                row_idx += 1;
            }
        }
    }

    if (guard_dir == Guard_Direction.Unkown) {
        unreachable;
    }

    const guard_pos = struct {
        pub fn next(guard_direction: Guard_Direction, row_idx_: *i32, col_idx_: *i32) void {
            switch (guard_direction) {
                Guard_Direction.Up => {
                    row_idx_.* -= 1;
                },
                Guard_Direction.Down => {
                    row_idx_.* += 1;
                },
                Guard_Direction.Left => {
                    col_idx_.* -= 1;
                },
                Guard_Direction.Right => {
                    col_idx_.* += 1;
                },
                else => unreachable,
            }
        }

        pub fn previous(guard_direction: Guard_Direction, row_idx_: *i32, col_idx_: *i32) void {
            switch (guard_direction) {
                Guard_Direction.Up => {
                    row_idx_.* += 1;
                },
                Guard_Direction.Down => {
                    row_idx_.* -= 1;
                },
                Guard_Direction.Left => {
                    col_idx_.* += 1;
                },
                Guard_Direction.Right => {
                    col_idx_.* -= 1;
                },
                else => unreachable,
            }
        }

        pub fn turn(guard_direction: *Guard_Direction) void {
            guard_direction.* = switch (guard_direction.*) {
                Guard_Direction.Up => Guard_Direction.Right,
                Guard_Direction.Right => Guard_Direction.Down,
                Guard_Direction.Down => Guard_Direction.Left,
                Guard_Direction.Left => Guard_Direction.Up,
                else => unreachable,
            };
        }
    };

    var guard_pos_visited = std.AutoHashMap(u32, void).init(allocator);
    defer guard_pos_visited.deinit();
    while (true) {
        guard_pos.next(guard_dir, &row_idx, &col_idx);

        if (is_pos_oob(row_idx, col_idx, row_len, input.len)) {
            break;
        }

        const input_idx = row_col_to_input_idx(row_idx, col_idx, row_len);
        const char = input[input_idx];
        if (char != '#') {
            try guard_pos_visited.put(input_idx, {});
            continue;
        }
        // current guard pos is in obstacle, go back and turn
        guard_pos.previous(guard_dir, &row_idx, &col_idx);
        guard_pos.turn(&guard_dir);
        const guard_pos_input_idx = row_col_to_input_idx(row_idx, col_idx, row_len);
        try guard_pos_visited.put(guard_pos_input_idx, {});
    }

    return guard_pos_visited.count();
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

pub fn row_col_to_input_idx(row_idx: i32, col_idx: i32, row_len: i32) u32 {
    const idx = row_idx * (row_len + 1) + col_idx;
    return @intCast(idx);
}
