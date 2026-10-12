//! The code cache's level B inside a compile (decision 509 (1), 144 B-60 S2):
//! a dependency's analysis read back from its entry instead of analysed, and
//! the entry of a dependency that was analysed written for the next
//! invocation.
//!
//! The compile driver (`comptime.zig` `compileOnce`) hands every module to a
//! `Session`, which files it in a GROUP: an embedded std module is a group of
//! its own (`std/<module>`), every module of a dependency package one group
//! (the package's import name), a module of the package under test none — it
//! is always analysed and never stored. Where the entries live and their keys
//! are the caller's (`Store`, the CLI's `analysis_store.zig`); the entry's
//! format is `analysis_entry.zig`.
//!
//! **A hit** — a group whose entry reads back whole under its key, for the
//! same modules — is decoded into the session's arena before the pre-passes
//! run, so neither `expandStdImports`, `orderReaders` nor the module tree
//! parses its modules (META carries what they learn); at each module's turn
//! its analysed output is appended and its JOURNAL replayed, and nothing of it
//! is analysed.
//!
//! **A miss** with a key records: around each of the group's modules the
//! session's registries, default DSL and catalogue are compared before and
//! after (`Snapshot`), the difference is the module's JOURNAL, and once the
//! group's last module is analysed — before any consumer is, and before
//! codegen rewrites anything in place — the entry is encoded and handed to the
//! store, which writes it once the invocation's generate succeeded. A group
//! is stored only when every module of it analysed (`ok`), its modules are
//! contiguous in the order, none reads `@TypeInfo.all` and none expanded a
//! template that queries the catalogue: their answers are the whole
//! program's, never the closure's.
//!
//! **The code** (S4): an entry's CODE holds each of its modules' own unit on
//! the target, as a build emitted it. The compile hands the emit a `Code`
//! (`ComptimeSession.level_b_code`): `codegen.generateWith` passes it to the
//! emitter (`Config.level_b_code`, never under `botopink test` — it emits a
//! dependency's test blocks until B-64), which takes a module's unit from it
//! instead of emitting the module (`Config.cachedUnit`), and once the emit
//! returned, every entry staged or read without CODE (`check` and `test` write
//! none) is staged again with it (`Code.record`). All four targets skip: a
//! dependency's unit is lowered against its own closure, never its consumers'
//! (decision 509 (2)) — wasm too, which links a dependency's bodies into each
//! CONSUMER's unit, lowered there; the dependency's own unit links only its
//! own dependencies. What a consumer instantiates never reaches an entry
//! (guard 4).
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");
const comptimeMod = @import("../comptime.zig");
const entry = @import("./analysis_entry.zig");
const reflectionMod = @import("./reflection.zig");
const modTree = @import("./mod_tree.zig");
const Module = @import("../module.zig").Module;
const moduleOutput = @import("../codegen/moduleOutput.zig");

const Allocator = std.mem.Allocator;
const ComptimeOutput = comptimeMod.ComptimeOutput;
const Journal = entry.Journal;

/// Where a compile's entries come from and go to — the CLI's analysis store.
pub const Store = struct {
    ctx: *anyopaque,
    vtable: *const VTable,
    /// `code_cache.EntryTarget.name` of the build: META's `target`.
    target: []const u8,
    /// What the last compile did, for the store's owner to read (a test, the
    /// measurement) — never a flag or a variable (decision 67).
    stats: Stats = .{},

    pub const VTable = struct {
        /// The key of `group` (a dependency package's import name, or
        /// `std/<module>`), or null: never stored.
        key: *const fn (ctx: *anyopaque, group: []const u8) ?entry.Key,
        /// The entry of `group` proven against `key`, or null (none, or one in
        /// doubt — deleted). Its bytes live as long as the store.
        read: *const fn (ctx: *anyopaque, group: []const u8, key: entry.Key) ?entry.Entry,
        /// Delete `group`'s entry: it proved whole but does not decode.
        discard: *const fn (ctx: *anyopaque, group: []const u8) void,
        /// Keep `bytes` (an entry, copied) to be written as `group`'s when the
        /// invocation's generate succeeds.
        stage: *const fn (ctx: *anyopaque, group: []const u8, bytes: []const u8) void,
    };
};

pub const Stats = struct {
    /// Modules analysed in this compile, the package under test's included.
    modules_analysed: usize = 0,
    /// Modules read back from an entry.
    modules_read: usize = 0,
    entries_read: usize = 0,
    entries_staged: usize = 0,
    /// Modules the emit skipped: their unit read from the entry's CODE.
    modules_code_read: usize = 0,
    /// Entries staged again with the CODE of their modules.
    code_staged: usize = 0,
};

/// The group of module `m`: an embedded std module's own path, a dependency's
/// package, or null for the package under test.
pub fn groupOf(m: Module) ?[]const u8 {
    if (isStdGroup(m)) return m.path;
    if (m.package.len > 0) return m.package;
    return null;
}

/// Whether `m` is an embedded std module — a group of its own.
fn isStdGroup(m: Module) bool {
    return m.std_member and std.mem.startsWith(u8, m.path, "std/");
}

/// The session's state a module's analysis and `registerExports` change.
pub const Registries = struct {
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    type_decls: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templates: *std.StringHashMap(ast.FnDecl),
    decorators: *std.StringHashMap(ast.FnDecl),
    extensions: *std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
    dsl: *comptimeMod.DefaultDsl,
    reflection: *reflectionMod.Reflection,
};

