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

/// One method a record/enum export declares, with the arity its lowering takes
/// (the receiver included, as `m.params.len` counts it). The arity is half the
/// identity of a method on the erlang backend: two types may share a name and
/// the `name/arity` pair is what a call site can be matched against, exactly as
/// the local `method_owners` index is keyed.
pub const MethodSig = struct {
    name: []const u8,
    arity: usize,
};

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
    /// The methods a record/enum export declares, name and arity (empty
    /// otherwise). A consumer calling one on an imported value
    /// (`stub.thenReturn(v)`) emits no local definition of it: erlang resolves
    /// the owning module from here — and, when two types of the program declare
    /// the same `name/arity`, resolves nothing and dispatches on the value.
    methods: []const MethodSig = &.{},
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
    /// A `.@"fn"` export's arity — the other half of its identity, and the half
    /// this index used to throw away. `MethodSig` carries it for a method
    /// because two types may declare one method name; two MODULES may declare
    /// one function name for exactly the same reason, and `parse/1` from
    /// `json` is not `parse/2` from `url`. 0 for every other kind (a record, an
    /// enum and a `val` are identified by their name alone, which is why a
    /// collision on one of those can only be refused).
    arity: usize = 0,
};

/// What a name resolves to for one consumer, counted over the PROGRAM.
///
/// The index is keyed by the bare symbol NAME, and a name is unique inside a
/// module, never over a program — `libs/std` declares `parse` in `json`, in
/// `querystring` and in `url` today. `exports` answered with a plain `get`, so
/// the winner was whichever module the `outputs` walk reached last, with no
/// dissent check and no diagnostic. This is that question asked properly: the
/// module the import NAMES answers first, then the arity the CALL takes, and
/// when neither tells the candidates apart the caller is handed the contest
/// instead of a guess.
pub const Pick = union(enum) {
    /// No `pub` declaration of that name anywhere in the program.
    none,
    /// Exactly one declaration answers.
    one: ExportInfo,
    /// Several answer and nothing in the question separates them.
    contested: Contested,
};

/// Two of the modules that declare one exported name, for the diagnostic. Two
/// is enough to name the defect; listing every one of them would not help a
/// reader fix it.
pub const Contested = struct {
    name: []const u8,
    a: []const u8,
    b: []const u8,

    /// This as the message of a `moduleOutput.Diagnostic.type`, so an ambiguous
    /// import fails the module that wrote it — the shape `AtomFault` uses, and
    /// for the same reason: the alternative is one module silently winning.
    pub fn message(self: Contested, alloc: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(
            alloc,
            "`{s}` is declared `pub` by `{s}` and by `{s}`, and this import does not say which — name the module it comes from (`from \"{s}\"`), or rename one of the two",
            .{ self.name, self.a, self.b, self.a },
        );
    }
};

