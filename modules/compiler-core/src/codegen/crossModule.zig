//! Backend-agnostic cross-module link analysis.
//!
//! Built once over every module's transformed program, this index lets each
//! emitter resolve a name imported `from "<pkg>"` to the module that actually
//! emits it — so a consumer can `require`/remote-call into the owner, construct
//! an imported record with the owner's declared field order, and the owner can
//! `export` only the symbols another module actually consumes.
//!
//! commonJS, erlang, and beam_asm all share this one analysis. wasm stays
//! single-module today (see `wat.zig`), so it ignores the index.

const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");
const commonJS = @import("./commonJS.zig");
const configMod = @import("./config.zig");

const ComptimeOutput = comptimeMod.ComptimeOutput;

/// Which kind of declaration a `pub` symbol comes from. Mirrors the relevant
/// `ast.Decl` tags; the consumer uses it to pick the right call/construction
/// lowering (a record name is constructed; a `fn`/`val` is referenced).
pub const ExportKind = enum { record, @"enum", @"fn", val };

/// Where a `pub` symbol is emitted, for resolving cross-module imports.
/// `module` is the emitting module's path (e.g. `"web/http"`). `is_class`
/// marks record/struct exports whose construction needs `new` (commonJS) or
/// the owner's map shape (erlang/beam). `fields` is the declared field order
/// of a record/struct (empty otherwise) — a consumer needs it to build the map
/// for an imported record literal with positional args.
pub const ExportInfo = struct {
    module: []const u8,
    kind: ExportKind,
    is_class: bool,
    fields: []const []const u8 = &.{},
    /// Method names a record/enum export declares (empty otherwise). A consumer
    /// calling one on an imported value (`stub.thenReturn(v)`) emits no local
    /// definition of it: erlang resolves the owning module from here.
    methods: []const []const u8 = &.{},
    /// A host-backed `declare fn`: its owner emits no function of that name (the
    /// annotation's template renders at each call site), so it cannot be reached
    /// by a remote call.
    is_external: bool = false,
    /// An external whose annotations carry an `erlang` target usable at the
    /// declared arity. The erlang backend answers such a `declare fn` in its
    /// owner with a wrapper function (the template applied to the wrapper's own
    /// parameters), so a consumer can call it remotely; without a target there
    /// is nothing to wrap and the consumer keeps the bare call, which erlc
    /// rejects by name.
    erlang_backed: bool = false,
};

/// Cross-module link info, built once over every module's transformed program.
/// `exports` maps a `pub` symbol name → its emitting module + shape; `imported`
/// is the set of names some module imports (so an owner only emits an export
/// for symbols actually consumed elsewhere — single-module programs stay
/// unchanged).
pub const CrossModule = struct {
    exports: std.StringHashMap(ExportInfo),
    imported: std.StringHashMap(void),
    /// Every module path in the program → its rendered Erlang/BEAM module atom
    /// (`"std/math"` → `"std@math"`). Rendered once, in `build`, so every
    /// emitter reads one spelling of the atom and the values outlive the
    /// per-module emitters that store them in their own tables.
    atoms: std.StringHashMap([]u8),
    /// Module paths whose atom cannot be used — two paths rendering the same
    /// atom, a `RESERVED` hit, or over `ATOM_MAX_BYTES`. Keyed by path, so the
    /// erlang and BEAM backends can fail exactly the modules involved with a
    /// diagnostic instead of letting one silently overwrite the other.
    atom_faults: std.StringHashMap(AtomFault),
    /// The type atoms a `duplicate_decl`/`too_long` fault quotes — rendered for
    /// the check and owned here, since no module table holds them.
    fault_atoms: std.ArrayListUnmanaged([]u8) = .empty,
    /// Owns the `fields` arrays allocated for record/struct exports.
    field_arrays: std.ArrayListUnmanaged([]const []const u8) = .empty,
    alloc: std.mem.Allocator,

    pub fn deinit(self: *CrossModule) void {
        for (self.field_arrays.items) |arr| self.alloc.free(arr);
        self.field_arrays.deinit(self.alloc);
        var ait = self.atoms.valueIterator();
        while (ait.next()) |a| self.alloc.free(a.*);
        self.atoms.deinit();
        for (self.fault_atoms.items) |a| self.alloc.free(a);
        self.fault_atoms.deinit(self.alloc);
        self.atom_faults.deinit();
        self.exports.deinit();
        self.imported.deinit();
    }

    /// Erlang/BEAM module atom of a module PATH (`"web/api/http"` →
    /// `"web@api@http"`). Falls back to the basename for a path the index never
    /// saw — the comptime evaluators emit a standalone module whose name is a
    /// placeholder, not a project module.
    pub fn atomFor(self: *const CrossModule, path: []const u8) []const u8 {
        return self.atoms.get(path) orelse moduleBasename(path);
    }

    /// Erlang/BEAM module atom of the module that emits `name`. Null when
    /// `name` isn't a cross-module export.
    pub fn ownerModuleAtom(self: *const CrossModule, name: []const u8) ?[]const u8 {
        const info = self.exports.get(name) orelse return null;
        return self.atomFor(info.module);
    }

    /// The fault that makes `path`'s atom unusable, or null.
    pub fn atomFault(self: *const CrossModule, path: []const u8) ?AtomFault {
        return self.atom_faults.get(path);
    }
};

/// Last path segment of a module path. NOT the module atom any more — it is
/// what a *source-level* name is compared against (an `import { order } from
/// "std"` namespace, a `wat.zig` import segment). The atom is `erlAtom`.
pub fn moduleBasename(path: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, path, '/')) |i| return path[i + 1 ..];
    return path;
}