const Hit = struct {
    output: ComptimeOutput,
    journal: Journal,
    meta: entry.ModuleMeta,
};

const Recording = struct {
    key: entry.Key,
    /// The group's modules in the input order.
    paths: std.ArrayListUnmanaged([]const u8) = .empty,
    /// The index of the group's last module in the session's order (`plan`).
    last: usize = 0,
    storable: bool = true,
    outputs: std.ArrayListUnmanaged(ComptimeOutput) = .empty,
    journals: std.ArrayListUnmanaged(Journal) = .empty,
    metas: std.ArrayListUnmanaged(entry.ModuleMeta) = .empty,
};

/// One compile's level B.
pub const Session = struct {
    /// The compile session's arena: decoded entries and journals live here.
    arena: Allocator,
    /// For snapshots (freed after each module) and the encoded entries.
    gpa: Allocator,
    store: *Store,
    hits: std.StringHashMapUnmanaged(Hit) = .empty,
    recording: std.StringArrayHashMapUnmanaged(Recording) = .empty,
    /// Module path → the std modules it needs (`std/<path>`), as
    /// `expandStdImports` found them, for a recording group's META.
    std_needs: std.StringHashMapUnmanaged([]const []const u8) = .empty,
    looked_up: std.StringHashMapUnmanaged(void) = .empty,
    /// What the emit reads and writes of the entries' CODE.
    code: *Code,

    pub fn init(arena: Allocator, gpa: Allocator, store: *Store) !Session {
        const code = try arena.create(Code);
        code.* = .{ .store = store };
        return .{ .arena = arena, .gpa = gpa, .store = store, .code = code };
    }

    pub const Which = enum { packages, std };

    /// Look up every group of `which` among `modules` once: a hit decoded,
    /// a miss with a key recorded.
    pub fn lookup(self: *Session, modules: []const Module, which: Which) !void {
        var groups: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged([]const u8)) = .empty;
        for (modules) |m| {
            const g = groupOf(m) orelse continue;
            if (isStdGroup(m) != (which == .std)) continue;
            if (self.looked_up.contains(g)) continue;
            const gop = try groups.getOrPut(self.arena, g);
            if (!gop.found_existing) gop.value_ptr.* = .empty;
            try gop.value_ptr.append(self.arena, m.path);
        }
        for (groups.keys(), groups.values()) |g, paths| {
            try self.looked_up.put(self.arena, g, {});
            const key = self.store.vtable.key(self.store.ctx, g) orelse continue;
            if (try self.readHit(g, key, paths.items)) continue;
            try self.recording.put(self.arena, g, .{ .key = key, .paths = paths });
        }
    }

    /// Decode `g`'s entry when it is one for `paths`; true on a hit.
    fn readHit(self: *Session, g: []const u8, key: entry.Key, paths: []const []const u8) !bool {
        const e = self.store.vtable.read(self.store.ctx, g, key) orelse return false;
        const decoded = entry.read(self.arena, e) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            error.Malformed => {
                self.store.vtable.discard(self.store.ctx, g);
                return false;
            },
        };
        const meta = decoded.meta;
        // Proven and decoded, but of another module set or target: a miss,
        // replaced when this invocation writes its own.
        if (!std.mem.eql(u8, meta.package, g) or !std.mem.eql(u8, meta.target, self.store.target)) return false;
        if (meta.modules.len != paths.len or meta.module_meta.len != paths.len or decoded.journals.len != paths.len) return false;
        for (meta.modules, paths, meta.module_meta) |a, b, mm| {
            if (!std.mem.eql(u8, a, b) or !std.mem.eql(u8, mm.path, b) or mm.reads_catalogue) return false;
        }
        for (paths, decoded.outputs, decoded.journals, meta.module_meta) |p, o, j, mm| {
            try self.hits.put(self.arena, p, .{ .output = o, .journal = j, .meta = mm });
        }
        if (decoded.code.len == paths.len) {
            for (paths, decoded.code) |p, c| try self.code.units.put(self.arena, p, c);
        } else try self.code.pending.append(self.arena, .{ .group = g, .key = key, .sections = e.sections, .modules = paths });
        self.store.stats.entries_read += 1;
        return true;
    }

    /// The pre-pass META of module `m` when it is read back.
    pub fn hitMeta(self: *const Session, m: Module) ?*const entry.ModuleMeta {
        const h = self.hitOf(m) orelse return null;
        return &h.meta;
    }

    /// Module `m`'s hit, or null. A hit is a dependency's module: a module of
    /// the package under test spelled like one (`shelf/items` beside the
    /// dependency `shelf`'s) is never answered by the dependency's entry.
    pub fn hitOf(self: *const Session, m: Module) ?*const Hit {
        if (groupOf(m) == null) return null;
        return self.hits.getPtr(m.path);
    }

    fn recordingOf(self: *Session, m: Module) ?*Recording {
        const g = groupOf(m) orelse return null;
        const r = self.recording.getPtr(g) orelse return null;
        return if (r.storable) r else null;
    }

    /// `expandStdImports` found that `m` needs the std modules `paths`.
    pub fn noteStdNeeds(self: *Session, m: Module, paths: []const []const u8) !void {
        if (self.recordingOf(m) == null) return;
        try self.std_needs.put(self.arena, m.path, paths);
    }

    /// One per module of `modules`: what the module tree knows of a hit.
    pub fn treeKnown(self: *const Session, modules: []const Module) ![]const ?modTree.Known {
        const out = try self.arena.alloc(?modTree.Known, modules.len);
        for (modules, out) |m, *k| k.* = if (self.hitMeta(m)) |mm| mm.tree else null;
        return out;
    }

    /// Where each recording group's modules sit in the session's order; a
    /// group whose modules are not contiguous there is not stored.
    pub fn plan(self: *Session, modules: []const Module) void {
        for (self.recording.keys(), self.recording.values()) |key, *r| {
            var first: ?usize = null;
            var last: usize = 0;
            var seen: usize = 0;
            for (modules, 0..) |m, i| {
                const g = groupOf(m) orelse continue;
                if (!std.mem.eql(u8, g, key)) continue;
                if (first == null) first = i;
                last = i;
                seen += 1;
            }
            const f = first orelse {
                r.storable = false;
                continue;
            };
            r.last = last;
            if (seen != r.paths.items.len or last - f + 1 != seen) r.storable = false;
        }
    }

    /// Before module `m` is analysed: a snapshot of what it may change when
    /// its group records, else null.
    pub fn begin(self: *Session, m: Module, regs: Registries) !?Snapshot {
        self.store.stats.modules_analysed += 1;
        if (self.recordingOf(m) == null) return null;
        return try Snapshot.take(self.gpa, regs);
    }

    /// Module `m` (at `idx`) was analysed to `out`: its journal recorded and,
    /// when it is its group's last, the entry encoded and staged. The caller
    /// frees `snapshot`.
    pub fn end(self: *Session, m: Module, idx: usize, out: ComptimeOutput, regs: Registries, snapshot: ?*const Snapshot, tree: *const modTree.Tree) !void {
        const snap = snapshot orelse return;
        const r = self.recordingOf(m) orelse return;
        if (out.outcome != .ok or snap.template_reads != regs.reflection.templateReads.items.len or regs.reflection.readers.contains(m.path)) {
            r.storable = false;
            return;
        }
        try r.journals.append(self.arena, try snap.diff(self.arena, regs));
        try r.outputs.append(self.arena, out);
        try r.metas.append(self.arena, .{
            .path = m.path,
            .std_imports = self.std_needs.get(m.path) orelse &.{},
            .tree = try modTree.knownOf(self.arena, tree, m.path),
        });
        if (idx != r.last) return;
        if (r.outputs.items.len != r.paths.items.len) {
            r.storable = false;
            return;
        }
        const g = groupOf(m).?;
        const bytes = try entry.write(self.gpa, r.key, .{
            .package = g,
            .target = self.store.target,
            .modules = r.paths.items,
            .module_meta = r.metas.items,
        }, r.outputs.items, r.journals.items);
        defer self.gpa.free(bytes);
        self.store.vtable.stage(self.store.ctx, g, bytes);
        self.store.stats.entries_staged += 1;
        r.storable = false;
        // Kept for the emit: staged again with its modules' CODE once they
        // are emitted.
        const kept = try self.arena.dupe(u8, bytes);
        const sections = (try entry.unpack(self.arena, kept, r.key)).sections;
        try self.code.pending.append(self.arena, .{ .group = g, .key = r.key, .sections = sections, .modules = r.paths.items });
    }

    /// Module `m` was not analysed (a reader refused at its import): its
    /// group is not stored.
    pub fn abandon(self: *Session, m: Module) void {
        if (self.recordingOf(m)) |r| r.storable = false;
    }

    /// Module `path` read back: its output's place taken, its journal replayed.
    pub fn replayHit(self: *Session, h: *const Hit, regs: Registries) !void {
        self.store.stats.modules_read += 1;
        try replay(self.arena, h.journal, regs);
    }
};

