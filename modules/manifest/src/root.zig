/// `botopink.json` — the one manifest model every tool reads.
///
/// The CLI (`compiler-cli/src/cli/config.zig`, `libs.zig`), the language server
/// (`language-server/src/project_graph.zig`), and `bpmp` (`bpmp/src/manifest.zig`,
/// `dep/spec.zig`) each used to carry their own reading of the manifest, and the
/// four readings disagreed (decisions 75 and 76 of 1.0.10-beta list how). This
/// package is the seam they now share: it depends on `std` only, so `bpmp`
/// keeps its "no compiler-core" contract while reading the same
/// fields, the same shapes and the same errors as the compiler.
///
/// Two kinds of manifest (decision 75):
///
///   * a **package** — `name`, `version`, `src`, `entry`, `files`, `target`,
///     `targets`, `dependencies`; what `botopink build/test` compiles and what a
///     consumer imports by name;
///   * a **workspace** — `"workspaces": ["modules/*", "examples/*"]`; never a
///     package (no `src`/`files`/`entry`/`dependencies`), it only declares its
///     **members**: every directory an entry expands to that holds a
///     `botopink.json`. A member's `name` is its import name.
///
/// `dependencies` is the object form only (decision 76):
///
///   `{ "<name>": { "path": "…" } | { "git": "…", "branch"|"tag"|"rev": "…", "subdir": "…" } | { "workspace": true } }`
///
/// Every refusal here is a `Located` error — the message, the manifest file and
/// the line/column of the offending entry — rendered in the CLI's diagnostic
/// shape, so the same text reaches a terminal, the runner's log and the editor.
/// Nothing is parsed and ignored, and no field turns a refusal off (decision 67).
///
/// Schema document: `conformance/docs.md` § The manifest schema — keep it in sync with this file.
const std = @import("std");

pub const FILENAME = "botopink.json";

// ── The OTP release ────────────────────────────────────────────────────────────

/// The one Erlang/OTP release the compiler emits for (decision 228 of
/// 1.0.11-beta): one exact release, not a range. `botopink --version` prints
/// it, every erlang and beam run of the CLI refuses an `erl` on `PATH` of
/// another release, a manifest's `"otp"` must name it, and `scripts/gate.sh`
/// and the CI workflows read it from here — it is written nowhere else. It
/// lives in this module, not in the CLI, because the manifest refusal needs it
/// and this module depends on `std` only.
pub const OTP_RELEASE = "28";

// ── Source files ───────────────────────────────────────────────────────────────

/// Every extension a botopink module is written in — the one list the CLI,
/// `botopink packages`, the language server and the formatter read (front 116
/// step 3), so no tool spells `.bp` alone and silently skips a `.bpp`. There
/// is no declaration-file kind (decision 575 (1)): a name ending in `.d.bp` is
/// a `.bp` module named `x.d`.
pub const SOURCE_EXTENSIONS = [_][]const u8{ BPP_EXT, ".botopink", ".bp" };
/// Another spelling of a module (decisions 198, 212, 361): a header, then the
/// literal of the package `"bpp"` names — unfolded by the toolchain.
pub const BPP_EXT = ".bpp";
/// `mod x;` resolves `x.bp`, then `x.bpp`, then `x/mod.bp` (front 116 step 3).
pub const MOD_SIBLING_EXTENSIONS = [_][]const u8{ ".bp", BPP_EXT };

/// A file in any of `SOURCE_EXTENSIONS`.
pub fn isSourceFile(name: []const u8) bool {
    for (SOURCE_EXTENSIONS) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return true;
    }
    return false;
}

/// A module that compiles to code: every source file.
pub fn isModuleFile(name: []const u8) bool {
    return isSourceFile(name);
}

pub fn isBppFile(name: []const u8) bool {
    return std.mem.endsWith(u8, name, BPP_EXT);
}

/// `name` without its source extension (`a/b.bp` → `a/b`, `Card.bpp` →
/// `Card`); unchanged when it has none.
pub fn stripSourceExt(name: []const u8) []const u8 {
    for (SOURCE_EXTENSIONS) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return name[0 .. name.len - ext.len];
    }
    return name;
}

test "source extensions: one list, .bpp a module, .d.bp a module named x.d" {
    try std.testing.expectEqualStrings("a/b.d", stripSourceExt("a/b.d.bp"));
    try std.testing.expectEqualStrings("Card", stripSourceExt("Card.bpp"));
    try std.testing.expectEqualStrings("main", stripSourceExt("main.bp"));
    try std.testing.expectEqualStrings("x", stripSourceExt("x.botopink"));
    try std.testing.expectEqualStrings("notes.txt", stripSourceExt("notes.txt"));
    try std.testing.expect(isModuleFile("Card.bpp"));
    try std.testing.expect(isModuleFile("main.bp"));
    try std.testing.expect(isModuleFile("types.d.bp"));
    try std.testing.expect(isSourceFile("types.d.bp"));
    try std.testing.expect(!isSourceFile("Card.bppx"));
}

// ── Located errors ─────────────────────────────────────────────────────────────

/// A manifest error with a place: the message, the manifest it is in, the raw
/// text (for the caret line) and a 1-based line/column plus span in bytes.
pub const Located = struct {
    message: []const u8,
    /// The refusal's code, when it has one (`dependency-target-missing`,
    /// decision 676): rendered `error[<code>]: <message>`.
    code: ?[]const u8 = null,
    file: []const u8,
    source: []const u8,
    line: usize,
    col: usize,
    span: usize,

    /// Render in the shape the CLI uses for every located diagnostic:
    ///
    ///   error: <message>
    ///    --> <file>:<line>:<col>
    ///     |
    ///   N | <source line>
    ///     | ^^^
    ///
    pub fn render(self: Located, w: *std.Io.Writer) !void {
        const line_w = digitWidth(self.line);
        if (self.code) |c| try w.print("error[{s}]: {s}\n", .{ c, self.message }) else try w.print("error: {s}\n", .{self.message});
        try w.splatByteAll(' ', line_w);
        try w.print("--> {s}:{d}:{d}\n", .{ self.file, self.line, self.col });
        try w.splatByteAll(' ', line_w + 1);
        try w.writeAll("|\n");
        try w.print("{d} | {s}\n", .{ self.line, lineText(self.source, self.line) });
        try w.splatByteAll(' ', line_w + 1);
        try w.writeAll("| ");
        try w.splatByteAll(' ', if (self.col > 0) self.col - 1 else 0);
        try w.splatByteAll('^', @max(self.span, 1));
        try w.writeAll("\n\n");
    }

    /// `render` into an owned string. The only way the allocating writer
    /// fails is out of memory.
    pub fn renderAlloc(self: Located, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
        var aw: std.Io.Writer.Allocating = .init(allocator);
        defer aw.deinit();
        self.render(&aw.writer) catch return error.OutOfMemory;
        return aw.toOwnedSlice();
    }

    /// `render` to stderr. Rendering is best effort — a diagnostic is never
    /// worth failing over.
    pub fn print(self: Located) void {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        const text = self.renderAlloc(fba.allocator()) catch {
            emit("error: {s}\n --> {s}:{d}:{d}\n", .{ self.message, self.file, self.line, self.col });
            return;
        };
        emit("{s}", .{text});
    }
};

/// Where `Located.print` writes: stderr, unless a caller pointed it at a
/// buffer — `botopink build --json` discards what reading the held targets
/// would print, beside the CLI's own `reporter.sink`. The CLI is one thread; nothing sets it concurrently.
pub var sink: ?*std.Io.Writer = null;

/// `botopink build --json` (decision 798 (6)): every located refusal printed is
/// also appended here, as `reporter.capture` holds the CLI's own messages, so
/// the build reads a manifest's refusal back as a `refused` event too.
pub var capture: ?*std.Io.Writer = null;

fn emit(comptime fmt: []const u8, args: anytype) void {
    if (capture) |c| c.print(fmt, args) catch {};
    if (sink) |w| {
        w.print(fmt, args) catch {};
    } else std.debug.print(fmt, args);
}

fn digitWidth(n: usize) usize {
    var w: usize = 1;
    var v = n;
    while (v >= 10) : (v /= 10) w += 1;
    return w;
}

/// The text of 1-based `line` in `source`, without its newline.
fn lineText(source: []const u8, line: usize) []const u8 {
    var it = std.mem.splitScalar(u8, source, '\n');
    var n: usize = 1;
    while (it.next()) |l| : (n += 1) {
        if (n == line) return std.mem.trimEnd(u8, l, "\r");
    }
    return "";
}

