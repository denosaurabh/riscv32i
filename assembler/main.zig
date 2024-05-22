const std = @import("std");
const assembler = @import("assembler.zig");
const instr_macros = @import("macros.zig");
const utils = @import("utils.zig");
const tests = @import("tests.zig");

const print = std.debug.print;

const MainErrors = error{MultipleGlobalsDefined};

const AssembleFunction = struct {
    name: []const u8,
    starts_at: u32,
};

pub fn main() !void {
    const assemly_path = "src/assembly.asm";
    const output_path = "src/output.bin";

    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // read file
    const file_contents_or_error = std.fs.cwd().readFileAlloc(allocator, assemly_path, std.math.maxInt(usize));
    defer if (file_contents_or_error) |file_contents| {
        allocator.free(file_contents);
    } else |_| {};

    if (file_contents_or_error) |file_contents| {
        const delimiter = "\n";
        var iterator = std.mem.split(u8, file_contents, delimiter);

        ////////////////////////////////////////////
        ////////////////////////////////////////////
        ////////////////////////////////////////////
        //// STATE

        var instruction_index: u32 = 0;

        var global_function: []const u8 = "";
        var functions_list = std.ArrayList(AssembleFunction).init(allocator);
        defer functions_list.deinit();

        ////////////////////////////////////////////
        ////////////////////////////////////////////
        ////////////////////////////////////////////
        const function_reference_type_instructions = [_][]const u8{ "jal", "beq", "bne", "blt", "bge", "bltu", "bgeu" };

        // ALL INSTRUCTIONS STORAGE
        var instructions = std.ArrayList([]const u8).init(allocator);

        while (iterator.next()) |file_line| {
            // trim line
            const trimmed_line = std.mem.trim(u8, file_line, " ");

            // skip empty lines
            if (trimmed_line.len == 0) {
                continue;
            }

            // remove comments
            const comment_token = "#";
            const comment_index = std.mem.indexOf(u8, trimmed_line, comment_token);
            const line = if (comment_index) |index| trimmed_line[0..index] else trimmed_line;
            if (line.len == 0) {
                continue;
            }

            //////////////////////////////////////////
            //////////////////////////////////////////
            // ASSMEBLE

            // GLOBAL FUNCTION DEFINITION
            const GLOBAL_KEYWORD = ".globl ";
            if (std.mem.startsWith(u8, line, GLOBAL_KEYWORD)) {
                const global_fn_name = line[(GLOBAL_KEYWORD.len)..];

                print("GLOBAL: {s}\n", .{global_fn_name});

                if (global_function.len != 0) {
                    print("GLOBAL FUNCTION ALREADY DEFINED: {s}\n", .{global_function});
                    return MainErrors.MultipleGlobalsDefined;
                }

                global_function = global_fn_name;
            } else if (std.mem.endsWith(u8, line, ":")) {
                const fn_name = line[0..(line.len - 1)];

                print("FN: {s}\n", .{fn_name});

                try functions_list.append(AssembleFunction{
                    .name = fn_name,
                    .starts_at = instruction_index,
                });
            } else {
                print("{d} [ASSEMBLE] {s}\n", .{ instruction_index, line });

                // check for macros & expand them

                // remove any commas
                const size = std.mem.replacementSize(u8, line, ",", "");
                const removed_commas_line = try allocator.alloc(u8, size);
                _ = std.mem.replace(u8, line, ",", "", removed_commas_line);

                // split the line into tokens
                const tokens = try utils.splitIntoTokens(allocator, removed_commas_line);

                // check instructions that refer a function
                if (utils.matchesAny(tokens[0], &function_reference_type_instructions)) {
                    instruction_index += 1;
                    try instructions.append(removed_commas_line);
                } else {
                    const macros_return = try instr_macros.expand_macros(allocator, tokens);

                    if (macros_return.has_multiple_instructions) {
                        for (macros_return.instructions) |instr| {
                            if (utils.matchesAny(instr[0], &function_reference_type_instructions)) {
                                try instructions.append(try combineTokens(allocator, instr));
                            } else {
                                const assemble_output = try assembler.assemble(&allocator, instr);
                                try instructions.append(assemble_output);
                            }

                            instruction_index += 1;

                            // const assemble_output = try assembler.assemble(&allocator, instr);
                            // try instructions.append(assemble_output);
                            // instruction_index += 1;
                        }
                    } else {
                        instruction_index += 1;

                        const assemble_output = try assembler.assemble(&allocator, tokens);
                        try instructions.append(assemble_output);
                    }

                    // const assemble_output = try assembler.assemble(&allocator, tokens);
                    // try instructions.append(assemble_output);
                }
            }
        }

        print("\nFUNCTIONS\n", .{});
        print("len: {}\n", .{functions_list.items.len});

        var fn_index: u32 = 0;
        for (functions_list.items) |assem_fn| {
            print("{d} {s} {d}\n", .{ fn_index, assem_fn.name, assem_fn.starts_at });

            fn_index += 1;
        }

        print("\nFINAL INSTRUCTIONS BEFORE TARGET RESOLVES\n", .{});
        print("len: {}\n", .{instructions.items.len});

        var index: u32 = 0;
        for (instructions.items) |instr| {
            print("{d} {s}\n", .{ index, instr });

            if (!std.mem.startsWith(u8, instr, "0") and !std.mem.startsWith(u8, instr, "1")) {
                const tokens = try utils.splitIntoTokens(allocator, instr);
                if (utils.matchesAny(tokens[0], &function_reference_type_instructions)) {}

                const instruction = tokens[0];
                var function_name_or_int = tokens[2]; // all other ins
                if (!std.mem.eql(u8, instruction, "jal")) {
                    function_name_or_int = tokens[3];
                }

                // calculate offset
                const offset = parseOffsetFromInstruction(&functions_list, function_name_or_int, index);
                const offset_str = try std.fmt.allocPrint(allocator, "{d}", .{offset});

                print("offset: {d}\n", .{offset});

                tokens[if (std.mem.eql(u8, instruction, "jal")) 2 else 3] = offset_str;

                const assemble_output = try assembler.assemble(&allocator, tokens);
                instructions.items[index] = assemble_output;
            } else {
                // print("NOT FOUND\n", .{});
            }

            index += 1;
        }

        print("\nSAVING TO {s}....\n", .{output_path});

        // save instructions to a file
        const file = try std.fs.cwd().createFile(output_path, .{ .truncate = true });
        defer file.close();

        var fsi_index: u32 = 0;
        for (instructions.items) |instr| {
            print("{d} {s}\n", .{ fsi_index, instr });
            _ = try file.writeAll(try std.fmt.allocPrint(std.heap.page_allocator, "{s}\n", .{instr}));

            fsi_index += 1;
        }
    } else |err| {
        print("Error reading file: {s}\n", .{@errorName(err)});
    }
}

