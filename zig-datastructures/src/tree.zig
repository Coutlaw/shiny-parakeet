const std = @import("std");

pub fn Node(T: anytype) type {
    return struct {
        value: T,
        left_child: ?*Node(T),
        right_child: ?*Node(T),

        const Self = @This();

        pub fn init(value: T) @This() {
            return .{
                .left_child = null,
                .right_child = null,
                .value = value,
            };
        }

        pub fn is_leaf(self: *Self) bool {
            if (self.left_child || self.right_child) {
                return false;
            }
            return true;
        }
    };
}

pub fn Tree(comptime T: type) type {
    return struct {
        root: ?*Node(T),
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .root = null,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.root == null) {
                return;
            }

            var item_stack = std.ArrayList(*Node(T)).empty;
            defer item_stack.deinit(self.allocator);

            item_stack.append(self.allocator, self.root.?) catch unreachable;

            while (item_stack.items.len > 0) {
                const node_opt = item_stack.pop();

                if (node_opt) |node| {
                    if (node.*.right_child) |righ_node| {
                        item_stack.append(self.allocator, righ_node) catch unreachable;
                    }
                    if (node.*.left_child) |left_node| {
                        item_stack.append(self.allocator, left_node) catch unreachable;
                    }

                    self.allocator.destroy(node);
                }
            }
        }

        // Chose to leave this as the public method so users don't have to pass in a node reference,
        // users are just exposed to the tree interface and not the nodes.
        // The functionality below starts by checking the root node, populating that node if it is null
        // Otherwise we traverse down the tree, comparing the value we are inserting to the current nodes children
        // Find the appropriate null pointer, and insert the node reference in the tree.
        // We do not insert duplicate values, so they are just destroyed
        pub fn insert(self: *Self, value: T) !void {
            // Handle empty tree, set root node and bail
            if (self.root == null) {
                self.root = try self.allocator.create(Node(T));
                self.root.?.* = Node(T).init(value);
                return;
            }

            var current = self.root;

            const new_node: ?*Node(T) = try self.allocator.create(Node(T));
            new_node.?.* = Node(T).init(value);

            while (true) {
                // check if option has value since every node is optional
                if (current) |current_node| {
                    if (value < current_node.*.value) {
                        if (current_node.*.left_child == null) {
                            current_node.*.left_child = new_node;
                            break;
                        } else {
                            current = current_node.*.left_child;
                        }
                    } else if (value > current_node.*.value) {
                        if (current_node.*.right_child == null) {
                            current_node.*.right_child = new_node;
                            break;
                        } else {
                            current = current_node.*.right_child;
                        }
                    } else {
                        self.allocator.destroy(new_node.?);
                        break;
                    }
                } else {
                    // will never reach this, but here for debugging
                    break;
                }
            }
        }

        //pub fn deinit(self: *self) void {

        //}

        // removes the first occurance of a value t
        //pub fn remove(self: *self, value: t) void {

        //}

        pub fn inorder_traversal(self: *Self) void {
            var stack = std.ArrayList(*Node(T)).empty;
            defer stack.deinit(self.allocator);

            if (self.root == null) {
                // Tree is empty
                return;
            }
            var current = self.root;
            while (current != null or stack.items.len > 0) {
                while (current != null) {
                    stack.append(self.allocator, current.?) catch unreachable;
                    current = current.?.left_child;
                }
                current = stack.pop();
                std.debug.print("{} ", .{current.?.value});
                current = current.?.right_child;
            }
            std.debug.print("\n", .{});
        }
    };
}

test "ptr" {
    // me testing my own understanding of optional pointers
    var num: i32 = 5;
    var optptr: ?*i32 = &num;
    try std.testing.expectEqual(optptr.?.*, 5);

    optptr = null;
    try std.testing.expectEqual(optptr, null);

    optptr = &num;
    if (optptr == null) {
        std.debug.print("optptr was null!\n", .{});
    } else {
        std.debug.print("optptr was not null!\n", .{});
        std.debug.print("derefed pointer was {d}\n", .{optptr.?.*});
    }

    if (optptr) |value| {
        std.debug.print("optptr not null, value: {d}", .{value.*});
    } else {
        std.debug.print("optptr was null", .{});
    }
}

test "tree_basics" {
    var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gp_allocator.deinit();
    const allocator = gp_allocator.allocator();
    var test_tree = Tree(i32).init(allocator);

    try std.testing.expectEqual(null, test_tree.root);
    defer test_tree.deinit();

    try test_tree.insert(5); // root Node()
    try std.testing.expectEqual(5, test_tree.root.?.*.value);
    try std.testing.expectEqual(null, test_tree.root.?.*.left_child);

    try test_tree.insert(3);
    try std.testing.expectEqual(3, test_tree.root.?.*.left_child.?.*.value);
    try std.testing.expectEqual(null, test_tree.root.?.*.right_child);

    try test_tree.insert(4);
    try test_tree.insert(6);
    try std.testing.expectEqual(4, test_tree.root.?.*.left_child.?.*.right_child.?.*.value);
    try std.testing.expectEqual(6, test_tree.root.?.*.right_child.?.*.value);

    // Can't add duplicate
    try test_tree.insert(3);
    try std.testing.expectEqual(3, test_tree.root.?.*.left_child.?.*.value);
    try std.testing.expectEqual(null, test_tree.root.?.*.left_child.?.*.left_child);
}

test "tree_traversals" {
    var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gp_allocator.deinit();
    const allocator = gp_allocator.allocator();
    var test_tree = Tree(i32).init(allocator);

    try std.testing.expectEqual(null, test_tree.root);
    defer test_tree.deinit();

    try test_tree.insert(5); // root Node()
    try test_tree.insert(3);
    try test_tree.insert(4);
    try test_tree.insert(6);
    try test_tree.insert(0);

    // print tree_traversals
    test_tree.inorder_traversal();
}
