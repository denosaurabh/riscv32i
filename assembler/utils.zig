const std = @import("std");

pub fn matchesAny(input: []const u8, candidates: []const []const u8) bool {
    for (candidates) |candidate| {
        if (std.mem.eql(u8, input, candidate)) {
            return true;
        }
    }
    return false;
}

pub fn splitIntoTokens(allocator: std.mem.Allocator, value: []const u8) ![][]const u8 {
    const instr_delimiter = " ";
    var instr_iterator = std.mem.split(u8, value, instr_delimiter);

    var tokens = std.ArrayList([]const u8).init(allocator);
    // defer tokens.deinit();

    while (instr_iterator.next()) |token| {
        try tokens.append(token);
    }

    const token_items = tokens.items;

    return token_items;
}