/// Byte offset → 1-based line and column.
fn lineCol(text: []const u8, offset: usize) struct { line: usize, col: usize } {
    const end = @min(offset, text.len);
    var line: usize = 1;
    var line_start: usize = 0;
    for (text[0..end], 0..) |c, i| {
        if (c == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    return .{ .line = line, .col = end - line_start + 1 };
}

const Span = struct { offset: usize, len: usize };

/// Where `"<key>"` sits in the manifest text; the first byte when absent (the
/// message carries the name either way, so an unexpected shape degrades to a
/// diagnostic on line 1 rather than to none).
fn locateKey(text: []const u8, key: []const u8) Span {
    var buf: [256]u8 = undefined;
    const quoted = std.fmt.bufPrint(&buf, "\"{s}\"", .{key}) catch return .{ .offset = 0, .len = 1 };
    if (std.mem.indexOf(u8, text, quoted)) |at| return .{ .offset = at, .len = quoted.len };
    return .{ .offset = 0, .len = @min(text.len, 1) };
}

/// Where `"<entry>"` sits after `"<key>"`: the entry itself, else the key, else
/// the first byte.
fn locateEntry(text: []const u8, key: []const u8, entry: []const u8) Span {
    var kbuf: [256]u8 = undefined;
    const qkey = std.fmt.bufPrint(&kbuf, "\"{s}\"", .{key}) catch return .{ .offset = 0, .len = 1 };
    var ebuf: [512]u8 = undefined;
    const qentry = std.fmt.bufPrint(&ebuf, "\"{s}\"", .{entry}) catch return locateKey(text, key);
    if (std.mem.indexOf(u8, text, qkey)) |k| {
        if (std.mem.indexOfPos(u8, text, k, qentry)) |at| return .{ .offset = at, .len = qentry.len };
        return .{ .offset = k, .len = qkey.len };
    }
    return .{ .offset = 0, .len = @min(text.len, 1) };
}

/// Why `name` cannot name a package, or null. The erlang and BEAM module atom
/// of every module starts with its package's name (decision 109 of
/// 1.0.10-beta: `std@math@@PI`, `myapp@main`), and an atom that does not start
/// with a lowercase letter has to be quoted — so such a name is refused here,
/// once, for every tool, rather than quoted there. `bp` is the compiler's own
/// namespace: a module compiled outside any package, and every comptime
/// evaluation, is `bp@…`.
pub fn nameRefusal(name: []const u8) ?[]const u8 {
    if (name.len == 0 or !(name[0] >= 'a' and name[0] <= 'z'))
        return "\"name\" must start with a lowercase letter — every erlang module atom of the package starts with it";
    if (std.mem.eql(u8, name, "bp"))
        return "\"name\" cannot be \"bp\" — it is the compiler's own namespace, the package of a module compiled outside any botopink.json";
    return null;
}

fn located(text: []const u8, file: []const u8, span: Span, message: []const u8) Located {
    const lc = lineCol(text, span.offset);
    return .{ .message = message, .file = file, .source = text, .line = lc.line, .col = lc.col, .span = span.len };
}

// ── The model ──────────────────────────────────────────────────────────────────

/// The pin of a `git` dependency. The three spellings are exclusive: an entry
/// with two of them is a located error, not a "strongest pin wins".
pub const DepRef = union(enum) {
    branch: []const u8,
    rev: []const u8,
    tag: []const u8,
    none,
};

/// One `dependencies` entry's source. Exactly one of `git`, `path`, `workspace`.
pub const DepSpec = struct {
    git: ?[]const u8 = null,
    path: ?[]const u8 = null,
    ref: DepRef = .none,
    /// `{ "workspace": true }` — the sibling member of the enclosing workspace
    /// with this entry's name.
    workspace: bool = false,
    /// `"subdir"` of a `git` dependency (decision 344 of 1.0.12-beta): the
    /// package lives at this directory of the repository, not at its root.
    /// A relative path of plain segments (no `.`, `..`, empty segment or
    /// backslash); `bpmp install` clones the repository once and resolves the
    /// package's `path` dependencies inside the same checkout.
    subdir: ?[]const u8 = null,

    pub fn isGit(self: DepSpec) bool {
        return self.git != null;
    }

    pub fn isPath(self: DepSpec) bool {
        return self.path != null;
    }
};

pub const DepEntry = struct {
    name: []const u8,
    spec: DepSpec,
    /// Decision 512 (2): the entry is the enclosing workspace's, inherited by
    /// this member (`inheritFrom`) — its `path`, written relative to the
    /// workspace's manifest, is rewritten relative to the member, and a
    /// refusal about it is located in the workspace's manifest
    /// (`Manifest.locateEntryAt`).
    inherited: bool = false,
};

/// Decision 512: the workspace manifest a member inherited from — where an
/// inherited dependency is written, so a refusal about it is located there.
pub const Origin = struct {
    path: []const u8,
    text: []const u8,
};

pub const Kind = enum { package, workspace };

/// Decision 334 of 1.0.12-beta: the runtime a wasm build binds to, named by
/// `"wasm": { "host": … }`. `wasi` — wasmtime and the runtimes that follow
/// WASI preview 2 — is the default; `browser` binds JS imports (`fetch`,
/// timers, `Promise` through JSPI).
pub const WasmHost = enum {
    wasi,
    browser,

    pub fn fromString(s: []const u8) ?WasmHost {
        inline for (@typeInfo(WasmHost).@"enum".fields) |f| {
            if (std.mem.eql(u8, s, f.name)) return @enumFromInt(f.value);
        }
        return null;
    }
};

/// A manifest's `"otp": "<release>"` and the manifest that wrote it, so a
/// refusal points at the value even when a member inherited it.
pub const OtpPin = struct {
    release: []const u8,
    path: []const u8,
    text: []const u8,

    /// A diagnostic located at this pin's value.
    pub fn locate(self: OtpPin, message: []const u8) Located {
        return located(self.text, self.path, locateEntry(self.text, "otp", self.release), message);
    }
};

/// Why `pin` cannot be a build's OTP release, or null: the compiler emits for
/// one release, `OTP_RELEASE`, and a manifest may pin that one only.
pub fn otpRefusal(arena: std.mem.Allocator, pin: OtpPin) std.mem.Allocator.Error!?Located {
    if (std.mem.eql(u8, pin.release, OTP_RELEASE)) return null;
    return pin.locate(try std.fmt.allocPrint(arena, "botopink emits Erlang for OTP " ++ OTP_RELEASE ++ "; \"otp\" names {s}", .{pin.release}));
}

/// The `"otp"` of `pin` against the one already in force, `first`: null when
/// they agree, else a refusal located at `pin`'s value naming `first`'s file.
fn otpDisagreement(arena: std.mem.Allocator, first: OtpPin, pin: OtpPin) std.mem.Allocator.Error!?Located {
    if (std.mem.eql(u8, first.release, pin.release)) return null;
    return pin.locate(try std.fmt.allocPrint(
        arena,
        "\"otp\" names {s} here, but {s} in {s} — every package of a build pins one OTP release",
        .{ pin.release, first.release, first.path },
    ));
}

/// The OTP pin of a build's closure (decision 228): `manifests` is every
/// package the build compiles, the project first. Every one that declares
/// `"otp"` must declare the release the first one did — a mismatch is refused
/// at the later value, naming the earlier file — and that release must be
/// `OTP_RELEASE` (`otpRefusal`). Null when none declares it: the compiler's
/// release applies.
pub fn closureOtp(arena: std.mem.Allocator, manifests: []const Manifest, out_err: *?Located) Error!?OtpPin {
    var first: ?OtpPin = null;
    for (manifests) |m| {
        const pin = m.otp orelse continue;
        if (first) |f| {
            if (try otpDisagreement(arena, f, pin)) |refusal| {
                out_err.* = refusal;
                return error.Invalid;
            }
        } else first = pin;
    }
    if (first) |f| {
        if (try otpRefusal(arena, f)) |refusal| {
            out_err.* = refusal;
            return error.Invalid;
        }
    }
    return first;
}

/// A parsed `botopink.json`. Strings point into the arena the manifest was
/// parsed with; `text` is the raw file so an error can be located in it.
pub const Manifest = struct {
    /// The path the manifest was read from (as given by the caller — relative
    /// stays relative), used in every located message.
    path: []const u8,
    text: []const u8,
    kind: Kind,
    name: []const u8,
    version: []const u8 = "0.1.0",
    /// Whether the manifest writes `"version"` — a member that does not takes
    /// its workspace's (decision 512 (4)).
    version_declared: bool = false,
    /// The workspace manifest this member inherited from (`inheritFrom`),
    /// null for a package outside any workspace or a workspace itself.
    inherited_from: ?Origin = null,
    description: ?[]const u8 = null,
    /// Source directory, relative to the manifest's directory (default `src/`).
    src: []const u8 = "src/",
    /// Module-tree root under `src` (`main.bp` for a binary, `root.bp` for a
    /// library). `null` lets the resolver detect it.
    entry: ?[]const u8 = null,
    /// The default build target, when declared.
    target: ?[]const u8 = null,
    /// The target whitelist the runner honours; a member inherits its
    /// workspace's when it declares none (set by `expand`).
    targets: ?[]const []const u8 = null,
    /// True when `targets` is the workspace's, inherited because this member
    /// writes none (decision 770: such a package declares no targets).
    targets_inherited: bool = false,
    /// The modules a consumer may import, each relative to `src`.
    files: []const []const u8 = &.{},
    dependencies: []const DepEntry = &.{},
    /// A workspace's member globs, verbatim (`modules/*`, `examples/acme-app`).
    workspaces: []const []const u8 = &.{},
    /// The `"otp"` pin (decision 228), when declared; a member without one
    /// inherits its workspace's (set by `expand`), which keeps pointing at the
    /// workspace's manifest.
    otp: ?OtpPin = null,
    /// `"wasm": { "host": … }` (decision 334): the runtime a wasm build binds
    /// to; absent means `wasi`. Read on the project being built only.
    wasm_host: WasmHost = .wasi,
    /// `"bpp": "<package>"` (decision 361): the dependency whose declarations
    /// std's `bpp` annotations mark — the four roles a `.bpp` file unfolds
    /// onto. Null when the manifest has no key. Read on the project being
    /// built only (`compiler-cli` `bpp.zig`).
    bpp: ?[]const u8 = null,
    /// `"typings": true` (decisions 619, 620): a commonJS build of this
    /// package writes a `.d.ts` beside each `.js`, as `botopink build
    /// --typescript` does; either turns the emission on. Read on the project
    /// being built only.
    typings: bool = false,

    pub fn isWorkspace(self: Manifest) bool {
        return self.kind == .workspace;
    }

    /// The directory holding the manifest.
    pub fn dir(self: Manifest) []const u8 {
        return std.fs.path.dirname(self.path) orelse ".";
    }

    /// A diagnostic about this manifest's `"<key>"`, located at that key (the
    /// first byte of the file when the manifest does not spell it out). Lets a
    /// caller outside this module report a problem it found *through* a
    /// manifest — a dependency's sidecar that cannot be shipped, say — in the
    /// same shape as the ones raised here.
    pub fn locateAt(self: Manifest, key: []const u8, message: []const u8) Located {
        return located(self.text, self.path, locateKey(self.text, key), message);
    }

    /// The same, located at the `"<entry>"` of this manifest's `"<key>"` object
    /// (`locateEntryAt("dependencies", "rakun", …)` points at the dependency
    /// entry), falling back to the key and then to the first byte.
    ///
    /// A dependency the member inherited from its workspace (decision 512) is
    /// written in the workspace's manifest: `locateEntryAt("dependencies", …)`
    /// on it points at the workspace's entry.
    pub fn locateEntryAt(self: Manifest, key: []const u8, entry: []const u8, message: []const u8) Located {
        if (self.inheritedDependency(key, entry)) |origin|
            return located(origin.text, origin.path, locateEntry(origin.text, key, entry), message);
        return located(self.text, self.path, locateEntry(self.text, key, entry), message);
    }

    /// The workspace manifest that writes dependency `entry`, when `key` is
    /// `"dependencies"` and the entry is one this member inherited.
    fn inheritedDependency(self: Manifest, key: []const u8, entry: []const u8) ?Origin {
        if (!std.mem.eql(u8, key, "dependencies")) return null;
        const origin = self.inherited_from orelse return null;
        for (self.dependencies) |d| {
            if (d.inherited and std.mem.eql(u8, d.name, entry)) return origin;
        }
        return null;
    }

    /// True when this manifest writes its own `"targets"` (decision 770): only
    /// such a package is refused for a target a dependency lacks (676).
    pub fn declaresTargets(self: Manifest) bool {
        return self.targets != null and !self.targets_inherited;
    }

    /// True when the whitelist is absent or contains `target`.
    pub fn supportsTarget(self: Manifest, target: []const u8) bool {
        const list = self.targets orelse return true;
        for (list) |t| if (std.mem.eql(u8, t, target)) return true;
        return false;
    }
};

pub const Error = error{
    /// The manifest was refused; `out_err` carries the located message.
    Invalid,
} || std.mem.Allocator.Error;

pub const ReadError = Error || error{NotFound};

/// Parse `text` as the manifest at `path`. On `error.Invalid` the located
/// refusal is in `out_err`; everything else is `OutOfMemory`. A package named
/// `std` is refused (decision 453): only `libs/std`, the bundled standard
/// library, bears the name — `read` and `parseBundledStd` are the readers that
/// know it is that one.
pub fn parse(arena: std.mem.Allocator, text: []const u8, path: []const u8, out_err: *?Located) Error!Manifest {
    return parseWith(arena, text, path, out_err, .{});
}

/// How `parseWith` reads a manifest.
pub const ParseOptions = struct {
    /// The manifest is the bundled `libs/std`'s (decision 453).
    bundled_std: bool = false,
    /// Leave `"bpp"`'s "names a dependency" check to `checkBpp`: a workspace
    /// member's `"bpp"` may name a dependency it inherits (decision 512), which
    /// is known only once `inheritFrom` ran.
    defer_bpp: bool = false,
};

/// `parse` with options — the reader of a manifest that may be a workspace
/// member (`config.load` in the CLI, `expand`).
pub fn parseWith(arena: std.mem.Allocator, text: []const u8, path: []const u8, out_err: *?Located, opts: ParseOptions) Error!Manifest {
    return parseAs(arena, text, path, out_err, opts);
}

/// `parse` of the manifest of the bundled `libs/std` itself (`isBundledStd`
/// said so): the one manifest that may be named `std` (decision 453).
pub fn parseBundledStd(arena: std.mem.Allocator, text: []const u8, path: []const u8, out_err: *?Located) Error!Manifest {
    return parseAs(arena, text, path, out_err, .{ .bundled_std = true });
}

/// Decision 453 — the name of the bundled standard library, reserved.
pub const STD_NAME = "std";

/// Why a manifest named `std` is refused unless it is the bundled `libs/std`.
pub const std_name_refusal = "the package name `std` is the bundled standard library's — choose another name";

/// True when `dir` is the bundled standard library: `<checkout>/libs/std`,
/// `<checkout>` being the compiler's own checkout (the directory that holds
/// `modules/compiler-core`). Judged by the directory's real path, never by the
/// `name` a manifest writes (decision 453).
pub fn isBundledStd(io: std.Io, dir: []const u8) bool {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = std.Io.Dir.cwd().realPathFile(io, dir, &buf) catch return false;
    const real = buf[0..n];
    if (!std.mem.eql(u8, std.fs.path.basename(real), STD_NAME)) return false;
    const libs = std.fs.path.dirname(real) orelse return false;
    if (!std.mem.eql(u8, std.fs.path.basename(libs), "libs")) return false;
    const checkout = std.fs.path.dirname(libs) orelse return false;
    var pbuf: [std.fs.max_path_bytes]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&pbuf);
    const core = std.fs.path.join(fba.allocator(), &.{ checkout, "modules", "compiler-core", "src", "root.zig" }) catch return false;
    std.Io.Dir.cwd().access(io, core, .{}) catch return false;
    return true;
}

fn parseAs(arena: std.mem.Allocator, text: []const u8, path: []const u8, out_err: *?Located, opts: ParseOptions) Error!Manifest {
    const bundled_std = opts.bundled_std;
    var parsed = std.json.parseFromSlice(std.json.Value, arena, text, .{}) catch {
        out_err.* = located(text, path, .{ .offset = 0, .len = 1 }, "botopink.json is not valid JSON");
        return error.Invalid;
    };
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) {
        out_err.* = located(text, path, .{ .offset = 0, .len = 1 }, "botopink.json must be a JSON object");
        return error.Invalid;
    }
    const obj = root.object;

    var m: Manifest = .{ .path = path, .text = text, .kind = .package, .name = "" };

    m.name = try requireString(arena, obj, "name", text, path, out_err);
    if (nameRefusal(m.name)) |why| {
        out_err.* = located(text, path, locateKey(text, "name"), why);
        return error.Invalid;
    }
    if (!bundled_std and std.mem.eql(u8, m.name, STD_NAME)) {
        out_err.* = located(text, path, locateKey(text, "name"), std_name_refusal);
        return error.Invalid;
    }
    if (try optionalString(arena, obj, "version", text, path, out_err)) |v| {
        m.version = v;
        m.version_declared = true;
    }
    m.description = try optionalString(arena, obj, "description", text, path, out_err);
    if (try optionalString(arena, obj, "src", text, path, out_err)) |v| m.src = v;
    m.entry = try optionalString(arena, obj, "entry", text, path, out_err);
    m.target = try optionalString(arena, obj, "target", text, path, out_err);
    m.targets = try optionalStringArray(arena, obj, "targets", text, path, out_err);
    if (try optionalStringArray(arena, obj, "files", text, path, out_err)) |f| {
        try checkFilesOneModuleEach(arena, f, text, path, out_err);
        m.files = f;
    }
    if (try optionalString(arena, obj, "otp", text, path, out_err)) |r| m.otp = .{ .release = r, .path = path, .text = text };

    if (obj.get("workspaces") != null) {
        m.kind = .workspace;
        const globs = (try optionalStringArray(arena, obj, "workspaces", text, path, out_err)) orelse unreachable;
        m.workspaces = globs;
        // A workspace is not a package: nothing compiles from it and nothing
        // imports it, so the package fields have no meaning here.
        for ([_][]const u8{ "src", "files", "entry", "wasm", "bpp", "typings" }) |field| {
            if (obj.get(field) != null) {
                out_err.* = located(text, path, locateKey(text, field), try std.fmt.allocPrint(
                    arena,
                    "a workspace manifest cannot carry \"{s}\" — a workspace declares members, it is not a package; move \"{s}\" to the member's own botopink.json",
                    .{ field, field },
                ));
                return error.Invalid;
            }
        }
        for (globs) |g| try checkGlobForm(arena, g, text, path, out_err);
        // Decision 512 (2): the dependencies every member inherits. A
        // `{ "workspace": true }` names a sibling of the member that writes it;
        // the workspace has none, so it is refused here.
        if (obj.get("dependencies")) |deps_val| {
            m.dependencies = try parseDependencies(arena, deps_val, text, path, out_err);
            for (m.dependencies) |d| {
                if (!d.spec.workspace) continue;
                out_err.* = located(text, path, locateEntry(text, "dependencies", d.name), try std.fmt.allocPrint(
                    arena,
                    "\"{s}\": {{ \"workspace\": true }} names a sibling member, and a workspace's dependencies are every member's — declare it in the members that use it",
                    .{d.name},
                ));
                return error.Invalid;
            }
        }
        return m;
    }

    if (obj.get("wasm")) |v| m.wasm_host = try parseWasm(arena, v, text, path, out_err);
    m.typings = try optionalBool(arena, obj, "typings", text, path, out_err);
    if (obj.get("dependencies")) |deps_val| {
        m.dependencies = try parseDependencies(arena, deps_val, text, path, out_err);
    }
    if (obj.get("bpp")) |v| {
        m.bpp = try parseBppShape(arena, v, text, path, out_err);
        if (!opts.defer_bpp) try checkBpp(arena, m, out_err);
    }
    return m;
}

/// Each entry of `"files"` is one module, `<package>/<stem>`: two entries of
/// one stem (`p.bp` and `p.bpp`, or one file listed twice) are one module
/// written twice, refused at the second — the rule `x.bp` beside `x.bpp`
/// (`bpp.refuseTwins`) and beside `x/mod.bp` (`AmbiguousModule`) already
/// follow. Loaded, the two were two modules of one path, and every consumer
/// of the package read the module's `pub` names twice (144 B-98).
fn checkFilesOneModuleEach(arena: std.mem.Allocator, files: []const []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!void {
    for (files, 0..) |file, i| {
        for (files[0..i]) |earlier| {
            if (!std.mem.eql(u8, stripSourceExt(earlier), stripSourceExt(file))) continue;
            out_err.* = located(text, path, locateLaterEntry(text, earlier, file), try std.fmt.allocPrint(
                arena,
                "\"files\" lists {s} and {s}, one module (`{s}`) written twice — keep one of the two files",
                .{ earlier, file, stripSourceExt(file) },
            ));
            return error.Invalid;
        }
    }
}

/// Where `"<later>"` sits in `"files"`, after `"<earlier>"` — so a file listed
/// twice is located at its second entry.
fn locateLaterEntry(text: []const u8, earlier: []const u8, later: []const u8) Span {
    const first = locateEntry(text, "files", earlier);
    var ebuf: [512]u8 = undefined;
    const qlater = std.fmt.bufPrint(&ebuf, "\"{s}\"", .{later}) catch return first;
    const from = first.offset + first.len;
    if (std.mem.indexOfPos(u8, text, from, qlater)) |at| return .{ .offset = at, .len = qlater.len };
    return first;
}

/// `"bpp"` (decision 361, amending 284 and 338 (6)): one package name, a
/// dependency of this manifest — the package whose declarations std's `bpp`
/// annotations mark. The object form `{"default", "style"}` is gone, refused
/// at the key naming the string form; any other non-string too; a name that
/// is not an entry of `"dependencies"` is refused at the value.
fn parseBppShape(arena: std.mem.Allocator, v: std.json.Value, text: []const u8, path: []const u8, out_err: *?Located) Error![]const u8 {
    if (v != .string) {
        out_err.* = located(text, path, locateKey(text, "bpp"), "\"bpp\" is a package name — write \"bpp\": \"jhonstart\"");
        return error.Invalid;
    }
    return try arena.dupe(u8, v.string);
}

/// `"bpp"` names one of the manifest's dependencies — its own or, for a
/// workspace member, one it inherits (decision 512) — else it is refused at
/// the value. `parse` calls it; a reader that parsed with `defer_bpp` calls it
/// once `inheritFrom` ran (`expand`, the CLI's `config.load`).
pub fn checkBpp(arena: std.mem.Allocator, m: Manifest, out_err: *?Located) Error!void {
    const name = m.bpp orelse return;
    for (m.dependencies) |d| {
        if (std.mem.eql(u8, d.name, name)) return;
    }
    out_err.* = located(m.text, m.path, locateEntry(m.text, "bpp", name), try std.fmt.allocPrint(arena, "\"bpp\" names \"{s}\", which is not a dependency — the package that unfolds .bpp files is an entry of \"dependencies\"", .{name}));
    return error.Invalid;
}

/// Read `<dir>/botopink.json` and `parse` it; the manifest's `path` is the
/// joined path. `error.NotFound` when the file cannot be read.
///
/// A package that is a member of a workspace comes back with what it inherits
/// from it (decision 512, `inheritInPlace`): every reader — the CLI, the
/// language server, the runner, `bpmp` — sees one member the same way.
pub fn read(arena: std.mem.Allocator, io: std.Io, dir: []const u8, out_err: *?Located) ReadError!Manifest {
    var m = try readWith(arena, io, dir, out_err, true);
    if (!m.isWorkspace()) try inheritInPlace(arena, io, &m, dir, out_err);
    return m;
}

/// Decision 512 for a package read on its own (not through `expand`): when the
/// nearest ancestor workspace lists `dir` (`workspaceOf`), `inheritFrom` it;
/// else check its `"bpp"` against its own dependencies. A manifest parsed with
/// `defer_bpp` goes through here (or through `expand`) before it is used.
pub fn inheritInPlace(arena: std.mem.Allocator, io: std.Io, m: *Manifest, dir: []const u8, out_err: *?Located) Error!void {
    const abs = try absolute(arena, io, dir);
    if (try workspaceOf(arena, io, abs, out_err)) |wsm| {
        // Both directories absolute (`workspaceOf` reads the workspace at an
        // absolute path): the member's depth below it is what they say.
        try inheritFrom(arena, wsm, m, abs, out_err);
    } else try checkBpp(arena, m.*, out_err);
}

/// `dir` as an absolute, normalised path (against the process's directory).
fn absolute(arena: std.mem.Allocator, io: std.Io, dir: []const u8) Error![]const u8 {
    if (std.fs.path.isAbsolute(dir)) return std.fs.path.resolve(arena, &.{dir});
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = std.process.currentPath(io, &buf) catch return std.fs.path.resolve(arena, &.{dir});
    return std.fs.path.resolve(arena, &.{ buf[0..n], dir });
}

fn readWith(arena: std.mem.Allocator, io: std.Io, dir: []const u8, out_err: *?Located, defer_bpp: bool) ReadError!Manifest {
    const path = try std.fs.path.join(arena, &.{ dir, FILENAME });
    const text = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .limited(1024 * 1024)) catch return error.NotFound;
    return parseAs(arena, text, path, out_err, .{ .bundled_std = isBundledStd(io, dir), .defer_bpp = defer_bpp });
}

