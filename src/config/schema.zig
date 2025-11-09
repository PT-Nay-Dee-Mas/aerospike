const std = @import("std");
const logging = @import("aero_log");
const core = @import("aero_core");
const Logger = logging.Logger;
const AeroError = core.AeroError;

pub const Schema = struct {
    namespace: []const u8,
    set_name: ?[]const u8 = null,
    default_ttl_seconds: ?u32 = null,
    allowed_bins: ?[][]const u8 = null,
    secondary_indexes: ?[][]const u8 = null,

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Validate Schema                                                ║
    // ║ Brief   : Ensures namespace is present and bins are non-empty            ║
    // ║ Params  :                                                                ║
    // ║   - logger: optional logger to print human-friendly diagnostics          ║
    // ║ Usage   : try schema.validate(&logger);                                  ║
    // ║ Returns :                                                                ║
    // ║   - Success: schema is considered valid                                  ║
    // ║   - Failure: AeroError.MissingRequiredConfig when invalid                ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn validate(self: *const Schema, logger: ?*const Logger) !void {
        if (self.namespace.len == 0) {
            if (logger) |lg| try lg.err("schema", "Namespace is required (AEROSPIKE_NAMESPACE)");
            return AeroError.MissingRequiredConfig;
        }
        if (self.allowed_bins) |bins| {
            for (bins) |b| {
                if (b.len == 0) {
                    if (logger) |lg| try lg.err("schema", "Allowed bin names must be non-empty");
                    return AeroError.MissingRequiredConfig;
                }
            }
        }
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Schema from Environment                                        ║
    // ║ Brief   : Reads namespace/set/TTL/bins/indexes from env variables        ║
    // ║ Params  :                                                                ║
    // ║   - allocator: allocator for owned strings                               ║
    // ║   - logger   : optional logger for pretty output                         ║
    // ║ Usage   : const s = try Schema.fromEnv(gpa, &logger);                    ║
    // ║ Returns :                                                                ║
    // ║   - Success: populated Schema                                            ║
    // ║   - Failure: AeroError.MissingRequiredConfig if namespace missing        ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn fromEnv(allocator: std.mem.Allocator, logger: ?*const Logger) !Schema {
        const ns = std.process.getEnvVarOwned(allocator, "AEROSPIKE_NAMESPACE") catch null;
        if (ns == null) {
            if (logger) |lg| try lg.err("schema", "AEROSPIKE_NAMESPACE is not set");
            return AeroError.MissingRequiredConfig;
        }
        defer allocator.free(ns.?);

        const set_val = std.process.getEnvVarOwned(allocator, "AEROSPIKE_SET") catch null;
        defer if (set_val) |v| allocator.free(v);

        const ttl_val = std.process.getEnvVarOwned(allocator, "AEROSPIKE_DEFAULT_TTL_SECONDS") catch null;
        defer if (ttl_val) |v| allocator.free(v);
        const ttl_opt: ?u32 = if (ttl_val) |t| std.fmt.parseInt(u32, t, 10) catch null else null;

        const bins_val = std.process.getEnvVarOwned(allocator, "AEROSPIKE_ALLOWED_BINS") catch null;
        defer if (bins_val) |v| allocator.free(v);
        const bins_opt: ?[][]const u8 = if (bins_val) |b| try parseCsvOwned(allocator, b) else null;

        const idx_val = std.process.getEnvVarOwned(allocator, "AEROSPIKE_SECONDARY_INDEXES") catch null;
        defer if (idx_val) |v| allocator.free(v);
        const idx_opt: ?[][]const u8 = if (idx_val) |i| try parseCsvOwned(allocator, i) else null;

        var schema: Schema = .{
            .namespace = try dup(allocator, ns.?),
            .set_name = if (set_val) |s| try dup(allocator, s) else null,
            .default_ttl_seconds = ttl_opt,
            .allowed_bins = bins_opt,
            .secondary_indexes = idx_opt,
        };
        try schema.validate(logger);
        return schema;
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Parse CSV (Owned)                                              ║
    // ║ Brief   : Splits a CSV into owned slices using provided allocator        ║
    // ║ Params  : allocator, csv                                                 ║
    // ║ Usage   : const bins = try parseCsvOwned(gpa, "bin1,bin2");              ║
    // ║ Returns :                                                                ║
    // ║   - Success: owned slice-of-slices                                       ║
    // ║   - Failure: allocation error                                            ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
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

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Duplicate Slice (Owned)                                        ║
    // ║ Brief   : Allocates and copies a slice                                   ║
    // ║ Params  : allocator, s                                                   ║
    // ║ Usage   : const name = try dup(gpa, "test");                             ║
    // ║ Returns :                                                                ║
    // ║   - Success: owned copy of input slice                                   ║
    // ║   - Failure: allocation error                                            ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    fn dup(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
        const out = try allocator.alloc(u8, s.len);
        std.mem.copy(u8, out, s);
        return out;
    }
};