// ── The code (S4) ─────────────────────────────────────────────────────────────

/// One compile's CODE: the units its entries hold, and the entries still
/// without them. Lives in the compile session's arena.
pub const Code = struct {
    store: *Store,
    /// A module read back from an entry with CODE → its CODE section.
    units: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// The entries staged by this compile, or read without CODE.
    pending: std.ArrayListUnmanaged(Pending) = .empty,

    pub const Pending = struct {
        group: []const u8,
        key: entry.Key,
        /// The entry's sections, CODE aside.
        sections: []const entry.Section,
        /// Its modules, in META's order.
        modules: []const []const u8,
    };

    /// What of the emit's configuration a unit's bytes depend on beyond the
    /// entry's key.
    pub const Emit = struct {
        wasm_artifact: bool,
        /// The build asked for a `.d.ts` (commonJS).
        typedef: bool,
    };

    /// Whether module `name`'s unit is to be recorded: the emit gives it
    /// everything CODE holds (commonJS: its `.d.ts`, asked for or not).
    pub fn records(self: *const Code, name: []const u8) bool {
        for (self.pending.items) |p| for (p.modules) |m| if (std.mem.eql(u8, m, name)) return true;
        return false;
    }

    /// Module `name`'s unit read back, owned by `gpa`, or null: emit it.
    /// A CODE that does not decode, or was emitted otherwise, is not used.
    pub fn take(self: *Code, gpa: Allocator, name: []const u8, how: Emit) !?moduleOutput.GenerateResult {
        const bytes = self.units.get(name) orelse return null;
        var scratch = std.heap.ArenaAllocator.init(gpa);
        defer scratch.deinit();
        const unit = entry.decodeCode(scratch.allocator(), bytes) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            error.Malformed => return null,
        };
        if (unit.wasm_artifact != how.wasm_artifact) return null;
        var r = unit.result;
        if (!how.typedef) r.typedef = null;
        const owned = try ownResult(gpa, r);
        self.store.stats.modules_code_read += 1;
        return owned;
    }

    /// The emit returned `outputs`: every pending entry whose modules all
    /// emitted is staged again with their CODE. With `typedef` false the
    /// `.d.ts` the emit made for CODE alone is dropped from `outputs` after.
    pub fn record(self: *Code, gpa: Allocator, outputs: []moduleOutput.ModuleOutput, how: Emit) !void {
        var codes: std.ArrayListUnmanaged([]u8) = .empty;
        defer {
            for (codes.items) |c| gpa.free(c);
            codes.deinit(gpa);
        }
        var sections: std.ArrayListUnmanaged(entry.Section) = .empty;
        defer sections.deinit(gpa);
        groups: for (self.pending.items) |p| {
            for (codes.items) |c| gpa.free(c);
            codes.clearRetainingCapacity();
            sections.clearRetainingCapacity();
            try sections.appendSlice(gpa, p.sections);
            for (p.modules) |m| {
                const o = outputOf(outputs, m) orelse continue :groups;
                if (o.result.failed()) continue :groups;
                const unit: entry.CodeUnit = .{ .wasm_artifact = how.wasm_artifact, .result = o.result };
                try codes.append(gpa, try entry.encodeCode(gpa, &unit));
                try sections.append(gpa, .{ .id = .code, .bytes = codes.items[codes.items.len - 1] });
            }
            const bytes = try entry.pack(gpa, p.key, sections.items);
            defer gpa.free(bytes);
            self.store.vtable.stage(self.store.ctx, p.group, bytes);
            self.store.stats.code_staged += 1;
        }
        if (!how.typedef) for (outputs) |*o| if (o.result.typedef) |t| {
            gpa.free(t);
            o.result.typedef = null;
        };
    }
};

