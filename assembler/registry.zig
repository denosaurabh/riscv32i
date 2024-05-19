const std = @import("std");

pub fn createRegMap(allocator: *const std.mem.Allocator) !std.StringHashMap(u8) {
    const reg_names = [_][]const u8{
        "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2",  "a3",
        "a4",   "a5", "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11",
        "t3",   "t4", "t5", "t6",
    };
    var map = std.StringHashMap(u8).init(allocator.*);
    for (reg_names, 0..) |name, index| {
        try map.put(name, @as(u8, @intCast(index)));
    }
    try map.put("fp", 8);
    return map;
}

pub fn parseRegister(reg: []const u8, reg_map: *const std.StringHashMap(u8)) !u8 {
    if (reg[0] == 'x') {
        return try std.fmt.parseInt(u8, reg[1..], 10);
    } else {
        return reg_map.get(reg).?;
    }
}
