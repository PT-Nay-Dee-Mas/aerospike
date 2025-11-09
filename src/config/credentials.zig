const std = @import("std");
const core = @import("aero_core");
const logging = @import("aero_log");
const AeroError = core.AeroError;
const Logger = logging.Logger;

pub const Credentials = struct {
    user: ?[]const u8 = null,
    password: ?[]const u8 = null,
    tls_enabled: bool = false,
    tls_ca_file: ?[]const u8 = null,
    tls_cert_file: ?[]const u8 = null,
    tls_key_file: ?[]const u8 = null,

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Validate Credentials                                           ║
    // ║ Brief   : Ensures required fields based on TLS/auth are present          ║
    // ║ Params  :                                                                ║
    // ║   - logger: optional logger for pretty output                            ║
    // ║ Usage   : try creds.validate(&logger);                                   ║
    // ║ Returns :                                                                ║
    // ║   - Success: credentials suitable for connection                         ║
    // ║   - Failure: AeroError.MissingRequiredCredential with guidance           ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn validate(self: *const Credentials, logger: ?*const Logger) !void {
        if (self.tls_enabled) {
            if (self.tls_ca_file == null or self.tls_cert_file == null or self.tls_key_file == null) {
                if (logger) |lg| try lg.err("credentials", "TLS enabled but CA/cert/key are missing");
                return AeroError.MissingRequiredCredential;
            }
        }
        // User/password are optional for community/enterprise parity; when provided, both must be present.
        if ((self.user == null) != (self.password == null)) {
            if (logger) |lg| try lg.err("credentials", "Provide both user and password or neither");
            return AeroError.MissingRequiredCredential;
        }
    }

    // ╔═════════════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Load Credentials from Environment                                     ║
    // ║ Brief   : Loads active/passive credentials using prefixes and validates         ║
    // ║ Params  :                                                                       ║
    // ║   - allocator: allocator for env ownership                                      ║
    // ║   - prefix   : e.g., "AEROSPIKE_ACTIVE_"                                        ║
    // ║   - logger   : optional logger                                                  ║
    // ║ Usage   : const c = try Credentials.fromEnv(gpa, "AEROSPIKE_ACTIVE_", &logger); ║
    // ║ Returns :                                                                       ║
    // ║   - Success: Credentials struct                                                 ║
    // ║   - Failure: validation errors if inconsistent                                  ║
    // ╚═════════════════════════════════════════════════════════════════════════════════╝
    pub fn fromEnv(allocator: std.mem.Allocator, prefix: []const u8, logger: ?*const Logger) !Credentials {
        var creds: Credentials = .{};
        const user_key = try std.fmt.allocPrint(allocator, "{s}USER", .{prefix});
        defer allocator.free(user_key);
        const pass_key = try std.fmt.allocPrint(allocator, "{s}PASSWORD", .{prefix});
        defer allocator.free(pass_key);
        const tls_key = try std.fmt.allocPrint(allocator, "{s}TLS_ENABLE", .{prefix});
        defer allocator.free(tls_key);
        const ca_key = try std.fmt.allocPrint(allocator, "{s}TLS_CA_FILE", .{prefix});
        defer allocator.free(ca_key);
        const cert_key = try std.fmt.allocPrint(allocator, "{s}TLS_CERT_FILE", .{prefix});
        defer allocator.free(cert_key);
        const key_key = try std.fmt.allocPrint(allocator, "{s}TLS_KEY_FILE", .{prefix});
        defer allocator.free(key_key);

        creds.user = std.process.getEnvVarOwned(allocator, user_key) catch null;
        creds.password = std.process.getEnvVarOwned(allocator, pass_key) catch null;
        const tls_val = std.process.getEnvVarOwned(allocator, tls_key) catch null;
        defer if (tls_val) |v| allocator.free(v);
        creds.tls_enabled = if (tls_val) |v| std.ascii.eqlIgnoreCase(v, "1") or std.ascii.eqlIgnoreCase(v, "true") else false;
        creds.tls_ca_file = std.process.getEnvVarOwned(allocator, ca_key) catch null;
        creds.tls_cert_file = std.process.getEnvVarOwned(allocator, cert_key) catch null;
        creds.tls_key_file = std.process.getEnvVarOwned(allocator, key_key) catch null;

        try creds.validate(logger);
        return creds;
    }

    // ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Load Credentials from Secret File                                                    ║
    // ║ Brief   : Parses simple `KEY=VALUE` secrets file for credentials                               ║
    // ║ Params  :                                                                                      ║
    // ║   - allocator: allocator                                                                       ║
    // ║   - path     : secrets file path                                                               ║
    // ║   - prefix   : key prefix to select (e.g., "ACTIVE_")                                          ║
    // ║   - logger   : optional logger                                                                 ║
    // ║ Usage   : const c = try Credentials.fromSecretsFile(gpa, "./secrets.env", "ACTIVE_", &logger); ║
    // ║ Returns :                                                                                      ║
    // ║   - Success: credentials struct                                                                ║
    // ║   - Failure: missing TLS components if enabled                                                 ║
    // ╚════════════════════════════════════════════════════════════════════════════════════════════════╝
    pub fn fromSecretsFile(allocator: std.mem.Allocator, path: []const u8, prefix: []const u8, logger: ?*const Logger) !Credentials {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        var creds: Credentials = .{};

        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();
        try file.reader().readAllArrayList(&buf, 16 * 1024);
        var it = std.mem.splitSequence(u8, buf.items, "\n");
        while (it.next()) |line| {
            if (line.len == 0 or line[0] == '#') continue;
            const eq = std.mem.indexOfScalar(u8, line, '=') orelse continue;
            const key = std.mem.trim(u8, line[0..eq], " \t\r");
            const value = std.mem.trim(u8, line[eq + 1 ..], " \t\r");
            if (!std.mem.startsWith(u8, key, prefix)) continue;
            if (std.mem.endsWith(u8, key, "USER")) {
                creds.user = try dup(allocator, value);
            } else if (std.mem.endsWith(u8, key, "PASSWORD")) {
                creds.password = try dup(allocator, value);
            } else if (std.mem.endsWith(u8, key, "TLS_ENABLE")) {
                creds.tls_enabled = std.ascii.eqlIgnoreCase(value, "1") or std.ascii.eqlIgnoreCase(value, "true");
            } else if (std.mem.endsWith(u8, key, "TLS_CA_FILE")) {
                creds.tls_ca_file = try dup(allocator, value);
            } else if (std.mem.endsWith(u8, key, "TLS_CERT_FILE")) {
                creds.tls_cert_file = try dup(allocator, value);
            } else if (std.mem.endsWith(u8, key, "TLS_KEY_FILE")) {
                creds.tls_key_file = try dup(allocator, value);
            }
        }
        try creds.validate(logger);
        return creds;
    }

    fn dup(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
        const out = try allocator.alloc(u8, s.len);
        std.mem.copy(u8, out, s);
        return out;
    }
};