// ── the Erlang/BEAM module atom (option A + A2) ───────────────────────────────
//
// `erlc` refuses a `-module` atom that differs from its file's basename, so the
// atom IS the filename and a module path cannot be carried by the directory and
// by the atom at once. This backend used to throw the directory away, which made
// the atom non-unique: `models/user.bp` and `services/user.bp` both emitted
// `-module(user)` — one silently overwrote the other in a shared output
// directory, and silently shadowed it on one code path — and eleven `libs/std`
// modules (`base64`, `crypto`, `dict`, `erlang`, `json`, `math`, `os`, `queue`,
// `random`, `sets`, `unicode`) shadowed the OTP module of the same name
// node-wide, which makes every other function of that OTP module `undef`.
//
// Option A joins the whole path with `@` — a legal UNQUOTED erlang atom, so no
// emitter, no `.S` writer and no hand-written `.erl` has to learn quoting — and
// A2 qualifies each EXTRA module one source file produces with `__<kind>__<decl>`,
// which decodes back to its origin. Both were re-verified with `erlc`/`erl` on
// OTP 29.

/// A botopink module's identity: its module path (`main`, `std/math`,
/// `models/user`). Every atom renderer takes one, so a caller cannot pass a
/// basename where a path is meant.
pub const ModuleId = struct {
    path: []const u8,

    pub fn of(path: []const u8) ModuleId {
        return .{ .path = path };
    }
};

/// Which extra module a source file produced — A2's `__<kind>__` qualifier.
/// A kind is never a free string: the segment is this enum's own tag name.
pub const Kind = enum {
    /// a `type` declared in that file — the module that holds its methods
    /// (policy 3) and the tag inside every value it builds (`typeAtom`).
    t,
    /// a `behavior` declared in that file. Reserved and emits nothing, by
    /// decision 23 — a behavior has no run-time representation.
    b,
    /// an `implement` block. Reserved; nothing emits it yet.
    im,
    /// a template body evaluated at compile time. Live.
    tpl,
    /// a decorator body evaluated at compile time. Live.
    dec,

    pub fn tag(self: Kind) []const u8 {
        return @tagName(self);
    }
};

/// A2's in-file qualifier separator, and the reason a run of `_` collapses to
/// one: the suffix has to be decodable, so `__` may not occur inside the path
/// half of an atom. It is OTP's own convention for the same purpose — `escript`
/// names its synthesised module `<script>__escript__<pid parts>`.
pub const QUALIFIER_SEP = "__";

/// The practical cap on a module atom is the FILENAME, not the 255-byte atom
/// limit: `erlc` stages its output through `<atom>.bea#`, five bytes more than
/// the atom, inside a 255-byte `NAME_MAX`. Measured on OTP 29: a 250-byte atom
/// compiles, a 251-byte one fails.
pub const ATOM_MAX_BYTES = 250;

/// OTP module names a single-segment botopink module may not render to, frozen
/// here as a source list rather than read from the running node: the atom a
/// build emits must not depend on which OTP release compiled it. `kernel` +
/// `stdlib` + the preloaded modules as shipped by OTP 29, plus the one name
/// outside those three that `libs/std` already collides with (`crypto`, from the
/// `crypto` application) — 225 names, sorted, which `isReserved` relies on.
/// Widen it by adding the name in sorted position; the test below re-checks both
/// the order and the eleven `libs/std` names.
pub const RESERVED = [_][]const u8{
    "application",           "application_controller", "application_master", "application_starter",               "argparse",               "array",
    "atomics",               "auth",                   "base64",             "beam_lib",                          "binary",                 "c",
    "calendar",              "code",                   "code_server",        "counters",                          "crypto",                 "data_publisher",
    "dets",                  "dets_server",            "dets_sup",           "dets_utils",                        "dets_v9",                "dict",
    "digraph",               "digraph_utils",          "disk_log",           "disk_log_1",                        "disk_log_server",        "disk_log_sup",
    "dist_ac",               "dist_util",              "edlin",              "edlin_context",                     "edlin_expand",           "edlin_key",
    "edlin_type_suggestion", "epp",                    "erl_abstract_code",  "erl_anno",                          "erl_bits",               "erl_boot_server",
    "erl_compile",           "erl_compile_server",     "erl_ddll",           "erl_debugger",                      "erl_distribution",       "erl_epmd",
    "erl_error",             "erl_erts_errors",        "erl_eval",           "erl_expand_records",                "erl_features",           "erl_init",
    "erl_internal",          "erl_kernel_errors",      "erl_lint",           "erl_parse",                         "erl_posix_msg",          "erl_pp",
    "erl_prim_loader",       "erl_reply",              "erl_scan",           "erl_signal_handler",                "erl_stdlib_errors",      "erl_tar",
    "erl_tracer",            "erlang",                 "erpc",               "error_handler",                     "error_logger",           "error_logger_file_h",
    "error_logger_tty_h",    "erts_code_purger",       "erts_debug",         "erts_dirty_process_signal_handler", "erts_internal",          "erts_literal_area_collector",
    "erts_trace_cleaner",    "escript",                "ets",                "eval_bits",                         "file",                   "file_io_server",
    "file_server",           "file_sorter",            "filelib",            "filename",                          "gb_sets",                "gb_trees",
    "gen",                   "gen_event",              "gen_fsm",            "gen_sctp",                          "gen_server",             "gen_statem",
    "gen_tcp",               "gen_tcp_socket",         "gen_udp",            "gen_udp_socket",                    "global",                 "global_group",
    "global_search",         "graph",                  "group",              "group_history",                     "heart",                  "inet",
    "inet6_sctp",            "inet6_tcp",              "inet6_tcp_dist",     "inet6_udp",                         "inet_config",            "inet_db",
    "inet_dns",              "inet_dns_tsig",          "inet_epmd_dist",     "inet_epmd_socket",                  "inet_gethost_native",    "inet_hosts",
    "inet_parse",            "inet_res",               "inet_sctp",          "inet_tcp",                          "inet_tcp_dist",          "inet_udp",
    "init",                  "io",                     "io_ansi",            "io_lib",                            "io_lib_format",          "io_lib_fread",
    "io_lib_pretty",         "json",                   "kernel",             "kernel_config",                     "kernel_refc",            "lists",
    "local_tcp",             "local_udp",              "log_mf_h",           "logger",                            "logger_backend",         "logger_config",
    "logger_disk_log_h",     "logger_filters",         "logger_formatter",   "logger_h_common",                   "logger_handler",         "logger_handler_watcher",
    "logger_olp",            "logger_proxy",           "logger_server",      "logger_simple_h",                   "logger_std_h",           "logger_sup",
    "man_docs",              "maps",                   "math",               "ms_transform",                      "net",                    "net_adm",
    "net_kernel",            "orddict",                "ordsets",            "os",                                "otp_internal",           "peer",
    "persistent_term",       "pg",                     "pg2",                "pool",                              "prim_buffer",            "prim_eval",
    "prim_file",             "prim_inet",              "prim_net",           "prim_socket",                       "prim_tty",               "prim_tty_sighandler",
    "prim_zip",              "proc_lib",               "proplists",          "qlc",                               "qlc_pt",                 "queue",
    "ram_file",              "rand",                   "random",             "raw_file_io",                       "raw_file_io_compressed", "raw_file_io_deflate",
    "raw_file_io_delayed",   "raw_file_io_inflate",    "raw_file_io_list",   "re",                                "records",                "rpc",
    "seq_trace",             "sets",                   "shell",              "shell_default",                     "shell_docs",             "shell_docs_markdown",
    "slave",                 "socket",                 "socket_registry",    "sofs",                              "standard_error",         "string",
    "supervisor",            "supervisor_bridge",      "sys",                "timer",                             "trace",                  "unicode",
    "unicode_util",          "uri_string",             "user_drv",           "user_sup",                          "win32reg",               "wrap_log_reader",
    "zip",                   "zlib",                   "zstd",
};

