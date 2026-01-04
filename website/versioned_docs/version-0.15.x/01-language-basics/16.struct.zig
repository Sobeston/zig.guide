const Vec3 = struct { x: f32, y: f32, z: f32 };

test "struct usage" {
    const my_vector: Vec3 = .{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}
