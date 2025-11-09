const std = @import("std");

pub const LogLevel = enum { trace, debug, info, warn, err, off };

pub const Logger = struct {
    level: LogLevel = .info,

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Initialize Logger                                              ║
    // ║ Brief   : Creates ANSI-styled logger with log level control              ║
    // ║ Params  :                                                                ║
    // ║   - level: desired LogLevel                                              ║
    // ║ Usage   :                                                                ║
    // ║   var logger = Logger.init(.debug);                                      ║
    // ║   try logger.info("Connected");                                          ║
    // ║ Returns :                                                                ║
    // ║   - Success: Logger ready to print messages                              ║
    // ║   - Failure: none (stderr sink)                                          ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn init(level: LogLevel) Logger {
        return .{ .level = level };
    }

    fn should(self: *const Logger, level: LogLevel) bool {
        return switch (self.level) {
            .off => false,
            .err => level == .err,
            .warn => level == .warn or level == .err,
            .info => level == .info or level == .warn or level == .err,
            .debug => level == .debug or level == .info or level == .warn or level == .err,
            .trace => true,
        };
    }

    fn color(level: LogLevel) []const u8 {
        return switch (level) {
            .trace => "\x1b[90m",
            .debug => "\x1b[36m",
            .info => "\x1b[32m",
            .warn => "\x1b[33m",
            .err => "\x1b[31;1m",
            .off => "",
        };
    }

    fn label(level: LogLevel) []const u8 {
        return switch (level) {
            .trace => "TRACE",
            .debug => "DEBUG",
            .info => "INFO",
            .warn => "WARN",
            .err => "ERROR",
            .off => "",
        };
    }

    fn reset() []const u8 {
        return "\x1b[0m";
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Log Line                                                       ║
    // ║ Brief   : Prints styled message with level, timestamp, and module tag    ║
    // ║ Params  :                                                                ║
    // ║   - level : severity level                                               ║
    // ║   - module: short module label                                           ║
    // ║   - msg   : message to print                                             ║
    // ║ Usage   : logger.log(.info, "client", "Connected to cluster");           ║
    // ║ Returns :                                                                ║
    // ║   - Success: message printed to stderr                                   ║
    // ║   - Failure: I/O error if stderr fails                                   ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn log(self: *const Logger, level: LogLevel, module: []const u8, msg: []const u8) !void {
        if (!self.should(level)) return;
        const ts = std.time.milliTimestamp();
        std.debug.print("{s}╔ {s} [{s}] {d}ms{s}\n", .{ color(level), label(level), module, ts, reset() });
        std.debug.print("{s}║ {s}{s}\n", .{ color(level), msg, reset() });
        std.debug.print("{s}╚══════════════════════════════════════════════════════════════{s}\n", .{ color(level), reset() });
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Trace                                                          ║
    // ║ Brief   : Convenience wrapper for trace-level logging                    ║
    // ║ Params  : module, msg                                                    ║
    // ║ Usage   : logger.trace("net", "dialing...");                             ║
    // ║ Returns : Success prints; Failure I/O error                              ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn trace(self: *const Logger, module: []const u8, msg: []const u8) !void {
        try self.log(.trace, module, msg);
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Debug                                                          ║
    // ║ Brief   : Convenience wrapper for debug-level logging                    ║
    // ║ Params  : module, msg                                                    ║
    // ║ Usage   : logger.debug("client", "state updated");                       ║
    // ║ Returns : Success prints; Failure I/O error                              ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn debug(self: *const Logger, module: []const u8, msg: []const u8) !void {
        try self.log(.debug, module, msg);
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Info                                                           ║
    // ║ Brief   : Convenience wrapper for info-level logging                     ║
    // ║ Params  : module, msg                                                    ║
    // ║ Usage   : logger.info("client", "connected");                            ║
    // ║ Returns : Success prints; Failure I/O error                              ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn info(self: *const Logger, module: []const u8, msg: []const u8) !void {
        try self.log(.info, module, msg);
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Warn                                                           ║
    // ║ Brief   : Convenience wrapper for warn-level logging                     ║
    // ║ Params  : module, msg                                                    ║
    // ║ Usage   : logger.warn("client", "retrying passive");                     ║
    // ║ Returns : Success prints; Failure I/O error                              ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn warn(self: *const Logger, module: []const u8, msg: []const u8) !void {
        try self.log(.warn, module, msg);
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Error                                                          ║
    // ║ Brief   : Convenience wrapper for error-level logging                    ║
    // ║ Params  : module, msg                                                    ║
    // ║ Usage   : logger.err("net", "connection failed");                        ║
    // ║ Returns : Success prints; Failure I/O error                              ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn err(self: *const Logger, module: []const u8, msg: []const u8) !void {
        try self.log(.err, module, msg);
    }
};