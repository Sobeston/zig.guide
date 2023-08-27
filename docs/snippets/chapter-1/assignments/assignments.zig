const constant: i32 = 5; // {{ signed_32bit_constant }}
var variable: u32 = 5000; // {{ unsigned_32bit_variable }}

// {{ explicit_coercion }}
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);