/// True when `<dir>` is the root of the checkout the walk-up started in: it
/// holds a `repository/` directory — the meta workspace (or a worktree of it
/// under `.tasks/<name>`), or CI's `botopink-lang` checkout with the libraries
/// cloned into `repository/<lib>`. The three root walk-ups (`compiler-cli`
/// `libs.zig`, `language-server`
/// `project_graph.zig`) add this directory's roots and stop there: an ancestor
/// of it belongs to another checkout. A worktree nested in the meta checkout
/// used to see the main checkout's `repository/*` as well, and every library
/// was "declared by two libraries" (decision 143).
pub fn isCheckoutRoot(io: std.Io, dir: []const u8) bool {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const path = std.fs.path.join(fba.allocator(), &.{ dir, "repository" }) catch return false;
    var d = std.Io.Dir.cwd().openDir(io, path, .{}) catch return false;
    d.close(io);
    return true;
}

/// True when `<dir>/botopink.json` exists and declares `workspaces` — the
/// probe the three root walk-ups use to add an ancestor workspace as a root.
/// A manifest that does not parse answers false; the walk-up is not the place
/// to report it (the command that reads it does).
pub fn isWorkspaceDir(io: std.Io, dir: []const u8) bool {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const path = std.fs.path.join(fba.allocator(), &.{ dir, FILENAME }) catch return false;
    var text_buf: [64 * 1024]u8 = undefined;
    var fba2 = std.heap.FixedBufferAllocator.init(&text_buf);
    const text = std.Io.Dir.cwd().readFileAlloc(io, path, fba2.allocator(), .limited(64 * 1024)) catch return false;
    // Cheap probe before parsing: the key must at least appear.
    if (std.mem.indexOf(u8, text, "\"workspaces\"") == null) return false;
    var arena_inst = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_inst.deinit();
    var parsed = std.json.parseFromSlice(std.json.Value, arena_inst.allocator(), text, .{}) catch return false;
    defer parsed.deinit();
    if (parsed.value != .object) return false;
    const v = parsed.value.object.get("workspaces") orelse return false;
    return v == .array;
}

fn requireString(arena: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error![]const u8 {
    const v = obj.get(key) orelse {
        out_err.* = located(text, path, .{ .offset = 0, .len = 1 }, try std.fmt.allocPrint(arena, "botopink.json has no \"{s}\"", .{key}));
        return error.Invalid;
    };
    if (v != .string) {
        out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be a string", .{key}));
        return error.Invalid;
    }
    return try arena.dupe(u8, v.string);
}

fn optionalString(arena: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!?[]const u8 {
    const v = obj.get(key) orelse return null;
    switch (v) {
        .null => return null,
        .string => |s| return try arena.dupe(u8, s),
        else => {
            out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be a string", .{key}));
            return error.Invalid;
        },
    }
}

/// `"<key>": true | false`, false when absent (`"typings"`).
fn optionalBool(arena: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!bool {
    const v = obj.get(key) orelse return false;
    if (v != .bool) {
        out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be true or false", .{key}));
        return error.Invalid;
    }
    return v.bool;
}

fn optionalStringArray(arena: std.mem.Allocator, obj: std.json.ObjectMap, key: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!?[]const []const u8 {
    const v = obj.get(key) orelse return null;
    if (v == .null) return null;
    if (v != .array) {
        out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be an array of strings", .{key}));
        return error.Invalid;
    }
    var out = try arena.alloc([]const u8, v.array.items.len);
    for (v.array.items, 0..) |item, i| {
        if (item != .string) {
            out_err.* = located(text, path, locateKey(text, key), try std.fmt.allocPrint(arena, "\"{s}\" must be an array of strings — entry {d} is not a string", .{ key, i + 1 }));
            return error.Invalid;
        }
        out[i] = try arena.dupe(u8, item.string);
    }
    return out;
}

const WASM_SHAPE = "{ \"host\": \"wasi\" | \"browser\" }";

/// `"wasm"` (decision 334): an object whose one field, `"host"`, names
/// `wasi` or `browser`. Nothing else is read, so nothing else is accepted: an
/// object without `"host"` (absent `"wasm"` is the one way to mean the
/// default), another field, a host that is not a string or not one of the two
/// — each a refusal located where it is written.
fn parseWasm(arena: std.mem.Allocator, v: std.json.Value, text: []const u8, path: []const u8, out_err: *?Located) Error!WasmHost {
    if (v != .object) {
        out_err.* = located(text, path, locateKey(text, "wasm"), "\"wasm\" must be an object — " ++ WASM_SHAPE);
        return error.Invalid;
    }
    var it = v.object.iterator();
    while (it.next()) |e| {
        if (std.mem.eql(u8, e.key_ptr.*, "host")) continue;
        out_err.* = located(text, path, locateEntry(text, "wasm", e.key_ptr.*), try std.fmt.allocPrint(arena, "\"wasm\" has no field \"{s}\" — its one field is \"host\": {s}", .{ e.key_ptr.*, WASM_SHAPE }));
        return error.Invalid;
    }
    const host = v.object.get("host") orelse {
        out_err.* = located(text, path, locateKey(text, "wasm"), "\"wasm\" names no \"host\" — write " ++ WASM_SHAPE ++ ", or omit \"wasm\" for the default \"wasi\"");
        return error.Invalid;
    };
    if (host != .string) {
        out_err.* = located(text, path, locateEntry(text, "wasm", "host"), "\"wasm\": \"host\" must be a string — \"wasi\" or \"browser\"");
        return error.Invalid;
    }
    return WasmHost.fromString(host.string) orelse {
        out_err.* = located(text, path, locateEntry(text, "wasm", host.string), try std.fmt.allocPrint(arena, "\"wasm\": \"host\" names \"{s}\" — a wasm build runs on \"wasi\" (wasmtime, WASI preview 2) or \"browser\" (JS imports, JSPI)", .{host.string}));
        return error.Invalid;
    };
}

/// The glob forms: `<dir>/*` (every child of `<dir>` that holds a manifest)
/// and a literal `<dir>` (decision 75), and `*` — every child of the
/// workspace's own directory, the form of a `conformance/modules/` workspace
/// whose members are its cells (decision 512 (5)); and the two-level forms
/// `*/cases/*` and `<dir>/*/cases/*` — the cases of every module (decision 765).
fn checkGlobForm(arena: std.mem.Allocator, g: []const u8, text: []const u8, path: []const u8, out_err: *?Located) Error!void {
    const bad = g.len == 0 or
        std.fs.path.isAbsolute(g) or
        std.mem.startsWith(u8, g, "..") or
        (std.mem.indexOfScalar(u8, g, '*') != null and !std.mem.eql(u8, g, "*") and !(std.mem.endsWith(u8, g, "/*") and std.mem.count(u8, g, "*") == 1) and casesOuter(g) == null);
    if (bad) {
        out_err.* = located(text, path, locateEntry(text, "workspaces", g), try std.fmt.allocPrint(
            arena,
            "workspaces entry \"{s}\" is not a supported form — use \"<dir>/*\" (every child of <dir> holding a botopink.json), \"*\" (every child of the workspace's directory), \"*/cases/*\" or \"<dir>/*/cases/*\" (the cases of every module) or a literal \"<dir>\" inside the workspace",
            .{g},
        ));
        return error.Invalid;
    }
}

const DEP_SHAPE = "{ \"<name>\": { \"path\": \"…\" } | { \"git\": \"…\", \"branch\"|\"tag\"|\"rev\": \"…\" } | { \"workspace\": true } }";

fn parseDependencies(arena: std.mem.Allocator, node: std.json.Value, text: []const u8, path: []const u8, out_err: *?Located) Error![]const DepEntry {
    switch (node) {
        .object => {},
        .array => |arr| {
            // The string array is the shape decision 76 retired. Name the fix
            // with the first entry so the message is a rewrite, not a rule.
            const first: []const u8 = if (arr.items.len > 0 and arr.items[0] == .string) arr.items[0].string else "<name>";
            out_err.* = located(text, path, locateKey(text, "dependencies"), try std.fmt.allocPrint(
                arena,
                "\"dependencies\" must be an object, not an array — write {s}; for example [\"{s}\"] becomes {{ \"{s}\": {{ \"path\": \"../{s}\" }} }}",
                .{ DEP_SHAPE, first, first, first },
            ));
            return error.Invalid;
        },
        else => {
            out_err.* = located(text, path, locateKey(text, "dependencies"), try std.fmt.allocPrint(arena, "\"dependencies\" must be an object — {s}", .{DEP_SHAPE}));
            return error.Invalid;
        },
    }
    const obj = node.object;
    var out = try arena.alloc(DepEntry, obj.count());
    var i: usize = 0;
    var it = obj.iterator();
    while (it.next()) |kv| {
        const name = kv.key_ptr.*;
        const spec_node = kv.value_ptr.*;
        const at = locateEntry(text, "dependencies", name);
        if (spec_node != .object) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" must be an object — {s}", .{ name, DEP_SHAPE }));
            return error.Invalid;
        }
        const s = spec_node.object;
        var spec: DepSpec = .{};
        var pins: usize = 0;

        if (s.get("git")) |v| {
            if (v != .string) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"git\" must be a string", .{name}));
                return error.Invalid;
            }
            spec.git = try arena.dupe(u8, v.string);
        }
        if (s.get("path")) |v| {
            if (v != .string) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"path\" must be a string", .{name}));
                return error.Invalid;
            }
            spec.path = try arena.dupe(u8, v.string);
        }
        if (s.get("workspace")) |v| {
            if (v != .bool or !v.bool) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"workspace\" can only be true — {{ \"workspace\": true }} names the sibling member of the enclosing workspace", .{name}));
                return error.Invalid;
            }
            spec.workspace = true;
        }
        if (s.get("subdir")) |v| {
            if (v != .string) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"subdir\" must be a string", .{name}));
                return error.Invalid;
            }
            spec.subdir = try arena.dupe(u8, v.string);
        }
        inline for (.{ "branch", "tag", "rev" }) |pin| {
            if (s.get(pin)) |v| {
                if (v != .string) {
                    out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\": \"{s}\" must be a string", .{ name, pin }));
                    return error.Invalid;
                }
                pins += 1;
                const dup = try arena.dupe(u8, v.string);
                spec.ref = if (comptime std.mem.eql(u8, pin, "branch")) .{ .branch = dup } else if (comptime std.mem.eql(u8, pin, "tag")) .{ .tag = dup } else .{ .rev = dup };
            }
        }

        const sources = @as(usize, @intFromBool(spec.git != null)) + @intFromBool(spec.path != null) + @intFromBool(spec.workspace);
        if (sources == 0) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" declares no source — one of \"git\", \"path\" or \"workspace\": true is required", .{name}));
            return error.Invalid;
        }
        if (sources > 1) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" declares more than one source — exactly one of \"git\", \"path\" or \"workspace\": true", .{name}));
            return error.Invalid;
        }
        if (pins > 1) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" declares more than one pin — exactly one of \"branch\", \"tag\" or \"rev\"", .{name}));
            return error.Invalid;
        }
        if (pins == 1 and spec.git == null) {
            out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" pins a ref without a \"git\" source — a pin applies to a git dependency only", .{name}));
            return error.Invalid;
        }
        if (spec.subdir) |sub| {
            if (spec.git == null) {
                out_err.* = located(text, path, at, try std.fmt.allocPrint(arena, "dependency \"{s}\" names a \"subdir\" without a \"git\" source — a subdir names a package inside a git repository", .{name}));
                return error.Invalid;
            }
            if (try subdirRefusal(arena, name, sub)) |msg| {
                out_err.* = located(text, path, at, msg);
                return error.Invalid;
            }
        }
        out[i] = .{ .name = try arena.dupe(u8, name), .spec = spec };
        // One repository is one checkout (decision 344): two dependencies on
        // one repository must name one ref, else the second's siblings would
        // come at another commit than the first's.
        for (out[0..i]) |prev| {
            const pg = prev.spec.git orelse continue;
            if (!sameRepository(pg, spec.git orelse continue)) continue;
            if (sameRef(prev.spec.ref, spec.ref)) continue;
            out_err.* = located(text, path, at, try std.fmt.allocPrint(
                arena,
                "dependencies \"{s}\" and \"{s}\" name one repository ({s}) at two refs ({s} and {s}) — one repository is one checkout; pin both at one ref",
                .{ prev.name, name, spec.git.?, try refLabel(arena, prev.spec.ref), try refLabel(arena, spec.ref) },
            ));
            return error.Invalid;
        }
        i += 1;
    }
    return out[0..i];
}

/// Why `sub`, the `"subdir"` of dependency `name`, cannot name a directory of
/// the repository, or null. It is a relative path of plain segments: an
/// absolute path, `..` (leaving the checkout), `.`, an empty segment and a
/// backslash are refused — each would be a second spelling of a directory the
/// plain form names, or a directory outside the repository.
pub fn subdirRefusal(arena: std.mem.Allocator, name: []const u8, sub: []const u8) std.mem.Allocator.Error!?[]const u8 {
    if (sub.len == 0)
        return try std.fmt.allocPrint(arena, "dependency \"{s}\": \"subdir\" is empty — omit \"subdir\" for the package at the repository's root", .{name});
    if (sub[0] == '/' or sub[0] == '\\' or (sub.len >= 2 and sub[1] == ':'))
        return try std.fmt.allocPrint(arena, "dependency \"{s}\": \"subdir\" \"{s}\" is absolute — it names a directory of the repository, relative to its root", .{ name, sub });
    if (std.mem.indexOfScalar(u8, sub, '\\') != null)
        return try std.fmt.allocPrint(arena, "dependency \"{s}\": \"subdir\" \"{s}\" holds a backslash — segments are separated by \"/\"", .{ name, sub });
    var it = std.mem.splitScalar(u8, sub, '/');
    while (it.next()) |seg| {
        if (std.mem.eql(u8, seg, ".."))
            return try std.fmt.allocPrint(arena, "dependency \"{s}\": \"subdir\" \"{s}\" leaves the repository — \"..\" is not a segment of a subdir", .{ name, sub });
        if (seg.len == 0 or std.mem.eql(u8, seg, "."))
            return try std.fmt.allocPrint(arena, "dependency \"{s}\": \"subdir\" \"{s}\" has an empty or \".\" segment — write the directory as plain segments separated by \"/\"", .{ name, sub });
    }
    return null;
}

/// Two `git` URLs name one repository when they are equal once a trailing `/`
/// and a trailing `.git` are dropped.
pub fn sameRepository(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, repositoryUrl(a), repositoryUrl(b));
}

/// A `git` URL without a trailing `/` or `.git` — the spelling two dependencies
/// on one repository share.
pub fn repositoryUrl(url: []const u8) []const u8 {
    var u = std.mem.trimEnd(u8, url, "/");
    if (std.mem.endsWith(u8, u, ".git")) u = u[0 .. u.len - ".git".len];
    return std.mem.trimEnd(u8, u, "/");
}

fn sameRef(a: DepRef, b: DepRef) bool {
    return switch (a) {
        .none => b == .none,
        .branch => |x| b == .branch and std.mem.eql(u8, x, b.branch),
        .tag => |x| b == .tag and std.mem.eql(u8, x, b.tag),
        .rev => |x| b == .rev and std.mem.eql(u8, x, b.rev),
    };
}

fn refLabel(arena: std.mem.Allocator, r: DepRef) std.mem.Allocator.Error![]const u8 {
    return switch (r) {
        .none => "the default branch",
        .branch => |x| std.fmt.allocPrint(arena, "branch \"{s}\"", .{x}),
        .tag => |x| std.fmt.allocPrint(arena, "tag \"{s}\"", .{x}),
        .rev => |x| std.fmt.allocPrint(arena, "rev \"{s}\"", .{x}),
    };
}

// ── Workspaces ─────────────────────────────────────────────────────────────────

pub const Member = struct {
    /// The member's import name — its manifest's `name`.
    name: []const u8,
    /// The member's directory (`<workspace>/<expansion>`).
    dir: []const u8,
    manifest: Manifest,
};

pub const Workspace = struct {
    dir: []const u8,
    manifest: Manifest,
    members: []const Member,

    pub fn member(self: Workspace, name: []const u8) ?Member {
        for (self.members) |m| if (std.mem.eql(u8, m.name, name)) return m;
        return null;
    }

    /// The member whose directory is `dir` (both compared as given — callers
    /// pass paths built from the same base).
    pub fn memberAt(self: Workspace, dir: []const u8) ?Member {
        for (self.members) |m| if (samePath(m.dir, dir)) return m;
        return null;
    }

    /// `a, b, c` — for messages that list the members.
    pub fn memberList(self: Workspace, arena: std.mem.Allocator) ![]const u8 {
        var buf: std.ArrayListUnmanaged(u8) = .empty;
        for (self.members, 0..) |m, i| {
            if (i > 0) try buf.appendSlice(arena, ", ");
            try buf.appendSlice(arena, m.name);
        }
        if (self.members.len == 0) try buf.appendSlice(arena, "none");
        return buf.toOwnedSlice(arena);
    }
};

/// Two paths name the same directory when they are byte-equal after trailing
/// separators are dropped. Callers build both from one base (the workspace
/// directory, or the process cwd), so no realpath is needed.
fn samePath(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, std.mem.trimEnd(u8, a, "/"), std.mem.trimEnd(u8, b, "/"));
}

