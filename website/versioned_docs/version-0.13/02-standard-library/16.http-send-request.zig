const std = @import("std");

const http = std.http;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;

const Post = struct { id: u8, userId: u8, title: []u8, body: []u8 };

test "http send request" {
    // Create a client with a custom allocator.
    var client = http.Client{ .allocator = test_allocator };
    defer client.deinit();

    // Allocate a buffer to store the response body.
    var body = std.ArrayList(u8).init(test_allocator);
    errdefer body.deinit();

    // Send a GET request to the specified URL.
    const fetch_result = try client.fetch(.{
        .location = .{ .url = "https://jsonplaceholder.typicode.com/posts/1" },
        .response_storage = .{ .dynamic = &body },
    });

    // Check that the request was successful.
    try expect(fetch_result.status == http.Status.ok);

    // Convert the response body to an owned slice.
    const owned_body = try body.toOwnedSlice();
    defer test_allocator.free(owned_body);

    // Parse the response body as a JSON object.
    const parsed = try std.json.parseFromSlice(
        Post,
        test_allocator,
        owned_body,
        .{},
    );
    defer parsed.deinit();

    const post = parsed.value;

    // Check that the response body was parsed correctly.
    try expect(post.userId == 1);
    try expect(post.id == 1);
    try expect(std.mem.eql(u8, post.title, "sunt aut facere repellat provident occaecati excepturi optio reprehenderit"));
    try expect(std.mem.eql(
        u8,
        post.body,
        "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto",
    ));
}
