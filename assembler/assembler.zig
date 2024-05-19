const std = @import("std");
const instruction = @import("instruction.zig");

const print = std.debug.print;

pub fn assemble(allocator: *const std.mem.Allocator, line: []const u8) !u32 {
    const delimiter = " ";
    var iterator = std.mem.split(u8, line, delimiter);

    var tokens = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer tokens.deinit();

    // var iterator = std.mem.split(u8, line, delimiter);
    while (iterator.next()) |token| {
        try tokens.append(token);
    }

    const res = instruction.parseInstruction(allocator, tokens.items) catch |err| {
        // Handle the error
        std.log.err("Error parsing instruction: {}", .{err});
        return err;
    };

    const binary_output = try res.encode();
    return binary_output;
}
