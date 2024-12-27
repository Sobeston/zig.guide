const std = @import("std");

const http = std.http;
const net = std.net;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

fn run_server(server: *net.Server) !void {
    while (true) {
        var conn = try server.accept();
        defer conn.stream.close();

        var read_buffer: [1024]u8 = undefined;
        var http_server = http.Server.init(conn, &read_buffer);

        var request = try http_server.receiveHead();

        try request.respond("Hello from http server!\n", .{});
    }
}

test "http receive response" {
    // Create a TCP server listening on localhost:8000.
    const addr = net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8000);

    var server = try addr.listen(.{});

    // Spawn a thread to run the server.
    const thread = try std.Thread.spawn(.{}, run_server, .{&server});
    _ = thread; // Ignore the thread handle.

    // Use the same client code as in the previous example.
    var client = http.Client{ .allocator = test_allocator };
    defer client.deinit();

    var body = std.ArrayList(u8).init(test_allocator);
    errdefer body.deinit();

    const fetch_result = try client.fetch(.{
        .location = .{ .url = "http://127.0.0.1:8000" },
        .response_storage = .{ .dynamic = &body },
    });

    const owned_body = try body.toOwnedSlice();
    defer test_allocator.free(owned_body);

    // Check that the request was successful and the response body is correct.
    try expect(fetch_result.status == http.Status.ok);
    try expect(std.mem.eql(u8, owned_body, "Hello from http server!\n"));
}