fn outputOf(outputs: []const moduleOutput.ModuleOutput, name: []const u8) ?*const moduleOutput.ModuleOutput {
    for (outputs) |*o| if (std.mem.eql(u8, o.name, name)) return o;
    return null;
}

/// The fields of `GenerateResult` `ownResult` copies, `entry.code_skips`
/// aside — a test holds the two lists to the type, so a field added there
/// is copied here too.
const owned_result_fields = [_][]const u8{ "js", "typedef", "units", "comptime_script", "wasm", "std_funcs", "comptime_trace" };

/// `r` (a decoded unit, in a scratch arena) copied into `gpa`, as an
/// emitter's own result is.
fn ownResult(gpa: Allocator, r: moduleOutput.GenerateResult) !moduleOutput.GenerateResult {
    var out: moduleOutput.GenerateResult = .{ .js = try gpa.dupe(u8, r.js), .comptime_script = null };
    errdefer out.deinit(gpa);
    if (r.typedef) |t| out.typedef = try gpa.dupe(u8, t);
    if (r.comptime_script) |t| out.comptime_script = try gpa.dupe(u8, t);
    if (r.wasm) |t| out.wasm = try gpa.dupe(u8, t);
    if (r.comptime_trace) |t| out.comptime_trace = try gpa.dupe(u8, t);
    if (r.units.len > 0) {
        const units = try gpa.alloc(moduleOutput.Unit, r.units.len);
        var filled: usize = 0;
        errdefer {
            for (units[0..filled]) |u| {
                gpa.free(u.atom);
                gpa.free(u.code);
            }
            gpa.free(units);
        }
        for (r.units, units) |u, *d| {
            const atom = try gpa.dupe(u8, u.atom);
            errdefer gpa.free(atom);
            d.* = .{ .atom = atom, .code = try gpa.dupe(u8, u.code) };
            filled += 1;
        }
        out.units = units;
    }
    if (r.std_funcs.len > 0) {
        const funcs = try gpa.alloc(moduleOutput.StdFunc, r.std_funcs.len);
        var filled: usize = 0;
        errdefer {
            for (funcs[0..filled]) |f| {
                gpa.free(f.symbol);
                gpa.free(f.label);
            }
            gpa.free(funcs);
        }
        for (r.std_funcs, funcs) |f, *d| {
            const symbol = try gpa.dupe(u8, f.symbol);
            errdefer gpa.free(symbol);
            d.* = .{ .symbol = symbol, .label = try gpa.dupe(u8, f.label), .hash = f.hash };
            filled += 1;
        }
        out.std_funcs = funcs;
    }
    return out;
}

// ── Snapshot and difference ───────────────────────────────────────────────────

fn Flat(comptime V: type) type {
    return std.StringHashMapUnmanaged(V);
}

fn Nested(comptime V: type) type {
    return std.StringHashMapUnmanaged(Flat(V));
}

