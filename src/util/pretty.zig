const std = @import("std");

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: Box Message                                                        ║
// ║ Brief   : Formats a message inside a Unicode box with title and color        ║
// ║ Params  :                                                                    ║
// ║   - allocator: memory allocator                                              ║
// ║   - title    : title string                                                  ║
// ║   - color    : ANSI color prefix (or empty)                                  ║
// ║   - body     : message body                                                  ║
// ║ Usage   : const s = try boxMessage(gpa, "Config", "\x1b[36m", "Loaded OK");  ║
// ║ Returns :                                                                    ║
// ║   - Success: allocated boxed string (caller frees)                           ║
// ║   - Failure: allocation errors                                               ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
pub fn boxMessage(allocator: std.mem.Allocator, title: []const u8, color: []const u8, body: []const u8) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    errdefer buf.deinit();
    try buf.writer().print("{s}╔ {s}\n", .{ color, title });
    try buf.writer().print("{s}║ {s}\n", .{ color, body });
    try buf.writer().print("{s}╚════════════════════════════════════════════════════\x1b[0m\n", .{ color });
    return buf.toOwnedSlice();
}