/// Expand a workspace manifest into its members and check the rules of
/// decision 75 over them:
///
///   * every `workspaces` entry expands to directories holding a manifest
///     (a `<dir>/*` glob skips a child without one; a literal `<dir>` must have one);
///   * a member is a package, never a workspace;
///   * two members with one `name` is an error;
///   * a member's `targets` may only restrict the workspace's; a member without
///     `targets` inherits them;
///   * a member's `otp` must be the workspace's; a member without one inherits it;
///   * `{ "workspace": true }` names a sibling member; a `path` that lands on a
///     sibling member or on the workspace itself is refused.
///
/// `m.path` must be the workspace's manifest path; member paths are built under
/// its directory.
pub fn expand(arena: std.mem.Allocator, io: std.Io, m: Manifest, out_err: *?Located) Error!Workspace {
    std.debug.assert(m.isWorkspace());
    const ws_dir = m.dir();
    var members: std.ArrayListUnmanaged(Member) = .empty;

    for (m.workspaces) |g| {
        if (casesOuter(g)) |outer| {
            const base = if (outer.len == 0) ws_dir else try std.fs.path.join(arena, &.{ ws_dir, outer });
            for (try childDirs(arena, io, base)) |module| {
                const cases_dir = try std.fs.path.join(arena, &.{ base, module, "cases" });
                std.Io.Dir.cwd().access(io, cases_dir, .{}) catch continue; // a module without cases
                for (try childDirs(arena, io, cases_dir)) |case| {
                    const member_dir = try std.fs.path.join(arena, &.{ cases_dir, case });
                    const manifest_path = try std.fs.path.join(arena, &.{ member_dir, FILENAME });
                    std.Io.Dir.cwd().access(io, manifest_path, .{}) catch continue; // not a member
                    try addMember(arena, io, &members, m, g, member_dir, out_err);
                }
            }
        } else if (globChildrenOf(g)) |sub| {
            const base = if (sub.len == 0) ws_dir else try std.fs.path.join(arena, &.{ ws_dir, sub });
            var d = std.Io.Dir.cwd().openDir(io, base, .{ .iterate = true }) catch {
                out_err.* = located(m.text, m.path, locateEntry(m.text, "workspaces", g), try std.fmt.allocPrint(
                    arena,
                    "workspaces entry \"{s}\": {s} is not a directory that can be read",
                    .{ g, base },
                ));
                return error.Invalid;
            };
            defer d.close(io);
            // Sorted, so the member order (and every message that lists it) is stable.
            var names: std.ArrayListUnmanaged([]const u8) = .empty;
            var it = d.iterate();
            while (it.next(io) catch null) |entry| {
                if (entry.kind != .directory) continue;
                try names.append(arena, try arena.dupe(u8, entry.name));
            }
            std.mem.sort([]const u8, names.items, {}, struct {
                fn lt(_: void, a: []const u8, b: []const u8) bool {
                    return std.mem.lessThan(u8, a, b);
                }
            }.lt);
            for (names.items) |child| {
                const member_dir = try std.fs.path.join(arena, &.{ base, child });
                const manifest_path = try std.fs.path.join(arena, &.{ member_dir, FILENAME });
                std.Io.Dir.cwd().access(io, manifest_path, .{}) catch continue; // not a member
                try addMember(arena, io, &members, m, g, member_dir, out_err);
            }
        } else {
            const member_dir = try std.fs.path.join(arena, &.{ ws_dir, g });
            const manifest_path = try std.fs.path.join(arena, &.{ member_dir, FILENAME });
            std.Io.Dir.cwd().access(io, manifest_path, .{}) catch {
                out_err.* = located(m.text, m.path, locateEntry(m.text, "workspaces", g), try std.fmt.allocPrint(
                    arena,
                    "workspaces entry \"{s}\": {s} does not exist — a literal entry names a directory holding a botopink.json",
                    .{ g, manifest_path },
                ));
                return error.Invalid;
            };
            try addMember(arena, io, &members, m, g, member_dir, out_err);
        }
    }

    var ws: Workspace = .{ .dir = ws_dir, .manifest = m, .members = members.items };

    // Second pass — rules that need the whole member set. Each member first
    // takes what its workspace declares for every member (decision 512).
    for (members.items) |*mem| try inheritFrom(arena, m, &mem.manifest, mem.dir, out_err);
    for (members.items) |*mem| {
        const mm = &mem.manifest;
        for (mm.dependencies) |dep| {
            const at_loc = mm.locateEntryAt("dependencies", dep.name, "");
            if (dep.spec.workspace) {
                if (std.mem.eql(u8, dep.name, mem.name)) {
                    out_err.* = withMessage(at_loc, try std.fmt.allocPrint(arena, "\"{s}\" cannot depend on itself", .{dep.name}));
                    return error.Invalid;
                }
                if (ws.member(dep.name) == null) {
                    out_err.* = withMessage(at_loc, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\": {{ \"workspace\": true }} names no member of {s} (members: {s})",
                        .{ dep.name, m.path, try ws.memberList(arena) },
                    ));
                    return error.Invalid;
                }
            } else if (dep.spec.path) |p| {
                const target = try std.fs.path.resolve(arena, &.{ mem.dir, p });
                const ws_abs = try std.fs.path.resolve(arena, &.{ws_dir});
                if (samePath(target, ws_abs)) {
                    out_err.* = withMessage(at_loc, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\": path \"{s}\" points at the workspace itself — a workspace is not a package; depend on one of its members with {{ \"workspace\": true }} (members: {s})",
                        .{ dep.name, p, try ws.memberList(arena) },
                    ));
                    return error.Invalid;
                }
                for (members.items) |other| {
                    const other_abs = try std.fs.path.resolve(arena, &.{other.dir});
                    if (samePath(target, other_abs)) {
                        out_err.* = withMessage(at_loc, try std.fmt.allocPrint(
                            arena,
                            "\"{s}\": path \"{s}\" points at the sibling member \"{s}\" — use {{ \"workspace\": true }}",
                            .{ dep.name, p, other.name },
                        ));
                        return error.Invalid;
                    }
                }
            }
        }
    }
    ws.members = try members.toOwnedSlice(arena);
    return ws;
}

/// The sorted names of the subdirectories of `dir_path` (empty when it cannot be read).
fn childDirs(arena: std.mem.Allocator, io: std.Io, dir_path: []const u8) Error![]const []const u8 {
    var d = std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true }) catch return &.{};
    defer d.close(io);
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = d.iterate();
    while (it.next(io) catch null) |entry| {
        if (entry.kind != .directory) continue;
        try names.append(arena, try arena.dupe(u8, entry.name));
    }
    std.mem.sort([]const u8, names.items, {}, struct {
        fn lt(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt);
    return names.items;
}

/// The directory a children glob lists, relative to the workspace: `<dir>`
/// for `<dir>/*`, `""` for `*` (the workspace's own); null for a literal entry.
fn globChildrenOf(g: []const u8) ?[]const u8 {
    if (casesOuter(g) != null) return null;
    if (std.mem.eql(u8, g, "*")) return "";
    if (std.mem.endsWith(u8, g, "/*")) return g[0 .. g.len - 2];
    return null;
}

/// The two-level form `*/cases/*` (`""`) or `<dir>/*/cases/*` (`<dir>`, a
/// literal without a `*`): the directory whose children are modules, each
/// holding its cases under `cases/` (decision 765). Null for any other glob.
fn casesOuter(g: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, g, "*/cases/*")) return "";
    const tail = "/*/cases/*";
    if (!std.mem.endsWith(u8, g, tail)) return null;
    const outer = g[0 .. g.len - tail.len];
    if (outer.len == 0 or std.mem.indexOfScalar(u8, outer, '*') != null) return null;
    return outer;
}

/// `l` with another message — a location computed once, reused.
fn withMessage(l: Located, message: []const u8) Located {
    var out = l;
    out.message = message;
    return out;
}

/// Decision 512 — what a member of the workspace `ws` takes from it, applied
/// to `member` (whose directory is `member_dir`, built from `ws`'s directory
/// as `expand` builds it, or both absolute):
///
///   * `dependencies`: every entry of the workspace's, its `path` (written
///     relative to the workspace's manifest) rewritten relative to the member;
///     the member's own are added to them, and an entry the member writes for
///     a name the workspace declares is refused, located at the member's entry
///     — one source per dependency in a workspace;
///   * `version`: the workspace's, when the member writes none and the
///     workspace does; `entry`: `main.bp` when the member writes none (`src`
///     already defaults to `src/`);
///   * `targets`: the workspace's when the member writes none, else a subset
///     of them (a member may only restrict); `otp`: the workspace's when the
///     member writes none, else the same release;
///   * `"bpp"` then names one of the member's dependencies, its own or an
///     inherited one (`checkBpp`).
///
/// Applied once: a manifest that already inherited is left as it is.
pub fn inheritFrom(arena: std.mem.Allocator, ws: Manifest, member: *Manifest, member_dir: []const u8, out_err: *?Located) Error!void {
    if (member.inherited_from != null) return;
    const mm = member;
    if (ws.dependencies.len > 0) {
        const up = try upToWorkspace(arena, ws.dir(), member_dir);
        var deps: std.ArrayListUnmanaged(DepEntry) = .empty;
        for (ws.dependencies) |wd| {
            for (mm.dependencies) |own| {
                if (!std.mem.eql(u8, own.name, wd.name)) continue;
                out_err.* = located(mm.text, mm.path, locateEntry(mm.text, "dependencies", own.name), try std.fmt.allocPrint(
                    arena,
                    "\"{s}\" is a dependency of the workspace ({s}), which every member inherits — delete this entry: a workspace has one source per dependency",
                    .{ own.name, ws.path },
                ));
                return error.Invalid;
            }
            var spec = wd.spec;
            if (spec.path) |p| {
                if (!std.fs.path.isAbsolute(p)) spec.path = try std.fs.path.join(arena, &.{ up, p });
            }
            try deps.append(arena, .{ .name = wd.name, .spec = spec, .inherited = true });
        }
        try deps.appendSlice(arena, mm.dependencies);
        mm.dependencies = deps.items;
    }
    if (!mm.version_declared and ws.version_declared) mm.version = ws.version;
    if (mm.entry == null) mm.entry = "main.bp";
    // `targets`: inherit, or restrict.
    if (ws.targets) |ws_targets| {
        if (mm.targets) |own| {
            for (own) |t| {
                if (!ws.supportsTarget(t)) {
                    out_err.* = located(mm.text, mm.path, locateEntry(mm.text, "targets", t), try std.fmt.allocPrint(
                        arena,
                        "\"{s}\" is not one of the workspace's targets [{s}] ({s}) — a member may only restrict the workspace's targets",
                        .{ t, try joinQuoted(arena, ws_targets), ws.path },
                    ));
                    return error.Invalid;
                }
            }
        } else {
            mm.targets = ws_targets;
            mm.targets_inherited = true;
        }
    }
    // `otp`: inherit, or say the same release.
    if (ws.otp) |ws_otp| {
        if (mm.otp) |own| {
            if (try otpDisagreement(arena, ws_otp, own)) |refusal| {
                out_err.* = refusal;
                return error.Invalid;
            }
        } else mm.otp = ws_otp;
    }
    mm.inherited_from = .{ .path = ws.path, .text = ws.text };
    try checkBpp(arena, mm.*, out_err);
}

/// `..` once per segment of `member_dir` below `ws_dir` (`../..` for
/// `<ws>/modules/x`): what makes a path written relative to the workspace's
/// manifest relative to the member's.
fn upToWorkspace(arena: std.mem.Allocator, ws_dir: []const u8, member_dir: []const u8) Error![]const u8 {
    const base = std.mem.trimEnd(u8, ws_dir, "/");
    var rest = member_dir;
    if (!std.mem.eql(u8, base, ".") and base.len > 0) {
        if (std.mem.startsWith(u8, member_dir, base) and member_dir.len > base.len and member_dir[base.len] == '/')
            rest = member_dir[base.len + 1 ..]
        else if (std.mem.eql(u8, std.mem.trimEnd(u8, member_dir, "/"), base))
            rest = "";
    }
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var it = std.mem.tokenizeScalar(u8, rest, '/');
    while (it.next()) |seg| {
        if (std.mem.eql(u8, seg, ".")) continue;
        if (out.items.len > 0) try out.append(arena, '/');
        try out.appendSlice(arena, "..");
    }
    if (out.items.len == 0) try out.append(arena, '.');
    return out.items;
}

/// Whether the workspace `ws` (its manifest's directory, as given) lists the
/// directory `dir` under `"workspaces"` — by its globs alone, without reading
/// any member: `<d>/*` lists every child of `<d>`, a literal entry the one
/// directory it names. Both paths are compared after `resolve`, so callers may
/// pass them absolute or from one base.
pub fn listsMember(arena: std.mem.Allocator, ws: Manifest, dir: []const u8) Error!bool {
    const target = try std.fs.path.resolve(arena, &.{dir});
    for (ws.workspaces) |g| {
        if (casesOuter(g)) |outer| {
            // <ws>/<outer>/<module>/cases/<case>
            const cases_dir = std.fs.path.dirname(target) orelse continue;
            if (!std.mem.eql(u8, std.fs.path.basename(cases_dir), "cases")) continue;
            const module_dir = std.fs.path.dirname(cases_dir) orelse continue;
            const base = try std.fs.path.resolve(arena, &.{ ws.dir(), outer });
            const parent = std.fs.path.dirname(module_dir) orelse continue;
            if (samePath(parent, base)) return true;
        } else if (globChildrenOf(g)) |sub| {
            const base = try std.fs.path.resolve(arena, &.{ ws.dir(), sub });
            const parent = std.fs.path.dirname(target) orelse continue;
            if (samePath(parent, base)) return true;
        } else {
            if (samePath(try std.fs.path.resolve(arena, &.{ ws.dir(), g }), target)) return true;
        }
    }
    return false;
}

/// The manifest of the workspace `dir` is a member of, by the nearest
/// ancestor workspace's globs (`listsMember`) — its members unread, so a
/// sibling's refused manifest does not refuse this one (the CLI's `config.load`
/// inherits through it before it expands the workspace). Null when the nearest
/// ancestor workspace does not list `dir`, or there is none. `dir` absolute.
pub fn workspaceOf(arena: std.mem.Allocator, io: std.Io, dir: []const u8, out_err: *?Located) Error!?Manifest {
    var d: []const u8 = std.fs.path.dirname(dir) orelse return null;
    while (true) {
        if (isWorkspaceDir(io, d)) {
            const m = read(arena, io, d, out_err) catch |err| switch (err) {
                error.NotFound => return null,
                else => |e| return e,
            };
            return if (try listsMember(arena, m, dir)) m else null;
        }
        const parent = std.fs.path.dirname(d) orelse return null;
        if (std.mem.eql(u8, parent, d)) return null;
        d = parent;
    }
}

fn joinQuoted(arena: std.mem.Allocator, items: []const []const u8) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    for (items, 0..) |s, i| {
        if (i > 0) try buf.appendSlice(arena, ", ");
        try buf.append(arena, '"');
        try buf.appendSlice(arena, s);
        try buf.append(arena, '"');
    }
    return buf.toOwnedSlice(arena);
}

fn addMember(
    arena: std.mem.Allocator,
    io: std.Io,
    members: *std.ArrayListUnmanaged(Member),
    ws: Manifest,
    glob: []const u8,
    member_dir: []const u8,
    out_err: *?Located,
) Error!void {
    const mm = readWith(arena, io, member_dir, out_err, true) catch |err| switch (err) {
        error.NotFound => {
            out_err.* = located(ws.text, ws.path, locateEntry(ws.text, "workspaces", glob), try std.fmt.allocPrint(
                arena,
                "workspaces entry \"{s}\": {s}/botopink.json could not be read",
                .{ glob, member_dir },
            ));
            return error.Invalid;
        },
        error.Invalid => return error.Invalid,
        error.OutOfMemory => return error.OutOfMemory,
    };
    if (mm.isWorkspace()) {
        out_err.* = located(mm.text, mm.path, locateKey(mm.text, "workspaces"), try std.fmt.allocPrint(
            arena,
            "\"{s}\" is a member of {s} and cannot itself be a workspace — workspaces do not nest",
            .{ mm.name, ws.path },
        ));
        return error.Invalid;
    }
    for (members.items) |other| {
        if (std.mem.eql(u8, other.name, mm.name)) {
            out_err.* = located(mm.text, mm.path, locateKey(mm.text, "name"), try std.fmt.allocPrint(
                arena,
                "member name \"{s}\" is declared twice in {s}: {s} and {s}",
                .{ mm.name, ws.path, other.manifest.path, mm.path },
            ));
            return error.Invalid;
        }
    }
    try members.append(arena, .{ .name = mm.name, .dir = member_dir, .manifest = mm });
}

