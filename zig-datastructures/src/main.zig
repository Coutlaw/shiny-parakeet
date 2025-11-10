const std = @import("std");
const zig_datastructures = @import("zig_datastructures");
const stack = @import("stack.zig");
const tree = @import("tree.zig");

pub fn main() !void {
    var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gp_allocator.deinit();
    const allocator = gp_allocator.allocator();
    var test_tree = tree.Tree(i32).init(allocator);
    defer test_tree.deinit();

    try test_tree.insert(5);
    try test_tree.insert(3);
    try test_tree.insert(4);
    try test_tree.insert(1);
    try test_tree.insert(2);
    try test_tree.insert(8);
    try test_tree.insert(9);
    try test_tree.insert(6);
    try test_tree.insert(7);

    // tree would look like this
    //          5
    //      3       8
    //  1   4      6     9
    //   2          7

    // confirming the tree
    var current_tree = try test_tree.inorder_traversal();
    std.debug.print("Tree values printed in order: {any}\n", .{current_tree.items});
    // clean up the space
    current_tree.deinit(test_tree.allocator);

    test_tree.remove(3);

    current_tree = try test_tree.inorder_traversal();
    std.debug.print("Tree values printed in order: {any}\n", .{current_tree.items});
    // clean up the space
    current_tree.deinit(test_tree.allocator);
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