/// Cross-module link info, built once over every module's transformed program.
/// `exports` maps a `pub` symbol name → its emitting module + shape; `imported`
/// is the set of names some module imports (so an owner only emits an export
/// for symbols actually consumed elsewhere — single-module programs stay
/// unchanged).
pub const CrossModule = struct {
    exports: std.StringHashMap(ExportInfo),
    /// EVERY `pub` declaration of a name, in walk order — the population
    /// `exports` collapses to one entry. `pick` counts dissent over this, the
    /// way `methodOwnerContested` counts a method's owners and
    /// `uniqueRecordWithField` counts a field's.
    owners: std.StringHashMap([]const ExportInfo),
    /// Consumer module path → the ambiguous import it wrote. Keyed by the
    /// module that must FAIL, exactly as `atom_faults` is: a name two modules
    /// export is only a defect where some third module reaches for it without
    /// saying which, and refusing the declarations themselves would refuse
    /// `libs/std`, whose `json`, `querystring` and `url` all declare `parse`.
    export_faults: std.StringHashMap(Contested),
    imported: std.StringHashMap(void),
    /// Every module path in the program → its rendered Erlang/BEAM module atom
    /// (`"std/math"` → `"std@math"`). Rendered once, in `build`, so every
    /// emitter reads one spelling of the atom and the values outlive the
    /// per-module emitters that store them in their own tables.
    atoms: std.StringHashMap([]u8),
    /// Module paths whose atom cannot be used — two paths rendering the same
    /// atom, a package name that cannot start an atom, or over
    /// `ATOM_MAX_BYTES`. Keyed by path, so the
    /// erlang and BEAM backends can fail exactly the modules involved with a
    /// diagnostic instead of letting one silently overwrite the other.
    atom_faults: std.StringHashMap(AtomFault),
    /// The type atoms a `duplicate_decl`/`too_long` fault quotes — rendered for
    /// the check and owned here, since no module table holds them.
    fault_atoms: std.ArrayListUnmanaged([]u8) = .empty,
    /// Owns the `fields` arrays allocated for record/struct exports.
    field_arrays: std.ArrayListUnmanaged([]const []const u8) = .empty,
    /// Owns the `methods` arrays allocated for record/enum exports.
    method_arrays: std.ArrayListUnmanaged([]const MethodSig) = .empty,
    /// Owns the per-name declaration lists `owners` hands out.
    owner_arrays: std.ArrayListUnmanaged([]const ExportInfo) = .empty,
    /// Which package owns each module path (decision 109) — every atom an
    /// emitter renders for a path goes through `idOf`.
    packages: Packages = .{},
    alloc: std.mem.Allocator,

    pub fn deinit(self: *CrossModule) void {
        for (self.field_arrays.items) |arr| self.alloc.free(arr);
        self.field_arrays.deinit(self.alloc);
        for (self.method_arrays.items) |arr| self.alloc.free(arr);
        self.method_arrays.deinit(self.alloc);
        for (self.owner_arrays.items) |arr| self.alloc.free(arr);
        self.owner_arrays.deinit(self.alloc);
        self.owners.deinit();
        self.export_faults.deinit();
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

    /// The identity of module `path` in this compilation — its package and
    /// path, for a renderer (`typeAtom`, `variantAtom`) to start the atom with.
    pub fn idOf(self: *const CrossModule, path: []const u8) ModuleId {
        return self.packages.idOf(path);
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

    /// The ambiguous import that fails module `path`, or null. Backend-
    /// independent — the collapse is in this index, not in any one emitter —
    /// so every backend's driver reports it.
    pub fn exportFault(self: *const CrossModule, path: []const u8) ?Contested {
        return self.export_faults.get(path);
    }

    /// Which declaration of `name` a consumer means.
    ///
    /// `source` is the import's own `from "<mod>"` (null where the caller has
    /// none in hand) and `arity` the argument count of the call (null at an
    /// import site, which binds a name and not a call). Both are narrowing
    /// questions and neither is a tie-breaker of last resort: when they leave
    /// two declarations standing the answer is `.contested`, never the first
    /// one. Decision 67 — refuse rather than guess.
    pub fn pick(
        self: *const CrossModule,
        name: []const u8,
        source: ?ast.ImportSource,
        arity: ?usize,
    ) Pick {
        const list = self.owners.get(name) orelse return .none;
        if (list.len == 0) return .none;
        if (list.len == 1) return .{ .one = list[0] };

        // The module the import NAMES. A module cannot declare one name twice,
        // so a source that names a module narrows to at most one — unless it is
        // a PACKAGE handle that happens to name several, which narrows nothing.
        var named_n: usize = 0;
        var named_hit: ExportInfo = undefined;
        if (source) |src| for (list) |e| {
            if (!src.namesModule(e.module)) continue;
            named_n += 1;
            named_hit = e;
        };
        if (named_n == 1) return .{ .one = named_hit };

        // The arity the CALL takes. This is `MethodSig`'s widening (`51a27b97`)
        // on the plain-`fn` axis: `parse/1` and `parse/2` are two functions and
        // a call site that passes one argument means the first.
        if (arity) |want| {
            var ar_n: usize = 0;
            var ar_hit: ExportInfo = undefined;
            for (list) |e| {
                if (named_n > 1 and !source.?.namesModule(e.module)) continue;
                if (e.kind != .@"fn" or e.arity != want) continue;
                ar_n += 1;
                ar_hit = e;
            }
            if (ar_n == 1) return .{ .one = ar_hit };
        }

        // Two of the candidates still standing, for the message.
        var a: ?ExportInfo = null;
        for (list) |e| {
            if (named_n > 1 and !source.?.namesModule(e.module)) continue;
            if (a == null) {
                a = e;
                continue;
            }
            return .{ .contested = .{ .name = name, .a = a.?.module, .b = e.module } };
        }
        return .{ .contested = .{ .name = name, .a = list[0].module, .b = list[1].module } };
    }

    /// `pick` for a caller that only wants the answer when there IS one — a
    /// lowering with a dynamic fallback, which asks the value instead of the
    /// name. A contest answers null, exactly as a missing export does.
    pub fn picked(
        self: *const CrossModule,
        name: []const u8,
        source: ?ast.ImportSource,
        arity: ?usize,
    ) ?ExportInfo {
        return switch (self.pick(name, source, arity)) {
            .one => |info| info,
            .none, .contested => null,
        };
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
/// `models/user`) and the PACKAGE that owns it — the `name` of the
/// `botopink.json` it was loaded under (decision 109). Every atom renderer
/// takes one, so a caller cannot pass a basename where a path is meant.
pub const ModuleId = struct {
    /// The module path the compiler knows the module by — for a dependency
    /// already `<dep>/<stem>`, which is how `from "<dep>"` resolves.
    path: []const u8,
    /// The owning package. Empty is NO package — a module compiled outside
    /// any `botopink.json` — and renders no atom (`error.MissingPackage`).
    package: []const u8 = "",
    /// Whether `path` already starts with `<package>/` — true for a
    /// dependency's module, false for the root package's.
    package_in_path: bool = false,

    /// A module of no package yet — an atom renderer refuses it until the
    /// package is known (`Packages.idOf`, `inPackage`).
    pub fn of(path: []const u8) ModuleId {
        return .{ .path = path };
    }

    /// Module `path` of the root package `package`.
    pub fn inPackage(package: []const u8, path: []const u8) ModuleId {
        return .{ .path = path, .package = package };
    }
};

/// The compiler's own namespace: the comptime evaluators put their modules
/// there (`bp@comptime__tpl__…`). A `botopink.json` may not take this name
/// (`manifest` refuses it), so no package's atoms can meet those.
pub const COMPILER_PACKAGE = "bp";

/// The implicit manifest of the compiler's own tests (decision 109): the
/// codegen snapshot harness compiles as package `test` — `test@main@@Foo` —
/// because a user's erlang/BEAM compilation without a `botopink.json` is
/// refused. Only the harness supplies it; a CLI run reads the real manifest.
pub const TEST_PACKAGE = "test";

/// The packages the compiler's tests compile under — `TEST_PACKAGE` as the
/// root, `std` embedded as always.
pub const test_packages: Packages = .{ .root = TEST_PACKAGE };

/// The library the compiler embeds: its modules reach every compilation as
/// `std/<stem>` without being listed as a dependency, so it is one whether or
/// not the driver names it.
pub const EMBEDDED_PACKAGE = "std";

/// Which package owns each module path of one compilation (decision 109): the
/// root package, whose modules have bare paths (`main`, `models/user`), and
/// the dependencies, whose modules the loader names `<dep>/<stem>`. Set by
/// the driver from `botopink.json`; the default is a compilation with no
/// manifest, whose root modules render no atom (`error.MissingPackage`) —
/// refused on erlang and BEAM, never given a fallback name.
pub const Packages = struct {
    /// The root package's `name`; empty is no manifest.
    root: []const u8 = "",
    /// Every dependency package whose modules are in the compilation.
    /// `EMBEDDED_PACKAGE` is one whether or not it is listed.
    deps: []const []const u8 = &.{},

    /// The identity of module `path`: a dependency's when its first segment
    /// names one (the root package being the embedded library itself is the
    /// exception), the root package's otherwise.
    pub fn idOf(self: Packages, path: []const u8) ModuleId {
        if (std.mem.indexOfScalar(u8, path, '/')) |slash| {
            const head = path[0..slash];
            if (self.isDep(head)) return .{ .path = path, .package = head, .package_in_path = true };
        }
        return .{ .path = path, .package = self.root };
    }

    fn isDep(self: Packages, name: []const u8) bool {
        if (std.mem.eql(u8, name, self.root)) return false;
        if (std.mem.eql(u8, name, EMBEDDED_PACKAGE)) return true;
        for (self.deps) |d| if (std.mem.eql(u8, d, name)) return true;
        return false;
    }
};

/// Which comptime producer a module came from — the `__<kind>__` qualifier of
/// a module the comptime evaluators build (`bp@comptime__tpl__<decl>__<hash>`).
/// A kind is never a free string: the segment is this enum's own tag name.
/// A `type` or an `implement` block is not a kind: decision 109 names its
/// module `<path>@@<Decl>` (`declAtom`), one rule for every declaration.
pub const Kind = enum {
    /// a template body evaluated at compile time.
    tpl,
    /// a decorator body evaluated at compile time.
    dec,

    pub fn tag(self: Kind) []const u8 {
        return @tagName(self);
    }
};

/// The comptime qualifier separator (`bp@comptime__tpl__html__<hash>`), and
/// the reason a run of `_` collapses to one in `erlAtom`: that suffix has to be
/// decodable, so `__` may not occur inside the path half of an atom. It is
/// OTP's own convention for the same purpose — `escript` names its synthesised
/// module `<script>__escript__<pid parts>`.
pub const QUALIFIER_SEP = "__";

/// Decision 109: the boundary between a module's atom and the declaration it
/// holds — `main@@SourceLocation`, `io@fs@@File`. A path segment is never
/// empty, so `@@` never occurs in `erlAtom`; and no source character maps to
/// `@`, so no declaration name can produce it either. That is why the decoder
/// is `split("@@")` with no qualifier table, and why the declaration half can
/// keep its case.
pub const DECL_SEP = "@@";

/// The practical cap on a module atom is the FILENAME, not the 255-byte atom
/// limit: `erlc` stages its output through `<atom>.bea#`, five bytes more than
/// the atom, inside a 255-byte `NAME_MAX`. Measured on OTP 29: a 250-byte atom
/// compiles, a 251-byte one fails.
pub const ATOM_MAX_BYTES = 250;

pub const AtomError = error{
    /// A module path, or a path whose every character sanitised away, cannot
    /// name a module.
    EmptyModulePath,
    /// A module of no package — compiled outside any `botopink.json`. The
    /// atom starts with the package, and there is no fallback name
    /// (decision 109): the erlang and BEAM drivers refuse the module.
    MissingPackage,
    /// A package name that does not start with a lowercase letter once
    /// sanitised: the atom starts with it, and an atom that does not start
    /// with `[a-z]` must be quoted. Refused rather than quoted (decision 67);
    /// `manifest` refuses such a `name` before it gets here.
    InvalidPackageName,
    /// A declaration whose name sanitised away cannot qualify an atom.
    EmptyDeclName,
    /// An atom that is neither `<package>@<path>`,
    /// `<package>@<path>@@<Decl>[__v__<variant>]` nor a comptime
    /// `<package>@<path>__<kind>__<decl>__<hash>` was not produced here.
    UndecodableAtom,
};

/// Option A, amended by decision 109: the owning package and the module path
/// as one legal unquoted erlang atom —
///
///     atom(module) = package ++ "@" ++ path, then
///     1. lowercase
///     2. '/' → '@'
///     3. every character outside [a-z0-9_@] → '_'
///     3b. collapse a run of two or more '_' to a single '_' (so `__` is free
///         for the comptime qualifier and the atom decodes)
///
/// `main` of package `myapp` is `myapp@main`, `std/math` (a dependency's
/// path already carries its package) is `std@math`, and a module of no
/// package is `error.MissingPackage`. Every atom holds an `@`, so none can be an OTP
/// module's name (`math`, `lists`) and none can shadow one; two libraries'
/// same-named modules differ by the package. The package must start with a
/// lowercase letter (`InvalidPackageName`). Caller owns the result.
pub fn erlAtom(alloc: std.mem.Allocator, id: ModuleId) (std.mem.Allocator.Error || AtomError)![]u8 {
    if (id.path.len == 0) return error.EmptyModulePath;
    if (id.package.len == 0) return error.MissingPackage;
    const package = id.package;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    if (!id.package_in_path) {
        try appendSanitised(alloc, &out, package);
        if (out.items.len == 0 or !(out.items[0] >= 'a' and out.items[0] <= 'z')) return error.InvalidPackageName;
        try out.append(alloc, '@');
    }
    const before = out.items.len;
    try appendSanitised(alloc, &out, id.path);
    if (out.items.len == before) return error.EmptyModulePath;
    if (id.package_in_path and !(out.items[0] >= 'a' and out.items[0] <= 'z')) return error.InvalidPackageName;
    return out.toOwnedSlice(alloc);
}

/// Rules 1–3b of `erlAtom` over `text`, appended to `out`. A `_` run is
/// collapsed across the join too, so `__` never occurs in a module atom.
fn appendSanitised(alloc: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), text: []const u8) std.mem.Allocator.Error!void {
    for (text) |raw| {
        const c = std.ascii.toLower(raw);
        const mapped: u8 = switch (c) {
            '/' => '@',
            'a'...'z', '0'...'9', '_', '@' => c,
            else => '_',
        };
        if (mapped == '_' and out.items.len > 0 and out.items[out.items.len - 1] == '_') continue;
        try out.append(alloc, mapped);
    }
}

/// The atom of a module a COMPTIME producer builds (A2's qualifier, kept for
/// the comptime evaluators only — a declaration's module is `declAtom`):
///
///     atom = erlAtom(path) "__" kind "__" decl [ "__" 16-hex-hash ]
///
/// One template declaration evaluates to many distinct generated bodies, and
/// the hash is what keeps a re-evaluation of an identical body the same module
/// (the content-addressing the comptime server relies on). Caller owns the
/// result.
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

/// Decision 109: the atom of the module a declaration becomes under policy 3 —
///
///     atom(decl) = erlAtom(path) ++ "@@" ++ <Decl>
///
/// `<Decl>` is the declaration's own name — a `type`'s, or the `val` an
/// `implement` block is bound to (`pond@@PatoNada`) — and it KEEPS ITS CASE:
/// `type SourceLocation` in `main.bp` is `main@@SourceLocation`, `type File`
/// in `io/fs.bp` is `io@fs@@File`, so the atom decodes back to its source.
/// Only a character outside `[A-Za-z0-9_]` folds to `_`. Still a legal
/// UNQUOTED atom: it starts with the module half's lowercase letter and holds
/// only `[a-zA-Z0-9_@]`. Caller owns the result.
pub fn declAtom(alloc: std.mem.Allocator, id: ModuleId, decl: []const u8) (std.mem.Allocator.Error || AtomError)![]u8 {
    if (decl.len == 0) return error.EmptyDeclName;
    const base = try erlAtom(alloc, id);
    defer alloc.free(base);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(alloc);
    try out.appendSlice(alloc, base);
    try out.appendSlice(alloc, DECL_SEP);
    for (decl) |c| {
        const mapped: u8 = switch (c) {
            'a'...'z', 'A'...'Z', '0'...'9', '_' => c,
            else => '_',
        };
        try out.append(alloc, mapped);
    }
    return out.toOwnedSlice(alloc);
}

/// The identity of a `type` declared in module `id` — the atom of the module
/// that holds its methods under policy 3 AND the tag inside every value the
/// type builds (half 3, decision 21): `declAtom(id, decl)`, so `type Person`
/// in `app/models.bp` is `app@models@@Person`. One renderer, because the
/// value's tag has to name the module that formats it.
pub fn typeAtom(alloc: std.mem.Allocator, id: ModuleId, decl: []const u8) (std.mem.Allocator.Error || AtomError)![]u8 {
    return declAtom(alloc, id, decl);
}

/// The `__v__` segment: a variant's tag, qualified by the enum it belongs to
/// and the module that declares the enum —
/// `typeAtom(id, decl) ++ "__v__" ++ lower(variant)`, so `Shape.Circle` in
/// `main.bp` is `main@@Shape__v__circle`. `Circle` is declared in five files
/// of the ecosystem; this is what tells them apart in one node. A legal
/// unquoted atom like its prefix, and `decodeAtom` reads it back. A variant is
/// a value tag, not a module: decision 109 renames the module half and leaves
/// this qualifier as it was.
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

/// What an atom this module rendered came from. The reason the boundary is a
/// token (`@@`, decision 109) instead of the `#<Decl>` the first proposal
/// asked for: `#` produced text the BEAM never reads, while this decodes.
pub const Decoded = struct {
    shape: enum { module, decl, gen, variant },
    /// The owning package — the atom's first segment. Borrowed.
    package: []const u8,
    /// The module path inside the package, `@` restored to `/`. Owned by the
    /// caller. A dependency's module path is `<package>/<path>`.
    path: []u8,
    /// Borrowed from the atom that was decoded. `kind` is set for a comptime
    /// module only (`gen`); a declaration has no kind.
    kind: []const u8 = "",
    decl: []const u8 = "",
    hash: []const u8 = "",
    /// The `__v__` segment of a variant tag; empty for every other shape.
    variant: []const u8 = "",

    pub fn deinit(self: *Decoded, alloc: std.mem.Allocator) void {
        alloc.free(self.path);
    }
};

/// Split an atom back into its origin: `split("@@")` for a declaration's
/// module or a value tag (decision 109), the `__` qualifier for a comptime
/// module, and the module half's first `@` for the package.
pub fn decodeAtom(alloc: std.mem.Allocator, atom: []const u8) (std.mem.Allocator.Error || AtomError)!Decoded {
    if (std.mem.indexOf(u8, atom, DECL_SEP)) |at| {
        const module_half = atom[0..at];
        const decl_half = atom[at + DECL_SEP.len ..];
        // One boundary: nothing nests a declaration in another today.
        if (module_half.len == 0 or decl_half.len == 0 or std.mem.indexOf(u8, decl_half, DECL_SEP) != null)
            return error.UndecodableAtom;
        const pkg, const path = try splitModule(alloc, module_half);
        errdefer alloc.free(path);
        const vsep = QUALIFIER_SEP ++ VARIANT_TAG ++ QUALIFIER_SEP;
        // The LAST `__v__`: `variantAtom` collapses a variant's `_` runs, so
        // the variant half never holds `__`, while a declaration keeps its
        // underscores (`__Token__Color`).
        if (std.mem.lastIndexOf(u8, decl_half, vsep)) |v| {
            const decl = decl_half[0..v];
            const variant = decl_half[v + vsep.len ..];
            if (decl.len == 0 or variant.len == 0) return error.UndecodableAtom;
            return .{ .shape = .variant, .package = pkg, .path = path, .decl = decl, .variant = variant };
        }
        return .{ .shape = .decl, .package = pkg, .path = path, .decl = decl_half };
    }
    var parts: [4][]const u8 = undefined;
    var n: usize = 0;
    var it = std.mem.splitSequence(u8, atom, QUALIFIER_SEP);
    while (it.next()) |part| {
        if (n == parts.len) return error.UndecodableAtom;
        parts[n] = part;
        n += 1;
    }
    if (n != 1 and n != 4) return error.UndecodableAtom;
    const pkg, const path = try splitModule(alloc, parts[0]);
    errdefer alloc.free(path);
    return switch (n) {
        1 => .{ .shape = .module, .package = pkg, .path = path },
        else => .{ .shape = .gen, .package = pkg, .path = path, .kind = parts[1], .decl = parts[2], .hash = parts[3] },
    };
}

/// The module half of an atom back to its package (borrowed) and its path in
/// the package (`@` → `/`, owned by the caller). Every module atom holds an
/// `@` after a non-empty package; one that does not was not rendered here.
fn splitModule(alloc: std.mem.Allocator, module_half: []const u8) (std.mem.Allocator.Error || AtomError)!struct { []const u8, []u8 } {
    const at = std.mem.indexOfScalar(u8, module_half, '@') orelse return error.UndecodableAtom;
    if (at == 0 or at + 1 == module_half.len) return error.UndecodableAtom;
    const path = try alloc.dupe(u8, module_half[at + 1 ..]);
    for (path) |*c| {
        if (c.* == '@') c.* = '/';
    }
    return .{ module_half[0..at], path };
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
    /// The other declaration's atom (`duplicate_decl`): equal to `atom` when
    /// the two names fold to one spelling, different when they differ only by
    /// case — two atoms, but one file on a case-insensitive file system.
    other_atom: []const u8 = "",

    pub const Reason = enum { duplicate, invalid_package, no_package, too_long, duplicate_decl };

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
            // Two `type` declarations of one module rendering one identity.
            // The declaration keeps its case (decision 109), so `Person` and
            // `person` are two atoms — but one file on a case-insensitive file
            // system, and one module and one value tag would be two types; the
            // pair is refused either way. `Foo-Bar`/`Foo_Bar` fold to one atom
            // outright (a character outside `[A-Za-z0-9_]` becomes `_`).
            .duplicate_decl => if (std.mem.eql(u8, self.atom, self.other_atom))
                std.fmt.allocPrint(
                    alloc,
                    "types `{s}` and `{s}` of module `{s}` both render to the erlang atom `{s}` — a type's identity is its name with every character outside `[A-Za-z0-9_]` folded to `_`",
                    .{ self.decl, self.other, self.path, self.atom },
                )
            else
                std.fmt.allocPrint(
                    alloc,
                    "types `{s}` and `{s}` of module `{s}` render to the erlang atoms `{s}` and `{s}`, which differ only by case — one file on a case-insensitive file system, so the pair is refused",
                    .{ self.decl, self.other, self.path, self.atom, self.other_atom },
                ),
            // `manifest` refuses such a `name` first; this is the same rule
            // where the atom is rendered, for a driver that did not.
            .invalid_package => std.fmt.allocPrint(
                alloc,
                "module `{s}` belongs to package `{s}`, whose name does not start with a lowercase letter — an erlang module atom starts with its package's name and is never quoted",
                .{ self.path, self.other },
            ),
            .no_package => std.fmt.allocPrint(
                alloc,
                "module `{s}` belongs to no package — an erlang module atom starts with the `name` of the botopink.json it is compiled under, and there is none",
                .{self.path},
            ),
            .too_long => std.fmt.allocPrint(
                alloc,
                "module `{s}` renders to an erlang module atom of {d} bytes (`{s}`); the limit is {d}, because `<atom>.beam` has to be a filename",
                .{ self.path, self.atom.len, self.atom, ATOM_MAX_BYTES },
            ),
        };
    }
};

/// Record one `pub` declaration: in `exports` (last writer, as it always was)
/// and in `owners` (every writer). Two maps because they answer two questions —
/// "the export named X", which the eighteen existing call sites ask, and "every
/// declaration of X", which is the only one that can be counted.
fn putExport(
    alloc: std.mem.Allocator,
    exports: *std.StringHashMap(ExportInfo),
    owners: *std.StringHashMap(std.ArrayListUnmanaged(ExportInfo)),
    name: []const u8,
    info: ExportInfo,
) !void {
    try exports.put(name, info);
    const gop = try owners.getOrPut(name);
    if (!gop.found_existing) gop.value_ptr.* = .empty;
    try gop.value_ptr.append(alloc, info);
}

pub fn build(alloc: std.mem.Allocator, outputs: []ComptimeOutput) !CrossModule {
    return buildIn(alloc, outputs, .{});
}

/// `build` for a compilation whose modules belong to `packages` — the erlang
/// and BEAM drivers, whose atoms start with the package (decision 109).
pub fn buildIn(alloc: std.mem.Allocator, outputs: []ComptimeOutput, packages: Packages) !CrossModule {
    var exports = std.StringHashMap(ExportInfo).init(alloc);
    errdefer exports.deinit();
    var imported = std.StringHashMap(void).init(alloc);
    errdefer imported.deinit();
    var field_arrays: std.ArrayListUnmanaged([]const []const u8) = .empty;
    errdefer {
        for (field_arrays.items) |arr| alloc.free(arr);
        field_arrays.deinit(alloc);
    }
    var method_arrays: std.ArrayListUnmanaged([]const MethodSig) = .empty;
    errdefer {
        for (method_arrays.items) |arr| alloc.free(arr);
        method_arrays.deinit(alloc);
    }

    // Every module's erlang/BEAM atom, rendered once, plus the check whose
    // absence is this front: a second path rendering the same atom, a package
    // name that cannot start an atom or an over-long atom is recorded against BOTH modules involved so the
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
        const id = packages.idOf(ct.name);
        const atom = erlAtom(alloc, id) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            error.InvalidPackageName => {
                try atom_faults.put(ct.name, .{ .atom = "", .path = ct.name, .reason = .invalid_package, .other = id.package });
                continue;
            },
            error.MissingPackage => {
                try atom_faults.put(ct.name, .{ .atom = "", .path = ct.name, .reason = .no_package });
                continue;
            },
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
        }
    }

    // The same check over every `type`'s atom (half 3's identity, policy 3's
    // module): two declarations of one module rendering one atom would be one
    // module and one value tag for two types. Across modules the path already
    // tells them apart, so the check is per module. Keyed by the module path
    // like the module faults, so the module fails as a whole. CASE-INSENSITIVE
    // (decision 109): the declaration keeps its case in the atom, so `Person`
    // and `person` are two atoms — and one `.erl` on a case-insensitive file
    // system, which is why the pair is still refused.
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
        // type atom LOWERCASED (owned) → the declaration that rendered it
        // first, and its atom as rendered (owned).
        const Seen = struct { decl: []const u8, atom: []u8 };
        var seen_types = std.StringHashMap(Seen).init(alloc);
        defer {
            var sit = seen_types.iterator();
            while (sit.next()) |e| {
                alloc.free(e.key_ptr.*);
                alloc.free(e.value_ptr.atom);
            }
            seen_types.deinit();
        }
        for (ok.transformed.decls) |decl| {
            const r = switch (decl) {
                .type_ => |t| t,
                else => continue,
            };
            const atom = typeAtom(alloc, packages.idOf(ct.name), r.name) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                error.EmptyModulePath, error.EmptyDeclName, error.UndecodableAtom, error.InvalidPackageName, error.MissingPackage => continue,
            };
            if (atom.len > ATOM_MAX_BYTES) {
                try fault_atoms.append(alloc, atom);
                try atom_faults.put(ct.name, .{ .atom = atom, .path = ct.name, .reason = .too_long, .decl = r.name });
                break;
            }
            const folded = try std.ascii.allocLowerString(alloc, atom);
            const gop = try seen_types.getOrPut(folded);
            if (gop.found_existing) {
                alloc.free(folded);
                try fault_atoms.append(alloc, atom);
                const first_atom = try alloc.dupe(u8, gop.value_ptr.atom);
                try fault_atoms.append(alloc, first_atom);
                try atom_faults.put(ct.name, .{ .atom = atom, .path = ct.name, .reason = .duplicate_decl, .other = gop.value_ptr.decl, .other_atom = first_atom, .decl = r.name });
                break;
            }
            gop.value_ptr.* = .{ .decl = r.name, .atom = atom };
        }
    }

    // EVERY `pub` declaration of a name, filled in the SAME walk as `exports`
    // so each one carries its OWN `fields` and `methods` — read back from
    // `exports` afterwards, the declaration that lost the `put` would carry
    // the winner's shape or none at all, which is the collapse this index
    // exists to undo. `exports` keeps its last-writer shape: eighteen call
    // sites read it and the overwhelming majority of names are declared once.
    var owners = std.StringHashMap(std.ArrayListUnmanaged(ExportInfo)).init(alloc);
    defer {
        var oit = owners.valueIterator();
        while (oit.next()) |l| l.deinit(alloc);
        owners.deinit();
    }
    var owner_arrays: std.ArrayListUnmanaged([]const ExportInfo) = .empty;
    errdefer {
        for (owner_arrays.items) |arr| alloc.free(arr);
        owner_arrays.deinit(alloc);
    }

    for (outputs) |*ct| {
        const ok = switch (ct.outcome) {
            .ok => |*o| o,
            else => continue,
        };
        for (ok.transformed.decls) |decl| switch (decl) {
            .type_ => |r| if (r.isPub) {
                const methods = try alloc.alloc(MethodSig, r.methods.len);
                for (r.methods, 0..) |m, i| methods[i] = .{ .name = m.name, .arity = m.params.len };
                try method_arrays.append(alloc, methods);
                switch (r.shape) {
                    .record => |record_fields| {
                        const fields = try alloc.alloc([]const u8, record_fields.len);
                        for (record_fields, 0..) |f, i| fields[i] = f.name;
                        try field_arrays.append(alloc, fields);
                        try putExport(alloc, &exports, &owners, r.name, .{ .module = ct.name, .kind = .record, .is_class = true, .fields = fields, .methods = methods });
                    },
                    .enum_ => try putExport(alloc, &exports, &owners, r.name, .{ .module = ct.name, .kind = .@"enum", .is_class = false, .methods = methods }),
                }
            },
            // `pub fn` exports — including host-backed `#[@External.<targert>(...)]` declarations.
            // An external fn's owning module re-exports the host symbol under the
            // fn name (`exports.regItem = regItem`), so a consumer that imports it
            // `from "<lib>"` must `require` that owner just like any other export;
            // omitting externals here left such imports unresolved at the call site.
            .@"fn" => |f| if (f.isPub)
                try putExport(alloc, &exports, &owners, f.name, .{
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
                    .arity = f.params.len,
                }),
            .val => |v| if (v.isPub) try putExport(alloc, &exports, &owners, v.name, .{ .module = ct.name, .kind = .val, .is_class = false }),
            // A `pub implement` is emitted as a namespace object; a consumer that
            // stars it (`import { Name* }`) references it as a value (`Name.m(x)`).
            .implement => |im| if (im.isPub) try putExport(alloc, &exports, &owners, im.name, .{ .module = ct.name, .kind = .val, .is_class = false }),
            .use => |u| for (u.imports) |imp| try imported.put(imp.name(), {}),
            else => {},
        };
    }

    var owners_final = std.StringHashMap([]const ExportInfo).init(alloc);
    errdefer owners_final.deinit();
    var oit = owners.iterator();
    while (oit.next()) |e| {
        const arr = try alloc.dupe(ExportInfo, e.value_ptr.items);
        try owner_arrays.append(alloc, arr);
        try owners_final.put(e.key_ptr.*, arr);
    }

    // An ambiguous IMPORT, keyed by the module that wrote it. A name several
    // modules export is not itself the defect — `libs/std` has thirteen of
    // them (`parse`, `stringify`, `empty`, `abs`, …), every one reached
    // qualified through its module — and refusing the declaration would refuse
    // the standard library. What cannot be answered is a consumer reaching for
    // the bare name with nothing in the import that says which module it means.
    var export_faults = std.StringHashMap(Contested).init(alloc);
    errdefer export_faults.deinit();
    {
        const tmp: CrossModule = .{
            .exports = exports,
            .owners = owners_final,
            .export_faults = export_faults,
            .imported = imported,
            .atoms = atoms,
            .atom_faults = atom_faults,
            .packages = packages,
            .alloc = alloc,
        };
        for (outputs) |*ct| {
            const ok = switch (ct.outcome) {
                .ok => |*o| o,
                else => continue,
            };
            for (ok.transformed.decls) |decl| switch (decl) {
                .use => |u| for (u.imports) |imp| {
                    if (export_faults.contains(ct.name)) break;
                    // An import site binds a NAME, not a call, so there is no
                    // arity to narrow with: botopink has no overloading and
                    // `import {parse}` binds exactly one `parse`.
                    switch (tmp.pick(imp.name(), u.source, null)) {
                        .contested => |c| try export_faults.put(ct.name, c),
                        .none, .one => {},
                    }
                },
                else => {},
            };
        }
    }
    return .{ .exports = exports, .owners = owners_final, .export_faults = export_faults, .imported = imported, .atoms = atoms, .atom_faults = atom_faults, .fault_atoms = fault_atoms, .field_arrays = field_arrays, .method_arrays = method_arrays, .owner_arrays = owner_arrays, .packages = packages, .alloc = alloc };
}

