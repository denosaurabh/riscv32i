const std = @import("std");

pub const ExpandMacrosReturn = struct {
    has_multiple_instructions: bool,
    instructions: [][][]const u8,
};

pub fn expand_macros(allocator: std.mem.Allocator, tokens: [][]const u8) !ExpandMacrosReturn {
    const instruction = tokens[0];

    if (eql(instruction, "li")) {
        const reg = tokens[1];
        const imm = tokens[2];
        const immediate = try std.fmt.parseInt(i32, imm, 10);

        return ExpandMacrosReturn{ .has_multiple_instructions = true, .instructions = try convertLiToLuiAddi(immediate, reg, allocator) };
    } else if (eql(instruction, "j")) {
        const target = tokens[1];

        var instructions = try allocator.alloc([][]const u8, 1);
        instructions[0] = try allocator.alloc([]const u8, 3);

        instructions[0][0] = "jal";
        instructions[0][1] = "ra";
        instructions[0][2] = target;

        return ExpandMacrosReturn{ .has_multiple_instructions = true, .instructions = instructions };
    } else if (eql(instruction, "ret")) {
        var instructions = try allocator.alloc([][]const u8, 1);
        instructions[0] = try allocator.alloc([]const u8, 3);

        instructions[0][0] = "jalr";
        instructions[0][1] = "x0";
        instructions[0][2] = "0(ra)";

        return ExpandMacrosReturn{ .has_multiple_instructions = true, .instructions = instructions };
    } else if (eql(instruction, "nop")) {
        var instructions = try allocator.alloc([][]const u8, 1);
        instructions[0] = try allocator.alloc([]const u8, 4);

        instructions[0][0] = "addi";
        instructions[0][1] = "x0";
        instructions[0][2] = "x0";
        instructions[0][3] = "0";

        return ExpandMacrosReturn{ .has_multiple_instructions = true, .instructions = instructions };
    } else if (eql(instruction, "mv")) {
        const dest = tokens[1];
        const src = tokens[2];

        var instructions = try allocator.alloc([][]const u8, 1);
        instructions[0] = try allocator.alloc([]const u8, 4);

        instructions[0][0] = "addi";
        instructions[0][1] = dest;
        instructions[0][2] = src;
        instructions[0][3] = "0";

        return ExpandMacrosReturn{ .has_multiple_instructions = true, .instructions = instructions };
    } else if (eql(instruction, "call")) {
        const target = tokens[1];

        var instructions = try allocator.alloc([][]const u8, 1);

        // !IMPORTANT: only will work if function is within ±1 MiB of the call site, (otherwise use `li` + `addi` + `jalr` instead)
        // thankfully, in our case, RAM ain't that big (1kb right now)
        instructions[0] = try allocator.alloc([]const u8, 3);
        instructions[0][0] = "jal";
        instructions[0][1] = "ra";
        instructions[0][2] = target;

        return ExpandMacrosReturn{ .has_multiple_instructions = true, .instructions = instructions };
    }

    const empty_3d_array: [][][]const u8 = &[_][][]const u8{};
    return ExpandMacrosReturn{ .has_multiple_instructions = false, .instructions = empty_3d_array };
}

fn convertLiToLuiAddi(immediate: i32, reg: []const u8, allocator: std.mem.Allocator) ![][][]const u8 {
    const imm = if (immediate < 0) @as(i64, immediate) + (1 << 32) else @as(i64, immediate);

    const upper_20 = @as(u32, @truncate(@as(u64, @bitCast(imm + (1 << 11))))) >> 12;
    const lower_12 = @as(u32, @truncate(@as(u64, @bitCast(imm)))) & 0xfff;

    const adjusted_lower_12 = if ((lower_12 & 0x800) != 0) @as(i32, @bitCast(lower_12)) - (1 << 12) else @as(i32, @bitCast(lower_12));
    const adjusted_upper_20 = if ((lower_12 & 0x800) != 0) upper_20 + 1 else upper_20;

    var instructions = try allocator.alloc([][]const u8, 2);

    instructions[0] = try allocator.alloc([]const u8, 3);
    instructions[0][0] = "lui";
    instructions[0][1] = reg;
    instructions[0][2] = try std.fmt.allocPrint(allocator, "{}", .{adjusted_upper_20});

    instructions[1] = try allocator.alloc([]const u8, 4);
    instructions[1][0] = "addi";
    instructions[1][1] = reg;
    instructions[1][2] = reg;
    instructions[1][3] = try std.fmt.allocPrint(allocator, "{}", .{adjusted_lower_12});

    return instructions;
}

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
