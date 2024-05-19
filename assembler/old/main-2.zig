const std = @import("std");
const print = std.debug.print;

const RTypeInstruction = enum {
    Add,
    Sub,
    Sll,
    Slt,
    Sltu,
    Xor,
    Srl,
    Sra,
    Or,
    And,
};

const ITypeInstruction = enum {
    Addi,
    Slti,
    Sltiu,
    Xori,
    Ori,
    Andi,
    Slli,
    Srli,
    Srai,
    Lb,
    Lh,
    Lw,
    Lbu,
    Lhu,
    Jalr,
};

const STypeInstruction = enum {
    Sb,
    Sh,
    Sw,
};

const BTypeInstruction = enum {
    Beq,
    Bne,
    Blt,
    Bge,
    Bltu,
    Bgeu,
};

const UTypeInstruction = enum {
    Lui,
    Auipc,
};

const JTypeInstruction = enum {
    Jal,
};

const Instruction = union(enum) {
    RType: struct {
        instruction: RTypeInstruction,
        rd: u8,
        rs1: u8,
        rs2: u8,
    },
    IType: struct {
        instruction: ITypeInstruction,
        rd: u8,
        rs1: u8,
        imm: i12,
    },
    SType: struct {
        instruction: STypeInstruction,
        rs1: u8,
        rs2: u8,
        imm: i12,
    },
    BType: struct {
        instruction: BTypeInstruction,
        rs1: u8,
        rs2: u8,
        imm: i12,
    },
    UType: struct {
        instruction: UTypeInstruction,
        rd: u8,
        imm: i32,
    },
    JType: struct {
        instruction: JTypeInstruction,
        rd: u8,
        imm: i32,
    },
    fn encode(self: *const Instruction) !u32 {
        switch (self.*) {
            .RType => |rtype| {
                const opcode: u32 = switch (rtype.instruction) {
                    .Add => 0b0110011,
                    .Sub => 0b0110011,
                    .Sll => 0b0110011,
                    .Slt => 0b0110011,
                    .Sltu => 0b0110011,
                    .Xor => 0b0110011,
                    .Srl => 0b0110011,
                    .Sra => 0b0110011,
                    .Or => 0b0110011,
                    .And => 0b0110011,
                };
                const funct3: u32 = switch (rtype.instruction) {
                    .Add => 0b000,
                    .Sub => 0b000,
                    .Sll => 0b001,
                    .Slt => 0b010,
                    .Sltu => 0b011,
                    .Xor => 0b100,
                    .Srl => 0b101,
                    .Sra => 0b101,
                    .Or => 0b110,
                    .And => 0b111,
                };
                const funct7: u32 = switch (rtype.instruction) {
                    .Add => 0b0000000,
                    .Sub => 0b0100000,
                    .Sll => 0b0000000,
                    .Slt => 0b0000000,
                    .Sltu => 0b0000000,
                    .Xor => 0b0000000,
                    .Srl => 0b0000000,
                    .Sra => 0b0100000,
                    .Or => 0b0000000,
                    .And => 0b0000000,
                };
                return opcode | (@as(u32, rtype.rd) << 7) | (funct3 << 12) | (@as(u32, rtype.rs1) << 15) | (@as(u32, rtype.rs2) << 20) | (funct7 << 25);
            },
            .IType => |itype| {
                const imm_as_u32: u32 = switch (itype.instruction) {
                    .Slli => @as(u32, @as(u12, @bitCast(itype.imm))) & 0x1F,
                    .Srli => @as(u32, @as(u12, @bitCast(itype.imm))) & 0x1F,
                    .Srai => (0b0100000 << 5) | (@as(u32, @as(u12, @bitCast(itype.imm))) & 0x1F),
                    else => @as(u32, @as(u12, @bitCast(itype.imm))) & 0xFFF,
                };
                const opcode: u32 = switch (itype.instruction) {
                    .Addi => 0b0010011,
                    .Slti => 0b0010011,
                    .Sltiu => 0b0010011,
                    .Xori => 0b0010011,
                    .Ori => 0b0010011,
                    .Andi => 0b0010011,
                    .Slli => 0b0010011,
                    .Srli => 0b0010011,
                    .Srai => 0b0010011,
                    .Lb => 0b0000011,
                    .Lh => 0b0000011,
                    .Lw => 0b0000011,
                    .Lbu => 0b0000011,
                    .Lhu => 0b0000011,
                    .Jalr => 0b1100111,
                };
                const funct3: u32 = switch (itype.instruction) {
                    .Addi => 0b000,
                    .Slti => 0b010,
                    .Sltiu => 0b011,
                    .Xori => 0b100,
                    .Ori => 0b110,
                    .Andi => 0b111,
                    .Slli => 0b001,
                    .Srli => 0b101,
                    .Srai => 0b101,
                    .Lb => 0b000,
                    .Lh => 0b001,
                    .Lw => 0b010,
                    .Lbu => 0b100,
                    .Lhu => 0b101,
                    .Jalr => 0b000,
                };
                return opcode | (@as(u32, itype.rd) << 7) | (funct3 << 12) | (@as(u32, itype.rs1) << 15) | (imm_as_u32 << 20);
            },
            .SType => |stype| {
                const imm11_5 = (@as(u32, @as(u12, @bitCast(stype.imm))) & 0xFE0) << 20; // bits [11:5] of the immediate
                const imm4_0 = (@as(u32, @as(u12, @bitCast(stype.imm))) & 0x1F) << 7; // bits [4:0]
                const opcode: u32 = switch (stype.instruction) {
                    .Sb => 0b0100011,
                    .Sh => 0b0100011,
                    .Sw => 0b0100011,
                };
                const funct3: u32 = switch (stype.instruction) {
                    .Sb => 0b000,
                    .Sh => 0b001,
                    .Sw => 0b010,
                };
                return opcode | imm4_0 | (funct3 << 12) | (@as(u32, stype.rs1) << 15) | (@as(u32, stype.rs2) << 20) | imm11_5;
            },
            .BType => |btype| {
                const imm11 = (@as(u32, @as(u12, @bitCast(btype.imm))) & 0x800) << 20; // bit 11 of the immediate
                const imm4_1 = (@as(u32, @as(u12, @bitCast(btype.imm))) & 0x1E) << 7; // bits [4:1] of the immediate
                const imm10_5 = (@as(u32, @as(u12, @bitCast(btype.imm))) & 0x7E0) << 20; // bits [10:5] of the immediate
                const imm12 = (@as(u32, @as(u12, @bitCast(btype.imm))) & 0x1000) << 19; // bit 12 of the immediate
                const opcode: u32 = switch (btype.instruction) {
                    .Beq => 0b1100011,
                    .Bne => 0b1100011,
                    .Blt => 0b1100011,
                    .Bge => 0b1100011,
                    .Bltu => 0b1100011,
                    .Bgeu => 0b1100011,
                };
                const funct3: u32 = switch (btype.instruction) {
                    .Beq => 0b000,
                    .Bne => 0b001,
                    .Blt => 0b100,
                    .Bge => 0b101,
                    .Bltu => 0b110,
                    .Bgeu => 0b111,
                };
                return opcode | imm11 | imm4_1 | (funct3 << 12) | (@as(u32, btype.rs1) << 15) | (@as(u32, btype.rs2) << 20) | imm10_5 | imm12;
            },
            .UType => |utype| {
                const imm31_12 = @as(u32, @bitCast(utype.imm)) << 12 & 0xFFFFF000; // bits [31:12] of the immediate
                const opcode: u32 = switch (utype.instruction) {
                    .Lui => 0b0110111,
                    .Auipc => 0b0010111,
                };
                return opcode | (@as(u32, utype.rd) << 7) | imm31_12;
            },
            .JType => |jtype| {
                const imm20 = (@as(u32, @bitCast(jtype.imm)) & 0x80000) << 11; // bit 20 of the immediate
                const imm10_1 = (@as(u32, @bitCast(jtype.imm)) & 0x7FE) << 20; // bits [10:1] of the immediate
                const imm11 = (@as(u32, @bitCast(jtype.imm)) & 0x100000) >> 9; // bit 11 of the immediate
                const imm19_12 = (@as(u32, @bitCast(jtype.imm)) & 0xFF000) << 1; // bits [19:12] of the immediate
                const opcode: u32 = 0b1101111;
                return opcode | (@as(u32, jtype.rd) << 7) | imm19_12 | imm11 | imm10_1 | imm20;
            },
        }
    }
};

