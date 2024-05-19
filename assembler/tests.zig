const std = @import("std");
const assembler = @import("assembler.zig");

const assemble = assembler.assemble;

test "add" {
    const machine_code = try assemble(&std.testing.allocator, "add ra sp gp");

    try std.testing.expectEqual(@as(u32, 0x3100B3), machine_code);
}

test "sub" {
    const machine_code = try assemble(&std.testing.allocator, "sub tp t0 t1");

    try std.testing.expectEqual(@as(u32, 0x40628233), machine_code);
}

test "sll" {
    const machine_code = try assemble(&std.testing.allocator, "sll t2 s0 fp");

    try std.testing.expectEqual(@as(u32, 0x8413B3), machine_code);
}

test "slt" {
    const machine_code = try assemble(&std.testing.allocator, "slt s1 a0 a1");

    try std.testing.expectEqual(@as(u32, 0xB524B3), machine_code);
}

test "sltu" {
    const machine_code = try assemble(&std.testing.allocator, "sltu a2 a3 a4");

    try std.testing.expectEqual(@as(u32, 0xE6B633), machine_code);
}

test "xor" {
    const machine_code = try assemble(&std.testing.allocator, "xor a5 a6 a7");

    try std.testing.expectEqual(@as(u32, 0x11847B3), machine_code);
}

test "srl" {
    const machine_code = try assemble(&std.testing.allocator, "srl s2 s3 s4");

    try std.testing.expectEqual(@as(u32, 0x149D933), machine_code);
}

test "sra" {
    const machine_code = try assemble(&std.testing.allocator, "sra s5 s6 s7");

    try std.testing.expectEqual(@as(u32, 0x417B5AB3), machine_code);
}

test "or" {
    const machine_code = try assemble(&std.testing.allocator, "or s8 s9 s10");

    try std.testing.expectEqual(@as(u32, 0x1ACEC33), machine_code);
}

test "and" {
    const machine_code = try assemble(&std.testing.allocator, "and t3 t4 t5");

    try std.testing.expectEqual(@as(u32, 0x1EEFE33), machine_code);
}

test "addi" {
    const machine_code = try assemble(&std.testing.allocator, "addi t6 ra 3");

    try std.testing.expectEqual(@as(u32, 0x308F93), machine_code);
}

test "slti" {
    const machine_code = try assemble(&std.testing.allocator, "slti sp sp 3");

    try std.testing.expectEqual(@as(u32, 0x312113), machine_code);
}

test "sltiu" {
    const machine_code = try assemble(&std.testing.allocator, "sltiu a0 a0 3");

    try std.testing.expectEqual(@as(u32, 0x353513), machine_code);
}

test "xori" {
    const machine_code = try assemble(&std.testing.allocator, "xori a1 a1 3");

    try std.testing.expectEqual(@as(u32, 0x35C593), machine_code);
}

test "ori" {
    const machine_code = try assemble(&std.testing.allocator, "ori a2 a2 3");

    try std.testing.expectEqual(@as(u32, 0x366613), machine_code);
}

test "andi" {
    const machine_code = try assemble(&std.testing.allocator, "andi a3 a3 3");

    try std.testing.expectEqual(@as(u32, 0x36F693), machine_code);
}

test "slli" {
    const machine_code = try assemble(&std.testing.allocator, "slli a4 a4 3");

    try std.testing.expectEqual(@as(u32, 0x371713), machine_code);
}

test "srai" {
    const machine_code = try assemble(&std.testing.allocator, "srai a6 a6 3");

    try std.testing.expectEqual(@as(u32, 0x40385813), machine_code);
}

test "lb" {
    const machine_code = try assemble(&std.testing.allocator, "lb a7 a7 3");

    try std.testing.expectEqual(@as(u32, 0x388883), machine_code);
}

test "lh" {
    const machine_code = try assemble(&std.testing.allocator, "lh s0 s0 3");

    try std.testing.expectEqual(@as(u32, 0x341403), machine_code);
}

test "lw" {
    const machine_code = try assemble(&std.testing.allocator, "lw s1 s1 3");

    try std.testing.expectEqual(@as(u32, 0x34A483), machine_code);
}

test "lbu" {
    const machine_code = try assemble(&std.testing.allocator, "lbu s2 s2 3");

    try std.testing.expectEqual(@as(u32, 0x394903), machine_code);
}

test "lhu" {
    const machine_code = try assemble(&std.testing.allocator, "lhu s3 4(s3)");

    try std.testing.expectEqual(@as(u32, 0x49d983), machine_code);
}

test "sb" {
    const machine_code = try assemble(&std.testing.allocator, "sb s4 0(s4)");

    try std.testing.expectEqual(@as(u32, 0x14a0023), machine_code);
}

test "sh" {
    const machine_code = try assemble(&std.testing.allocator, "sh s5 2(s5)");

    try std.testing.expectEqual(@as(u32, 0x15a9123), machine_code);
}

test "sw" {
    const machine_code = try assemble(&std.testing.allocator, "sw s6 3(s6)");

    try std.testing.expectEqual(@as(u32, 0x16b21a3), machine_code);
}

test "beq" {
    const machine_code = try assemble(&std.testing.allocator, "beq s7 s7 3");

    try std.testing.expectEqual(@as(u32, 0x17b8163), machine_code);
}

test "bne" {
    const machine_code = try assemble(&std.testing.allocator, "bne t0 t0 3");

    try std.testing.expectEqual(@as(u32, 0x529163), machine_code);
}

test "blt" {
    const machine_code = try assemble(&std.testing.allocator, "blt t1 t1 4");

    try std.testing.expectEqual(@as(u32, 0x634263), machine_code);
}

test "bge" {
    const machine_code = try assemble(&std.testing.allocator, "bge t2 t2 3");

    try std.testing.expectEqual(@as(u32, 0x73d163), machine_code);
}

test "bltu" {
    const machine_code = try assemble(&std.testing.allocator, "bltu t3 t3 3");

    try std.testing.expectEqual(@as(u32, 0x1ce6163), machine_code);
}

test "bgeu" {
    const machine_code = try assemble(&std.testing.allocator, "bgeu t4 t4 2");

    try std.testing.expectEqual(@as(u32, 0x1def163), machine_code);
}

test "lui" {
    const machine_code = try assemble(&std.testing.allocator, "lui t5 3");

    try std.testing.expectEqual(@as(u32, 0x3f37), machine_code);
}

test "auipc" {
    const machine_code = try assemble(&std.testing.allocator, "auipc t6 3");

    try std.testing.expectEqual(@as(u32, 0x3f97), machine_code);
}

test "jal" {
    const machine_code = try assemble(&std.testing.allocator, "jal ra 0");

    try std.testing.expectEqual(@as(u32, 0xef), machine_code);
}

test "jalr" {
    const machine_code = try assemble(&std.testing.allocator, "jalr sp 3(sp)");

    try std.testing.expectEqual(@as(u32, 0x310167), machine_code);
}
