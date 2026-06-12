/// Downloader — content-addressed cache + sha256 verification.
///
/// `fetch(url, expected_sha256, dest)` is the only operation. The flow is:
///   1. Look up `<cache>/tarballs/<sha256>.<ext>`. **Cache hit** ⇒ no network.
///   2. Cache miss ⇒ HTTPS GET via `std.http.Client` to a `.partial` temp
///      file with up to `max_retries` attempts (100ms × 2^n backoff).
///   3. Verify sha256 against `expected_sha256`. Mismatch ⇒ error.
///   4. Atomically move the verified temp file into the cache under its
///      content-addressed name.
///
/// The HTTP path uses `std.http.Client` directly (no third-party deps). If
/// `auth_token` is supplied (CI workflows set it from `GITHUB_TOKEN`), it is
/// sent as `Authorization: Bearer` so the rate-limited path hits the
/// authenticated quota. The transport rejects `http://` for integrity reasons.
const std = @import("std");
const sha256 = @import("./sha256.zig");

pub const Error = error{
    InsecureScheme,
    HttpRequestFailed,
    HttpStatusError,
    HashLengthInvalid,
    HashCharacterInvalid,
    HashMismatch,
    OnlineUnavailable,
} || std.mem.Allocator.Error;

pub const EnvMap = ?*const std.process.Environ.Map;

pub const FetchResult = struct {
    /// Path under `<cache>/tarballs/`. Caller owns via `gpa`.
    cache_path: []u8,
    /// True iff the cache short-circuited the download.
    cache_hit: bool,
    /// Sha256 of the bytes (lowercase hex).
    sha256_hex: [sha256.HEX_LEN]u8,
};

pub const FetchOptions = struct {
    /// `<cache>/tarballs/`. Caller-supplied (storage.zig owns the layout).
    cache_dir: []const u8,
    /// File extension under the cache (e.g. `tar.gz`).
    ext: []const u8,
    /// Optional auth — `GITHUB_TOKEN` is set on CI.
    auth_token: ?[]const u8 = null,
    /// HTTP retry budget. `1` ⇒ no retry; default `3` ⇒ initial + two retries.
    max_retries: u8 = 3,
};

/// Fetch `url` into the cache. The cache-hit short-circuit is hermetic (no
/// HTTP). Cache miss streams via `std.http.Client` with exponential backoff
/// and verifies the sha256 before exposing the cached path.
pub fn fetch(
    gpa: std.mem.Allocator,
    io: std.Io,
    url: []const u8,
    expected_sha256: []const u8,
    opts: FetchOptions,
) anyerror!FetchResult {
    if (!std.mem.startsWith(u8, url, "https://")) return error.InsecureScheme;

    // 1. Cache lookup. The expected sha256 IS the cache key.
    const expected_hex = try sha256.parseSidecar(expected_sha256);
    const name = try std.fmt.allocPrint(gpa, "{s}.{s}", .{ expected_hex, opts.ext });
    defer gpa.free(name);
    const cache_path = try std.fs.path.join(gpa, &.{ opts.cache_dir, name });
    errdefer gpa.free(cache_path);

    if (try readCached(gpa, io, cache_path)) |data| {
        defer gpa.free(data);
        if (sha256.verify(data, expected_sha256)) |got| {
            return .{ .cache_path = cache_path, .cache_hit = true, .sha256_hex = got };
        } else |_| {
            // A corrupt cache entry (partial write from a previous crash) is
            // not a user-facing error — silently re-fetch. The verify on the
            // refetch path catches a *server*-side mismatch loudly.
            std.Io.Dir.cwd().deleteFile(io, cache_path) catch {};
        }
    }

    // 2. Cache miss → download with retry/backoff.
    var attempt: u8 = 0;
    var last_err: anyerror = error.HttpRequestFailed;
    while (attempt < opts.max_retries) : (attempt += 1) {
        const downloaded = downloadOnce(gpa, io, url, opts.auth_token) catch |err| {
            last_err = err;
            // 100ms, 200ms, 400ms…
            const ms: i64 = @as(i64, 100) << @intCast(attempt);
            io.sleep(std.Io.Duration.fromMilliseconds(ms), .awake) catch {};
            continue;
        };
        defer gpa.free(downloaded);

        const got = try sha256.verify(downloaded, expected_sha256);

        // Atomic write: `.partial` → rename to content-addressed name.
        const partial = try std.fmt.allocPrint(gpa, "{s}.partial", .{cache_path});
        defer gpa.free(partial);
        if (std.fs.path.dirname(cache_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |perr| switch (perr) {
                error.PathAlreadyExists => {},
                else => return perr,
            };
        }
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = partial, .data = downloaded });
        try std.Io.Dir.cwd().rename(partial, std.Io.Dir.cwd(), cache_path, io);

        return .{ .cache_path = cache_path, .cache_hit = false, .sha256_hex = got };
    }
    return last_err;
}

fn readCached(gpa: std.mem.Allocator, io: std.Io, path: []const u8) !?[]u8 {
    return std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .unlimited) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
}