fn splitStringIntoLines(allocator: *const std.mem.Allocator, input: []const u8) ![][]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator.*);
    defer lines.deinit();
    var tokenizer = std.mem.tokenize(u8, input, "\n");
    while (tokenizer.next()) |line| {
        try lines.append(line);
    }
    return lines.toOwnedSlice();
}

pub fn splitStringByWhitespace(allocator: *const std.mem.Allocator, input: []const u8) ![][]const u8 {
    var tokens = std.ArrayList([]const u8).init(allocator.*);
    defer tokens.deinit();
    var tokenizer = std.mem.tokenize(u8, input, " \t\n\r");
    while (tokenizer.next()) |token| {
        try tokens.append(token);
    }
    return tokens.toOwnedSlice();
}

fn assemble(allocator: *const std.mem.Allocator, source: []const u8) !std.ArrayList(u32) {
    const lines = try splitStringIntoLines(allocator, source);
    defer allocator.free(lines);
    var encoded = std.ArrayList(u32).init(allocator.*);
    for (lines) |line| {
        const tokens = try splitStringByWhitespace(allocator, line);
        defer allocator.free(tokens);
        const instruction = try parseInstruction(allocator, tokens);
        try encoded.append(try instruction.encode());
    }
    return encoded;
}

fn createRegMap(allocator: *const std.mem.Allocator) !std.StringHashMap(u8) {
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

fn parseRegister(reg: []const u8, reg_map: *const std.StringHashMap(u8)) !u8 {
    if (reg[0] == 'x') {
        return try std.fmt.parseInt(u8, reg[1..], 10);
    } else {
        return reg_map.get(reg).?;
    }
}

fn matchesAny(input: []const u8, candidates: []const []const u8) bool {
    for (candidates) |candidate| {
        if (std.mem.eql(u8, input, candidate)) {
            return true;
        }
    }
    return false;
}

fn getRTypeInstruction(instruction: []const u8) !RTypeInstruction {
    if (std.mem.eql(u8, instruction, "add")) return RTypeInstruction.Add;
    if (std.mem.eql(u8, instruction, "sub")) return RTypeInstruction.Sub;
    if (std.mem.eql(u8, instruction, "sll")) return RTypeInstruction.Sll;
    if (std.mem.eql(u8, instruction, "slt")) return RTypeInstruction.Slt;
    if (std.mem.eql(u8, instruction, "sltu")) return RTypeInstruction.Sltu;
    if (std.mem.eql(u8, instruction, "xor")) return RTypeInstruction.Xor;
    if (std.mem.eql(u8, instruction, "srl")) return RTypeInstruction.Srl;
    if (std.mem.eql(u8, instruction, "sra")) return RTypeInstruction.Sra;
    if (std.mem.eql(u8, instruction, "or")) return RTypeInstruction.Or;
    if (std.mem.eql(u8, instruction, "and")) return RTypeInstruction.And;
    unreachable;
}

fn getITypeInstruction(instruction: []const u8) !ITypeInstruction {
    if (std.mem.eql(u8, instruction, "addi")) return ITypeInstruction.Addi;
    if (std.mem.eql(u8, instruction, "slti")) return ITypeInstruction.Slti;
    if (std.mem.eql(u8, instruction, "sltiu")) return ITypeInstruction.Sltiu;
    if (std.mem.eql(u8, instruction, "xori")) return ITypeInstruction.Xori;
    if (std.mem.eql(u8, instruction, "ori")) return ITypeInstruction.Ori;
    if (std.mem.eql(u8, instruction, "andi")) return ITypeInstruction.Andi;
    if (std.mem.eql(u8, instruction, "slli")) return ITypeInstruction.Slli;
    if (std.mem.eql(u8, instruction, "srli")) return ITypeInstruction.Srli;
    if (std.mem.eql(u8, instruction, "srai")) return ITypeInstruction.Srai;
    if (std.mem.eql(u8, instruction, "lb")) return ITypeInstruction.Lb;
    if (std.mem.eql(u8, instruction, "lh")) return ITypeInstruction.Lh;
    if (std.mem.eql(u8, instruction, "lw")) return ITypeInstruction.Lw;
    if (std.mem.eql(u8, instruction, "lbu")) return ITypeInstruction.Lbu;
    if (std.mem.eql(u8, instruction, "lhu")) return ITypeInstruction.Lhu;
    if (std.mem.eql(u8, instruction, "jalr")) return ITypeInstruction.Jalr;
    unreachable;
}

fn getSTypeInstruction(instruction: []const u8) !STypeInstruction {
    if (std.mem.eql(u8, instruction, "sb")) return STypeInstruction.Sb;
    if (std.mem.eql(u8, instruction, "sh")) return STypeInstruction.Sh;
    if (std.mem.eql(u8, instruction, "sw")) return STypeInstruction.Sw;
    unreachable;
}

fn getBTypeInstruction(instruction: []const u8) !BTypeInstruction {
    if (std.mem.eql(u8, instruction, "beq")) return BTypeInstruction.Beq;
    if (std.mem.eql(u8, instruction, "bne")) return BTypeInstruction.Bne;
    if (std.mem.eql(u8, instruction, "blt")) return BTypeInstruction.Blt;
    if (std.mem.eql(u8, instruction, "bge")) return BTypeInstruction.Bge;
    if (std.mem.eql(u8, instruction, "bltu")) return BTypeInstruction.Bltu;
    if (std.mem.eql(u8, instruction, "bgeu")) return BTypeInstruction.Bgeu;
    unreachable;
}

fn getUTypeInstruction(instruction: []const u8) !UTypeInstruction {
    if (std.mem.eql(u8, instruction, "lui")) return UTypeInstruction.Lui;
    if (std.mem.eql(u8, instruction, "auipc")) return UTypeInstruction.Auipc;
    unreachable;
}

fn parseInstruction(allocator: *const std.mem.Allocator, tokens: [][]const u8) !Instruction {
    var reg_map = try createRegMap(allocator);
    defer reg_map.deinit();
    const instruction = tokens[0];
    const rtype_instructions = [_][]const u8{ "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and" };
    const itype_instructions = [_][]const u8{ "addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai", "lb", "lh", "lw", "lbu", "lhu", "jalr" };
    const stype_instructions = [_][]const u8{ "sb", "sh", "sw" };
    const btype_instructions = [_][]const u8{ "beq", "bne", "blt", "bge", "bltu", "bgeu" };
    const utype_instructions = [_][]const u8{ "lui", "auipc" };
    if (matchesAny(instruction, &rtype_instructions)) {
        const rd = try parseRegister(tokens[1], &reg_map);
        const rs1 = try parseRegister(tokens[2], &reg_map);
        const rs2 = try parseRegister(tokens[3], &reg_map);
        const rtype_instruction = try getRTypeInstruction(instruction);
        return Instruction{
            .RType = .{
                .instruction = rtype_instruction,
                .rd = rd,
                .rs1 = rs1,
                .rs2 = rs2,
            },
        };
    } else if (matchesAny(instruction, &itype_instructions)) {
        const rd = try parseRegister(tokens[1], &reg_map);
        var imm: i12 = undefined;
        var rs1: u8 = undefined;
        if (std.mem.eql(u8, instruction, "jalr") or std.mem.eql(u8, instruction, "lhu")) {
            var offset_and_rs1 = std.ArrayList([]const u8).init(allocator.*);
            defer offset_and_rs1.deinit();
            var it = std.mem.tokenize(u8, tokens[2], "()");
            while (it.next()) |token| {
                try offset_and_rs1.append(token);
            }
            imm = try std.fmt.parseInt(i12, offset_and_rs1.items[0], 10);
            rs1 = try parseRegister(offset_and_rs1.items[1], &reg_map);
        } else {
            rs1 = try parseRegister(tokens[2], &reg_map);
            imm = try std.fmt.parseInt(i12, tokens[3], 10);
        }
        const itype_instruction = try getITypeInstruction(instruction);
        return Instruction{
            .IType = .{
                .instruction = itype_instruction,
                .rd = rd,
                .rs1 = rs1,
                .imm = imm,
            },
        };
    } else if (matchesAny(instruction, &stype_instructions)) {
        const rs2 = try parseRegister(tokens[1], &reg_map);
        var offset_and_rs1 = std.ArrayList([]const u8).init(allocator.*);
        defer offset_and_rs1.deinit();
        var it = std.mem.tokenize(u8, tokens[2], "()");
        while (it.next()) |token| {
            try offset_and_rs1.append(token);
        }
        const imm = try std.fmt.parseInt(i12, offset_and_rs1.items[0], 10);
        const rs1 = try parseRegister(offset_and_rs1.items[1], &reg_map);
        const stype_instruction = try getSTypeInstruction(instruction);
        return Instruction{
            .SType = .{
                .instruction = stype_instruction,
                .rs1 = rs1,
                .rs2 = rs2,
                .imm = imm,
            },
        };
    } else if (matchesAny(instruction, &btype_instructions)) {
        const rs1 = try parseRegister(tokens[1], &reg_map);
        const rs2 = try parseRegister(tokens[2], &reg_map);
        const imm = try std.fmt.parseInt(i12, tokens[3], 10);
        const btype_instruction = try getBTypeInstruction(instruction);
        return Instruction{
            .BType = .{
                .instruction = btype_instruction,
                .rs1 = rs1,
                .rs2 = rs2,
                .imm = imm,
            },
        };
    } else if (matchesAny(instruction, &utype_instructions)) {
        const rd = try parseRegister(tokens[1], &reg_map);
        const imm = try std.fmt.parseInt(i32, tokens[2], 10);
        const utype_instruction = try getUTypeInstruction(instruction);
        return Instruction{
            .UType = .{
                .instruction = utype_instruction,
                .rd = rd,
                .imm = imm,
            },
        };
    } else if (std.mem.eql(u8, instruction, "jal")) {
        const rd = try parseRegister(tokens[1], &reg_map);
        const imm = try std.fmt.parseInt(i32, tokens[2], 10);
        return Instruction{
            .JType = .{
                .instruction = JTypeInstruction.Jal,
                .rd = rd,
                .imm = imm,
            },
        };
    }
    unreachable;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    arena.deinit();
    const allocator = arena.allocator();
    const source_code =
        \\addi x2 x2 -4
        \\sw x10 0(x2)
    ;
    const machine_code = try assemble(&allocator, source_code[0..]);
    defer machine_code.deinit();
    for (machine_code.items) |code| {
        print("{b:0>32}\n", .{code});
    }
}

test "add" {
    const machine_code = try assemble(&std.testing.allocator, "add ra sp gp");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x3100B3), machine_code.items[0]);
}