// ── tests: the atom, its qualifier, its decoder and the collision check ───────

const testing = std.testing;

fn expectAtom(expected: []const u8, path: []const u8) !void {
    const got = try erlAtom(testing.allocator, test_packages.idOf(path));
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(expected, got);
}

/// The packages of a program `myapp` that depends on `webkit` (and, like every
/// program, on the embedded `std`).
const app_packages: Packages = .{ .root = "myapp", .deps = &.{"webkit"} };

fn expectAtomIn(expected: []const u8, packages: Packages, path: []const u8) !void {
    const got = try erlAtom(testing.allocator, packages.idOf(path));
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(expected, got);
}

test "erlAtom: the atom starts with the owning package (decision 109)" {
    // The root package's modules have bare paths; the package is prepended.
    try expectAtomIn("myapp@main", app_packages, "main");
    try expectAtomIn("myapp@models@user", app_packages, "models/user");
    // A dependency's module path already starts with its package.
    try expectAtomIn("webkit@http", app_packages, "webkit/http");
    try expectAtomIn("std@math", app_packages, "std/math");
    try expectAtomIn("std@io@fs", app_packages, "std/io/fs");
    // A root directory that merely shares a name with nothing is the root's.
    try expectAtomIn("myapp@web@api@http", app_packages, "web/api/http");
    // Compiling the embedded library itself: its modules are the root's.
    try expectAtomIn("std@math", .{ .root = "std" }, "math");
    // A package name is sanitised like a path segment.
    try expectAtomIn("generic_loader_binding@main", .{ .root = "generic-loader-binding" }, "main");
}