/// The workspace `project_dir` is a member of, if any: the nearest ancestor
/// holding a workspace manifest whose expansion lists `project_dir`. An
/// ancestor workspace that does not list the directory is not its workspace
/// (`null`). `project_dir` must be absolute. A workspace that does not expand
/// is a located error — the member cannot know its siblings.
pub fn enclosingWorkspace(arena: std.mem.Allocator, io: std.Io, project_dir: []const u8, out_err: *?Located) Error!?Workspace {
    var dir: []const u8 = std.fs.path.dirname(project_dir) orelse return null;
    while (true) {
        if (isWorkspaceDir(io, dir)) {
            const m = read(arena, io, dir, out_err) catch |err| switch (err) {
                error.NotFound => return null,
                else => |e| return e,
            };
            // A directory the workspace's globs do not list is no member: the
            // workspace is not expanded for it (a sibling's refused manifest is
            // not this directory's error — a cell's `deps/<lib>` under a
            // `conformance/modules/` workspace).
            if (!try listsMember(arena, m, project_dir)) return null;
            const ws = try expand(arena, io, m, out_err);
            const abs_target = try std.fs.path.resolve(arena, &.{project_dir});
            for (ws.members) |mem| {
                const abs_member = try std.fs.path.resolve(arena, &.{mem.dir});
                if (samePath(abs_member, abs_target)) return ws;
            }
            return null;
        }
        const parent = std.fs.path.dirname(dir) orelse return null;
        if (std.mem.eql(u8, parent, dir)) return null;
        dir = parent;
    }
}

/// Where every build cache lives, relative to its cache root (decision 225):
/// deleting the root's `.botopinkbuild/` deletes them all.
pub const CACHE_DIR = ".botopinkbuild/cache";

/// The directory whose `.botopinkbuild/cache/` holds the caches of the package
/// in `project_dir`: the root of `workspace` (the one it is a member of) — so
/// the members of one library repository share one cache — else `project_dir`.
pub fn cacheRoot(project_dir: []const u8, workspace: ?Workspace) []const u8 {
    return if (workspace) |ws| ws.dir else project_dir;
}

/// `cacheRoot` for a caller that has not looked the workspace up: asks
/// `enclosingWorkspace` for `project_dir` (absolute). A workspace that does not
/// expand is its located error — the caller decides whether that is fatal.
pub fn findCacheRoot(arena: std.mem.Allocator, io: std.Io, project_dir: []const u8, out_err: *?Located) Error![]const u8 {
    return cacheRoot(project_dir, try enclosingWorkspace(arena, io, project_dir, out_err));
}

/// `<root>/.botopinkbuild/cache/<store>` — the home of one store under a cache
/// root (`cacheRoot` / `findCacheRoot`). Nothing reads the environment: a cache
/// in the user's home is one `rm -rf .botopinkbuild` cannot reach.
pub fn cacheDir(arena: std.mem.Allocator, root: []const u8, store: []const u8) std.mem.Allocator.Error![]const u8 {
    return std.fs.path.join(arena, &.{ root, CACHE_DIR, store });
}

/// Where a project's `git` dependencies are linked, relative to the project (or
/// to its workspace root): `bpmp install` links each into its store, `bpmp link`
/// each into a local checkout's `repository/<name>` (decision 483).
pub const DEPS_DIR = ".botopinkbuild/deps";

/// The directories whose children a `git` dependency of the project at
/// `project_dir` (absolute) is looked up in before the walk-up roots (decision
/// 483), in order: `<project_dir>/.botopinkbuild/deps`, then — for a workspace
/// member — `<workspace root>/.botopinkbuild/deps`. `bpmp install` writes the
/// first (it links the dependencies of the manifest in its working directory,
/// and a workspace manifest declares none); `bpmp link` run at a workspace root
/// writes the second, one link per name for every member. A directory that does
/// not exist is listed all the same (`scanRoots` skips it). A workspace that
/// does not expand contributes nothing here — the command that reads it
/// reports it.
pub fn depsRoots(arena: std.mem.Allocator, io: std.Io, project_dir: []const u8) std.mem.Allocator.Error![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    try out.append(arena, try std.fs.path.join(arena, &.{ project_dir, DEPS_DIR }));
    var err: ?Located = null;
    const ws = enclosingWorkspace(arena, io, project_dir, &err) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Invalid => null,
    };
    if (ws) |w| {
        const ws_deps = try std.fs.path.join(arena, &.{ w.dir, DEPS_DIR });
        if (!samePath(try std.fs.path.resolve(arena, &.{ws_deps}), try std.fs.path.resolve(arena, &.{out.items[0]})))
            try out.append(arena, ws_deps);
    }
    return out.toOwnedSlice(arena);
}

/// A package is a library when its module tree is rooted at `root.bp` rather
/// than `main.bp`: `entry` decides when set, else the presence of
/// `<src>/main.bp`. A library member with no `files` ships nothing to a
/// consumer — the failure `botopink test` and the runner report.
pub fn isLibraryPackage(io: std.Io, m: Manifest) bool {
    if (m.entry) |e| return !std.mem.eql(u8, std.fs.path.basename(e), "main.bp");
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const main_path = std.fs.path.join(fba.allocator(), &.{ m.dir(), std.mem.trimEnd(u8, m.src, "/"), "main.bp" }) catch return true;
    std.Io.Dir.cwd().access(io, main_path, .{}) catch return true;
    return false;
}

pub const SHIPS_NOTHING = "ships nothing: manifest has no \"files\" — a workspace member that is a library lists every module a consumer may import";

/// The located `ships nothing` error for a library member without `files`, or
/// null when the member ships something (or is an application).
pub fn shipsNothing(io: std.Io, m: Manifest) ?Located {
    if (m.files.len > 0) return null;
    if (!isLibraryPackage(io, m)) return null;
    return located(m.text, m.path, locateKey(m.text, "name"), SHIPS_NOTHING);
}

// ── Discovery across roots ─────────────────────────────────────────────────────

/// One library a root list makes reachable by name: a package directory that
/// is an immediate child of a root, or a member of a workspace that is a root
/// or a root's child. A workspace itself is an entry too (`is_workspace`), so a
/// lookup by its name can say what it is instead of "not found".
pub const Entry = struct {
    /// Import name: the directory name of a plain package, the manifest `name`
    /// of a member, the directory name of a workspace.
    name: []const u8,
    dir: []const u8,
    /// Null when `problem` prevented parsing.
    manifest: ?Manifest,
    /// The enclosing workspace of a member.
    workspace: ?*const Workspace = null,
    is_workspace: bool = false,
    /// Why this entry cannot be used: a manifest that does not parse, a
    /// workspace that does not expand, a name declared by two libraries.
    problem: ?Located = null,
};

/// Discover every library the ordered `roots` make reachable, one shared walk
/// for the compiler, the runner and the language server:
///
///   * a root whose own `botopink.json` is a workspace contributes its members;
///   * otherwise each immediate child holding a `botopink.json` contributes
///     itself (a package) or its members (a workspace) — no recursion beyond
///     that, no environment variable;
///   * the same directory reached through two roots is one entry;
///   * two **members** with one `name` in different directories (across roots,
///     or a member and a plain package) are both marked with a located problem
///     — first-root-wins is what decision 75 retires. Two plain packages with
///     one name keep first-root-wins, as they always did.
///
/// A manifest that is refused marks only its own entry (or its workspace's
/// members' entry) with the problem — a broken sibling never fails a build
/// that does not use it. Entries keep root order.
pub fn scanRoots(arena: std.mem.Allocator, io: std.Io, roots: []const []const u8) std.mem.Allocator.Error![]Entry {
    var entries: std.ArrayListUnmanaged(Entry) = .empty;
    for (roots) |root| {
        var err: ?Located = null;
        if (read(arena, io, root, &err)) |own| {
            if (own.isWorkspace()) {
                try addWorkspaceEntries(arena, io, &entries, own, std.fs.path.basename(root), root);
                continue;
            }
            // A root that is itself a package: not a layout any tool produces;
            // scan its children like any other root.
        } else |e| switch (e) {
            error.NotFound => {},
            error.Invalid => {
                // The root's own manifest is broken but it is not a workspace
                // (or cannot be told); children still count.
            },
            error.OutOfMemory => return error.OutOfMemory,
        }
        var d = std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true }) catch continue;
        defer d.close(io);
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = d.iterate();
        while (it.next(io) catch null) |entry| {
            // A symbolic link to a directory is a child like a directory:
            // `bpmp install` materialises every dependency under
            // `.botopinkbuild/deps/` as one.
            const is_dir = switch (entry.kind) {
                .directory => true,
                .sym_link => blk: {
                    var target = d.openDir(io, entry.name, .{}) catch break :blk false;
                    target.close(io);
                    break :blk true;
                },
                else => false,
            };
            if (!is_dir) continue;
            try names.append(arena, try arena.dupe(u8, entry.name));
        }
        std.mem.sort([]const u8, names.items, {}, struct {
            fn lt(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.lessThan(u8, a, b);
            }
        }.lt);
        for (names.items) |child| {
            const child_dir = try std.fs.path.join(arena, &.{ root, child });
            var cerr: ?Located = null;
            const cm = read(arena, io, child_dir, &cerr) catch |e| switch (e) {
                error.NotFound => continue,
                error.Invalid => {
                    try addUnique(arena, &entries, .{ .name = child, .dir = child_dir, .manifest = null, .problem = cerr });
                    continue;
                },
                error.OutOfMemory => return error.OutOfMemory,
            };
            if (cm.isWorkspace()) {
                try addWorkspaceEntries(arena, io, &entries, cm, child, child_dir);
            } else {
                try addUnique(arena, &entries, .{ .name = child, .dir = child_dir, .manifest = cm });
            }
        }
    }
    return resolveDuplicateNames(arena, entries.items);
}

fn addWorkspaceEntries(
    arena: std.mem.Allocator,
    io: std.Io,
    entries: *std.ArrayListUnmanaged(Entry),
    m: Manifest,
    name: []const u8,
    dir: []const u8,
) std.mem.Allocator.Error!void {
    var err: ?Located = null;
    const ws = expand(arena, io, m, &err) catch |e| switch (e) {
        error.Invalid => {
            try addUnique(arena, entries, .{ .name = name, .dir = dir, .manifest = m, .is_workspace = true, .problem = err });
            return;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
    const ws_ptr = try arena.create(Workspace);
    ws_ptr.* = ws;
    for (ws.members) |mem| {
        try addUnique(arena, entries, .{ .name = mem.name, .dir = mem.dir, .manifest = mem.manifest, .workspace = ws_ptr });
    }
    // The umbrella after its members: a core member named like its umbrella's
    // directory (`repository/rakun/modules/rakun`) is what `rakun` means.
    try addUnique(arena, entries, .{ .name = name, .dir = dir, .manifest = m, .is_workspace = true, .workspace = ws_ptr });
}

/// Append unless the same directory is already listed (one directory reached
/// through two roots — the enclosing workspace of the cwd and `repository/`,
/// typically — is one library).
fn addUnique(arena: std.mem.Allocator, entries: *std.ArrayListUnmanaged(Entry), e: Entry) std.mem.Allocator.Error!void {
    const abs = try std.fs.path.resolve(arena, &.{e.dir});
    for (entries.items) |x| {
        const xabs = try std.fs.path.resolve(arena, &.{x.dir});
        if (samePath(abs, xabs)) return;
    }
    try entries.append(arena, e);
}

/// One name, two directories: two plain packages keep first-root-wins (the
/// later one is dropped, as it always was); a pair involving a workspace member
/// is refused on both sides. A workspace entry never competes — a core member
/// named like its umbrella's directory is told apart by `is_workspace`.
fn resolveDuplicateNames(arena: std.mem.Allocator, entries: []Entry) std.mem.Allocator.Error![]Entry {
    var out: std.ArrayListUnmanaged(Entry) = .empty;
    outer: for (entries) |e| {
        if (!e.is_workspace) {
            for (out.items) |*seen| {
                if (seen.is_workspace or !std.mem.eql(u8, seen.name, e.name)) continue;
                if (seen.workspace == null and e.workspace == null) continue :outer; // first root wins
                const message = try std.fmt.allocPrint(
                    arena,
                    "\"{s}\" is declared by two libraries: {s} and {s} — a name resolves to one library; rename one of them",
                    .{ e.name, seen.dir, e.dir },
                );
                if (seen.problem == null) seen.problem = nameProblem(seen.*, message);
                var dup = e;
                if (dup.problem == null) dup.problem = nameProblem(dup, message);
                try out.append(arena, dup);
                continue :outer;
            }
        }
        try out.append(arena, e);
    }
    return out.toOwnedSlice(arena);
}

fn nameProblem(e: Entry, message: []const u8) Located {
    if (e.manifest) |m| return located(m.text, m.path, locateKey(m.text, "name"), message);
    return .{ .message = message, .file = e.dir, .source = "", .line = 1, .col = 1, .span = 1 };
}

/// The library named `name`: the first package or member so named; a
/// workspace so named only when no package is (so a lookup can say what the
/// umbrella is instead of "not found").
pub fn find(entries: []const Entry, name: []const u8) ?Entry {
    var umbrella: ?Entry = null;
    for (entries) |e| {
        if (!std.mem.eql(u8, e.name, name)) continue;
        if (e.is_workspace) {
            if (umbrella == null) umbrella = e;
            continue;
        }
        return e;
    }
    return umbrella;
}

// ── Dependency resolution ──────────────────────────────────────────────────────

pub const ResolvedDep = struct {
    dir: []const u8,
    manifest: Manifest,
};

/// Resolve one `dependencies` entry of the project at `project_dir` (absolute)
/// whose manifest is `project`:
///
///   * `{ "workspace": true }` → the sibling member of the enclosing workspace
///     with that name; no enclosing workspace, or no such member, is a located
///     error in the project's manifest;
///   * `{ "path": … }` → `<project_dir>/<path>`, which must hold a package of
///     that name; a workspace, a sibling member (use `{ "workspace": true }`) and
///     a name mismatch are located errors;
///   * `{ "git": … }` → the first entry named so in the first of `tiers` that
///     carries the name (decision 483: `BOTOPINK_LIB_ROOTS`, then the project's
///     `.botopinkbuild/deps/` links — `depsRoots` —, then the walk-up roots;
///     each tier is one `scanRoots`, so a name in two tiers is the earlier
///     tier's and never "declared by two libraries"); an entry with a problem
///     returns that problem; a workspace is refused with its member list;
///     `null` when no tier carries the name.
pub fn resolveDependency(
    arena: std.mem.Allocator,
    io: std.Io,
    project: Manifest,
    project_dir: []const u8,
    dep: DepEntry,
    tiers: []const []const Entry,
    out_err: *?Located,
) Error!?ResolvedDep {
    const at = project.locateEntryAt("dependencies", dep.name, "");
    if (dep.spec.workspace) {
        const ws = (try enclosingWorkspace(arena, io, project_dir, out_err)) orelse {
            out_err.* = withMessage(at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": {{ \"workspace\": true }} but {s} is not a member of any workspace — no ancestor botopink.json lists this directory under \"workspaces\"",
                .{ dep.name, project.path },
            ));
            return error.Invalid;
        };
        const mem = ws.member(dep.name) orelse {
            out_err.* = withMessage(at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": {{ \"workspace\": true }} names no member of {s} (members: {s})",
                .{ dep.name, ws.manifest.path, try ws.memberList(arena) },
            ));
            return error.Invalid;
        };
        return .{ .dir = mem.dir, .manifest = mem.manifest };
    }
    if (dep.spec.path) |p| {
        const target = try std.fs.path.resolve(arena, &.{ project_dir, p });
        var terr: ?Located = null;
        const tm = read(arena, io, target, &terr) catch |e| switch (e) {
            error.NotFound => {
                out_err.* = withMessage(at, try std.fmt.allocPrint(
                    arena,
                    "\"{s}\": path \"{s}\" holds no botopink.json (looked at {s}/botopink.json)",
                    .{ dep.name, p, target },
                ));
                return error.Invalid;
            },
            error.Invalid => {
                out_err.* = terr;
                return error.Invalid;
            },
            error.OutOfMemory => return error.OutOfMemory,
        };
        if (tm.isWorkspace()) {
            var werr: ?Located = null;
            const ws = expand(arena, io, tm, &werr) catch |e| switch (e) {
                error.Invalid => {
                    out_err.* = werr;
                    return error.Invalid;
                },
                error.OutOfMemory => return error.OutOfMemory,
            };
            out_err.* = withMessage(at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": path \"{s}\" is a workspace, not a package — depend on one of its members: {s}",
                .{ dep.name, p, try ws.memberList(arena) },
            ));
            return error.Invalid;
        }
        if (try enclosingWorkspace(arena, io, project_dir, out_err)) |ws| {
            for (ws.members) |mem| {
                if (samePath(try std.fs.path.resolve(arena, &.{mem.dir}), target)) {
                    out_err.* = withMessage(at, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\": path \"{s}\" points at the sibling member \"{s}\" — use {{ \"workspace\": true }}",
                        .{ dep.name, p, mem.name },
                    ));
                    return error.Invalid;
                }
            }
        }
        if (!std.mem.eql(u8, tm.name, dep.name)) {
            out_err.* = withMessage(at, try std.fmt.allocPrint(
                arena,
                "\"{s}\": path \"{s}\" holds a package named \"{s}\" — the dependency key is the import name and must match",
                .{ dep.name, p, tm.name },
            ));
            return error.Invalid;
        }
        return .{ .dir = target, .manifest = tm };
    }
    // git: by name, tier by tier (decision 483).
    const found = for (tiers) |tier| {
        if (find(tier, dep.name)) |e| break e;
    } else return null;
    if (found.problem) |pr| {
        out_err.* = pr;
        return error.Invalid;
    }
    if (found.is_workspace) {
        const list = if (found.workspace) |ws| try ws.memberList(arena) else "none";
        out_err.* = withMessage(at, try std.fmt.allocPrint(
            arena,
            "\"{s}\" is a workspace, not a package — import one of its members: {s}",
            .{ dep.name, list },
        ));
        return error.Invalid;
    }
    return .{ .dir = found.dir, .manifest = found.manifest.? };
}