// fn findAssembleFunctionByName(array_list: *std.array_list.ArrayListAligned(AssembleFunction, null), name: []const u8) !?*const AssembleFunction {
fn findAssembleFunctionByName(array_list: *std.ArrayListAligned(AssembleFunction, null), name: []const u8) !?*const AssembleFunction {
    for (array_list.items) |*func| {
        if (std.mem.eql(u8, func.name, name)) {
            return func;
        }
    }

    return null;
}

fn parseOffsetFromInstruction(functions_list: *std.ArrayListAligned(AssembleFunction, null), function_name_or_int: []const u8, index: u32) i32 {
    const offset: i32 = std.fmt.parseInt(i32, function_name_or_int, 0) catch {
        const found_assem_fn = findAssembleFunctionByName(functions_list, function_name_or_int) catch |fn_err| {
            print("findAssembleFunctionByName Error: {s}\n", .{fn_err});
            unreachable;
        };

        if (found_assem_fn) |assem_fn| {
            const offset: i32 = (@as(i32, @intCast(assem_fn.starts_at)) - @as(i32, @intCast(index))) * 4;
            return offset;
        } else {
            unreachable;
        }
    };

    return offset;
}

fn combineTokens(allocator: std.mem.Allocator, tokens: []const []const u8) ![]const u8 {
    // Create an ArrayList to collect the combined string
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    // Append each token to the list with spaces in between
    var i: u32 = 0;
    for (tokens) |
        token,
    | {
        try list.appendSlice(token);
        if (i < tokens.len - 1) {
            try list.append(' ');
        }

        i += 1;
    }

    // Return the combined string as a slice
    return list.toOwnedSlice();
}
