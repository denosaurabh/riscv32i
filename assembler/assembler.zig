const std = @import("std");
const instruction = @import("instruction.zig");

const print = std.debug.print;

pub fn assemble(allocator: *const std.mem.Allocator, tokens: [][]const u8) ![]u8 {
    const res = instruction.parseInstruction(allocator, tokens) catch |err| {
        // Handle the error
        std.log.err("Error parsing instruction: {}", .{err});
        return err;
    };

    const assemble_output = try res.encode();

    var binary_output = try std.fmt.allocPrint(std.heap.page_allocator, "{b}", .{assemble_output});
    while (binary_output.len < 32) { // Append '0' characters until the length is 32
        binary_output = try std.fmt.allocPrint(std.heap.page_allocator, "0{s}", .{binary_output});
    }

    return binary_output;
}