// ── Tests ──────────────────────────────────────────────────────────────────────
//
// Fixtures live under `tests/fixtures/` (cwd is `modules/manifest`, set by
// build.zig): a good workspace and one broken manifest per located error.

const testing = std.testing;
const FIX = "tests/fixtures";

fn parseText(arena: std.mem.Allocator, text: []const u8) !Manifest {
    var err: ?Located = null;
    return parse(arena, text, "botopink.json", &err);
}

/// Parse `text` expecting a refusal; returns the rendered located error.
fn refuse(arena: std.mem.Allocator, text: []const u8) ![]const u8 {
    var err: ?Located = null;
    const r = parse(arena, text, "botopink.json", &err);
    try testing.expectError(error.Invalid, r);
    return try err.?.renderAlloc(arena);
}

test "parse: a package manifest — every field the tools read" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const m = try parseText(a,
        \\{ "name": "acme", "version": "0.0.1", "description": "d", "src": "lib/", "entry": "root.bp",
        \\  "target": "commonJS", "targets": ["commonJS", "erlang"], "files": ["root.bp", "http.bp"],
        \\  "dependencies": {
        \\    "std-extra": { "path": "../std-extra" },
        \\    "jhonstart": { "git": "https://github.com/botopink/jhonstart.git", "branch": "feat" },
        \\    "acme-core": { "workspace": true }
        \\  } }
    );
    try testing.expectEqual(Kind.package, m.kind);
    try testing.expectEqualStrings("acme", m.name);
    try testing.expectEqualStrings("0.0.1", m.version);
    try testing.expectEqualStrings("d", m.description.?);
    try testing.expectEqualStrings("lib/", m.src);
    try testing.expectEqualStrings("root.bp", m.entry.?);
    try testing.expectEqualStrings("commonJS", m.target.?);
    try testing.expectEqual(@as(usize, 2), m.targets.?.len);
    try testing.expectEqual(@as(usize, 2), m.files.len);
    try testing.expectEqual(@as(usize, 3), m.dependencies.len);
    try testing.expectEqualStrings("../std-extra", m.dependencies[0].spec.path.?);
    try testing.expectEqualStrings("feat", m.dependencies[1].spec.ref.branch);
    try testing.expect(m.dependencies[2].spec.workspace);
    try testing.expect(m.supportsTarget("erlang"));
    try testing.expect(!m.supportsTarget("wasm"));
}

test "parse: defaults when the optional fields are absent" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const m = try parseText(arena_inst.allocator(),
        \\{ "name": "p" }
    );
    try testing.expectEqualStrings("0.1.0", m.version);
    try testing.expectEqualStrings("src/", m.src);
    try testing.expect(m.entry == null);
    try testing.expect(m.target == null);
    try testing.expect(m.targets == null);
    try testing.expectEqual(@as(usize, 0), m.files.len);
    try testing.expectEqual(@as(usize, 0), m.dependencies.len);
    try testing.expect(m.supportsTarget("wasm"));
}

test "parse: the string-array dependencies form is a located error naming the fix (76)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const out = try refuse(arena_inst.allocator(),
        \\{ "name": "p",
        \\  "dependencies": ["erika"] }
    );
    try testing.expectEqualStrings(
        \\error: "dependencies" must be an object, not an array — write { "<name>": { "path": "…" } | { "git": "…", "branch"|"tag"|"rev": "…" } | { "workspace": true } }; for example ["erika"] becomes { "erika": { "path": "../erika" } }
        \\ --> botopink.json:2:3
        \\  |
        \\2 |   "dependencies": ["erika"] }
        \\  |   ^^^^^^^^^^^^^^
        \\
        \\
    , out);
}

test "parse: an empty dependencies array is refused too — the object form is the only form" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const out = try refuse(arena_inst.allocator(),
        \\{ "name": "p", "dependencies": [] }
    );
    try testing.expect(std.mem.indexOf(u8, out, "must be an object, not an array") != null);
}

test "parse: a name that cannot start an erlang atom is refused, located at the name (decision 109)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    for ([_][]const u8{
        \\{ "name": "MyApp" }
        ,
        \\{ "name": "9lives" }
        ,
        \\{ "name": "_x" }
        ,
        \\{ "name": "" }
        ,
    }) |text| {
        const out = try refuse(arena_inst.allocator(), text);
        try testing.expect(std.mem.indexOf(u8, out, "must start with a lowercase letter") != null);
    }
    const bp_out = try refuse(arena_inst.allocator(),
        \\{ "name": "bp" }
    );
    try testing.expect(std.mem.indexOf(u8, bp_out, "compiler's own namespace") != null);
    // A lowercase first letter is all it asks: the rest is sanitised.
    try testing.expect(nameRefusal("acme-web") == null);
    try testing.expect(nameRefusal("myApp2") == null);
}

test "parse: a package named std is refused at its name, unless it is the bundled libs/std (453)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const out = try refuse(a,
        \\{ "name": "std", "version": "0.0.1" }
    );
    try testing.expectEqualStrings(
        \\error: the package name `std` is the bundled standard library's — choose another name
        \\ --> botopink.json:1:3
        \\  |
        \\1 | { "name": "std", "version": "0.0.1" }
        \\  |   ^^^^^^
        \\
        \\
    , out);
    var err: ?Located = null;
    const m = try parseBundledStd(a, "{ \"name\": \"std\" }", "botopink.json", &err);
    try testing.expectEqualStrings("std", m.name);
}

test "isBundledStd: the checkout's libs/std by its place, not by a name" {
    // cwd is `modules/manifest`: `../../libs/std` is the compiler's own std.
    try testing.expect(isBundledStd(testing.io, "../../libs/std"));
    try testing.expect(!isBundledStd(testing.io, "tests/fixtures/workspace"));
    try testing.expect(!isBundledStd(testing.io, "../../libs"));
    try testing.expect(!isBundledStd(testing.io, "no/such/dir"));
}

test "parse: a dependency with no source is a located error" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const out = try refuse(arena_inst.allocator(),
        \\{ "name": "p", "dependencies": {
        \\  "x": { "branch": "feat" } } }
    );
    try testing.expectEqualStrings(
        \\error: dependency "x" declares no source — one of "git", "path" or "workspace": true is required
        \\ --> botopink.json:2:3
        \\  |
        \\2 |   "x": { "branch": "feat" } } }
        \\  |   ^^^
        \\
        \\
    , out);
}

test "parse: two pins, two sources, a pin without git, and workspace: false are located errors" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const two_pins = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "git": "https://e/x.git", "branch": "feat", "rev": "deadbeef" } } }
    );
    try testing.expect(std.mem.indexOf(u8, two_pins, "error: dependency \"x\" declares more than one pin — exactly one of \"branch\", \"tag\" or \"rev\"") != null);
    const two_sources = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "path": "../x", "workspace": true } } }
    );
    try testing.expect(std.mem.indexOf(u8, two_sources, "error: dependency \"x\" declares more than one source — exactly one of \"git\", \"path\" or \"workspace\": true") != null);
    const pin_no_git = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "path": "../x", "tag": "v1" } } }
    );
    try testing.expect(std.mem.indexOf(u8, pin_no_git, "error: dependency \"x\" pins a ref without a \"git\" source") != null);
    const ws_false = try refuse(a,
        \\{ "name": "p", "dependencies": { "x": { "workspace": false } } }
    );
    try testing.expect(std.mem.indexOf(u8, ws_false, "error: dependency \"x\": \"workspace\" can only be true") != null);
}

test "parse: a git dependency's \"subdir\" names a package inside its repository (decision 344)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const m = try parseText(arena_inst.allocator(),
        \\{ "name": "app", "dependencies": {
        \\  "rakun-web": { "git": "https://github.com/botopink/rakun", "tag": "v1.0", "subdir": "modules/rakun-web" },
        \\  "rakun": { "git": "https://github.com/botopink/rakun.git", "tag": "v1.0", "subdir": "modules/rakun" },
        \\  "erika": { "git": "https://github.com/botopink/erika.git" } } }
    );
    try testing.expectEqual(@as(usize, 3), m.dependencies.len);
    try testing.expectEqualStrings("modules/rakun-web", m.dependencies[0].spec.subdir.?);
    try testing.expectEqualStrings("v1.0", m.dependencies[0].spec.ref.tag);
    try testing.expectEqualStrings("modules/rakun", m.dependencies[1].spec.subdir.?);
    try testing.expect(m.dependencies[2].spec.subdir == null);
    try testing.expect(sameRepository("https://github.com/botopink/rakun", "https://github.com/botopink/rakun.git/"));
    try testing.expect(!sameRepository("https://github.com/botopink/rakun", "https://github.com/botopink/rakun-web"));
}

test "parse: a \"subdir\" without \"git\" is a located error" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const out = try refuse(arena_inst.allocator(),
        \\{ "name": "p", "dependencies": {
        \\  "web": { "path": "../rakun", "subdir": "modules/rakun-web" } } }
    );
    try testing.expectEqualStrings(
        \\error: dependency "web" names a "subdir" without a "git" source — a subdir names a package inside a git repository
        \\ --> botopink.json:2:3
        \\  |
        \\2 |   "web": { "path": "../rakun", "subdir": "modules/rakun-web" } } }
        \\  |   ^^^^^
        \\
        \\
    , out);
    const ws = try refuse(arena_inst.allocator(),
        \\{ "name": "p", "dependencies": { "web": { "workspace": true, "subdir": "modules/web" } } }
    );
    try testing.expect(std.mem.indexOf(u8, ws, "error: dependency \"web\" names a \"subdir\" without a \"git\" source") != null);
}

test "parse: a \"subdir\" absolute, leaving the repository, or not plain segments is a located error" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const abs = try refuse(a,
        \\{ "name": "p", "dependencies": {
        \\  "web": { "git": "https://e/rakun.git", "subdir": "/modules/web" } } }
    );
    try testing.expectEqualStrings(
        \\error: dependency "web": "subdir" "/modules/web" is absolute — it names a directory of the repository, relative to its root
        \\ --> botopink.json:2:3
        \\  |
        \\2 |   "web": { "git": "https://e/rakun.git", "subdir": "/modules/web" } } }
        \\  |   ^^^^^
        \\
        \\
    , abs);
    for ([_][]const u8{
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": ".." } } }
        ,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "../other/web" } } }
        ,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "modules/../../web" } } }
        ,
    }) |text| {
        const out = try refuse(a, text);
        try testing.expect(std.mem.indexOf(u8, out, "leaves the repository — \"..\" is not a segment of a subdir") != null);
    }
    const drive = try refuse(a,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "C:/web" } } }
    );
    try testing.expect(std.mem.indexOf(u8, drive, "is absolute") != null);
    const backslash = try refuse(a,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "modules\\web" } } }
    );
    try testing.expect(std.mem.indexOf(u8, backslash, "holds a backslash") != null);
    for ([_][]const u8{
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "." } } }
        ,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "./modules/web" } } }
        ,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "modules//web" } } }
        ,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "modules/web/" } } }
        ,
    }) |text| {
        const out = try refuse(a, text);
        try testing.expect(std.mem.indexOf(u8, out, "has an empty or \".\" segment") != null);
    }
    const empty = try refuse(a,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": "" } } }
    );
    try testing.expect(std.mem.indexOf(u8, empty, "\"subdir\" is empty — omit \"subdir\" for the package at the repository's root") != null);
    const not_string = try refuse(a,
        \\{ "name": "p", "dependencies": { "web": { "git": "https://e/rakun.git", "subdir": ["modules/web"] } } }
    );
    try testing.expect(std.mem.indexOf(u8, not_string, "dependency \"web\": \"subdir\" must be a string") != null);
}

test "parse: one repository at two refs is a located error naming both dependencies" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const out = try refuse(a,
        \\{ "name": "p", "dependencies": {
        \\  "web": { "git": "https://e/rakun.git", "tag": "v1.0", "subdir": "modules/web" },
        \\  "core": { "git": "https://e/rakun", "branch": "feat", "subdir": "modules/core" } } }
    );
    try testing.expectEqualStrings(
        \\error: dependencies "web" and "core" name one repository (https://e/rakun) at two refs (tag "v1.0" and branch "feat") — one repository is one checkout; pin both at one ref
        \\ --> botopink.json:3:3
        \\  |
        \\3 |   "core": { "git": "https://e/rakun", "branch": "feat", "subdir": "modules/core" } } }
        \\  |   ^^^^^^
        \\
        \\
    , out);
    // A pinned ref against the default branch is two refs as well.
    const default_vs_tag = try refuse(a,
        \\{ "name": "p", "dependencies": { "a": { "git": "https://e/r.git" }, "b": { "git": "https://e/r.git", "tag": "v1" } } }
    );
    try testing.expect(std.mem.indexOf(u8, default_vs_tag, "dependencies \"a\" and \"b\" name one repository (https://e/r.git) at two refs (the default branch and tag \"v1\")") != null);
}

test "parse: a workspace manifest — kind, globs, and no package field" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const m = try parseText(a,
        \\{ "name": "acme", "targets": ["commonJS"], "workspaces": ["modules/*", "examples/acme-app"] }
    );
    try testing.expect(m.isWorkspace());
    try testing.expectEqual(@as(usize, 2), m.workspaces.len);

    const with_files = try refuse(a,
        \\{ "name": "acme",
        \\  "workspaces": ["modules/*"],
        \\  "files": ["root.bp"] }
    );
    try testing.expectEqualStrings(
        \\error: a workspace manifest cannot carry "files" — a workspace declares members, it is not a package; move "files" to the member's own botopink.json
        \\ --> botopink.json:3:3
        \\  |
        \\3 |   "files": ["root.bp"] }
        \\  |   ^^^^^^^
        \\
        \\
    , with_files);
    for ([_][]const u8{ "src", "entry", "wasm" }) |field| {
        const text = try std.fmt.allocPrint(a, "{{ \"name\": \"w\", \"workspaces\": [\"m/*\"], \"{s}\": {s} }}", .{ field, if (std.mem.eql(u8, field, "wasm")) "{ \"host\": \"wasi\" }" else "\"x\"" });
        const out = try refuse(a, text);
        const want = try std.fmt.allocPrint(a, "error: a workspace manifest cannot carry \"{s}\"", .{field});
        try testing.expect(std.mem.indexOf(u8, out, want) != null);
    }
}

test "parse: unsupported glob forms are located errors" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const out = try refuse(a,
        \\{ "name": "w", "workspaces": ["modules/**"] }
    );
    try testing.expect(std.mem.indexOf(u8, out, "error: workspaces entry \"modules/**\" is not a supported form — use \"<dir>/*\"") != null);
    for ([_][]const u8{ "*/src", "../x", "/abs", "", "*/cases", "a/*/cases", "*/*/cases/*", "x/*/cases/*/y", "a*/b/cases/*" }) |g| {
        const text = try std.fmt.allocPrint(a, "{{ \"name\": \"w\", \"workspaces\": [\"{s}\"] }}", .{g});
        _ = try refuse(a, text);
    }
}

test "expand: the two-level globs list the cases of every module (decision 765)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var err: ?Located = null;
    const m = try read(a, testing.io, FIX ++ "/cases-workspace", &err);
    const ws = try expand(a, testing.io, m, &err);
    // "*" finds `plain` alone (the other children hold no manifest).
    try testing.expectEqualStrings("plain, parser-prints, parser-refused, d1-proved", try ws.memberList(a));
    try testing.expectEqualStrings(FIX ++ "/cases-workspace/parser/cases/prints", ws.member("parser-prints").?.dir);
    // A case may only restrict the workspace's targets.
    try testing.expectEqual(@as(usize, 1), ws.member("parser-refused").?.manifest.targets.?.len);
    try testing.expectEqual(@as(usize, 2), ws.member("parser-prints").?.manifest.targets.?.len);
}

