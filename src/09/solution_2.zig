const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try defragment_filesystem_block_checksum(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try defragment_filesystem_block_checksum(allocator, input_example) == 2858);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try defragment_filesystem_block_checksum(allocator, input_full) == 6360363199987);
}

const File = struct { id: u64, idx: u64, len: u4 };
const Empty = struct { idx: u64, len: u4 };
pub fn defragment_filesystem_block_checksum(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const line_end_idx = std.mem.indexOfScalar(u8, input, '\n') orelse 0;
    if (line_end_idx == 0) return 0;
    var file_list = std.ArrayList(File).init(allocator);
    defer file_list.deinit();
    var empty_list = std.ArrayList(Empty).init(allocator);
    defer empty_list.deinit();
    var fs_idx: u64 = 0;
    var is_file: bool = true;
    for (0..line_end_idx) |idx| {
        const len: u4 = try std.fmt.parseInt(u4, &[_]u8{input[idx]}, 10);
        if (is_file) {
            try file_list.append(.{
                .idx = fs_idx,
                .id = idx / 2,
                .len = len,
            });
        } else {
            try empty_list.append(.{ .idx = fs_idx, .len = len });
        }
        fs_idx += len;
        is_file = !is_file;
    }

    if (empty_list.items.len == 0) {
        std.debug.print("no defragmentation necessary, no empty places\n", .{});
        return 0;
    }

    var file_idx: u64 = file_list.items.len - 1;
    var fs_checksum: u64 = 0;
    file_loop: while (file_idx > 0) : (file_idx -= 1) {
        const file = file_list.items[file_idx];
        for (0..file_idx) |empty_idx| {
            const empty = empty_list.items[empty_idx];
            if (empty.len >= file.len) {
                fs_checksum += file_get_checksum(file.id, empty.idx, file.len);
                empty_list.items[empty_idx].idx += file.len;
                empty_list.items[empty_idx].len -= file.len;
                continue :file_loop;
            }
        }
        fs_checksum += file_get_checksum(file.id, file.idx, file.len);
    }

    return fs_checksum;
}

pub fn file_get_checksum(id: u64, idx: u64, len: u4) u64 {
    // use arithmetic progression formula of range idx to idx + len
    // multiply with file id to get checksum of file
    return id * (((idx + idx + len - 1) * len) / 2);
}