/// The session's state before one module: every map copied (an inner map
/// whole), every list by its length. Owned by its own arena, freed after the
/// difference is taken.
pub const Snapshot = struct {
    arena_inst: std.heap.ArenaAllocator,
    registry: Nested(*T.Type),
    type_decls: Nested(ast.DeclKind),
    templates: Flat(ast.FnDecl),
    decorators: Flat(ast.FnDecl),
    extensions: Nested(ast.ImplementDecl),
    dsl_mod_names: Flat([]const u8),
    dsl_handlers: Flat(comptimeMod.DefaultDsl.Handler),
    meta: Flat(usize),
    typed_meta: Flat(usize),
    decorator_meta_types: Flat([]const reflectionMod.MetaCallType),
    assoc: Flat(usize),
    declared: usize,
    template_queries: Flat([]const reflectionMod.TemplateQuery),
    hook_fns: Flat(@FieldType(@FieldType(reflectionMod.Reflection, "hookFns").KV, "value")),
    scopes: Flat(reflectionMod.WrittenName),
    template_reads: usize,

    pub fn take(gpa: Allocator, regs: Registries) !Snapshot {
        var arena_inst = std.heap.ArenaAllocator.init(gpa);
        errdefer arena_inst.deinit();
        const a = arena_inst.allocator();
        const r = regs.reflection;
        return .{
            .registry = try copyNested(*T.Type, a, regs.registry),
            .type_decls = try copyNested(ast.DeclKind, a, regs.type_decls),
            .templates = try copyFlat(ast.FnDecl, a, regs.templates),
            .decorators = try copyFlat(ast.FnDecl, a, regs.decorators),
            .extensions = try copyNested(ast.ImplementDecl, a, regs.extensions),
            .dsl_mod_names = try copyFlat([]const u8, a, &regs.dsl.modName),
            .dsl_handlers = try copyFlat(comptimeMod.DefaultDsl.Handler, a, &regs.dsl.handler),
            .meta = try lengths(a, &r.meta),
            .typed_meta = try lengths(a, &r.typedMeta),
            .decorator_meta_types = try copyFlat([]const reflectionMod.MetaCallType, a, &r.decoratorMetaTypes),
            .assoc = try lengths(a, &r.assoc),
            .declared = r.declared.items.len,
            .template_queries = try copyFlat([]const reflectionMod.TemplateQuery, a, &r.templateQueries),
            .hook_fns = try copyFlat(@FieldType(@FieldType(reflectionMod.Reflection, "hookFns").KV, "value"), a, &r.hookFns),
            .scopes = try copyFlat(reflectionMod.WrittenName, a, &r.scopes),
            .template_reads = r.templateReads.items.len,
            .arena_inst = arena_inst,
        };
    }

    pub fn deinit(self: *Snapshot) void {
        self.arena_inst.deinit();
    }

    /// What changed since the snapshot, allocated with `arena`.
    pub fn diff(self: *const Snapshot, arena: Allocator, regs: Registries) !Journal {
        const r = regs.reflection;
        return .{
            .registry = try diffNested(*T.Type, arena, &self.registry, regs.registry),
            .type_decls = try diffNested(ast.DeclKind, arena, &self.type_decls, regs.type_decls),
            .templates = try diffFlat(ast.FnDecl, arena, &self.templates, regs.templates),
            .decorators = try diffFlat(ast.FnDecl, arena, &self.decorators, regs.decorators),
            .extensions = try diffNested(ast.ImplementDecl, arena, &self.extensions, regs.extensions),
            .dsl_mod_names = try diffFlat([]const u8, arena, &self.dsl_mod_names, &regs.dsl.modName),
            .dsl_handlers = try diffFlat(comptimeMod.DefaultDsl.Handler, arena, &self.dsl_handlers, &regs.dsl.handler),
            .meta = try diffLists(reflectionMod.MetaEntry, arena, &self.meta, &r.meta),
            .typed_meta = try diffLists(reflectionMod.TypedMetaEntry, arena, &self.typed_meta, &r.typedMeta),
            .decorator_meta_types = try diffFlat([]const reflectionMod.MetaCallType, arena, &self.decorator_meta_types, &r.decoratorMetaTypes),
            .assoc = try diffLists([]const u8, arena, &self.assoc, &r.assoc),
            .declared = try arena.dupe(reflectionMod.DeclaredEntry, r.declared.items[self.declared..]),
            .template_queries = try diffFlat([]const reflectionMod.TemplateQuery, arena, &self.template_queries, &r.templateQueries),
            .hook_fns = try diffFlat(@FieldType(@FieldType(reflectionMod.Reflection, "hookFns").KV, "value"), arena, &self.hook_fns, &r.hookFns),
            .scopes = try diffFlat(reflectionMod.WrittenName, arena, &self.scopes, &r.scopes),
        };
    }
};

fn copyFlat(comptime V: type, a: Allocator, map: anytype) !Flat(V) {
    var out: Flat(V) = .empty;
    try out.ensureTotalCapacity(a, @intCast(map.count()));
    var it = map.iterator();
    while (it.next()) |e| out.putAssumeCapacity(e.key_ptr.*, e.value_ptr.*);
    return out;
}

fn copyNested(comptime V: type, a: Allocator, map: anytype) !Nested(V) {
    var out: Nested(V) = .empty;
    try out.ensureTotalCapacity(a, @intCast(map.count()));
    var it = map.iterator();
    while (it.next()) |e| out.putAssumeCapacity(e.key_ptr.*, try copyFlat(V, a, e.value_ptr));
    return out;
}

fn lengths(a: Allocator, map: anytype) !Flat(usize) {
    var out: Flat(usize) = .empty;
    try out.ensureTotalCapacity(a, map.count());
    var it = map.iterator();
    while (it.next()) |e| out.putAssumeCapacity(e.key_ptr.*, e.value_ptr.items.len);
    return out;
}

/// Two values the same: their bytes (a pointer by address, a slice by address
/// and length). A value put again equal reads as unchanged; one equal in
/// content at another address reads as replaced, which replays to the same.
fn same(comptime V: type, a: V, b: V) bool {
    return std.mem.eql(u8, std.mem.asBytes(&a), std.mem.asBytes(&b));
}

fn byKey(comptime E: type) fn (void, E, E) bool {
    return struct {
        fn lt(_: void, x: E, y: E) bool {
            return std.mem.order(u8, x.key, y.key) == .lt;
        }
    }.lt;
}