test "sub" {
    const machine_code = try assemble(&std.testing.allocator, "sub tp t0 t1");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x40628233), machine_code.items[0]);
}

test "sll" {
    const machine_code = try assemble(&std.testing.allocator, "sll t2 s0 fp");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x8413B3), machine_code.items[0]);
}

test "slt" {
    const machine_code = try assemble(&std.testing.allocator, "slt s1 a0 a1");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0xB524B3), machine_code.items[0]);
}

test "sltu" {
    const machine_code = try assemble(&std.testing.allocator, "sltu a2 a3 a4");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0xE6B633), machine_code.items[0]);
}

test "xor" {
    const machine_code = try assemble(&std.testing.allocator, "xor a5 a6 a7");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x11847B3), machine_code.items[0]);
}

test "srl" {
    const machine_code = try assemble(&std.testing.allocator, "srl s2 s3 s4");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x149D933), machine_code.items[0]);
}

test "sra" {
    const machine_code = try assemble(&std.testing.allocator, "sra s5 s6 s7");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x417B5AB3), machine_code.items[0]);
}

test "or" {
    const machine_code = try assemble(&std.testing.allocator, "or s8 s9 s10");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x1ACEC33), machine_code.items[0]);
}

test "and" {
    const machine_code = try assemble(&std.testing.allocator, "and t3 t4 t5");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x1EEFE33), machine_code.items[0]);
}