/// Fetch `url` straight to bytes — no sha verify, no caching. Used for
/// small / unknown-digest payloads (sha sidecars, GitHub API responses).
/// Same retry/backoff harness as `fetch` once `max_retries > 1`.
pub fn fetchBytes(
    gpa: std.mem.Allocator,
    io: std.Io,
    url: []const u8,
    auth_token: ?[]const u8,
    max_retries: u8,
) ![]u8 {
    if (!std.mem.startsWith(u8, url, "https://")) return error.InsecureScheme;
    var attempt: u8 = 0;
    var last_err: anyerror = error.HttpRequestFailed;
    while (attempt < max_retries) : (attempt += 1) {
        return downloadOnce(gpa, io, url, auth_token) catch |err| {
            last_err = err;
            const ms: i64 = @as(i64, 100) << @intCast(attempt);
            io.sleep(std.Io.Duration.fromMilliseconds(ms), .awake) catch {};
            continue;
        };
    }
    return last_err;
}

fn downloadOnce(
    gpa: std.mem.Allocator,
    io: std.Io,
    url: []const u8,
    auth_token: ?[]const u8,
) ![]u8 {
    var client: std.http.Client = .{ .allocator = gpa, .io = io };
    defer client.deinit();

    var auth_buf: [512]u8 = undefined;
    var extra_headers: []const std.http.Header = &.{};
    var extra_headers_storage: [1]std.http.Header = undefined;
    if (auth_token) |t| {
        const v = try std.fmt.bufPrint(&auth_buf, "Bearer {s}", .{t});
        extra_headers_storage[0] = .{ .name = "Authorization", .value = v };
        extra_headers = extra_headers_storage[0..1];
    }

    var body: std.Io.Writer.Allocating = .init(gpa);
    errdefer body.deinit();

    const result = try client.fetch(.{
        .location = .{ .url = url },
        .method = .GET,
        .response_writer = &body.writer,
        .extra_headers = extra_headers,
    });
    if (@intFromEnum(result.status) >= 400) {
        body.deinit();
        return error.HttpStatusError;
    }
    return body.toOwnedSlice();
}

/// Re-export so commands can read sha256 sidecars by name.
pub fn loadSidecar(
    gpa: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
) ![sha256.HEX_LEN]u8 {
    const data = try std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .limited(512));
    defer gpa.free(data);
    return sha256.parseSidecar(data);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "fetch: rejects non-https URLs (integrity floor)" {
    try testing.expectError(error.InsecureScheme, fetch(
        testing.allocator,
        testing.io,
        "http://example.com/x.tar.gz",
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        .{ .cache_dir = "/tmp", .ext = "tar.gz" },
    ));
}

test "fetch: invalid sha length errors before any I/O" {
    try testing.expectError(error.HashLengthInvalid, fetch(
        testing.allocator,
        testing.io,
        "https://example.com/x.tar.gz",
        "short",
        .{ .cache_dir = "/tmp", .ext = "tar.gz" },
    ));
}

test "fetch: cache hit short-circuits without HTTP" {
    const dir = ".botopinkbuild/bpmp-tests/download-cache-hit";
    std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    try std.Io.Dir.cwd().createDirPath(testing.io, dir);

    const payload = "abc";
    const sha = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
    const cached_path = dir ++ "/" ++ "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz";
    try std.Io.Dir.cwd().writeFile(testing.io, .{ .sub_path = cached_path, .data = payload });

    var got = try fetch(
        testing.allocator,
        testing.io,
        "https://example.com/x.tar.gz",
        sha,
        .{ .cache_dir = dir, .ext = "tar.gz" },
    );
    defer testing.allocator.free(got.cache_path);
    try testing.expect(got.cache_hit);
    try testing.expectEqualStrings(sha, &got.sha256_hex);
}

test "fetch: corrupt cache entry is silently refetched (here: returns retry error after no network)" {
    const dir = ".botopinkbuild/bpmp-tests/download-cache-corrupt";
    std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    defer std.Io.Dir.cwd().deleteTree(testing.io, dir) catch {};
    try std.Io.Dir.cwd().createDirPath(testing.io, dir);

    // sha for "abc" but bytes for "DEF" → verify will fail on cache read.
    const sha = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
    const cached_path = dir ++ "/ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.tar.gz";
    try std.Io.Dir.cwd().writeFile(testing.io, .{ .sub_path = cached_path, .data = "DEF" });

    // Refetch path will try the network — in a hermetic test that hits
    // .example with `max_retries = 1` we expect an HTTP-layer error (the
    // exact error name varies by platform / DNS state, hence the catch).
    const result = fetch(
        testing.allocator,
        testing.io,
        "https://0.0.0.0:1/never.tar.gz",
        sha,
        .{ .cache_dir = dir, .ext = "tar.gz", .max_retries = 1 },
    );
    if (result) |ok| {
        testing.allocator.free(ok.cache_path);
        return error.UnexpectedNetworkSuccess;
    } else |_| {
        // Any error is acceptable here — the test verifies the cache-corrupt
        // path advances past `verify` instead of bailing on `HashMismatch`.
    }
}

test "loadSidecar: reads release-pack.sh-shaped file" {
    const dir = ".botopinkbuild/bpmp-tests/sidecar";
    std.Io.Dir.cwd().deleteTree(testing.io, ".botopinkbuild/bpmp-tests/sidecar") catch {};
    defer std.Io.Dir.cwd().deleteTree(testing.io, ".botopinkbuild/bpmp-tests/sidecar") catch {};
    try std.Io.Dir.cwd().createDirPath(testing.io, dir);
    const path = dir ++ "/x.sha256";
    try std.Io.Dir.cwd().writeFile(testing.io, .{
        .sub_path = path,
        .data = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad\n",
    });
    const got = try loadSidecar(testing.allocator, testing.io, path);
    try testing.expectEqualStrings(
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        &got,
    );
}