test "erlAtom: a module of no package renders no atom — there is no fallback name" {
    try testing.expectError(error.MissingPackage, erlAtom(testing.allocator, .of("main")));
    try testing.expectError(error.MissingPackage, erlAtom(testing.allocator, (Packages{}).idOf("main")));
    // …but the embedded `std` still names its own modules.
    try expectAtomIn("std@math", .{}, "std/math");
    // The compiler's tests compile under the implicit manifest `test`.
    try expectAtomIn("test@main", test_packages, "main");
    try expectAtomIn("test@models@user", test_packages, "models/user");
    // Every atom holds an `@`, so none is an OTP module's name.
    try expectAtomIn("test@math", test_packages, "math");
}

test "erlAtom: a package that does not start with a lowercase letter is refused, never quoted" {
    try testing.expectError(error.InvalidPackageName, erlAtom(testing.allocator, .{ .path = "main", .package = "9lives" }));
    try testing.expectError(error.InvalidPackageName, erlAtom(testing.allocator, .{ .path = "main", .package = "_x" }));
    try testing.expectError(error.InvalidPackageName, erlAtom(testing.allocator, .{ .path = "1st/mod", .package = "1st", .package_in_path = true }));
    // Case folds, so `MyApp` is `myapp` — refused by `manifest`, not here.
    try expectAtomIn("myapp@main", .{ .root = "MyApp" }, "main");
}

