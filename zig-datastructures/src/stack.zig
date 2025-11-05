const std = @import("std");
const mem = std.mem;

const StackErrors = error{EmptyStack};

pub fn Stack(comptime T: type) type {
    return struct {
        items: std.ArrayList(T),

        allocator: mem.Allocator,
        const Self = @This();

        pub fn init(allocator: mem.Allocator) @This() {
            return .{
                .items = std.ArrayList(T).empty,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        pub fn pop(self: *Self) !T {
            if (self.items.pop()) |value| {
                return value;
            }
            return StackErrors.EmptyStack;
        }

        pub fn push(self: *Self, item: T) !void {
            try self.items.append(self.allocator, item);
        }

        pub fn peek(self: *Self) ?T {
            if (self.items.items.len == 0) {
                return null;
            }
            return self.items.items[self.items.items.len - 1];
        }

        pub fn is_empty(self: *Self) bool {
            return self.items.items.len == 0;
        }

        pub fn len(self: *Self) usize {
            return self.items.items.len;
        }
    };
}

test "Stack" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stack = Stack(i32).init(allocator);
    defer stack.deinit();

    try stack.push(10);
    try stack.push(20);
    try stack.push(30);

    try std.testing.expectEqual(stack.len(), 3);
    try std.testing.expectEqual(stack.peek(), 30);
    try std.testing.expectEqual(stack.pop(), 30);
    try std.testing.expectEqual(stack.is_empty(), false);
    try std.testing.expectEqual(stack.len(), 2);
    try std.testing.expectEqual(stack.pop(), 20);
    try std.testing.expectEqual(stack.pop(), 10);
    try std.testing.expectEqual(stack.is_empty(), true);
    try std.testing.expectError(error.EmptyStack, stack.pop());
}
