//pub fn parse_csv() void {
//    var file = try std.fs.cwd().openFile("data.csv", .{});
//    defer file.close();
//
//    var reader = file.reader();
//    var line = std.ArrayList(u8).init(allocator);
//    defer line.deinit();
//
//    while (reader.readUntilDelimiterOrEofAlloc(line.writer(), '\n', 1024 * 1024) catch |err| {
//        // Handle read error, maybe break loop
//        break;
//    }) |bytes_read| {
//        // Process 'line.items' as a single CSV row
//    }
//}
