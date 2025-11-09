const std = @import("std");
const cfg = @import("aero_config");
const logging = @import("aero_log");
const core = @import("aero_core");
const ClientConfig = cfg.ClientConfig;
const Credentials = cfg.Credentials;
const DatabaseEndpoint = cfg.DatabaseEndpoint;
const Logger = logging.Logger;

test "credentials validate requires both user and password when set" {
    var logger = Logger.init(.off);
    var creds: Credentials = .{ .user = "alice", .password = null };
    try std.testing.expectError(core.AeroError.MissingRequiredCredential, creds.validate(&logger));
}

test "endpoint validate requires hosts and port" {
    var logger = Logger.init(.off);
    var ep: DatabaseEndpoint = .{ .hosts = &[_][]const u8{}, .port = 0 };
    try std.testing.expectError(core.AeroError.MissingRequiredConfig, ep.validate(&logger));
}