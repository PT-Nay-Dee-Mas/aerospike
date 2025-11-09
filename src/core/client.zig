const std = @import("std");
const logging = @import("aero_log");
const Logger = logging.Logger;
const AeroError = @import("error.zig").AeroError;
const ClientConfig = @import("aero_config").ClientConfig;
const DatabaseEndpoint = @import("aero_config").DatabaseEndpoint;
const sendInfo = @import("aero_net").sendInfo;

pub const Client = struct {
    allocator: std.mem.Allocator,
    cfg: ClientConfig,
    logger: Logger,

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Initialize Client                                              ║
    // ║ Brief   : Builds client with edition, config (active/passive) and logger ║
    // ║ Params  :                                                                ║
    // ║   - allocator: allocator for owned memory                                ║
    // ║   - cfg      : client configuration                                      ║
    // ║ Usage   :                                                                ║
    // ║   var client = try Client.init(gpa, cfg);                                ║
    // ║   defer client.deinit();                                                 ║
    // ║ Returns :                                                                ║
    // ║   - Success: initialized Client                                          ║
    // ║   - Failure: allocation errors                                           ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn init(allocator: std.mem.Allocator, cfg: ClientConfig) !Client {
        return .{ .allocator = allocator, .cfg = cfg, .logger = Logger.init(.info) };
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Deinitialize Client                                            ║
    // ║ Brief   : Frees resources owned by the client                            ║
    // ║ Params  : N/A                                                            ║
    // ║ Usage   : client.deinit();                                               ║
    // ║ Returns :                                                                ║
    // ║   - Success: resources released                                          ║
    // ║   - Failure: none                                                        ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn deinit(self: *Client) void {
        _ = self;
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Connect (Active/Passive Failover)                              ║
    // ║ Brief   : Tries active endpoint first; on failure attempts passive       ║
    // ║ Params  : N/A                                                            ║
    // ║ Usage   : try client.connect();                                          ║
    // ║ Returns :                                                                ║
    // ║   - Success: connection established to active or passive                 ║
    // ║   - Failure: AeroError.ConnectionFailed if neither reachable             ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn connect(self: *Client) !void {
        try self.logger.info("client", "Starting connection attempts (active then passive)");
        if (try self.tryEndpoint(&self.cfg.active)) return;
        if (self.cfg.passive) |p| {
            try self.logger.warn("client", "Active failed; attempting passive endpoint");
            if (try self.tryEndpoint(&p)) return;
        }
        return AeroError.ConnectionFailed;
    }

    // ╔══════════════════════════════════════════════════════════════════════════╗
    // ║ Function: Ping Cluster                                                   ║
    // ║ Brief   : Uses Info protocol `statistics` to validate server response    ║
    // ║ Params  : N/A                                                            ║
    // ║ Usage   : const ok = try client.ping();                                  ║
    // ║ Returns :                                                                ║
    // ║   - Success: true when active or passive replies                         ║
    // ║   - Failure: AeroError.ConnectionFailed when neither responds            ║
    // ╚══════════════════════════════════════════════════════════════════════════╝
    pub fn ping(self: *Client) !bool {
        if (try self.tryEndpoint(&self.cfg.active)) return true;
        if (self.cfg.passive) |p| {
            if (try self.tryEndpoint(&p)) return true;
        }
        return AeroError.ConnectionFailed;
    }

    fn tryEndpoint(self: *Client, ep: *const DatabaseEndpoint) !bool {
        // ╔══════════════════════════════════════════════════════════════════════════╗
        // ║ Function: Try Endpoint                                                   ║
        // ║ Brief   : Attempts Info `statistics` against all hosts in the endpoint   ║
        // ║ Params  :                                                                ║
        // ║   - self: client instance                                                ║
        // ║   - ep  : endpoint containing hosts/port/timeouts                        ║
        // ║ Usage   : if (try self.tryEndpoint(&self.cfg.active)) return true;       ║
        // ║ Returns :                                                                ║
        // ║   - Success: true if any host returns a non-empty response               ║
        // ║   - Failure: false if none respond; may bubble AeroError on allocation   ║
        // ╚══════════════════════════════════════════════════════════════════════════╝
        for (ep.hosts) |host| {
            const resp = sendInfo(self.allocator, host, ep.port, "statistics", ep.connect_timeout_ms, &self.logger) catch {
                continue;
            };
            defer self.allocator.free(resp);
            if (resp.len > 0) {
                try self.logger.info("client", "Received statistics from server");
                return true;
            }
        }
        return false;
    }
};