fn sortedStrings(items: [][]const u8) void {
    std.mem.sort([]const u8, items, {}, struct {
        fn lt(_: void, x: []const u8, y: []const u8) bool {
            return std.mem.order(u8, x, y) == .lt;
        }
    }.lt);
}

/// Every entry of `map`, as puts sorted by key.
fn allOf(comptime V: type, arena: Allocator, map: anytype) !entry.MapOps(V) {
    var puts = try arena.alloc(entry.Put(V), map.count());
    var it = map.iterator();
    var i: usize = 0;
    while (it.next()) |e| : (i += 1) puts[i] = .{ .key = e.key_ptr.*, .value = e.value_ptr.* };
    std.mem.sort(entry.Put(V), puts, {}, byKey(entry.Put(V)));
    return .{ .puts = puts };
}

fn diffFlat(comptime V: type, arena: Allocator, before: *const Flat(V), now: anytype) !entry.MapOps(V) {
    var puts: std.ArrayListUnmanaged(entry.Put(V)) = .empty;
    var removes: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = now.iterator();
    while (it.next()) |e| {
        if (before.get(e.key_ptr.*)) |old| if (same(V, old, e.value_ptr.*)) continue;
        try puts.append(arena, .{ .key = e.key_ptr.*, .value = e.value_ptr.* });
    }
    var bit = before.iterator();
    while (bit.next()) |e| if (!now.contains(e.key_ptr.*)) try removes.append(arena, e.key_ptr.*);
    std.mem.sort(entry.Put(V), puts.items, {}, byKey(entry.Put(V)));
    sortedStrings(removes.items);
    return .{ .puts = puts.items, .removes = removes.items };
}

fn diffNested(comptime V: type, arena: Allocator, before: *const Nested(V), now: anytype) !entry.NestedOps(V) {
    var maps: std.ArrayListUnmanaged(entry.InnerOps(V)) = .empty;
    var removes: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = now.iterator();
    while (it.next()) |e| {
        const k = e.key_ptr.*;
        if (before.getPtr(k)) |inner_before| {
            const ops = try diffFlat(V, arena, inner_before, e.value_ptr);
            if (ops.removes.len > 0) {
                try maps.append(arena, .{ .key = k, .reset = true, .ops = try allOf(V, arena, e.value_ptr) });
            } else if (ops.puts.len > 0) {
                try maps.append(arena, .{ .key = k, .reset = false, .ops = ops });
            }
        } else try maps.append(arena, .{ .key = k, .reset = true, .ops = try allOf(V, arena, e.value_ptr) });
    }
    var bit = before.iterator();
    while (bit.next()) |e| if (!now.contains(e.key_ptr.*)) try removes.append(arena, e.key_ptr.*);
    std.mem.sort(entry.InnerOps(V), maps.items, {}, byKey(entry.InnerOps(V)));
    sortedStrings(removes.items);
    return .{ .maps = maps.items, .removes = removes.items };
}

fn diffLists(comptime E: type, arena: Allocator, before: *const Flat(usize), now: anytype) !entry.ListAppends(E) {
    var lists: std.ArrayListUnmanaged(entry.Appended(E)) = .empty;
    var it = now.iterator();
    while (it.next()) |e| {
        const n = before.get(e.key_ptr.*) orelse 0;
        const items = e.value_ptr.items;
        if (items.len <= n) continue;
        // Copied: the list's buffer may move as it grows.
        try lists.append(arena, .{ .key = e.key_ptr.*, .items = try arena.dupe(E, items[n..]) });
    }
    std.mem.sort(entry.Appended(E), lists.items, {}, byKey(entry.Appended(E)));
    return .{ .lists = lists.items };
}

// ── Replay ────────────────────────────────────────────────────────────────────

fn isManaged(comptime M: type) bool {
    return @hasField(M, "unmanaged");
}

fn putIn(map: anytype, arena: Allocator, k: []const u8, v: anytype) !void {
    if (comptime isManaged(@TypeOf(map.*))) try map.put(k, v) else try map.put(arena, k, v);
}

fn replayFlat(comptime V: type, arena: Allocator, map: anytype, ops: entry.MapOps(V)) !void {
    for (ops.removes) |k| _ = map.remove(k);
    for (ops.puts) |p| try putIn(map, arena, p.key, p.value);
}

fn replayNested(comptime V: type, arena: Allocator, map: anytype, ops: entry.NestedOps(V)) !void {
    const Outer = @TypeOf(map.*);
    const Inner = if (comptime isManaged(Outer)) @FieldType(Outer.Unmanaged.KV, "value") else @FieldType(Outer.KV, "value");
    for (ops.removes) |k| _ = map.remove(k);
    for (ops.maps) |m| {
        if (m.reset or !map.contains(m.key)) {
            const fresh: Inner = if (comptime isManaged(Inner)) Inner.init(arena) else .empty;
            try putIn(map, arena, m.key, fresh);
        }
        try replayFlat(V, arena, map.getPtr(m.key).?, m.ops);
    }
}

fn replayLists(comptime E: type, arena: Allocator, map: *std.StringHashMapUnmanaged(std.ArrayListUnmanaged(E)), a: entry.ListAppends(E)) !void {
    for (a.lists) |l| {
        const gop = try map.getOrPut(arena, l.key);
        if (!gop.found_existing) gop.value_ptr.* = .empty;
        try gop.value_ptr.appendSlice(arena, l.items);
    }
}

