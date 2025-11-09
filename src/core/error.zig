const std = @import("std");
const logging = @import("aero_log");
const Logger = logging.Logger;

pub const AeroError = error{
    MissingRequiredCredential,
    MissingRequiredConfig,
    InvalidEdition,
    ConnectionFailed,
    OperationUnsupported,
    TLSUnavailable,
};

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: Render Pretty Error                                                ║
// ║ Brief   : Prints styled multi-line error with actionable hints               ║
// ║ Params  :                                                                    ║
// ║   - logger : Logger instance to print                                        ║
// ║   - title  : short error title                                               ║
// ║   - details: detailed description                                            ║
// ║   - hint   : helpful next-step suggestion                                    ║
// ║ Usage   :                                                                    ║
// ║   try renderError(&logger, "Connection Failed", details, "Check firewall");  ║
// ║ Returns :                                                                    ║
// ║   - Success: message printed to stderr                                       ║
// ║   - Failure: I/O error if stderr fails                                       ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
pub fn renderError(logger: *const Logger, title: []const u8, details: []const u8, hint: []const u8) !void {
    const sep = "══════════════════════════════════════════════════════════════";
    try logger.err("error", title);
    std.debug.print("\x1b[31;1m║ Details: {s}\x1b[0m\n", .{details});
    std.debug.print("\x1b[35m║ Hint   : {s}\x1b[0m\n", .{hint});
    std.debug.print("\x1b[31m╚{s}\x1b[0m\n", .{sep});
}