test "addi" {
    const machine_code = try assemble(&std.testing.allocator, "addi t6 ra 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x308F93), machine_code.items[0]);
}

test "slti" {
    const machine_code = try assemble(&std.testing.allocator, "slti sp sp 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x312113), machine_code.items[0]);
}

test "sltiu" {
    const machine_code = try assemble(&std.testing.allocator, "sltiu a0 a0 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x353513), machine_code.items[0]);
}

test "xori" {
    const machine_code = try assemble(&std.testing.allocator, "xori a1 a1 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x35C593), machine_code.items[0]);
}

test "ori" {
    const machine_code = try assemble(&std.testing.allocator, "ori a2 a2 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x366613), machine_code.items[0]);
}

test "andi" {
    const machine_code = try assemble(&std.testing.allocator, "andi a3 a3 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x36F693), machine_code.items[0]);
}

test "slli" {
    const machine_code = try assemble(&std.testing.allocator, "slli a4 a4 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x371713), machine_code.items[0]);
}

test "srai" {
    const machine_code = try assemble(&std.testing.allocator, "srai a6 a6 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x40385813), machine_code.items[0]);
}

test "lb" {
    const machine_code = try assemble(&std.testing.allocator, "lb a7 a7 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x388883), machine_code.items[0]);
}

test "lh" {
    const machine_code = try assemble(&std.testing.allocator, "lh s0 s0 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x341403), machine_code.items[0]);
}

test "lw" {
    const machine_code = try assemble(&std.testing.allocator, "lw s1 s1 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x34A483), machine_code.items[0]);
}

test "lbu" {
    const machine_code = try assemble(&std.testing.allocator, "lbu s2 s2 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x394903), machine_code.items[0]);
}

test "lhu" {
    const machine_code = try assemble(&std.testing.allocator, "lhu s3 4(s3)");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x49d983), machine_code.items[0]);
}

test "sb" {
    const machine_code = try assemble(&std.testing.allocator, "sb s4 0(s4)");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x14a0023), machine_code.items[0]);
}

test "sh" {
    const machine_code = try assemble(&std.testing.allocator, "sh s5 2(s5)");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x15a9123), machine_code.items[0]);
}

test "sw" {
    const machine_code = try assemble(&std.testing.allocator, "sw s6 3(s6)");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x16b21a3), machine_code.items[0]);
}

test "beq" {
    const machine_code = try assemble(&std.testing.allocator, "beq s7 s7 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x17b8163), machine_code.items[0]);
}

test "bne" {
    const machine_code = try assemble(&std.testing.allocator, "bne t0 t0 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x529163), machine_code.items[0]);
}

test "blt" {
    const machine_code = try assemble(&std.testing.allocator, "blt t1 t1 4");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x634263), machine_code.items[0]);
}

test "bge" {
    const machine_code = try assemble(&std.testing.allocator, "bge t2 t2 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x73d163), machine_code.items[0]);
}

test "bltu" {
    const machine_code = try assemble(&std.testing.allocator, "bltu t3 t3 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x1ce6163), machine_code.items[0]);
}

test "bgeu" {
    const machine_code = try assemble(&std.testing.allocator, "bgeu t4 t4 2");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x1def163), machine_code.items[0]);
}

test "lui" {
    const machine_code = try assemble(&std.testing.allocator, "lui t5 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x3f37), machine_code.items[0]);
}

test "auipc" {
    const machine_code = try assemble(&std.testing.allocator, "auipc t6 3");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x3f97), machine_code.items[0]);
}

test "jal" {
    const machine_code = try assemble(&std.testing.allocator, "jal ra 0");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0xef), machine_code.items[0]);
}

test "jalr" {
    const machine_code = try assemble(&std.testing.allocator, "jalr sp 3(sp)");
    defer machine_code.deinit();
    try std.testing.expectEqual(@as(u32, 0x310167), machine_code.items[0]);
}
