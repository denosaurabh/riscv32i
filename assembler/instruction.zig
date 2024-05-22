// CREDIT: https://www.fromthetransistor.com
const std = @import("std");
const registry = @import("registry.zig");
const utils = @import("utils.zig");

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

const ECALLTypeFunct3 = enum {
    Print,
};

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

fn getECallTypeFunct3(instruction: []const u8) !ECALLTypeFunct3 {
    if (std.mem.eql(u8, instruction, "print")) return ECALLTypeFunct3.Print;
    unreachable;
}

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
    ECALLType: struct {
        funct3: ECALLTypeFunct3,
        rd: u8,
        rs1: u8,
    },
    pub fn encode(self: *const Instruction) !u32 {
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
                const imm_u32 = @as(u32, @as(u12, @bitCast(btype.imm)));
                // const imm_u32 = @as(u32, @bitCast(@as(i32, @intCast(btype.imm)))); // <- this worked slightly better
                const imm11 = (imm_u32 & 0x800) << 20; // bit 11 of the immediate
                const imm4_1 = (imm_u32 & 0x1E) << 7; // bits [4:1] of the immediate
                const imm10_5 = (imm_u32 & 0x7E0) << 20; // bits [10:5] of the immediate
                const imm12 = (imm_u32 & 0x1000) << 19; // bit 12 of the immediate
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

                // print("imm[raw]:            {d}\n", .{btype.imm});
                // print("imm[i32]:            {d}\n", .{@as(i32, @intCast(btype.imm))});
                // print("imm[u32]:            {d}\n", .{@as(u32, @bitCast(@as(i32, @intCast(btype.imm))))});

                // print("imm                  {b:032}\n", .{imm_u32});
                // print("opcode:              {b:032}\n", .{opcode});
                // print("imm11:               {b:032}\n", .{imm11});
                // print("imm4_1:              {b:032}\n", .{imm4_1});
                // print("imm10_5:             {b:032}\n", .{imm10_5});
                // print("imm12:               {b:032}\n", .{imm12});

                // print("o|11:                {b:032}\n", .{opcode | imm11});
                // print("o|11|4_1:            {b:032}\n", .{opcode | imm11 | imm4_1});
                // print("o|11|4_1:            {b:032}\n", .{opcode | imm11 | imm4_1});
                // print("o|11|4_1|10_5|12:    {b:032}\n", .{opcode | imm11 | imm4_1 | imm10_5 | imm12});

                // print("res                  {b:032}\n", .{opcode | imm11 | imm4_1 | (funct3 << 12) | (@as(u32, btype.rs1) << 15) | (@as(u32, btype.rs2) << 20) | imm10_5 | imm12});

                var result = opcode | imm11 | imm4_1 | (funct3 << 12) | (@as(u32, btype.rs1) << 15) | (@as(u32, btype.rs2) << 20) | imm10_5 | imm12;

                // TODO: HACK to fix the issue with the immediate value when negative
                if (@as(i12, @bitCast(btype.imm)) < 0) { // if negative
                    result |= (1 << 7); // convert 8th (imm11) bit to 1
                }

                return result;
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
                // const imm = @as(u32, @bitCast(jtype.imm));
                // const imm20 = (imm & 0x80000) << 11; // bit 20 of the immediate
                // const imm10_1 = (imm & 0x7FE) << 20; // bits [10:1] of the immediate
                // const imm11 = (imm & 0x100000) >> 9; // bit 11 of the immediate
                // const imm19_12 = (imm & 0xFF000) << 1; // bits [19:12] of the immediate
                // const opcode: u32 = 0b1101111;
                // return opcode | (@as(u32, jtype.rd) << 7) | imm19_12 | imm11 | imm10_1 | imm20;

                // WAY: 2
                // const imm = jtype.imm;
                const imm = @as(u32, @bitCast(jtype.imm));
                const imm20 = (@as(u32, imm) & 0x100000) >> 20; // bit 20 to bit 31
                const imm10_1 = (@as(u32, imm) & 0x7FE) << 20; // bits [10:1] to bits [30:21]
                const imm11 = (@as(u32, imm) & 0x800) << 9; // bit 11 to bit 20
                const imm19_12 = (@as(u32, imm) & 0xFF000); // bits [19:12] to bits [19:12]
                const imm_combined = (imm20 << 31) | imm10_1 | imm11 | imm19_12;

                // Opcode for JAL
                const opcode: u32 = 0b1101111;

                // Combine the opcode, rd, and the immediate parts
                return opcode | (@as(u32, jtype.rd) << 7) | imm_combined;
            },
            .ECALLType => |ecalltype| {
                const imm_as_u32: u32 = 0b000000000000; // 12-bit
                const opcode: u32 = 0b1110011;
                const funct3: u32 = switch (ecalltype.funct3) {
                    .Print => 0b000,
                };
                return opcode | (@as(u32, ecalltype.rd) << 7) | (funct3 << 12) | (@as(u32, ecalltype.rs1) << 15) | (imm_as_u32 << 20);
            },
        }
    }
};

const ParseInstructionError = error{
    InvalidOrUnsupportedInstruction,
};

