const std = @import("std");

pub fn matchesAny(input: []const u8, candidates: []const []const u8) bool {
    for (candidates) |candidate| {
        if (std.mem.eql(u8, input, candidate)) {
            return true;
        }
    }
    return false;
}
