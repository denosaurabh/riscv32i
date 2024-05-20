const std = @import("std");
const assembler = @import("assembler.zig");
const tests = @import("tests.zig");

const print = std.debug.print;
// const allocator = std.heap.page_allocator;

pub fn main() !void {
    const assemly_path = "src/assembly.asm";
    const output_path = "src/output.bin";

    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    arena.deinit();
    const allocator = arena.allocator();

    const file_contents_or_error = std.fs.cwd().readFileAlloc(allocator, assemly_path, std.math.maxInt(usize));
    defer if (file_contents_or_error) |file_contents| {
        allocator.free(file_contents);
    } else |_| {};

    if (file_contents_or_error) |file_contents| {
        const delimiter = "\n";

        var iterator = std.mem.split(u8, file_contents, delimiter);

        const file = try std.fs.cwd().createFile(output_path, .{ .truncate = true });
        defer file.close();

        while (iterator.next()) |line| {
            const comment_index = std.mem.indexOf(u8, line, "#");
            const truncated_line = if (comment_index) |index| line[0..index] else line;

            if (truncated_line.len == 0) {
                continue;
            }

            // assemble
            const binary_output = assembler.assemble(&allocator, truncated_line) catch |err| {
                std.log.err("Error assembling line: {}", .{err});
                return err;
            };

            var result = try std.fmt.allocPrint(std.heap.page_allocator, "{b}\n", .{binary_output});
            defer std.heap.page_allocator.free(result);

            // Append '0' characters until the length is 32
            while (result.len < 32 + 1) {
                result = try std.fmt.allocPrint(std.heap.page_allocator, "0{s}", .{result});
            }

            _ = try file.writeAll(result);
        }

        // print("INSTRUCTIONS COMPILED :)\n", .{});
    } else |err| {
        print("Error reading file: {s}\n", .{@errorName(err)});
    }
}
