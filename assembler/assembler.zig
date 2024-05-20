const std = @import("std");
const instruction = @import("instruction.zig");

const print = std.debug.print;

pub fn assemble(allocator: *const std.mem.Allocator, tokens: [][]const u8) !u32 {
    const res = instruction.parseInstruction(allocator, tokens) catch |err| {
        // Handle the error
        std.log.err("Error parsing instruction: {}", .{err});
        return err;
    };

    const binary_output = try res.encode();
    return binary_output;
}