pub fn parseInstruction(allocator: *const std.mem.Allocator, tokens: [][]const u8) !Instruction {
    // print("tokens[0]: {s}\n", .{tokens[0]});
    // print("tokens[1]: {s}\n", .{tokens[1]});
    // print("tokens[2]: {s}\n", .{tokens[2]});
    // print("tokens[3]: {s}\n", .{tokens[3]});

    var reg_map = try registry.createRegMap(allocator);
    defer reg_map.deinit();
    const instruction = tokens[0];
    const rtype_instructions = [_][]const u8{ "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and" };
    const itype_instructions = [_][]const u8{ "addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai", "lb", "lh", "lw", "lbu", "lhu", "jalr" };
    const stype_instructions = [_][]const u8{ "sb", "sh", "sw" };
    const btype_instructions = [_][]const u8{ "beq", "bne", "blt", "bge", "bltu", "bgeu" };
    const utype_instructions = [_][]const u8{ "lui", "auipc" };
    if (utils.matchesAny(instruction, &rtype_instructions)) {
        const rd = try registry.parseRegister(tokens[1], &reg_map);
        const rs1 = try registry.parseRegister(tokens[2], &reg_map);
        const rs2 = try registry.parseRegister(tokens[3], &reg_map);
        const rtype_instruction = try getRTypeInstruction(instruction);
        return Instruction{
            .RType = .{
                .instruction = rtype_instruction,
                .rd = rd,
                .rs1 = rs1,
                .rs2 = rs2,
            },
        };
    } else if (utils.matchesAny(instruction, &itype_instructions)) {
        const rd = try registry.parseRegister(tokens[1], &reg_map);
        var imm: i12 = undefined;
        var rs1: u8 = undefined;
        if (std.mem.eql(u8, instruction, "jalr") or std.mem.eql(u8, instruction, "lhu")) {
            var offset_and_rs1 = std.ArrayList([]const u8).init(allocator.*);
            defer offset_and_rs1.deinit();
            var it = std.mem.tokenize(u8, tokens[2], "()");
            while (it.next()) |token| {
                try offset_and_rs1.append(token);
            }
            imm = try parseInt(i12, offset_and_rs1.items[0]);
            rs1 = try registry.parseRegister(offset_and_rs1.items[1], &reg_map);
        } else {
            rs1 = try registry.parseRegister(tokens[2], &reg_map);
            imm = try parseInt(i12, tokens[3]);
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
    } else if (utils.matchesAny(instruction, &stype_instructions)) {
        const rs2 = try registry.parseRegister(tokens[1], &reg_map);
        var offset_and_rs1 = std.ArrayList([]const u8).init(allocator.*);
        defer offset_and_rs1.deinit();
        var it = std.mem.tokenize(u8, tokens[2], "()");
        while (it.next()) |token| {
            try offset_and_rs1.append(token);
        }
        const imm = try parseInt(i12, offset_and_rs1.items[0]);
        const rs1 = try registry.parseRegister(offset_and_rs1.items[1], &reg_map);
        const stype_instruction = try getSTypeInstruction(instruction);
        return Instruction{
            .SType = .{
                .instruction = stype_instruction,
                .rs1 = rs1,
                .rs2 = rs2,
                .imm = imm,
            },
        };
    } else if (utils.matchesAny(instruction, &btype_instructions)) {
        const rs1 = try registry.parseRegister(tokens[1], &reg_map);
        const rs2 = try registry.parseRegister(tokens[2], &reg_map);
        const imm = try parseInt(i12, tokens[3]);
        const btype_instruction = try getBTypeInstruction(instruction);
        return Instruction{
            .BType = .{
                .instruction = btype_instruction,
                .rs1 = rs1,
                .rs2 = rs2,
                .imm = imm,
            },
        };
    } else if (utils.matchesAny(instruction, &utype_instructions)) {
        const rd = try registry.parseRegister(tokens[1], &reg_map);
        const imm = try parseInt(i32, tokens[2]);
        const utype_instruction = try getUTypeInstruction(instruction);
        return Instruction{
            .UType = .{
                .instruction = utype_instruction,
                .rd = rd,
                .imm = imm,
            },
        };
    } else if (std.mem.eql(u8, instruction, "jal")) {
        const rd = try registry.parseRegister(tokens[1], &reg_map);
        const imm = try parseInt(i32, tokens[2]);
        return Instruction{
            .JType = .{
                .instruction = JTypeInstruction.Jal,
                .rd = rd,
                .imm = imm,
            },
        };
    } else if (std.mem.eql(u8, instruction, "ecall")) {
        const rd = try registry.parseRegister(tokens[2], &reg_map);
        // const rs1 = try registry.parseRegister(tokens[3], &reg_map);
        const rs1: u8 = 0b00000; // 5-bit

        return Instruction{
            .ECALLType = .{
                .funct3 = ECALLTypeFunct3.Print,
                .rs1 = rs1,
                .rd = rd,
            },
        };
    }

    print("INSTRUCTION '{s}'' is either invalid or unsupported instruction", .{instruction});

    return ParseInstructionError.InvalidOrUnsupportedInstruction;
    // unreachable;
}

pub fn parseInt(comptime T: type, buf: []const u8) !T {
    if (buf.len > 2 and buf[0] == '0' and (buf[1] == 'x' or buf[1] == 'X')) {
        // Hexadecimal string
        return std.fmt.parseInt(T, buf[2..], 16);
    } else {
        // Decimal string
        return std.fmt.parseInt(T, buf, 10);
    }
}
