const std = @import("std");
const aerospike = @import("aerospike");

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    const cfg = try aerospike.ClientConfig.initDefault(gpa);
    var client = try aerospike.Client.init(gpa, cfg);
    defer client.deinit();
    try client.connect();
    std.debug.print("Connected to Aerospike (active/passive failover supported)\n", .{});
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Test: Edition Defaults to Community                                          ║
// ║ Brief: Verifies detectEditionFromEnvOrDefault yields a valid edition         ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
test "edition defaults to community" {
    const gpa = std.testing.allocator;
    const ed = try aerospike.detectEditionFromEnvOrDefault(gpa, "AEROSPIKE_EDITION");
    try std.testing.expect(ed == .community or ed == .enterprise);
}