test "erlAtom: a character outside [a-z0-9_@] becomes `_`, and case folds" {
    try expectAtom("test@my_mod@user", "My-Mod/User");
    try expectAtom("test@a_b@c_d", "a.b/c d");
    // A path segment may start with anything: the package comes first.
    try expectAtom("test@1st@mod", "1st/mod");
    try expectAtom("test@_hidden", "_hidden");
}

test "erlAtom: a run of `_` collapses, so `__` stays free for the qualifier" {
    try expectAtom("test@my_mod@user", "my__mod/user");
    try expectAtom("test@a_b", "a___b");
    // …across the join too: a package ending in `_` and a path starting with it.
    try expectAtomIn("my_@_x", .{ .root = "my_" }, "_x");
    // …which is the pathological collision the check in `build` has to catch.
    const a = try erlAtom(testing.allocator, test_packages.idOf("my__mod/user"));
    defer testing.allocator.free(a);
    const b = try erlAtom(testing.allocator, test_packages.idOf("my_mod/user"));
    defer testing.allocator.free(b);
    try testing.expectEqualStrings(a, b);
}

test "erlAtom: a path that would exceed 250 bytes renders and is caught later" {
    const long = "a" ** 300;
    const got = try erlAtom(testing.allocator, test_packages.idOf(long));
    defer testing.allocator.free(got);
    // The renderer does not truncate — truncating is what made atoms collide.
    // It is `build`'s check that refuses it, with the filename limit named.
    try testing.expectEqual(@as(usize, 305), got.len);
    try testing.expect(got.len > ATOM_MAX_BYTES);
}