test "listsMember: a case is listed by the two-level globs, a module and a stray directory are not" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var err: ?Located = null;
    const m = try read(a, testing.io, FIX ++ "/cases-workspace", &err);
    try testing.expect(try listsMember(a, m, FIX ++ "/cases-workspace/parser/cases/prints"));
    try testing.expect(try listsMember(a, m, FIX ++ "/cases-workspace/decisions-taken/d-1/cases/proved"));
    try testing.expect(!try listsMember(a, m, FIX ++ "/cases-workspace/parser/cases"));
    try testing.expect(!try listsMember(a, m, FIX ++ "/cases-workspace/parser/other/prints"));
    // Only the "*/cases/*" form lists a case of the modules directly under the root.
    const only = try read(a, testing.io, FIX ++ "/cases-workspace", &err);
    var narrowed = only;
    narrowed.workspaces = &.{"decisions-taken/*/cases/*"};
    try testing.expect(!try listsMember(a, narrowed, FIX ++ "/cases-workspace/parser/cases/prints"));
    try testing.expect(try listsMember(a, narrowed, FIX ++ "/cases-workspace/decisions-taken/d-1/cases/proved"));
}

test "expand: the fixture workspace — members, inherited targets, example member" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var err: ?Located = null;
    const m = try read(a, testing.io, FIX ++ "/workspace", &err);
    try testing.expect(m.isWorkspace());
    const ws = try expand(a, testing.io, m, &err);
    try testing.expectEqual(@as(usize, 4), ws.members.len);
    try testing.expectEqualStrings("acme, acme-empty, acme-web, acme-app", try ws.memberList(a));
    // `acme` restricts to commonJS; `acme-web` and `acme-app` inherit both.
    const core = ws.member("acme").?;
    try testing.expectEqual(@as(usize, 1), core.manifest.targets.?.len);
    const web = ws.member("acme-web").?;
    try testing.expectEqual(@as(usize, 2), web.manifest.targets.?.len);
    try testing.expectEqualStrings(FIX ++ "/workspace/modules/acme-web", web.dir);
    try testing.expect(web.manifest.dependencies[0].spec.workspace);
    // The example is a member like any other, and an application ships nothing by design.
    const app = ws.member("acme-app").?;
    try testing.expect(!isLibraryPackage(testing.io, app.manifest));
    try testing.expect(shipsNothing(testing.io, app.manifest) == null);
    // A library member with no `files` ships nothing.
    const empty = ws.member("acme-empty").?;
    try testing.expect(isLibraryPackage(testing.io, empty.manifest));
    const sn = shipsNothing(testing.io, empty.manifest).?;
    try testing.expectEqualStrings(
        \\error: ships nothing: manifest has no "files" — a workspace member that is a library lists every module a consumer may import
        \\ --> tests/fixtures/workspace/modules/acme-empty/botopink.json:2:3
        \\  |
        \\2 |   "name": "acme-empty",
        \\  |   ^^^^^^
        \\
        \\
    , try sn.renderAlloc(a));
    try testing.expect(shipsNothing(testing.io, core.manifest) == null);
}

test "parse: two entries of \"files\" naming one module are refused at the second (144 B-98)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try expectHead(try refuse(a,
        \\{ "name": "p", "files": ["root.bp", "root.bp"] }
    ), "error: \"files\" lists root.bp and root.bp, one module (`root`) written twice — keep one of the two files", "--> botopink.json:1:37");
    try expectHead(try refuse(a,
        \\{ "name": "p", "files": ["ui/Card.bpp", "ui/Card.bp"] }
    ), "error: \"files\" lists ui/Card.bpp and ui/Card.bp, one module (`ui/Card`) written twice — keep one of the two files", "--> botopink.json:1:41");
    // One stem per entry: a module and a folder module of other stems are two (`p.d.bp` is the module `p.d`).
    var err: ?Located = null;
    const m = try parse(a,
        \\{ "name": "p", "files": ["root.bp", "p.bp", "p.d.bp", "p/mod.bp"] }
    , "botopink.json", &err);
    try testing.expectEqual(@as(usize, 4), m.files.len);
}

/// The first two rendered lines: the message and the `--> file:line:col` location.
fn expectHead(out: []const u8, message: []const u8, location: []const u8) !void {
    var it = std.mem.splitScalar(u8, out, '\n');
    const l1 = it.next() orelse return error.TestExpectedHead;
    const l2 = it.next() orelse return error.TestExpectedHead;
    try testing.expectEqualStrings(message, l1);
    try testing.expectEqualStrings(location, std.mem.trimStart(u8, l2, " "));
}

/// Read + expand a fixture workspace expecting a refusal; returns the rendered error.
fn refuseWorkspace(a: std.mem.Allocator, dir: []const u8) ![]const u8 {
    var err: ?Located = null;
    const m = try read(a, testing.io, dir, &err);
    const r = expand(a, testing.io, m, &err);
    try testing.expectError(error.Invalid, r);
    return try err.?.renderAlloc(a);
}

test "expand: a member that is a workspace, a duplicate member name, a missing literal entry" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings(
        \\error: "inner" is a member of tests/fixtures/bad/nested-workspace/botopink.json and cannot itself be a workspace — workspaces do not nest
        \\ --> tests/fixtures/bad/nested-workspace/modules/inner/botopink.json:3:3
        \\  |
        \\3 |   "workspaces": ["sub/*"]
        \\  |   ^^^^^^^^^^^^
        \\
        \\
    , try refuseWorkspace(a, FIX ++ "/bad/nested-workspace"));
    try testing.expectEqualStrings(
        \\error: member name "dup" is declared twice in tests/fixtures/bad/duplicate-member/botopink.json: tests/fixtures/bad/duplicate-member/modules/a/botopink.json and tests/fixtures/bad/duplicate-member/modules/b/botopink.json
        \\ --> tests/fixtures/bad/duplicate-member/modules/b/botopink.json:1:3
        \\  |
        \\1 | { "name": "dup", "files": ["root.bp"] }
        \\  |   ^^^^^^
        \\
        \\
    , try refuseWorkspace(a, FIX ++ "/bad/duplicate-member"));
    try expectHead(
        try refuseWorkspace(a, FIX ++ "/bad/missing-literal"),
        "error: workspaces entry \"modules/ghost\": tests/fixtures/bad/missing-literal/modules/ghost/botopink.json does not exist — a literal entry names a directory holding a botopink.json",
        "--> tests/fixtures/bad/missing-literal/botopink.json:1:31",
    );
    const missing_dir = try refuseWorkspace(a, FIX ++ "/bad/missing-dir");
    try testing.expect(std.mem.indexOf(u8, missing_dir, "error: workspaces entry \"nope/*\": tests/fixtures/bad/missing-dir/nope is not a directory that can be read") != null);
}

test "parse: a workspace declares the dependencies its members share; { \"workspace\": true } there is refused (decision 512)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const m = try parseText(a,
        \\{ "name": "cells", "workspaces": ["*"], "dependencies": { "lib": { "path": "../lib" } } }
    );
    try testing.expect(m.isWorkspace());
    try testing.expectEqual(@as(usize, 1), m.dependencies.len);
    try testing.expectEqualStrings("../lib", m.dependencies[0].spec.path.?);
    try testing.expectEqualStrings(
        \\error: "lib": { "workspace": true } names a sibling member, and a workspace's dependencies are every member's — declare it in the members that use it
        \\ --> botopink.json:1:59
        \\  |
        \\1 | { "name": "cells", "workspaces": ["*"], "dependencies": { "lib": { "workspace": true } } }
        \\  |                                                           ^^^^^
        \\
        \\
    , try refuse(a,
        \\{ "name": "cells", "workspaces": ["*"], "dependencies": { "lib": { "workspace": true } } }
    ));
}

test "expand: a member inherits the workspace's dependencies, version and targets, and defaults its entry (decision 512)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var err: ?Located = null;
    const ws = try expand(a, io, try read(a, io, FIX ++ "/inherit", &err), &err);
    try testing.expectEqualStrings("a, b", try ws.memberList(a));

    // `a` writes its name alone: every dependency, the version and the
    // targets are the workspace's, the entry `main.bp`.
    const ma = ws.member("a").?.manifest;
    try testing.expectEqual(@as(usize, 2), ma.dependencies.len);
    try testing.expectEqualStrings("lib", ma.dependencies[0].name);
    try testing.expect(ma.dependencies[0].inherited);
    // The path is the workspace's, rewritten relative to the member.
    try testing.expectEqualStrings("../vendor/lib", ma.dependencies[0].spec.path.?);
    try testing.expectEqualStrings("https://e/remote.git", ma.dependencies[1].spec.git.?);
    try testing.expectEqualStrings("2.0.0", ma.version);
    try testing.expectEqualStrings("main.bp", ma.entry.?);
    try testing.expectEqual(@as(usize, 2), ma.targets.?.len);
    // A refusal about an inherited entry is located in the workspace's manifest.
    const loc = ma.locateEntryAt("dependencies", "lib", "m");
    try testing.expectEqualStrings(FIX ++ "/inherit/botopink.json", loc.file);
    try testing.expectEqual(@as(usize, 7), loc.line);

    // `b` adds its own dependency, keeps its version, restricts the targets,
    // and its "bpp" names a dependency it inherits.
    const mb = ws.member("b").?.manifest;
    try testing.expectEqual(@as(usize, 3), mb.dependencies.len);
    try testing.expectEqualStrings("extra", mb.dependencies[2].name);
    try testing.expect(!mb.dependencies[2].inherited);
    try testing.expectEqualStrings("1.0.0", mb.version);
    try testing.expectEqual(@as(usize, 1), mb.targets.?.len);
    try testing.expectEqualStrings("lib", mb.bpp.?);

    // An inherited `path` resolves where the workspace's manifest says.
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];
    const a_dir = try std.fs.path.join(a, &.{ cwd, FIX ++ "/inherit/a" });
    const lib = (try resolveDependency(a, io, ma, a_dir, ma.dependencies[0], &.{}, &err)).?;
    try testing.expectEqualStrings("lib", lib.manifest.name);
    try testing.expect(std.mem.endsWith(u8, lib.dir, "/inherit/vendor/lib"));
}

test "expand: a member redeclaring an inherited dependency is refused, located at its entry (decision 512)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    try testing.expectEqualStrings(
        \\error: "lib" is a dependency of the workspace (tests/fixtures/bad/inherit-redeclare/botopink.json), which every member inherits — delete this entry: a workspace has one source per dependency
        \\ --> tests/fixtures/bad/inherit-redeclare/x/botopink.json:3:21
        \\  |
        \\3 |   "dependencies": { "lib": { "path": "../vendor/lib" } }
        \\  |                     ^^^^^
        \\
        \\
    , try refuseWorkspace(arena_inst.allocator(), FIX ++ "/bad/inherit-redeclare"));
}

test "workspaceOf: the workspace whose globs list a directory, its members unread; a path dependency on a member inherits" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];
    var err: ?Located = null;
    const member = try std.fs.path.join(a, &.{ cwd, FIX ++ "/inherit/b" });
    try testing.expectEqualStrings("cells", (try workspaceOf(a, io, member, &err)).?.name);
    // `vendor/lib` sits under the workspace, but `*` lists the children only.
    const vendored = try std.fs.path.join(a, &.{ cwd, FIX ++ "/inherit/vendor/lib" });
    try testing.expect((try workspaceOf(a, io, vendored, &err)) == null);
    // Nor is it expanded for it: a workspace whose members refuse to expand
    // (a member redeclares an inherited dependency) is no error of a package
    // it does not list.
    const unlisted = try std.fs.path.join(a, &.{ cwd, FIX ++ "/bad/inherit-redeclare/vendor/lib" });
    try testing.expect((try enclosingWorkspace(a, io, unlisted, &err)) == null);

    // A package outside the workspace that depends on `a` by path reads `a`
    // with what it inherits.
    const outside = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/local" });
    const project = try parse(a, "{ \"name\": \"local\" }", "botopink.json", &err);
    const got = (try resolveDependency(a, io, project, outside, .{ .name = "a", .spec = .{ .path = "../../inherit/a" } }, &.{}, &err)).?;
    try testing.expectEqual(@as(usize, 2), got.manifest.dependencies.len);
    try testing.expectEqualStrings("2.0.0", got.manifest.version);
}

test "expand: a member may only restrict the workspace's targets" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    try expectHead(
        try refuseWorkspace(arena_inst.allocator(), FIX ++ "/bad/target-widen"),
        "error: \"erlang\" is not one of the workspace's targets [\"commonJS\"] (tests/fixtures/bad/target-widen/botopink.json) — a member may only restrict the workspace's targets",
        "--> tests/fixtures/bad/target-widen/modules/wide/botopink.json:1:43",
    );
}

/// `closureOtp` over manifests parsed from `texts`, each at its own path
/// (`pkg<i>/botopink.json`), expecting a refusal; returns the rendered error.
fn refuseClosureOtp(a: std.mem.Allocator, texts: []const []const u8) ![]const u8 {
    var ms = try a.alloc(Manifest, texts.len);
    for (texts, 0..) |t, i| {
        var err: ?Located = null;
        ms[i] = try parse(a, t, try std.fmt.allocPrint(a, "pkg{d}/botopink.json", .{i}), &err);
    }
    var err: ?Located = null;
    try testing.expectError(error.Invalid, closureOtp(a, ms, &err));
    return try err.?.renderAlloc(a);
}

test "parse: \"wasm\" names the host a wasm build binds to, absent meaning wasi (decision 334)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqual(WasmHost.wasi, (try parseText(a,
        \\{ "name": "app", "target": "wasm" }
    )).wasm_host);
    try testing.expectEqual(WasmHost.wasi, (try parseText(a,
        \\{ "name": "app", "target": "wasm", "wasm": { "host": "wasi" } }
    )).wasm_host);
    try testing.expectEqual(WasmHost.browser, (try parseText(a,
        \\{ "name": "app", "target": "wasm", "wasm": { "host": "browser" } }
    )).wasm_host);
}

test "parse: \"typings\" turns the .d.ts emission on, absent meaning off (decisions 619, 620)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expect(!(try parseText(a,
        \\{ "name": "app" }
    )).typings);
    try testing.expect((try parseText(a,
        \\{ "name": "app", "typings": true }
    )).typings);
    try testing.expectEqualStrings(
        \\error: "typings" must be true or false
        \\ --> botopink.json:1:18
        \\  |
        \\1 | { "name": "app", "typings": "yes" }
        \\  |                  ^^^^^^^^^
        \\
        \\
    , try refuse(a,
        \\{ "name": "app", "typings": "yes" }
    ));
}

test "parse: a \"wasm\" that names no known host, or anything beside it, is a located error (decision 334)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings(
        \\error: "wasm": "host" names "deno" — a wasm build runs on "wasi" (wasmtime, WASI preview 2) or "browser" (JS imports, JSPI)
        \\ --> botopink.json:1:36
        \\  |
        \\1 | { "name": "app", "wasm": { "host": "deno" } }
        \\  |                                    ^^^^^^
        \\
        \\
    , try refuse(a,
        \\{ "name": "app", "wasm": { "host": "deno" } }
    ));
    try expectHead(try refuse(a,
        \\{ "name": "app", "wasm": "wasi" }
    ), "error: \"wasm\" must be an object — { \"host\": \"wasi\" | \"browser\" }", "--> botopink.json:1:18");
    try expectHead(try refuse(a,
        \\{ "name": "app", "wasm": {} }
    ), "error: \"wasm\" names no \"host\" — write { \"host\": \"wasi\" | \"browser\" }, or omit \"wasm\" for the default \"wasi\"", "--> botopink.json:1:18");
    try expectHead(try refuse(a,
        \\{ "name": "app", "wasm": { "host": 1 } }
    ), "error: \"wasm\": \"host\" must be a string — \"wasi\" or \"browser\"", "--> botopink.json:1:28");
    try expectHead(try refuse(a,
        \\{ "name": "app", "wasm": { "host": "wasi", "jspi": true } }
    ), "error: \"wasm\" has no field \"jspi\" — its one field is \"host\": { \"host\": \"wasi\" | \"browser\" }", "--> botopink.json:1:44");
}

test "parse: \"bpp\" is one package name, a dependency (decision 361)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings("jhonstart", (try parseText(a,
        \\{ "name": "app", "dependencies": { "jhonstart": { "path": "../jhonstart" } }, "bpp": "jhonstart" }
    )).bpp.?);
    try testing.expectEqual(@as(?[]const u8, null), (try parseText(a,
        \\{ "name": "app" }
    )).bpp);
}

test "parse: the object form of \"bpp\", a non-string and a name that is no dependency are located errors (decision 361)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings(
        \\error: "bpp" is a package name — write "bpp": "jhonstart"
        \\ --> botopink.json:1:71
        \\  |
        \\1 | { "name": "app", "dependencies": { "jhonstart": { "path": "../j" } }, "bpp": { "default": "jhonstart" } }
        \\  |                                                                       ^^^^^
        \\
        \\
    , try refuse(a,
        \\{ "name": "app", "dependencies": { "jhonstart": { "path": "../j" } }, "bpp": { "default": "jhonstart" } }
    ));
    try expectHead(try refuse(a,
        \\{ "name": "app", "bpp": ["jhonstart"] }
    ), "error: \"bpp\" is a package name — write \"bpp\": \"jhonstart\"", "--> botopink.json:1:18");
    try expectHead(try refuse(a,
        \\{ "name": "app", "dependencies": { "jhonstart": { "path": "../j" } }, "bpp": "jhonstrat" }
    ), "error: \"bpp\" names \"jhonstrat\", which is not a dependency — the package that unfolds .bpp files is an entry of \"dependencies\"", "--> botopink.json:1:78");
    try expectHead(try refuse(a,
        \\{ "name": "w", "workspaces": ["m/*"], "bpp": "jhonstart" }
    ), "error: a workspace manifest cannot carry \"bpp\" — a workspace declares members, it is not a package; move \"bpp\" to the member's own botopink.json", "--> botopink.json:1:39");
}