/// Whether `name` is one of `RESERVED`. Binary search — `RESERVED` is sorted.
pub fn isReserved(name: []const u8) bool {
    var lo: usize = 0;
    var hi: usize = RESERVED.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        switch (std.mem.order(u8, RESERVED[mid], name)) {
            .eq => return true,
            .lt => lo = mid + 1,
            .gt => hi = mid,
        }
    }
    return false;
}

pub const AtomError = error{
    /// A module path, or a path whose every character sanitised away, cannot
    /// name a module.
    EmptyModulePath,
    /// A declaration whose name sanitised away cannot qualify an atom.
    EmptyDeclName,
    /// An atom that does not split into 1, 3 or 4 `__`-separated parts was not
    /// produced by `erlAtom`/`erlDeclAtom`.
    UndecodableAtom,
};

/// Option A: the module path as a legal unquoted erlang atom.
///
///     1. lowercase the path
///     2. '/' → '@'
///     3. every character outside [a-z0-9_@] → '_'
///     3b. collapse a run of two or more '_' to a single '_' (so `__` is free
///         for A2's qualifier and the atom decodes)
///     4. if the first character is not [a-z], prefix "bp@"
///     5. if the result has no '@' and is RESERVED, prefix "bp@"
///
/// Rule 5 only fires for a single-segment path: any path with a directory
/// already carries a prefix and cannot collide with OTP. `main` stays `main`.
/// Caller owns the result.
pub fn erlAtom(alloc: std.mem.Allocator, id: ModuleId) (std.mem.Allocator.Error || AtomError)![]u8 {
    if (id.path.len == 0) return error.EmptyModulePath;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    var has_at = false;
    for (id.path) |raw| {
        const c = std.ascii.toLower(raw);
        const mapped: u8 = switch (c) {
            '/' => '@',
            'a'...'z', '0'...'9', '_', '@' => c,
            else => '_',
        };
        if (mapped == '_' and out.items.len > 0 and out.items[out.items.len - 1] == '_') continue;
        if (mapped == '@') has_at = true;
        try out.append(alloc, mapped);
    }
    if (out.items.len == 0) return error.EmptyModulePath;
    const first = out.items[0];
    const needs_prefix = !(first >= 'a' and first <= 'z') or (!has_at and isReserved(out.items));
    if (needs_prefix) try out.insertSlice(alloc, 0, "bp@");
    return out.toOwnedSlice(alloc);
}

/// A2: the atom of an EXTRA module one source file produces.
///
///     atom = erlAtom(path) "__" kind "__" decl [ "__" 16-hex-hash ]
///
/// `hash` belongs to a comptime producer only — one template declaration
/// evaluates to many distinct generated bodies, and the hash is what keeps a
/// re-evaluation of an identical body the same module (the content-addressing
/// the comptime server relies on). Caller owns the result.
pub fn erlDeclAtom(
    alloc: std.mem.Allocator,
    id: ModuleId,
    kind: Kind,
    decl: []const u8,
    hash: ?u64,
) (std.mem.Allocator.Error || AtomError)![]u8 {
    const base = try erlAtom(alloc, id);
    defer alloc.free(base);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    try out.appendSlice(alloc, base);
    try out.appendSlice(alloc, QUALIFIER_SEP);
    try out.appendSlice(alloc, kind.tag());
    try out.appendSlice(alloc, QUALIFIER_SEP);
    const before = out.items.len;
    for (decl) |raw| {
        const c = std.ascii.toLower(raw);
        const mapped: u8 = switch (c) {
            'a'...'z', '0'...'9', '_' => c,
            else => '_',
        };
        if (mapped == '_' and out.items.len > before and out.items[out.items.len - 1] == '_') continue;
        if (mapped == '_' and out.items.len == before) continue;
        try out.append(alloc, mapped);
    }
    if (out.items.len == before) return error.EmptyDeclName;
    if (hash) |h| {
        try out.appendSlice(alloc, QUALIFIER_SEP);
        var hex: [16]u8 = undefined;
        _ = std.fmt.bufPrint(&hex, "{x:0>16}", .{h}) catch unreachable;
        try out.appendSlice(alloc, &hex);
    }
    return out.toOwnedSlice(alloc);
}

