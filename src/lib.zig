const std = @import("std");
const core = @import("aero_core");
const cfg = @import("aero_config");
const logging = @import("aero_log");
const pkg = @import("pkg");

pub const Edition = core.Edition;
pub const detectEditionFromEnvOrDefault = @import("aero_core").detectEditionFromEnvOrDefault;
pub const Client = core.Client;
pub const ClientConfig = cfg.ClientConfig;
pub const DatabaseEndpoint = cfg.DatabaseEndpoint;
pub const Credentials = cfg.Credentials;
pub const LogLevel = logging.LogLevel;
pub const Logger = logging.Logger;

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: Library Version                                                    ║
// ║ Brief   : Returns the semantic version string for this library               ║
// ║ Params  : N/A                                                                ║
// ║ Usage   : const v = version();                                               ║
// ║ Returns :                                                                    ║
// ║   - Success: version string                                                  ║
// ║   - Failure: none                                                            ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
pub fn version() []const u8 {
    return std.fmt.comptimePrint("{s}/{s}", .{ pkg.pkg_name, pkg.pkg_version });
}
