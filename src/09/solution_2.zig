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

const File = struct { id: u64, len: u64, idx: u64, checksum: u64 };
const Empty = struct { len: u64, idx: u64 };
const Field = enum { file, empty };
const TaggedField = union(Field) { file: File, empty: Empty };
pub fn defragment_filesystem_block_checksum(allocator: std.mem.Allocator, input: []const u8) !u64 {
    const line_end_idx = std.mem.indexOfScalar(u8, input, '\n') orelse 0;
    if (line_end_idx == 0) return 0;
    var list = std.ArrayList(TaggedField).init(allocator);
    defer list.deinit();
    var fs_idx: u64 = 0;
    for (0..line_end_idx) |idx| {
        const is_file_len = idx % 2 == 0;
        const len: u64 = input[idx] - '0';
        if (is_file_len) {
            const file_id: u64 = idx / 2;
            const checksum = file_get_checksum(file_id, len, fs_idx);
            try list.append(.{ .file = .{ .id = file_id, .len = len, .idx = fs_idx, .checksum = checksum } });
        } else {
            try list.append(.{ .empty = .{ .idx = fs_idx, .len = len } });
        }
        fs_idx += len;
    }

    if (list.items.len == 0) {
        std.debug.print("no defragmentation necessary, no empty places\n", .{});
        return 0;
    }

    var file_idx: u64 = list.items.len - 1;
    var empty_idx: u64 = 1;
    while (true) {
        if (file_idx == 0) {
            break;
        }
        if (empty_idx > file_idx) {
            empty_idx = 1;
            file_idx -= 2;
            continue;
        }

        const file = list.items[file_idx].file;
        const empty = list.items[empty_idx].empty;
        if (empty.len < file.len) {
            empty_idx += 2;
            continue;
        }

        list.items[file_idx].file.checksum = file_get_checksum(file.id, file.len, empty.idx);
        list.items[file_idx].file.idx = empty.idx;

        list.items[empty_idx].empty.idx += file.len;
        list.items[empty_idx].empty.len -= file.len;
        empty_idx = 1;
        file_idx -= 2;
    }

    var fs_checksum: u64 = 0;
    for (list.items) |item| {
        switch (item) {
            .file => |*file| {
                fs_checksum += file.*.checksum;
            },
            else => {},
        }
    }
    //try print_tagged_fields(allocator, list.items);
    return fs_checksum;
}

pub fn file_get_checksum(id: u64, len: u64, idx: u64) u64 {
    var checksum: u64 = 0;
    for (idx..idx + len) |mul| {
        checksum += id * mul;
    }
    return checksum;
}

pub fn print_tagged_fields(allocator: std.mem.Allocator, list: []const TaggedField) !void {
    var files = std.ArrayList(File).init(allocator);
    defer files.deinit();
    for (list) |item| {
        switch (item) {
            .file => |*file| {
                try files.append(file.*);
            },
            else => {},
        }
    }
    std.mem.sort(File, files.items, {}, file_compare_idx_asc);

    var prev_end_idx: u64 = 0;
    for (files.items) |file| {
        for (prev_end_idx..file.idx) |idx| {
            std.debug.print("{any} -> empty\n", .{idx});
        }
        for (file.idx..file.idx + file.len) |idx| {
            std.debug.print("{any} -> {any}\n", .{ idx, file.id });
        }
        prev_end_idx = file.idx + file.len;
    }
}

pub fn file_compare_idx_asc(context: void, a: File, b: File) bool {
    _ = context;
    return a.idx < b.idx;
}