/// The identity of a `type` declared in module `id` — the atom of the module
/// that holds its methods under policy 3 AND the tag inside every value the
/// type builds (half 3, decision 21): `erlDeclAtom(id, .t, decl)`, so
/// `type Person` in `app/models.bp` is `app@models__t__person`. One renderer,
/// because the value's tag has to name the module that formats it.
pub fn typeAtom(alloc: std.mem.Allocator, id: ModuleId, decl: []const u8) (std.mem.Allocator.Error || AtomError)![]u8 {
    return erlDeclAtom(alloc, id, .t, decl, null);
}

/// The `__v__` segment: a variant's tag, qualified by the enum it belongs to
/// and the module that declares the enum —
/// `typeAtom(id, decl) ++ "__v__" ++ lower(variant)`. `Circle` is declared in
/// five files of the ecosystem; this is what tells them apart in one node. A
/// legal unquoted atom like its prefix, and `decodeAtom` reads it back.
pub fn variantAtom(alloc: std.mem.Allocator, id: ModuleId, decl: []const u8, variant: []const u8) (std.mem.Allocator.Error || AtomError)![]u8 {
    const base = try typeAtom(alloc, id, decl);
    defer alloc.free(base);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    try out.appendSlice(alloc, base);
    try out.appendSlice(alloc, QUALIFIER_SEP);
    try out.appendSlice(alloc, VARIANT_TAG);
    try out.appendSlice(alloc, QUALIFIER_SEP);
    const before = out.items.len;
    for (variant) |raw| {
        const c = std.ascii.toLower(raw);
        const mapped: u8 = switch (c) {
            'a'...'z', '0'...'9', '_' => c,
            else => '_',
        };
        if (mapped == '_' and out.items.len > before and out.items[out.items.len - 1] == '_') continue;
        if (mapped == '_' and out.items.len == before) continue;
        try out.append(alloc, mapped);
    }
    if (out.items.len == before) return error.EmptyDeclName;
    return out.toOwnedSlice(alloc);
}

/// The segment that qualifies a variant inside its type's atom. Not a `Kind`:
/// a variant is not a module a source file produces, it is a value tag that
/// decodes back to the module which does.
pub const VARIANT_TAG = "v";

/// What an atom this module rendered came from. The reason A2 spells the
/// qualifier `__<kind>__<decl>` instead of the `#<Decl>` the first proposal
/// asked for: `#` produced text the BEAM never reads, while this decodes.
pub const Decoded = struct {
    shape: enum { module, decl, gen, variant },
    /// The module path, `@` restored to `/`. Owned by the caller.
    path: []u8,
    /// Borrowed from the atom that was decoded.
    kind: []const u8 = "",
    decl: []const u8 = "",
    hash: []const u8 = "",
    /// The `__v__` segment of a variant tag; empty for every other shape.
    variant: []const u8 = "",

    pub fn deinit(self: *Decoded, alloc: std.mem.Allocator) void {
        alloc.free(self.path);
    }
};

/// Split an atom back into its origin. `bp@` stays part of the path, because it
/// is the prefix rule 4/5 added and only the compiler knows whether it was
/// there in the source.
pub fn decodeAtom(alloc: std.mem.Allocator, atom: []const u8) (std.mem.Allocator.Error || AtomError)!Decoded {
    var parts: [5][]const u8 = undefined;
    var n: usize = 0;
    var it = std.mem.splitSequence(u8, atom, QUALIFIER_SEP);
    while (it.next()) |part| {
        if (n == parts.len) return error.UndecodableAtom;
        parts[n] = part;
        n += 1;
    }
    const path = try alloc.dupe(u8, parts[0]);
    errdefer alloc.free(path);
    for (path) |*c| {
        if (c.* == '@') c.* = '/';
    }
    return switch (n) {
        1 => .{ .shape = .module, .path = path },
        3 => .{ .shape = .decl, .path = path, .kind = parts[1], .decl = parts[2] },
        4 => .{ .shape = .gen, .path = path, .kind = parts[1], .decl = parts[2], .hash = parts[3] },
        // `<path>__t__<decl>__v__<variant>`: only a type's atom carries a
        // variant, and only under the `v` segment.
        5 => if (std.mem.eql(u8, parts[1], Kind.t.tag()) and std.mem.eql(u8, parts[3], VARIANT_TAG))
            .{ .shape = .variant, .path = path, .kind = parts[1], .decl = parts[2], .variant = parts[4] }
        else
            error.UndecodableAtom,
        else => error.UndecodableAtom,
    };
}

/// The basename a module's artifact is written under, without its extension.
/// The erlang and BEAM trees are FLAT and the filename is the atom, because
/// `erlc` demands the two be equal; commonJS, its `.d.ts` and wasm keep the
/// mirrored `<module path>` tree, because a `require` target and a wasm import
/// segment ARE the path. Caller owns the result.
pub fn outputStem(target: configMod.TargetSource, alloc: std.mem.Allocator, id: ModuleId) (std.mem.Allocator.Error || AtomError)![]u8 {
    return switch (target) {
        .erlang, .beam => try erlAtom(alloc, id),
        .commonJS, .wasm => try alloc.dupe(u8, id.path),
    };
}