test "otp: a release the compiler does not emit for is refused, located at the value (decision 228)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings("28", OTP_RELEASE);
    try testing.expectEqualStrings(
        \\error: botopink emits Erlang for OTP 28; "otp" names 26
        \\ --> pkg0/botopink.json:1:27
        \\  |
        \\1 | { "name": "rakun", "otp": "26" }
        \\  |                           ^^^^
        \\
        \\
    , try refuseClosureOtp(a, &.{
        \\{ "name": "rakun", "otp": "26" }
    }));
    // Not a string: the shape every string field is held to.
    try expectHead(try refuse(a,
        \\{ "name": "rakun", "otp": 28 }
    ), "error: \"otp\" must be a string", "--> botopink.json:1:20");
}

test "otp: a closure whose packages pin two releases is refused, naming both manifests (decision 228)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings(
        \\error: "otp" names 29 here, but 28 in pkg0/botopink.json — every package of a build pins one OTP release
        \\ --> pkg2/botopink.json:1:25
        \\  |
        \\1 | { "name": "dep", "otp": "29" }
        \\  |                         ^^^^
        \\
        \\
    , try refuseClosureOtp(a, &.{
        \\{ "name": "rakun", "otp": "28" }
        ,
        \\{ "name": "quiet" }
        ,
        \\{ "name": "dep", "otp": "29" }
    }));
    // A closure that agrees answers its pin; one where nobody pins answers null.
    var err: ?Located = null;
    const agree = [_]Manifest{ try parseText(a, "{ \"name\": \"a\", \"otp\": \"28\" }"), try parseText(a, "{ \"name\": \"b\" }"), try parseText(a, "{ \"name\": \"c\", \"otp\": \"28\" }") };
    try testing.expectEqualStrings("28", (try closureOtp(a, &agree, &err)).?.release);
    const none = [_]Manifest{ try parseText(a, "{ \"name\": \"a\" }"), try parseText(a, "{ \"name\": \"b\" }") };
    try testing.expect((try closureOtp(a, &none, &err)) == null);
}

test "expand: a member inherits the workspace's otp, and may not name another" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var err: ?Located = null;
    const ws = try expand(a, testing.io, try read(a, testing.io, FIX ++ "/otp", &err), &err);
    const plain = ws.member("plain").?.manifest.otp.?;
    try testing.expectEqualStrings("28", plain.release);
    // The inherited pin still points at the line that says it.
    try testing.expectEqualStrings(FIX ++ "/otp/botopink.json", plain.path);
    try testing.expectEqualStrings(FIX ++ "/otp/modules/same/botopink.json", ws.member("same").?.manifest.otp.?.path);
    try expectHead(
        try refuseWorkspace(a, FIX ++ "/bad/otp-member"),
        "error: \"otp\" names 29 here, but 28 in tests/fixtures/bad/otp-member/botopink.json — every package of a build pins one OTP release",
        "--> tests/fixtures/bad/otp-member/modules/other/botopink.json:1:27",
    );
}

test "expand: a path to a sibling member, a path to the workspace, an unknown workspace dependency, a self dependency" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try expectHead(
        try refuseWorkspace(a, FIX ++ "/bad/sibling-path"),
        "error: \"core\": path \"../core\" points at the sibling member \"core\" — use { \"workspace\": true }",
        "--> tests/fixtures/bad/sibling-path/modules/web/botopink.json:2:21",
    );
    const to_ws = try refuseWorkspace(a, FIX ++ "/bad/workspace-path");
    try testing.expect(std.mem.indexOf(u8, to_ws, "error: \"umbrella\": path \"../../\" points at the workspace itself — a workspace is not a package; depend on one of its members with { \"workspace\": true } (members: web)") != null);
    try expectHead(
        try refuseWorkspace(a, FIX ++ "/bad/workspace-dep-missing"),
        "error: \"ghost\": { \"workspace\": true } names no member of tests/fixtures/bad/workspace-dep-missing/botopink.json (members: web)",
        "--> tests/fixtures/bad/workspace-dep-missing/modules/web/botopink.json:2:21",
    );
    const self_dep = try refuseWorkspace(a, FIX ++ "/bad/self-dep");
    try testing.expect(std.mem.indexOf(u8, self_dep, "error: \"web\" cannot depend on itself") != null);
}

test "scanRoots: a root's workspace child contributes its members; a plain package keeps its directory name" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{FIX ++ "/roots/repository"};
    const entries = try scanRoots(a, testing.io, &roots);
    // `plain` (a package dir), the `workspace` umbrella and its four members.
    try testing.expectEqual(@as(usize, 6), entries.len);
    try testing.expect(find(entries, "plain") != null);
    try testing.expect(find(entries, "plain").?.workspace == null);
    const umbrella = find(entries, "workspace").?;
    try testing.expect(umbrella.is_workspace);
    try testing.expect(umbrella.problem == null);
    const web = find(entries, "acme-web").?;
    try testing.expect(web.workspace != null);
    try testing.expectEqualStrings(FIX ++ "/roots/repository/workspace/modules/acme-web", web.dir);
    try testing.expect(find(entries, "acme-app") != null);
    try testing.expect(find(entries, "nomanifest") == null);
}

test "scanRoots: a symbolic link to a package directory is a child like a directory (the `bpmp install` store)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    // `deps/side` links to `../packages/side`; `deps/not-a-dir` links to a file.
    const roots = [_][]const u8{FIX ++ "/symlinked-store/deps"};
    const entries = try scanRoots(a, testing.io, &roots);
    try testing.expectEqual(@as(usize, 1), entries.len);
    const side = find(entries, "side").?;
    try testing.expectEqualStrings(FIX ++ "/symlinked-store/deps/side", side.dir);
    try testing.expect(side.problem == null);
}

test "scanRoots: a root that is itself a workspace contributes its members, and a directory reached twice is one entry" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{ FIX ++ "/roots/repository/workspace", FIX ++ "/roots/repository" };
    const entries = try scanRoots(a, testing.io, &roots);
    try testing.expectEqual(@as(usize, 6), entries.len);
    try testing.expect(find(entries, "acme").?.problem == null);
}

test "scanRoots: two members with one name across roots are both a located problem; a broken sibling marks only itself" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{ FIX ++ "/roots/repository", FIX ++ "/roots/other" };
    const entries = try scanRoots(a, testing.io, &roots);
    // `other/` holds a second workspace declaring `acme-web` again, and a
    // package whose manifest still uses the array form.
    var count: usize = 0;
    for (entries) |e| {
        if (std.mem.eql(u8, e.name, "acme-web")) {
            count += 1;
            const text = try e.problem.?.renderAlloc(a);
            try testing.expect(std.mem.indexOf(u8, text, "error: \"acme-web\" is declared by two libraries: tests/fixtures/roots/repository/workspace/modules/acme-web and tests/fixtures/roots/other/second/modules/acme-web") != null);
        }
    }
    try testing.expectEqual(@as(usize, 2), count);
    try testing.expect(find(entries, "acme").?.problem == null);
    const broken = find(entries, "array-deps").?;
    try testing.expect(broken.manifest == null);
    try testing.expect(std.mem.indexOf(u8, broken.problem.?.message, "must be an object, not an array") != null);
    // Two plain packages named `plain`: the first root wins, the second is dropped.
    var plain_count: usize = 0;
    for (entries) |e| if (std.mem.eql(u8, e.name, "plain")) {
        plain_count += 1;
    };
    try testing.expectEqual(@as(usize, 1), plain_count);
    try testing.expectEqualStrings(FIX ++ "/roots/repository/plain", find(entries, "plain").?.dir);
}

test "scanRoots + find: a core member named like its umbrella's directory is the library, the umbrella is not" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roots = [_][]const u8{FIX ++ "/roots/named"};
    const entries = try scanRoots(a, testing.io, &roots);
    const core = find(entries, "rakun").?;
    try testing.expect(!core.is_workspace);
    try testing.expect(core.workspace != null);
    try testing.expect(core.problem == null);
    try testing.expectEqualStrings(FIX ++ "/roots/named/rakun/modules/rakun", core.dir);
    // A workspace with no member of its name still answers, as the umbrella.
    try testing.expect(find(entries, "workspace") == null);
    const second_roots = [_][]const u8{FIX ++ "/roots/other"};
    const second = try scanRoots(a, testing.io, &second_roots);
    try testing.expect(find(second, "second").?.is_workspace);
}

test "resolveDependency: workspace, path, git-by-name, a workspace by name, a member by path" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const cwd = cwd_buf[0..cwd_n];

    const roots = [_][]const u8{FIX ++ "/roots/repository"};
    const entries = try scanRoots(a, io, &roots);

    // `acme-web` depends on `acme` with { "workspace": true }.
    const web_dir = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/repository/workspace/modules/acme-web" });
    var err: ?Located = null;
    const web = try read(a, io, web_dir, &err);
    const core = (try resolveDependency(a, io, web, web_dir, web.dependencies[0], &.{entries}, &err)).?;
    try testing.expectEqualStrings("acme", core.manifest.name);
    try testing.expect(std.mem.endsWith(u8, core.dir, "/modules/acme"));

    // `plain` depends on `acme-web` by name (git form) and on `local` by path.
    const plain_dir = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/repository/plain" });
    const plain = try read(a, io, plain_dir, &err);
    const by_name = (try resolveDependency(a, io, plain, plain_dir, plain.dependencies[0], &.{entries}, &err)).?;
    try testing.expectEqualStrings("acme-web", by_name.manifest.name);
    const by_path = (try resolveDependency(a, io, plain, plain_dir, plain.dependencies[1], &.{entries}, &err)).?;
    try testing.expectEqualStrings("local", by_path.manifest.name);
    try testing.expect(std.mem.endsWith(u8, by_path.dir, "/roots/local"));
    // A name nothing carries is null (the caller words "not found").
    try testing.expect((try resolveDependency(a, io, plain, plain_dir, .{ .name = "absent", .spec = .{ .git = "https://e/a.git" } }, &.{entries}, &err)) == null);

    // The workspace by name, with its members listed.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "workspace", .spec = .{ .git = "https://e/w.git" } }, &.{entries}, &err));
    try testing.expectEqualStrings("\"workspace\" is a workspace, not a package — import one of its members: acme, acme-empty, acme-web, acme-app", err.?.message);

    // A member depending on a sibling by path (the workspace rule, at resolution time).
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, web, web_dir, .{ .name = "acme", .spec = .{ .path = "../acme" } }, &.{entries}, &err));
    try testing.expectEqualStrings("\"acme\": path \"../acme\" points at the sibling member \"acme\" — use { \"workspace\": true }", err.?.message);

    // { "workspace": true } outside any workspace.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "acme", .spec = .{ .workspace = true } }, &.{entries}, &err));
    try testing.expect(std.mem.startsWith(u8, err.?.message, "\"acme\": { \"workspace\": true } but "));
    try testing.expect(std.mem.indexOf(u8, err.?.message, "is not a member of any workspace") != null);

    // A path that holds no manifest, and a path whose package has another name.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "x", .spec = .{ .path = "../nowhere" } }, &.{entries}, &err));
    try testing.expect(std.mem.startsWith(u8, err.?.message, "\"x\": path \"../nowhere\" holds no botopink.json"));
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "other", .spec = .{ .path = "../../local" } }, &.{entries}, &err));
    try testing.expectEqualStrings("\"other\": path \"../../local\" holds a package named \"local\" — the dependency key is the import name and must match", err.?.message);
    // A path to a workspace.
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, .{ .name = "ws", .spec = .{ .path = "../workspace" } }, &.{entries}, &err));
    try testing.expectEqualStrings("\"ws\": path \"../workspace\" is a workspace, not a package — depend on one of its members: acme, acme-empty, acme-web, acme-app", err.?.message);
}

test "resolveDependency: a git dependency answers from the first tier that carries it (decision 483)" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];
    const plain_dir = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/repository/plain" });
    var err: ?Located = null;
    const plain = try read(a, io, plain_dir, &err);
    const acme_web: DepEntry = plain.dependencies[0];

    // `acme-web` is a member of `roots/other/second` and of
    // `roots/repository/workspace`. Scanned as one tier they are "declared by
    // two libraries"; as two tiers the first one carries it.
    const other = try scanRoots(a, io, &.{FIX ++ "/roots/other"});
    const repo = try scanRoots(a, io, &.{FIX ++ "/roots/repository"});
    const first = (try resolveDependency(a, io, plain, plain_dir, acme_web, &.{ other, repo }, &err)).?;
    try testing.expectEqualStrings(FIX ++ "/roots/other/second/modules/acme-web", first.dir);
    const swapped = (try resolveDependency(a, io, plain, plain_dir, acme_web, &.{ repo, other }, &err)).?;
    try testing.expectEqualStrings(FIX ++ "/roots/repository/workspace/modules/acme-web", swapped.dir);
    // A tier that does not carry the name passes it on; no tier is null.
    const store = try scanRoots(a, io, &.{FIX ++ "/symlinked-store/deps"});
    const passed = (try resolveDependency(a, io, plain, plain_dir, acme_web, &.{ store, repo }, &err)).?;
    try testing.expectEqualStrings(FIX ++ "/roots/repository/workspace/modules/acme-web", passed.dir);
    try testing.expect((try resolveDependency(a, io, plain, plain_dir, acme_web, &.{store}, &err)) == null);
    try testing.expect((try resolveDependency(a, io, plain, plain_dir, acme_web, &.{}, &err)) == null);
    // One tier holding both is the refusal it always was.
    const joint = try scanRoots(a, io, &.{ FIX ++ "/roots/other", FIX ++ "/roots/repository" });
    err = null;
    try testing.expectError(error.Invalid, resolveDependency(a, io, plain, plain_dir, acme_web, &.{joint}, &err));
    try testing.expect(std.mem.indexOf(u8, err.?.message, "is declared by two libraries") != null);
}

test "depsRoots: a package's own links; a workspace member's, then its workspace root's" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];

    const outside = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/local" });
    const own = try depsRoots(a, io, outside);
    try testing.expectEqual(@as(usize, 1), own.len);
    try testing.expectEqualStrings(try std.fs.path.join(a, &.{ outside, DEPS_DIR }), own[0]);

    const member = try std.fs.path.join(a, &.{ cwd, FIX ++ "/workspace/examples/acme-app" });
    const both = try depsRoots(a, io, member);
    try testing.expectEqual(@as(usize, 2), both.len);
    try testing.expectEqualStrings(try std.fs.path.join(a, &.{ member, DEPS_DIR }), both[0]);
    try testing.expect(std.mem.endsWith(u8, both[1], FIX ++ "/workspace/" ++ DEPS_DIR));
}

test "enclosingWorkspace: a member finds its workspace; a package outside finds none; isWorkspaceDir probes" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const cwd = cwd_buf[0..cwd_n];
    var err: ?Located = null;
    const member = try std.fs.path.join(a, &.{ cwd, FIX ++ "/workspace/examples/acme-app" });
    const ws = (try enclosingWorkspace(a, io, member, &err)).?;
    try testing.expectEqualStrings("acme", ws.manifest.name);
    const outside = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/local" });
    try testing.expect((try enclosingWorkspace(a, io, outside, &err)) == null);
    try testing.expect(isWorkspaceDir(io, FIX ++ "/workspace"));
    try testing.expect(!isWorkspaceDir(io, FIX ++ "/roots/local"));
    try testing.expect(!isWorkspaceDir(io, FIX ++ "/nowhere"));
}

test "findCacheRoot: a member's caches live under its workspace, a package's under itself" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd_n = try std.process.currentPath(io, &cwd_buf);
    const cwd = cwd_buf[0..cwd_n];
    var err: ?Located = null;
    const member = try std.fs.path.join(a, &.{ cwd, FIX ++ "/workspace/examples/acme-app" });
    const ws_root = try findCacheRoot(a, io, member, &err);
    try testing.expect(std.mem.endsWith(u8, ws_root, FIX ++ "/workspace"));
    try testing.expect(std.mem.endsWith(u8, try cacheDir(a, ws_root, "lsp"), FIX ++ "/workspace/.botopinkbuild/cache/lsp"));
    const outside = try std.fs.path.join(a, &.{ cwd, FIX ++ "/roots/local" });
    try testing.expectEqualStrings(outside, try findCacheRoot(a, io, outside, &err));
}

test "Located.render: the CLI diagnostic shape, width-aware" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const l: Located = .{ .message = "m", .file = "f.json", .source = "a\nb\nc\nd\ne\nf\ng\nh\ni\nj\n{ \"x\": 1 }", .line = 11, .col = 3, .span = 3 };
    try testing.expectEqualStrings(
        \\error: m
        \\  --> f.json:11:3
        \\   |
        \\11 | { "x": 1 }
        \\   |   ^^^
        \\
        \\
    , try l.renderAlloc(arena_inst.allocator()));
}
