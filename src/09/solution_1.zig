const std = @import("std");
const input_full = @embedFile("input_full.txt");
const input_example = @embedFile("input_example.txt");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const result = try defragment_filesystem_checksum(allocator, input_full);
    std.debug.print("result: {d}\n", .{result});
}

test "result example" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try defragment_filesystem_checksum(allocator, input_example) == 1928);
}

test "result full" {
    const allocator = std.testing.allocator;
    try std.testing.expect(try defragment_filesystem_checksum(allocator, input_full) == 6344673854800);
}

const File = struct { id: u64, len: u64 };
pub fn defragment_filesystem_checksum(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const line_end_idx = std.mem.indexOfScalar(u8, input, '\n') orelse 0;
    if (line_end_idx == 0) return 0;
    var file_list = std.ArrayList(File).init(allocator);
    defer file_list.deinit();
    var empty_list = std.ArrayList(u64).init(allocator);
    defer empty_list.deinit();
    for (0..line_end_idx) |idx| {
        const is_file_len = idx % 2 == 0;
        const len: u64 = input[idx] - '0';
        if (is_file_len) {
            const file_id: u64 = idx / 2;
            try file_list.append(.{ .id = file_id, .len = len });
        } else {
            try empty_list.append(len);
        }
    }

    if (empty_list.items.len == 0) {
        std.debug.print("no defragmentation necessary, no empty places\n", .{});
        return 0;
    }

    var fs_checksum: u64 = 0;
    var fs_idx: u64 = 0;
    var empty_idx: u64 = 0;
    var moved_files: u64 = 0;
    file_loop: for (file_list.items, 0..) |file, file_idx| {
        const reverse_idx: u64 = file_list.items.len - moved_files - 1;
        for (0..file.len) |_| {
            fs_checksum += fs_idx * file.id;
            fs_idx += 1;
        }
        if (reverse_idx == file_idx) break;
        var empty_space: u64 = empty_list.items[empty_idx];
        for (0..reverse_idx) |tmp_idx| {
            const file_reverse_idx = reverse_idx - tmp_idx;
            const file_mv = file_list.items[file_reverse_idx];
            if (file_mv.len > empty_space) {
                // move partial file in empty space
                for (0..empty_space) |file_len_idx| {
                    _ = file_len_idx;
                    fs_checksum += fs_idx * file_mv.id;
                    fs_idx += 1;
                }
                file_list.items[file_reverse_idx].len -= empty_space;
                empty_idx += 1;
                continue :file_loop;
            }

            // move whole file into empty space
            for (0..file_mv.len) |_| {
                fs_checksum += fs_idx * file_mv.id;
                fs_idx += 1;
            }
            moved_files += 1;
            empty_space -= file_mv.len;

            if (empty_space == 0) {
                empty_idx += 1;
                continue :file_loop;
            }
        }
    }

    return fs_checksum;
}