/// Why a module's rendered atom cannot be used. The absence of this check is
/// the whole reason this front exists: two paths rendering one atom was a
/// silent winner, never a diagnostic.
pub const AtomFault = struct {
    atom: []const u8,
    path: []const u8,
    reason: Reason,
    /// The other module path that rendered the same atom (`duplicate`), or the
    /// other declaration name (`duplicate_decl`).
    other: []const u8 = "",
    /// The declaration whose type atom faulted. `duplicate_decl` only.
    decl: []const u8 = "",

    pub const Reason = enum { duplicate, reserved, too_long, duplicate_decl };

    /// This as the message of a `moduleOutput.Diagnostic.type`, so the failure
    /// reaches the driver naming both source modules instead of one of them
    /// quietly overwriting the other.
    pub fn message(self: AtomFault, alloc: std.mem.Allocator) ![]u8 {
        return switch (self.reason) {
            .duplicate => std.fmt.allocPrint(
                alloc,
                "modules `{s}` and `{s}` both render to the erlang module atom `{s}` — `__` is reserved as the in-file qualifier separator, so a run of `_` in a path segment collapses to one",
                .{ self.path, self.other, self.atom },
            ),
            // Two `type` declarations of one module rendering one identity: the
            // type atom lowercases the declaration name and folds every other
            // character to `_`, so `Person`/`person` and `Foo_Bar`/`FooBar` are
            // one atom — one module and one value tag for two types.
            .duplicate_decl => std.fmt.allocPrint(
                alloc,
                "types `{s}` and `{s}` of module `{s}` both render to the erlang atom `{s}` — a type's identity is its lowercased name with every other character folded to `_`",
                .{ self.decl, self.other, self.path, self.atom },
            ),
            .reserved => std.fmt.allocPrint(
                alloc,
                "module `{s}` renders to `{s}`, which is the name of an OTP module and would shadow it node-wide",
                .{ self.path, self.atom },
            ),
            .too_long => std.fmt.allocPrint(
                alloc,
                "module `{s}` renders to an erlang module atom of {d} bytes (`{s}`); the limit is {d}, because `<atom>.beam` has to be a filename",
                .{ self.path, self.atom.len, self.atom, ATOM_MAX_BYTES },
            ),
        };
    }
};

pub fn build(alloc: std.mem.Allocator, outputs: []ComptimeOutput) !CrossModule {
    var exports = std.StringHashMap(ExportInfo).init(alloc);
    errdefer exports.deinit();
    var imported = std.StringHashMap(void).init(alloc);
    errdefer imported.deinit();
    var field_arrays: std.ArrayListUnmanaged([]const []const u8) = .empty;
    errdefer {
        for (field_arrays.items) |arr| alloc.free(arr);
        field_arrays.deinit(alloc);
    }

    // Every module's erlang/BEAM atom, rendered once, plus the check whose
    // absence is this front: a second path rendering the same atom, a RESERVED
    // hit or an over-long atom is recorded against BOTH modules involved so the
    // erlang and BEAM backends can fail them with a diagnostic. A module that
    // did not lex, parse or type-check is still named here — it is a source
    // module and its atom still competes for the filename.
    var atoms = std.StringHashMap([]u8).init(alloc);
    errdefer {
        var it = atoms.valueIterator();
        while (it.next()) |a| alloc.free(a.*);
        atoms.deinit();
    }
    var atom_faults = std.StringHashMap(AtomFault).init(alloc);
    errdefer atom_faults.deinit();
    // atom text → the first module path that rendered it.
    var seen = std.StringHashMap([]const u8).init(alloc);
    defer seen.deinit();
    for (outputs) |*ct| {
        if (ct.name.len == 0) continue;
        if (atoms.contains(ct.name)) continue;
        const atom = erlAtom(alloc, .of(ct.name)) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            // A path that renders to nothing cannot name a module; leaving it
            // out of `atoms` falls back to the basename, exactly as before.
            error.EmptyModulePath, error.EmptyDeclName, error.UndecodableAtom => continue,
        };
        try atoms.put(ct.name, atom);
        const gop = try seen.getOrPut(atom);
        if (gop.found_existing) {
            try atom_faults.put(ct.name, .{ .atom = atom, .path = ct.name, .reason = .duplicate, .other = gop.value_ptr.* });
            try atom_faults.put(gop.value_ptr.*, .{ .atom = atom, .path = gop.value_ptr.*, .reason = .duplicate, .other = ct.name });
        } else {
            gop.value_ptr.* = ct.name;
        }
        if (atom.len > ATOM_MAX_BYTES) {
            try atom_faults.put(ct.name, .{ .atom = atom, .path = ct.name, .reason = .too_long });
        } else if (isReserved(atom)) {
            // Rule 5 prefixes `bp@` for a single-segment reserved name, so this
            // can only fire for a shape rule 5 does not cover. It is kept
            // because a shadowed OTP module is silent and node-wide.
            try atom_faults.put(ct.name, .{ .atom = atom, .path = ct.name, .reason = .reserved });
        }
    }

    // The same check over every `type`'s atom (half 3's identity, policy 3's
    // module): two declarations of one module rendering one atom would be one
    // module and one value tag for two types. Across modules the path already
    // tells them apart, so the check is per module. Keyed by the module path
    // like the module faults, so the module fails as a whole.
    var fault_atoms: std.ArrayListUnmanaged([]u8) = .empty;
    errdefer {
        for (fault_atoms.items) |a| alloc.free(a);
        fault_atoms.deinit(alloc);
    }
    for (outputs) |*ct| {
        const ok = switch (ct.outcome) {
            .ok => |*o| o,
            else => continue,
        };
        if (atom_faults.contains(ct.name)) continue;
        // type atom (owned) → the declaration that rendered it first.
        var seen_types = std.StringHashMap([]const u8).init(alloc);
        defer {
            var kit = seen_types.keyIterator();
            while (kit.next()) |k| alloc.free(k.*);
            seen_types.deinit();
        }
        for (ok.transformed.decls) |decl| {
            const r = switch (decl) {
                .type_ => |t| t,
                else => continue,
            };
            const atom = typeAtom(alloc, .of(ct.name), r.name) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                error.EmptyModulePath, error.EmptyDeclName, error.UndecodableAtom => continue,
            };
            if (atom.len > ATOM_MAX_BYTES) {
                try fault_atoms.append(alloc, atom);
                try atom_faults.put(ct.name, .{ .atom = atom, .path = ct.name, .reason = .too_long, .decl = r.name });
                break;
            }
            const gop = try seen_types.getOrPut(atom);
            if (gop.found_existing) {
                try fault_atoms.append(alloc, atom);
                try atom_faults.put(ct.name, .{ .atom = atom, .path = ct.name, .reason = .duplicate_decl, .other = gop.value_ptr.*, .decl = r.name });
                break;
            }
            gop.value_ptr.* = r.name;
        }
    }

    for (outputs) |*ct| {
        const ok = switch (ct.outcome) {
            .ok => |*o| o,
            else => continue,
        };
        for (ok.transformed.decls) |decl| switch (decl) {
            .type_ => |r| if (r.isPub) {
                const methods = try alloc.alloc([]const u8, r.methods.len);
                for (r.methods, 0..) |m, i| methods[i] = m.name;
                try field_arrays.append(alloc, methods);
                switch (r.shape) {
                    .record => |record_fields| {
                        const fields = try alloc.alloc([]const u8, record_fields.len);
                        for (record_fields, 0..) |f, i| fields[i] = f.name;
                        try field_arrays.append(alloc, fields);
                        try exports.put(r.name, .{ .module = ct.name, .kind = .record, .is_class = true, .fields = fields, .methods = methods });
                    },
                    .enum_ => try exports.put(r.name, .{ .module = ct.name, .kind = .@"enum", .is_class = false, .methods = methods }),
                }
            },
            // `pub fn` exports — including host-backed `#[@External.<targert>(...)]` declarations.
            // An external fn's owning module re-exports the host symbol under the
            // fn name (`exports.regItem = regItem`), so a consumer that imports it
            // `from "<lib>"` must `require` that owner just like any other export;
            // omitting externals here left such imports unresolved at the call site.
            .@"fn" => |f| if (f.isPub)
                try exports.put(f.name, .{
                    .module = ct.name,
                    .kind = .@"fn",
                    .is_class = false,
                    .is_external = f.isExternal(),
                    // An arity-branched annotation only backs the declaration
                    // when a branch matches its parameter count — the owner
                    // renders that branch into the wrapper.
                    .erlang_backed = f.isExternal() and
                        (f.externalFor("erlang") != null or
                            ast.externalArityBranchFor(f.annotations, "erlang", f.params.len) != null),
                }),
            .val => |v| if (v.isPub) try exports.put(v.name, .{ .module = ct.name, .kind = .val, .is_class = false }),
            // A `pub implement` is emitted as a namespace object; a consumer that
            // stars it (`import { Name* }`) references it as a value (`Name.m(x)`).
            .implement => |im| if (im.isPub) try exports.put(im.name, .{ .module = ct.name, .kind = .val, .is_class = false }),
            .use => |u| for (u.imports) |imp| try imported.put(imp.name(), {}),
            else => {},
        };
    }
    return .{ .exports = exports, .imported = imported, .atoms = atoms, .atom_faults = atom_faults, .fault_atoms = fault_atoms, .field_arrays = field_arrays, .alloc = alloc };
}