test "erlAtom: an empty path is an error, not an empty atom" {
    try testing.expectError(error.EmptyModulePath, erlAtom(testing.allocator, test_packages.idOf("")));
    // Nothing else can sanitise away: every character maps to `@` or `_`.
    try expectAtom("test@@@@", "///");
}

test "erlDeclAtom: the kind segment is the enum tag, never a free string" {
    const cases = [_]struct { kind: Kind, want: []const u8 }{
        .{ .kind = .tpl, .want = "test@models@user__tpl__pessoa" },
        .{ .kind = .dec, .want = "test@models@user__dec__pessoa" },
    };
    for (cases) |c| {
        const got = try erlDeclAtom(testing.allocator, test_packages.idOf("models/user"), c.kind, "Pessoa", null);
        defer testing.allocator.free(got);
        try testing.expectEqualStrings(c.want, got);
    }
}

test "erlDeclAtom: a comptime producer carries the 16-hex content hash" {
    const got = try erlDeclAtom(testing.allocator, test_packages.idOf("ui/panel"), .tpl, "panel", 0x3f1a9c02b7e4d5f8);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings("test@ui@panel__tpl__panel__3f1a9c02b7e4d5f8", got);
}

test "erlDeclAtom: a comptime declaration name is escaped and its `_` runs collapse" {
    const got = try erlDeclAtom(testing.allocator, test_packages.idOf("main"), .tpl, "My-Type__X", null);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings("test@main__tpl__my_type_x", got);
    try testing.expectError(error.EmptyDeclName, erlDeclAtom(testing.allocator, test_packages.idOf("main"), .tpl, "--", null));
}

test "decodeAtom: every shape round-trips to its origin" {
    const cases = [_]struct {
        atom: []const u8,
        shape: @FieldType(Decoded, "shape"),
        package: []const u8,
        path: []const u8,
        kind: []const u8 = "",
        decl: []const u8 = "",
        hash: []const u8 = "",
    }{
        .{ .atom = "myapp@models@user", .shape = .module, .package = "myapp", .path = "models/user" },
        .{ .atom = "std@math", .shape = .module, .package = "std", .path = "math" },
        .{ .atom = "test@main", .shape = .module, .package = "test", .path = "main" },
        // Decision 109: `<package>@<path>@@<Decl>`, the declaration's case kept.
        .{ .atom = "myapp@models@user@@Pessoa", .shape = .decl, .package = "myapp", .path = "models/user", .decl = "Pessoa" },
        .{ .atom = "std@io@fs@@File", .shape = .decl, .package = "std", .path = "io/fs", .decl = "File" },
        .{ .atom = "std@math@@PI", .shape = .decl, .package = "std", .path = "math", .decl = "PI" },
        .{ .atom = "pond_pkg@pond@@PatoNada", .shape = .decl, .package = "pond_pkg", .path = "pond", .decl = "PatoNada" },
        .{
            .atom = "bp@comptime__tpl__panel__3f1a9c02b7e4d5f8",
            .shape = .gen,
            .package = "bp",
            .path = "comptime",
            .kind = "tpl",
            .decl = "panel",
            .hash = "3f1a9c02b7e4d5f8",
        },
    };
    for (cases) |c| {
        var d = try decodeAtom(testing.allocator, c.atom);
        defer d.deinit(testing.allocator);
        try testing.expectEqual(c.shape, d.shape);
        try testing.expectEqualStrings(c.package, d.package);
        try testing.expectEqualStrings(c.path, d.path);
        try testing.expectEqualStrings(c.kind, d.kind);
        try testing.expectEqualStrings(c.decl, d.decl);
        try testing.expectEqualStrings(c.hash, d.hash);
    }
    // No package: an atom without `@` was not rendered here.
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "main"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "@main"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a@b__c"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a@b__c__d"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a@b__c__d__e__f"));
    // One `@@` boundary, with something on both sides: no construct nests a
    // declaration in another today.
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a@b@@B@@C"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "@@B"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a@b@@"));
    try testing.expectError(error.UndecodableAtom, decodeAtom(testing.allocator, "a@@B"));
}

fn expectTypeAtom(expected: []const u8, path: []const u8, decl: []const u8) !void {
    const got = try typeAtom(testing.allocator, app_packages.idOf(path), decl);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(expected, got);
}

fn expectVariantAtom(expected: []const u8, path: []const u8, decl: []const u8, variant: []const u8) !void {
    const got = try variantAtom(testing.allocator, app_packages.idOf(path), decl, variant);
    defer testing.allocator.free(got);
    try testing.expectEqualStrings(expected, got);
}

test "typeAtom: the type's identity is the `<package>@<path>@@<Decl>` module of the file that declares it" {
    // The package, the path, the declaration with its case kept (decision 109).
    try expectTypeAtom("myapp@main@@Person", "main", "Person");
    try expectTypeAtom("myapp@main@@SourceLocation", "main", "SourceLocation");
    try expectTypeAtom("std@io@fs@@File", "std/io/fs", "File");
    try expectTypeAtom("std@math@@PI", "std/math", "PI");
    try expectTypeAtom("myapp@app@models@@Person", "app/models", "Person");
    try expectTypeAtom("std@dict@@Dict", "std/dict", "Dict");
    // A name that needs escaping: only a character outside `[A-Za-z0-9_]`
    // folds to `_`; underscores and case stay, so the atom decodes back.
    try expectTypeAtom("myapp@main@@__Token__Color", "main", "__Token__Color");
    try expectTypeAtom("myapp@main@@Http2_Server", "main", "Http2-Server");
    // The `val` an `implement` block is bound to is a declaration like any other.
    try expectTypeAtom("myapp@pond@@PatoNada", "pond", "PatoNada");
    // Over the filename limit is an error at the renderer's caller (`build`).
    const long = "Z" ** 260;
    const atom = try typeAtom(testing.allocator, test_packages.idOf("main"), long);
    defer testing.allocator.free(atom);
    try testing.expect(atom.len > ATOM_MAX_BYTES);
    try testing.expectError(error.EmptyDeclName, typeAtom(testing.allocator, test_packages.idOf("main"), ""));
}

test "declAtom: every atom is unquoted — a lowercase first letter, then [a-zA-Z0-9_@]" {
    const cases = [_]struct { path: []const u8, decl: []const u8 }{
        .{ .path = "main", .decl = "SourceLocation" },
        .{ .path = "std/io/fs", .decl = "File" },
        .{ .path = "Models/User", .decl = "Http2-Server" },
        .{ .path = "dict", .decl = "Dict" },
        .{ .path = "9lives", .decl = "Cat" },
    };
    for (cases) |c| {
        const got = try declAtom(testing.allocator, app_packages.idOf(c.path), c.decl);
        defer testing.allocator.free(got);
        try testing.expect(got[0] >= 'a' and got[0] <= 'z');
        for (got) |ch| try testing.expect(std.ascii.isAlphanumeric(ch) or ch == '_' or ch == '@');
    }
}

