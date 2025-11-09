# Aerospike Zig Library (CE/EE Parity)

> Modern, production-ready Zig library to connect to Aerospike Community Edition (CE) and Enterprise Edition (EE) with identical behavior by design.

[![Zig](https://img.shields.io/badge/Zig-%3E=%200.15.2-orange)](https://ziglang.org/) [![OS](https://img.shields.io/badge/OS-macOS%20%7C%20Linux-blue)](#requirements) [![FFI](https://img.shields.io/badge/FFI-C%20ABI-green)](#c-ffi)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Zig Package Manager](#zig-package-manager)
  - [Build From Source](#build-from-source)
- [Quickstart (Zig)](#quickstart-zig)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [C FFI](#c-ffi)
- [Language Integrations](#language-integrations)
  - [Java (JNI/JNA)](#java-jni-jna)
  - [PHP (FFI)](#php-ffi)
  - [Go (cgo)](#go-cgo)
  - [Rust (bindgen)](#rust-bindgen)
  - [Python (ctypes/cffi)](#python-ctypes-cffi)
  - [JavaScript (Node.js ffi-napi)](#javascript-nodejs-ffi-napi)
  - [JavaScript (Bun FFI)](#javascript-bun-ffi)
- [Versioning](#versioning)
- [Design Principles](#design-principles)
- [FAQ](#faq)
- [Contributing](#contributing)

---

## Overview
This library provides a robust Zig interface for connecting to an Aerospike cluster. It is engineered for large-scale, enterprise-grade deployments and guarantees parity between CE and EE: all features behave identically regardless of edition.

Use cases:
- Configure an active endpoint and optionally a passive endpoint for failover.
- Manage credentials from environment or a secrets file.
- Validate required configuration inputs with clear, actionable error messages.
- Use structured logging with levels.

## Features

| Feature | Description |
| --- | --- |
| CE/EE Parity | Identical features and behaviors across both editions. |
| Active/Passive Endpoints | Simple failover when the active is down. |
| Env & Secrets | Credentials from env or a secrets file. |
| Config Validation | Detailed, human-readable validations and hints. |
| Structured Logging | Rich levels: trace, debug, info, warn, err, off. |
| FFI (C ABI) | Dynamic library + header for multi-language consumption. |

## Requirements

| Component | Version |
| --- | --- |
| Zig | >= 0.15.2 |
| Java | 25.0.1 |
| PHP | 8.4.14 |
| Go | 1.25.4 |
| Rust | 1.91.0 |
| Python | 3.14.0 |
| JavaScript (Node.js) | 24.11.0 |
| JavaScript (Bun) | 1.3.2 |
| OS | macOS or Linux |

> Note: Non-Zig languages use the generated dynamic library (`libaerospike.{dylib,so}`) and C header (`include/aerospike.h`).

## Installation

### Zig Package Manager
Add the dependency to your `build.zig.zon` with a single command:

```sh
# From your project root (where build.zig.zon lives)
zig fetch --save https://github.com/PT-Nay-Dee-Mas/aerospike/archive/refs/tags/v1.1.0.tar.gz
```

Wire the module in your `build.zig`:

```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Obtain dependency and module
    const aerospike_dep = b.dependency("aerospike", .{});
    const aerospike_mod = aerospike_dep.module("aerospike");

    const exe = b.addExecutable(.{
        .name = "my-app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{ .{ .name = "aerospike", .module = aerospike_mod } },
        }),
    });
    b.installArtifact(exe);
}
```

### Build From Source

```sh
# Clone
git clone https://github.com/PT-Nay-Dee-Mas/aerospike
cd aerospike

# Build and run tests
zig build test

# Build shared library and install artifacts
zig build
# Artifacts are installed under zig-out/
#   - zig-out/lib/libaerospike.dylib      (macOS)
#   - zig-out/lib/libaerospike.so         (Linux)
#   - include/aerospike.h                 (C header)
```

## Quickstart (Zig)

```zig
const std = @import("std");
const aerospike = @import("aerospike");

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    // Load default config from env (active + optional passive)
    const cfg = try aerospike.ClientConfig.initDefault(gpa);

    // Create client
    var client = try aerospike.Client.init(gpa, cfg);
    defer client.deinit();

    // Connect (active, then passive failover)
    try client.connect();

    // Optionally ping
    const ok = try client.ping();
    std.debug.print("Ping result: {any}\n", .{ok});
}
```

## Configuration
Set environment variables to configure endpoints and credentials.

| Key | Type | Required | Notes |
| --- | --- | --- | --- |
| `AEROSPIKE_EDITION` | `community` or `enterprise` | Yes | CE/EE parity. |
| `AEROSPIKE_ACTIVE_HOSTS` | CSV of hosts | Yes | e.g., `10.0.0.1,10.0.0.2`. |
| `AEROSPIKE_ACTIVE_PORT` | `u16` | No | Defaults to `3000`. |
| `AEROSPIKE_ACTIVE_CONNECT_TIMEOUT_MS` | `u32` | No | Defaults to `5000`. |
| `AEROSPIKE_ACTIVE_READ_TIMEOUT_MS` | `u32` | No | Defaults to `5000`. |
| `AEROSPIKE_ACTIVE_CLUSTER_NAME` | string | No | Optional cluster name. |
| `AEROSPIKE_ACTIVE_USER` | string | Conditional | If PASSWORD set, USER must be set too. |
| `AEROSPIKE_ACTIVE_PASSWORD` | string | Conditional | Either both set or neither. |
| `AEROSPIKE_ACTIVE_TLS_ENABLE` | bool | No | Enable TLS. |
| `AEROSPIKE_ACTIVE_TLS_CA_FILE` | path | Conditional | Required when TLS enabled. |
| `AEROSPIKE_ACTIVE_TLS_CERT_FILE` | path | Conditional | Required when TLS enabled. |
| `AEROSPIKE_ACTIVE_TLS_KEY_FILE` | path | Conditional | Required when TLS enabled. |
| `AEROSPIKE_PASSIVE_HOSTS` | CSV of hosts | No | Passive endpoint optional. |
| `AEROSPIKE_PASSIVE_PORT` | `u16` | No | Defaults to `3000`. |
| `AEROSPIKE_PASSIVE_CONNECT_TIMEOUT_MS` | `u32` | No | Defaults to `5000`. |
| `AEROSPIKE_PASSIVE_READ_TIMEOUT_MS` | `u32` | No | Defaults to `5000`. |
| `AEROSPIKE_PASSIVE_CLUSTER_NAME` | string | No | Optional cluster name. |

Schema (application-level):

| Key | Type | Required | Notes |
| --- | --- | --- | --- |
| `AEROSPIKE_NAMESPACE` | string | Yes (if schema used) | Namespace name (e.g., `test`). |
| `AEROSPIKE_SET` | string | No | Default set name; optional. |
| `AEROSPIKE_DEFAULT_TTL_SECONDS` | `u32` | No | Default record TTL; `null`/missing means server default. |
| `AEROSPIKE_ALLOWED_BINS` | CSV strings | No | Whitelist of bin names expected by the app. |
| `AEROSPIKE_SECONDARY_INDEXES` | CSV strings | No | Index names (declarative only; not auto-created). |

## API Reference
Public APIs available via `const aerospike = @import("aerospike");`.

| Symbol | Kind | Signature (simplified) | Description |
| --- | --- | --- | --- |
| `Edition` | enum | `community | enterprise` | Aerospike editions. |
| `detectEditionFromEnvOrDefault` | fn | `(allocator, env_key) !Edition` | Reads edition from env with defaults. |
| `Client` | struct | methods below | Aerospike client with failover. |
| `Client.init` | fn | `(allocator, cfg) !Client` | Initialize client with logger. |
| `Client.deinit` | fn | `(self: *Client) void` | Free resources. |
| `Client.connect` | fn | `(self: *Client) !void` | Connect (active then passive). |
| `Client.ping` | fn | `(self: *Client) !bool` | Info `statistics` check. |
| `ClientConfig` | struct | methods below | Config for client. |
| `ClientConfig.initDefault` | fn | `(allocator) !ClientConfig` | Build config from env. |
| `DatabaseEndpoint` | struct | methods below | Endpoint description. |
| `DatabaseEndpoint.fromEnv` | fn | `(allocator, prefix, logger) !DatabaseEndpoint` | Parse endpoint from env prefix. |
| `DatabaseEndpoint.validate` | fn | `(self, logger) !void` | Validate endpoint fields. |
| `Credentials` | struct | methods below | Authentication data. |
| `Credentials.fromEnv` | fn | `(allocator, prefix, logger) !Credentials` | Parse credentials from env. |
| `Credentials.fromSecretsFile` | fn | `(allocator, path, prefix, logger) !Credentials` | Parse credentials from file. |
| `Credentials.validate` | fn | `(self, logger) !void` | Validate credentials. |
| `Logger` | struct | `init(level)` + level fns | Structured logging. |
| `LogLevel` | enum | `trace|debug|info|warn|err|off` | Logging levels. |
| `version` | fn | `() []const u8` | Library version string. |

Internal/sub-module helpers:

| Symbol | Kind | Signature | Module |
| --- | --- | --- | --- |
| `sendInfo` | fn | `(allocator, host, port, cmd, timeout_ms, logger) ![]u8` | `aero_net` |
| `AeroError` | error set | `ConnectionFailed | ...` | `aero_core` |
| `editionParityStatement` | fn | `() []const u8` | `aero_core` |
| `boxMessage` | fn | `(allocator, title, color, body) ![]u8` | `aero_util` |

> Tip: Most applications only need `ClientConfig`, `Client`, `Logger`, and `Edition`.

## C FFI
This project ships a C ABI for multi-language consumption.

| Artifact | Path |
| --- | --- |
| Dynamic Library | `zig-out/lib/libaerospike.dylib` (macOS) / `zig-out/lib/libaerospike.so` (Linux) |
| Header | `include/aerospike.h` |

C ABI functions:

| Function | Return | Brief |
| --- | --- | --- |
| `const char* aero_version(void)` | `char*` | Version string. |
| `int32_t aero_detect_edition(const char* env_key)` | `int32_t` | `0=community, 1=enterprise, -1=invalid`. |
| `aero_client_t aero_client_init_default(void)` | `void*` | Initialize client from env (opaque handle). |
| `void aero_client_deinit(aero_client_t handle)` | `void` | Free client handle. |
| `int32_t aero_client_connect(aero_client_t handle)` | `int32_t` | `0=success, -1=failure`. |
| `int32_t aero_client_ping(aero_client_t handle)` | `int32_t` | `1=success, 0=failure`. |
| `void aero_free(void* ptr)` | `void` | Free library-allocated memory. |

Linking notes:
- macOS: set `DYLD_LIBRARY_PATH` or `install_name_tool` per your workflow.
- Linux: set `LD_LIBRARY_PATH` or install to a standard lib directory.

## Language Integrations
Each language below shows how to add this library via your toolchain and perform a basic connect/ping.

### Java (JNI/JNA)
Version: 25.0.1

Using JNA (simpler, runtime binding):

```xml
<!-- build.gradle.kts or pom.xml -->
<!-- Add JNA dependency -->
<dependency>
  <groupId>net.java.dev.jna</groupId>
  <artifactId>jna</artifactId>
  <version>5.18.1</version>
</dependency>
```

```java
import com.sun.jna.*;

public interface AerospikeLib extends Library {
    AerospikeLib INSTANCE = Native.load("aerospike", AerospikeLib.class);
    String aero_version();
    int aero_detect_edition(String envKey);
    Pointer aero_client_init_default();
    void aero_client_deinit(Pointer handle);
    int aero_client_connect(Pointer handle);
    int aero_client_ping(Pointer handle);
}

public class Main {
    public static void main(String[] args) {
        // Ensure DYLD_LIBRARY_PATH / LD_LIBRARY_PATH contains zig-out/lib
        System.out.println("Version: " + AerospikeLib.INSTANCE.aero_version());
        Pointer h = AerospikeLib.INSTANCE.aero_client_init_default();
        if (h == null) throw new RuntimeException("Init failed");
        int rc = AerospikeLib.INSTANCE.aero_client_connect(h);
        if (rc != 0) throw new RuntimeException("Connect failed");
        int ok = AerospikeLib.INSTANCE.aero_client_ping(h);
        System.out.println("Ping: " + ok);
        AerospikeLib.INSTANCE.aero_client_deinit(h);
    }
}
```

### PHP (FFI)
Version: 8.4.14

```php
<?php
$header = file_get_contents(__DIR__ . '/include/aerospike.h');
$lib = FFI::cdef($header, __DIR__ . '/zig-out/lib/libaerospike.dylib'); // or .so on Linux

echo "Version: " . FFI::string($lib->aero_version()) . "\n";
$h = $lib->aero_client_init_default();
if ($h == null) die("Init failed\n");
$rc = $lib->aero_client_connect($h);
if ($rc != 0) die("Connect failed\n");
$ok = $lib->aero_client_ping($h);
echo "Ping: $ok\n";
$lib->aero_client_deinit($h);
```

### Go (cgo)
Version: 1.25.4

```go
package main

/*
#cgo LDFLAGS: -Laerospike/zig-out/lib -laerospike
#include "aerospike/include/aerospike.h"
*/
import "C"
import "fmt"

func main() {
    fmt.Println("Version:", C.GoString(C.aero_version()))
    h := C.aero_client_init_default()
    if h == nil { panic("init failed") }
    if C.aero_client_connect(h) != 0 { panic("connect failed") }
    ok := C.aero_client_ping(h)
    fmt.Println("Ping:", ok)
    C.aero_client_deinit(h)
}
```

### Rust (bindgen)
Version: 1.91.0

`Cargo.toml`:

```toml
[package]
name = "aerospike_demo"
version = "1.0.0"
edition = "2024"

[build-dependencies]
bindgen = "0.72.1"
```

`build.rs`:

```rust
fn main() {
    println!("cargo:rustc-link-lib=dylib=aerospike");
    println!("cargo:rustc-link-search=native=zig-out/lib");
    let bindings = bindgen::Builder::default()
        .header("include/aerospike.h")
        .generate()
        .expect("Unable to generate bindings");
    bindings
        .write_to_file(std::path::Path::new("src/bindings.rs"))
        .expect("Couldn't write bindings!");
}
```

`src/main.rs`:

```rust
mod bindings;
use bindings::*;
use std::ffi::CStr;

fn main() {
    unsafe {
        let v = aero_version();
        println!("Version: {}", CStr::from_ptr(v).to_str().unwrap());
        let h = aero_client_init_default();
        if h.is_null() { panic!("init failed"); }
        if aero_client_connect(h) != 0 { panic!("connect failed"); }
        let ok = aero_client_ping(h);
        println!("Ping: {}", ok);
        aero_client_deinit(h);
    }
}
```

### Python (ctypes/cffi)
Version: 3.14.0

```python
import ctypes
lib = ctypes.CDLL("zig-out/lib/libaerospike.dylib")  # or .so
lib.aero_version.restype = ctypes.c_char_p
print("Version:", lib.aero_version().decode())

lib.aero_client_init_default.restype = ctypes.c_void_p
h = lib.aero_client_init_default()
assert h
rc = lib.aero_client_connect(ctypes.c_void_p(h))
assert rc == 0
ok = lib.aero_client_ping(ctypes.c_void_p(h))
print("Ping:", ok)
lib.aero_client_deinit(ctypes.c_void_p(h))
```

### JavaScript (Node.js ffi-napi)
Version: 24.11.0

```bash
npm install ffi-napi ref-napi
```

```js
const ffi = require('ffi-napi');
const ref = require('ref-napi');
const lib = ffi.Library('zig-out/lib/libaerospike', {
  aero_version: ['string', []],
  aero_client_init_default: ['pointer', []],
  aero_client_deinit: ['void', ['pointer']],
  aero_client_connect: ['int', ['pointer']],
  aero_client_ping: ['int', ['pointer']],
});

console.log('Version:', lib.aero_version());
const h = lib.aero_client_init_default();
if (ref.isNull(h)) throw new Error('init failed');
if (lib.aero_client_connect(h) !== 0) throw new Error('connect failed');
console.log('Ping:', lib.aero_client_ping(h));
lib.aero_client_deinit(h);
```

### JavaScript (Bun FFI)
Version: 1.3.2

```ts
const { dlopen, FFIType } = Bun;
const lib = dlopen("zig-out/lib/libaerospike.dylib", {
  aero_version: { args: [], returns: FFIType.cstring },
  aero_client_init_default: { args: [], returns: FFIType.ptr },
  aero_client_deinit: { args: [FFIType.ptr], returns: FFIType.void },
  aero_client_connect: { args: [FFIType.ptr], returns: FFIType.int },
  aero_client_ping: { args: [FFIType.ptr], returns: FFIType.int },
});

console.log('Version:', lib.symbols.aero_version());
const h = lib.symbols.aero_client_init_default();
if (!h) throw new Error('init failed');
if (lib.symbols.aero_client_connect(h) !== 0) throw new Error('connect failed');
console.log('Ping:', lib.symbols.aero_client_ping(h));
lib.symbols.aero_client_deinit(h);
```

## Versioning

| Version | Zig Min | Notable Changes |
| --- | --- | --- |
| `1.0.0` | `0.15.2` | Initial CE/EE parity, active/passive failover, C FFI, logging. |
| `1.1.0` | `0.15.2` | Secret‑safe logging; optional env‑driven schema (namespace/set/TTL/bins/indexes); package name/version sourced from build.zig.zon and surfaced in version APIs |

## Design Principles

- Zig-first implementation with no external client dependency.
- Clean, modular architecture with strict doc comments and ergonomic error handling.
- Parity between CE and EE: same API surface and behavior.
- Human-readable diagnostics and logging; consistent developer experience.

## FAQ

- Does the library support both CE and EE? Yes, with identical behavior by construction.
- How do I select an edition? Set `AEROSPIKE_EDITION=community` or `enterprise`.
- Do I need TLS files? Only if `*_TLS_ENABLE=true`; then CA, cert, key paths are required.
- Where are the build artifacts? Installed under `zig-out/` after `zig build`.
- How do I use it from other languages? Link against `libaerospike` and include `aerospike.h` as shown above.

## Contributing

- Fork the repo and create a topic branch.
- Run `zig build test` to validate changes.
- Submit a PR with a concise description and tests when applicable.

---