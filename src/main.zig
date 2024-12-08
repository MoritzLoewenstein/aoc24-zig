const std = @import("std");
pub const solution_01_1 = @import("01/solution_1.zig");
pub const solution_01_2 = @import("01/solution_2.zig");
pub const solution_02_1 = @import("02/solution_1.zig");
pub const solution_02_2 = @import("02/solution_2.zig");
pub const solution_03_1 = @import("03/solution_1.zig");
pub const solution_03_2 = @import("03/solution_2.zig");
pub const solution_04_1 = @import("04/solution_1.zig");
pub const solution_04_2 = @import("04/solution_2.zig");
pub const solution_05_1 = @import("05/solution_1.zig");
pub const solution_05_2 = @import("05/solution_2.zig");
pub const solution_06_1 = @import("06/solution_1.zig");
pub const solution_06_2 = @import("06/solution_2.zig");
pub const solution_07_1 = @import("07/solution_1.zig");
pub const solution_07_2 = @import("07/solution_2.zig");

test {
    std.testing.refAllDecls(@This());
}