test "variantAtom: a variant is qualified by its enum and its module" {
    try expectVariantAtom("myapp@main@@Shape__v__circle", "main", "Shape", "Circle");
    try expectVariantAtom("myapp@app@models@@Shape__v__dot", "app/models", "Shape", "Dot");
    // The many `Circle`s of an ecosystem stay many atoms: the package and the
    // path differ.
    try expectVariantAtom("webkit@draw@@Shape__v__circle", "webkit/draw", "Shape", "Circle");
    // A variant whose name needs escaping.
    try expectVariantAtom("myapp@main@@Token__v__500", "main", "Token", "__500");
    try testing.expectError(error.EmptyDeclName, variantAtom(testing.allocator, test_packages.idOf("main"), "Token", "-"));
}

test "decodeAtom: a variant tag round-trips to {variant, package, path, decl, variant} (E15)" {
    const atom = try variantAtom(testing.allocator, app_packages.idOf("app/models"), "Shape", "Circle");
    defer testing.allocator.free(atom);
    var d = try decodeAtom(testing.allocator, atom);
    defer d.deinit(testing.allocator);
    try testing.expectEqual(@as(@FieldType(Decoded, "shape"), .variant), d.shape);
    try testing.expectEqualStrings("myapp", d.package);
    try testing.expectEqualStrings("app/models", d.path);
    try testing.expectEqualStrings("Shape", d.decl);
    try testing.expectEqualStrings("circle", d.variant);
    // And a type atom decodes as before — the `__v__` clause changed nothing.
    const ta = try typeAtom(testing.allocator, app_packages.idOf("app/models"), "Shape");
    defer testing.allocator.free(ta);
    var td = try decodeAtom(testing.allocator, ta);
    defer td.deinit(testing.allocator);
    try testing.expectEqual(@as(@FieldType(Decoded, "shape"), .decl), td.shape);
    try testing.expectEqualStrings("Shape", td.decl);
}

test "decodeAtom: what erlDeclAtom wrote is what decodeAtom reads back" {
    const atom = try erlDeclAtom(testing.allocator, test_packages.idOf("ui/panel"), .tpl, "panel", 0xb7e4d5f83f1a9c02);
    defer testing.allocator.free(atom);
    var d = try decodeAtom(testing.allocator, atom);
    defer d.deinit(testing.allocator);
    try testing.expectEqual(@as(@FieldType(Decoded, "shape"), .gen), d.shape);
    try testing.expectEqualStrings("test", d.package);
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
        const got = try outputStem(c.target, testing.allocator, app_packages.idOf("std/math"));
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
    var xc = try buildIn(testing.allocator, &outputs, test_packages);
    defer xc.deinit();

    try testing.expectEqualStrings("test@my_mod@user", xc.atomFor("my__mod/user"));
    try testing.expectEqualStrings("test@my_mod@user", xc.atomFor("my_mod/user"));
    try testing.expectEqualStrings("test@main", xc.atomFor("main"));

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
    try testing.expect(std.mem.indexOf(u8, msg, "test@my_mod@user") != null);
}

/// A `CrossModule` holding nothing but the `owners` lists — `pick` reads only
/// those, and building one through `build` would need a whole typed program per
/// case. Every other map is empty and unused.
fn pickIndex(owners: *std.StringHashMap([]const ExportInfo)) CrossModule {
    return .{
        .exports = std.StringHashMap(ExportInfo).init(testing.allocator),
        .owners = owners.*,
        .export_faults = std.StringHashMap(Contested).init(testing.allocator),
        .imported = std.StringHashMap(void).init(testing.allocator),
        .atoms = std.StringHashMap([]u8).init(testing.allocator),
        .atom_faults = std.StringHashMap(AtomFault).init(testing.allocator),
        .alloc = testing.allocator,
    };
}

test "pick: one declaration answers, and the `from` picks between two" {
    var owners = std.StringHashMap([]const ExportInfo).init(testing.allocator);
    defer owners.deinit();
    const parses = [_]ExportInfo{
        .{ .module = "one", .kind = .@"fn", .is_class = false, .arity = 1 },
        .{ .module = "two", .kind = .@"fn", .is_class = false, .arity = 2 },
    };
    const only = [_]ExportInfo{.{ .module = "solo", .kind = .@"fn", .is_class = false, .arity = 0 }};
    try owners.put("parse", &parses);
    try owners.put("solo", &only);
    var xc = pickIndex(&owners);
    // `exports` etc. are borrowed empties here, so deinit them directly rather
    // than through `CrossModule.deinit`, which would also free `owners`.
    defer {
        xc.exports.deinit();
        xc.export_faults.deinit();
        xc.imported.deinit();
        xc.atoms.deinit();
        xc.atom_faults.deinit();
    }

    try testing.expect(xc.pick("absent", null, null) == .none);
    // One declaration: no question to ask.
    try testing.expectEqualStrings("solo", (xc.picked("solo", null, null) orelse return error.TestExpectedPick).module);

    // The `from` answers, in both directions — this is the whole defect: the
    // old `exports.get` kept ONE of the two and the walk order chose it.
    const from_one: ast.ImportSource = .{ .module = "one" };
    const from_two: ast.ImportSource = .{ .module = "two" };
    try testing.expectEqualStrings("one", (xc.picked("parse", from_one, null) orelse return error.TestExpectedPick).module);
    try testing.expectEqualStrings("two", (xc.picked("parse", from_two, null) orelse return error.TestExpectedPick).module);

    // The arity answers when the source names nothing (a package handle).
    const from_pkg: ast.ImportSource = .{ .module = "somepkg" };
    try testing.expectEqualStrings("one", (xc.picked("parse", from_pkg, 1) orelse return error.TestExpectedPick).module);
    try testing.expectEqualStrings("two", (xc.picked("parse", from_pkg, 2) orelse return error.TestExpectedPick).module);

    // Neither answers: contested, never the first one.
    try testing.expect(xc.picked("parse", null, null) == null);
    try testing.expect(xc.picked("parse", from_pkg, null) == null);
    // An arity NEITHER declares does not narrow, so it is still contested.
    try testing.expect(xc.picked("parse", null, 7) == null);
    switch (xc.pick("parse", null, null)) {
        .contested => |c| {
            try testing.expectEqualStrings("parse", c.name);
            try testing.expectEqualStrings("one", c.a);
            try testing.expectEqualStrings("two", c.b);
            const msg = try c.message(testing.allocator);
            defer testing.allocator.free(msg);
            try testing.expect(std.mem.indexOf(u8, msg, "one") != null);
            try testing.expect(std.mem.indexOf(u8, msg, "two") != null);
        },
        else => return error.TestExpectedContest,
    }
}

test "pick: a record name is contested by its name alone — there is no arity to ask" {
    var owners = std.StringHashMap([]const ExportInfo).init(testing.allocator);
    defer owners.deinit();
    const outcomes = [_]ExportInfo{
        .{ .module = "parser", .kind = .record, .is_class = true },
        .{ .module = "net", .kind = .record, .is_class = true },
    };
    try owners.put("Outcome", &outcomes);
    var xc = pickIndex(&owners);
    defer {
        xc.exports.deinit();
        xc.export_faults.deinit();
        xc.imported.deinit();
        xc.atoms.deinit();
        xc.atom_faults.deinit();
    }
    const from_parser: ast.ImportSource = .{ .module = "parser" };
    try testing.expectEqualStrings("parser", (xc.picked("Outcome", from_parser, null) orelse return error.TestExpectedPick).module);
    // An arity cannot tell two records apart, so it changes nothing.
    try testing.expect(xc.picked("Outcome", null, 1) == null);
    try testing.expect(xc.picked("Outcome", null, null) == null);
}

