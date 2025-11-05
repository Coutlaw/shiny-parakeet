const std = @import("std");
const zig = @import("zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const commands = &[_][]const u8{ "bash", "-c", "echo Hello from Bash" };

    var child = std.process.Child.init(commands, allocator);

    try child.spawn();

    const term_sig = try child.wait();

    switch (term_sig) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("Bash worked!\n", .{});
            } else {
                std.debug.print("Oopsie Whoopsie, we made a fucky wucky: {d}\n", .{code});
            }
        },
        else => {
            std.debug.print("Don't even know what sorts of fucked up we got to\n", .{});
        },
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