// ── tests: the atom, its qualifier, its decoder and the collision check ───────

const testing = std.testing;

fn expectAtom(expected: []const u8, path: []const u8) !void {
    const got = try erlAtom(testing.allocator, .of(path));
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(expected, got);
}

test "erlAtom: one segment stays itself, so `main` is unchanged" {
    try expectAtom("main", "main");
    try expectAtom("geometry", "geometry");
}

test "erlAtom: two and three segments join with `@`, unquoted" {
    try expectAtom("std@math", "std/math");
    try expectAtom("web@api@http", "web/api/http");
    // The collision the front exists to remove: one basename, two atoms.
    try expectAtom("models@user", "models/user");
    try expectAtom("services@user", "services/user");
}

test "erlAtom: a single-segment RESERVED name takes the `bp@` prefix" {
    // The eleven `libs/std` modules that shadow OTP today.
    try expectAtom("bp@math", "math");
    try expectAtom("bp@erlang", "erlang");
    try expectAtom("bp@queue", "queue");
    try expectAtom("bp@dict", "dict");
    // A path with a directory already carries a prefix, so rule 5 must NOT
    // fire — `std@math` cannot shadow `math`.
    try expectAtom("std@math", "std/math");
    try expectAtom("std@erlang", "std/erlang");
}

test "erlAtom: a character outside [a-z0-9_@] becomes `_`, and case folds" {
    try expectAtom("my_mod@user", "My-Mod/User");
    try expectAtom("a_b@c_d", "a.b/c d");
    // Rule 4: a leading non-letter takes the prefix.
    try expectAtom("bp@1st@mod", "1st/mod");
    try expectAtom("bp@_hidden", "_hidden");
}

test "erlAtom: a run of `_` collapses, so `__` stays free for the qualifier" {
    try expectAtom("my_mod@user", "my__mod/user");
    try expectAtom("a_b", "a___b");
    // …which is the pathological collision the check in `build` has to catch.
    const a = try erlAtom(testing.allocator, .of("my__mod/user"));
    defer testing.allocator.free(a);
    const b = try erlAtom(testing.allocator, .of("my_mod/user"));
    defer testing.allocator.free(b);
    try testing.expectEqualStrings(a, b);
}