test "ImportSource.namesModule: the full path and its last segment, never a package handle" {
    const from_http: ast.ImportSource = .{ .module = "http" };
    try testing.expect(from_http.namesModule("web/http"));
    try testing.expect(from_http.namesModule("http"));
    try testing.expect(!from_http.namesModule("web/https"));
    const full: ast.ImportSource = .{ .module = "web/http" };
    try testing.expect(full.namesModule("web/http"));
    try testing.expect(!full.namesModule("api/http"));
    // A package handle names the package: it matches only a module whose
    // basename IS the handle (the single-module lib shape).
    const pkg: ast.ImportSource = .{ .module = "viewlib" };
    try testing.expect(pkg.namesModule("viewlib/viewlib"));
    try testing.expect(!pkg.namesModule("viewlib/query"));
    // `.root` names no module in particular, so it never narrows.
    const root: ast.ImportSource = .root;
    try testing.expect(!root.namesModule("main"));
}

test "build: an atom over the filename limit is a fault naming the limit" {
    const long = "z" ** 260;
    var outputs = [_]ComptimeOutput{syntaxFailed(long)};
    var xc = try buildIn(testing.allocator, &outputs, test_packages);
    defer xc.deinit();
    const f = xc.atomFault(long) orelse return error.TestExpectedFault;
    try testing.expectEqual(AtomFault.Reason.too_long, f.reason);
    const msg = try f.message(testing.allocator);
    defer testing.allocator.free(msg);
    try testing.expect(std.mem.indexOf(u8, msg, "250") != null);
}

test "build: no module renders an OTP module's name — every atom holds its package" {
    // `math` is an OTP module; the root package's `math.bp` is `myapp@math`,
    // std's is `std@math`, and neither can shadow `math` node-wide.
    var outputs = [_]ComptimeOutput{ syntaxFailed("math"), syntaxFailed("std/math") };
    var xc = try buildIn(testing.allocator, &outputs, app_packages);
    defer xc.deinit();
    try testing.expectEqualStrings("myapp@math", xc.atomFor("math"));
    try testing.expectEqualStrings("std@math", xc.atomFor("std/math"));
    try testing.expect(xc.atomFault("math") == null);
    try testing.expect(xc.atomFault("std/math") == null);
}

test "build: a package whose name cannot start an atom fails its modules, located" {
    var outputs = [_]ComptimeOutput{syntaxFailed("main")};
    var xc = try buildIn(testing.allocator, &outputs, .{ .root = "9lives" });
    defer xc.deinit();
    const f = xc.atomFault("main") orelse return error.TestExpectedFault;
    try testing.expectEqual(AtomFault.Reason.invalid_package, f.reason);
    const msg = try f.message(testing.allocator);
    defer testing.allocator.free(msg);
    try testing.expect(std.mem.indexOf(u8, msg, "`9lives`") != null);
    try testing.expect(std.mem.indexOf(u8, msg, "lowercase letter") != null);
}

/// A `ComptimeOutput` whose program holds only the `type` declarations named —
/// every other field of `OkData` empty. Enough for `build` to render each
/// type's atom, which is what the `duplicate_decl` check reads.
fn typesOnly(alloc: std.mem.Allocator, name: []const u8, decls: []ast.DeclKind) ComptimeOutput {
    return .{ .name = name, .src = "", .outcome = .{ .ok = .{
        .bindings = &.{},
        .comptime_script = null,
        .comptime_vals = std.StringHashMap([]const u8).init(alloc),
        .transformed = .{ .decls = decls },
        .type_ids = std.StringHashMap(usize).init(alloc),
        .dispatch_rewrites = std.AutoHashMap(ast.Loc, []const u8).init(alloc),
        .js_method_renames = std.AutoHashMap(ast.Loc, []const u8).init(alloc),
        .instance_lowerings = std.AutoHashMap(ast.Loc, @import("../comptime/env.zig").InstanceLowering).init(alloc),
        .custom_ast = &.{},
        .comptime_traces = &.{},
    } } };
}

test "build: two types of one module whose atoms differ only by case is a duplicate_decl fault naming both" {
    // `Person` renders `test@main@@Person` and `person` renders `test@main@@person`
    // (decision 109: the declaration keeps its case) — two atoms, but one
    // `.erl` on a case-insensitive file system, so the pair is refused.
    var no_fields: [0]ast.Field = .{};
    var decls = [_]ast.DeclKind{
        .{ .type_ = .{ .name = "Person", .shape = .{ .record = &no_fields } } },
        .{ .type_ = .{ .name = "person", .shape = .{ .record = &no_fields } } },
    };
    var outputs = [_]ComptimeOutput{typesOnly(testing.allocator, "main", &decls)};
    var xc = try buildIn(testing.allocator, &outputs, test_packages);
    defer xc.deinit();

    const fault = xc.atomFault("main") orelse return error.TestExpectedFault;
    try testing.expectEqual(AtomFault.Reason.duplicate_decl, fault.reason);
    try testing.expectEqualStrings("test@main@@person", fault.atom);
    try testing.expectEqualStrings("test@main@@Person", fault.other_atom);
    try testing.expectEqualStrings("Person", fault.other);
    try testing.expectEqualStrings("person", fault.decl);

    const msg = try fault.message(testing.allocator);
    defer testing.allocator.free(msg);
    try testing.expect(std.mem.indexOf(u8, msg, "`person`") != null);
    try testing.expect(std.mem.indexOf(u8, msg, "`Person`") != null);
    try testing.expect(std.mem.indexOf(u8, msg, "`test@main@@person`") != null);
    try testing.expect(std.mem.indexOf(u8, msg, "`test@main@@Person`") != null);
    try testing.expect(std.mem.indexOf(u8, msg, "case-insensitive") != null);
}

test "build: two types folding to one atom outright is the same fault, with one atom" {
    // `Foo-Bar` and `Foo_Bar` both render `test@main@@Foo_Bar`: only a character
    // outside `[A-Za-z0-9_]` folds, and it folds to `_`.
    var no_fields: [0]ast.Field = .{};
    var decls = [_]ast.DeclKind{
        .{ .type_ = .{ .name = "Foo-Bar", .shape = .{ .record = &no_fields } } },
        .{ .type_ = .{ .name = "Foo_Bar", .shape = .{ .record = &no_fields } } },
    };
    var outputs = [_]ComptimeOutput{typesOnly(testing.allocator, "main", &decls)};
    var xc = try buildIn(testing.allocator, &outputs, test_packages);
    defer xc.deinit();
    const fault = xc.atomFault("main") orelse return error.TestExpectedFault;
    try testing.expectEqual(AtomFault.Reason.duplicate_decl, fault.reason);
    try testing.expectEqualStrings("test@main@@Foo_Bar", fault.atom);
    try testing.expectEqualStrings("test@main@@Foo_Bar", fault.other_atom);
    const msg = try fault.message(testing.allocator);
    defer testing.allocator.free(msg);
    try testing.expect(std.mem.indexOf(u8, msg, "both render to the erlang atom `test@main@@Foo_Bar`") != null);
}

test "build: two types whose atoms differ raise no fault, and the module's own atom stands" {
    var no_fields: [0]ast.Field = .{};
    var decls = [_]ast.DeclKind{
        .{ .type_ = .{ .name = "Person", .shape = .{ .record = &no_fields } } },
        .{ .type_ = .{ .name = "Vec", .shape = .{ .record = &no_fields } } },
        // Case kept and `_` kept: `FooBar` and `Foo_Bar` are two atoms that no
        // file system folds together.
        .{ .type_ = .{ .name = "FooBar", .shape = .{ .record = &no_fields } } },
        .{ .type_ = .{ .name = "Foo_Bar", .shape = .{ .record = &no_fields } } },
    };
    var outputs = [_]ComptimeOutput{typesOnly(testing.allocator, "app/models", &decls)};
    var xc = try buildIn(testing.allocator, &outputs, test_packages);
    defer xc.deinit();
    try testing.expect(xc.atomFault("app/models") == null);
    try testing.expectEqualStrings("test@app@models", xc.atomFor("app/models"));
}
