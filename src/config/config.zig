const std = @import("std");
const core = @import("aero_core");
const logging = @import("aero_log");
const Edition = core.Edition;
const detectEditionFromEnvOrDefault = @import("aero_core").detectEditionFromEnvOrDefault;
const Credentials = @import("credentials.zig").Credentials;
const DatabaseEndpoint = @import("database.zig").DatabaseEndpoint;
const Logger = logging.Logger;
const Schema = @import("schema.zig").Schema;

pub const ClientConfig = struct {
    edition: Edition = .community,
    active: DatabaseEndpoint,
    passive: ?DatabaseEndpoint = null,
    active_credentials: Credentials,
    passive_credentials: ?Credentials = null,
    schema: ?Schema = null,

    // ╔═══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Initialize Default Config                                       ║
    // ║ Brief   : Loads edition and active endpoint/credentials from env;         ║
    // ║           constructs passive if provided                                  ║
    // ║ Params  :                                                                 ║
    // ║   - allocator: allocator for owned strings                                ║
    // ║ Usage   : const cfg = try ClientConfig.initDefault(gpa);                  ║
    // ║ Returns :                                                                 ║
    // ║   - Success: config based on environment variables                        ║
    // ║   - Failure: AeroError.MissingRequiredConfig when active endpoint invalid ║
    // ╚═══════════════════════════════════════════════════════════════════════════╝
    pub fn initDefault(allocator: std.mem.Allocator) !ClientConfig {
        const edition = try detectEditionFromEnvOrDefault(allocator, "AEROSPIKE_EDITION");
        const logger = Logger.init(.info);
        const active = try DatabaseEndpoint.fromEnv(allocator, "AEROSPIKE_ACTIVE_", &logger);
        const active_creds = try Credentials.fromEnv(allocator, "AEROSPIKE_ACTIVE_", &logger);

        // Passive is optional; if env vars exist, construct it.
        var passive_ep_opt: ?DatabaseEndpoint = null;
        var passive_creds_opt: ?Credentials = null;
        const passive_hosts = std.process.getEnvVarOwned(allocator, "AEROSPIKE_PASSIVE_HOSTS") catch null;
        defer if (passive_hosts) |v| allocator.free(v);
        if (passive_hosts != null) {
            passive_ep_opt = try DatabaseEndpoint.fromEnv(allocator, "AEROSPIKE_PASSIVE_", &logger);
            passive_creds_opt = try Credentials.fromEnv(allocator, "AEROSPIKE_PASSIVE_", &logger);
        }

        const ns_probe = std.process.getEnvVarOwned(allocator, "AEROSPIKE_NAMESPACE") catch null;
        defer if (ns_probe) |v| allocator.free(v);
        var schema_opt: ?Schema = null;
        if (ns_probe != null) {
            schema_opt = Schema.fromEnv(allocator, &logger) catch null;
        }

        return .{
            .edition = edition,
            .active = active,
            .passive = passive_ep_opt,
            .active_credentials = active_creds,
            .passive_credentials = passive_creds_opt,
            .schema = schema_opt,
        };
    }
};
