const std = @import("std");
const assembler = @import("assembler.zig");
const utils = @import("utils.zig");
const tests = @import("tests.zig");

const print = std.debug.print;
// const allocator = std.heap.page_allocator;

const MainErrors = error{
    MultipleGlobalsDefined,
};

const AssembleFunction = struct {
    name: []const u8,
    starts_at: u32,
    // instructions: []const u8,
};

pub fn main() !void {
    const assemly_path = "src/assembly.asm";
    const output_path = "src/output.bin";

    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

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
                    // .instructions = "",
                });
            } else {
                print("{d} [ASSEMBLE] {s}\n", .{ instruction_index, line });

                instruction_index += 1;

                // remove any commas
                const size = std.mem.replacementSize(u8, line, ",", "");
                const removed_commas_line = try allocator.alloc(u8, size);
                _ = std.mem.replace(u8, line, ",", "", removed_commas_line);

                // split the line into tokens
                const tokens = try splitIntoTokens(allocator, removed_commas_line);

                // check token references functions
                if (utils.matchesAny(tokens[0], &function_reference_type_instructions)) {
                    // print("{s}\n", .{line});

                    try instructions.append(removed_commas_line);

                    // functions_list.items[functions_list.len - 1].instructions = line;

                    // const function_name = token_items[2];
                    // const function_index = functions_list.indexOf(function_name) catch |err| {
                    //     std.log.err("Error finding function: {}", .{err});
                    //     return err;
                    // };

                    // const function = functions_list.items[function_index];

                    // const offset = function.starts_at - instruction_index;
                    // const offset_str = try std.fmt.allocPrint(allocator, "{d}", .{offset});

                    // const new_instruction = try std.fmt.allocPrint(allocator, "{s} {s} {s}", .{token_items[0], token_items[1], offset_str});
                    // functions_list.items[function_index].instructions = new_instruction;

                } else {
                    // ASSEMBLE
                    const assemble_output = assembler.assemble(&allocator, tokens) catch |err| {
                        std.log.err("Error assembling line: {}", .{err});
                        return err;
                    };
                    // print("assemble_output: {}\n", .{assemble_output});

                    // convert to binary
                    var result = try std.fmt.allocPrint(std.heap.page_allocator, "{b}", .{assemble_output});
                    while (result.len < 32) { // Append '0' characters until the length is 32
                        result = try std.fmt.allocPrint(std.heap.page_allocator, "0{s}", .{result});
                    }

                    // print("{s}", .{result});
                    try instructions.append(result);

                    // _ = try file.writeAll(result);
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
                const tokens = try splitIntoTokens(allocator, instr);
                if (utils.matchesAny(tokens[0], &function_reference_type_instructions)) {}

                const instruction = tokens[0];
                var function_name = tokens[3]; // all other ins
                if (std.mem.eql(u8, instruction, "jal")) {
                    function_name = tokens[2];
                }

                const found_assem_fn = findAssembleFunctionByName(&functions_list, function_name) catch |err| {
                    print("Error: {s}\n", .{err});
                    return;
                };

                if (found_assem_fn) |assem_fn| {
                    print("LLLL: {d} {d}\n\n", .{ assem_fn.starts_at, index });
                    const offset: u32 = (assem_fn.starts_at - index) * 2;
                    const offset_str = try std.fmt.allocPrint(allocator, "{d}", .{offset});

                    // const buf: [256]u8 = undefined;
                    // const offset_str = try std.fmt.bufPrint(&buf, "{}", offset);

                    // if (std.mem.eql(u8, instruction, "jal")) {
                    tokens[if (std.mem.eql(u8, instruction, "jal")) 2 else 3] = offset_str;

                    const assemble_output = assembler.assemble(&allocator, tokens) catch |err| {
                        std.log.err("Error assembling line: {}", .{err});
                        return err;
                    };
                    // print("assemble_output: {}\n", .{assemble_output});

                    // convert to binary
                    var result = try std.fmt.allocPrint(std.heap.page_allocator, "{b}", .{assemble_output});
                    while (result.len < 32) { // Append '0' characters until the length is 32
                        result = try std.fmt.allocPrint(std.heap.page_allocator, "0{s}", .{result});
                    }

                    // instructions[index] = result;
                    instructions.items[index] = result;

                    // print("Found function with Name {s}: {s}\n", .{assem_fn.name, function_name});
                } else {
                    print("NOT FOUND", .{});
                    // print("Function with Name {s} not found.\n", .{function_name});
                }
            }

            // find function start_at from list

            index += 1;
        }

        // print("\nFINAL INSTRUCTIONS\n", .{});
        // print("len: {}\n", .{instructions.items.len});

        // var fi_index: u32 = 0;
        // for (instructions.items) |instr| {
        //     print("{d} {s}\n", .{ fi_index, instr });
        //     fi_index += 1;
        // }

        print("\nSAVING TO {s}....\n", .{output_path});

        const file = try std.fs.cwd().createFile(output_path, .{ .truncate = true });
        defer file.close();

        var fsi_index: u32 = 0;
        for (instructions.items) |instr| {
            print("{d} {s}\n", .{ fsi_index, instr });
            _ = try file.writeAll(try std.fmt.allocPrint(std.heap.page_allocator, "{s}\n", .{instr}));

            fsi_index += 1;
        }

        // print("INSTRUCTIONS COMPILED :)\n", .{});
    } else |err| {
        print("Error reading file: {s}\n", .{@errorName(err)});
    }
}

fn splitIntoTokens(allocator: std.mem.Allocator, value: []const u8) ![][]const u8 {
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

// fn findAssembleFunctionByName(array_list: *std.array_list.ArrayListAligned(AssembleFunction, null), name: []const u8) !?*const AssembleFunction {
fn findAssembleFunctionByName(array_list: *std.ArrayListAligned(AssembleFunction, null), name: []const u8) !?*const AssembleFunction {
    for (array_list.items) |*func| {
        if (std.mem.eql(u8, func.name, name)) {
            return func;
        }
    }

    return null;
}