test "erlAtom: a path that would exceed 250 bytes renders and is caught later" {
    const long = "a" ** 300;
    const got = try erlAtom(testing.allocator, .of(long));
    defer testing.allocator.free(got);
    // The renderer does not truncate — truncating is what made atoms collide.
    // It is `build`'s check that refuses it, with the filename limit named.
    try testing.expectEqual(@as(usize, 300), got.len);
    try testing.expect(got.len > ATOM_MAX_BYTES);
}

test "erlAtom: an empty path is an error, not an empty atom" {
    try testing.expectError(error.EmptyModulePath, erlAtom(testing.allocator, .of("")));
    // Nothing else can sanitise away: every character maps to `@` or `_`.
    try expectAtom("bp@@@@", "///");
}

test "erlDeclAtom: the kind segment is the enum tag, never a free string" {
    const cases = [_]struct { kind: Kind, want: []const u8 }{
        .{ .kind = .t, .want = "models@user__t__pessoa" },
        .{ .kind = .b, .want = "models@user__b__pessoa" },
        .{ .kind = .im, .want = "models@user__im__pessoa" },
        .{ .kind = .tpl, .want = "models@user__tpl__pessoa" },
        .{ .kind = .dec, .want = "models@user__dec__pessoa" },
    };
    for (cases) |c| {
        const got = try erlDeclAtom(testing.allocator, .of("models/user"), c.kind, "Pessoa", null);
        defer testing.allocator.free(got);
        try testing.expectEqualStrings(c.want, got);
    }
}

test "erlDeclAtom: a comptime producer carries the 16-hex content hash" {
    const got = try erlDeclAtom(testing.allocator, .of("ui/panel"), .tpl, "panel", 0x3f1a9c02b7e4d5f8);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings("ui@panel__tpl__panel__3f1a9c02b7e4d5f8", got);
}

test "erlDeclAtom: a declaration name is escaped and its `_` runs collapse" {
    const got = try erlDeclAtom(testing.allocator, .of("main"), .t, "My-Type__X", null);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings("main__t__my_type_x", got);
    try testing.expectError(error.EmptyDeclName, erlDeclAtom(testing.allocator, .of("main"), .t, "--", null));
}

test "decodeAtom: every shape round-trips to its origin" {
    const cases = [_]struct {
        atom: []const u8,
        shape: @FieldType(Decoded, "shape"),
        path: []const u8,
        kind: []const u8 = "",
        decl: []const u8 = "",
        hash: []const u8 = "",
    }{
        .{ .atom = "models@user", .shape = .module, .path = "models/user" },
        .{ .atom = "web@api@http", .shape = .module, .path = "web/api/http" },
        .{ .atom = "main", .shape = .module, .path = "main" },
        .{ .atom = "models@user__t__pessoa", .shape = .decl, .path = "models/user", .kind = "t", .decl = "pessoa" },
        .{ .atom = "std@math__b__signed", .shape = .decl, .path = "std/math", .kind = "b", .decl = "signed" },
        .{
            .atom = "ui@panel__tpl__panel__3f1a9c02b7e4d5f8",
            .shape = .gen,
            .path = "ui/panel",
            .kind = "tpl",
            .decl = "panel",
            .hash = "3f1a9c02b7e4d5f8",
        },
    };
    for (cases) |c| {
        var d = try decodeAtom(testing.allocator, c.atom);
        defer d.deinit(testing.allocator);
        try testing.expectEqual(c.shape, d.shape);
        try testing.expectEqualStrings(c.path, d.path);
        try testing.expectEqualStrings(c.kind, d.kind);
        try testing.expectEqualStrings(c.decl, d.decl);
        try testing.expectEqualStrings(c.hash, d.hash);
    }
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a__b"));
    // Five segments decode only as a variant tag: `__t__` then `__v__`.
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a__b__c__d__e"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a__tpl__c__v__e"));
}

fn expectTypeAtom(expected: []const u8, path: []const u8, decl: []const u8) !void {
    const got = try typeAtom(testing.allocator, .of(path), decl);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(expected, got);
}

fn expectVariantAtom(expected: []const u8, path: []const u8, decl: []const u8, variant: []const u8) !void {
    const got = try variantAtom(testing.allocator, .of(path), decl, variant);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(expected, got);
}

test "typeAtom: the type's identity is the `__t__` module of the file that declares it" {
    // A single-segment path, a multi-segment path.
    try expectTypeAtom("main__t__person", "main", "Person");
    try expectTypeAtom("app@models__t__person", "app/models", "Person");
    // A reserved single-segment name keeps rule 5's prefix in the path half.
    try expectTypeAtom("bp@dict__t__dict", "dict", "Dict");
    // A name that needs escaping: lowercased, every other character folded to
    // one `_`, so the atom stays unquoted and decodable.
    try expectTypeAtom("main__t__token_color", "main", "__Token__Color");
    try expectTypeAtom("main__t__http2_server", "main", "Http2-Server");
    // Over the filename limit is an error at the renderer's caller (`build`).
    const long = "Z" ** 260;
    const atom = try typeAtom(testing.allocator, .of("main"), long);
    defer testing.allocator.free(atom);
    try testing.expect(atom.len > ATOM_MAX_BYTES);
    try testing.expectError(error.EmptyDeclName, typeAtom(testing.allocator, .of("main"), "-"));
}

test "variantAtom: a variant is qualified by its enum and its module" {
    try expectVariantAtom("main__t__shape__v__circle", "main", "Shape", "Circle");
    try expectVariantAtom("app@models__t__shape__v__dot", "app/models", "Shape", "Dot");
    // The many `Circle`s of an ecosystem stay many atoms: the path differs.
    try expectVariantAtom("draw@query__t__shape__v__circle", "draw/query", "Shape", "Circle");
    // A variant whose name needs escaping.
    try expectVariantAtom("main__t__token__v__500", "main", "Token", "__500");
    try testing.expectError(error.EmptyDeclName, variantAtom(testing.allocator, .of("main"), "Token", "-"));
}

