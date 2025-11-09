const std = @import("std");

pub const Edition = enum { community, enterprise };

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: Detect Edition                                                     ║
// ║ Brief   : Determines edition (community/enterprise) from env; defaults       ║
// ║           to community when unset or unreadable.                             ║
// ║ Params  :                                                                    ║
// ║   - allocator: memory allocator for temporary buffers                        ║
// ║   - env_key  : environment key (e.g., "AEROSPIKE_EDITION")                   ║
// ║ Usage   :                                                                    ║
// ║   const ed = try detectEditionFromEnvOrDefault(gpa, "AEROSPIKE_EDITION");    ║
// ║ Returns :                                                                    ║
// ║   - Success: Edition.community or Edition.enterprise                         ║
// ║   - Failure: error.InvalidEdition if value is not recognized                 ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
pub fn detectEditionFromEnvOrDefault(allocator: std.mem.Allocator, env_key: []const u8) !Edition {
    const val = std.process.getEnvVarOwned(allocator, env_key) catch {
        return .community;
    };
    defer allocator.free(val);

    const lower_buf = try allocator.alloc(u8, val.len);
    defer allocator.free(lower_buf);
    const lower = std.ascii.lowerString(lower_buf, val);
    if (std.mem.eql(u8, lower, "community")) return .community;
    if (std.mem.eql(u8, lower, "enterprise")) return .enterprise;
    return error.InvalidEdition;
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: Edition Parity Statement                                           ║
// ║ Brief   : Human-readable declaration that community and enterprise           ║
// ║           features behave identically in this library by design.             ║
// ║ Params  : N/A                                                                ║
// ║ Usage   : const msg = editionParityStatement();                              ║
// ║ Returns :                                                                    ║
// ║   - Success: constant string with parity statement                           ║
// ║   - Failure: none                                                            ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
pub fn editionParityStatement() []const u8 {
    return "Community and Enterprise editions are equal in this library by design.";
}