/// Apply module's journal `j` to the session — what its analysis and
/// `registerExports` did there.
pub fn replay(arena: Allocator, j: Journal, regs: Registries) !void {
    const r = regs.reflection;
    try replayNested(*T.Type, arena, regs.registry, j.registry);
    try replayNested(ast.DeclKind, arena, regs.type_decls, j.type_decls);
    try replayFlat(ast.FnDecl, arena, regs.templates, j.templates);
    try replayFlat(ast.FnDecl, arena, regs.decorators, j.decorators);
    try replayNested(ast.ImplementDecl, arena, regs.extensions, j.extensions);
    try replayFlat([]const u8, arena, &regs.dsl.modName, j.dsl_mod_names);
    try replayFlat(comptimeMod.DefaultDsl.Handler, arena, &regs.dsl.handler, j.dsl_handlers);
    try replayLists(reflectionMod.MetaEntry, r.arena, &r.meta, j.meta);
    try replayLists(reflectionMod.TypedMetaEntry, r.arena, &r.typedMeta, j.typed_meta);
    try replayFlat([]const reflectionMod.MetaCallType, r.arena, &r.decoratorMetaTypes, j.decorator_meta_types);
    try replayLists([]const u8, r.arena, &r.assoc, j.assoc);
    for (j.declared) |d| try r.addDeclared(d);
    try replayFlat([]const reflectionMod.TemplateQuery, r.arena, &r.templateQueries, j.template_queries);
    try replayFlat(@FieldType(@FieldType(reflectionMod.Reflection, "hookFns").KV, "value"), r.arena, &r.hookFns, j.hook_fns);
    try replayFlat(reflectionMod.WrittenName, r.arena, &r.scopes, j.scopes);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

/// A store in memory: every group but the package under test has one key.
const MemoryStore = struct {
    entries: std.StringHashMapUnmanaged([]u8) = .empty,
    staged: std.StringHashMapUnmanaged([]u8) = .empty,
    /// The section tables `read` builds.
    tables: std.heap.ArenaAllocator = undefined,
    store: Store = undefined,

    const vtable: Store.VTable = .{ .key = keyFn, .read = readFn, .discard = discardFn, .stage = stageFn };
    const the_key: entry.Key = @splat(0x42);

    fn init(self: *MemoryStore) void {
        self.* = .{ .tables = std.heap.ArenaAllocator.init(testing.allocator) };
        self.store = .{ .ctx = self, .vtable = &vtable, .target = "erlang" };
    }

    fn deinit(self: *MemoryStore) void {
        inline for (.{ &self.entries, &self.staged }) |m| {
            var it = m.iterator();
            while (it.next()) |e| {
                testing.allocator.free(e.key_ptr.*);
                testing.allocator.free(e.value_ptr.*);
            }
            m.deinit(testing.allocator);
        }
        self.tables.deinit();
    }

    /// What the last compile staged becomes what the next one reads.
    fn commit(self: *MemoryStore) !void {
        var it = self.staged.iterator();
        while (it.next()) |e| {
            if (try self.entries.fetchPut(testing.allocator, e.key_ptr.*, e.value_ptr.*)) |old| {
                testing.allocator.free(old.key);
                testing.allocator.free(old.value);
            }
        }
        self.staged.clearRetainingCapacity();
    }

    fn keyFn(_: *anyopaque, _: []const u8) ?entry.Key {
        return the_key;
    }

    fn readFn(ctx: *anyopaque, group: []const u8, key: entry.Key) ?entry.Entry {
        const self: *MemoryStore = @ptrCast(@alignCast(ctx));
        const bytes = self.entries.get(group) orelse return null;
        return entry.unpack(self.tables.allocator(), bytes, key) catch null;
    }

    fn discardFn(_: *anyopaque, _: []const u8) void {}

    fn stageFn(ctx: *anyopaque, group: []const u8, bytes: []const u8) void {
        const self: *MemoryStore = @ptrCast(@alignCast(ctx));
        const copy = testing.allocator.dupe(u8, bytes) catch return;
        if (self.staged.getPtr(group)) |slot| {
            testing.allocator.free(slot.*);
            slot.* = copy;
            return;
        }
        const g = testing.allocator.dupe(u8, group) catch return;
        self.staged.put(testing.allocator, g, copy) catch {};
    }
};

test "level B: a package expanding a template that reads the catalogue is never stored, nor is the package under test; the template's own package is, and is read back" {
    const h = @import("tests/helpers.zig");
    const io = testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    const modules = [_]Module{
        .{ .path = "looks/root", .package = "looks", .source = "pub default mod looks;\n" },
        .{ .path = "looks/looks", .package = "looks", .source =
        \\pub fn theme(comptime decl: @Decl) {
        \\    decl.setMeta("named", decl.name);
        \\}
        \\
        \\pub default fn looks(comptime e: @Expr<string>) -> @Expr<string> {
        \\    val themes = @TypeInfo.all(with: theme);
        \\    return @expr(e.text() + ": " + themes.length.toString());
        \\}
        \\
        },
        .{ .path = "middle/mid", .package = "middle", .source =
        \\import looks from "looks";
        \\
        \\pub fn shown() -> string {
        \\    return looks "mid";
        \\}
        \\
        },
        .{ .path = "main", .source =
        \\import {mid.shown} from "middle";
        \\
        \\pub fn main() {
        \\    @print(shown());
        \\}
        \\
        },
    };
    var mem: MemoryStore = undefined;
    mem.init();
    defer mem.deinit();

    var first = try comptimeMod.compileWith(testing.allocator, &modules, io, build_root, "erlang", &mem.store);
    defer first.deinit(testing.allocator);
    for (first.outputs.items) |o| try testing.expect(o.outcome == .ok);
    try testing.expect(mem.staged.contains("looks"));
    try testing.expect(!mem.staged.contains("middle"));
    try testing.expect(!mem.staged.contains("main"));
    try testing.expect(!mem.staged.contains(""));
    try mem.commit();

    var second = try comptimeMod.compileWith(testing.allocator, &modules, io, build_root, "erlang", &mem.store);
    defer second.deinit(testing.allocator);
    for (second.outputs.items) |o| try testing.expect(o.outcome == .ok);
    // `looks` read back; `middle` and `main` analysed again.
    try testing.expectEqual(@as(usize, 2), mem.store.stats.modules_read);
    try testing.expectEqual(@as(usize, 2), mem.store.stats.modules_analysed);
    try testing.expectEqual(@as(usize, 0), mem.store.stats.entries_staged);
}

test "level B: a package that reads @TypeInfo.all is never stored" {
    const h = @import("tests/helpers.zig");
    const io = testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    const modules = [_]Module{
        .{ .path = "cat/cat", .package = "cat", .source =
        \\pub fn listed(comptime decl: @Decl) {
        \\    decl.setMeta("named", decl.name);
        \\}
        \\
        \\#[listed]
        \\pub fn one() -> i32 {
        \\    return 1;
        \\}
        \\
        \\pub fn count() -> i32 {
        \\    return @TypeInfo.all(with: listed).length;
        \\}
        \\
        },
        .{ .path = "main", .source =
        \\pub fn main() {
        \\    @print("main");
        \\}
        \\
        },
    };
    var mem: MemoryStore = undefined;
    mem.init();
    defer mem.deinit();
    var session = try comptimeMod.compileWith(testing.allocator, &modules, io, build_root, "erlang", &mem.store);
    defer session.deinit(testing.allocator);
    try testing.expect(!mem.staged.contains("cat"));
    try testing.expectEqual(@as(usize, 0), mem.store.stats.entries_staged);
}

test "level B: a hit is the dependency's module — one of the package under test spelled like it is analysed" {
    const h = @import("tests/helpers.zig");
    const io = testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    // The dependency `looks` and a module of the package under test at the
    // same path, `looks/looks` (a folder of the project named like the
    // dependency).
    const modules = [_]Module{
        .{ .path = "looks/looks", .package = "looks", .source = "pub fn n() -> i32 {\n    return 1;\n}\n" },
        .{ .path = "looks/looks", .source = "pub fn n() -> i32 {\n    return 2;\n}\n" },
    };
    var mem: MemoryStore = undefined;
    mem.init();
    defer mem.deinit();
    var first = try comptimeMod.compileWith(testing.allocator, &modules, io, build_root, "erlang", &mem.store);
    defer first.deinit(testing.allocator);
    try testing.expect(mem.staged.contains("looks"));
    try mem.commit();

    var second = try comptimeMod.compileWith(testing.allocator, &modules, io, build_root, "erlang", &mem.store);
    defer second.deinit(testing.allocator);
    // The dependency's module read back; the project's own analysed.
    try testing.expectEqual(@as(usize, 1), mem.store.stats.modules_read);
    try testing.expectEqual(@as(usize, 1), mem.store.stats.modules_analysed);
    try testing.expectEqual(@as(usize, 2), second.outputs.items.len);
    for (second.outputs.items) |o| try testing.expect(o.outcome == .ok);
}

test "level B: an entry under the group's key for another module set is a miss, and the group is written again" {
    const h = @import("tests/helpers.zig");
    const io = testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    const root: Module = .{ .path = "looks/root", .package = "looks", .source = "pub default mod looks;\n" };
    const looks: Module = .{ .path = "looks/looks", .package = "looks", .source = "pub fn n() -> i32 {\n    return 1;\n}\n" };
    var mem: MemoryStore = undefined;
    mem.init();
    defer mem.deinit();
    var first = try comptimeMod.compileWith(testing.allocator, &[_]Module{ root, looks }, io, build_root, "erlang", &mem.store);
    defer first.deinit(testing.allocator);
    try mem.commit();

    // The same key (`MemoryStore` has one), the package with one module
    // fewer: nothing of the entry is used, the group is analysed and staged.
    var second = try comptimeMod.compileWith(testing.allocator, &[_]Module{looks}, io, build_root, "erlang", &mem.store);
    defer second.deinit(testing.allocator);
    try testing.expectEqual(@as(usize, 0), mem.store.stats.modules_read);
    try testing.expectEqual(@as(usize, 1), mem.store.stats.modules_analysed);
    try testing.expectEqual(@as(usize, 1), mem.store.stats.entries_staged);
    try testing.expect(mem.staged.contains("looks"));
}

test "level B CODE: every field of GenerateResult is stored and copied back, or named in code_skips" {
    const fields = @typeInfo(moduleOutput.GenerateResult).@"struct".fields;
    try testing.expectEqual(fields.len, owned_result_fields.len + entry.code_skips.len);
    inline for (fields) |f| {
        var found = false;
        for (owned_result_fields) |n| found = found or std.mem.eql(u8, n, f.name);
        inline for (entry.code_skips) |sk| found = found or comptime std.mem.eql(u8, sk.field, f.name);
        try testing.expect(found);
    }
}
