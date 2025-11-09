const std = @import("std");
const lib = @import("aerospike");
const pkg = @import("pkg");

const c_allocator: std.mem.Allocator = std.heap.c_allocator;

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: aero_version (C ABI)                                               ║
// ║ Brief   : Returns a static null-terminated version string                    ║
// ║ Params  : N/A                                                                ║
// ║ Usage   : const v = aero_version();                                          ║
// ║ Returns :                                                                    ║
// ║   - Success: pointer to static C string                                      ║
// ║   - Failure: N/A                                                             ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
var VERSION_BUF: [128]u8 = undefined;

export fn aero_version() [*:0]const u8 {
    return std.fmt.bufPrintZ(&VERSION_BUF, "{s}/{s}", .{ pkg.pkg_name, pkg.pkg_version });
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: aero_detect_edition (C ABI)                                        ║
// ║ Brief   : Detect edition from env key; returns code                          ║
// ║ Params  : env_key (C string, e.g. "AEROSPIKE_EDITION")                       ║
// ║ Usage   : int code = aero_detect_edition("AEROSPIKE_EDITION");               ║
// ║ Returns :                                                                    ║
// ║   - Success: 0=community, 1=enterprise                                       ║
// ║   - Failure: -1 invalid                                                      ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
export fn aero_detect_edition(env_key: [*:0]const u8) c_int {
    const key = std.mem.span(env_key);
    const result = lib.detectEditionFromEnvOrDefault(c_allocator, key) catch {
        return -1;
    };
    return switch (result) {
        .community => 0,
        .enterprise => 1,
    };
}

const Client = lib.Client;

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: aero_client_init_default (C ABI)                                   ║
// ║ Brief   : Initializes client from env config with internal logger            ║
// ║ Params  : N/A                                                                ║
// ║ Usage   : void* h = aero_client_init_default();                              ║
// ║ Returns :                                                                    ║
// ║   - Success: non-null opaque handle                                          ║
// ║   - Failure: null                                                            ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
export fn aero_client_init_default() ?*anyopaque {
    const conf = lib.ClientConfig.initDefault(c_allocator) catch {
        return null;
    };
    var client = lib.Client.init(c_allocator, conf) catch {
        return null;
    };
    const ptr = c_allocator.create(Client) catch {
        client.deinit();
        return null;
    };
    ptr.* = client;
    return @ptrCast(ptr);
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: aero_client_deinit (C ABI)                                         ║
// ║ Brief   : Deinitializes client and frees the handle                          ║
// ║ Params  : handle (opaque pointer)                                            ║
// ║ Usage   : aero_client_deinit(h);                                             ║
// ║ Returns : N/A                                                                ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
export fn aero_client_deinit(handle: ?*anyopaque) void {
    if (handle) |h| {
        const ptr: *Client = @as(*Client, @ptrCast(@alignCast(h)));
        ptr.deinit();
        c_allocator.destroy(ptr);
    }
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: aero_client_connect (C ABI)                                        ║
// ║ Brief   : Connects using active then passive failover                        ║
// ║ Params  : handle (opaque pointer)                                            ║
// ║ Usage   : int rc = aero_client_connect(h);                                   ║
// ║ Returns :                                                                    ║
// ║   - Success: 0                                                               ║
// ║   - Failure: -1                                                              ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
export fn aero_client_connect(handle: ?*anyopaque) c_int {
    if (handle == null) return -1;
    const ptr: *Client = @as(*Client, @ptrCast(@alignCast(handle.?)));
    return if (ptr.connect()) |_| 0 else |_| -1;
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: aero_client_ping (C ABI)                                           ║
// ║ Brief   : Pings cluster via Info `statistics`                                ║
// ║ Params  : handle (opaque pointer)                                            ║
// ║ Usage   : int ok = aero_client_ping(h);                                      ║
// ║ Returns :                                                                    ║
// ║   - Success: 1                                                               ║
// ║   - Failure: 0                                                               ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
export fn aero_client_ping(handle: ?*anyopaque) c_int {
    if (handle == null) return 0;
    const ptr: *Client = @as(*Client, @ptrCast(@alignCast(handle.?)));
    const ok = ptr.ping() catch {
        return 0;
    };
    return if (ok) 1 else 0;
}

// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║ Function: aero_free (C ABI)                                                  ║
// ║ Brief   : Convenience free for memory returned by this library               ║
// ║ Params  : ptr                                                                ║
// ║ Usage   : aero_free(buf);                                                    ║
// ║ Returns : N/A                                                                ║
// ╚══════════════════════════════════════════════════════════════════════════════╝
export fn aero_free(ptr: ?*anyopaque) void {
    if (ptr) |p| std.c.free(p);
}
