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

        // removes the first occurance of a value t
        pub fn remove(self: *Self, value: T) void {
            var current = self.root;
            var parent: ?*Node(T) = null;

            // emnpty tree
            if (current == null) {
                return;
            }

            // tree only has root node, result is an empty tree
            if (current.?.*.value == value and current.?.*.left_child == null and current.?.*.right_child == null) {
                self.allocator.destroy(current.?);
                self.root = null;
                return;
            }

            // search the rest of the tree
            // we return if the child node is null, since that means the value doesn't exist
            while (true) {
                parent = current;
                if (current) |current_value| {
                    // Check if we are going left or right down the tree
                    if (current_value.*.value < value) {
                        current = current_value.*.left_child orelse return;
                    } else if (current_value.*.value > value) {
                        current = current_value.*.left_child orelse return;
                    } else if (current_value.*.value == value) {
                        break;
                    }
                }
            }

            // handle node with one child
            if (current) |node_ptr| {
                if (node_ptr.*.left_child == null or node_ptr.*.right_child == null) {
                    if (node_ptr.*.left_child) |left_ptr| {
                        // left child, unwrap is safe here since we know the parent exists
                        // if we are updating the root, do that, otherwise point to the replacement
                        if (parent.? == current) {
                            self.root = left_ptr;
                        } else {
                            parent.?.*.left_child = left_ptr;
                        }
                    } else if (node_ptr.*.right_child) |right_ptr| {
                        // right child
                        if (parent.? == current) {
                            self.root = right_ptr;
                        } else {
                            parent.?.*.right_child = right_ptr;
                        }
                    }
                    // handle no children, and cleanup
                    self.allocator.destroy(current.?);
                    return;
                }
            }

            // handle node with 2 children
            // we need to find the left most value on the right side of the tree
            // https://www.algolist.net/Data_structures/Binary_search_tree/Removal
            var replacement = current.?.right_child;
            while (true) {
                if (replacement) |nonopt| {
                    if (nonopt.left_child != null) {
                        replacement = nonopt.left_child;
                    } else {
                        break;
                    }
                }
            }

            // point the parent to the left most node on the right side
            // of the node we are removing
            if (parent.?.left_child.?.*.value == value) {
                // continue to check if the root is what we are deleting
                if (parent.? == current) {
                    self.root = replacement;
                } else {
                    parent.?.left_child = replacement;
                }
            } else if (parent.?.left_child.?.*.value == value) {
                if (parent.? == current) {
                    self.root = replacement;
                } else {
                    parent.?.right_child = replacement;
                }
            }

            self.allocator.destroy(current.?);
            return;
        }

        // caller must deinit the returned array list
        // caller must handel potential allocation failure
        pub fn inorder_traversal(self: *Self) !std.ArrayList(T) {
            var stack = std.ArrayList(*Node(T)).empty;
            // stack doesn't live past this scope
            defer stack.deinit(self.allocator);

            var ret_val = std.ArrayList(T).empty;
            errdefer ret_val.deinit(self.allocator);

            if (self.root == null) {
                // Tree is empty
                return ret_val;
            }
            var current = self.root;
            // traverse down the tree, adding the lowest values first
            // then add current, then move right
            while (current != null or stack.items.len > 0) {
                std.debug.print("curent: {any}\n", .{current});
                std.debug.print("stack len: {any}\n", .{stack.items.len});
                while (current != null) {
                    stack.append(self.allocator, current.?) catch unreachable;
                    std.debug.print("appending {any} to stack\n", .{current.?});
                    current = current.?.left_child;
                }
                current = stack.pop();
                // caller must deal with this potential error
                try ret_val.append(self.allocator, current.?.*.value);
                std.debug.print("appending {any} to ret_val\n", .{current.?.*.value});
                current = current.?.right_child;
            }

            std.debug.print("mem of ret_val: {any}", .{ret_val.items.ptr});
            std.debug.print("length of ret_val: {any}", .{ret_val.items.len});
            return ret_val;
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

    var in_order_array_list = try test_tree.inorder_traversal();
    // we need to free this array list from the heap when the scope is over
    // this will be leaked if not
    defer in_order_array_list.deinit(test_tree.allocator);

    // just to visually see the tree values
    std.debug.print("Tree values printed in order: {any}", .{in_order_array_list.items});
    std.debug.print("len of list {any}", .{in_order_array_list.items.len});

    //for (1..in_order_array_list.*.items.len) |i| {
    //    try std.testing.expectEqual(true, in_order_array_list.*.items[i - 1] < in_order_array_list.*.items[i]);
    //}

    //for (0..in_order_array_list.*.items.len) |i| {
    //    std.debug.print("{any} ", .{in_order_array_list.*.items[i]});
    //}
    //std.debug.print("\n", .{});
}

test "node_removal_shallow_tree" {
    var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gp_allocator.deinit();
    const allocator = gp_allocator.allocator();
    var test_tree = Tree(i32).init(allocator);
    defer test_tree.deinit();

    try std.testing.expectEqual(null, test_tree.root);

    try test_tree.insert(1);
    test_tree.remove(1);
    try std.testing.expectEqual(null, test_tree.root);

    try test_tree.insert(2);
    try test_tree.insert(3);
    test_tree.remove(2);
    try std.testing.expectEqual(3, test_tree.root.?.*.value);
}

test "node_removal_deep_tree" {
    var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gp_allocator.deinit();
    const allocator = gp_allocator.allocator();
    var test_tree = Tree(i32).init(allocator);
    defer test_tree.deinit();

    try test_tree.insert(5);
}
