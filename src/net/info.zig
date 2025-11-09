const std = @import("std");
const core = @import("aero_core");
const logging = @import("aero_log");
const AeroError = core.AeroError;
const Logger = logging.Logger;

// ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
// ║ Function: Send Info Command                                                               ║
// ║ Brief   : Connects via TCP and sends Aerospike Info (text) command                        ║
// ║ Params  :                                                                                 ║
// ║   - allocator : allocator for response buffer                                             ║
// ║   - host      : server hostname or IP                                                     ║
// ║   - port      : server port (default 3000)                                                ║
// ║   - cmd       : info command (e.g., "statistics")                                         ║
// ║   - timeout_ms: connection/read timeout (currently unused)                                ║
// ║   - logger    : optional logger                                                           ║
// ║ Usage   : const resp = try sendInfo(gpa, "127.0.0.1", 3000, "statistics", 3000, &logger); ║
// ║ Returns :                                                                                 ║
// ║   - Success: owned response bytes (caller frees)                                          ║
// ║   - Failure: AeroError.ConnectionFailed on connect/read errors                            ║
// ╚═══════════════════════════════════════════════════════════════════════════════════════════╝
pub fn sendInfo(allocator: std.mem.Allocator, host: []const u8, port: u16, cmd: []const u8, _timeout_ms: u32, logger: ?*const Logger) ![]u8 {
    _ = _timeout_ms; // currently unused; kept for API parity
    // Prefer standard helper; if not available in the Zig version, fallback will be needed.
    var stream = std.net.tcpConnectToHost(allocator, host, port) catch {
        if (logger) |lg| lg.err("net", "TCP connection failed") catch {};
        return AeroError.ConnectionFailed;
    };
    defer stream.close();
    if (logger) |lg| lg.info("net", "Connected via TCP for Info command") catch {};

    // Use direct stream write/read for Zig 0.15
    const line = try std.fmt.allocPrint(allocator, "{s}\n", .{cmd});
    defer allocator.free(line);
    try stream.writeAll(line);

    // Read up to 32KB which is sufficient for typical info responses.
    var buf = try allocator.alloc(u8, 32 * 1024);
    const n = stream.read(buf) catch {
        if (logger) |lg| lg.err("net", "Failed reading Info response") catch {};
        allocator.free(buf);
        return AeroError.ConnectionFailed;
    };
    return buf[0..n];
}