test "decodeAtom: a variant tag round-trips to {variant, path, t, decl, variant} (E15)" {
    const atom = try variantAtom(testing.allocator, .of("app/models"), "Shape", "Circle");
    defer testing.allocator.free(atom);
    var d = try decodeAtom(testing.allocator, atom);
    defer d.deinit(testing.allocator);
    try testing.expectEqual(@as(@FieldType(Decoded, "shape"), .variant), d.shape);
    try testing.expectEqualStrings("app/models", d.path);
    try testing.expectEqualStrings("t", d.kind);
    try testing.expectEqualStrings("shape", d.decl);
    try testing.expectEqualStrings("circle", d.variant);
    // And a type atom decodes as before — the `__v__` clause changed nothing.
    const ta = try typeAtom(testing.allocator, .of("app/models"), "Shape");
    defer testing.allocator.free(ta);
    var td = try decodeAtom(testing.allocator, ta);
    defer td.deinit(testing.allocator);
    try testing.expectEqual(@as(@FieldType(Decoded, "shape"), .decl), td.shape);
    try testing.expectEqualStrings("shape", td.decl);
}

test "decodeAtom: what erlDeclAtom wrote is what decodeAtom reads back" {
    const atom = try erlDeclAtom(testing.allocator, .of("ui/panel"), .tpl, "panel", 0xb7e4d5f83f1a9c02);
    defer testing.allocator.free(atom);
    var d = try decodeAtom(testing.allocator, atom);
    defer d.deinit(testing.allocator);
    try testing.expectEqual(@as(@FieldType(Decoded, "shape"), .gen), d.shape);
    try testing.expectEqualStrings("ui/panel", d.path);
    try testing.expectEqualStrings("tpl", d.kind);
    try testing.expectEqualStrings("panel", d.decl);
    try testing.expectEqualStrings("b7e4d5f83f1a9c02", d.hash);
}

test "outputStem: erlang and beam take the atom, commonJS and wasm the path" {
    const cases = [_]struct { target: configMod.TargetSource, want: []const u8 }{
        .{ .target = .erlang, .want = "std@math" },
        .{ .target = .beam, .want = "std@math" },
        .{ .target = .commonJS, .want = "std/math" },
        .{ .target = .wasm, .want = "std/math" },
    };
    for (cases) |c| {
        const got = try outputStem(c.target, testing.allocator, .of("std/math"));
        defer testing.allocator.free(got);
        try testing.expectEqualStrings(c.want, got);
    }
}

fn syntaxFailed(name: []const u8) ComptimeOutput {
    return .{ .name = name, .src = "", .outcome = .{ .parseError = .{ .parse = null } } };
}

test "build: two paths rendering one atom is a fault on BOTH, not a silent winner" {
    var outputs = [_]ComptimeOutput{
        syntaxFailed("my__mod/user"),
        syntaxFailed("my_mod/user"),
        syntaxFailed("main"),
    };
    var xc = try build(testing.allocator, &outputs);
    defer xc.deinit();

    try testing.expectEqualStrings("my_mod@user", xc.atomFor("my__mod/user"));
    try testing.expectEqualStrings("my_mod@user", xc.atomFor("my_mod/user"));
    try testing.expectEqualStrings("main", xc.atomFor("main"));

    const a = xc.atomFault("my__mod/user") orelse return error.TestExpectedFault;
    const b = xc.atomFault("my_mod/user") orelse return error.TestExpectedFault;
    try testing.expectEqual(AtomFault.Reason.duplicate, a.reason);
    try testing.expectEqual(AtomFault.Reason.duplicate, b.reason);
    try testing.expectEqualStrings("my_mod/user", a.other);
    try testing.expectEqualStrings("my__mod/user", b.other);
    try testing.expect(xc.atomFault("main") == null);

    const msg = try a.message(testing.allocator);
    defer testing.allocator.free(msg);
    try testing.expect(std.mem.indexOf(u8, msg, "my__mod/user") != null);
    try testing.expect(std.mem.indexOf(u8, msg, "my_mod/user") != null);
    try testing.expect(std.mem.indexOf(u8, msg, "my_mod@user") != null);
}

test "build: an atom over the filename limit is a fault naming the limit" {
    const long = "z" ** 260;
    var outputs = [_]ComptimeOutput{syntaxFailed(long)};
    var xc = try build(testing.allocator, &outputs);
    defer xc.deinit();
    const f = xc.atomFault(long) orelse return error.TestExpectedFault;
    try testing.expectEqual(AtomFault.Reason.too_long, f.reason);
    const msg = try f.message(testing.allocator);
    defer testing.allocator.free(msg);
    try testing.expect(std.mem.indexOf(u8, msg, "250") != null);
}

test "build: a RESERVED single-segment name is prefixed, so it raises no fault" {
    var outputs = [_]ComptimeOutput{ syntaxFailed("math"), syntaxFailed("std/math") };
    var xc = try build(testing.allocator, &outputs);
    defer xc.deinit();
    try testing.expectEqualStrings("bp@math", xc.atomFor("math"));
    try testing.expectEqualStrings("std@math", xc.atomFor("std/math"));
    try testing.expect(xc.atomFault("math") == null);
    try testing.expect(xc.atomFault("std/math") == null);
}

test "RESERVED is sorted and holds the eleven names `libs/std` already collides with" {
    for (RESERVED[1..], 0..) |name, i| {
        try testing.expect(std.mem.order(u8, RESERVED[i], name) == .lt);
    }
    for ([_][]const u8{
        "base64", "crypto", "dict",   "erlang", "json",    "math",
        "os",     "queue",  "random", "sets",   "unicode",
    }) |name| {
        try testing.expect(isReserved(name));
    }
    try testing.expect(!isReserved("main"));
    try testing.expect(!isReserved("geometry"));
    try testing.expect(!isReserved("std@math"));
}
