const std = @import("std");
const logging = @import("aero_log");
const core = @import("aero_core");
const Logger = logging.Logger;
const AeroError = core.AeroError;

pub const DatabaseEndpoint = struct {
    hosts: [][]const u8 = &[_][]const u8{},
    port: u16 = 3000,
    connect_timeout_ms: u32 = 5000,
    read_timeout_ms: u32 = 5000,
    cluster_name: ?[]const u8 = null,

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Validate Endpoint                                              ║
    // ║ Brief   : Validates hosts and port; enforces required fields             ║
    // ║ Params  :                                                                ║
    // ║   - logger: optional logger for pretty output                            ║
    // ║ Usage   : try endpoint.validate(&logger);                                ║
    // ║ Returns :                                                                ║
    // ║   - Success: endpoint ready to use                                       ║
    // ║   - Failure: AeroError.MissingRequiredConfig if invalid                  ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn validate(self: *const DatabaseEndpoint, logger: ?*const Logger) !void {
        if (self.hosts.len == 0) {
            if (logger) |lg| try lg.err("config", "No hosts provided. Set AEROSPIKE_ACTIVE_HOSTS or passive equivalent.");
            return AeroError.MissingRequiredConfig;
        }
        if (self.port == 0) {
            if (logger) |lg| try lg.err("config", "Port cannot be 0. Set AEROSPIKE_ACTIVE_PORT or passive equivalent.");
            return AeroError.MissingRequiredConfig;
        }
    }

    // ╔═══════════════════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Endpoint from Environment                                                   ║
    // ║ Brief   : Builds endpoint from `HOSTS` CSV and `PORT` using a prefix                  ║
    // ║ Params  :                                                                             ║
    // ║   - allocator: allocator                                                              ║
    // ║   - prefix   : e.g., "AEROSPIKE_ACTIVE_"                                              ║
    // ║   - logger   : optional logger                                                        ║
    // ║ Usage   : const ep = try DatabaseEndpoint.fromEnv(gpa, "AEROSPIKE_ACTIVE_", &logger); ║
    // ║ Returns :                                                                             ║
    // ║   - Success: endpoint populated from env                                              ║
    // ║   - Failure: AeroError.MissingRequiredConfig if missing/invalid values                ║
    // ╚═══════════════════════════════════════════════════════════════════════════════════════╝
    pub fn fromEnv(allocator: std.mem.Allocator, prefix: []const u8, logger: ?*const Logger) !DatabaseEndpoint {
        var ep: DatabaseEndpoint = .{};
        const hosts_key = try std.fmt.allocPrint(allocator, "{s}HOSTS", .{prefix});
        defer allocator.free(hosts_key);
        const port_key = try std.fmt.allocPrint(allocator, "{s}PORT", .{prefix});
        defer allocator.free(port_key);
        const ctimeout_key = try std.fmt.allocPrint(allocator, "{s}CONNECT_TIMEOUT_MS", .{prefix});
        defer allocator.free(ctimeout_key);
        const rtimeout_key = try std.fmt.allocPrint(allocator, "{s}READ_TIMEOUT_MS", .{prefix});
        defer allocator.free(rtimeout_key);
        const cname_key = try std.fmt.allocPrint(allocator, "{s}CLUSTER_NAME", .{prefix});
        defer allocator.free(cname_key);

        const hosts_val = std.process.getEnvVarOwned(allocator, hosts_key) catch null;
        defer if (hosts_val) |v| allocator.free(v);
        if (hosts_val) |v| {
            ep.hosts = try parseCsvOwned(allocator, v);
        }
        const port_val = std.process.getEnvVarOwned(allocator, port_key) catch null;
        defer if (port_val) |v| allocator.free(v);
        if (port_val) |v| ep.port = std.fmt.parseInt(u16, v, 10) catch 3000;

        const ct_val = std.process.getEnvVarOwned(allocator, ctimeout_key) catch null;
        defer if (ct_val) |v| allocator.free(v);
        if (ct_val) |v| ep.connect_timeout_ms = std.fmt.parseInt(u32, v, 10) catch ep.connect_timeout_ms;

        const rt_val = std.process.getEnvVarOwned(allocator, rtimeout_key) catch null;
        defer if (rt_val) |v| allocator.free(v);
        if (rt_val) |v| ep.read_timeout_ms = std.fmt.parseInt(u32, v, 10) catch ep.read_timeout_ms;

        ep.cluster_name = std.process.getEnvVarOwned(allocator, cname_key) catch null;

        try ep.validate(logger);
        return ep;
    }

    fn parseCsvOwned(allocator: std.mem.Allocator, csv: []const u8) ![][]const u8 {
        var items = std.ArrayListUnmanaged([]const u8){};
        errdefer {
            for (items.items) |it| allocator.free(it);
            items.deinit(allocator);
        }
        var it = std.mem.splitAny(u8, csv, ", ");
        while (it.next()) |part| {
            const trimmed = std.mem.trim(u8, part, " \t\r");
            if (trimmed.len == 0) continue;
            const duped = try allocator.alloc(u8, trimmed.len);
            std.mem.copyForwards(u8, duped, trimmed);
            try items.append(allocator, duped);
        }
        return items.toOwnedSlice(allocator);
    }
};
