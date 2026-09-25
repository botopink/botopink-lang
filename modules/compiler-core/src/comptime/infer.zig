/// Type inference for the botopink type checker.
///
/// Entry points:
///   `inferProgram(env, program)` ---- infers all top-level declarations and
///   returns a map of name → *Type for every declared binding.
///
/// The inference is two-pass:
///   1. Register all type definitions (records, structs, enums) and build
///      constructor types for them.
///   2. Infer the type of every expression/declaration and bind the result.
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");
const Env = @import("env.zig").Env;
const envMod = @import("env.zig");
const TypeError = @import("error.zig").TypeError;
const diagnostics = @import("diagnostics.zig");
const effectChain = @import("effect_chain.zig");
const template = @import("template.zig");
const primOpTemplate = @import("primOpTemplate.zig");
const templateEval = @import("template_eval.zig");
const decoratorEval = @import("decorator_eval.zig");
const specializeMod = @import("specialize.zig");
const unifyMod = @import("unify.zig");
const snapshotMod = @import("snapshot.zig");
const unify = unifyMod.unify;
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const Module = @import("../module.zig").Module;
const comptimeMod = @import("../comptime.zig");

pub const InferError = error{ TypeError, OutOfMemory };

/// A single resolved top-level binding: the declaration name and its inferred type.
pub const Binding = struct {
    name: []const u8,
    type_: *T.Type,
};

/// Like `Binding` but also carries the typed expression tree for `val` declarations.
/// `typedExpr` is null for type declarations (record/struct/enum/interface/fn).
/// `decl` is the original AST declaration node.
/// `typeId` is set for record/struct/enum declarations (monotonic counter).
pub const TypedBinding = struct {
    name: []const u8,
    type_: *T.Type,
    typedExpr: ?ast.TypedExpr,
    decl: ast.DeclKind,
    typeId: ?usize = null,
};

// ── public entry point ────────────────────────────────────────────────────────

/// Infer types for an entire program.
///
/// Pass 1 registers all type definitions (record, struct, enum) and builds
/// constructor bindings in the environment.
/// Pass 2 infers every `val` and `fn` declaration in source order.
///
/// Returns a slice of `Binding` values in declaration order.
/// All memory is allocated in `env.arena`.
/// Decision 107 — every item of an import list binds exactly one local name
/// (`ImportPath.name()`: the alias, else the leaf). The names one module's
/// imports bind are unique: a second item binding a name already bound is
/// `import-name-collision`, located at that second item, in either spelling.
/// A repeated IDENTICAL item is not a collision — an `@emit` contribution
/// re-imports what its module already imports, and codegen dedups it the
/// same way (`seen_imports`). Runs for every `use` decl, `from "std"` or not,
/// on both inference entry points.
fn noteImportBindings(env: *Env, u: ast.ImportDecl) InferError!void {
    if (u.activationOnly) return;
    for (u.imports) |imp| {
        // A `*` opts an extension in by its declared name; the dispatch rewrite
        // emits `Name.method(recv)`, so a renamed binding is one it never
        // reaches. Refused rather than bound half-way.
        if (imp.activate and imp.alias != null) {
            const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}* as {s}` — an activation names the extension it opts in; it cannot be renamed", .{ diagnostics.import_alias_on_activation, imp.leaf(), imp.alias.? });
            env.lastError = TypeError.custom(msg, "Drop the `as`: `import {Name*}` activates `Name` under its own name.").withLoc(imp.loc);
            return error.TypeError;
        }
        const local = imp.name();
        const gop = try env.importBound.getOrPut(local);
        if (gop.found_existing) {
            if (gop.value_ptr.samePath(imp)) continue;
            const first = gop.value_ptr.*;
            const first_path = try first.dotted(env.arena);
            const this_path = try imp.dotted(env.arena);
            const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}` is already bound by the import of `{s}`; `{s}` would bind it again", .{ diagnostics.import_name_collision, local, first_path, this_path });
            env.lastError = TypeError.custom(msg, "Rename one of the two with `as` (`url.parse as parseUrl`), or import the namespace and qualify the call.").withLoc(imp.loc);
            return error.TypeError;
        }
        gop.value_ptr.* = imp;
    }
}

/// Decision 106 — the root of std is pure: a module at `std/<name>` (one
/// segment under `std/`) imports nothing from `io/`, whether it spells the
/// std package bare (`import {io.fs.readText};`, the package's own root) or
/// `from "std"`, in the dotted or the grouped form (`io: {fs}`), and
/// including the namespace `io` itself. `io/` and `testing/` modules are two
/// segments deep and are not checked; neither is user code, where `io.` on
/// the import line is a reading signal and not a guarantee. No configuration
/// (decision 67). Located at the offending item.
fn checkStdRootPurity(env: *Env, u: ast.ImportDecl) InferError!void {
    if (!std.mem.startsWith(u8, env.modulePath, "std/")) return;
    const name = env.modulePath["std/".len..];
    if (std.mem.indexOfScalar(u8, name, '/') != null) return;
    const into_std = switch (u.source) {
        .root => true,
        .module => |m| std.mem.eql(u8, m, "std"),
    };
    if (!into_std) return;
    for (u.imports) |imp| {
        if (!std.mem.eql(u8, imp.segments[0], "io")) continue;
        const path = try imp.dotted(env.arena);
        const msg = try std.fmt.allocPrint(env.arena, "{s}: std module `{s}` is at the root of std, which is pure; `{s}` imports from `io/`", .{ diagnostics.std_root_imports_io, name, path });
        env.lastError = TypeError.custom(msg, "Move the module under `io/` (it talks to the world), or take the value it needs as a parameter.").withLoc(imp.loc);
        return error.TypeError;
    }
}

/// `import {bool} from "std"` — marks each imported std module in
/// `env.stdImports` so qualified calls (`bool.negate(x)`) resolve against
/// `env.stdModules`. Returns true when the decl was a `from "std"` import
/// (fully handled here); unknown std module → clear type error.
///
/// Decision 107 — an item may carry a path. `import {io.fs} from "std"` (or
/// `io: {fs}`) binds the MODULE `io/fs` as the namespace `fs`;
/// `import {io.fs.readText as read}` binds the module's `pub fn` as the value
/// `read`; `import {collections.Dict}` registers that one `pub type`. Only the
/// leaf enters scope — neither `io` nor `fs` is bound by the last two.
fn markStdImports(env: *Env, u: ast.ImportDecl) InferError!bool {
    try checkStdRootPurity(env, u);
    try noteImportBindings(env, u);
    const from_std = switch (u.source) {
        .module => |m| std.mem.eql(u8, m, "std"),
        .root => false,
    };
    if (!from_std) return false;
    for (u.imports) |imp| {
        const whole = try imp.fullPath(env.arena);
        // The leaf is a module (the namespace form, dotted or grouped).
        if (env.stdModules.contains(whole)) {
            try env.stdImports.put(imp.name(), whole);
            // Type export: register the module's `pub` record/struct/enum decls
            // into this env so case patterns and annotations can name them
            // (e.g. `Order` from `import {order} from "std"`). Variant/constructor
            // value bindings come along — construct via the module's fns
            // (`order.lt()`), not the bare constructors (codegen has no local decl).
            if (env.stdModuleTypes.get(whole)) |decls| {
                for (decls) |d| try registerTypeDecl(env, d);
            }
            try checkStdTargetSupport(env, whole);
            continue;
        }
        // The leaf is a symbol of the module the prefix names.
        if (imp.isQualified()) {
            const mod_name = try imp.prefixPath(env.arena);
            const exports = env.stdModules.get(mod_name) orelse {
                const msg = try std.fmt.allocPrint(env.arena, "unknown \"std\" module `{s}` in import", .{mod_name});
                env.lastError = TypeError.custom(msg, "Only the leaf of an import path enters scope; the segments before it name a std module (`libs/std/src/root.bp` lists them).").withLoc(imp.loc);
                return error.TypeError;
            };
            const leaf = imp.leaf();
            var bound_type = false;
            if (env.stdModuleTypes.get(mod_name)) |decls| {
                for (decls) |d| {
                    const type_name = switch (d) {
                        .type_ => |t| t.name,
                        else => continue,
                    };
                    if (!std.mem.eql(u8, type_name, leaf)) continue;
                    if (imp.alias != null) {
                        const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}` is a type; a type keeps its declared name", .{ diagnostics.import_alias_on_type, leaf });
                        env.lastError = TypeError.custom(msg, "Import the type under its own name (`import {collections.Dict}`); `as` renames a value or a function.").withLoc(imp.loc);
                        return error.TypeError;
                    }
                    try registerTypeDecl(env, d);
                    bound_type = true;
                    break;
                }
            }
            if (!bound_type) {
                const ty = exports.get(leaf) orelse {
                    const msg = try std.fmt.allocPrint(env.arena, "std module `{s}` has no public `{s}`", .{ mod_name, leaf });
                    env.lastError = TypeError.custom(msg, "Check the name against the module's `pub` declarations (`libs/std/AGENTS.md` lists each module's surface).").withLoc(imp.loc);
                    return error.TypeError;
                };
                try env.bind(imp.name(), ty);
            }
            try checkStdTargetSupport(env, mod_name);
            continue;
        }
        env.lastError = TypeError.custom(
            "unknown \"std\" module in import",
            "Available std modules: bool. (`result` is builtin — call `result.map(r, f)` without importing.)",
        ).withLoc(imp.loc);
        return error.TypeError;
    }
    return true;
}

/// STD-001 — when an active target is set on this env (the CLI codegen
/// path), red on imports of std modules whose declares lack an
/// `@external(<target>, …)` match. Pure-bp `pub fn` (with body) ship
/// on every target without a host binding, so they're skipped. Only
/// host-bound `pub declare fn` are gated.
fn checkStdTargetSupport(env: *Env, mod_name: []const u8) InferError!void {
    const tgt = env.target orelse return;
    const fns = env.stdModuleFns.get(mod_name) orelse return;
    for (fns) |f| {
        if (f.body.len > 0) continue;
        if (!f.isExternal()) continue;
        if (f.externalFor(tgt) != null) continue;
        const msg = try std.fmt.allocPrint(env.arena, "{s}: std/{s}.{s} has no `@external` for target '{s}'", .{ diagnostics.std_unsupported_on_target, mod_name, f.name, tgt });
        env.lastError = TypeError.custom(msg, "Either add a per-target `@external` to the declare, or pick a target the module supports (see libs/std/src/examples.md per-target coverage matrix).");
        return error.TypeError;
    }
}

/// Append one `TypedBinding` per imported symbol in a `use` decl so the LSP's
/// completion/hover engine sees them. `import {…} from "std"` is marked (and
/// contributes no value bindings — std symbols resolve via `env.stdModules`).
/// `resolveImports` already bound each name, so we read the type from `env`.
fn appendImportBindings(
    env: *Env,
    list: *std.ArrayListUnmanaged(TypedBinding),
    decl: ast.DeclKind,
    u: ast.ImportDecl,
) InferError!void {
    // A `from "std"` namespace item contributes no value binding; a symbol
    // leaf of one (`import {dict.empty as newDict}`, decision 107) was bound
    // by `markStdImports` and is listed like any other import.
    _ = try markStdImports(env, u);
    for (u.imports) |imp| {
        const name = imp.name();
        if (env.lookup(name)) |ty| {
            try list.append(env.arena, .{
                .name = name,
                .type_ = ty,
                .typedExpr = null,
                .decl = decl,
            });
        }
    }
}

pub fn inferProgram(env: *Env, program: ast.Program) InferError![]Binding {
    var list: std.ArrayListUnmanaged(Binding) = .empty;
    env.testIndex = 0;

    try validateUniqueDefaults(env, program);

    // Pass 1: register type definitions and their constructors.
    for (program.decls) |decl| {
        try registerTypeDecl(env, decl);
    }
    try registerExtensions(env, program);
    try buildScopeSnapshot(env, program);
    try registerFnSignatures(env, program);
    try registerAnnotationTypes(env, program);

    // Annotation processors run before bodies (see `inferProgramTyped`): a
    // decorator's `@emit`ed decls must be spliced before a body referencing them
    // is inferred. Bail out early when contributions exist — the spliced
    // re-analysis does the real inference.
    try validateDecorators(env, program);
    try validateEffectAnnotations(env, program);
    try validateExternalInline(env, program);
    try invokeDecorators(env, program);
    if (env.contributions.items.len > 0) {
        return list.toOwnedSlice(env.arena);
    }

    // Pass 2: infer value-producing declarations in order.
    for (program.decls) |decl| {
        if (try inferDecl(env, decl)) |b| {
            try list.append(env.arena, b);
        }
    }

    // C10 second pass — every declaration is registered by now, so an annotation
    // that still names nothing is an unknown type, reported at the annotation.
    try env.checkPendingTypeNames();

    // Pass 3: semantic validation of `implement` blocks and struct accessors.
    // (Decorators already ran above, before body inference.)
    try validateProgram(env, program);

    return list.toOwnedSlice(env.arena);
}

/// Like `inferProgram` but returns `TypedBinding` slices that include the
/// typed expression tree for each `val` declaration.
/// A package declares at most one `pub default mod` and one `pub default fn`; a
/// duplicate of either in one module is the error (NOT the location — they may be
/// declared in any module of the package). Cross-module pairing is the driver's
/// job (`registerExports`); this catches the per-module case for both inference
/// entry points.
fn validateUniqueDefaults(env: *Env, program: ast.Program) InferError!void {
    var default_mods: usize = 0;
    var default_fns: usize = 0;
    for (program.decls) |decl| switch (decl) {
        .mod => |m| if (m.isDefault) {
            default_mods += 1;
        },
        .@"fn" => |f| if (f.isDefault) {
            default_fns += 1;
        },
        else => {},
    };
    if (default_mods > 1 or default_fns > 1) {
        env.lastError = TypeError.custom(
            "a package declares at most one `pub default mod` and one `pub default fn`",
            "Remove the duplicate default declaration; a package has a single default module and handler.",
        );
        return error.TypeError;
    }
}

pub fn inferProgramTyped(env: *Env, program: ast.Program) InferError![]TypedBinding {
    var list: std.ArrayListUnmanaged(TypedBinding) = .empty;
    env.testIndex = 0;

    try validateUniqueDefaults(env, program);

    for (program.decls) |decl| {
        try registerTypeDecl(env, decl);
    }
    try registerExtensions(env, program);
    try buildScopeSnapshot(env, program);
    try registerFnSignatures(env, program);
    try registerAnnotationTypes(env, program);

    // Annotation processors run BEFORE bodies are inferred: a decorator's
    // `@emit`ed declarations must be spliced (by `analyzeSource`) and present
    // before any body that references the generated decl is type-checked.
    // (Previously decorators ran in pass 3, after bodies — a body referencing a
    // generated decl failed spuriously, which blocked `@emit` under `botopink
    // test`. The serialized handles read only the AST, so no body inference is
    // needed first.)
    try validateDecorators(env, program);
    try validateEffectAnnotations(env, program);
    try validateExternalInline(env, program);
    try invokeDecorators(env, program);
    if (env.contributions.items.len > 0) {
        // A decorator `@emit`ed code: the spliced re-analysis (`analyzeSource`)
        // does the real, full inference of the generated declarations. But the
        // LSP needs a useful binding list even when that spliced code can't
        // type-check standalone (it may reference symbols only resolvable with
        // the project graph). Collect the bindings that don't depend on the
        // not-yet-spliced decls: imports, type declarations, and `fn`
        // signatures, and `val`s. A decl that fails to infer — a `val` whose body
        // references a generated decl, say — is tolerated (it just contributes no
        // binding) so one broken body never blanks the whole list. Generic — no
        // decorator framework is named here.
        for (program.decls) |decl| switch (decl) {
            .use => |u| try appendImportBindings(env, &list, decl, u),
            // N23 — a `val` is inferred tolerantly like the other decls: one
            // that references a not-yet-spliced decl fails and contributes no
            // binding; a well-typed one still binds (the LSP lists it).
            .val => {
                const maybe = inferDeclTyped(env, decl) catch |err| switch (err) {
                    error.TypeError => blk: {
                        env.lastError = null;
                        break :blk null;
                    },
                    else => return err,
                };
                if (maybe) |b| try list.append(env.arena, b);
            },
            else => {
                const maybe = inferDeclTyped(env, decl) catch |err| switch (err) {
                    error.TypeError => null,
                    else => return err,
                };
                if (maybe) |b| try list.append(env.arena, b);
            },
        };
        return list.toOwnedSlice(env.arena);
    }

    for (program.decls) |decl| {
        switch (decl) {
            // `resolveImports` (called before inference in comptime.zig) already
            // called `env.bind(name, ty)` for each symbol in the `use` statement.
            // Emit one TypedBinding per import so the LSP completion engine can
            // see them — the dummy `name = ""` binding is gone.
            .use => |u| try appendImportBindings(env, &list, decl, u),
            else => {
                if (try inferDeclTyped(env, decl)) |b| {
                    try list.append(env.arena, b);
                }
            },
        }
    }

    // C10 second pass — every declaration is registered by now, so an annotation
    // that still names nothing is an unknown type, reported at the annotation.
    try env.checkPendingTypeNames();

    // Semantic validation of `implement` blocks and struct accessors. (Decorators
    // already ran above, before body inference.)
    try validateProgram(env, program);

    return list.toOwnedSlice(env.arena);
}

// ── pass 3: semantic validation ───────────────────────────────────────────────

/// Validate `implement` blocks against the interfaces they claim to satisfy and
/// check that struct getters/setters agree with their backing field's type.
///
/// Runs after type registration so user-defined interface and field types are
/// already known. **Both** forms are checked for method coverage — the standalone
/// `implement … for …` block and the inline `type … implement I { }` clause
/// (decision 58). Interfaces that are not declared in this program (e.g. stdlib
/// interfaces) are skipped — their method sets are not visible.
fn validateProgram(env: *Env, program: ast.Program) InferError!void {
    var interfaces = std.StringHashMap(ast.BehaviorDecl).init(env.arena);
    defer interfaces.deinit();
    for (program.decls) |decl| switch (decl) {
        .behavior => |d| try interfaces.put(d.name, d),
        else => {},
    };

    for (program.decls) |decl| switch (decl) {
        .implement => |impl| try validateImplement(env, impl, interfaces),
        .type_ => |td| try validateInlineImplements(env, td, interfaces, program),
        else => {},
    };
}

/// Decision 58 — an inline `implement <Behavior> { }` on a type declaration
/// asserts that the type satisfies the behavior, and nothing verified the
/// assertion: `type Money(cents: i32) implement Display { }` **checked**, with
/// `Display` declared in the same file and with the long-registered `Generator`
/// too. Only the separate block was covered (the
/// `implement_missing_a_required_interface_method` snapshot family), so this was
/// the same family as decisions 37, 38 and 45 — the checker accepting what a
/// backend then answers on its own.
///
/// It is the same coverage check `validateImplement` runs, applied to the inline
/// form; decision 58 settles that it is not a question about meaning.
///
/// A required method is one the behavior declares with **no body** — a
/// `default fn` carries its own, so implementing it is optional. It is satisfied
/// by a member of the type's own body, or by a member of any separate
/// `implement <Behavior> for <this type>` block in the same program: writing both
/// halves is legal and the inline clause is what names the contract.
///
/// Interfaces this program does not declare are skipped, exactly as
/// `validateImplement` skips them. That leaves an ambient `libs/std` behavior
/// unchecked in both forms — the block form's existing blind spot, reported rather
/// than widened here, because closing it needs the interface-member registry and
/// would red every implementation the registry cannot open.
fn validateInlineImplements(
    env: *Env,
    td: ast.TypeDecl,
    interfaces: std.StringHashMap(ast.BehaviorDecl),
    program: ast.Program,
) InferError!void {
    for (td.implement) |iface| {
        const iname = interfaceRefName(iface);
        const d = interfaces.get(iname) orelse continue;
        for (d.methods) |am| {
            if (am.body != null) continue; // a default method — optional
            if (typeDeclProvidesMethod(td, am.name)) continue;
            if (separateImplementProvides(program, td.name, iname, am.name)) continue;
            env.lastError = TypeError.missingMethod(td.name, iname, am.name);
            return error.TypeError;
        }
    }
}

/// True when the type's own body provides `name` with a body. A `declare fn`
/// member is an abstract slot typed from its signature, so it provides nothing.
fn typeDeclProvidesMethod(td: ast.TypeDecl, name: []const u8) bool {
    for (td.methods) |m| {
        if (!std.mem.eql(u8, m.name, name)) continue;
        if (m.body != null) return true;
    }
    return false;
}

/// True when some `implement <iname> for <target>` block in this program provides
/// `name` — either unqualified, or qualified with `iname` itself.
fn separateImplementProvides(
    program: ast.Program,
    target: []const u8,
    iname: []const u8,
    name: []const u8,
) bool {
    for (program.decls) |decl| {
        const impl = switch (decl) {
            .implement => |i| i,
            else => continue,
        };
        if (!std.mem.eql(u8, impl.target, target)) continue;
        if (!implementsInterface(impl, iname)) continue;
        for (impl.methods) |m| {
            if (!std.mem.eql(u8, m.name, name)) continue;
            const q = m.qualifier orelse return true;
            if (std.mem.eql(u8, q, iname)) return true;
        }
    }
    return false;
}

/// True when interface `d` declares a method named `name` (abstract or default).
fn interfaceHasMethod(d: ast.BehaviorDecl, name: []const u8) bool {
    for (d.methods) |m| {
        if (std.mem.eql(u8, m.name, name)) return true;
    }
    return false;
}

/// The bare name of an interface type ref — the identifier the interface was
/// declared under. Generic interfaces (`Iface<A, B>`, `@Context<…>`) reduce to
/// their head name (`Iface`, `Context`); non-name refs yield "".
fn interfaceRefName(ref: ast.TypeRef) []const u8 {
    return switch (ref) {
        .named => |n| n,
        .generic => |g| g.name,
        else => "",
    };
}

/// True when `name` is one of the interfaces this implement block declares.
fn implementsInterface(impl: ast.ImplementDecl, name: []const u8) bool {
    for (impl.interfaces) |iface| {
        if (std.mem.eql(u8, interfaceRefName(iface), name)) return true;
    }
    return false;
}

fn validateImplement(
    env: *Env,
    impl: ast.ImplementDecl,
    interfaces: std.StringHashMap(ast.BehaviorDecl),
) InferError!void {
    // Per-method checks: qualifier validity, method existence, ambiguity.
    for (impl.methods) |m| {
        if (m.qualifier) |q| {
            // The qualifier must name an interface this block implements.
            if (!implementsInterface(impl, q)) {
                env.lastError = TypeError.unknownInterface(q, m.name);
                return error.TypeError;
            }
            // If the interface is visible, it must declare the method.
            if (interfaces.get(q)) |d| {
                if (!interfaceHasMethod(d, m.name)) {
                    env.lastError = TypeError.unknownMethod(impl.target, m.name);
                    return error.TypeError;
                }
            }
        } else {
            // Unqualified: find which implemented interfaces declare this method.
            var first: ?[]const u8 = null;
            var second: ?[]const u8 = null;
            for (impl.interfaces) |iface| {
                const iname = interfaceRefName(iface);
                const d = interfaces.get(iname) orelse continue;
                if (!interfaceHasMethod(d, m.name)) continue;
                if (first == null) {
                    first = iname;
                } else if (second == null) {
                    second = iname;
                }
            }
            if (first == null) {
                env.lastError = TypeError.unknownMethod(impl.target, m.name);
                return error.TypeError;
            }
            if (second) |snd| {
                env.lastError = TypeError.ambiguousMethod(m.name, first.?, snd);
                return error.TypeError;
            }
        }
    }

    // Coverage: every abstract method of every implemented interface must be met.
    for (impl.interfaces) |iface| {
        const iname = interfaceRefName(iface);
        const d = interfaces.get(iname) orelse continue;
        for (d.methods) |am| {
            if (am.body != null) continue; // default method — implementing it is optional
            var covered = false;
            for (impl.methods) |m| {
                if (!std.mem.eql(u8, m.name, am.name)) continue;
                if (m.qualifier) |q| {
                    if (std.mem.eql(u8, q, iname)) {
                        covered = true;
                        break;
                    }
                } else {
                    covered = true;
                    break;
                }
            }
            if (!covered) {
                env.lastError = TypeError.missingMethod(impl.target, iname, am.name);
                return error.TypeError;
            }
        }
    }
}

/// Resolve the declared type of struct field `name`, or null when there is no
/// field with that name (e.g. a computed getter that backs no field).
fn structFieldType(
    env: *Env,
    s: ast.StructDecl,
    genericMap: std.StringHashMap(*T.Type),
    name: []const u8,
) InferError!?*T.Type {
    for (s.members) |m| switch (m) {
        .field => |f| if (std.mem.eql(u8, f.name, name)) {
            return try resolveFieldType(env, f, genericMap);
        },
        else => {},
    };
    return null;
}

/// Check that each getter/setter named after a field agrees with that field's
/// type: a getter must return the field type, a setter must accept it.
fn validateStructAccessors(env: *Env, s: ast.StructDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    for (s.genericParams) |gp| {
        try genericMap.put(gp.name, try env.freshVar());
    }

    for (s.members) |m| switch (m) {
        .getter => |g| {
            const fieldTy = (try structFieldType(env, s, genericMap, g.name)) orelse continue;
            const retTy = try env.resolveTypeName(g.returnType, genericMap);
            try unify(env, fieldTy, retTy);
        },
        .setter => |st| {
            const fieldTy = (try structFieldType(env, s, genericMap, st.name)) orelse continue;
            // The value parameter follows `self`; skip malformed setters.
            if (st.params.len < 2) continue;
            const valueParam = st.params[st.params.len - 1];
            const valueTy = try resolveTypeRefInContext(env, valueParam.typeRef, genericMap);
            try unify(env, fieldTy, valueTy);
        },
        else => {},
    };
}

// ── stdlib preload ────────────────────────────────────────────────────────────

/// Parse and register all stdlib interface declarations into `env`.
///
/// The three stdlib source files are embedded at compile time via `@embedFile`.
/// Each file is lexed and parsed in a temporary arena that is freed immediately
/// after inference; the resulting type bindings live in `env.arena`.
fn inferDeclTyped(env: *Env, decl: ast.DeclKind) InferError!?TypedBinding {
    switch (decl) {
        .val => |v| {
            // 01 R8 — `ValDecl` carries no location for its annotation; an
            // unlocated refusal there reds at the value.
            const annType: ?*T.Type = if (v.typeAnnotation) |ann|
                resolveTypeRef(env, ann) catch |err| return locateTypeRefError(env, err, v.value.getLoc())
            else
                null;
            // When binding a lambda to a `fn(...) -> ...` annotation, feed the
            // annotation into the lambda so its params are typed from context.
            const typedExpr = if (annType != null and v.value.* == .function)
                try inferFunctionExprExpected(env, v.value.function, v.value.function.loc, annType, false)
            else
                // 00 · 01-checker — the annotation is this position's expected
                // type, so `val t: Token = .Color.Red.500;` resolves the path
                // on `Token`.
                try inferExprTypedExpecting(env, v.value.*, annType);
            const ty = typedExpr.getType();
            if (annType) |at| try unifyAt(env, at, ty, v.value.getLoc());
            // The annotation is the DECLARED type — bind it, not the RHS type
            // (`val head: ?i32 = 5;` must bind `?i32`, or a later
            // `option.map(head, f)` sees a bare `i32`).
            const bindTy = annType orelse ty;
            try validateMemoryAnnotations(env, v, bindTy);
            try noteTypeValue(env, v.name, v.value.*, annType == null and !v.mutable);
            if (v.mutable) try env.bind(v.name, bindTy) else try env.bindVal(v.name, bindTy);
            return .{ .name = v.name, .type_ = bindTy, .typedExpr = typedExpr, .decl = decl };
        },
        .@"fn" => |f| {
            const ty = try inferFnDecl(env, f);
            try env.bind(f.name, ty);
            return .{ .name = f.name, .type_ = ty, .typedExpr = null, .decl = decl };
        },
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => {
                const typeName = try buildRecordDeclName(env, tdecl);
                const typeId = if (env.lookupTypeDef(tdecl.name)) |td| switch (td) {
                    .record => |rec| rec.id,
                    else => null,
                } else null;
                try inferTypeMethods(env, tdecl.name, tdecl.genericParams, tdecl.methods);
                return .{ .name = tdecl.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
            },
            .enum_ => {
                const typeName = try buildEnumDeclName(env, tdecl);
                const typeId = if (env.lookupTypeDef(tdecl.name)) |td| switch (td) {
                    .enum_ => |en| en.id,
                    else => null,
                } else null;
                try inferTypeMethods(env, tdecl.name, tdecl.genericParams, tdecl.methods);
                return .{ .name = tdecl.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
            },
        },
        .behavior => |d| {
            const typeName = try buildInterfaceDeclName(env, d);
            try registerInterfaceAssociatedFns(env, d);
            return .{ .name = d.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl };
        },
        // Handled in `inferProgramTyped` — each import name is looked up in env.
        // `from "std"` imports must be marked here too — the untyped path
        // (tests, LSP) otherwise leaves qualified-call receivers unbound.
        .use => |u| {
            _ = try markStdImports(env, u);
            return null;
        },
        // A test block produces no binding, but its body must type-check.
        .@"test" => |t| {
            try inferTestDecl(env, t);
            return null;
        },
        else => return null,
    }
}

// ── pass 1: type definition registration ─────────────────────────────────────

fn registerTypeDecl(env: *Env, decl: ast.DeclKind) InferError!void {
    switch (decl) {
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => try registerRecord(env, tdecl),
            .enum_ => try registerEnum(env, tdecl),
        },
        else => {},
    }
}

/// Pre-pass (mutual recursion): bind every top-level `fn`/`pub fn` name to its
/// signature type BEFORE any body is inferred, so a function can call another
/// declared later in the same module (`renderToString` ⇄ `renderChildren`).
///
/// A top-level function's signature is fully determined by its declared
/// parameter and return types plus generic params — the body never changes it —
/// so the type built here matches what `inferFnDecl` later derives when it walks
/// the body (which re-binds the same name for self-recursion). This mirrors how
/// recursive `record` type names are registered in pass 1 before any use.
fn registerFnSignatures(env: *Env, program: ast.Program) InferError!void {
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| {
            try env.bind(f.name, try buildFnSignatureType(env, f));
            // C-04 — the signature type drops the `default` expressions; keep
            // the parameters as written so a short call can be told from a
            // call missing a required argument.
            try env.fnParams.put(f.name, f.params);
            registerDecoratorSig(env, f.name, f.params, f);
            if (f.typeGuardParam) |paramName| {
                var paramIndex: usize = 0;
                for (f.params, 0..) |p, i| {
                    if (std.mem.eql(u8, p.name, paramName)) {
                        paramIndex = i;
                        break;
                    }
                }
                // 06 C5 — the narrowed type is its own slot; `returnType` is `bool`.
                const narrowedName: []const u8 = if (f.typeGuardType) |gt| switch (gt) {
                    .named => |n| n,
                    else => paramName,
                } else paramName;
                try env.typeGuardFns.put(f.name, .{ .paramIndex = paramIndex, .narrowedTypeName = narrowedName });
            }
        },
        // A `declare fn` decorator (`declare fn service(comptime _: @Decl)`) —
        // the bodyless form a lib ships its markers as — parses as a delegate.
        .delegate => |d| registerDecoratorSig(env, d.name, d.params, null),
        else => {},
    };
}

/// True when `params` open with `comptime _: @Decl`, the signature shape that
/// marks a function as a decorator (annotation processor). The core recognizes
/// decorators purely by this shape — it never knows what a marker means (that is
/// the lib's job). Applies to both `pub fn` and `declare fn` forms.
pub fn isDecoratorParams(params: []const ast.Param) bool {
    if (params.len == 0) return false;
    const p0 = params[0];
    return p0.modifier == .@"comptime" and p0.typeRef.isDeclType();
}

/// Register a decorator imported from another module — its full `FnDecl` (body
/// included) — into this module's decorator table, so `#[name(args)]` sites here
/// argument-check against it AND run its body over each annotated declaration at
/// comptime. Mirrors `registerImportedTemplateFn` for the `@Expr` template case;
/// the core stays lib-agnostic (it carries the decorator across modules by its
/// generic `@Decl`-first shape, never by any lib's name). No-op for non-decorators.
pub fn registerImportedDecorator(env: *Env, name: []const u8, fn_decl: ast.FnDecl) void {
    registerDecoratorSig(env, name, fn_decl.params, fn_decl);
}

/// Register an `implement` block imported and activated from another module
/// (`import { Name* } from "mod"`) into this module's extension table, so
/// `obj.method()` dispatches to it. Local extensions are auto-applied
/// ([[registerExtensions]]); imported ones are opt-in via the `*` activation —
/// they only land here when the importer asked for them. The dispatch table makes
/// no further local/imported distinction (every entry here is meant to resolve).
pub fn registerImportedExtension(env: *Env, im: ast.ImplementDecl) !void {
    try env.extensions.put(im.name, .{
        .name = im.name,
        .target = im.target,
        .interfaces = im.interfaces,
        .methods = try collectImplMethodNames(env, im.methods),
    });
}

/// Record a decorator's trailing signature (everything after the leading
/// `comptime _: @Decl`) so `#[name(args)]` applications can be argument-checked,
/// plus its full `FnDecl` (when it has a body) so the body can run over each
/// annotated declaration at comptime (P2). No-op for ordinary functions.
fn registerDecoratorSig(env: *Env, name: []const u8, params: []const ast.Param, fn_decl: ?ast.FnDecl) void {
    if (!isDecoratorParams(params)) return;
    env.decorators.put(name, .{ .params = params[1..], .fn_decl = fn_decl }) catch {};
}

/// True when a type's `implement` clause lists the builtin `@Annotation`
/// marker — the signal that a `record`/`struct`/`enum` may be used as an
/// annotation (`#[MyMarker(field: value)]` or, for an enum,
/// `#[@External.Variant(args)]`). Plain `Annotation` (no `@` prefix) is
/// matched too, since `implement` entries don't carry the builtin sigil.
fn implementsAnnotation(impls: []const ast.TypeRef) bool {
    for (impls) |t| switch (t) {
        .named => |n| if (std.mem.eql(u8, n, "Annotation")) return true,
        .generic => |g| if (std.mem.eql(u8, g.name, "Annotation")) return true,
        else => {},
    };
    return false;
}

/// Convert a record/struct/enum-variant field list into the `[]ast.Param`
/// shape `DecoratorSig` consumes. Field defaults flow through as `default`,
/// so the annotation argument validator applies them on a missing positional /
/// named arg — the same rule a fn-param default uses. The synthetic param
/// list lives in `env.arena`, so it outlives the registration call.
fn recordFieldsAsParams(env: *Env, fields: []const ast.Field) ![]ast.Param {
    var out = try env.arena.alloc(ast.Param, fields.len);
    for (fields, 0..) |f, i| {
        out[i] = .{
            .name = f.name,
            .typeRef = f.typeRef,
            .default = f.default,
        };
    }
    return out;
}

fn structFieldsAsParams(env: *Env, members: []const ast.StructMember) ![]ast.Param {
    var count: usize = 0;
    for (members) |m| if (m == .field) {
        count += 1;
    };
    var out = try env.arena.alloc(ast.Param, count);
    var i: usize = 0;
    for (members) |m| switch (m) {
        .field => |f| {
            out[i] = .{
                .name = f.name,
                .typeRef = f.typeRef,
                .default = f.init,
            };
            i += 1;
        },
        else => {},
    };
    return out;
}

fn enumVariantAsParams(env: *Env, variant: ast.EnumVariant) ![]ast.Param {
    var out = try env.arena.alloc(ast.Param, variant.fields.len);
    for (variant.fields, 0..) |f, i| {
        out[i] = .{
            .name = f.name,
            .typeRef = f.typeRef,
            .default = f.default,
        };
    }
    return out;
}

/// Register every `record`/`struct`/`enum` decl whose `implement` clause lists
/// `Annotation` as an annotation-style sig in `env.decorators`. Records and
/// structs go in under their bare name (`#[MyMarker(args)]`); each enum
/// variant goes in under the qualified path (`#[@External.Erlang(args)]` ⇒
/// `"External.Erlang"`). Skips ordinary types — the fn-shape `comptime _:
/// @Decl` decorator path keeps working untouched.
pub fn registerAnnotationTypes(env: *Env, program: ast.Program) InferError!void {
    for (program.decls) |decl| switch (decl) {
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => {
                if (!implementsAnnotation(tdecl.implement)) continue;
                const params = try recordFieldsAsParams(env, tdecl.recordFields());
                env.decorators.put(tdecl.name, .{ .params = params, .fn_decl = null }) catch {};
            },
            .enum_ => {
                if (!implementsAnnotation(tdecl.implement)) continue;
                for (tdecl.variants()) |v| {
                    const params = try enumVariantAsParams(env, v);
                    const qname = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ tdecl.name, v.name });
                    env.decorators.put(qname, .{ .params = params, .fn_decl = null }) catch {};
                }
            },
        },
        else => {},
    };
}

/// Build a top-level function's callable type (params → return) without binding
/// its parameters into `env` or inferring its body. Mirrors the signature half
/// of `inferFnDecl`: a generic map, `fn(...)`-param and ordinary-param
/// resolution, the return type, and generalization of declared generic params
/// the signature left unbound (so each call site instantiates them fresh).
fn buildFnSignatureType(env: *Env, f: ast.FnDecl) InferError!*T.Type {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    for (f.genericParams) |gp| {
        try genericMap.put(gp.name, try env.freshVar());
    }

    var paramTypes = try env.arena.alloc(*T.Type, f.params.len);
    for (f.params, 0..) |p, i| {
        paramTypes[i] = if (p.fnType) |ft| blk: {
            const fparams = try env.arena.alloc(*T.Type, ft.params.len);
            for (ft.params, 0..) |fp, j| {
                fparams[j] = genericMap.get(fp.typeName) orelse try env.namedType(fp.typeName);
            }
            const fret = if (ft.returnType) |rn|
                genericMap.get(rn) orelse try env.namedType(rn)
            else
                try env.namedType("void");
            break :blk try env.funcType(fparams, fret);
        } else try resolveParamType(env, p, genericMap);
    }

    const retType = if (f.returnType) |rt|
        try resolveReturnType(env, rt, f.returnTypeLoc, genericMap)
    else
        try env.namedType("void");

    // Generalize declared generic params the signature left unbound (same rule
    // as `inferFnDecl`): each becomes `.generic`, so use sites instantiate fresh.
    var git = genericMap.valueIterator();
    while (git.next()) |gv| {
        const resolved = gv.*.deref();
        if (resolved.* != .typeVar) continue;
        const cell = resolved.typeVar;
        switch (cell.state) {
            .unbound => |u| cell.state = .{ .generic = u.id },
            else => {},
        }
    }

    return env.funcType(paramTypes, retType);
}

/// Pre-pass for static extension dispatch: record inherent methods, register
/// named `implement`/`extend` blocks, collect activations, and validate
/// `implement` blocks against their interfaces.
///
/// Runs after type-definition registration (pass 1) and before expression
/// inference (pass 2) so `obj.method()` resolution sees the full picture.
fn registerExtensions(env: *Env, program: ast.Program) InferError!void {
    // Note: `implement`-vs-interface coverage (extra/missing methods) is validated
    // by `validateProgram`; this pre-pass only builds the dispatch tables.

    // Inherent methods + extension entries.
    for (program.decls) |decl| {
        switch (decl) {
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => for (tdecl.methods) |im| try env.addInherentMethod(tdecl.name, im.name),
                .enum_ => for (tdecl.methods) |im| try env.addInherentMethod(tdecl.name, im.name),
            },
            .implement => |im| {
                try env.extensions.put(im.name, .{
                    .name = im.name,
                    .target = im.target,
                    .interfaces = im.interfaces,
                    .methods = try collectImplMethodNames(env, im.methods),
                });
                // Bind the symbol as a value so a qualified call `Sym.m(obj)` can
                // infer `Sym` as its receiver expression (it names a namespace of
                // methods, not a typed value — a fresh var types it permissively).
                try env.bind(im.name, try env.freshVar());
            },
            .extend => |ex| {
                // Rule A: methods are added to a type only through `implement
                // <Interface> for T`, which `validateImplement` checks against the
                // interface. A contract-free `extend` block is rejected.
                env.lastError = TypeError.extendRequiresInterface(ex.target);
                return error.TypeError;
            },
            else => {},
        }
    }

    // Activations carried by `use` declarations: an `import { name* } from "…"`
    // opts an *imported* extension into scope, while a bare `name*;`
    // (`activationOnly`) names a local symbol. Rule B: a locally-declared
    // extension is auto-applied in its module, so a bare `name*;` is never needed.
    for (program.decls) |decl| {
        switch (decl) {
            .use => |u| for (u.imports) |imp| {
                if (!imp.activate) continue;
                const nm = imp.name();
                if (u.activationOnly) {
                    // `*` is only for imports. A bare statement is redundant when it
                    // names a local extension, and otherwise names no extension.
                    env.lastError = if (env.extensions.contains(nm))
                        TypeError.redundantActivation(nm)
                    else
                        TypeError.notAnExtension(nm);
                    return error.TypeError;
                }
                try env.activations.put(nm, {});
            },
            else => {},
        }
    }
}

/// Build the V1 origin-scope snapshot for the module being inferred: every
/// top-level declaration plus imported names, mapped to a `BindingKind`
/// (expr-templates F4). The snapshot is attached to every `expr` capture so
/// template functions can `lookup` names in the *caller's* scope — function
/// locals are not visible (V1 limit recorded in the spec).
///
/// Runs after `resolveImports` (comptime.zig) bound the imports, so an
/// imported name's kind is derived from its bound type (`fn` vs value).
fn buildScopeSnapshot(env: *Env, program: ast.Program) InferError!void {
    const snap = template.ScopeSnapshot.init(env.arena, env.modulePath) catch return error.OutOfMemory;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| try snap.put(f.name, .fn_, false),
        .val => |v| try snap.put(v.name, .val, false),
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => try snap.put(tdecl.name, .struct_, false),
            .enum_ => try snap.put(tdecl.name, .enum_, false),
        },
        .behavior => |i| try snap.put(i.name, .interface, false),
        .use => |u| for (u.imports) |imp| {
            const name = imp.name();
            const kind: template.BindingKind = blk: {
                const ty = env.lookup(name) orelse break :blk .val;
                break :blk if (ty.deref().* == .func) .fn_ else .val;
            };
            try snap.put(name, kind, true);
        },
        else => {},
    };
    env.scopeSnapshot = snap;
}

fn collectImplMethodNames(env: *Env, methods: []const ast.ImplementMethod) ![]const []const u8 {
    var names = try env.arena.alloc([]const u8, methods.len);
    for (methods, 0..) |m, i| names[i] = m.name;
    return names;
}

fn extractImplementNames(arena: std.mem.Allocator, impls: []const ast.TypeRef) ![]const []const u8 {
    if (impls.len == 0) return &.{};
    var names = try arena.alloc([]const u8, impls.len);
    for (impls, 0..) |im, i| {
        names[i] = switch (im) {
            .named => |n| n,
            .generic => |g| g.name,
            else => "unknown",
        };
    }
    return names;
}

/// Render a `TypeRef` to its source-level string form (heap-allocated in `arena`).
fn typeRefToString(arena: std.mem.Allocator, ref: ast.TypeRef) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try appendTypeRefStr(&buf, arena, ref);
    return buf.toOwnedSlice(arena);
}

/// If any of `impls` is `@Context<B, R>`, return the rendered `ContextBase` (`B`).
/// Returns null when the type does not implement `@Context`.
fn contextBaseFromImplements(arena: std.mem.Allocator, impls: []const ast.TypeRef) !?[]const u8 {
    for (impls) |im| {
        switch (im) {
            .generic => |g| if (std.mem.eql(u8, g.name, "Context")) {
                if (g.args.len >= 1) return try typeRefToString(arena, g.args[0]);
                return null;
            },
            else => {},
        }
    }
    return null;
}

/// True for an effect whose return type *wraps* the value the body produces
/// (`#[@future]` → `@Future<T>`, `#[@result]` → `@Result<D, E>`, …). `#[@context]`
/// is the one effect that does not: it names the activation capability itself,
/// and its return type is the owner (decision 88). Decision 90 reads this
/// predicate — a wrapper effect whose unwrapped return type owns a context
/// activates hooks on its own, since the wrapper says nothing about activation.
fn isWrapperEffect(eff: ast.EffectKind) bool {
    return eff != .context;
}

/// Look through a wrapper return type to the type that owns the context.
/// Decision 89 — **only** `@Future<T>` is unwrapped, and only one level: a
/// `#[@future] fn … -> @Future<Element>` has owner `Element`, so a hook declared
/// `-> @Context<Element, R>` is type-legal in it. Every other return type,
/// wrapper or not, is its own owner.
fn unwrapContextOwner(retType: ast.TypeRef) ast.TypeRef {
    return switch (retType) {
        .generic => |g| if (std.mem.eql(u8, g.name, "Future") and g.args.len >= 1)
            g.args[0]
        else
            retType,
        else => retType,
    };
}

/// Derive the `@Context` capability of a function from its declared return type.
/// The owner is read after `unwrapContextOwner` (decision 89 — through `@Future<T>`
/// to `T`), and implements `@Context` either directly (`@Context<B, R>`) or via a
/// named type whose inline `implement` clause lists `@Context<B, R>` — the owner
/// type of a component (`#[@context] fn Widget() -> Element`, decision 88).
/// `eff` is the fn's effect annotation and decides `annotated`, the second half of
/// the capability — a body activates a hook only when its return type owns a
/// context **and** `annotated` is true (`inferUseHookExpr`). `annotated` is set by
/// `#[@context]`, **or** (decision 90) by a wrapper effect whose unwrapped return
/// type owns a context: `#[@future] fn Page() -> @Future<Element>` activates
/// without a second annotation, which R5 forbids spelling anyway. A fn with no
/// effect annotation, or one whose return owns no context, is untouched by this:
/// the two refusals of decision 67 still fire.
fn contextInfoFromReturn(env: *Env, retType: ?ast.TypeRef, eff: ?ast.EffectKind, fnName: []const u8) InferError!envMod.FnContext {
    const display = if (retType) |rt| try typeRefToString(env.arena, rt) else "void";
    const contextAnnotated = eff == .context;
    const wrapperEffect = if (eff) |e| isWrapperEffect(e) else false;
    // Decision 90 — the owner answers the question the annotation would have.
    const ownerActivates = contextAnnotated or wrapperEffect;
    if (retType) |rt| switch (unwrapContextOwner(rt)) {
        .generic => |g| if (std.mem.eql(u8, g.name, "Context")) {
            const base = if (g.args.len >= 1) try typeRefToString(env.arena, g.args[0]) else null;
            return .{ .implementsContext = true, .base = base, .returnDisplay = display, .annotated = ownerActivates, .fnName = fnName };
        },
        .named => |n| if (env.lookupTypeDef(n)) |td| {
            if (td.contextBase()) |b| return .{ .implementsContext = true, .base = b, .returnDisplay = display, .annotated = ownerActivates, .fnName = fnName };
        },
        else => {},
    };
    return .{ .implementsContext = false, .base = null, .returnDisplay = display, .annotated = contextAnnotated, .fnName = fnName };
}

/// The display name of a `ContextBase` type (a phantom, typically a plain named type).
fn baseNameOfType(ty: *T.Type) ?[]const u8 {
    return switch (ty.deref().*) {
        .named => |n| n.name,
        else => null,
    };
}

/// The `ContextBase` of an inferred type, if it implements `@Context`.
/// Handles both `@Context<B, R>` directly and named types implementing it inline.
fn contextBaseOfType(env: *Env, ty: *T.Type) ?[]const u8 {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| blk: {
            if (std.mem.eql(u8, n.name, "Context")) {
                break :blk if (n.args.len >= 1) baseNameOfType(n.args[0]) else null;
            }
            if (env.lookupTypeDef(n.name)) |td| break :blk td.contextBase();
            break :blk null;
        },
        else => null,
    };
}

/// The type a `use` binding destructures from: the `Return` (`R`) of `@Context<B, R>`
/// when the hook's type is `@Context`, or the type itself for a named context type.
fn bindingSourceType(ty: *T.Type) *T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Context") and n.args.len >= 2) n.args[1] else ty,
        else => ty,
    };
}

fn registerRecord(env: *Env, r: ast.TypeDecl) InferError!void {
    // Build generic param map: each param name → fresh generic type var.
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, r.genericParams.len);
    for (r.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    // Resolve each field's type.
    var fields = try env.arena.alloc(envMod.FieldDef, r.recordFields().len);
    for (r.recordFields(), 0..) |f, i| {
        fields[i] = .{
            .name = f.name,
            .type_ = try resolveFieldType(env, f, genericMap),
        };
    }

    // §1G — resolve each generic param's optional default into a `*T.Type`
    // against the same `genericMap` so a default that references an earlier
    // param (e.g. `<T, U = T>`) binds correctly.
    var genericDefaults = try env.arena.alloc(?*T.Type, r.genericParams.len);
    for (r.genericParams, 0..) |gp, i| {
        genericDefaults[i] = if (gp.default) |dft|
            try resolveTypeRefInContext(env, dft, genericMap)
        else
            null;
    }

    // Register the type definition.
    const typeId = env.allocTypeId();
    const implNames = try extractImplementNames(env.arena, r.implement);
    const ctxBase = try contextBaseFromImplements(env.arena, r.implement);
    try env.registerTypeDef(r.name, .{ .record = .{
        .name = r.name,
        .id = typeId,
        .genericParams = genericIds,
        .genericDefaults = genericDefaults,
        .fields = fields,
        .implements = implNames,
        .contextBase = ctxBase,
    } });

    // Build constructor function type: `fn(T1, T2, ...) -> RecordName<A,B,...>`.
    // The return type carries the generic type vars so that after call-site
    // unification `typeNameOf` can display the instantiated form, e.g. `Pair<Int,String>`.
    var paramTypes = try env.arena.alloc(*T.Type, r.recordFields().len);
    for (fields, 0..) |f, i| paramTypes[i] = f.type_;
    var retArgs = try env.arena.alloc(*T.Type, r.genericParams.len);
    for (r.genericParams, 0..) |gp, i| retArgs[i] = genericMap.get(gp.name).?;
    const retType = try env.namedTypeArgs(r.name, retArgs);
    const ctorType = try env.funcType(paramTypes, retType);
    try env.bind(r.name, ctorType);

    // Constructor params (F4 fn-param-default-expansion): every record field
    // is also a ctor param; expose its `default` Expr to the transform pass so
    // `expandTrailingDefaults` injects missing trailing defaults at the
    // `Config(...)` call site. Same rule as fn-decl call defaults.
    try env.ctorParams.put(r.name, try recordFieldsAsParams(env, r.recordFields()));

    // Inherent method signatures (self = the record instance type).
    try registerInherentMethodTypes(env, r.name, retType, &genericMap, r.methods);
}

/// Resolve and store the signatures of a type's inherent methods so a later
/// `recv.method(args)` call can recover the method's real return type (instead
/// of a fresh var). `instanceType` is what `Self` resolves to — the type
/// applied to its own generic cells; `typeGenerics` maps the type's generic
/// param names to those cells. The stored signature is self-first:
/// `fn(self: Instance, params…) -> Ret`. `makeMethodCall` instantiates it per
/// call site, so the shared cells never collapse across calls.
fn registerInherentMethodTypes(
    env: *Env,
    typeName: []const u8,
    instanceType: *T.Type,
    typeGenerics: *const std.StringHashMap(*T.Type),
    methods: []const ast.BehaviorMethod,
) InferError!void {
    for (methods) |im| {
        // Register the method NAME for dispatch. This runs from registerRecord/
        // /Struct/Enum, so it also covers types brought in by `import … from
        // "std"` (which `registerExtensions` never sees — it only scans the
        // local program's decls).
        try env.addInherentMethod(typeName, im.name);
        // C-04 — and its parameters as written. This runs BEFORE the
        // return-type gate below: a method without an annotated return still
        // has declared defaults, and its call sites still have to fill them.
        try env.setInherentMethodParams(typeName, im.name, im.params);

        // Only methods with an explicit return-type annotation get a stored
        // signature. Without one the true return type comes from body inference
        // (not available here), so we leave such calls to the fresh-var fallback
        // rather than mis-typing them as `void`.
        const retRef = im.returnType orelse continue;
        // Per-method generic scope: the type's generics + `Self` + the method's
        // own generic params (fresh vars).
        var gm = std.StringHashMap(*T.Type).init(env.arena);
        defer gm.deinit();
        var git = typeGenerics.iterator();
        while (git.next()) |e| try gm.put(e.key_ptr.*, e.value_ptr.*);
        try gm.put("Self", instanceType);
        for (im.genericParams) |gp| try gm.put(gp.name, try env.freshVar());

        const params = try env.arena.alloc(*T.Type, im.params.len);
        for (im.params, 0..) |p, i| {
            params[i] = if (p.fnType) |ft| blk: {
                const fparams = try env.arena.alloc(*T.Type, ft.params.len);
                for (ft.params, 0..) |fp, j| {
                    fparams[j] = gm.get(fp.typeName) orelse try env.namedType(fp.typeName);
                }
                const fret = if (ft.returnType) |rn|
                    gm.get(rn) orelse try env.namedType(rn)
                else
                    try env.namedType("void");
                break :blk try env.funcType(fparams, fret);
            } else try resolveParamType(env, p, gm);
        }
        const ret = try resolveReturnType(env, retRef, im.returnTypeLoc, gm);
        try env.setInherentMethodType(typeName, im.name, try env.funcType(params, ret));
    }
}

/// Register an interface's associated functions — `default fn` members with no
/// `self` receiver (`Pair.of`, `Function.compose`, `Array.range`) — under the
/// qualified name `"<Interface>.<method>"`, so `inferCallExpr` can resolve a
/// `Interface.method(...)` call as a callable. Interface + method generics are
/// generalized to `.generic`, so each call site instantiates fresh vars
/// (let-polymorphism, same as top-level generic fns). Methods that take a `self`
/// receiver are instance methods (handled by the inherent-method machinery) and
/// are skipped here.
fn registerInterfaceAssociatedFns(env: *Env, d: ast.BehaviorDecl) InferError!void {
    // Record EVERY interface decl so codegen can emit its namespace/prototype
    // when used, and the dispatch can follow the `extends` chain (markers like
    // `I32 extends Signed` carry no methods but link the tower).
    try env.assocInterfaceDecls.put(d.name, d);
    for (d.methods) |im| {
        const has_self = im.params.len > 0 and std.mem.eql(u8, im.params[0].name, "self");
        if (has_self) continue;

        var gm = std.StringHashMap(*T.Type).init(env.arena);
        defer gm.deinit();
        for (d.genericParams) |gp| try gm.put(gp.name, try env.freshVar());
        for (im.genericParams) |gp| try gm.put(gp.name, try env.freshVar());

        const params = try env.arena.alloc(*T.Type, im.params.len);
        for (im.params, 0..) |p, i| {
            params[i] = if (p.fnType) |ft| blk: {
                const fparams = try env.arena.alloc(*T.Type, ft.params.len);
                for (ft.params, 0..) |fp, j| {
                    fparams[j] = gm.get(fp.typeName) orelse try env.namedType(fp.typeName);
                }
                const fret = if (ft.returnType) |rn|
                    gm.get(rn) orelse try env.namedType(rn)
                else
                    try env.namedType("void");
                break :blk try env.funcType(fparams, fret);
            } else try resolveParamType(env, p, gm);
        }
        const ret = if (im.returnType) |rt|
            try resolveReturnType(env, rt, im.returnTypeLoc, gm)
        else
            try env.namedType("void");
        const fnTy = try env.funcType(params, ret);

        // Generalize remaining unbound generics → `.generic`.
        var git = gm.valueIterator();
        while (git.next()) |gv| {
            const resolved = gv.*.deref();
            if (resolved.* != .typeVar) continue;
            switch (resolved.typeVar.state) {
                .unbound => |u| resolved.typeVar.state = .{ .generic = u.id },
                else => {},
            }
        }

        const qname = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ d.name, im.name });
        try env.bind(qname, fnTy);
    }
}

/// Infer a call to an interface associated function (`Pair.of(a, b)`). `fnTy` is
/// the registered signature (`.generic` params); each call instantiates fresh
/// vars, unifies them with the args, and yields the instantiated return type.
fn inferAssociatedFnCall(
    env: *Env,
    recvName: []const u8,
    callee: []const u8,
    fnTy: *T.Type,
    typedReceiver: ?*ast.TypedExpr,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!TypedExpr {
    // Mark the interface used so codegen emits its namespace object.
    try env.usedAssocInterfaces.put(recvName, {});
    const inst = (try instantiateGenericType(env, fnTy)).deref();
    if (inst.* != .func) {
        env.lastError = TypeError.custom("not an associated function", "").withLoc(loc);
        return error.TypeError;
    }
    const fp = inst.func.params;
    const total = typedArgs.len + typedTrailing.len;
    if (total != fp.len) {
        env.lastError = TypeError.arityMismatch(callee, fp.len, total).withLoc(loc);
        return error.TypeError;
    }
    for (typedArgs, 0..) |arg, i| {
        try unifyAt(env, fp[i], arg.value.getType(), arg.value.getLoc());
    }
    // Trailing lambdas fill the remaining params; unify a fresh fn shape.
    for (typedTrailing, 0..) |tl, i| {
        const lamParams = try env.arena.alloc(*T.Type, tl.params.len);
        for (lamParams) |*lp| lp.* = try env.freshVar();
        try unifyAt(env, fp[typedArgs.len + i], try env.funcType(lamParams, try env.freshVar()), loc);
    }
    return TypedExpr{ .call = .{ .loc = loc, .type_ = inst.func.ret, .kind = .{ .call = .{
        .receiver = typedReceiver,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

fn registerStruct(env: *Env, s: ast.StructDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, s.genericParams.len);
    for (s.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    // Collect non-private fields.
    var fieldCount: usize = 0;
    for (s.members) |m| switch (m) {
        .field => fieldCount += 1,
        else => {},
    };

    var fields = try env.arena.alloc(envMod.FieldDef, fieldCount);
    var fi: usize = 0;
    for (s.members) |m| switch (m) {
        .field => |f| {
            fields[fi] = .{
                .name = f.name,
                .type_ = try resolveFieldType(env, f, genericMap),
            };
            fi += 1;
        },
        else => {},
    };

    // §1G — resolve generic defaults against the same map.
    var genericDefaults = try env.arena.alloc(?*T.Type, s.genericParams.len);
    for (s.genericParams, 0..) |gp, i| {
        genericDefaults[i] = if (gp.default) |dft|
            try resolveTypeRefInContext(env, dft, genericMap)
        else
            null;
    }

    const structTypeId = env.allocTypeId();
    const implNames = try extractImplementNames(env.arena, s.implement);
    const ctxBase = try contextBaseFromImplements(env.arena, s.implement);
    try env.registerTypeDef(s.name, .{ .struct_ = .{
        .name = s.name,
        .id = structTypeId,
        .genericParams = genericIds,
        .genericDefaults = genericDefaults,
        .fields = fields,
        .implements = implNames,
        .contextBase = ctxBase,
    } });

    var paramTypes = try env.arena.alloc(*T.Type, fields.len);
    for (fields, 0..) |f, i| paramTypes[i] = f.type_;
    const retType = try env.namedType(s.name);
    const ctorType = try env.funcType(paramTypes, retType);
    try env.bind(s.name, ctorType);

    // Constructor params (F4 fn-param-default-expansion): mirror registerRecord.
    try env.ctorParams.put(s.name, try structFieldsAsParams(env, s.members));

    // Inherent method signatures (self = the struct instance, bare name to
    // match the constructor's return type).
    var structMethods: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
    defer structMethods.deinit(env.arena);
    for (s.members) |m| switch (m) {
        .method => |im| try structMethods.append(env.arena, im),
        else => {},
    };
    try registerInherentMethodTypes(env, s.name, retType, &genericMap, structMethods.items);
}

fn registerEnum(env: *Env, e: ast.TypeDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, e.genericParams.len);
    for (e.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    // §enum-sections F1 — synthesise one inner enum per section under a mangled
    // path-encoded name (`__<EnumName>__<SectionPath>`) and surface them on the
    // parent as wrapper variants `Section(__EnumName__Section)`. The synthesised
    // enums live in the type-def table only — their constructor names are NOT
    // bound at the top level; path-access (`.Section.Inner.Leaf`) lowers to the
    // wrapped form during expression inference (F2).
    var section_wrappers = try env.arena.alloc(envMod.VariantDef, e.sections().len);
    for (e.sections(), 0..) |sec, si| {
        const inner_name = try registerEnumSection(env, e.name, &.{}, sec);
        const wrapper_field = try env.arena.alloc(envMod.FieldDef, 1);
        wrapper_field[0] = .{ .name = "_inner", .type_ = try env.namedType(inner_name) };
        section_wrappers[si] = .{ .name = sec.name, .fields = wrapper_field };
    }

    // F4G-tail — variant ctor return type carries the enum's generic cells, so
    // a call site sees `Result2<T_cell, E_cell>` and unification at the use site
    // pins each cell (e.g. `Result2.Yes(42)` binds T_cell = i32) AND a
    // function-return annotation that omits trailing args (`-> Result2<i32>`
    // with `E = string` default) resolves to the same arity. Without the
    // args the ctor would produce bare `Result2` and the unifier would see
    // arity mismatch against the defaults-filled annotation.
    var ctorRetArgs = try env.arena.alloc(*T.Type, e.genericParams.len);
    for (e.genericParams, 0..) |gp, i| ctorRetArgs[i] = genericMap.get(gp.name).?;
    const ctorRetType = if (e.genericParams.len == 0)
        try env.namedType(e.name)
    else
        try env.namedTypeArgs(e.name, ctorRetArgs);

    var variants = try env.arena.alloc(envMod.VariantDef, e.variants().len + section_wrappers.len);
    for (e.variants(), 0..) |v, vi| {
        var fields = try env.arena.alloc(envMod.FieldDef, v.fields.len);
        for (v.fields, 0..) |f, fi| {
            fields[fi] = .{
                .name = f.name,
                .type_ = try resolveFieldType(env, f, genericMap),
            };
        }
        variants[vi] = .{ .name = v.name, .fields = fields };

        // Each variant is also a constructor: unit → `EnumName<...>`, payload
        // → `fn(T...) → EnumName<...>`.
        const ctorType = if (v.fields.len == 0)
            ctorRetType
        else blk: {
            var ps = try env.arena.alloc(*T.Type, v.fields.len);
            for (fields, 0..) |f, i| ps[i] = f.type_;
            break :blk try env.funcType(ps, ctorRetType);
        };
        try env.bind(v.name, ctorType);

        // Constructor params (F4 fn-param-default-expansion): register the
        // variant under both its bare name (`Error`) and the qualified path
        // (`Level.Error`) so transform's `expandTrailingDefaults` finds it for
        // either call shape — `Error("boom")` or `Level.Error("boom")`.
        const variant_params = try enumVariantAsParams(env, v);
        try env.ctorParams.put(v.name, variant_params);
        const qname = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ e.name, v.name });
        try env.ctorParams.put(qname, variant_params);
    }
    // Append the section wrappers after the bare variants — order is irrelevant
    // for type-def semantics, but stable for snapshot determinism.
    for (section_wrappers, 0..) |w, wi| {
        variants[e.variants().len + wi] = w;
    }

    // §1G — resolve generic defaults against the same map.
    var genericDefaults = try env.arena.alloc(?*T.Type, e.genericParams.len);
    for (e.genericParams, 0..) |gp, i| {
        genericDefaults[i] = if (gp.default) |dft|
            try resolveTypeRefInContext(env, dft, genericMap)
        else
            null;
    }

    const enumTypeId = env.allocTypeId();
    const implNames = try extractImplementNames(env.arena, e.implement);
    const ctxBase = try contextBaseFromImplements(env.arena, e.implement);
    try env.registerTypeDef(e.name, .{ .enum_ = .{
        .name = e.name,
        .id = enumTypeId,
        .genericParams = genericIds,
        .genericDefaults = genericDefaults,
        .variants = variants,
        .implements = implNames,
        .contextBase = ctxBase,
    } });
    // Bind the enum name itself so `inferDecl` can look it up.
    const enumInstance = try env.namedType(e.name);
    try env.bind(e.name, enumInstance);

    // Inherent method signatures (self = the enum instance type).
    try registerInherentMethodTypes(env, e.name, enumInstance, &genericMap, e.methods);
}

/// Synthesise a single enum-section as a hidden inner enum. Walks nested
/// sections first (depth-first), then composes the section's own variant list
/// as: bare/payload variants from `sec.variants` (digit names get the `_`
/// prefix codegen needs) + wrapper variants for each nested sub-section. The
/// mangled name (`__<EnumName>__<Path>__<SectionName>`) is registered as a
/// `TypeDef.enum_` and returned for the caller to wrap.
fn registerEnumSection(
    env: *Env,
    enum_name: []const u8,
    parent_path: []const []const u8,
    sec: ast.EnumSection,
) InferError![]const u8 {
    // path = parent_path ++ [sec.name]
    var path = try env.arena.alloc([]const u8, parent_path.len + 1);
    for (parent_path, 0..) |p, i| path[i] = p;
    path[parent_path.len] = sec.name;

    // mangled = "__" + enum_name + "__" + path.join("__")
    var mbuf: std.ArrayList(u8) = .empty;
    try mbuf.appendSlice(env.arena, "__");
    try mbuf.appendSlice(env.arena, enum_name);
    for (path) |seg| {
        try mbuf.appendSlice(env.arena, "__");
        try mbuf.appendSlice(env.arena, seg);
    }
    const mangled = try mbuf.toOwnedSlice(env.arena);

    // Recurse into sub-sections first; collect their mangled names.
    var sub_wrappers = try env.arena.alloc(envMod.VariantDef, sec.sections.len);
    for (sec.sections, 0..) |sub, i| {
        const sub_name = try registerEnumSection(env, enum_name, path, sub);
        const f = try env.arena.alloc(envMod.FieldDef, 1);
        f[0] = .{ .name = "_inner", .type_ = try env.namedType(sub_name) };
        sub_wrappers[i] = .{ .name = sub.name, .fields = f };
    }

    var variants = try env.arena.alloc(envMod.VariantDef, sec.variants.len + sub_wrappers.len);
    for (sec.variants, 0..) |v, i| {
        var fields = try env.arena.alloc(envMod.FieldDef, v.fields.len);
        // Inner section variants do not see the parent's generic params — they
        // are concrete by construction. An empty map suffices.
        var empty_map = std.StringHashMap(*T.Type).init(env.arena);
        defer empty_map.deinit();
        for (v.fields, 0..) |f, fi| {
            fields[fi] = .{
                .name = f.name,
                .type_ = try resolveFieldType(env, f, empty_map),
            };
        }
        // Pure-digit leaves carry the underscore-prefixed name codegen expects.
        // `__` prefix (not single `_`) — `_500` would trip commonJS's
        // tuple-index heuristic (`t._N` → `t[N]`) and lower a variant
        // access to bracket-with-number `obj[500]`, which misses the
        // string-keyed `"_500"` slot. `__500` keeps the JS field-access
        // form `obj.__500` intact.
        const variant_name = if (v.numeric)
            try std.fmt.allocPrint(env.arena, "__{s}", .{v.name})
        else
            v.name;
        variants[i] = .{ .name = variant_name, .fields = fields };
    }
    for (sub_wrappers, 0..) |w, i| variants[sec.variants.len + i] = w;

    const type_id = env.allocTypeId();
    try env.registerTypeDef(mangled, .{ .enum_ = .{
        .name = mangled,
        .id = type_id,
        .genericParams = &.{},
        .genericDefaults = &.{},
        .variants = variants,
        .implements = &.{},
        .contextBase = null,
    } });

    // §enum-sections F4 — also build the matching AST enum TypeDecl so the
    // post-inference `withSynthesisedEnumDecls` pass can prepend it to
    // `program.decls`, giving codegen a top-level enum to emit (mirroring
    // the manually-written enum-of-enum form, byte-identical at codegen).
    try registerSynthesisedEnumDecl(env, mangled, sec, sub_wrappers);

    return mangled;
}

/// §enum-sections F4 — assemble the AST enum `TypeDecl` for a synthesised inner
/// enum (the one `registerEnumSection` just registered under `mangled`). The
/// decl carries the section's bare/payload variants (`sec.variants`, with the
/// `_` prefix on numeric leaves matching the F1 mangling) followed by one
/// wrapper variant per sub-section (`{ name: <SubSection>, fields: [{name:
/// "_inner", typeRef: named "__Enum__Path__SubSection"}] }`). The decl lands
/// in `env.synthesisedEnumDecls` keyed by `mangled` — a later post-pass
/// inlines it into the program's top-level decls so codegen emits it normally.
fn registerSynthesisedEnumDecl(
    env: *Env,
    mangled: []const u8,
    sec: ast.EnumSection,
    sub_wrappers: []const envMod.VariantDef,
) InferError!void {
    var ast_variants = try env.arena.alloc(ast.EnumVariant, sec.variants.len + sub_wrappers.len);
    for (sec.variants, 0..) |v, i| {
        // `__` prefix (not single `_`) — `_500` would trip commonJS's
        // tuple-index heuristic (`t._N` → `t[N]`) and lower a variant
        // access to bracket-with-number `obj[500]`, which misses the
        // string-keyed `"_500"` slot. `__500` keeps the JS field-access
        // form `obj.__500` intact.
        const variant_name = if (v.numeric)
            try std.fmt.allocPrint(env.arena, "__{s}", .{v.name})
        else
            v.name;
        // Copy the variant fields (the AST owns them by slice, so we reslice
        // through the arena to keep ownership clean even though the source
        // EnumSection still references them).
        const fields = try env.arena.alloc(ast.Field, v.fields.len);
        for (v.fields, 0..) |f, fi| fields[fi] = f;
        ast_variants[i] = .{ .name = variant_name, .fields = fields, .numeric = v.numeric };
    }
    // Wrapper variants for nested sub-sections — single `_inner` field typed
    // to the sub-section's mangled name. The sub_wrappers slice carries the
    // resolved inner types; we recover the mangled name from the FieldDef's
    // named type for the AST TypeRef.
    for (sub_wrappers, 0..) |w, i| {
        std.debug.assert(w.fields.len == 1);
        const inner_type = w.fields[0].type_.deref();
        std.debug.assert(inner_type.* == .named);
        const fields = try env.arena.alloc(ast.Field, 1);
        fields[0] = .{
            .name = "_inner",
            .typeRef = .{ .named = inner_type.named.name },
            .default = null,
        };
        ast_variants[sec.variants.len + i] = .{
            .name = w.name,
            .fields = fields,
            .numeric = false,
        };
    }
    const enum_decl = ast.TypeDecl{
        .name = mangled,
        .isPub = false,
        .shape = .{ .enum_ = .{ .variants = ast_variants } },
    };
    try env.synthesisedEnumDecls.put(mangled, enum_decl);
}

// ── §enum-sections F2 — path-access resolution ──────────────────────────────
//
// A dot-shorthand chain rooted at a `.dotIdent` (`.Color.Red.500`) may resolve
// as a section path on an enum carrying sections (F1 desugar). The first
// segment is matched against every registered enum's variants — when a hit
// names a section wrapper (the synthesised `Section(_inner: __Enum__Section)`
// variant), the rest of the path walks through the inner enum's variants
// recursively. Pure-digit leaves (`500`) are looked up under their
// underscore-prefixed name (`_500`) to match the synthesised mangling.
//
// The lowering builds nested constructor calls: `Color(Red(_500))` where each
// call carries the proper type from the enum it constructs.

/// Walk an `identAccess` chain rooted at a `.dotIdent`, collect segments from
/// head to leaf, and try to resolve them as a section path on some enum.
/// Returns `null` when the chain doesn't root at a dotIdent or no enum
/// matches the path. Takes the leaf member + receiver separately because the
/// `identAccess` payload is an anonymous struct, not a nameable type.
///
/// 00 · 01-checker — WHICH enum carries the path is decided by the expected
/// type (`env.expectedType`), never by the order `env.typeDefs` happens to
/// hand the enums over: that map holds the synthesised section enums beside
/// the declared ones, so `.Color.Red.500` is carried by emilia's `Token` and
/// by `__Token__Border` alike and the winner used to change with the size of
/// the typedef set.
fn tryResolveEnumSectionPath(
    env: *Env,
    leaf_member: []const u8,
    leaf_receiver: *const ast.Expr,
    loc: ast.Loc,
) InferError!?TypedExpr {
    // Collect chain segments by walking inward through nested identAccess.
    // Top-level call supplies the LEAF member; we walk inward to the root
    // `dotIdent` whose name is the FIRST segment.
    var segs: std.ArrayList([]const u8) = .empty;
    defer segs.deinit(env.arena);
    // The location of each segment's node, parallel to `segs` (N17 — the
    // caret of an unresolved path points at the offending segment).
    var segLocs: std.ArrayList(ast.Loc) = .empty;
    defer segLocs.deinit(env.arena);
    try segs.append(env.arena, leaf_member);
    try segLocs.append(env.arena, loc);
    var cur: *const ast.Expr = leaf_receiver;
    // The enum a fully qualified chain names outright (`Token.Color.Red.500`).
    var qualified_owner: ?envMod.TypeDef.Enum = null;
    while (true) {
        if (cur.* != .identifier) return null;
        switch (cur.*.identifier.kind) {
            .identAccess => |sub| {
                try segs.append(env.arena, sub.member);
                try segLocs.append(env.arena, cur.*.getLoc());
                cur = sub.receiver;
            },
            .dotIdent => |name| {
                try segs.append(env.arena, name);
                try segLocs.append(env.arena, cur.*.getLoc());
                break;
            },
            .ident => |name| {
                // 00 · 01-checker — the fully qualified spelling names its
                // enum: `Token.Color.Red.500`. The root identifier is the
                // owner and the rest of the chain is the path, so the one
                // spelling that carries the answer in itself is not refused.
                // A two-segment `Color.Red` is an ordinary variant access and
                // stays on the regular identAccess path below.
                if (segs.items.len < 2) return null;
                const td = env.lookupTypeDef(name) orelse return null;
                if (td != .enum_) return null;
                qualified_owner = td.enum_;
                break;
            },
        }
    }
    // segs is leaf→head; reverse to head→leaf for path walking.
    std.mem.reverse([]const u8, segs.items);
    std.mem.reverse(ast.Loc, segLocs.items);

    if (qualified_owner) |owner| {
        // The enum is named, so there is no candidate set and nothing to be
        // ambiguous about. A chain that turns out not to be a section path is
        // handed back to the ordinary identAccess handling, which reports it.
        if (!enumCarriesSectionPath(env, owner, segs.items)) return null;
        return try resolveAndRecordSectionPath(env, owner, segs.items, loc);
    }

    if (segs.items.len < 2) return null;

    // Collect EVERY registered enum whose top-level variant matches the head
    // segment AND whose section tree carries the rest of the path. The set,
    // not the first hit, is what the choice is made from.
    // Also remember the enum whose HEAD segment matched (`enum_with_head`)
    // so a partial-match path (head OK, tail wrong: `.Color.Bogus`) can
    // raise ES4 with a focused message instead of bubbling a confusing
    // generic "unknown field" error from the fall-through code.
    var candidates: std.ArrayList([]const u8) = .empty;
    defer candidates.deinit(env.arena);
    var enum_with_head: ?[]const u8 = null;
    var enum_def_with_head: ?envMod.TypeDef.Enum = null;
    var it = env.typeDefs.iterator();
    while (it.next()) |entry| {
        const td = entry.value_ptr.*;
        if (td != .enum_) continue;
        const en = td.enum_;
        if (enumCarriesSectionPath(env, en, segs.items)) {
            if (!containsStr(candidates.items, en.name)) try candidates.append(env.arena, en.name);
            continue;
        }
        // Did the head segment at least match a section wrapper on this
        // enum? If yes, the user intended a section path on this enum — a
        // bad tail is an ES4 candidate.
        if (enum_with_head == null and headSectionVariantOn(en, segs.items[0])) {
            enum_with_head = en.name;
            enum_def_with_head = en;
        }
    }

    if (candidates.items.len > 0) {
        // One carrier: the path names it. More than one: the expected type of
        // this position is what decides — an annotation, a declared parameter,
        // the return target, an array literal's element type.
        const chosen: ?[]const u8 = if (candidates.items.len == 1)
            candidates.items[0]
        else
            expectedEnumAmong(env.expectedType, candidates.items);
        if (chosen) |name| {
            const owner = env.lookupTypeDef(name).?.enum_;
            return try resolveAndRecordSectionPath(env, owner, segs.items, loc);
        }
        // ES5 — more than one enum carries the path and nothing here says
        // which. Refuse, naming every candidate: picking one is what made the
        // answer a function of the hash order, and the position that cannot
        // say what it expects is the position that has to spell it out.
        return raiseAmbiguousSectionPath(env, candidates.items, segs.items, segLocs.items[0]);
    }

    // ES4 — chain looks like a section path (`.<Section>.<more>` rooted at
    // a dotIdent, ≥ 2 segments) and the head matched a known section
    // wrapper, but the tail didn't resolve. Raise a focused error so the
    // user sees "enum 'Token' has no path '.Color.Bogus'" instead of the
    // generic fall-through diagnostic.
    if (enum_with_head) |owner| {
        const path_text = try sectionPathText(env, segs.items);
        const msg = try std.fmt.allocPrint(
            env.arena,
            "enum \"{s}\" has no path \"{s}\" (ES4 — enum-sections path resolution)",
            .{ owner, path_text },
        );
        const bad = firstUnresolvedSectionSegment(env, enum_def_with_head.?, segs.items);
        const badLoc = if (bad < segLocs.items.len) segLocs.items[bad] else loc;
        env.lastError = TypeError.custom(msg, "Check the section/variant chain against the enum declaration's `sections` tree; numeric leaves are matched under their declared digit form (`.Color.Red.500`).").withLoc(badLoc);
        return error.TypeError;
    }
    return null;
}

/// The chain as the user wrote it, leading dot and all: `.Color.Red.500`.
fn sectionPathText(env: *Env, path: []const []const u8) InferError![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(env.arena);
    for (path) |seg| {
        try buf.append(env.arena, '.');
        try buf.appendSlice(env.arena, seg);
    }
    return buf.toOwnedSlice(env.arena);
}

/// ES5 — the path is carried by more than one enum and nothing at this
/// position says which. Refuse, naming every candidate.
///
/// Picking one is what made the answer depend on `env.typeDefs`' hash order,
/// and a pick cannot be right here: the two enums are different types and the
/// program means one of them. The candidates are sorted so the message is the
/// same on every run — the set comes off a hash map.
fn raiseAmbiguousSectionPath(
    env: *Env,
    candidates: [][]const u8,
    path: []const []const u8,
    loc: ast.Loc,
) InferError!?TypedExpr {
    std.mem.sort([]const u8, candidates, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.order(u8, a, b) == .lt;
        }
    }.lessThan);
    var names: std.ArrayList(u8) = .empty;
    defer names.deinit(env.arena);
    for (candidates, 0..) |name, i| {
        if (i > 0) try names.appendSlice(env.arena, if (i + 1 == candidates.len) " and " else ", ");
        try names.append(env.arena, '"');
        try names.appendSlice(env.arena, name);
        try names.append(env.arena, '"');
    }
    const msg = try std.fmt.allocPrint(
        env.arena,
        "the path \"{s}\" is carried by more than one enum — {s} — and nothing here says which (ES5 — enum-sections path ambiguity)",
        .{ try sectionPathText(env, path), names.items },
    );
    env.lastError = TypeError.custom(
        msg,
        "Give the position a type the path can be read against — a `val` annotation, a declared parameter, the function's return type — or write the path from its enum (`Token.Color.Red.500`).",
    ).withLoc(loc);
    return error.TypeError;
}

/// Resolve `path` in `en` and record the untyped rewrite for it.
///
/// The rewrite is the equivalent qualified-ctor form, stashed under this
/// chain's outermost loc. The post-inference rewrite pass
/// (`withEnumSectionRewrites` in `comptime.zig`) walks the untyped AST and
/// swaps the original chain for it, so codegen — which reads the untyped AST —
/// emits `Token.Color(__Token__Color.Red(…))` instead of the source text.
fn resolveAndRecordSectionPath(
    env: *Env,
    en: envMod.TypeDef.Enum,
    path: []const []const u8,
    loc: ast.Loc,
) InferError!?TypedExpr {
    const resolved = try resolveSectionPathInEnum(env, en, path, loc) orelse return null;
    if (try buildSectionPathRewrite(env, en, path)) |rewrite| {
        try env.enumSectionRewrites.put(loc, rewrite);
    }
    return resolved;
}

/// The candidate `expected` names, or null when the expectation says nothing
/// about the choice (there is none, it is still a type variable, or it names
/// an enum that carries no such path). `?Token` answers `Token`: the
/// expectation of an optional position is the optional's inner type.
fn expectedEnumAmong(expected: ?*T.Type, candidates: []const []const u8) ?[]const u8 {
    var ty = (expected orelse return null).deref();
    if (ty.* == .named and std.mem.eql(u8, ty.named.name, "optional") and ty.named.args.len == 1) {
        ty = ty.named.args[0].deref();
    }
    if (ty.* != .named) return null;
    for (candidates) |c| if (std.mem.eql(u8, c, ty.named.name)) return c;
    return null;
}

/// True when `en`'s section tree carries `path` all the way down to a unit
/// variant — the predicate form of `resolveSectionPathInEnum`, so the set of
/// carriers can be collected without building a typed node for each one. The
/// two walk the same steps and must keep agreeing: a path this answers `true`
/// for is a path `resolveSectionPathInEnum` resolves.
fn enumCarriesSectionPath(env: *Env, en: envMod.TypeDef.Enum, path: []const []const u8) bool {
    if (path.len == 0) return false;
    var current = en;
    for (path, 0..) |seg, i| {
        var matched: ?envMod.VariantDef = null;
        for (current.variants) |v| {
            if (std.mem.eql(u8, v.name, seg) or
                (looksNumeric(seg) and v.name.len > 1 and v.name[0] == '_' and v.name[1] == '_' and std.mem.eql(u8, v.name[2..], seg)))
            {
                matched = v;
                break;
            }
        }
        const variant = matched orelse return false;
        // The leaf of a section path is a unit variant; a payload variant
        // (`Hex(value: string)`) is a call, not the end of a chain.
        if (i + 1 == path.len) return variant.fields.len == 0;
        // Every inner segment must be a section wrapper.
        if (variant.fields.len != 1 or !std.mem.eql(u8, variant.fields[0].name, "_inner")) return false;
        const inner_type = variant.fields[0].type_.deref();
        if (inner_type.* != .named) return false;
        const inner_def = env.lookupTypeDef(inner_type.named.name) orelse return false;
        if (inner_def != .enum_) return false;
        current = inner_def.enum_;
    }
    return false;
}

/// Index of the first segment of `path` that does not name a variant or a
/// section wrapper on the way down `en`'s section tree.
fn firstUnresolvedSectionSegment(env: *Env, en: envMod.TypeDef.Enum, path: []const []const u8) usize {
    var current = en;
    for (path, 0..) |seg, i| {
        var matched: ?envMod.VariantDef = null;
        for (current.variants) |v| {
            if (std.mem.eql(u8, v.name, seg) or
                (looksNumeric(seg) and v.name.len > 1 and v.name[0] == '_' and v.name[1] == '_' and std.mem.eql(u8, v.name[2..], seg)))
            {
                matched = v;
                break;
            }
        }
        const variant = matched orelse return i;
        if (i + 1 == path.len) return path.len;
        if (variant.fields.len != 1 or !std.mem.eql(u8, variant.fields[0].name, "_inner")) return i + 1;
        const inner_type = variant.fields[0].type_.deref();
        if (inner_type.* != .named) return i + 1;
        const inner_def = env.lookupTypeDef(inner_type.named.name) orelse return i + 1;
        if (inner_def != .enum_) return i + 1;
        current = inner_def.enum_;
    }
    return path.len;
}

/// True iff `enum_def` has a section-wrapper variant named `head`. Used
/// by the ES4 partial-match detector to identify which enum the user
/// likely intended in a failed path-access chain.
fn headSectionVariantOn(enum_def: envMod.TypeDef.Enum, head: []const u8) bool {
    for (enum_def.variants) |v| {
        if (!std.mem.eql(u8, v.name, head)) continue;
        // A section wrapper carries exactly one `_inner` field whose type
        // is a named (synthesised) enum. Bare variants carry zero fields
        // and don't qualify as a "section path head".
        if (v.fields.len != 1) return false;
        if (!std.mem.eql(u8, v.fields[0].name, "_inner")) return false;
        return true;
    }
    return false;
}

/// §enum-sections F2 — assemble the UNTYPED AST equivalent of the qualified
/// nested ctor call (`<EnumName>.<Section>(_inner: <recurse>)` … leaf is
/// `<EnumName>.<variant>` identAccess). The codegen-side rewrite pass
/// substitutes this expression in place of the dot-shorthand chain.
///
/// All synthesised nodes carry the sentinel loc `{line=0, col=0}` so a
/// second pass over the rewritten tree (the transform walker recurses into
/// the substituted expression) does not re-trigger the rewrite map lookup —
/// real source locs always have `line >= 1`.
fn buildSectionPathRewrite(
    env: *Env,
    en: envMod.TypeDef.Enum,
    path: []const []const u8,
) InferError!?*const ast.Expr {
    if (path.len == 0) return null;
    const head = path[0];
    const rest = path[1..];

    var matched: ?envMod.VariantDef = null;
    for (en.variants) |v| {
        if (std.mem.eql(u8, v.name, head) or
            (looksNumeric(head) and v.name.len > 1 and v.name[0] == '_' and v.name[1] == '_' and std.mem.eql(u8, v.name[2..], head)))
        {
            matched = v;
            break;
        }
    }
    const variant = matched orelse return null;

    const synth_loc = ast.Loc{ .line = 0, .col = 0 };

    // Recv: `ident(en.name)` — the enum name binding lookup happens at
    // codegen via stringification only; no env lookup needed.
    const enum_recv = try env.arena.create(ast.Expr);
    enum_recv.* = ast.Expr{ .identifier = .{
        .loc = synth_loc,
        .kind = .{ .ident = en.name },
    } };

    if (rest.len == 0) {
        if (variant.fields.len != 0) return null;
        // Leaf: `<EnumName>.<variant>` identAccess.
        const leaf = try env.arena.create(ast.Expr);
        leaf.* = ast.Expr{ .identifier = .{
            .loc = synth_loc,
            .kind = .{ .identAccess = .{
                .receiver = enum_recv,
                .member = variant.name,
            } },
        } };
        return leaf;
    }

    // Non-leaf: must be a section wrapper.
    if (variant.fields.len != 1) return null;
    if (!std.mem.eql(u8, variant.fields[0].name, "_inner")) return null;
    const inner_type = variant.fields[0].type_.deref();
    if (inner_type.* != .named) return null;
    const inner_def = env.lookupTypeDef(inner_type.named.name) orelse return null;
    if (inner_def != .enum_) return null;

    const inner_rewrite = try buildSectionPathRewrite(env, inner_def.enum_, rest) orelse return null;

    // Build the call args slice with a single named `_inner` arg.
    const args = try env.arena.alloc(ast.CallArg, 1);
    args[0] = .{
        .label = "_inner",
        .value = @constCast(inner_rewrite),
        .comments = &.{},
    };
    const trailing = try env.arena.alloc(ast.TrailingLambda, 0);
    const call = try env.arena.create(ast.Expr);
    call.* = ast.Expr{ .call = .{
        .loc = synth_loc,
        .kind = .{ .call = .{
            .receiver = enum_recv,
            .callee = variant.name,
            .is_builtin = false,
            .args = args,
            .trailing = trailing,
        } },
    } };
    return call;
}

/// Try to resolve a path `[head, ..., leaf]` through enum `en`'s variants. The
/// head must match an enum variant; if that variant carries a single field
/// named `_inner` typed to a synthesised inner enum, recurse the rest of the
/// path into it. Pure-digit segments are looked up with an `_` prefix to
/// match the F1 mangling. Returns the built typed nested-ctor-call expression
/// or `null` if the path doesn't match.
///
/// The lowered shape is fully qualified at every level — leaves are emitted
/// as `identAccess(<EnumName>, <variant>)` and section wrappers as call
/// expressions whose receiver names the enum — so the codegen produces the
/// equivalent of the manually-written `Token.Color(__Token__Color.Red(…))`
/// form without needing to know which enum a bare `Color(...)` came from.
fn resolveSectionPathInEnum(
    env: *Env,
    en: envMod.TypeDef.Enum,
    path: []const []const u8,
    loc: ast.Loc,
) InferError!?TypedExpr {
    if (path.len == 0) return null;
    const head = path[0];
    const rest = path[1..];

    // Find the variant matching the head segment.
    var matched: ?envMod.VariantDef = null;
    for (en.variants) |v| {
        if (std.mem.eql(u8, v.name, head) or
            (looksNumeric(head) and v.name.len > 1 and v.name[0] == '_' and v.name[1] == '_' and std.mem.eql(u8, v.name[2..], head)))
        {
            matched = v;
            break;
        }
    }
    const variant = matched orelse return null;

    const enum_type = try env.namedType(en.name);

    if (rest.len == 0) {
        // Leaf: unit variant ⇒ `<EnumName>.<variant>` identAccess so codegen
        // emits the qualified form (`__Token__Color__Red._500` in JS). Bare
        // `dotIdent(_500)` would lose the enum context the synthesised inner
        // enums need. Payload variants without a section-wrapper `_inner`
        // field can't terminate a section-path chain.
        if (variant.fields.len != 0) return null;
        const enum_ident = try makeTypedPtr(env, TypedExpr{ .identifier = .{
            .loc = loc,
            .type_ = enum_type,
            .kind = .{ .ident = en.name },
        } });
        return TypedExpr{ .identifier = .{ .loc = loc, .type_ = enum_type, .kind = .{ .identAccess = .{
            .receiver = enum_ident,
            .member = variant.name,
        } } } };
    }

    // Non-leaf: variant must be a section wrapper — single `_inner` field
    // typed to a synthesised inner enum.
    if (variant.fields.len != 1) return null;
    if (!std.mem.eql(u8, variant.fields[0].name, "_inner")) return null;
    const inner_type = variant.fields[0].type_.deref();
    if (inner_type.* != .named) return null;
    const inner_def = env.lookupTypeDef(inner_type.named.name) orelse return null;
    if (inner_def != .enum_) return null;

    const inner_val = try resolveSectionPathInEnum(env, inner_def.enum_, rest, loc) orelse return null;
    const inner_ptr = try makeTypedPtr(env, inner_val);

    // Wrap in this section's ctor call with a qualified receiver:
    // `<EnumName>.Section(_inner: <inner_val>)`. The qualified form lets the
    // backends route through the parent enum's section-wrapper ctor without
    // needing a bare `Section` binding in env.
    const enum_ident = try makeTypedPtr(env, TypedExpr{ .identifier = .{
        .loc = loc,
        .type_ = enum_type,
        .kind = .{ .ident = en.name },
    } });
    var args = try env.arena.alloc(ast.CallArgOf(.typed), 1);
    args[0] = .{ .label = "_inner", .value = inner_ptr, .comments = &.{} };
    return TypedExpr{ .call = .{ .loc = loc, .type_ = enum_type, .kind = .{ .call = .{
        .receiver = enum_ident,
        .callee = variant.name,
        .is_builtin = false,
        .args = args,
        .trailing = &.{},
    } } } };
}

/// True when every byte of `s` is an ASCII digit (`0`–`9`). Used to detect
/// numeric leaf segments (`500`, `4`) that the F1 desugar mangled to
/// `_500` / `_4`.
fn looksNumeric(s: []const u8) bool {
    if (s.len == 0) return false;
    for (s) |c| if (c < '0' or c > '9') return false;
    return true;
}

// ── pass 2: declaration inference ────────────────────────────────────────────

/// Build a signature name for a record declaration binding — the 1.0.3
/// surface, which is what hover, completion and signature help print for the
/// constructor: `"type Name<G>(f1: T1, f2: T2)"`, fields inline, body omitted.
/// It is the name of the binding's *type*, not of the record — the instances
/// are `named` by `r.name` alone — so the spelling is free to follow the
/// document; `record { … }` was the pre-1.0.3 surface, which no longer parses.
fn buildRecordDeclName(env: *Env, r: ast.TypeDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "type ");
    try buf.appendSlice(env.arena, r.name);
    try appendGenericParamsStr(&buf, env.arena, r.genericParams);
    try buf.append(env.arena, '(');
    for (r.recordFields(), 0..) |f, i| {
        if (i > 0) try buf.appendSlice(env.arena, ", ");
        try buf.appendSlice(env.arena, f.name);
        try buf.appendSlice(env.arena, ": ");
        try appendTypeRefStr(&buf, env.arena, f.typeRef);
    }
    try buf.append(env.arena, ')');
    return try buf.toOwnedSlice(env.arena);
}

/// `<A, B>` after a declaration's name, or nothing when it has no generics —
/// the 1.0.3 spelling shared by the three declaration-name builders.
fn appendGenericParamsStr(buf: *std.ArrayList(u8), arena: std.mem.Allocator, params: anytype) !void {
    if (params.len == 0) return;
    try buf.append(arena, '<');
    for (params, 0..) |gp, i| {
        if (i > 0) try buf.appendSlice(arena, ", ");
        try buf.appendSlice(arena, gp.name);
    }
    try buf.append(arena, '>');
}

/// Build a signature name for a struct declaration binding.
/// Format: `"struct {\n    name: Type\n}"` ---- fields only.
fn buildStructDeclName(env: *Env, s: ast.StructDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "struct");
    if (s.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (s.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " {\n");
    for (s.members) |m| {
        switch (m) {
            .field => |f| {
                try buf.appendSlice(env.arena, "    ");
                try buf.appendSlice(env.arena, f.name);
                try buf.appendSlice(env.arena, ": ");
                try buf.appendSlice(env.arena, try typeRefToString(env.arena, f.typeRef));
                if (f.init) |_| {
                    try buf.append(env.arena, '\n');
                } else {
                    try buf.append(env.arena, '\n');
                }
            },
            else => {},
        }
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for a behavior declaration binding — the 1.0.3
/// surface: `"behavior Name<G> {\n    val x: T;\n    fn method<G>(params) -> R;\n}"`.
fn buildInterfaceDeclName(env: *Env, d: ast.BehaviorDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "behavior ");
    try buf.appendSlice(env.arena, d.name);
    try appendGenericParamsStr(&buf, env.arena, d.genericParams);
    try buf.appendSlice(env.arena, " {\n");
    for (d.fields) |f| {
        try buf.appendSlice(env.arena, "    val ");
        try buf.appendSlice(env.arena, f.name);
        try buf.appendSlice(env.arena, ": ");
        try buf.appendSlice(env.arena, f.typeName);
        try buf.appendSlice(env.arena, ";\n");
    }
    for (d.methods) |m| {
        try buf.appendSlice(env.arena, "    fn ");
        try buf.appendSlice(env.arena, m.name);
        try appendGenericParamsStr(&buf, env.arena, m.genericParams);
        try buf.append(env.arena, '(');
        for (m.params, 0..) |p, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, p.name);
            if (p.modifier == .@"comptime" or p.modifier == .syntax) {
                try buf.appendSlice(env.arena, " comptime");
            }
            try buf.appendSlice(env.arena, ": ");
            if (p.modifier == .syntax) try buf.appendSlice(env.arena, "syntax ");
            try appendTypeRefStr(&buf, env.arena, p.typeRef);
        }
        try buf.append(env.arena, ')');
        if (m.returnType) |rt| {
            try buf.appendSlice(env.arena, " -> ");
            try appendTypeRefStr(&buf, env.arena, rt);
        }
        if (!m.is_default) try buf.appendSlice(env.arena, ";");
        try buf.append(env.arena, '\n');
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for an enum declaration binding — the 1.0.3
/// surface, compact as the formatter prints it:
/// `"type Name<G> { Variant, Variant(field: Type) }"`.
fn buildEnumDeclName(env: *Env, e: ast.TypeDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "type ");
    try buf.appendSlice(env.arena, e.name);
    try appendGenericParamsStr(&buf, env.arena, e.genericParams);
    try buf.appendSlice(env.arena, " { ");
    for (e.variants(), 0..) |v, vi| {
        if (vi > 0) try buf.appendSlice(env.arena, ", ");
        try buf.appendSlice(env.arena, v.name);
        if (v.fields.len > 0) {
            try buf.append(env.arena, '(');
            for (v.fields, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(env.arena, ", ");
                try buf.appendSlice(env.arena, f.name);
                try buf.appendSlice(env.arena, ": ");
                try appendTypeRefStr(&buf, env.arena, f.typeRef);
            }
            try buf.append(env.arena, ')');
        }
    }
    try buf.appendSlice(env.arena, " }");
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for a fn declaration binding.
/// Format: `fn(name [comptime]: [syntax ]Type, ...) -> ReturnType`
/// The function name and generic params are omitted; modifiers are included.
fn buildFnSigName(env: *Env, f: ast.FnDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "fn(");
    for (f.params, 0..) |p, i| {
        if (i > 0) try buf.appendSlice(env.arena, ", ");
        try buf.appendSlice(env.arena, p.name);
        if (p.modifier == .@"comptime" or p.modifier == .syntax) {
            try buf.appendSlice(env.arena, " comptime");
        }
        try buf.appendSlice(env.arena, ": ");
        if (p.modifier == .syntax) {
            try buf.appendSlice(env.arena, "syntax ");
        }
        try appendTypeRefStr(&buf, env.arena, p.typeRef);
    }
    try buf.append(env.arena, ')');
    if (f.returnType) |rt| {
        try buf.appendSlice(env.arena, " -> ");
        try appendTypeRefStr(&buf, env.arena, rt);
    }
    return try buf.toOwnedSlice(env.arena);
}

/// Append the string form of a TypeRef to `buf`.
fn appendTypeRefStr(buf: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator, ref: ast.TypeRef) std.mem.Allocator.Error!void {
    switch (ref) {
        .named => |n| try buf.appendSlice(allocator, n),
        .array => |elem| {
            try appendTypeRefStr(buf, allocator, elem.*);
            try buf.appendSlice(allocator, "[]");
        },
        .tuple_ => |elems| {
            try buf.appendSlice(allocator, "#(");
            for (elems, 0..) |e, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, e);
            }
            try buf.append(allocator, ')');
        },
        .labeledTuple => |lt| {
            try buf.appendSlice(allocator, "#(");
            for (lt.elems, 0..) |e, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try buf.appendSlice(allocator, lt.labels[i]);
                try buf.appendSlice(allocator, ": ");
                try appendTypeRefStr(buf, allocator, e);
            }
            try buf.append(allocator, ')');
        },
        .optional => |inner| {
            try buf.append(allocator, '?');
            try appendTypeRefStr(buf, allocator, inner.*);
        },
        .function => |f| {
            try buf.appendSlice(allocator, "fn(");
            for (f.params, 0..) |p, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, p);
            }
            try buf.appendSlice(allocator, ") -> ");
            try appendTypeRefStr(buf, allocator, f.returnType.*);
        },
        .generic => |b| {
            if (b.is_builtin) try buf.append(allocator, '@');
            try buf.appendSlice(allocator, b.name);
            try buf.append(allocator, '<');
            for (b.args, 0..) |a, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, a);
            }
            try buf.append(allocator, '>');
        },
        .typeparam => |constraints| {
            try buf.appendSlice(allocator, "typeparam");
            for (constraints, 0..) |c, i| {
                try buf.appendSlice(allocator, if (i == 0) " " else " | ");
                try appendTypeRefStr(buf, allocator, c);
            }
        },
    }
}

fn inferDecl(env: *Env, decl: ast.DeclKind) InferError!?Binding {
    switch (decl) {
        .val => |v| {
            // The annotation is resolved BEFORE the value so it can be this
            // position's expected type (00 · 01-checker) — see
            // `inferDeclTyped`'s `.val` case.
            const annType: ?*T.Type = if (v.typeAnnotation) |ann|
                resolveTypeRef(env, ann) catch |err| return locateTypeRefError(env, err, v.value.getLoc())
            else
                null;
            const ty = try inferExprExpecting(env, v.value.*, annType);
            // Bind the DECLARED (annotated) type when present.
            var bindTy = ty;
            if (annType) |at| {
                try unifyAt(env, at, ty, v.value.getLoc());
                bindTy = at;
            }
            try validateMemoryAnnotations(env, v, bindTy);
            try noteTypeValue(env, v.name, v.value.*, annType == null and !v.mutable);
            if (v.mutable) try env.bind(v.name, bindTy) else try env.bindVal(v.name, bindTy);
            return .{ .name = v.name, .type_ = bindTy };
        },
        .@"fn" => |f| {
            const ty = try inferFnDecl(env, f);
            try env.bind(f.name, ty);
            const sigName = try buildFnSigName(env, f);
            return .{ .name = f.name, .type_ = try env.namedType(sigName) };
        },
        // Type declarations produce a binding whose type name encodes the body.
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => {
                const typeName = try buildRecordDeclName(env, tdecl);
                return .{ .name = tdecl.name, .type_ = try env.namedType(typeName) };
            },
            .enum_ => {
                const typeName = try buildEnumDeclName(env, tdecl);
                return .{ .name = tdecl.name, .type_ = try env.namedType(typeName) };
            },
        },
        .behavior => |d| {
            const typeName = try buildInterfaceDeclName(env, d);
            try registerInterfaceAssociatedFns(env, d);
            return .{ .name = d.name, .type_ = try env.namedType(typeName) };
        },
        // A test block produces no binding, but its body must type-check.
        .@"test" => |t| {
            try inferTestDecl(env, t);
            return null;
        },
        // `from "std"` imports mark module namespaces (no value binding) —
        // the untyped path (tests, LSP) needs this too, not just
        // `inferProgramTyped`'s `.use` interception.
        .use => |u| {
            _ = try markStdImports(env, u);
            return null;
        },
        // implement doesn't produce a value binding.
        else => return null,
    }
}

/// Type-check a `test { … }` body. Body is treated like a `#[@future]` fn
/// returning void: `await <future>` is accepted (the test runner awaits
/// the test fn's return value on every backend that supports futures —
/// commonJS via `async function`, erlang via the eager `@Future<T>` = `T`
/// rule that makes `await` an identity). `yield` stays rejected; `throw`
/// is lenient (a panic surfaces as the test's red diagnostic).
fn inferTestDecl(env: *Env, t: ast.TestDecl) InferError!void {
    const savedThrowCtx = env.throwContext;
    env.throwContext = .unchecked;
    defer env.throwContext = savedThrowCtx;

    // `@src().fnName` inside a test body is the test name, verbatim (decision
    // 73); an anonymous `test { … }` gets the `test_<idx>` fallback the
    // commonJS registry gives it (`codegen/commonJS.zig`, `test_entries`).
    const savedFnName = env.currentFnName;
    env.currentFnName = t.name orelse try std.fmt.allocPrint(env.arena, "test_{d}", .{env.testIndex});
    env.testIndex += 1;
    defer env.currentFnName = savedFnName;

    const prevStarFn = env.starFn;
    const prevLabelsLen = env.labelStack.items.len;
    defer {
        env.starFn = prevStarFn;
        env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    }
    // §A3 follow-up — tests run inside an implicit future context so
    // callers can `await flush()` / `await fetch(url)` directly in
    // assertions. The lowering side (`commonJS.emitTestFn`) emits an
    // `async function` to match.
    env.starFn = .{
        .allowsAwait = true,
        .allowsYield = false,
        .iterItem = null,
        .iterCompletion = null,
        .fnLabel = null,
        .effect = .future,
    };
    env.labelStack.shrinkRetainingCapacity(0);

    try inferBodyStmts(env, t.body);
}

/// One variant of `pub type External implement Annotation { … }` in
/// `libs/std/src/builtins.d.bp`, and whether it declares `inline: bool = false`.
pub const ExternalVariant = struct { name: []const u8, declares_inline: bool };

/// The five `External` variants (front 20 F9). `inline` opts a `(target,
/// method)` pair out of the dispatch table, and exactly two emitters read it —
/// `codegen/erlang.zig` and `codegen/beam_asm.zig`, each through a
/// `hasExternalInline` over the LAST argument — so exactly two variants declare
/// it. On the other three a written `inline` is a switch nothing reads, which
/// decision 67 refuses rather than accepts and ignores (`refuseUnreadInline`).
/// `builtins.d.bp` is documentation the compiler does not parse, so the table
/// is restated here, once, and `comptime/tests/infer_decls.zig` reads the file
/// and fails in both directions when the two disagree.
pub const external_variants = [_]ExternalVariant{
    .{ .name = "Erlang", .declares_inline = true },
    .{ .name = "Node", .declares_inline = false },
    .{ .name = "Beam", .declares_inline = true },
    .{ .name = "Wasm", .declares_inline = false },
    .{ .name = "Typescript", .declares_inline = false },
};

/// The `External` variant the annotation names, or null when the path names none
/// (a lower-case spelling is still matched: `external.erlang` reaches
/// `refuseLowerCaseExternal` first, and the emitters compare case-insensitively).
fn externalVariantOf(a: ast.Annotation) ?ExternalVariant {
    if (!std.mem.startsWith(u8, a.name, "External.")) return null;
    const variant = a.name["External.".len..];
    for (external_variants) |v| {
        if (std.ascii.eqlIgnoreCase(variant, v.name)) return v;
    }
    return null;
}

/// True when `a` writes the `inline` flag: an argument labelled `inline`, or a
/// bare trailing `true` / `false` after the template — the positional form the
/// emitters' `hasExternalInline` reads (last argument, literally `true`).
fn writesInline(a: ast.Annotation) bool {
    for (a.args, 0..) |arg, i| {
        if (a.labelOf(i)) |label| {
            if (std.mem.eql(u8, label, "inline")) return true;
        } else if (i == a.args.len - 1 and i > 0 and
            (std.mem.eql(u8, arg, "true") or std.mem.eql(u8, arg, "false")))
        {
            return true;
        }
    }
    return false;
}

/// Front 20 F9, decision 67 — a written `inline` that no emitter would read is
/// refused at the annotation rather than accepted as a switch that does
/// nothing. Three shapes are unread: the flag on a variant that does not
/// declare it (`Node` / `Wasm` / `Typescript`), the flag anywhere but last
/// (both `hasExternalInline` read the last argument only), and a value that is
/// not `true` / `false` (the readers compare against the literal `true`).
fn refuseUnreadInline(env: *Env, a: ast.Annotation) InferError!void {
    const v = externalVariantOf(a) orelse return;
    if (!writesInline(a)) return;
    const fail = struct {
        fn fail(e_: *Env, a_: ast.Annotation, msg: []const u8, hint: []const u8) InferError {
            var e = TypeError.custom(msg, hint);
            if (a_.loc) |l| e = e.withLoc(l);
            e_.lastError = e;
            return error.TypeError;
        }
    }.fail;
    if (!v.declares_inline) {
        return fail(env, a, try std.fmt.allocPrint(
            env.arena,
            "`External.{s}` declares no `inline` — the flag is read by the erlang and beam emitters only",
            .{v.name},
        ), try std.fmt.allocPrint(
            env.arena,
            "Delete it: on `External.{s}` `inline` is a switch nothing reads. `External.Erlang` and `External.Beam` declare it (`builtins.d.bp`).",
            .{v.name},
        ));
    }
    for (a.args, 0..) |arg, i| {
        const labelled = if (a.labelOf(i)) |label| std.mem.eql(u8, label, "inline") else false;
        const last = i == a.args.len - 1;
        if (!labelled and !last) continue;
        if (!last) {
            return fail(env, a, try std.fmt.allocPrint(
                env.arena,
                "`External.{s}`'s `inline` must be the last argument — the emitters read the last argument only",
                .{v.name},
            ), "Write the template first: `#[@External.Erlang(\"<template>\", inline = true)]`.");
        }
        if (!std.mem.eql(u8, arg, "true") and !std.mem.eql(u8, arg, "false")) {
            return fail(env, a, try std.fmt.allocPrint(
                env.arena,
                "`External.{s}`'s `inline` is a bool, got `{s}`",
                .{ v.name, arg },
            ), "Write `inline = true` or `inline = false`.");
        }
    }
}

/// The inline rule on every `#[@External.<Target>(…)]` a method carries —
/// `codegen/erlang.zig` and `codegen/beam_asm.zig` read `hasExternalInline` over
/// a behavior's and a type's methods, so a flag written there is checked the
/// same way a `declare fn`'s is (`validateExternalAnnotation`).
fn validateExternalInline(env: *Env, program: ast.Program) InferError!void {
    for (program.decls) |decl| switch (decl) {
        .type_ => |tdecl| for (tdecl.methods) |m| {
            for (m.annotations) |a| try refuseUnreadInline(env, a);
        },
        .behavior => |i| for (i.methods) |m| {
            for (m.annotations) |a| try refuseUnreadInline(env, a);
        },
        else => {},
    };
}

/// Type-checks one `external(target, module, symbol)` annotation against its
/// builtin signature (builtins.d.bp): `fn external(target: Target, module: string, symbol: string)`.
fn validateExternalAnnotation(env: *Env, f: ast.FnDecl, a: ast.Annotation) InferError!void {
    const fnLoc: ?ast.Loc = if (f.body.len > 0) f.body[0].expr.getLoc() else null;
    const fail = struct {
        fn fail(e_: *Env, loc: ?ast.Loc, msg: []const u8, hint: []const u8) InferError {
            var e = TypeError.custom(msg, hint);
            if (loc) |l| e = e.withLoc(l);
            e_.lastError = e;
            return error.TypeError;
        }
    }.fail;
    // RULE: `external` annotations are only valid on `declare fn` declarations
    // — the host symbol replaces the body, so an annotated plain `fn` (with or
    // without a body) is malformed.
    if (!f.isDeclare) {
        return fail(env, fnLoc, "`#[@External.<Target>(…)]` requires a `declare fn` declaration", "Write `#[@External.Erlang( \"string\", \"length\")] pub declare fn length(s: string) -> i32;`");
    }
    // target validation: the variant must name a known target.
    if (externalVariantOf(a) == null) {
        return fail(env, fnLoc, "`@external` target must be a Target member: node, typescript, erlang, beam or wasm", "Example: #[@External.Erlang( \"string\", \"length\")]");
    }
    // `inline` (front 20 F9): read on the variants that declare it, refused on
    // the ones that do not — before the arity count, which would otherwise
    // report the unread flag as a wrong argument count.
    try refuseUnreadInline(env, a);
    // `External.<Target>(module, symbol)` form: 1-2 body args (symbol alone
    // or module + symbol). The trailing `inline = true`/`false` flag, on a
    // variant that declares it, adds one more arg.
    var effective_len = a.args.len;
    if (effective_len >= 2 and writesInline(a)) effective_len -= 1;
    if (effective_len < 1 or effective_len > 2) {
        return fail(env, fnLoc, "`@external` expects 1 or 2 arguments: module and/or symbol", "Example: #[@External.Erlang( \"string\", \"length\")] or #[@External.Node(\"reverse\")]");
    }
    // remaining args: string literals or `when(argc == N): "<template>"` branches.
    for (a.args[0..effective_len]) |arg| {
        if (ast.parseArityBranchArg(arg) != null) continue;
        if (arg.len < 2 or arg[0] != '"') {
            return fail(env, fnLoc, "`@external` module and symbol must be string literals", "Example: #[@External.Node(\"./gleam_stdlib.mjs\", \"string_length\")]");
        }
    }
}

// ── generic decorator argument validation (annotation processors, P1) ─────────
//
// A decorator is any fn whose first param is `comptime _: @Decl` (recognized by
// `registerDecoratorSig` into `env.decorators`). Applying `#[d(args)]` is sugar
// for a comptime call `d(reflect(decl), args…)`; the trailing `args` are checked
// here against the decorator's declared signature — arity + argument types —
// with no lib knowledge. PLACEMENT rules (where a marker may sit) are the
// decorator body's job (P2), not the core's.

/// Validate every `#[decorator(args)]` application in `program` against the
/// recognized decorator's trailing signature. Annotations whose name is not a
/// recognized decorator are left untouched: builtins (`external`) validate
/// elsewhere, and an unknown bare marker stays lenient (a lib may not be loaded).
fn validateDecorators(env: *Env, program: ast.Program) InferError!void {
    if (env.decorators.count() == 0) return;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| try checkDecoratorAnnotations(env, f.annotations, f.name),
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => {
                try checkDecoratorAnnotations(env, tdecl.annotations, tdecl.name);
                for (tdecl.recordFields()) |fld| try checkDecoratorAnnotations(env, fld.annotations, fld.name);
                for (tdecl.methods) |m| try checkDecoratorAnnotations(env, m.annotations, m.name);
            },
            .enum_ => {
                try checkDecoratorAnnotations(env, tdecl.annotations, tdecl.name);
                for (tdecl.methods) |m| try checkDecoratorAnnotations(env, m.annotations, m.name);
            },
        },
        .behavior => |i| {
            try checkDecoratorAnnotations(env, i.annotations, i.name);
            for (i.methods) |m| try checkDecoratorAnnotations(env, m.annotations, m.name);
        },
        else => {},
    };
}

/// Reject `#[@<effect>]` annotations where an effect is implementation-only
/// (F1b): on an interface method, which is declarative and expresses its effect
/// through the return wrapper alone. (Bodyless top-level `declare fn` is caught
/// in `inferFnDecl`.)
fn validateEffectAnnotations(env: *Env, program: ast.Program) InferError!void {
    for (program.decls) |decl| switch (decl) {
        .behavior => |i| {
            for (i.methods) |m| {
                if (effectAnnotationOf(m.annotations) != null) {
                    env.lastError = TypeError.custom(
                        "effect annotations mark an implementation; declare the effect in the return type",
                        "A behavior method expresses its effect through the return wrapper (e.g. `-> @Future<T>`), with no annotation.",
                    );
                    return error.TypeError;
                }
            }
        },
        else => {},
    };
}

/// The effect named by a builtin `#[@<effect>]` annotation, or null.
fn effectAnnotationOf(anns: []const ast.Annotation) ?ast.EffectKind {
    for (anns) |a| {
        if (a.is_builtin) {
            if (ast.EffectKind.fromAnnotationName(a.name)) |k| return k;
        }
    }
    return null;
}

/// Check one declaration's annotation list. `owner` names the annotated
/// declaration (for diagnostics).
fn checkDecoratorAnnotations(env: *Env, anns: []const ast.Annotation, owner: []const u8) InferError!void {
    for (anns) |a| {
        if (a.is_builtin) continue; // `@external`, … validated by their own pass.
        const sig = env.decorators.get(a.name) orelse continue;
        try checkDecoratorArgs(env, a, sig, owner);
    }
}

/// Type-check a single `#[name(args…)]` application's trailing arguments against
/// the decorator's parameters (everything after `comptime _: @Decl`). V1: arity
/// (honoring trailing defaults) + a per-argument lexical kind check (string /
/// numeric / bool / enum-member), mirroring `validateExternalAnnotation`.
fn checkDecoratorArgs(env: *Env, a: ast.Annotation, sig: envMod.DecoratorSig, owner: []const u8) InferError!void {
    const fail = struct {
        fn fail(e_: *Env, msg: []const u8, hint: []const u8) InferError {
            e_.lastError = TypeError.custom(msg, hint);
            return error.TypeError;
        }
    }.fail;

    // Arity: required params (no default) ≤ args ≤ total params.
    var required: usize = 0;
    for (sig.params) |p| {
        if (p.default == null) required += 1;
    }
    if (a.args.len < required or a.args.len > sig.params.len) {
        const msg = try std.fmt.allocPrint(env.arena, "`#[{s}]` on `{s}` expects {d} argument(s), got {d}", .{ a.name, owner, sig.params.len, a.args.len });
        return fail(env, msg, "Match the decorator's declared parameters (after the leading `comptime _: @Decl`).");
    }

    // Per-argument kind check against the declared parameter type.
    for (a.args, 0..) |arg, i| {
        const want = paramTypeName(sig.params[i].typeRef) orelse continue; // non-simple type → lenient
        if (!argMatchesType(arg, want)) {
            const msg = try std.fmt.allocPrint(env.arena, "`#[{s}]` argument {d} must be {s}", .{ a.name, i + 1, want });
            return fail(env, msg, "Decorator arguments are type-checked against the decorator's signature.");
        }
    }
}

// ── generic decorator invocation (annotation processors, P2) ──────────────────
//
// After argument validation, the decorator's BODY runs over the declaration it
// annotates: the core serializes that declaration into a `@Decl` handle and the
// body (lib code) gives the marker meaning — validate placement/arguments via
// `fail`/`failAt`. The core knows nothing about any specific marker. Runs only
// in the full compile pipeline (`env.templateEval` set, node available); tooling
// paths (LSP / compileTypesOnly) skip it.

/// Render a `TypeRef` as the simple type name a `@Decl` handle exposes
/// (best-effort: the named/generic head, else empty).
fn declTypeName(tr: ast.TypeRef) []const u8 {
    return switch (tr) {
        .named => |n| n,
        .generic => |g| g.name,
        else => "",
    };
}

/// Run every body-carrying decorator applied to one declaration over its handle.
fn runDeclDecorators(
    env: *Env,
    ctx: envMod.TemplateEvalCtx,
    anns: []const ast.Annotation,
    handle: decoratorEval.DeclHandle,
) InferError!void {
    for (anns) |a| {
        if (a.is_builtin) continue;
        const sig = env.decorators.get(a.name) orelse continue;
        const dfn = sig.fn_decl orelse continue; // bodyless `declare fn` marker
        if (dfn.body.len == 0) continue; // empty body — nothing to run

        var plain = try env.arena.alloc(template.PlainArg, a.args.len);
        for (a.args, 0..) |arg, i| {
            const pname = if (i < sig.params.len) sig.params[i].name else "_";
            plain[i] = .{ .paramName = pname, .source = arg };
        }

        // Diagnostics point at the annotation. A `failAt` span has no source text
        // to map onto for a declaration, so it is reported at the annotation too.
        const outcome = decoratorEval.evaluate(env.arena, ctx.io, ctx.build_root, dfn, handle, plain, &env.comptimeTraces) catch {
            return decoratorError(env, a, "the decorator evaluator failed to run", "Decorator bodies run in a persistent `erl` process at compile time — check that `erl` and `erlc` are on PATH.");
        };
        switch (outcome) {
            .ok => |contributions| {
                // `@emit(...)` sources — spliced into the module by `analyzeModule`.
                for (contributions) |src| try env.contributions.append(env.arena, src);
            },
            .fail => |fl| return decoratorError(env, a, fl.message, "raised by the decorator via `fail`/`failAt`"),
            .err => |m| return decoratorError(env, a, m, "the decorator could not be evaluated"),
        }
    }
}

fn decoratorError(env: *Env, a: ast.Annotation, message: []const u8, hint: []const u8) InferError {
    var e = TypeError.custom(message, hint);
    if (a.loc) |loc| e = e.withLoc(loc);
    env.lastError = e;
    return error.TypeError;
}

/// Walk `program` and run body-carrying decorators over every annotated
/// declaration (and its methods). Mirrors `validateDecorators`' walk; runs after
/// it (so arguments are already validated).
fn invokeDecorators(env: *Env, program: ast.Program) InferError!void {
    if (env.skipDecoratorInvoke) return; // second pass: contributions already spliced
    if (env.decorators.count() == 0) return;
    const ctx = env.templateEval orelse return;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| {
            const h = decoratorEval.DeclHandle{
                .kind = "Fn",
                .name = f.name,
                .fields = &.{},
                .methods = &.{},
                .returnType = if (f.returnType) |rt| declTypeName(rt) else "",
                .annotations = f.annotations,
            };
            try runDeclDecorators(env, ctx, f.annotations, h);
        },
        .type_ => |tdecl| switch (tdecl.shape) {
            .record => {
                var fields = try env.arena.alloc(decoratorEval.FieldHandle, tdecl.recordFields().len);
                for (tdecl.recordFields(), 0..) |fld, i| {
                    fields[i] = .{
                        .name = fld.name,
                        .typeName = declTypeName(fld.typeRef),
                        .annotations = fld.annotations,
                    };
                }
                const h = decoratorEval.DeclHandle{
                    .kind = "Type",
                    .name = tdecl.name,
                    .fields = fields,
                    .methods = tdecl.methods,
                    .returnType = "",
                    .annotations = tdecl.annotations,
                };
                try runDeclDecorators(env, ctx, tdecl.annotations, h);
                for (tdecl.recordFields()) |fld| {
                    const fh = decoratorEval.DeclHandle{
                        .kind = "Field",
                        .name = fld.name,
                        .fields = &.{},
                        .methods = &.{},
                        .returnType = declTypeName(fld.typeRef),
                        .annotations = fld.annotations,
                    };
                    try runDeclDecorators(env, ctx, fld.annotations, fh);
                }
                for (tdecl.methods) |m| {
                    const mh = decoratorEval.DeclHandle{
                        .kind = "Method",
                        .name = m.name,
                        .fields = &.{},
                        .methods = &.{},
                        .returnType = if (m.returnType) |rt| declTypeName(rt) else "",
                        .annotations = m.annotations,
                    };
                    try runDeclDecorators(env, ctx, m.annotations, mh);
                }
            },
            .enum_ => {
                const vs = tdecl.variants();
                const secs = tdecl.sections();
                const names = try env.arena.alloc([]const u8, vs.len + secs.len);
                for (vs, 0..) |v, i| names[i] = v.name;
                for (secs, 0..) |sec, i| names[vs.len + i] = sec.name;
                const h = decoratorEval.DeclHandle{
                    .kind = "Type",
                    .name = tdecl.name,
                    .fields = &.{},
                    .variants = names,
                    .methods = tdecl.methods,
                    .returnType = "",
                    .annotations = tdecl.annotations,
                };
                try runDeclDecorators(env, ctx, tdecl.annotations, h);
                for (tdecl.methods) |m| {
                    const mh = decoratorEval.DeclHandle{
                        .kind = "Method",
                        .name = m.name,
                        .fields = &.{},
                        .methods = &.{},
                        .returnType = if (m.returnType) |rt| declTypeName(rt) else "",
                        .annotations = m.annotations,
                    };
                    try runDeclDecorators(env, ctx, m.annotations, mh);
                }
            },
        },
        .behavior => |i| {
            // Behavior-level markers (`#[mock]`) reflect with kind `Behavior`,
            // exposing the interface's fields + method signatures. Its methods also
            // reflect individually (`#[getMapping]` on a route) as `Method`.
            var fields = try env.arena.alloc(decoratorEval.FieldHandle, i.fields.len);
            for (i.fields, 0..) |fld, idx| {
                fields[idx] = .{
                    .name = fld.name,
                    .typeName = fld.typeName,
                    .annotations = &.{},
                };
            }
            const h = decoratorEval.DeclHandle{
                .kind = "Behavior",
                .name = i.name,
                .fields = fields,
                .methods = i.methods,
                .returnType = "",
                .annotations = i.annotations,
            };
            try runDeclDecorators(env, ctx, i.annotations, h);
            for (i.methods) |m| {
                const mh = decoratorEval.DeclHandle{
                    .kind = "Method",
                    .name = m.name,
                    .fields = &.{},
                    .methods = &.{},
                    .returnType = if (m.returnType) |rt| declTypeName(rt) else "",
                    .annotations = m.annotations,
                };
                try runDeclDecorators(env, ctx, m.annotations, mh);
            }
        },
        else => {},
    };
}

/// The simple (named) type of a parameter, or null for arrays/optionals/generics
/// where the lexical check is skipped (kept lenient in V1).
fn paramTypeName(tr: ast.TypeRef) ?[]const u8 {
    return switch (tr) {
        .named => |n| n,
        else => null,
    };
}

/// True when the raw annotation argument lexeme is consistent with `typeName`.
/// Annotation args reach inference as source lexemes, so this is a lexical (not
/// full-expression) check: enough to catch `#[value(123)]` where a string is
/// required, while staying permissive for user/named types.
fn argMatchesType(arg: []const u8, typeName: []const u8) bool {
    if (arg.len == 0) return true;
    if (std.mem.eql(u8, typeName, "string")) {
        return arg[0] == '"';
    }
    if (std.mem.eql(u8, typeName, "bool")) {
        return std.mem.eql(u8, arg, "true") or std.mem.eql(u8, arg, "false");
    }
    // Numeric primitives: a leading digit or sign (covers i32/i64/f32/f64/u*).
    if (std.mem.startsWith(u8, typeName, "i") or std.mem.startsWith(u8, typeName, "u") or
        std.mem.startsWith(u8, typeName, "f"))
    {
        const c = arg[0];
        return std.ascii.isDigit(c) or c == '-' or c == '+';
    }
    return true; // enum member / named type → lenient (full check is the body's job).
}

/// The index of the element labeled `label` (decision 8 §6), or null when no
/// element carries that label or two do (an ambiguous label names nothing).
fn tupleLabelIndex(labels: []const []const u8, label: []const u8) ?usize {
    var found: ?usize = null;
    for (labels, 0..) |l, i| {
        if (!std.mem.eql(u8, l, label)) continue;
        if (found != null) return null;
        found = i;
    }
    return found;
}

/// Parse a tuple-index member name (`_0`, `_1`, …) into its integer index.
/// Returns null for any other member name. Mirrors codegen's tupleIndexMember.
fn tupleMemberIndex(member: []const u8) ?usize {
    // `t._N` and the bare `t.N` both name element N.
    const digits = if (member.len > 0 and member[0] == '_') member[1..] else member;
    if (digits.len == 0) return null;
    for (digits) |ch| {
        if (!std.ascii.isDigit(ch)) return null;
    }
    return std.fmt.parseInt(usize, digits, 10) catch null;
}

/// True when `name` names a registered type definition with generic params.
fn typeDefHasGenerics(env: *Env, name: []const u8) bool {
    const td = env.lookupTypeDef(name) orelse return false;
    return switch (td) {
        .record => |r| r.genericParams.len > 0,
        .struct_ => |s| s.genericParams.len > 0,
        .enum_ => |e| e.genericParams.len > 0,
    };
}

/// Per-call-site instantiation of a generic type-def constructor. Without it
/// the registration-time generic cells unify destructively at the first call
/// (`Pair(first: p.second, …)` in one fn would bind `A := B` for every later
/// `Pair(1, "one")` — "expected i32, found string").
fn instantiateCtorType(env: *Env, callee: []const u8, ctorType: *T.Type) InferError!*T.Type {
    if (!typeDefHasGenerics(env, callee)) return ctorType;
    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    return instantiateType(env, ctorType, &seen, .allVars);
}

/// Field type of a generic record instance: substitute the registration-time
/// generic cells with the instance's type args (`p: Pair<i32, string>` →
/// `p.second: string`). The cells are recovered positionally from the
/// constructor binding's return type (`fn(…) -> Pair<A_cell, B_cell>`).
/// Falls back to the registered (shared) field type when the shape doesn't
/// line up — never worse than the previous behavior.
fn instantiateFieldType(env: *Env, typeName: []const u8, instArgs: []*T.Type, fieldType: *T.Type) InferError!*T.Type {
    if (instArgs.len == 0) return fieldType;
    const ctor = env.lookup(typeName) orelse return fieldType;
    const ctorResolved = ctor.deref();
    if (ctorResolved.* != .func) return fieldType;
    const ret = ctorResolved.func.ret.deref();
    if (ret.* != .named or ret.named.args.len != instArgs.len) return fieldType;

    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    for (ret.named.args, instArgs) |cellTy, inst| {
        const cellResolved = cellTy.deref();
        if (cellResolved.* != .typeVar) continue;
        try seen.put(cellResolved.typeVar, inst);
    }
    if (seen.count() == 0) return fieldType;
    return instantiateType(env, fieldType, &seen, .allVars);
}

/// Which type-variable states `instantiateType` substitutes with fresh vars.
///   - `.allVars`: `.unbound` AND `.generic` — registration-time copies for
///     ctors / "std" module exports, where every var belongs to the scheme.
///   - `.genericOnly`: standard HM instantiation — only generalized
///     (`.generic`) vars are freshened; `.unbound` vars belong to the
///     enclosing inference in progress and must stay shared.
const InstantiateMode = enum { allVars, genericOnly };

/// Deep-copies `ty`, substituting type variables (per `mode`) with fresh
/// ones. Per-call-site instantiation — without it the shared fn type would
/// unify destructively at the first call site.
fn instantiateType(env: *Env, ty: *T.Type, seen: *std.AutoHashMap(*T.TypeCell, *T.Type), mode: InstantiateMode) InferError!*T.Type {
    const resolved = ty.deref();
    switch (resolved.*) {
        .typeVar => |cell| switch (cell.state) {
            .unbound => {
                if (mode == .genericOnly) return resolved;
                if (seen.get(cell)) |fresh| return fresh;
                const fresh = try env.freshVar();
                try seen.put(cell, fresh);
                return fresh;
            },
            .generic => {
                if (seen.get(cell)) |fresh| return fresh;
                const fresh = try env.freshVar();
                try seen.put(cell, fresh);
                return fresh;
            },
            .link => unreachable, // deref follows links
        },
        .named => |n| {
            if (n.args.len == 0) return resolved;
            const args = try env.arena.alloc(*T.Type, n.args.len);
            for (n.args, 0..) |a, i| args[i] = try instantiateType(env, a, seen, mode);
            const node = try env.arena.create(T.Type);
            // 06 N24 — a tuple's element labels (decision 8 §6) live on the
            // `named` node, so instantiating a generic signature has to carry
            // them: `fn ref<T>() -> #(current: T)` lost them here and
            // `r.current` reds "this tuple has no element labeled".
            node.* = .{ .named = .{ .name = n.name, .args = args, .labels = n.labels } };
            return node;
        },
        .func => |f| {
            const params = try env.arena.alloc(*T.Type, f.params.len);
            for (f.params, 0..) |p, i| params[i] = try instantiateType(env, p, seen, mode);
            const node = try env.arena.create(T.Type);
            node.* = .{ .func = .{ .params = params, .ret = try instantiateType(env, f.ret, seen, mode) } };
            return node;
        },
        .union_ => |members| {
            const copies = try env.arena.alloc(*T.Type, members.len);
            for (members, 0..) |m, i| copies[i] = try instantiateType(env, m, seen, mode);
            const node = try env.arena.create(T.Type);
            node.* = .{ .union_ = copies };
            return node;
        },
        .record => |fields| {
            const copies = try env.arena.alloc(T.Field, fields.len);
            for (fields, 0..) |f, i| copies[i] = .{ .name = f.name, .type_ = try instantiateType(env, f.type_, seen, mode) };
            const node = try env.arena.create(T.Type);
            node.* = .{ .record = copies };
            return node;
        },
    }
}

/// True when `ty` contains a generalized (`.generic`) type variable.
/// Cheap pre-check so `instantiateGenericType` can skip allocation in the
/// common monomorphic case.
fn hasGenericVar(ty: *T.Type) bool {
    const resolved = ty.deref();
    switch (resolved.*) {
        .typeVar => |cell| return cell.state == .generic,
        .named => |n| {
            for (n.args) |a| if (hasGenericVar(a)) return true;
            return false;
        },
        .func => |f| {
            for (f.params) |p| if (hasGenericVar(p)) return true;
            return hasGenericVar(f.ret);
        },
        .union_ => |members| {
            for (members) |m| if (hasGenericVar(m)) return true;
            return false;
        },
        .record => |fields| {
            for (fields) |f| if (hasGenericVar(f.type_)) return true;
            return false;
        },
    }
}

/// Standard HM instantiation: deep-copies `ty` substituting every `.generic`
/// var with a fresh unbound one. One substitution map across params + return,
/// so `fn(x: A) -> A` yields the SAME fresh var on both sides. Two calls to
/// the same generic fn each get their own fresh vars and never conflict.
/// Returns `ty` unchanged when it has no `.generic` vars (monomorphic case).
fn instantiateGenericType(env: *Env, ty: *T.Type) InferError!*T.Type {
    if (!hasGenericVar(ty)) return ty;
    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    return instantiateType(env, ty, &seen, .genericOnly);
}

/// R3 (decision 8 §8, decision 15) — `#[@external(node, "…")]` in lower case.
///
/// The annotation grammar accepts any `#[@name(…)]`, and only the capitalised
/// path form `External.<Target>` is read as host-backed (`FnDecl.isExternal`,
/// `ast.zig`'s `startsWith("External.")`). A lower-case one therefore fell
/// through as an unknown annotation and was dropped: the `declare fn` bound no
/// host, `botopink check` exited 0, and nothing was said. Name the spelling
/// that works, at the annotation.
///
/// Only the `@`-prefixed builtin form is caught. `#[external(…)]` without the
/// `@` is a user-defined attribute — a decorator's own name — and means
/// something else entirely.
/// Decision 38 — a `val` is **immutable**, local or module-level. `val x = 0;
/// x = 1;` checked and then threw on node (`const`) and ran on the other three
/// targets; the rule moves to compile time, and the error names `var`.
fn refuseValAssign(env: *Env, name: []const u8, loc: ast.Loc) InferError!void {
    if (!env.isVal(name)) return;
    var e = TypeError.custom(
        try std.fmt.allocPrint(env.arena, "`{s}` is a `val` and cannot be assigned", .{name}),
        try std.fmt.allocPrint(env.arena, "Declare it `var {s} = …` to reassign it, or bind the new value to a new name.", .{name}),
    );
    env.lastError = e.withLoc(loc);
    return error.TypeError;
}

/// `#[@BeamMemory.<member>(…)]` on a module binding — front 17 step 3,
/// decisions 41 and 51. A misread memory annotation does not fail, it moves
/// where the state lives, so every part is checked in the commit the carrier
/// was born in: the binding is a `var`; the member is one of `ProcessDict`
/// (the default, said out loud), `Ets` or `PersistentTerm`; every argument is
/// the one the annotation takes, `keyed`, with a `true`/`false` value; and
/// `keyed = true` names a `Dict` — an `i32` has no key, and neither has a
/// list (51).
fn validateMemoryAnnotations(env: *Env, v: ast.ValDecl, bindTy: *T.Type) InferError!void {
    const members = [_][]const u8{ "ProcessDict", "Ets", "PersistentTerm" };
    for (v.annotations) |a| {
        if (!std.mem.startsWith(u8, a.name, "BeamMemory.")) continue;
        const loc = a.loc orelse v.value.getLoc();
        if (!v.mutable) return failAt(
            env,
            loc,
            try std.fmt.allocPrint(env.arena, "`#[@{s}]` needs a `var` — `{s}` is a `val`", .{ a.name, v.name }),
            try std.fmt.allocPrint(env.arena, "Write `#[@{s}] var {s}: T = …;`.", .{ a.name, v.name }),
        );
        const member = a.name["BeamMemory.".len..];
        var known = false;
        for (members) |m| known = known or std.mem.eql(u8, m, member);
        if (!known) return failAt(
            env,
            loc,
            try std.fmt.allocPrint(env.arena, "unknown member `{s}` in `@BeamMemory` — expected `ProcessDict`, `Ets` or `PersistentTerm`", .{member}),
            "The member names where the `var` lives on the BEAM; `ProcessDict` is what a `var` with no annotation means.",
        );
        for (a.writtenArgs(), 0..) |arg, i| {
            const label = a.labelOf(i) orelse arg;
            if (!std.mem.eql(u8, label, "keyed")) return failAt(
                env,
                loc,
                try std.fmt.allocPrint(env.arena, "unknown argument `{s}` — expected `keyed`", .{label}),
                try std.fmt.allocPrint(env.arena, "Write `#[@{s}(keyed = true)]`.", .{a.name}),
            );
            const is_true = std.mem.eql(u8, arg, "true");
            if (!is_true and !std.mem.eql(u8, arg, "false")) return failAt(
                env,
                loc,
                try std.fmt.allocPrint(env.arena, "`keyed` takes `true` or `false`, not `{s}`", .{arg}),
                null,
            );
            if (is_true and !typeIsDict(bindTy)) return failAt(
                env,
                loc,
                try std.fmt.allocPrint(env.arena, "`keyed` needs a keyed container — {s} has no key", .{try describeForKeyed(env, bindTy)}),
                "Only a `Dict<K, V>` is keyed; a list stores its whole value (decision 51).",
            );
        }
    }
}

fn failAt(env: *Env, loc: ast.Loc, msg: []const u8, hint: ?[]const u8) InferError {
    var e = TypeError.custom(msg, hint);
    env.lastError = e.withLoc(loc);
    return error.TypeError;
}

/// Is `t` the standard library's `Dict<K, V>`?
fn typeIsDict(t: *T.Type) bool {
    const d = t.deref();
    return switch (d.*) {
        .named => |n| std.mem.eql(u8, n.name, "Dict") or std.mem.startsWith(u8, n.name, "Dict<"),
        else => false,
    };
}

/// `an \`i32\`` / `a \`string[]\`` — the type in the `keyed` diagnostic.
fn describeForKeyed(env: *Env, t: *T.Type) ![]const u8 {
    const rendered = try snapshotMod.typeNameOf(env.arena, t);
    const article: []const u8 = if (rendered.len > 0 and std.mem.indexOfScalar(u8, "aeiouAEIOU", rendered[0]) != null) "an" else "a";
    return std.fmt.allocPrint(env.arena, "{s} `{s}`", .{ article, rendered });
}

/// Decision 37 — a record is **immutable**. `p.age = 31` and `self.count += 1`
/// both checked and both mutated in place; the decided form is a new value,
/// `Person(..p, age: 31)`, which the constructor's `..` spread already builds
/// (06 C11).
///
/// Only a receiver whose type is a record this module registered is refused.
/// Everything else keeps assigning: a receiver still an unresolved type
/// variable is an inference gap and must not red here, and a named type the env
/// cannot open — an imported record, a `@Result`/`?T` wrapper, a host object a
/// library binds — is not something this rule can speak for.
fn refuseRecordFieldAssign(
    env: *Env,
    receiver: ast.Expr,
    receiverType: *T.Type,
    field: []const u8,
    loc: ast.Loc,
) InferError!void {
    const t = receiverType.deref();
    if (t.* != .named) return;
    const typeName = t.named.name;
    const td = env.lookupTypeDef(typeName) orelse return;
    if (td != .record) return;
    // Name the receiver in the hint when it is something the author can spread:
    // a plain name (`p`, `self`). Anything else gets the shape without it.
    const spread: []const u8 = switch (receiver) {
        .identifier => |id| switch (id.kind) {
            .ident => |n| n,
            else => "…",
        },
        else => "…",
    };
    var e = TypeError.custom(
        try std.fmt.allocPrint(
            env.arena,
            "a `{s}` is immutable — its field `{s}` cannot be assigned",
            .{ typeName, field },
        ),
        try std.fmt.allocPrint(
            env.arena,
            "Build a new value instead: `{s}(..{s}, {s}: <value>)`.",
            .{ typeName, spread, field },
        ),
    );
    env.lastError = e.withLoc(loc);
    return error.TypeError;
}

fn refuseLowerCaseExternal(env: *Env, a: ast.Annotation) InferError!void {
    if (!a.is_builtin) return;
    const misspelled = std.ascii.eqlIgnoreCase(a.name, "external") or
        (std.ascii.startsWithIgnoreCase(a.name, "external.") and
            !std.mem.startsWith(u8, a.name, "External."));
    if (!misspelled) return;
    // `#[@external(node, "…")]` names its target in the first argument;
    // `#[@external.node("…")]` in the path. Either way the fix is the same
    // annotation with the target capitalised, so spell it out.
    const target: []const u8 = blk: {
        if (std.mem.indexOfScalar(u8, a.name, '.')) |i| break :blk a.name[i + 1 ..];
        const args = a.writtenArgs();
        if (args.len >= 1 and args[0].len > 0 and std.ascii.isAlphabetic(args[0][0])) break :blk args[0];
        break :blk "Node";
    };
    const capitalised = try env.arena.dupe(u8, target);
    if (capitalised.len > 0) capitalised[0] = std.ascii.toUpper(capitalised[0]);
    var e = TypeError.custom(
        try std.fmt.allocPrint(
            env.arena,
            "`#[@{s}]` binds no host — an external target is written `External.<Target>`",
            .{a.name},
        ),
        try std.fmt.allocPrint(
            env.arena,
            "Write `#[@External.{s}(\"<template>\")]`; only the capitalised path form is read as host-backed.",
            .{capitalised},
        ),
    );
    if (a.loc) |l| e = e.withLoc(l);
    env.lastError = e;
    return error.TypeError;
}

fn inferFnDecl(env: *Env, f: ast.FnDecl) InferError!*T.Type {
    // ── `@[external(…)]` annotation validation (F1) ─────────────────────────
    for (f.annotations) |a| {
        try refuseLowerCaseExternal(env, a);
        if (std.mem.startsWith(u8, a.name, "External.") and a.name.len > "External.".len) {
            try validateExternalAnnotation(env, f, a);
        }
    }

    // ── effect annotation is implementation-only (F1b) ──────────────────────
    // A `#[@<effect>]` marks a `fn` with a body; a bodyless `declare fn` (and a
    // `.d.bp` declaration) expresses its effect through the return wrapper only.
    //
    // §A3 EXCEPTION — `#[@result] declare fn` / `#[@future] declare fn` are
    // allowed when the fn carries at least one `@external(...)` annotation and
    // its return type is the matching wrapper (`@Result<R, E>` / `@Future<T,
    // E>`): the host template owns the wrapper shape, and the marker signals
    // "this declare carries effect-wrapping at the host boundary" rather than
    // wrapping a body. All other effects + the bare (no-external) form remain
    // rejected.
    if (f.body.len == 0 and f.effectAnnotation() != null) {
        const allow = blk: {
            const e = f.effectAnnotation() orelse break :blk false;
            if (e != .result and e != .future) break :blk false;
            var hasExternal = false;
            for (f.annotations) |a| {
                if (std.mem.startsWith(u8, a.name, "External.") and a.name.len > "External.".len) {
                    hasExternal = true;
                    break;
                }
            }
            if (!hasExternal) break :blk false;
            const expectedWrapper = e.returnWrapper();
            const isWrapperReturn = blk2: {
                const rt = f.returnType orelse break :blk2 false;
                break :blk2 switch (rt) {
                    .named => |n| std.mem.eql(u8, n, expectedWrapper),
                    .generic => |g| std.mem.eql(u8, g.name, expectedWrapper),
                    else => false,
                };
            };
            break :blk isWrapperReturn;
        };
        if (!allow) {
            env.lastError = TypeError.custom(
                "effect annotations mark an implementation; declare the effect in the return type",
                "A `declare fn` expresses its effect through the return wrapper (e.g. `-> @Future<T>`), with no annotation.",
            );
            return error.TypeError;
        }
    }

    // Build generic map.
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    for (f.genericParams) |gp| {
        try genericMap.put(gp.name, try env.freshVar());
    }

    // Collect typeparam constraints so call sites can validate comptime args.
    var typeparams: std.ArrayListUnmanaged(envMod.TypeparamConstraint) = .empty;
    // Collect `expr` meta-kind params so call sites capture their arguments
    // unevaluated (expr-templates F4).
    var exprParams: std.ArrayListUnmanaged(envMod.ExprParamInfo) = .empty;

    // Infer parameter types.
    var paramTypes = try env.arena.alloc(*T.Type, f.params.len);
    for (f.params, 0..) |p, i| {
        if (p.typeRef.isExprType()) {
            // An `@Expr<…>` parameter only exists at compile time — require the
            // `comptime` modifier so the binding-time is visible in the signature.
            if (p.modifier != .@"comptime") {
                env.lastError = TypeError.custom(
                    "an `@Expr` parameter requires the `comptime` modifier",
                    "Write it as `comptime name: @Expr<T>` — template arguments are captured at compile time.",
                ).withLoc(if (f.body.len > 0) f.body[0].expr.getLoc() else ast.Loc{ .line = 1, .col = 1 });
                return error.TypeError;
            }
            try exprParams.append(env.arena, .{ .paramIndex = i, .paramName = p.name });
        }
        if (p.typeRef == .typeparam) {
            const constraints = p.typeRef.typeparam;
            const names = try env.arena.alloc([]const u8, constraints.len);
            for (constraints, 0..) |c, ci| {
                names[ci] = switch (c) {
                    .named => |n| n,
                    else => "",
                };
            }
            try typeparams.append(env.arena, .{ .paramIndex = i, .paramName = p.name, .names = names });
        }
        // `fn(value: T) -> U` param: build a real func type (the typeRef is
        // just `.named "fn"`); names resolve via the generic map first.
        const ty = if (p.fnType) |ft| blk: {
            const fparams = try env.arena.alloc(*T.Type, ft.params.len);
            for (ft.params, 0..) |fp, j| {
                fparams[j] = genericMap.get(fp.typeName) orelse try env.namedType(fp.typeName);
            }
            const fret = if (ft.returnType) |rn|
                genericMap.get(rn) orelse try env.namedType(rn)
            else
                try env.namedType("void");
            break :blk try env.funcType(fparams, fret);
        } else try resolveParamType(env, p, genericMap);
        paramTypes[i] = ty;
        if (p.destruct) |d| {
            // Destructuring param: bind each field name to its type.
            const tyName: []const u8 = switch (p.typeRef) {
                .named => |n| n,
                else => "",
            };
            const maybeTypeDef = env.typeDefs.get(tyName);
            switch (d) {
                .names => |*n| {
                    for (n.fields) |fld| {
                        const fieldTy = if (maybeTypeDef) |td|
                            if (td.findField(fld.field_name)) |f_| f_.type_ else try env.freshVar()
                        else
                            try env.freshVar();
                        try env.bind(fld.bind_name, fieldTy);
                    }
                },
                .tuple_ => |t| {
                    // For tuple destructuring, we'd need the tuple element types.
                    // For now, bind each name to a fresh type variable.
                    for (t) |fname| {
                        try env.bind(fname, try env.freshVar());
                    }
                },
                .list => {}, // List destructuring — no bindings to infer
                .ctor => {}, // Constructor destructuring — handled by pattern matching
            }
        } else {
            try env.bind(p.name, ty);
        }
    }

    // Infer return type.
    const retType = if (f.returnType) |rt|
        try resolveReturnType(env, rt, f.returnTypeLoc, genericMap)
    else
        try env.namedType("void");

    // The return type decides whether `use` is allowed in the body and which
    // ContextBase every `use` must agree on (@Context F7). Scope it to the body.
    const savedFnCtx = env.fnContext;
    env.fnContext = try contextInfoFromReturn(env, f.returnType, f.effect, f.name);
    defer env.fnContext = savedFnCtx;

    // `@src().fnName` inside this body (decision 73). A lambda in the body does
    // not change it — a lambda has no name.
    const savedFnName = env.currentFnName;
    env.currentFnName = f.name;
    defer env.currentFnName = savedFnName;

    // A `-> @Expr<…>` (or `-> @ExprCustom<…>`) return marks a template
    // function: its body runs at comptime, enabling the `@expr`/`@code`
    // construction builtins (and, for the custom carrier, `q.custom`).
    const savedInTemplate = env.inTemplateFn;
    env.inTemplateFn = if (f.returnType) |rt| rt.isTemplateReturnType() else false;
    defer env.inTemplateFn = savedInTemplate;

    // Determine how `throw` is checked inside this body:
    //   - no declared return type             → unchecked (lenient: e.g. `catch throw …`)
    //   - `#[@result] fn -> @Result<D, E>`    → checked-Result effect: thrown value
    //     must match `E`; `return`/`throw` construct `{ok, V}`/`{error, E}` values
    //   - plain `fn -> @Result<D, E>`         → NO special treatment: `throw` stays
    //     a raw host exception (unchecked), values are not wrapped
    //   - any other return type               → `throw` is illegal
    const isResultFn = f.returnsResult();
    const eff = f.effect;
    var throwCtx: envMod.ThrowContext = .unchecked;
    if (f.returnType) |_| {
        throwCtx = .plain;
        if (isResultFn) {
            throwCtx = .unchecked;
            if (eff == .result) {
                const rtDeref = retType.deref();
                if (rtDeref.* == .named and rtDeref.named.args.len >= 2) {
                    throwCtx = .{ .result = rtDeref.named.args[1] };
                }
            }
        }
        // R6 (§2) — `throw` belongs to a fallible-channel effect. Allow it in
        // `#[@future]` / `#[@iterator]` / `#[@futureGenerator]` bodies too — the
        // auto-wrap in `transform.zig` rewrites each form to the right wrapper.
        // `#[@generator]` and `#[@context]` keep `.plain` (they have no error
        // channel — throwing reds with `effect-throw-without-fallible-channel`).
        if (eff) |e| switch (e) {
            .future, .iterator, .futureGenerator => throwCtx = .unchecked,
            else => {},
        };
    }
    const savedThrowCtx = env.throwContext;
    env.throwContext = throwCtx;
    defer env.throwContext = savedThrowCtx;

    // ── effect ↔ return-type validation + async/generator context (F1) ───────
    // An effect annotation must match its return wrapper (`#[@future]` →
    // `@Future<…>`, etc.); a plain `fn` must NOT return one of the async
    // wrappers (those need an effect annotation).
    const wrapperKind = classifyWrapperReturn(retType);
    const fnLoc: ?ast.Loc = if (f.body.len > 0) f.body[0].expr.getLoc() else null;
    if (eff) |e| {
        if (!effectMatchesReturn(env, e, retType)) {
            // R3 / R4 — the annotation effect kind disagrees with the return
            // wrapper kind. The diagnostic carries the stable code from
            // `comptime/diagnostics.zig` so snapshot consumers can key on it.
            const retDeref = retType.deref();
            const code: []const u8 = if (retDeref.* == .named)
                diagnostics.effect_wrapper_mismatch
            else
                diagnostics.effect_missing_wrapper;
            const msg = try std.fmt.allocPrint(
                env.arena,
                "{s}: `#[@{s}]` requires a `-> @{s}<…>` return type",
                .{ code, e.annotationName(), e.returnWrapper() },
            );
            var err = TypeError.custom(msg, "The effect annotation and the return wrapper must name the same effect.");
            if (fnLoc) |l| err = err.withLoc(l);
            env.lastError = err;
            return error.TypeError;
        }
    } else if (wrapperKind != .none) {
        var err = TypeError.custom(
            "a function returning `@Future`/`@Iterator`/`@FutureGenerator` needs an effect annotation",
            "Mark it `#[@future]` / `#[@iterator]` / `#[@futureGenerator]`.",
        );
        if (fnLoc) |l| err = err.withLoc(l);
        env.lastError = err;
        return error.TypeError;
    } else if (isResultFn) {
        // N25 / decision 8 § 9 — the wrapper without its annotation is an
        // error too. A plain `fn -> @Result<D, E>` used to be accepted and
        // given NO special treatment: `return` did not wrap, `throw` stayed a
        // raw host exception. That is a second, unwritten Result calculus; the
        // decision leaves one.
        const msg = try std.fmt.allocPrint(
            env.arena,
            "{s}: @Result needs #[@result] — a function returning `@Result<D, E>` declares its effect",
            .{diagnostics.effect_missing_annotation},
        );
        var err = TypeError.custom(
            msg,
            "Mark it `#[@result]`: `return` then carries the success value and `throw` the error channel's own (decision 8 § 9). Without the annotation the wrapper is not built.",
        );
        // 01 R9 — the caret is on the return type the rule is about, not on
        // the first statement of the body.
        if (f.returnTypeLoc.line != 0) {
            err = err.withLoc(f.returnTypeLoc);
        } else if (fnLoc) |l| err = err.withLoc(l);
        env.lastError = err;
        return error.TypeError;
    }

    // Establish the effect context (saved/restored around the body) so nested
    // `await`/`yield` validate against this function, not an enclosing one.
    const prevStarFn = env.starFn;
    const prevLabelsLen = env.labelStack.items.len;
    defer {
        env.starFn = prevStarFn;
        env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    }
    if (eff) |e| {
        // Every effect gets a body context, whatever it grants: the chain
        // decides `allowsAwait` / `allowsYield`, and a capability it does not
        // grant is REFUSED at the site rather than skipped for want of a
        // context (decision 95 + 67).
        env.starFn = starCtxFromEffect(e, retType, f.label);
        if (f.label) |lbl| try env.labelStack.append(env.arena, lbl);
    } else {
        // A plain function body sees no effect context and no outer labels.
        env.starFn = null;
        env.labelStack.shrinkRetainingCapacity(0);
    }
    // The `try` gate reads the effect directly: a `#[@result]` body answers
    // `try` and carries no star context worth asking.
    const savedFnEffect = env.fnEffect;
    env.fnEffect = eff;
    defer env.fnEffect = savedFnEffect;
    // Decision 96 — the body's `ContextBase` is fixed by its first `use`, so
    // the anchor starts empty at every body and is restored on the way out.
    const savedUseAnchor = env.useAnchor;
    env.useAnchor = null;
    defer env.useAnchor = savedUseAnchor;
    // §1C — `@getContex(T)` is only valid inside a `#[@context]` fn body
    // (RC5). Save/restore the flag around the body so nested non-context
    // closures fall back to false correctly.
    const savedInContextFn = env.inContextFn;
    env.inContextFn = if (eff) |e| e == .context else false;
    defer env.inContextFn = savedInContextFn;

    // Self-recursion: bind the fn's own signature before walking the body so
    // `pushRange(out, start + 1, stop)` inside `pushRange` resolves. (Mutual
    // recursion across decls still needs a program-level pre-pass.)
    try env.bind(f.name, try env.funcType(paramTypes, retType));

    // Register type guard info for narrowing at call sites.
    if (f.typeGuardParam) |paramName| {
        // Find the parameter index matching the guard parameter name.
        var paramIndex: usize = 0;
        for (f.params, 0..) |p, i| {
            if (std.mem.eql(u8, p.name, paramName)) {
                paramIndex = i;
                break;
            }
        }
        // Record the narrowed type name (06 C5: its own slot, not `returnType`,
        // which a guard declares as `bool`).
        const narrowedName: []const u8 = if (f.typeGuardType) |gt| switch (gt) {
            .named => |n| n,
            else => paramName,
        } else paramName;
        try env.typeGuardFns.put(f.name, .{ .paramIndex = paramIndex, .narrowedTypeName = narrowedName });
    }

    // C1 — every `return <value>` in the body unifies with the declared
    // return type, or with an effect wrapper's inner channel.
    const savedReturnTarget = env.returnTarget;
    const savedReturnBareIsVoid = env.returnBareIsVoid;
    const savedReturnWhole = env.returnWhole;
    defer {
        env.returnTarget = savedReturnTarget;
        env.returnBareIsVoid = savedReturnBareIsVoid;
        env.returnWhole = savedReturnWhole;
    }
    env.returnWhole = if (f.returnType != null) retType else null;
    env.returnTarget = if (f.typeGuardParam != null)
        // A type guard (`-> x is T`) returns `bool`; `T` is the narrowed type.
        try env.namedType("bool")
    else
        returnTargetFor(retType, eff, f.returnType != null and !env.inTemplateFn);
    // Annotations inside the body see the fn's generic params (`var acc:
    // Array<#(P, O)> = []`), so a `return acc` unifies P with P, not with an
    // opaque named `P`.
    const savedFnGenericMap = env.fnGenericMap;
    env.fnGenericMap = &genericMap;
    defer env.fnGenericMap = savedFnGenericMap;
    env.returnBareIsVoid = env.returnTarget != null and (eff == null or eff.? == .result or eff.? == .future);

    try inferBodyStmts(env, f.body);

    // Generalize (HM let-polymorphism): declared generic params still unbound
    // after the body is inferred become `.generic`. Every use site then gets a
    // fresh instantiation via `instantiateGenericType` — two calls in the same
    // scope never share vars. Params the body linked to a concrete type are
    // left alone (they were never polymorphic).
    var git = genericMap.valueIterator();
    while (git.next()) |gv| {
        const resolved = gv.*.deref();
        if (resolved.* != .typeVar) continue;
        const cell = resolved.typeVar;
        switch (cell.state) {
            .unbound => |u| cell.state = .{ .generic = u.id },
            else => {},
        }
    }

    if (typeparams.items.len > 0) {
        try env.registerTypeparams(f.name, try typeparams.toOwnedSlice(env.arena));
    }
    if (exprParams.items.len > 0) {
        try env.registerExprParams(f.name, try exprParams.toOwnedSlice(env.arena));
    }
    // A function returning `@Expr<T>` / `@ExprCustom<T>` is a template
    // function: its calls are expanded at comptime (F6) and the declaration
    // never reaches codegen.
    if (f.returnType) |rt| {
        if (rt.isTemplateReturnType()) try env.templateFns.put(f.name, f);
    }

    return env.funcType(paramTypes, retType);
}

/// Walk the bodies of a type's instance/associated methods (record / struct /
/// enum) to record the codegen instance-method lowerings (and type the calls
/// inside). Their signatures are registered earlier, but the bodies were never
/// walked — so a `self.xs.map(f)` call was neither typed nor recorded, and the
/// non-JS backends had no way to lower it.
///
/// This is BEST-EFFORT: a method whose body trips an inference gap is skipped
/// (the lowerings recorded up to that point stand; the rest fall back to the
/// backend default). Record method bodies are not part of the strict
/// type-checking contract here — only `default fn` interface bodies are (see
/// `inferInterfaceDefaultBodies`) — so a gap must not fail the whole compile.
fn inferTypeMethods(
    env: *Env,
    typeName: []const u8,
    typeGenerics: []const ast.GenericParam,
    methods: []const ast.BehaviorMethod,
) InferError!void {
    for (methods) |m| {
        const body = m.body orelse continue;
        if (m.is_declare) continue;

        // `@src().fnName` inside a method is `Type.method` (decision 73).
        const savedFnName = env.currentFnName;
        env.currentFnName = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ typeName, m.name });
        defer env.currentFnName = savedFnName;

        var genericMap = std.StringHashMap(*T.Type).init(env.arena);
        defer genericMap.deinit();

        // `Self = Type<G0, G1, …>` over fresh generics shared with the params.
        const selfArgs = try env.arena.alloc(*T.Type, typeGenerics.len);
        for (typeGenerics, 0..) |gp, i| {
            const v = try env.freshVar();
            selfArgs[i] = v;
            try genericMap.put(gp.name, v);
        }
        const selfTy = if (typeGenerics.len == 0)
            try env.namedType(typeName)
        else
            try env.namedTypeArgs(typeName, selfArgs);
        try genericMap.put("Self", selfTy);

        // Method-level generics (`mapValues<C>`).
        for (m.genericParams) |gp| try genericMap.put(gp.name, try env.freshVar());

        // Bind parameters — a `self` receiver resolves through `Self`.
        for (m.params) |p| {
            const ty = if (p.fnType) |ft| blk: {
                const fparams = try env.arena.alloc(*T.Type, ft.params.len);
                for (ft.params, 0..) |fp, j| {
                    fparams[j] = genericMap.get(fp.typeName) orelse try env.namedType(fp.typeName);
                }
                const fret = if (ft.returnType) |rn|
                    genericMap.get(rn) orelse try env.namedType(rn)
                else
                    try env.namedType("void");
                break :blk try env.funcType(fparams, fret);
            } else try resolveParamType(env, p, genericMap);
            try env.bind(p.name, ty);
        }

        // Scope the return-type-derived `use`/effect context to this body.
        const savedFnCtx = env.fnContext;
        const methodEffect = effectAnnotationOf(m.annotations);
        env.fnContext = try contextInfoFromReturn(env, m.returnType, methodEffect, m.name);
        defer env.fnContext = savedFnCtx;
        // An effect annotation on a method is the method's, exactly as on a
        // free fn (decision 8 §9): the body gets the effect's context — a
        // generator method is a generator scope for its `yield`s (decision
        // 105), a plain method none.
        const savedStarFn = env.starFn;
        const savedFnEffect = env.fnEffect;
        const savedThrowCtx = env.throwContext;
        const savedLoopDepth = env.loopDepth;
        const savedBreakScope = env.breakScope;
        const savedLabelsLen = env.labelStack.items.len;
        defer {
            env.starFn = savedStarFn;
            env.fnEffect = savedFnEffect;
            env.throwContext = savedThrowCtx;
            env.loopDepth = savedLoopDepth;
            env.breakScope = savedBreakScope;
            env.labelStack.shrinkRetainingCapacity(savedLabelsLen);
        }
        env.labelStack.shrinkRetainingCapacity(0);
        env.loopDepth = 0;
        env.breakScope = .none;
        if (methodEffect) |e| {
            const retTy = if (m.returnType) |rt| try resolveTypeRefInContext(env, rt, genericMap) else try env.freshVar();
            env.starFn = starCtxFromEffect(e, retTy, null);
            env.fnEffect = e;
            env.throwContext = if (effectChain.grants(e, .try_)) .unchecked else .plain;
        } else {
            env.starFn = null;
            env.fnEffect = null;
        }

        // 06 C9 — a method body is part of the strict contract, like a
        // `default fn` interface body (`inferInterfaceDefaultBodies`). The walk
        // used to swallow `error.TypeError` into `lastError = null`, so a real
        // mismatch inside a method compiled and only failed at run time.
        var inferredReturn: ?*T.Type = null;
        // The early-exit narrowing (`narrowAfterEarlyExit`) lives as long as
        // the block does, so it is collected here and restored below.
        var narrowed: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
        defer narrowed.deinit(env.arena);
        for (body) |stmt| {
            const typed = try inferExprTyped(env, stmt.expr);
            try narrowAfterEarlyExit(env, stmt.expr, &narrowed);
            // 06 C9 — the return type of a method that annotates none comes
            // from its body. `registerInherentMethodTypes` stores a signature
            // only for an annotated method ("rather than mis-typing them as
            // `void`"), so `d.get()` fell to the fresh-var fallback and
            // `val a: string = d.get();` compiled. Every `return <v>` in the
            // body agrees (they unify), and a bare `return` / no return leaves
            // it `void`.
            if (m.returnType == null and stmt.expr == .jump and stmt.expr.jump.kind == .@"return") {
                if (stmt.expr.jump.kind.@"return" != null) {
                    const rv = typed.jump.kind.@"return".?;
                    if (inferredReturn) |prev| {
                        try unifyAt(env, prev, rv.getType(), rv.getLoc());
                    } else {
                        inferredReturn = rv.getType();
                    }
                }
            }
        }
        if (narrowed.items.len > 0) try restorePatternBindings(env, narrowed.items);
        if (m.returnType == null) {
            const params = try env.arena.alloc(*T.Type, m.params.len);
            for (m.params, 0..) |p, i| {
                params[i] = env.lookup(p.name) orelse try env.freshVar();
            }
            const ret = inferredReturn orelse try env.namedType("void");
            try env.setInherentMethodType(typeName, m.name, try env.funcType(params, ret));
        }
    }
}

const WrapperReturnKind = enum { none, future, iterator, futureGenerator };

/// Classify a resolved return type as `@Future` / `@Iterator` / `@FutureGenerator`.
fn classifyWrapperReturn(ty: *T.Type) WrapperReturnKind {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Future"))
            .future
        else if (std.mem.eql(u8, n.name, "Iterator"))
            .iterator
        else if (std.mem.eql(u8, n.name, "FutureGenerator"))
            .futureGenerator
        else
            .none,
        else => .none,
    };
}

/// True when `retType` is the builtin wrapper named by `eff` (an unresolved
/// type variable stays lenient, matching the rest of the effect checks).
/// `#[@context]` also accepts a named type that implements `@Context<B, _>`
/// through its inline `implement` clause — the owner type of a component,
/// `#[@context] fn Widget() -> Element` (decision 88).
fn effectMatchesReturn(env: *Env, eff: ast.EffectKind, retType: *T.Type) bool {
    const t = retType.deref();
    return switch (t.*) {
        .named => |n| std.mem.eql(u8, n.name, eff.returnWrapper()) or
            (eff == .context and contextBaseOfType(env, retType) != null),
        .typeVar => true,
        else => false,
    };
}

/// Build the effect body context (drives `await`/`yield` validation) from the
/// effect kind and its return type. EVERY effect gets one — `env.starFn` is
/// null only in a plain `fn` — so a capability the chain does not grant is
/// refused rather than falling through an absent context (decision 95 + 67;
/// before this, `yield` in a `#[@result]` or `#[@context]` body was accepted
/// because the guard was written `if (env.starFn) |ctx|`).
/// C1 — the type a `return <value>` unifies with inside a fn whose declared
/// return type is `retType`: the wrapper's inner channel for an effect body
/// (`#[@result]` → R of `@Result<R, E>`, `#[@future]` → T, `#[@generator]` → R of
/// `@Generator<T, R>`, any `-> @Context<B, X>` → X), the declared type
/// otherwise. Null when returns are not checked: no declared return type, a
/// template fn, or an iterator effect (which forbids `return <expr>`).
fn returnTargetFor(retType: *T.Type, eff: ?ast.EffectKind, checked: bool) ?*T.Type {
    if (!checked) return null;
    const t = retType.deref();
    // A hook returns `@Context<B, X>` with or without `#[@context]`: its body
    // returns the `X` the `use` prefix binds (a `state` or `memo` hook).
    if (t.* == .named and std.mem.eql(u8, t.named.name, "Context") and t.named.args.len >= 2) {
        return t.named.args[1];
    }
    const e = eff orelse return retType;
    if (t.* != .named) return null;
    const args = t.named.args;
    return switch (e) {
        .result, .future => if (args.len >= 1) args[0] else null,
        .generator => if (args.len >= 2) args[1] else null,
        // A `#[@context]` fn whose return is not the `@Context<B, X>` wrapper
        // (handled above) returns its owner type as written — a component's
        // `-> Element` (decision 88).
        .context => retType,
        .iterator, .futureGenerator => null,
    };
}

fn starCtxFromEffect(eff: ast.EffectKind, retType: *T.Type, fnLabel: ?[]const u8) envMod.StarFnCtx {
    const t = retType.deref();
    const item: ?*T.Type = switch (t.*) {
        .named => |n| if (n.args.len >= 1) n.args[0] else null,
        else => null,
    };
    // §1I — `@Iterator<T, E, C>` / `@FutureGenerator<T, E, C>` carry the
    // completion type in the third argument. Default-fill (`C = void`) lands
    // via `builtinDefaultFilledArgs` before this point, so `args.len >= 3`
    // is reliable for iterator/futureGenerator.
    const completion: ?*T.Type = switch (t.*) {
        .named => |n| if (n.args.len >= 3) n.args[2] else null,
        else => null,
    };
    // `iterItem` / `iterCompletion` are the iterator channels: only the three
    // generator-shaped wrappers carry them, and `.iterator` / `.futureGenerator`
    // are the two the `break` handler reads for RI2/RI3.
    const yields = effectChain.grants(eff, .yield_);
    return .{
        .allowsAwait = effectChain.grants(eff, .await_),
        .allowsYield = yields,
        .iterItem = if (yields) item else null,
        .iterCompletion = switch (eff) {
            .iterator, .futureGenerator => completion,
            else => null,
        },
        .fnLabel = fnLabel,
        .effect = eff,
    };
}

// ── expression inference ──────────────────────────────────────────────────────

fn isIntType(t: *T.Type) bool {
    return t.isNamed("i8") or t.isNamed("u8") or
        t.isNamed("i16") or t.isNamed("u16") or
        t.isNamed("i32") or t.isNamed("u32") or
        t.isNamed("i64") or t.isNamed("u64") or
        t.isNamed("isize") or t.isNamed("usize");
}

fn isFloatType(t: *T.Type) bool {
    return t.isNamed("f32") or t.isNamed("f64");
}

/// True when `t` satisfies a single typeparam constraint named `name`.
/// Besides exact name matches, the category names `int` and `float` match any
/// integer / floating-point primitive respectively.
fn typeSatisfiesConstraint(t: *T.Type, name: []const u8) bool {
    if (t.isNamed(name)) return true;
    if (std.mem.eql(u8, name, "int")) return isIntType(t);
    if (std.mem.eql(u8, name, "float")) return isFloatType(t);
    return false;
}

/// True when index `i` names a typeparam parameter in `constraints`.
fn isTypeparamIndex(constraints: []const envMod.TypeparamConstraint, i: usize) bool {
    for (constraints) |c| {
        if (c.paramIndex == i) return true;
    }
    return false;
}

/// The `expr` param info for parameter index `i`, or null when `i` is an
/// ordinary parameter.
fn exprParamAt(params: []const envMod.ExprParamInfo, i: usize) ?envMod.ExprParamInfo {
    for (params) |p| {
        if (p.paramIndex == i) return p;
    }
    return null;
}

/// Type-check and capture an argument bound to a `comptime p: expr T`
/// parameter (expr-templates F4). The argument unifies against the **inner**
/// `T` — it is an expression *of* `T`, not a value of `expr T` — and is
/// captured unevaluated with provenance (module path, location, origin-scope
/// snapshot) for the call-site expansion pass (F6).
///
/// V1 rule (spec): a source-capable template requires a **literal** string at
/// the call site (single or multiline, interpolation allowed) — a variable
/// carries no span or scope to attach.
fn captureExprArg(
    env: *Env,
    callee: []const u8,
    param: envMod.ExprParamInfo,
    rawArg: *const ast.Expr,
    typedArg: ast.CallArgOf(.typed),
    paramType: *T.Type,
) InferError!template.CapturedExpr {
    // Inner `T` of `expr T` (`expr` is encoded as a named type with one arg);
    // a bare `expr` param already carries a fresh var as its arg.
    const pDeref = paramType.deref();
    const inner: *T.Type = if (pDeref.* == .named and pDeref.named.args.len == 1)
        pDeref.named.args[0]
    else
        try env.freshVar();
    try unifyAt(env, inner, typedArg.value.getType(), typedArg.value.getLoc());

    // V1 literal rule. `text` stays null for `${…}` templates — the parts
    // live on the captured node. A hole-less multiline literal arrives as a
    // plain `stringLit` whose content keeps the `\n` after the opening `"""`,
    // so newline presence doubles as the multiline flag.
    var text: ?[]const u8 = null;
    var multiline = false;
    var isLiteral = false;
    // `newlines` only decides `multiline` for a hole-less literal: the lexer
    // stamps every token with the line it STARTS on, so a multiline literal's
    // loc is already its opening `"""` and needs no adjustment. (It used to
    // carry the CLOSING line, which this function compensated for by
    // subtracting the content's newlines.)
    var newlines: usize = 0;
    if (rawArg.* == .literal) {
        switch (rawArg.literal.kind) {
            .stringLit => |s| {
                text = s;
                newlines = std.mem.count(u8, s, "\n");
                multiline = newlines > 0;
                isLiteral = true;
            },
            .stringTemplate => |t| {
                multiline = t.multiline;
                // `${…}` holes are assumed single-line in V1.
                for (t.parts) |p| switch (p) {
                    .text => |s| newlines += std.mem.count(u8, s, "\n"),
                    .expr => {},
                };
                isLiteral = true;
            },
            else => {},
        }
    }
    if (!isLiteral) {
        env.lastError = TypeError.custom(
            "an `expr` argument must be a literal string at the call site",
            "Write the template inline — `f \"\"\"…\"\"\"` or `f(\"…\")`; a variable carries no span or scope to capture (V1).",
        ).withLoc(typedArg.value.getLoc());
        return error.TypeError;
    }

    const litLoc = rawArg.getLoc();
    return template.CapturedExpr{
        .callee = callee,
        .paramIndex = param.paramIndex,
        .paramName = param.paramName,
        .node = rawArg,
        .text = text,
        .multiline = multiline,
        .loc = litLoc,
        .modulePath = env.modulePath,
        .scope = env.scopeSnapshot,
    };
}

/// Register a template function imported from another module (expr-templates
/// F6-full): the export registry carries the full `FnDecl` so the importing
/// module can expand its calls. Derives the `@Expr` param infos the call-site
/// capture logic needs. NOTE (V1 hygiene caveat, recorded): code the template
/// builds re-infers in the *caller's* scope — library helpers it references
/// must be visible there.
pub fn registerImportedTemplateFn(env: *Env, name: []const u8, decl: ast.FnDecl) !void {
    try env.templateFns.put(name, decl);
    var infos: std.ArrayListUnmanaged(envMod.ExprParamInfo) = .empty;
    for (decl.params, 0..) |p, i| {
        if (p.typeRef.isExprType()) {
            try infos.append(env.arena, .{ .paramIndex = i, .paramName = p.name });
        }
    }
    if (infos.items.len > 0) {
        try env.registerExprParams(name, try infos.toOwnedSlice(env.arena));
    }
}

/// Register a nominal type (record/struct/enum) imported from another module.
/// The export registry carries the full declaration so the importing module can
/// rebuild the `TypeDef` — its `implements` / `contextBase` and fields, not just
/// the constructor value binding. Without this, an imported type's `implement`
/// clause is invisible here (e.g. the `use`-legality check `contextInfoFromReturn`
/// looks up `env.lookupTypeDef` and would find nothing). This mirrors the
/// `from "std"` type-export path, which re-runs `registerTypeDecl` over the
/// module's `pub` type decls. Registering in the importing env also re-binds the
/// constructor with this module's own type ids.
pub fn registerImportedTypeDecl(env: *Env, decl: ast.DeclKind) !void {
    try registerTypeDecl(env, decl);
}

/// 01 R2 — importing a type registers the closure of the types its
/// declaration mentions (field types and method signature types,
/// transitively) from the module it comes from, so `import { User }` works
/// when `User(role: Role)` and `Role` was not named in the clause. Each type
/// of the closure is registered as a TYPE only: the constructor and variant
/// bindings its registration adds are removed again — naming it in the
/// import is what brings its constructor into scope. Call before registering
/// `decl` itself: its fields resolve against the closure.
pub fn registerImportedTypeClosure(
    env: *Env,
    moduleDecls: std.StringHashMap(ast.DeclKind),
    decl: ast.DeclKind,
) !void {
    try registerTypeClosureDepth(env, moduleDecls, decl, 0);
}

fn registerTypeClosureDepth(
    env: *Env,
    moduleDecls: std.StringHashMap(ast.DeclKind),
    decl: ast.DeclKind,
    depth: usize,
) !void {
    if (depth >= 32 or decl != .type_) return;
    const td = decl.type_;
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    defer names.deinit(env.arena);
    for (td.recordFields()) |f| try collectTypeRefNames(env, f.typeRef, &names);
    for (td.variants()) |v| for (v.fields) |f| try collectTypeRefNames(env, f.typeRef, &names);
    for (td.methods) |m| {
        for (m.params) |p| try collectTypeRefNames(env, p.typeRef, &names);
        if (m.returnType) |rt| try collectTypeRefNames(env, rt, &names);
    }
    for (names.items) |n| {
        if (std.mem.eql(u8, n, td.name)) continue;
        if (env.lookupTypeDef(n) != null) continue;
        const dep = moduleDecls.get(n) orelse continue;
        if (dep != .type_) continue;
        try registerTypeClosureDepth(env, moduleDecls, dep, depth + 1);
        if (env.lookupTypeDef(n) != null) continue;
        // Register the type, then take back the bindings it added.
        var before = std.StringHashMap(void).init(env.arena);
        defer before.deinit();
        var kit = env.bindings.keyIterator();
        while (kit.next()) |k| try before.put(k.*, {});
        try registerTypeDecl(env, dep);
        var added: std.ArrayListUnmanaged([]const u8) = .empty;
        defer added.deinit(env.arena);
        var ait = env.bindings.keyIterator();
        while (ait.next()) |k| if (!before.contains(k.*)) try added.append(env.arena, k.*);
        for (added.items) |k| _ = env.bindings.remove(k);
    }
}

fn collectTypeRefNames(env: *Env, ref: ast.TypeRef, out: *std.ArrayListUnmanaged([]const u8)) !void {
    switch (ref) {
        .named => |n| try out.append(env.arena, n),
        .array => |e| try collectTypeRefNames(env, e.*, out),
        .optional => |e| try collectTypeRefNames(env, e.*, out),
        .tuple_ => |es| for (es) |e| try collectTypeRefNames(env, e, out),
        .labeledTuple => |lt| for (lt.elems) |e| try collectTypeRefNames(env, e, out),
        .function => |f| {
            for (f.params) |e| try collectTypeRefNames(env, e, out);
            try collectTypeRefNames(env, f.returnType.*, out);
        },
        .generic => |g| {
            try out.append(env.arena, g.name);
            for (g.args) |e| try collectTypeRefNames(env, e, out);
        },
        .typeparam => |cs| for (cs) |e| try collectTypeRefNames(env, e, out),
    }
}

// ── template call-site expansion (expr-templates F6, V1 driver) ───────────────

/// Expand a call to a template function (`-> @Expr<…>`) at the call site.
///
/// The V1 driver expands bodies of the form `return E` where `E` is an
/// identifier naming an `@Expr` parameter (pass-through: the captured
/// template splices in), `@expr(E)` (explicit value/expression lift), or
/// `@code("…")` (parse generated source text into code). Construction is
/// always explicit — there is no implicit value lifting. Richer bodies
/// (template methods, control flow) need the comptime evaluation runtime —
/// F6-full, not this driver.
///
/// Splice + re-check: the expansion is re-inferred in the *caller's*
/// environment, then checked against a bounded return (`-> @Expr<T>`); a
/// bare `-> @Expr` reveals the expansion's own structural type per call
/// site. The expansion is recorded in `env.templateExpansions` (keyed by
/// call loc) and substituted into the untyped AST by the transform pass —
/// codegen never sees the call or the template function.
fn expandTemplateCall(
    env: *Env,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    retType: *T.Type,
    loc: ast.Loc,
) InferError!TypedExpr {
    const body = classifyTemplateBody(tfn, captures) orelse {
        // Not reducible by inspection — run the body in the eval runtime
        // (F6-full). Tooling paths carry no eval context and keep the error.
        if (env.templateEval != null) {
            return expandTemplateCallViaRuntime(env, tfn, captures, plainArgs, retType, loc);
        }
        env.lastError = TypeError.custom(
            "cannot expand this template function at compile time",
            "The V1 expansion driver supports bodies of the form `return <@Expr param>`, `return @expr(value)`, or `return @code(\"…\")` with a literal string; richer bodies need the eval runtime (full `compile` pipeline).",
        ).withLoc(loc);
        return error.TypeError;
    };

    const expansion: *const ast.Expr = switch (body) {
        .capture, .lifted => |node| node,
        .code => |src| parseCodeText(env, src) orelse {
            env.lastError = TypeError.custom(
                "the `@code(…)` text does not parse as an expression",
                "The string handed to `@code` must be a single well-formed botopink expression.",
            ).withLoc(loc);
            return error.TypeError;
        },
    };

    return finishExpansion(env, expansion, retType, loc);
}

/// Splice + re-check the chosen expansion in the caller's environment, verify
/// a concrete `-> @Expr<T>` bound (an unconstrained generic reveals the type
/// per call site instead), and record the substitution for the transform pass.
fn finishExpansion(env: *Env, expansion: *const ast.Expr, retType: *T.Type, loc: ast.Loc) InferError!TypedExpr {
    const typed = try inferExprTyped(env, expansion.*);

    // The expansion carries only the executable `code` half (the `ast` tree is
    // stored separately for tooling). Verify it against the declared bound for
    // both carriers: `@Expr<T>` (named "Expr") and `@ExprCustom<T>` (the
    // `CustomExpr<T>` struct), whose `T` is the code's value type.
    const rDeref = retType.deref();
    if (rDeref.* == .named and rDeref.named.args.len == 1 and
        (std.mem.eql(u8, rDeref.named.name, "Expr") or std.mem.eql(u8, rDeref.named.name, "CustomExpr")))
    {
        const bound = rDeref.named.args[0];
        if (bound.deref().* != .typeVar) {
            try unifyAt(env, bound, typed.getType(), loc);
        }
    }

    try env.templateExpansions.put(loc, expansion);
    return typed;
}

/// Run the template body in the node eval runtime and turn the protocol
/// result into an expansion (F6-full, slice 1). Limits (recorded follow-ups):
/// every parameter must be an `@Expr` capture (runtime params have no
/// comptime value) and captured templates must be hole-free (`${…}` parts
/// cannot cross into the evaluator yet).
fn expandTemplateCallViaRuntime(
    env: *Env,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    retType: *T.Type,
    loc: ast.Loc,
) InferError!TypedExpr {
    const ctx = env.templateEval.?;

    // All params must be accounted for: each is either an @Expr capture or a
    // plain-arg literal. Runtime params (no value at compile time) are rejected.
    if (captures.len + plainArgs.len != tfn.params.len) {
        env.lastError = TypeError.custom(
            "template function has parameters without compile-time values (V1)",
            "Every parameter must be either `comptime p: @Expr<T>` or receive a literal value at the call site.",
        ).withLoc(loc);
        return error.TypeError;
    }
    // Memoize by callee + capture texts + scope JSON + plain arg values —
    // hole-free captures only: a holed template's expansion embeds the call
    // site's own hole expressions, so equal text parts at two sites would alias
    // the wrong holes. Scope JSON catches scope-change invalidation (a binding
    // added/removed between builds).
    var holed = false;
    for (captures) |cap| {
        if (cap.text == null) holed = true;
    }
    // `@ExprCustom<T>` calls are never memoized: each expansion also stores a
    // reference `CustomNode` tree keyed by *this* call's location, so the
    // evaluation must run per call site (the memo cache holds only the `code`
    // expression). Custom templates are opt-in and rare — correctness over the
    // node round-trip saving.
    const isCustomRet = blk: {
        const d = retType.deref();
        break :blk d.* == .named and std.mem.eql(u8, d.named.name, "CustomExpr");
    };
    const memoKey: ?[]const u8 = if (holed or isCustomRet) null else blk: {
        var buf: std.ArrayListUnmanaged(u8) = .empty;
        buf.appendSlice(env.arena, tfn.name) catch return error.OutOfMemory;
        for (captures) |cap| {
            buf.append(env.arena, 0) catch return error.OutOfMemory;
            buf.appendSlice(env.arena, cap.text.?) catch return error.OutOfMemory;
            if (cap.scope) |scope| {
                buf.append(env.arena, 0) catch return error.OutOfMemory;
                const scopeJson = scope.toJsonAlloc(env.arena) catch return error.OutOfMemory;
                buf.appendSlice(env.arena, scopeJson) catch return error.OutOfMemory;
            }
        }
        for (plainArgs) |pa| {
            buf.append(env.arena, 0) catch return error.OutOfMemory;
            buf.appendSlice(env.arena, pa.paramName) catch return error.OutOfMemory;
            buf.append(env.arena, 1) catch return error.OutOfMemory;
            buf.appendSlice(env.arena, pa.source) catch return error.OutOfMemory;
        }
        break :blk buf.toOwnedSlice(env.arena) catch return error.OutOfMemory;
    };
    if (memoKey) |key| {
        if (env.templateEvalCache.get(key)) |cached| {
            return finishExpansion(env, cached, retType, loc);
        }
    }

    const outcome = templateEval.evaluate(env.arena, ctx.io, ctx.build_root, tfn, captures, plainArgs, &env.comptimeTraces) catch {
        env.lastError = TypeError.custom(
            "the template evaluator failed to run",
            "Template bodies run in a persistent `erl` process at compile time — check that `erl` and `erlc` are on PATH.",
        ).withLoc(loc);
        return error.TypeError;
    };

    const expansion: *const ast.Expr = switch (outcome) {
        .code => |src| blk: {
            const parsed = parseCodeText(env, src) orelse {
                env.lastError = TypeError.custom(
                    "the code built by the template does not parse as an expression",
                    "`build(…)`/`@code(…)` output must be a single well-formed botopink expression.",
                ).withLoc(loc);
                return error.TypeError;
            };
            // Splice the caller's `${…}` hole expressions back in place of
            // the `__bp_hole_<param>_<i>` placeholders the template embedded.
            substituteHoles(@constCast(parsed), captures);
            break :blk parsed;
        },
        .capture => |param| captureNodeFor(captures, param) orelse {
            env.lastError = TypeError.custom(
                "the template returned an unknown capture",
                "This is a template-evaluator protocol bug — please report it.",
            ).withLoc(loc);
            return error.TypeError;
        },
        .custom => |c| blk: {
            // The `code` half is spliced exactly like a plain `.code` outcome —
            // runtime/codegen never learn it came from `q.custom`.
            const parsed = parseCodeText(env, c.code) orelse {
                env.lastError = TypeError.custom(
                    "the code built by the template does not parse as an expression",
                    "`q.custom(tree, code)` — the `code` must be a single well-formed botopink expression (e.g. from `q.build(…)`).",
                ).withLoc(loc);
                return error.TypeError;
            };
            substituteHoles(@constCast(parsed), captures);
            // The `ast` half: the reference tree the template built.
            const root = template.parseCustomNodeFromTree(env.arena, c.ast) catch return error.OutOfMemory;
            const prov: ?*const template.CapturedExpr = if (captures.len > 0) &captures[0] else null;
            env.customAstByLoc.put(loc, .{
                .callee = tfn.name,
                .root = root,
                .file = if (prov) |p| p.modulePath else env.modulePath,
                .line = if (prov) |p| p.loc.line else loc.line,
                .col = if (prov) |p| p.loc.col else loc.col,
            }) catch return error.OutOfMemory;
            break :blk parsed;
        },
        .value => |v| valueToAstLiteral(env, v, loc, liftShapeOf(env, tfn)) orelse {
            env.lastError = TypeError.custom(
                "the template's `@expr(…)` value cannot be lifted as a literal",
                "V1 lifts numbers, strings, booleans, null, and arrays of those.",
            ).withLoc(loc);
            return error.TypeError;
        },
        .fail => |f| {
            const cap: ?*const template.CapturedExpr = blk: {
                if (f.param) |pn| for (captures) |*c| {
                    if (std.mem.eql(u8, c.paramName, pn)) break :blk c;
                };
                break :blk if (captures.len > 0) &captures[0] else null;
            };
            if (cap) |c| {
                env.lastError = template.failDiagnostic(c, f.span, f.message);
            } else {
                env.lastError = TypeError.custom(f.message, "raised by the template function via `fail`/`failAt`").withLoc(loc);
            }
            return error.TypeError;
        },
        .err => |msg| {
            env.lastError = TypeError.custom(
                msg,
                "Thrown while evaluating the template function's body at compile time.",
            ).withLoc(loc);
            return error.TypeError;
        },
    };

    if (memoKey) |key| {
        env.templateEvalCache.put(key, expansion) catch return error.OutOfMemory;
    }
    return finishExpansion(env, expansion, retType, loc);
}

/// Replace `__bp_hole_<param>_<i>` placeholder identifiers in freshly parsed
/// template output with the caller's hole expressions (the i-th `${…}` part
/// of the named capture). The parsed tree is private to this expansion, so
/// in-place mutation is safe. Walks every expression-bearing position the
/// surface produces — closure / fn bodies, branches, loops, bindings, jumps —
/// so a template that splices its hole inside a lambda body (e.g. a query
/// DSL building `{ row -> row.x == __bp_hole_q_0 }`) still resolves.
fn substituteHoles(e: *ast.Expr, captures: []const template.CapturedExpr) void {
    switch (e.*) {
        .identifier => |id| switch (id.kind) {
            .ident => |name| {
                const hole = holeForPlaceholder(name, captures) orelse return;
                e.* = hole.*;
            },
            .identAccess => |ia| substituteHoles(ia.receiver, captures),
            else => {},
        },
        .binaryOp => |b| {
            substituteHoles(b.lhs, captures);
            substituteHoles(b.rhs, captures);
        },
        .unaryOp => |u| substituteHoles(u.expr, captures),
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (cc.receiver) |r| substituteHoles(r, captures);
                for (cc.args) |arg| substituteHoles(arg.value, captures);
                for (cc.trailing) |tl| substituteHolesStmts(tl.body, captures);
            },
            .pipeline => |pl| {
                substituteHoles(pl.lhs, captures);
                substituteHoles(pl.rhs, captures);
            },
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| substituteHoles(g, captures),
            .arrayLit => |al| for (al.elems) |*elem| substituteHoles(elem, captures),
            .tupleLit => |tl| for (tl.elems) |*elem| substituteHoles(elem, captures),
            else => {},
        },
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |t| for (t.parts) |part| switch (part) {
                .text => {},
                .expr => |hole| substituteHoles(hole, captures),
            },
            else => {},
        },
        .function => |fe| substituteHolesStmts(fe.kind.body, captures),
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                substituteHoles(i.cond, captures);
                substituteHolesStmts(i.then_, captures);
                if (i.else_) |els| substituteHolesStmts(els, captures);
            },
            .tryCatch => |tc| {
                substituteHoles(tc.expr, captures);
                substituteHoles(tc.handler, captures);
            },
        },
        .loop => |lp| {
            substituteHoles(lp.iter, captures);
            if (lp.indexRange) |ir| substituteHoles(ir, captures);
            substituteHolesStmts(lp.body, captures);
        },
        .binding => |bd| switch (bd.kind) {
            .localBind => |lb| substituteHoles(lb.value, captures),
            .assign => |as| {
                switch (as.target) {
                    .name => {},
                    .fieldAccess => |fa| substituteHoles(fa.receiver, captures),
                }
                substituteHoles(as.value, captures);
            },
            .localBindDestruct => |dd| substituteHoles(dd.value, captures),
        },
        .jump => |jp| switch (jp.kind) {
            .@"return" => |r| if (r) |expr| substituteHoles(expr, captures),
            .throw_ => |t| if (t) |expr| substituteHoles(expr, captures),
            .try_ => |t| if (t) |expr| substituteHoles(expr, captures),
            .await_ => |a| substituteHoles(a, captures),
            .@"break" => |b| if (b.value) |expr| substituteHoles(expr, captures),
            .@"continue" => {},
            .yield => |y| if (y.value) |expr| substituteHoles(expr, captures),
        },
        else => {},
    }
}

/// Walk a statement list and run `substituteHoles` over each statement's
/// expression. Used for function bodies, branch arms, loop bodies — every
/// place the surface threads a `[]Stmt` instead of a single expression.
fn substituteHolesStmts(stmts: []ast.Stmt, captures: []const template.CapturedExpr) void {
    for (stmts) |*s| substituteHoles(&s.expr, captures);
}

/// Resolve a `__bp_hole_<param>_<i>` placeholder to the i-th `${…}` hole
/// expression of the named capture, or null for ordinary identifiers.
fn holeForPlaceholder(name: []const u8, captures: []const template.CapturedExpr) ?*const ast.Expr {
    const prefix = "__bp_hole_";
    if (!std.mem.startsWith(u8, name, prefix)) return null;
    const rest = name[prefix.len..];
    const sep = std.mem.lastIndexOfScalar(u8, rest, '_') orelse return null;
    const param = rest[0..sep];
    const idx = std.fmt.parseInt(usize, rest[sep + 1 ..], 10) catch return null;

    for (captures) |cap| {
        if (!std.mem.eql(u8, cap.paramName, param)) continue;
        if (cap.node.* != .literal or cap.node.literal.kind != .stringTemplate) return null;
        var holeIdx: usize = 0;
        for (cap.node.literal.kind.stringTemplate.parts) |part| switch (part) {
            .text => {},
            .expr => |hole| {
                if (holeIdx == idx) return hole;
                holeIdx += 1;
            },
        };
        return null;
    }
    return null;
}

/// The labels of a tuple a template lifts (decision 8 §6), read from the
/// template body: `return @expr(#(server, debug))` labels its elements
/// `server` and `debug`, and `val server = #(host, port)` earlier in the body
/// labels the nested tuple. Children follow the elements; null = unlabeled.
const LiftShape = struct {
    labels: []const []const u8,
    children: []const ?*const LiftShape,
};

/// The shape of the value `tfn` lifts through `return @expr(E)` — the first
/// such return in the body — or null when the body builds no labeled tuple.
fn liftShapeOf(env: *Env, tfn: ast.FnDecl) ?*const LiftShape {
    for (tfn.body) |stmt| {
        if (stmt.expr != .jump or stmt.expr.jump.kind != .@"return") continue;
        const ret = stmt.expr.jump.kind.@"return" orelse continue;
        if (ret.* != .call or ret.call.kind != .call) continue;
        const cc = ret.call.kind.call;
        if (!cc.is_builtin or cc.args.len != 1 or !std.mem.eql(u8, cc.callee, "expr")) continue;
        return shapeOfExpr(env, tfn.body, cc.args[0].value.*, 0);
    }
    return null;
}

fn shapeOfExpr(env: *Env, body: []const ast.Stmt, e: ast.Expr, depth: usize) ?*const LiftShape {
    if (depth > 16) return null;
    switch (e) {
        .identifier => |id| {
            if (id.kind != .ident) return null;
            // The last `val`/`var` binding of that name in the body.
            var bound: ?*const ast.Expr = null;
            for (body) |stmt| {
                if (stmt.expr == .binding and stmt.expr.binding.kind == .localBind) {
                    const lb = stmt.expr.binding.kind.localBind;
                    if (std.mem.eql(u8, lb.name, id.kind.ident)) bound = lb.value;
                }
            }
            return if (bound) |b| shapeOfExpr(env, body, b.*, depth + 1) else null;
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| return shapeOfExpr(env, body, g.*, depth + 1),
            .tupleLit => |tl| {
                const labels = env.arena.alloc([]const u8, tl.elems.len) catch return null;
                const children = env.arena.alloc(?*const LiftShape, tl.elems.len) catch return null;
                for (tl.elems, 0..) |elem, i| {
                    labels[i] = if (elem == .identifier and elem.identifier.kind == .ident) elem.identifier.kind.ident else "";
                    children[i] = shapeOfExpr(env, body, elem, depth + 1);
                }
                const shape = env.arena.create(LiftShape) catch return null;
                shape.* = .{ .labels = labels, .children = children };
                return shape;
            },
            else => return null,
        },
        else => return null,
    }
}

/// Build a literal expression from a TypedValue produced by template evaluation.
/// A tuple takes the labels `shape` names; an object (a map the host built)
/// lifts as a tuple labeled by its keys.
fn valueToAstLiteral(env: *Env, v: templateEval.TypedValue, loc: ast.Loc, shape: ?*const LiftShape) ?*const ast.Expr {
    const node = env.arena.create(ast.Expr) catch return null;
    switch (v) {
        .integer => |n| {
            const text = std.fmt.allocPrint(env.arena, "{d}", .{n}) catch return null;
            node.* = .{ .literal = .{ .loc = loc, .kind = .{ .numberLit = text } } };
        },
        .float => |f| {
            const text = std.fmt.allocPrint(env.arena, "{d}", .{f}) catch return null;
            node.* = .{ .literal = .{ .loc = loc, .kind = .{ .numberLit = text } } };
        },
        .string => |str| {
            const text = env.arena.dupe(u8, str) catch return null;
            node.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = text } } };
        },
        .bool => |b| {
            node.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = if (b) "true" else "false" } } };
        },
        .null => {
            node.* = .{ .literal = .{ .loc = loc, .kind = .null_ } };
        },
        .array => |items| {
            const elems = env.arena.alloc(ast.Expr, items.len) catch return null;
            for (items, 0..) |item, i| {
                const elem = valueToAstLiteral(env, item, loc, null) orelse return null;
                elems[i] = elem.*;
            }
            node.* = .{ .collection = .{ .loc = loc, .kind = .{ .arrayLit = .{ .elems = elems } } } };
        },
        .tuple => |items| {
            // The yaml case: the template computes a structure and the caller
            // gets a fully typed tuple whose labels come from the body.
            const matches = if (shape) |sh| sh.labels.len == items.len else false;
            const elems = env.arena.alloc(ast.Expr, items.len) catch return null;
            for (items, 0..) |item, i| {
                const child: ?*const LiftShape = if (matches) shape.?.children[i] else null;
                const elem = valueToAstLiteral(env, item, loc, child) orelse return null;
                elems[i] = elem.*;
            }
            node.* = .{ .collection = .{ .loc = loc, .kind = .{ .tupleLit = .{
                .elems = elems,
                .labels = if (matches) shape.?.labels else &.{},
            } } } };
        },
        .object => |pairs| {
            // A map built by host code lifts as a tuple labeled by its keys.
            const elems = env.arena.alloc(ast.Expr, pairs.len) catch return null;
            const labels = env.arena.alloc([]const u8, pairs.len) catch return null;
            for (pairs, 0..) |pair, i| {
                const value = valueToAstLiteral(env, pair.value, loc, null) orelse return null;
                elems[i] = value.*;
                labels[i] = env.arena.dupe(u8, pair.key) catch return null;
            }
            node.* = .{ .collection = .{ .loc = loc, .kind = .{ .tupleLit = .{ .elems = elems, .labels = labels } } } };
        },
    }
    return node;
}

/// What a V1-expandable template body (`return E`) reduces to. Construction
/// is explicit: no implicit value lifting — a constant only becomes code via
/// `@expr(…)`, and generated source only via `@code(…)`.
const TemplateBody = union(enum) {
    /// `return <expr param>` — the captured argument splices in unchanged.
    capture: *const ast.Expr,
    /// `return @expr(E)` — lift the explicit expression as code.
    lifted: *const ast.Expr,
    /// `return @code("…")` — parse the source text into code.
    code: []const u8,
};

/// Classify a template body for the V1 expansion driver, or null when the
/// body needs the runtime-backed evaluator (F6-full).
fn classifyTemplateBody(tfn: ast.FnDecl, captures: []const template.CapturedExpr) ?TemplateBody {
    if (tfn.body.len != 1) return null;
    const stmt = tfn.body[0];
    if (stmt.expr != .jump) return null;
    if (stmt.expr.jump.kind != .@"return") return null;
    const ret = stmt.expr.jump.kind.@"return" orelse return null;

    switch (ret.*) {
        // `return template` — pass-through: an @Expr param IS an expr value.
        .identifier => |id| {
            if (id.kind != .ident) return null;
            const node = captureNodeFor(captures, id.kind.ident) orelse return null;
            return .{ .capture = node };
        },
        // `return @expr(E)` / `return @code("…")` — explicit construction.
        .call => |c| {
            if (c.kind != .call) return null;
            const cc = c.kind.call;
            if (!cc.is_builtin or cc.args.len != 1) return null;
            const arg = cc.args[0].value;
            if (std.mem.eql(u8, cc.callee, "expr")) {
                // A lifted expression must not reference the template's own
                // parameters — splicing `t` into the caller would leave an
                // unbound name. Such bodies go to the eval runtime instead.
                for (tfn.params) |p| {
                    if (specializeMod.identInExpr(arg.*, p.name)) return null;
                }
                return if (isV1Liftable(arg)) .{ .lifted = arg } else null;
            }
            if (std.mem.eql(u8, cc.callee, "code")) {
                if (arg.* == .literal and arg.literal.kind == .stringLit) {
                    return .{ .code = arg.literal.kind.stringLit };
                }
                return null;
            }
            return null;
        },
        else => return null,
    }
}

/// Parse `@code` source text into an expression (allocated in the env arena).
/// Null when the text fails to lex/parse as a single expression.
fn parseCodeText(env: *Env, src: []const u8) ?*const ast.Expr {
    var lx = Lexer.init(src);
    const tokens = lx.scanAll(env.arena) catch return null;
    var p = Parser.init(tokens);
    const node = env.arena.create(ast.Expr) catch return null;
    node.* = p.parseExpr(env.arena) catch return null;
    if (!p.check(.endOfFile)) return null;
    return node;
}

/// The source lexeme of a literal (or bool-identifier) argument bound to a plain
/// template parameter (`template.PlainArg.source`). Returns null when the
/// expression is not a supported constant (string, number, null, true/false).
fn literalSourceAlloc(arena: std.mem.Allocator, expr: *const ast.Expr) error{OutOfMemory}!?[]const u8 {
    // Booleans are identifiers in the AST (not literal nodes).
    if (expr.* == .identifier) {
        const name = switch (expr.identifier.kind) {
            .ident => |n| n,
            else => return null,
        };
        if (std.mem.eql(u8, name, "true")) return "true";
        if (std.mem.eql(u8, name, "false")) return "false";
        return null;
    }
    if (expr.* != .literal) return null;
    return switch (expr.literal.kind) {
        // stringLit holds the literal's raw content (escapes unprocessed).
        .stringLit => |s| try std.fmt.allocPrint(arena, "\"{s}\"", .{s}),
        // numberLit is stored as raw source text.
        .numberLit => |n| try std.fmt.allocPrint(arena, "{s}", .{n}),
        .null_ => "null",
        else => null,
    };
}

/// The captured argument bound to the `@Expr` parameter named `name`.
fn captureNodeFor(captures: []const template.CapturedExpr, name: []const u8) ?*const ast.Expr {
    for (captures) |cap| {
        if (std.mem.eql(u8, cap.paramName, name)) return cap.node;
    }
    return null;
}

/// True when `e` is a V1-liftable expression for `@expr(…)` — literals,
/// identifiers, operators, calls, collections. Control flow is conservatively
/// left to the runtime-backed evaluator (F6-full).
fn isV1Liftable(e: *const ast.Expr) bool {
    return switch (e.*) {
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| isV1Liftable(inner),
            else => false,
        },
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |t| blk: {
                for (t.parts) |p| switch (p) {
                    .text => {},
                    .expr => |hole| if (!isV1Liftable(hole)) break :blk false,
                };
                break :blk true;
            },
            else => true,
        },
        .identifier => |id| switch (id.kind) {
            .identAccess => |ia| isV1Liftable(ia.receiver),
            else => true,
        },
        .binaryOp => |b| isV1Liftable(b.lhs) and isV1Liftable(b.rhs),
        .unaryOp => |u| isV1Liftable(u.expr),
        .call => |c| switch (c.kind) {
            .call => |cc| blk: {
                if (cc.receiver) |r| if (!isV1Liftable(r)) break :blk false;
                for (cc.args) |a| if (!isV1Liftable(a.value)) break :blk false;
                break :blk true;
            },
            .pipeline => |p| isV1Liftable(p.lhs) and isV1Liftable(p.rhs),
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| isV1Liftable(g),
            .arrayLit => |al| blk: {
                for (al.elems) |*elem| if (!isV1Liftable(elem)) break :blk false;
                break :blk true;
            },
            .tupleLit => |tl| blk: {
                for (tl.elems) |*elem| if (!isV1Liftable(elem)) break :blk false;
                break :blk true;
            },
            else => false,
        },
        else => false,
    };
}

/// Validate every constrained typeparam argument of a call against its declared
/// constraints. Unconstrained typeparams (empty `names`) accept any type.
/// On violation: sets `env.lastError` and returns `error.TypeError`.
fn validateTypeparams(
    env: *Env,
    constraints: []const envMod.TypeparamConstraint,
    typedArgs: []ast.CallArgOf(.typed),
) InferError!void {
    for (constraints) |c| {
        if (c.names.len == 0) continue; // unconstrained — accepts any type
        if (c.paramIndex >= typedArgs.len) continue;
        const argType = typedArgs[c.paramIndex].value.getType();
        var ok = false;
        for (c.names) |name| {
            if (typeSatisfiesConstraint(argType, name)) {
                ok = true;
                break;
            }
        }
        if (!ok) {
            env.lastError = TypeError
                .typeparamConstraint(c.paramName, argType, c.names)
                .withLoc(typedArgs[c.paramIndex].value.getLoc());
            return error.TypeError;
        }
    }
}

/// Calls `unify` and, if it fails, stamps the expression's location onto the error.
fn unifyAt(env: *Env, a: *T.Type, b: *T.Type, loc: ast.Loc) InferError!void {
    // `Children` coercion — applied before unification since `unifyAt` is
    // always called target-first (`unifyAt(param, arg)`).
    if (childrenCoercion(env, a, b)) return;
    unify(env, a, b) catch |err| {
        if (env.lastError) |*e| e.loc = loc;
        return err;
    };
}

/// True when `target` names a behavior and `source` is a named type that
/// declares `implement <target>` — a `MockCounter` returned where the fn
/// declares `-> Counter`.
fn behaviorCoercion(env: *Env, target: *T.Type, source: *T.Type) bool {
    const t = target.deref();
    const s = source.deref();
    if (t.* != .named or s.* != .named) return false;
    if (std.mem.eql(u8, t.named.name, s.named.name)) return false;
    const td = env.lookupTypeDef(s.named.name) orelse return false;
    const impls = switch (td) {
        .record => |r| r.implements,
        .struct_ => |st| st.implements,
        .enum_ => |e| e.implements,
    };
    for (impls) |i| if (behaviorReaches(env, i, t.named.name, 0)) return true;
    return false;
}

/// 01 R4 — whether behavior `from` is `to` or extends it, through the
/// `extends` chain. `depth` bounds a cyclic chain.
fn behaviorReaches(env: *Env, from: []const u8, to: []const u8, depth: usize) bool {
    if (std.mem.eql(u8, from, to)) return true;
    if (depth >= 16) return false;
    const decl = env.assocInterfaceDecls.get(from) orelse return false;
    for (decl.extends) |parent| {
        if (behaviorReaches(env, parent, to, depth + 1)) return true;
    }
    return false;
}

/// 01 R4 — an argument meets its declared parameter. A parameter (or a
/// constructor field) typed by a behavior accepts a value whose type
/// implements that behavior, directly or through `extends`; everything else
/// is `unifyAt`. Target-first, like `unifyAt`: the coercion only ever widens
/// an implementer into the behavior, never the reverse.
fn unifyArgument(env: *Env, param: *T.Type, arg: *T.Type, loc: ast.Loc) InferError!void {
    if (behaviorCoercion(env, param, arg)) return;
    try unifyAt(env, param, arg, loc);
}

/// True when `source` coerces into a `Children`-typed `target`. A `Children`
/// parameter (the builder children model a markup DSL's `div { … }` needs)
/// accepts another `Children`, any array (`Element[]` — the list form), a
/// `string` (→ a text child), or a single value implementing `@Context` (an
/// `Element` → a one-element list). Coercion is one-directional: it only fires
/// when the *declared* type (`target`) is `Children`, never the reverse.
fn childrenCoercion(env: *Env, target: *T.Type, source: *T.Type) bool {
    const t = target.deref();
    if (t.* != .named or !std.mem.eql(u8, t.named.name, "Children")) return false;
    const s = source.deref();
    return switch (s.*) {
        .named => |n| std.mem.eql(u8, n.name, "Children") or
            std.mem.eql(u8, n.name, "array") or
            std.mem.eql(u8, n.name, "string") or
            contextBaseOfType(env, source) != null,
        else => false,
    };
}
fn inferBuiltinCallReturnType(
    env: *Env,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!*T.Type {
    // `@block { … }` — the value of the block is what its `return`s carry
    // (C1: those returns target the block, not the enclosing fn); a block
    // without a valued `return` takes its tail expression's type.
    if (std.mem.eql(u8, callee, "block") and typedTrailing.len >= 1 and env.lastTrailingReturnTargets.len >= 1) {
        const target = env.lastTrailingReturnTargets[0];
        const td = target.deref();
        if (td.* == .typeVar and td.typeVar.state == .unbound) {
            const body = typedTrailing[0].body;
            if (body.len > 0 and body[body.len - 1].expr != .jump) return body[body.len - 1].expr.getType();
            return env.namedType("void");
        }
        return target;
    }
    // ── `@Expr` construction builtins (expr-templates) ───────────────────────
    // Construction is explicit: `@expr(value)` lifts a comptime value as code
    // and `@code(text)` parses generated source text. Both only make sense
    // inside a template function (`-> @Expr<…>`), whose body runs at comptime.
    if (std.mem.eql(u8, callee, "expr") or std.mem.eql(u8, callee, "code")) {
        if (!env.inTemplateFn) {
            var e = TypeError.custom(
                "`@expr`/`@code` build comptime code — only valid inside a template function",
                "Declare the enclosing fn with a `-> @Expr<…>` return type.",
            );
            if (typedArgs.len >= 1) e = e.withLoc(typedArgs[0].value.getLoc());
            env.lastError = e;
            return error.TypeError;
        }
        if (std.mem.eql(u8, callee, "expr")) {
            // `@expr(v)`: the result is an expression OF the value's type.
            const inner: *T.Type = if (typedArgs.len >= 1) typedArgs[0].value.getType() else try env.freshVar();
            return env.namedTypeArgs("Expr", &.{inner});
        }
        // `@code(text)`: the produced expression's type is revealed at expansion.
        if (typedArgs.len >= 1) {
            try unifyAt(env, try env.namedType("string"), typedArgs[0].value.getType(), typedArgs[0].value.getLoc());
        }
        return env.namedTypeArgs("Expr", &.{try env.freshVar()});
    }

    // ── Type introspection / manipulation builtins (§1.0.0-beta) ─────────────
    // `@typeInfo(T: type) -> TypeInfo` — returns a TypeInfo enum variant
    // describing the structure of T. Comptime-only: evaluated during inference,
    // produces zero runtime code.
    if (std.mem.eql(u8, callee, "typeInfo")) {
        // Accept any type expression (identifier, array, optional, etc.).
        // Type-checking ensures the argument is a type, so no additional
        // validation is needed here — the inference system handles it.
        return env.namedType("TypeInfo");
    }
    // `@TypeOf(value: any) -> type` — returns the type of any value.
    // Comptime-only.
    if (std.mem.eql(u8, callee, "TypeOf")) {
        if (typedArgs.len > 0) return typedArgs[0].value.getType();
        return env.freshVar();
    }
    // `@makeRecord(fields: RecordField[]) -> type` — creates a new record type
    // from field descriptors. Comptime-only.
    if (std.mem.eql(u8, callee, "makeRecord")) {
        return env.freshVar();
    }
    // `@RecordKeys(T: type) -> string[]` — returns field name strings of a
    // record type. Comptime-only.
    if (std.mem.eql(u8, callee, "RecordKeys")) {
        // C6: the same `array` type a `string[]` annotation resolves to.
        return try env.namedTypeArgs("array", &.{try env.namedType("string")});
    }
    // `@Field(value: any, comptime name: string) -> any` — field access by
    // compile-time-known name. Comptime-only.
    if (std.mem.eql(u8, callee, "field")) {
        // C6: `@field(v, "x")` has the type of v's field `x` when the receiver
        // is a known non-generic record and the name is a literal; otherwise it
        // stays open (a fresh var), never the receiver's type.
        if (typedArgs.len >= 2) fieldBlk: {
            const recv = typedArgs[0].value.getType().deref();
            if (recv.* != .named) break :fieldBlk;
            const nameLit = switch (typedArgs[1].value.*) {
                .literal => |l| switch (l.kind) {
                    .stringLit => |str| str,
                    else => break :fieldBlk,
                },
                else => break :fieldBlk,
            };
            const td = env.lookupTypeDef(recv.named.name) orelse break :fieldBlk;
            const fields = switch (td) {
                .record => |r| if (r.genericParams.len == 0) r.fields else break :fieldBlk,
                .struct_ => |st| if (st.genericParams.len == 0) st.fields else break :fieldBlk,
                .enum_ => break :fieldBlk,
            };
            for (fields) |fd| {
                if (std.mem.eql(u8, fd.name, nameLit)) return fd.type_;
            }
            env.lastError = TypeError.unknownField(recv.named.name, nameLit).withLoc(typedArgs[1].value.getLoc());
            return error.TypeError;
        }
        return env.freshVar();
    }
    // `@emit(source)` — a comptime body (a decorator) contributes generated
    // top-level declarations, spliced into its module. Void; the source is parsed
    // + inferred in a second pass over the module (see `analyzeModule`).
    if (std.mem.eql(u8, callee, "emit")) {
        if (typedArgs.len >= 1) {
            try unifyAt(env, try env.namedType("string"), typedArgs[0].value.getType(), typedArgs[0].value.getLoc());
        }
        return env.namedType("void");
    }
    // §1C — `@getContex(T)` fetches the active provider of type `T` from
    // the context scope stack. The argument is a TYPE (not a value); the
    // intrinsic is only valid inside a `#[@context]` fn body. RC1 (no
    // active provider) requires the `contextStack.zig` provider tracker
    // — landed separately; RC3 (Anchor-tree reachability) is wired here.
    if (std.mem.eql(u8, callee, "getContex")) {
        // RC5 — outside a `#[@context]` fn body the intrinsic is meaningless.
        if (!env.inContextFn) {
            var e = TypeError.custom(
                diagnostics.context_getcontex_outside_context_fn ++
                    ": `@getContex(T)` only resolves inside a `#[@context]` fn body",
                "Mark the enclosing fn `#[@context]` (`-> @Context<Base, T>`) — `@getContex` walks the active provider stack maintained by the `use` blocks.",
            );
            if (typedArgs.len >= 1) e = e.withLoc(typedArgs[0].value.getLoc());
            env.lastError = e;
            return error.TypeError;
        }
        // RC4 — the argument must be a type reference (a record / struct /
        // enum name), never a value expression. The parser already wrapped
        // values as `Expr`; we detect non-identifier arg shapes here.
        if (typedArgs.len >= 1) {
            const arg = typedArgs[0].value;
            const isTypeIdent = arg.* == .identifier and arg.identifier.kind == .ident and
                env.lookupTypeDef(arg.identifier.kind.ident) != null;
            if (!isTypeIdent) {
                env.lastError = TypeError.custom(
                    diagnostics.context_getcontex_expects_type ++
                        ": `@getContex(T)` expects a type as its sole argument",
                    "Pass a record/struct/enum name (the type whose provider you want to fetch); literals and value expressions are not accepted.",
                ).withLoc(arg.getLoc());
                return error.TypeError;
            }
            // RC3 (§1C / F4C-T4) — the requested type's `contextBase` must
            // match the enclosing fn's Anchor. A type whose Anchor is a
            // different tree is statically out of reach: no `use` chain in
            // this fn can ever provide it, since every `use` site lives
            // under the fn's Anchor by RC2. The `inContextFn` flag (RC5)
            // guarantees `env.fnContext` is set when we reach this arm.
            const requestedName = arg.identifier.kind.ident;
            const requestedBase = env.lookupTypeDef(requestedName).?.contextBase();
            const enclosingBase: ?[]const u8 = if (env.fnContext) |fc| fc.base else null;
            if (requestedBase != null and enclosingBase != null and
                !std.mem.eql(u8, requestedBase.?, enclosingBase.?))
            {
                const msg = try std.fmt.allocPrint(
                    env.arena,
                    "{s}: `@getContex({s})` is outside the enclosing `#[@context]` fn's Anchor tree (enclosing Anchor `{s}`, requested type's Anchor `{s}`)",
                    .{ diagnostics.context_getcontex_anchor_violation, requestedName, enclosingBase.?, requestedBase.? },
                );
                env.lastError = TypeError.custom(
                    msg,
                    "Either provide the requested type under an Anchor reachable from the enclosing fn, or change the enclosing fn's `@Context<Base, …>` to share an Anchor with the requested type.",
                ).withLoc(arg.getLoc());
                return error.TypeError;
            }
            // Best-effort return type: the named user type. RC1 (active
            // provider check) needs the contextStack runtime to land.
            return env.namedType(requestedName);
        }
        return env.freshVar();
    }
    // `@comptimeError(message)` — report a compile-time error from comptime
    // code. Takes a string message and sets env.lastError, causing inference
    // to fail with a custom type error.
    if (std.mem.eql(u8, callee, "comptimeError")) {
        if (typedArgs.len >= 1) {
            const arg = typedArgs[0].value;
            const msg: []const u8 = switch (arg.*) {
                .literal => |lit| switch (lit.kind) {
                    .stringLit => |s| s,
                    else => "<non-string argument>",
                },
                else => "<non-literal argument>",
            };
            env.lastError = TypeError.custom(
                try std.fmt.allocPrint(env.arena, "comptime error: {s}", .{msg}),
                "This error was raised by @comptimeError during type checking.",
            ).withLoc(arg.getLoc());
            return error.TypeError;
        }
        env.lastError = TypeError.custom(
            "comptime error",
            "@comptimeError called without a message.",
        );
        return error.TypeError;
    }
    // The runtime builtins (`@print`, `@panic`, `@todo`, …) are typed by the
    // backends; here they are `void` placeholders. Anything else is a typo —
    // refuse it (decision 67) instead of compiling it to `void` in silence.
    if (isKnownBuiltinName(env, callee)) return env.namedType("void");
    env.lastError = TypeError.custom(
        try unknownBuiltinMessage(env, callee),
        "Builtin names are exact and lowercase (`@print`, `@panic`, `@src`); see `libs/std/src/builtins.d.bp` for the list.",
    ).withLoc(loc);
    return error.TypeError;
}

/// The type name `@src()` answers with (decision 73). Declared in
/// `comptime.zig`'s `decl_reflection_src`; spliced into a program that names it
/// by `withSourceLocationDecl`.
const source_location_type_name = "SourceLocation";

/// The builtin fns that reach `inferBuiltinCallReturnType`'s fallback by
/// design: runtime builtins the backends lower natively (`@print`, `@debug`,
/// `@trap`, …), plus the `declare fn`s of `builtins_fns.d.bp` (`@panic`,
/// `@todo`) and the `print`/`println` bindings `registerBuiltins` seeds.
const runtime_builtin_names = [_][]const u8{
    "print", "println", "debug", "panic", "todo", "trap", "compilerError", "module", "emit", "is",
};

/// Every `@name` the checker or a backend understands — the arms of
/// `inferBuiltinCallReturnType` and the intercepts in `inferCallExpr` included.
/// Only read to suggest a spelling in `unknown-builtin`.
const all_builtin_names = runtime_builtin_names ++ [_][]const u8{
    "src",        "block",      "expr",  "code",      "typeInfo",      "TypeOf",
    "makeRecord", "RecordKeys", "field", "getContex", "comptimeError",
};

fn isKnownBuiltinName(env: *Env, callee: []const u8) bool {
    for (runtime_builtin_names) |n| {
        if (std.mem.eql(u8, n, callee)) return true;
    }
    // The parser's own sugar: `xs[i]` lands as the `[]` builtin call. C-02
    // intercepts it in `inferCallExpr` and it no longer reaches the `void`
    // fallback below; the name stays known so a `[]` that survived a degraded
    // module is not reported as a misspelled builtin.
    if (std.mem.eql(u8, callee, ast.index_builtin_name)) return true;
    return env.stdlibFnDecls.contains(callee);
}

/// `unknown-builtin: unknown builtin \`@name\`` — with the nearest known name
/// when one is an edit away (`@pritn` → `@print`), the way `removedBuiltinType`
/// points at a replacement.
fn unknownBuiltinMessage(env: *Env, callee: []const u8) ![]const u8 {
    for (all_builtin_names) |candidate| {
        if (editDistanceIsOne(callee, candidate)) {
            return std.fmt.allocPrint(
                env.arena,
                "{s}: unknown builtin `@{s}` — did you mean `@{s}`?",
                .{ diagnostics.unknown_builtin, callee, candidate },
            );
        }
    }
    return std.fmt.allocPrint(env.arena, "{s}: unknown builtin `@{s}`", .{ diagnostics.unknown_builtin, callee });
}

/// True when `a` becomes `b` by one substitution, one insertion, one deletion
/// or one adjacent transposition (case-insensitive: `@Src` is one edit from
/// `@src`).
fn editDistanceIsOne(a: []const u8, b: []const u8) bool {
    if (std.ascii.eqlIgnoreCase(a, b)) return a.len > 0 and !std.mem.eql(u8, a, b);
    if (a.len == b.len) {
        var diffs: usize = 0;
        var first: ?usize = null;
        for (a, b, 0..) |ca, cb, i| {
            if (std.ascii.toLower(ca) != std.ascii.toLower(cb)) {
                diffs += 1;
                if (first == null) first = i;
            }
        }
        if (diffs == 1) return true;
        if (diffs == 2) {
            const i = first.?;
            return i + 1 < a.len and
                std.ascii.toLower(a[i]) == std.ascii.toLower(b[i + 1]) and
                std.ascii.toLower(a[i + 1]) == std.ascii.toLower(b[i]);
        }
        return false;
    }
    const long, const short = if (a.len > b.len) .{ a, b } else .{ b, a };
    if (long.len != short.len + 1) return false;
    var i: usize = 0;
    var j: usize = 0;
    var skipped = false;
    while (i < long.len and j < short.len) {
        if (std.ascii.toLower(long[i]) == std.ascii.toLower(short[j])) {
            i += 1;
            j += 1;
        } else {
            if (skipped) return false;
            skipped = true;
            i += 1;
        }
    }
    return true;
}

/// `@src()` (1.0.10-beta front 01-std, decision 73): a `SourceLocation(file,
/// line, column, fnName)` naming the call site, evaluated here and never at
/// run time. The call is rewritten into the ordinary constructor call
/// `SourceLocation(file: "<env.srcPath>", line: L, column: C, fnName: "<env.currentFnName>")`
/// with four literal arguments: the typed node is that call (so the typed AST
/// carries the record type) and the untyped rewrite is recorded in
/// `env.srcRewrites` for the transform pass to splice, the way `@makeRecord`
/// and template expansions are. Every backend then lowers it through the
/// record-constructor path it already has — no codegen file knows `@src`.
///
/// `line`/`column` are the 1-based position of the `@` token — the numbers a
/// diagnostic prints; `file` is the package-relative path (`env.srcPath`);
/// `fnName` is the enclosing fn / `Type.method` / test name, `""` at module
/// level. Zero arguments, no trailing lambda: anything else is
/// `src-takes-no-arguments`.
fn inferSrcBuiltin(env: *Env, call: anytype, loc: ast.Loc) InferError!TypedExpr {
    if (call.args.len != 0 or call.trailing.len != 0) {
        env.lastError = TypeError.custom(
            diagnostics.src_takes_no_arguments ++ ": `@src()` takes no arguments",
            "Write `@src()` — the location is the call site's own; there is nothing to pass.",
        ).withLoc(loc);
        return error.TypeError;
    }
    env.usesSourceLocation = true;

    const strLit = struct {
        fn make(e: *Env, l: ast.Loc, text: []const u8) !*ast.Expr {
            const node = try e.arena.create(ast.Expr);
            node.* = .{ .literal = .{ .loc = l, .kind = .{ .stringLit = text } } };
            return node;
        }
        fn number(e: *Env, l: ast.Loc, n: usize) !*ast.Expr {
            const node = try e.arena.create(ast.Expr);
            node.* = .{ .literal = .{ .loc = l, .kind = .{ .numberLit = try std.fmt.allocPrint(e.arena, "{d}", .{n}) } } };
            return node;
        }
    };
    const args = try env.arena.alloc(ast.CallArg, 4);
    args[0] = .{ .label = "file", .value = try strLit.make(env, loc, env.srcPath) };
    args[1] = .{ .label = "line", .value = try strLit.number(env, loc, loc.line) };
    args[2] = .{ .label = "column", .value = try strLit.number(env, loc, loc.col) };
    args[3] = .{ .label = "fnName", .value = try strLit.make(env, loc, env.currentFnName) };
    const rewrite = try env.arena.create(ast.Expr);
    rewrite.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = source_location_type_name,
        .is_builtin = false,
        .args = args,
        .trailing = &.{},
    } } } };
    try env.srcRewrites.put(loc, rewrite);
    return inferExprTyped(env, rewrite.*);
}

/// Evaluate `@makeRecord(fields)` at inference time when `fields` is a literal
/// array of RecordField values. Extracts field names and type names from the
/// untyped AST, looks up the types, and creates a synthetic record type.
///
/// Returns a TypedExpr on success, null when the argument cannot be statically
/// evaluated (delegates to the general builtin path which returns a fresh var).
fn tryEvalMakeRecord(env: *Env, arg: ast.Expr, loc: ast.Loc) InferError!?TypedExpr {
    switch (arg) {
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                if (al.elems.len == 0) {
                    // Empty record.
                    return try makeSyntheticRecordType(env, &.{});
                }
                var fields: std.ArrayListUnmanaged(envMod.FieldDef) = .empty;
                for (al.elems) |*elem| {
                    // Each element should be a call: RecordField(name: "x", typeName: "i32")
                    switch (elem.*) {
                        .call => |ec| switch (ec.kind) {
                            .call => |ecc| {
                                var fieldName: ?[]const u8 = null;
                                var typeName: ?[]const u8 = null;
                                for (ecc.args) |farg| {
                                    if (farg.label) |label| {
                                        if (std.mem.eql(u8, label, "name")) {
                                            switch (farg.value.*) {
                                                .literal => |lit| switch (lit.kind) {
                                                    .stringLit => |s| fieldName = s,
                                                    else => {},
                                                },
                                                else => {},
                                            }
                                        } else if (std.mem.eql(u8, label, "typeName")) {
                                            switch (farg.value.*) {
                                                .literal => |lit| switch (lit.kind) {
                                                    .stringLit => |s| typeName = s,
                                                    else => {},
                                                },
                                                else => {},
                                            }
                                        }
                                    }
                                }
                                const name = fieldName orelse {
                                    env.lastError = TypeError.custom(
                                        "@makeRecord: RecordField missing 'name'",
                                        "Each RecordField must have a 'name' label.",
                                    ).withLoc(loc);
                                    return error.TypeError;
                                };
                                const tname = typeName orelse {
                                    env.lastError = TypeError.custom(
                                        "@makeRecord: RecordField missing 'typeName'",
                                        "Each RecordField must have a 'typeName' label.",
                                    ).withLoc(loc);
                                    return error.TypeError;
                                };
                                // Resolve the type name to a Type.
                                const ty = try env.namedType(tname);
                                try fields.append(env.arena, .{ .name = name, .type_ = ty });
                            },
                            else => return null,
                        },
                        else => return null,
                    }
                }
                return try makeSyntheticRecordType(env, fields.items);
            },
            else => return null,
        },
        else => return null,
    }
}

/// Resolve comptime type-manipulation calls (§1.0.0-beta Steps 4-6).
/// These are std functions (`mergeRecords`, `mapFields`, `partial`, `omit`,
/// `pick`) that operate on types at compile time. They are resolved entirely
/// during inference and produce zero runtime code.
///
/// Returns a TypedExpr on match, or null when the callee is not a known
/// type-manipulation function.
fn tryResolveTypeManipulationCall(
    env: *Env,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?TypedExpr {
    _ = typedTrailing;
    if (!std.mem.eql(u8, callee, "mergeRecords") and
        !std.mem.eql(u8, callee, "mapFields") and
        !std.mem.eql(u8, callee, "partial") and
        !std.mem.eql(u8, callee, "omit") and
        !std.mem.eql(u8, callee, "pick"))
    {
        return null;
    }

    // Dispatch per function.
    if (std.mem.eql(u8, callee, "mergeRecords")) {
        return try resolveMergeRecords(env, typedArgs, loc);
    }
    if (std.mem.eql(u8, callee, "partial")) {
        return try resolvePartial(env, typedArgs, loc);
    }
    if (std.mem.eql(u8, callee, "omit")) {
        return try resolveOmit(env, typedArgs, loc);
    }
    if (std.mem.eql(u8, callee, "pick")) {
        return try resolvePick(env, typedArgs, loc);
    }
    // mapFields: takes a lambda transform — not yet implemented.
    return null;
}

/// Resolve `mergeRecords(A, B)` — merge two record types into one.
fn resolveMergeRecords(env: *Env, typedArgs: []ast.CallArgOf(.typed), loc: ast.Loc) InferError!TypedExpr {
    if (typedArgs.len < 2) {
        env.lastError = TypeError.custom(
            "mergeRecords expects two type arguments",
            "Usage: mergeRecords(comptime A: type, comptime B: type) -> type",
        ).withLoc(loc);
        return error.TypeError;
    }
    const nameA = resolveTypeArgName(env, typedArgs[0].value, "mergeRecords", "first", loc) orelse return error.TypeError;
    const nameB = resolveTypeArgName(env, typedArgs[1].value, "mergeRecords", "second", loc) orelse return error.TypeError;

    const defA = env.lookupTypeDef(nameA) orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "mergeRecords: '{s}' is not a known record type", .{nameA}),
            "Only named record types can be merged.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };
    const fieldsA = defA.fields() orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "mergeRecords: '{s}' is not a record type", .{nameA}),
            "Only record types can be merged.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };
    const defB = env.lookupTypeDef(nameB) orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "mergeRecords: '{s}' is not a known record type", .{nameB}),
            "Only named record types can be merged.",
        ).withLoc(typedArgs[1].value.getLoc());
        return error.TypeError;
    };
    const fieldsB = defB.fields() orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "mergeRecords: '{s}' is not a record type", .{nameB}),
            "Only record types can be merged.",
        ).withLoc(typedArgs[1].value.getLoc());
        return error.TypeError;
    };

    // Check for conflicts: same name, different types.
    for (fieldsA) |fa| {
        for (fieldsB) |fb| {
            if (std.mem.eql(u8, fa.name, fb.name)) {
                // Types must be structurally equal.
                if (!typesEqual(fa.type_, fb.type_)) {
                    const msg = std.fmt.allocPrint(env.arena, "mergeRecords: field '{s}' has conflicting types in the two records", .{fa.name}) catch "mergeRecords: conflicting field types";
                    env.lastError = TypeError.custom(
                        msg,
                        "Fields with the same name must have identical types.",
                    ).withLoc(loc);
                    return error.TypeError;
                }
            }
        }
    }

    // Build merged field list: A's fields first, then B's non-duplicate fields.
    var mergedFields: std.ArrayListUnmanaged(envMod.FieldDef) = .empty;
    for (fieldsA) |f| try mergedFields.append(env.arena, f);
    for (fieldsB) |fb| {
        var duplicate = false;
        for (fieldsA) |fa| {
            if (std.mem.eql(u8, fa.name, fb.name)) {
                duplicate = true;
                break;
            }
        }
        if (!duplicate) try mergedFields.append(env.arena, fb);
    }

    return try makeSyntheticRecordType(env, mergedFields.items);
}

/// Resolve `partial(T)` — make all fields optional.
fn resolvePartial(env: *Env, typedArgs: []ast.CallArgOf(.typed), loc: ast.Loc) InferError!TypedExpr {
    if (typedArgs.len < 1) {
        env.lastError = TypeError.custom(
            "partial expects a type argument",
            "Usage: partial(comptime T: type) -> type",
        ).withLoc(loc);
        return error.TypeError;
    }
    const name = resolveTypeArgName(env, typedArgs[0].value, "partial", "first", loc) orelse return error.TypeError;
    const def = env.lookupTypeDef(name) orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "partial: '{s}' is not a known record type", .{name}),
            "Only named record types can be made partial.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };
    const fields = def.fields() orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "partial: '{s}' is not a record type", .{name}),
            "Only record types can be made partial.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };

    // Wrap each field's type in an optional.
    var partialFields = try env.arena.alloc(envMod.FieldDef, fields.len);
    for (fields, 0..) |f, i| {
        const optTy = try env.arena.create(T.Type);
        const args = try env.arena.alloc(*T.Type, 1);
        args[0] = f.type_;
        optTy.* = .{ .named = .{ .name = "optional", .args = args } };
        partialFields[i] = .{ .name = f.name, .type_ = optTy };
    }

    return try makeSyntheticRecordType(env, partialFields);
}

/// Resolve `omit(T, name)` — remove a single field by name.
fn resolveOmit(env: *Env, typedArgs: []ast.CallArgOf(.typed), loc: ast.Loc) InferError!TypedExpr {
    if (typedArgs.len < 2) {
        env.lastError = TypeError.custom(
            "omit expects a type and a field name",
            "Usage: omit(comptime T: type, comptime name: string) -> type",
        ).withLoc(loc);
        return error.TypeError;
    }
    const typeName = resolveTypeArgName(env, typedArgs[0].value, "omit", "first", loc) orelse return error.TypeError;
    const fieldName = resolveStringArg(env, typedArgs[1].value, "omit", "second", loc) orelse return error.TypeError;

    const def = env.lookupTypeDef(typeName) orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "omit: '{s}' is not a known record type", .{typeName}),
            "Only named record types support omit.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };
    const fields = def.fields() orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "omit: '{s}' is not a record type", .{typeName}),
            "Only record types support omit.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };

    // Collect all fields except the named one.
    var kept: std.ArrayListUnmanaged(envMod.FieldDef) = .empty;
    var found = false;
    for (fields) |f| {
        if (std.mem.eql(u8, f.name, fieldName)) {
            found = true;
        } else {
            try kept.append(env.arena, f);
        }
    }
    if (!found) {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "omit: field '{s}' not found in type '{s}'", .{ fieldName, typeName }),
            "The field name must exist in the record type.",
        ).withLoc(typedArgs[1].value.getLoc());
        return error.TypeError;
    }

    return try makeSyntheticRecordType(env, kept.items);
}

/// Resolve `pick(T, names)` — keep only specified fields.
fn resolvePick(env: *Env, typedArgs: []ast.CallArgOf(.typed), loc: ast.Loc) InferError!TypedExpr {
    if (typedArgs.len < 2) {
        env.lastError = TypeError.custom(
            "pick expects a type and field names",
            "Usage: pick(comptime T: type, comptime names: string[]) -> type",
        ).withLoc(loc);
        return error.TypeError;
    }
    const typeName = resolveTypeArgName(env, typedArgs[0].value, "pick", "first", loc) orelse return error.TypeError;

    // The second arg is a string array literal.
    const names = resolveStringArrayArg(env, typedArgs[1].value, "pick", loc) orelse return error.TypeError;

    const def = env.lookupTypeDef(typeName) orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "pick: '{s}' is not a known record type", .{typeName}),
            "Only named record types support pick.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };
    const fields = def.fields() orelse {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "pick: '{s}' is not a record type", .{typeName}),
            "Only record types support pick.",
        ).withLoc(typedArgs[0].value.getLoc());
        return error.TypeError;
    };

    // Keep only fields whose name is in the names list.
    var kept: std.ArrayListUnmanaged(envMod.FieldDef) = .empty;
    for (names) |name| {
        var found = false;
        for (fields) |f| {
            if (std.mem.eql(u8, f.name, name)) {
                try kept.append(env.arena, f);
                found = true;
                break;
            }
        }
        if (!found) {
            env.lastError = TypeError.custom(
                try std.fmt.allocPrint(env.arena, "pick: field '{s}' not found in type '{s}'", .{ name, typeName }),
                "All field names must exist in the record type.",
            ).withLoc(loc);
            return error.TypeError;
        }
    }

    return try makeSyntheticRecordType(env, kept.items);
}

/// Extract a type name from a typed argument that should be a type reference.
fn resolveTypeArgName(env: *Env, arg: *const ast.TypedExpr, fn_name: []const u8, pos: []const u8, loc: ast.Loc) ?[]const u8 {
    _ = loc;
    switch (arg.*) {
        .identifier => |id| if (id.kind == .ident) {
            const name = id.kind.ident;
            if (env.lookupTypeDef(name) != null) return name;
            // Also accept primitive type names.
            if (env.lookup(name) != null) return name;
        },
        else => {},
    }
    const msg = std.fmt.allocPrint(env.arena, "{s}: {s} argument must be a type name", .{ fn_name, pos }) catch {
        env.lastError = TypeError.custom("out of memory", "").withLoc(arg.getLoc());
        return null;
    };
    env.lastError = TypeError.custom(
        msg,
        "Pass a record type name, not a value or expression.",
    ).withLoc(arg.getLoc());
    return null;
}

/// Extract a string literal from a typed argument.
fn resolveStringArg(env: *Env, arg: *const ast.TypedExpr, fn_name: []const u8, pos: []const u8, loc: ast.Loc) ?[]const u8 {
    _ = loc;
    switch (arg.*) {
        .literal => |lit| switch (lit.kind) {
            .stringLit => |s| return s,
            else => {},
        },
        else => {},
    }
    const msg = std.fmt.allocPrint(env.arena, "{s}: {s} argument must be a string literal", .{ fn_name, pos }) catch {
        env.lastError = TypeError.custom("out of memory", "").withLoc(arg.getLoc());
        return null;
    };
    env.lastError = TypeError.custom(
        msg,
        "Pass a string literal (e.g. \"fieldName\"), not a variable.",
    ).withLoc(arg.getLoc());
    return null;
}

/// Extract a string array from a typed argument (for pick's names parameter).
fn resolveStringArrayArg(env: *Env, arg: *const ast.TypedExpr, fn_name: []const u8, loc: ast.Loc) ?[]const []const u8 {
    _ = loc;
    switch (arg.*) {
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                var names: std.ArrayListUnmanaged([]const u8) = .empty;
                for (al.elems) |*elem| {
                    switch (elem.*) {
                        .literal => |lit| switch (lit.kind) {
                            .stringLit => |s| names.append(env.arena, s) catch {
                                env.lastError = TypeError.custom("out of memory", "").withLoc(arg.getLoc());
                                return null;
                            },
                            else => {
                                const msg = std.fmt.allocPrint(env.arena, "{s}: all array elements must be string literals", .{fn_name}) catch {
                                    env.lastError = TypeError.custom("out of memory", "").withLoc(arg.getLoc());
                                    return null;
                                };
                                env.lastError = TypeError.custom(
                                    msg,
                                    "Each element should be a string like \"fieldName\".",
                                ).withLoc(arg.getLoc());
                                return null;
                            },
                        },
                        else => {
                            const msg = std.fmt.allocPrint(env.arena, "{s}: all array elements must be string literals", .{fn_name}) catch {
                                env.lastError = TypeError.custom("out of memory", "").withLoc(arg.getLoc());
                                return null;
                            };
                            env.lastError = TypeError.custom(
                                msg,
                                "Each element should be a string like \"fieldName\".",
                            ).withLoc(arg.getLoc());
                            return null;
                        },
                    }
                }
                return names.items;
            },
            else => {},
        },
        else => {},
    }
    const msg = std.fmt.allocPrint(env.arena, "{s}: second argument must be a string array literal", .{fn_name}) catch {
        env.lastError = TypeError.custom("out of memory", "").withLoc(arg.getLoc());
        return null;
    };
    env.lastError = TypeError.custom(
        msg,
        "Pass a string array like [\"name\", \"id\"].",
    ).withLoc(arg.getLoc());
    return null;
}

/// Check if two types are structurally equal (deref and compare).
fn typesEqual(a: *T.Type, b: *T.Type) bool {
    const ta = a.deref();
    const tb = b.deref();
    switch (ta.*) {
        .named => |na| switch (tb.*) {
            .named => |nb| {
                if (!std.mem.eql(u8, na.name, nb.name)) return false;
                if (na.args.len != nb.args.len) return false;
                for (na.args, 0..) |arg_a, i| {
                    if (!typesEqual(arg_a, nb.args[i])) return false;
                }
                return true;
            },
            else => return false,
        },
        .record => |ra| switch (tb.*) {
            .record => |rb| {
                if (ra.len != rb.len) return false;
                for (ra, 0..) |fa, i| {
                    if (!std.mem.eql(u8, fa.name, rb[i].name)) return false;
                    if (!typesEqual(fa.type_, rb[i].type_)) return false;
                }
                return true;
            },
            else => return false,
        },
        .func => |fa| switch (tb.*) {
            .func => |fb| {
                if (fa.params.len != fb.params.len) return false;
                for (fa.params, 0..) |p, i| {
                    if (!typesEqual(p, fb.params[i])) return false;
                }
                return typesEqual(fa.ret, fb.ret);
            },
            else => return false,
        },
        .typeVar => |ca| {
            if (ca == tb.typeVar) return true;
            switch (tb.*) {
                .typeVar => |cb| return ca == cb,
                else => return false,
            }
        },
        .union_ => return false,
    }
}

/// Create a synthetic/anonymous record type from field definitions and return
/// a TypedExpr holding the type value.
fn makeSyntheticRecordType(env: *Env, fields: []envMod.FieldDef) !TypedExpr {
    const typeId = env.allocTypeId();
    const syntheticName = try std.fmt.allocPrint(env.arena, "#synth_{d}", .{typeId});

    // Build the record Type (anonymous structural record).
    var recordFields = try env.arena.alloc(T.Field, fields.len);
    for (fields, 0..) |f, i| {
        recordFields[i] = .{ .name = f.name, .type_ = f.type_ };
    }
    const recordTy = try env.arena.create(T.Type);
    recordTy.* = .{ .record = recordFields };

    // Register the type definition so it can be looked up by name.
    try env.registerTypeDef(syntheticName, .{ .record = .{
        .name = syntheticName,
        .id = typeId,
        .genericParams = &.{},
        .fields = fields,
    } });

    // Bind the name as a constructor.
    var paramTypes = try env.arena.alloc(*T.Type, fields.len);
    for (fields, 0..) |f, i| paramTypes[i] = f.type_;
    const ctorType = try env.funcType(paramTypes, recordTy);
    try env.bind(syntheticName, ctorType);

    return TypedExpr{ .identifier = .{
        .loc = .{ .line = 0, .col = 0 },
        .type_ = recordTy,
        .kind = .{ .ident = syntheticName },
    } };
}

fn unwrapResultType(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Result") and n.args.len >= 1)
            n.args[0]
        else
            null,
        else => null,
    };
}

/// Unwrap the Ok type of a `@Result<D, E>` operand for `try`/`catch`.
/// A still-unresolved type variable is allowed (its `Result`-ness is unknown);
/// any other concrete non-Result type is a compile-time error.
fn tryUnwrapOrError(env: *Env, rawTy: *T.Type, loc: ast.Loc) InferError!*T.Type {
    if (unwrapResultType(rawTy)) |ty| return ty;
    const d = rawTy.deref();
    if (d.* == .typeVar) return rawTy;
    env.lastError = TypeError.tryOnNonResult(d).withLoc(loc);
    return InferError.TypeError;
}

/// `@Future<T>` -> `T`. Returns null when `ty` is not a `Future`.
fn unwrapFutureType(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Future") and n.args.len >= 1)
            n.args[0]
        else
            null,
        else => null,
    };
}

/// `@Iterator<T>` / `@FutureGenerator<T, E>` -> `T`. Returns null when `ty` is not an iterator.
fn unwrapIteratorType(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if ((std.mem.eql(u8, n.name, "Iterator") or
            std.mem.eql(u8, n.name, "FutureGenerator")) and n.args.len >= 1)
            n.args[0]
        else
            null,
        else => null,
    };
}

/// Shallow structural equality check ---- used by case-arm deduplication.
/// Does NOT unify type variables; treats any typeVar as distinct from a named type.
fn typesSameShape(a: *T.Type, b: *T.Type) bool {
    const ta = a.deref();
    const tb = b.deref();
    if (ta == tb) return true;
    return switch (ta.*) {
        .named => |na| switch (tb.*) {
            .named => |nb| std.mem.eql(u8, na.name, nb.name),
            else => false,
        },
        .union_ => |ua| switch (tb.*) {
            .union_ => |ub| ua.len == ub.len,
            else => false,
        },
        .typeVar => switch (tb.*) {
            .typeVar => |cellB| ta.typeVar == cellB,
            else => false,
        },
        else => false,
    };
}

/// Number of leading required generic arguments for a known builtin wrapper.
/// Returns null for builtins without a fixed arity (e.g. `@Decl`, `array`,
/// `optional`, `tuple`) so the resolver leaves their arg-count checks alone.
/// The defaulted tail (per §1G / `tasks/v0.beta.19/specs/frente-b-rules-tooling.md`):
///   - `@Future<T, E = any>`            → 1 required
///   - `@Generator<T, R = void>`        → 1 required
///   - `@Iterator<T, E = any, C = void>`→ 1 required
///   - `@FutureGenerator<T, E = any, C = void>` → 1 required
///   - `@Result<R, E>`                  → 2 required
///   - `@Context<Base, T>`              → 2 required
///   - `@Expr<T>` / `@ExprCustom<T>`    → 1 required
fn builtinRequiredGenericArgs(name: []const u8) ?usize {
    const eq = std.mem.eql;
    if (eq(u8, name, "Future")) return 1;
    if (eq(u8, name, "Generator")) return 1;
    if (eq(u8, name, "Iterator")) return 1;
    if (eq(u8, name, "FutureGenerator")) return 1;
    if (eq(u8, name, "Result")) return 2;
    if (eq(u8, name, "Context")) return 2;
    if (eq(u8, name, "Expr")) return 1;
    if (eq(u8, name, "ExprCustom")) return 1;
    return null;
}

/// Full default-position list for the known builtin wrappers, when the
/// caller supplied `given` leading args (a value < total params). Returns
/// the full param-name list (so the resolver can fill positions `given..len`
/// with `env.namedType(<name>)`); returns null when the builtin declares no
/// defaults or when no fill is needed.
///
/// Layouts (per §1G default tail):
///   - `Future<T, E = any>`              → `["any"]` for the E slot
///   - `Generator<T, R = void>`          → `["void"]` for the R slot
///   - `Iterator<T, E = any, C = void>`  → `["any", "void"]` for the E/C slots
///   - `FutureGenerator<T, E = any, C = void>` → same as Iterator
///
/// The returned slice always has the FULL declared arity (so the caller
/// allocates an args slice sized to it and indexes positions
/// `given..returned.len` for the type names to bind).
fn builtinDefaultFilledArgs(env: *Env, name: []const u8, given: usize) ?[]const []const u8 {
    _ = env;
    const eq = std.mem.eql;
    // Each entry is the FULL position list; the caller pulls names from
    // position `given..len` for the unfilled tail. The leading slots are
    // placeholders ("" — never read; the caller already filled them).
    if (eq(u8, name, "Future") and given < 2) {
        return &.{ "", "any" };
    }
    if (eq(u8, name, "Generator") and given < 2) {
        return &.{ "", "void" };
    }
    if (eq(u8, name, "Iterator") and given < 3) {
        return &.{ "", "any", "void" };
    }
    if (eq(u8, name, "FutureGenerator") and given < 3) {
        return &.{ "", "any", "void" };
    }
    return null;
}

/// 06 N30 — resolve a param's annotation with its source location in scope, so
/// an unknown type name reds at the annotation instead of at the file.
fn resolveParamType(env: *Env, p: ast.Param, genericMap: std.StringHashMap(*T.Type)) InferError!*T.Type {
    const prev = env.atTypeRef(p.typeLoc);
    defer env.typeRefLoc = prev;
    return resolveTypeRefInContext(env, p.typeRef, genericMap);
}

/// 06 N30 — the same for a record/variant field's annotation.
fn resolveFieldType(env: *Env, f: ast.Field, genericMap: std.StringHashMap(*T.Type)) InferError!*T.Type {
    const prev = env.atTypeRef(f.typeLoc);
    defer env.typeRefLoc = prev;
    return resolveTypeRefInContext(env, f.typeRef, genericMap);
}

/// 06 N30 — the same for a declared return type (`-> Foo`). Only the sites that
/// register a declaration pass the location: a signature re-resolved at a call
/// site would carry the *declaring* file's coordinates into the caller's
/// diagnostic, and the declaring module already reds on its own annotation.
fn resolveReturnType(
    env: *Env,
    ref: ast.TypeRef,
    loc: ast.Loc,
    genericMap: std.StringHashMap(*T.Type),
) InferError!*T.Type {
    const prev = env.atTypeRef(loc);
    defer env.typeRefLoc = prev;
    return resolveTypeRefInContext(env, ref, genericMap);
}

/// Resolve an `ast.TypeRef` to a `*T.Type` using a generic-parameter map.
/// Used when the type ref appears inside a generic context (record/enum registration).
fn resolveTypeRefInContext(env: *Env, ref: ast.TypeRef, genericMap: std.StringHashMap(*T.Type)) InferError!*T.Type {
    switch (ref) {
        .named => |n| {
            // The builtin record is declared in a prelude the backends never
            // see; a module that names it gets its declaration spliced in
            // (`comptime.zig`, `withSourceLocationDecl`).
            if (std.mem.eql(u8, n, source_location_type_name)) env.usesSourceLocation = true;
            return env.resolveTypeName(n, genericMap);
        },
        .array => |elem| {
            const elemTy = try resolveTypeRefInContext(env, elem.*, genericMap);
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = elemTy;
            return env.namedTypeArgs("array", args);
        },
        .tuple_ => |elems| {
            const args = try env.arena.alloc(*T.Type, elems.len);
            for (elems, 0..) |e, i| args[i] = try resolveTypeRefInContext(env, e, genericMap);
            return env.namedTypeArgs("tuple", args);
        },
        .labeledTuple => |lt| {
            const args = try env.arena.alloc(*T.Type, lt.elems.len);
            for (lt.elems, 0..) |e, i| args[i] = try resolveTypeRefInContext(env, e, genericMap);
            const ty = try env.namedTypeArgs("tuple", args);
            ty.named.labels = lt.labels;
            return ty;
        },
        .optional => |inner| {
            const innerTy = try resolveTypeRefInContext(env, inner.*, genericMap);
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = innerTy;
            return env.namedTypeArgs("optional", args);
        },
        .function => |f| {
            // Build a `.func` type so a `fn(A, B) -> R` annotation unifies with
            // lambda/anonymous-function values, propagating the annotated param
            // and return types into the value's fresh type variables.
            const paramTypes = try env.arena.alloc(*T.Type, f.params.len);
            for (f.params, 0..) |p, i| {
                paramTypes[i] = try resolveTypeRefInContext(env, p, genericMap);
            }
            const returnType = try resolveTypeRefInContext(env, f.returnType.*, genericMap);
            return env.funcType(paramTypes, returnType);
        },
        .generic => |b| {
            // Decision 8 §3 — `A | B` reaches inference as a `generic` under the
            // reserved name `ast.union_type_name`; `unionMembers()` reads the
            // members back. It is a union type, not a nominal one called `|`,
            // which is what the old resolution produced ("expected |, got i32").
            if (ref.unionMembers()) |members| {
                var flat: std.ArrayListUnmanaged(*T.Type) = .empty;
                for (members) |m| {
                    const mt = try resolveTypeRefInContext(env, m, genericMap);
                    try appendUnionMember(env, &flat, mt);
                }
                // `finishUnion` collapses `A | A` to `A`: the grammar allows the
                // spelling and nothing downstream should meet a one-member union.
                return finishUnion(env, flat.items);
            }
            // RG3 (§1G) — required generic argument missing. Each known builtin
            // wrapper has a fixed required-arg minimum: the parameters before
            // the defaulted trailing range. Catching it here covers the
            // `@Future<>` / `@Iterator<>` shape; user-defined types' defaults
            // are tracked separately on `TypeDef.genericParams` (follow-up).
            if (b.is_builtin) {
                if (builtinRequiredGenericArgs(b.name)) |required| {
                    if (b.args.len < required) {
                        env.lastError = TypeError.custom(
                            "generic-required-arg-missing: a required generic argument is missing",
                            "Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.",
                        );
                        return error.TypeError;
                    }
                }
            }
            // §1G default-fill — when fewer trailing args are supplied than the
            // builtin declares, the missing positions take their declared
            // defaults. `@Future<User>` ⇒ `@Future<User, any>`; `@Iterator<i32>`
            // ⇒ `@Iterator<i32, any, void>`; `@Iterator<i32, MyError>` ⇒
            // `@Iterator<i32, MyError, void>`; `@Generator<i32>` ⇒
            // `@Generator<i32, void>`. `@Result` and `@Context` declare no
            // defaults — RG3 above already rejected an under-supplied form.
            const filled_args = if (b.is_builtin)
                builtinDefaultFilledArgs(env, b.name, b.args.len)
            else
                null;
            // User-typeDef defaults (§1G consumer-threading): when a non-
            // builtin generic name resolves to a registered TypeDef whose
            // params declared defaults, the omitted trailing slots take
            // those resolved defaults. Builtins above and user types here
            // share the post-fill flow; only the source of the default
            // differs.
            const user_defaults: ?[]const ?*T.Type = if (!b.is_builtin) blk: {
                const td = env.lookupTypeDef(b.name) orelse break :blk null;
                const dflts = td.genericDefaults();
                if (dflts.len == 0 or b.args.len >= dflts.len) break :blk null;
                break :blk dflts;
            } else null;
            const arg_count = if (filled_args) |fa|
                fa.len
            else if (user_defaults) |ud|
                ud.len
            else
                b.args.len;
            const args = try env.arena.alloc(*T.Type, arg_count);
            for (b.args, 0..) |a, i| {
                args[i] = try resolveTypeRefInContext(env, a, genericMap);
            }
            if (filled_args) |fa| {
                for (b.args.len..fa.len) |i| {
                    args[i] = try env.namedType(fa[i]);
                }
            } else if (user_defaults) |ud| {
                for (b.args.len..ud.len) |i| {
                    // A null default at this position means the param is
                    // required (the parser's strict-trailing rule means a
                    // null here can only follow a non-null one — RG3
                    // would have caught the under-supplied form, but be
                    // defensive: fall back to a fresh type var).
                    args[i] = ud[i] orelse try env.freshVar();
                }
            }
            // `?T` is the ONLY optional spelling — optional is not a concrete
            // type (user decision, 2026-06-06). The nominal forms `@Option<T>` /
            // `@Optional<T>` are rejected with a pointed diagnostic; the stdlib
            // `interface Option<T>` is the declarative reference for `?T`'s
            // methods, not a type.
            if (b.is_builtin and (std.mem.eql(u8, b.name, "Option") or std.mem.eql(u8, b.name, "Optional"))) {
                env.lastError = TypeError.custom(
                    "`@Option<T>` is not a type — the optional type is written `?T`",
                    "Replace the annotation with `?T` (e.g. `?i32`).",
                );
                return error.TypeError;
            }
            // `@Expr<T>` is encoded like `optional`/`array` — a named type with
            // one arg, so structural unification gives `@Expr<T> ~ @Expr<U>
            // iff T ~ U` for free. The generic parameter is mandatory; a type
            // only the expansion knows is an ordinary fn generic
            // (`fn yaml<T>(…) -> @Expr<T>`), resolved via `genericMap` above.
            // `Array<T>` is the canonical spelling of the array type `T[]` —
            // normalise it so annotations unify with array-literal inference
            // (`[1, 2]` infers as named "array").
            // `@ExprCustom<T>` is the marker spelling of the carrier struct
            // `CustomExpr<T>` (`{ code: Expr<T>, ast: CustomNode }`) — normalise
            // it so a template fn's `-> @ExprCustom<T>` return unifies with the
            // `q.custom(…)` value the body produces (exactly as `@Expr` ↔ the
            // `Expr` interface).
            const name = if (std.mem.eql(u8, b.name, "Array"))
                "array"
            else if (b.is_builtin and std.mem.eql(u8, b.name, "ExprCustom"))
                "CustomExpr"
            else
                b.name;
            return env.namedTypeArgs(name, args);
        },
        // A comptime typeparam accepts a value of any type at the call site;
        // its constraints are validated separately (see `validateTypeparams`).
        // Resolve to a fresh variable so unification against it never fails.
        .typeparam => return env.freshVar(),
        // Anonymous record type `{ f: T, … }` — a structural `Type.record` that
        // unifies field-by-field with a `record { … }` literal (same field set,
        // declaration order; see unify.zig).
    }
}

/// Resolve an `ast.TypeRef` annotation to a `*T.Type` (no generic context).
fn resolveTypeRef(env: *Env, ref: ast.TypeRef) InferError!*T.Type {
    if (env.fnGenericMap) |gm| return resolveTypeRefInContext(env, ref, gm.*);
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    return resolveTypeRefInContext(env, ref, genericMap);
}

/// Infer the type of an expression, returning a *Type.
/// On type error: sets `env.lastError` and returns `error.TypeError`.
/// This is a thin wrapper around `inferExprTyped` ---- it discards the typed node.
pub fn inferExpr(env: *Env, expr: ast.Expr) InferError!*T.Type {
    return (try inferExprTyped(env, expr)).getType();
}

// ── typed expression construction ─────────────────────────────────────────────

const TypedExpr = ast.TypedExpr;
const TypedStmt = ast.StmtOf(.typed);
const PatternBindingSnapshot = struct {
    name: []const u8,
    previous: ?*T.Type,
};

/// Allocate a heap-owned TypedExpr in env.arena.
fn makeTypedPtr(env: *Env, node: TypedExpr) !*TypedExpr {
    const ptr = try env.arena.create(TypedExpr);
    ptr.* = node;
    return ptr;
}

/// Convert a slice of untyped statements to typed ones (arena-allocated).
/// The statement walk for a body that needs no typed nodes back — a plain
/// `fn`, a method and a `test` block. It exists so those three apply the
/// early-exit narrowing the same way `inferStmtsTyped` does: `if (x == null) {
/// return …; }` narrows `x` for the REST of the block, and a body walked with a
/// bare `for` loop would have been the one shape where it did not.
fn inferBodyStmts(env: *Env, body: []const ast.Stmt) InferError!void {
    var narrowed: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
    defer narrowed.deinit(env.arena);
    for (body) |stmt| {
        _ = try inferExpr(env, stmt.expr);
        try narrowAfterEarlyExit(env, stmt.expr, &narrowed);
    }
    if (narrowed.items.len > 0) try restorePatternBindings(env, narrowed.items);
}

fn inferStmtsTyped(env: *Env, stmts: []const ast.Stmt) InferError![]TypedStmt {
    const out = try env.arena.alloc(TypedStmt, stmts.len);
    // The early-exit narrowing (`narrowAfterEarlyExit`) outlives the `if` that
    // states it, so this is where it is applied and where it ends: a name
    // narrowed by a guard clause is narrowed for the REST of this block and
    // restored when the block does.
    var narrowed: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
    defer narrowed.deinit(env.arena);
    for (stmts, 0..) |s, i| {
        out[i] = .{ .expr = try inferExprTyped(env, s.expr) };
        try narrowAfterEarlyExit(env, s.expr, &narrowed);
    }
    if (narrowed.items.len > 0) try restorePatternBindings(env, narrowed.items);
    return out;
}

/// Convert a slice of untyped trailing lambdas to typed ones (arena-allocated).
fn inferTrailingLambdasTyped(env: *Env, trailing: []const ast.TrailingLambda) InferError![]ast.TrailingLambdaOf(.typed) {
    const out = try env.arena.alloc(ast.TrailingLambdaOf(.typed), trailing.len);
    // C1 — a trailing lambda's `return`s belong to the lambda (an `@block`,
    // a `use memo { -> return … }`), never to the enclosing fn.
    const savedReturnTarget = env.returnTarget;
    const savedReturnBareIsVoid = env.returnBareIsVoid;
    const savedReturnWhole = env.returnWhole;
    defer {
        env.returnTarget = savedReturnTarget;
        env.returnBareIsVoid = savedReturnBareIsVoid;
        env.returnWhole = savedReturnWhole;
    }
    env.returnWhole = null;
    const targets = try env.arena.alloc(*T.Type, trailing.len);
    for (trailing, 0..) |tl, i| {
        targets[i] = try env.freshVar();
        env.returnTarget = targets[i];
        env.returnBareIsVoid = false;
        out[i] = .{
            .label = tl.label,
            .params = tl.params,
            .body = try inferStmtsTyped(env, tl.body),
        };
    }
    env.lastTrailingReturnTargets = targets;
    return out;
}

/// Decision 8 §5.2 — a **type pattern**: an arm whose pattern is a bare type
/// name (`i32 { n -> … }`, `string { s -> … }`, `Person { p -> … }`) tests the
/// matched value's type and narrows the arm to it. Returns the tested type, or
/// null when the name is an ordinary binder.
///
/// The name has to be a type the env knows AND not a variant of the subject —
/// a variant path is read as a variant first, which is what keeps
/// `case s { Circle { … } }` a variant arm.
fn typePatternType(env: *Env, pattern: ast.Pattern, subjectType: *T.Type) InferError!?*T.Type {
    const name = typePatternName(env, pattern, subjectType) orelse return null;
    return try env.namedType(name);
}

/// The type name a pattern tests as a type pattern, or null when it is an
/// ordinary binder. Split out of `typePatternType` because the coverage walk
/// (§5.4) has to ask the question from `patternIsCatchAll`, which allocates
/// nothing and cannot fail: a type pattern is **not** a catch-all, and reading
/// it as one is what let `case x { i32 { … } }` stand in for `_`.
fn typePatternName(env: *Env, pattern: ast.Pattern, subjectType: *T.Type) ?[]const u8 {
    const name = switch (pattern) {
        .ident => |n| n,
        else => return null,
    };
    if (isVariantPath(name)) return null;
    if (isEnumVariantNameForSubject(env, subjectType, name)) return null;
    if (!isKnownTypeName(env, name)) return null;
    return name;
}

/// A name the env can resolve as a type: a primitive, or a declaration this
/// module registered. Deliberately *not* every name — an unregistered one is a
/// binder, which is what every arm written before decision 8 relies on.
fn isKnownTypeName(env: *Env, name: []const u8) bool {
    for (scalar_type_names) |p| if (std.mem.eql(u8, name, p)) return true;
    return env.lookupTypeDef(name) != null;
}

/// Decision 8 §5.1 P8 — the bare variant name inside a pattern's written path.
///
/// The parser keeps the path exactly as written, because the leading `.` is
/// what tells a variant path from a binding (`dff3446`): `Circle`,
/// `Shape.Circle` and `.Circle` all reach here, and only the last segment names
/// a variant. Every variant table in the checker is keyed by the bare name, so
/// nothing matched `.Circle` and every variant read as missing.
fn bareVariantName(written: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, written, '.')) |i| return written[i + 1 ..];
    return written;
}

/// True when a pattern's written name is a **path** and so can never be a
/// binding — `.None`, `Maybe.None`, `Token.Text.Bold`. A path that names no
/// variant of the subject is a mistake, not a catch-all binder.
fn isVariantPath(written: []const u8) bool {
    return std.mem.indexOfScalar(u8, written, '.') != null;
}

fn isEnumVariantNameForSubject(env: *Env, subjectType: *T.Type, candidate: []const u8) bool {
    const ty = subjectType.deref();
    if (ty.* != .named) return false;
    const bare = bareVariantName(candidate);
    if (env.lookupTypeDef(ty.named.name)) |td| {
        switch (td) {
            .enum_ => |en| {
                for (en.variants) |v| {
                    if (std.mem.eql(u8, v.name, bare)) return true;
                }
            },
            else => {},
        }
    }
    return false;
}

fn saveAndBindPatternName(
    env: *Env,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
    name: []const u8,
    ty: *T.Type,
) InferError!void {
    var seen = false;
    for (snapshots.items) |s| {
        if (std.mem.eql(u8, s.name, name)) {
            seen = true;
            break;
        }
    }
    if (!seen) {
        try snapshots.append(env.arena, .{
            .name = name,
            .previous = env.lookup(name),
        });
    }
    try env.bind(name, ty);
}

fn restorePatternBindings(env: *Env, snapshots: []const PatternBindingSnapshot) InferError!void {
    var i = snapshots.len;
    while (i > 0) {
        i -= 1;
        const snapshot = snapshots[i];
        if (snapshot.previous) |old| {
            try env.bind(snapshot.name, old);
        } else {
            _ = env.bindings.remove(snapshot.name);
        }
    }
}

fn bindPatternNamesForSubject(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    switch (pattern) {
        .wildcard, .numberLit, .stringLit => {},
        .ident => |name| {
            if (isEnumVariantNameForSubject(env, subjectType, name)) return;
            // §5.2 — a bare type name is a type pattern, not a binder: it tests
            // the value and binds nothing. The arm's own binder is its lambda
            // parameter (`i32 { n -> … }`), bound by `inferCaseArmBody`.
            if (try typePatternType(env, pattern, subjectType) != null) return;
            // C8 — a binder names the matched value itself.
            try saveAndBindPatternName(env, snapshots, name, subjectType);
        },
        .variant => |v| {
            // C8 — each payload binding takes the variant field's declared type,
            // instantiated against the subject's generic args.
            const payload = try variantPayloadTypes(env, subjectType, v.name);
            switch (v.payload) {
                .binding => |binding| {
                    const ty = if (payload) |p| (if (p.len == 1) p[0] else try env.freshVar()) else try env.freshVar();
                    try saveAndBindPatternName(env, snapshots, binding, ty);
                },
                .fields => |fields| {
                    for (fields, 0..) |binding, i| {
                        const ty = if (payload) |p| (if (p.len == fields.len) p[i] else try env.freshVar()) else try env.freshVar();
                        try saveAndBindPatternName(env, snapshots, binding, ty);
                    }
                },
                .literals => |args| {
                    for (args, 0..) |arg, i| {
                        const ty = if (payload) |p| (if (p.len == args.len) p[i] else try env.freshVar()) else try env.freshVar();
                        try bindPatternNamesForSubject(env, arg, ty, snapshots);
                    }
                },
            }
        },
        .list => |lst| {
            // C8 — elements take the array's element type, the spread the array type.
            const st = subjectType.deref();
            const elemTy: ?*T.Type = if (st.* == .named and std.mem.eql(u8, st.named.name, "array") and st.named.args.len == 1) st.named.args[0] else null;
            for (lst.elems) |elem| {
                switch (elem) {
                    .bind => |name| try saveAndBindPatternName(env, snapshots, name, elemTy orelse try env.freshVar()),
                    else => {},
                }
            }
            if (lst.spread) |name| {
                if (name.len > 0) try saveAndBindPatternName(env, snapshots, name, if (elemTy != null) subjectType else try env.freshVar());
            }
        },
        .@"or" => |patterns| {
            if (patterns.len == 0) return;
            const before = snapshots.items.len;
            try bindPatternNamesForSubject(env, patterns[0], subjectType, snapshots);
            // C8 — a name bound by every alternative is the unification of its
            // types across them; disagreeing alternatives red.
            for (patterns[1..]) |alt| {
                var local: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
                defer local.deinit(env.arena);
                try bindPatternNamesForSubject(env, alt, subjectType, &local);
                for (local.items) |ls| {
                    const newTy = env.lookup(ls.name) orelse continue;
                    var inFirst = false;
                    for (snapshots.items[before..]) |fs| {
                        if (std.mem.eql(u8, fs.name, ls.name)) inFirst = true;
                    }
                    if (inFirst) {
                        if (ls.previous) |prev| {
                            try unify(env, prev, newTy);
                            try env.bind(ls.name, prev);
                        }
                    } else {
                        try snapshots.append(env.arena, ls);
                    }
                }
            }
        },
        .multi => {},
    }
}

/// C8 — the declared payload field types of `variantName` for a value of
/// `subjectType`, instantiated against the subject's generic args; null when
/// the subject's type or the variant is not known (the bindings stay fresh).
/// `@Result<R, E>`: `Ok` → [R], `Err`/`Error` → [E]; `?T`: `Some` → [T].
fn variantPayloadTypes(env: *Env, subjectType: *T.Type, writtenName: []const u8) InferError!?[]*T.Type {
    const st = subjectType.deref();
    if (st.* != .named) return null;
    const n = st.named;
    const eq = std.mem.eql;
    // §5.1 P8 — the written form may be a path (`.Some`, `Maybe.Some`); the
    // payload table is keyed by the bare variant name.
    const variantName = bareVariantName(writtenName);
    if (eq(u8, n.name, "Result") and n.args.len >= 2) {
        if (eq(u8, variantName, "Ok")) return try env.arena.dupe(*T.Type, n.args[0..1]);
        if (eq(u8, variantName, "Err") or eq(u8, variantName, "Error")) return try env.arena.dupe(*T.Type, n.args[1..2]);
        return null;
    }
    if (eq(u8, n.name, "optional") and n.args.len == 1) {
        if (eq(u8, variantName, "Some")) return try env.arena.dupe(*T.Type, n.args[0..1]);
        return null;
    }
    const td = env.lookupTypeDef(n.name) orelse return null;
    if (td != .enum_) return null;
    const en = td.enum_;
    var fields: ?[]envMod.FieldDef = null;
    for (en.variants) |vd| {
        if (eq(u8, vd.name, variantName)) fields = vd.fields;
    }
    const fs = fields orelse return null;
    const out = try env.arena.alloc(*T.Type, fs.len);
    // The registration cells of a generic enum are the args of any of its
    // variant constructors' result type (`Enum<A_cell, …>`).
    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    if (en.genericParams.len > 0 and n.args.len == en.genericParams.len) {
        for (en.variants) |vd| {
            const ctor = env.lookup(vd.name) orelse continue;
            const cd = ctor.deref();
            const ret = if (cd.* == .func) cd.func.ret.deref() else cd;
            if (ret.* != .named or !eq(u8, ret.named.name, en.name) or ret.named.args.len != n.args.len) continue;
            for (ret.named.args, n.args) |cellTy, inst| {
                const cr = cellTy.deref();
                if (cr.* == .typeVar) try seen.put(cr.typeVar, inst);
            }
            break;
        }
    }
    for (fs, 0..) |f, i| {
        out[i] = if (seen.count() > 0) try instantiateType(env, f.type_, &seen, .allVars) else f.type_;
    }
    return out;
}

/// 06 C9 — whether `td` answers `member` by some route other than an inherent
/// method: a field of function type called like a method (`c.set(9)` on
/// `#(value, set)`-shaped records), or a `default fn` the type adopts from a
/// behavior it implements (through that behavior's `extends` chain). Both are
/// legitimate and neither is registered in `inherentMethods`, so the unknown-
/// method check has to ask before it reds.
fn typeAnswersMember(env: *Env, td: envMod.TypeDef, member: []const u8) bool {
    if (td.fields()) |fs| {
        for (fs) |f| {
            if (std.mem.eql(u8, f.name, member)) return true;
        }
    }
    const implements: []const []const u8 = switch (td) {
        .record => |r| r.implements,
        .struct_ => |st| st.implements,
        .enum_ => |e| e.implements,
    };
    for (implements) |iface| {
        if (behaviorDeclaresMember(env, iface, member, 0)) return true;
    }
    return false;
}

/// Whether `iface` — or anything it extends — declares `member`. `depth` bounds
/// a cyclic `extends` chain.
fn behaviorDeclaresMember(env: *Env, iface: []const u8, member: []const u8, depth: usize) bool {
    if (depth >= 16) return false;
    const decl = env.assocInterfaceDecls.get(iface) orelse return false;
    for (decl.methods) |m| {
        if (std.mem.eql(u8, m.name, member)) return true;
    }
    for (decl.fields) |f| {
        if (std.mem.eql(u8, f.name, member)) return true;
    }
    for (decl.extends) |parent| {
        if (behaviorDeclaresMember(env, parent, member, depth + 1)) return true;
    }
    return false;
}

/// Decision 2 — whether a branch's statements end in something that HAS a
/// value. Every binding expression (an assignment, a `val`/`var`, a
/// destructuring) and a loop are statements: they end the branch with nothing
/// for the other branch to agree with.
fn stmtsYieldValue(stmts: []const ast.StmtOf(.typed)) bool {
    if (stmts.len == 0) return false;
    return switch (stmts[stmts.len - 1].expr) {
        .binding => false,
        .loop => false,
        else => true,
    };
}

/// 06 N24 / decision 8 §6 — `c.set(9)` where `set` is a LABEL of the tuple
/// `c`, naming an element of function type. Types the call from that element's
/// signature and records the positional rewrite the backends need
/// (`c._1(9)`), the same `enumSectionRewrites` channel the member-access path
/// uses for `row.pop` → `row._1`. Null when the receiver is not a labelled
/// tuple, or the callee is not one of its labels — every other dispatch then
/// runs as before.
fn inferTupleLabelCall(
    env: *Env,
    recvPtr: ?*ast.TypedExpr,
    recvExpr: ?*ast.Expr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?TypedExpr {
    const recv = recvPtr orelse return null;
    const written = recvExpr orelse return null;
    const rt = recv.getType().deref();
    if (rt.* != .named or !std.mem.eql(u8, rt.named.name, "tuple")) return null;
    const idx = tupleLabelIndex(rt.named.labels, callee) orelse return null;
    if (idx >= rt.named.args.len) return null;

    const elem = rt.named.args[idx].deref();
    const retType: *T.Type = switch (elem.*) {
        .func => |f| blk: {
            const total = typedArgs.len + typedTrailing.len;
            if (f.params.len != total) {
                env.lastError = TypeError.arityMismatch(callee, f.params.len, total).withLoc(loc);
                return error.TypeError;
            }
            for (typedArgs, f.params[0..typedArgs.len]) |ta, p| {
                try unifyAt(env, p, ta.value.getType(), ta.value.getLoc());
            }
            break :blk f.ret;
        },
        else => try env.freshVar(),
    };

    const positional = try std.fmt.allocPrint(env.arena, "_{d}", .{idx});
    const rewrite = try env.arena.create(ast.Expr);
    rewrite.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = written,
        .callee = positional,
        .is_builtin = false,
        .args = &.{},
        .trailing = &.{},
    } } } };
    try env.enumSectionRewrites.put(loc, rewrite);

    return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = positional,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// 06 C3 — arithmetic constrains its operands to a numeric type, reported at
/// the offending operand. `"a" * "b"` and `-"s"` used to check: `*` only
/// unified the two sides with each other (two strings agree) and `-` applied
/// no constraint at all. Permissive for a type variable an inference gap has
/// not resolved, and for any named type the env does not know to be
/// non-numeric — only the types that certainly hold no arithmetic red.
/// The two type kinds decision 8 says must be **narrowed before they are
/// used**: `unknown` (§2.2) and a union (§3.3). Both carry a set of
/// possibilities rather than one type, and both reach the same five operations
/// — arithmetic, `+`, an ordering comparison, a field read and a method call —
/// through a permissive tail that would otherwise accept silently.
///
/// `@print(x)`, `x == y`, `x != y`, assignment and passing to a generic
/// parameter stay allowed for both, and reach inference by paths this is not on.
///
/// §3.3's own rule is narrower than this: a use is allowed when **every**
/// member allows it. Deciding that means re-resolving the operation once per
/// member, which this front has not built; refusing the union outright refuses
/// more than §3.3 and is never wrong, and the fix — narrow first — is the same
/// sentence either way.
///
/// `what` completes "cannot …", so it is a verb phrase.
fn refuseUnknownUse(env: *Env, ty: *T.Type, loc: ast.Loc, what: []const u8) InferError!void {
    const t = ty.deref();
    if (unifyMod.isUnknown(t)) {
        var e = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "cannot {s} an `unknown` value", .{what}),
            "Narrow it first: `if (x is i32) { … }` makes `x` an `i32` inside the block.",
        );
        env.lastError = e.withLoc(loc);
        return error.TypeError;
    }
    if (t.* == .union_) {
        const rendered = try snapshotMod.typeNameOf(env.arena, t);
        var e = TypeError.custom(
            try std.fmt.allocPrint(env.arena, "cannot {s} a `{s}` — not every member of the union answers it", .{ what, rendered }),
            "Narrow it first: a `case` with one arm per member, or `if (v is i32) { … }`.",
        );
        env.lastError = e.withLoc(loc);
        return error.TypeError;
    }
}

/// Decision 8 §4.2 — what may stand on the right of `is`: a primitive, a named
/// type's constructor, a tuple `#(…)`, and a generic type applied to `unknown`
/// only.
///
/// `Box<i32>` is the error the section names: a run-time test can see that a
/// value is a `Box`, and cannot see what is in it, so `Box<i32>` would be a
/// promise the test does not keep. `Box<unknown>` says exactly what the test
/// can answer. A tuple is checkable — arity and each element are — and so are
/// the other structural spellings the grammar builds out of type refs.
fn checkIsTestableType(env: *Env, ref: ast.TypeRef, loc: ast.Loc) InferError!void {
    switch (ref) {
        .generic => |g| {
            if (ref.unionMembers()) |members| {
                for (members) |m| try checkIsTestableType(env, m, loc);
                return;
            }
            for (g.args) |arg| {
                const isUnknownArg = arg == .named and
                    std.mem.eql(u8, arg.named, ast.unknown_type_name);
                if (isUnknownArg) continue;
                var e = TypeError.custom(
                    try std.fmt.allocPrint(
                        env.arena,
                        "`is` cannot test the type argument of `{s}`",
                        .{g.name},
                    ),
                    "A run-time test sees the type, not what is inside it. Write the argument as `unknown` (`Box<unknown>`) and narrow the contents separately.",
                );
                env.lastError = e.withLoc(loc);
                return error.TypeError;
            }
        },
        else => {},
    }
}

/// Decision 8 §4 — the narrowing an `if` condition records: the name it tested
/// and the type it tested it for. Null when the condition is not one of the
/// forms that narrow.
const IsNarrowing = struct { name: []const u8, ref: ast.TypeRef };

/// `x is T` where `x` is a plain name. Only a name can be narrowed: narrowing
/// rebinds it for the branch, and there is nothing to rebind for `f().x`.
fn isNarrowingOf(cond: ast.Expr) ?IsNarrowing {
    if (cond != .call) return null;
    const c = cond.call.kind;
    if (c != .call) return null;
    const cc = c.call;
    if (!cc.is_builtin or !std.mem.eql(u8, cc.callee, ast.is_builtin_name)) return null;
    const tested = cc.isType orelse return null;
    if (cc.args.len != 1) return null;
    const arg = cc.args[0].value.*;
    if (arg != .identifier or arg.identifier.kind != .ident) return null;
    return .{ .name = arg.identifier.kind.ident, .ref = tested };
}

/// Decision 8 §4, as the null test extends it — one name a condition narrows,
/// and the type it takes on each SIDE of that condition. `then_` is the type
/// the name has where the condition held, `else_` the type it has where it did
/// not; either may be null, which means "that side leaves the name's own type
/// alone". `x is T` fills `then_` only; `x != null` fills `then_`, `x == null`
/// fills `else_`, and that symmetry is the whole of the negative form.
const CondNarrowing = struct {
    name: []const u8,
    then_: ?*T.Type = null,
    else_: ?*T.Type = null,
};

/// The payload of a `?T`, or null for every other type — an unresolved type
/// VARIABLE included, because an inference gap must not narrow a name to a
/// guess. `optional` is the named type the parser lands `?T` as.
fn optionalPayloadOf(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    if (t.* != .named) return null;
    const n = t.named;
    if (!std.mem.eql(u8, n.name, "optional") or n.args.len != 1) return null;
    return n.args[0];
}

/// The name of a plain identifier expression, or null. Only a NAME narrows,
/// for the same reason `x is T` only narrows one: narrowing is a rebinding,
/// and there is nothing to rebind for `o.inner` or `f().x`.
fn plainIdentName(expr: ast.Expr) ?[]const u8 {
    if (expr != .identifier or expr.identifier.kind != .ident) return null;
    return expr.identifier.kind.ident;
}

fn isNullLiteral(expr: ast.Expr) bool {
    return expr == .literal and expr.literal.kind == .null_;
}

/// `x != null` / `x == null`, in either operand order. `present_when_true` says
/// which side of the test holds the value.
fn nullTestOf(cond: ast.Expr) ?struct { name: []const u8, present_when_true: bool } {
    if (cond != .binaryOp) return null;
    const b = cond.binaryOp;
    const present = switch (b.op) {
        .ne => true,
        .eq => false,
        else => return null,
    };
    const name = if (isNullLiteral(b.rhs.*))
        plainIdentName(b.lhs.*)
    else if (isNullLiteral(b.lhs.*))
        plainIdentName(b.rhs.*)
    else
        null;
    return .{ .name = name orelse return null, .present_when_true = present };
}

/// Every name a condition narrows, appended to `out`. The null test is the leaf
/// (`x != null`, `x == null`); `&&`, `||` and `not` combine leaves, and each
/// combines exactly one side:
///
///   * `a && b` HOLDS only when both hold, so the then side keeps both halves'
///     narrowings. Its failure says nothing — either half may be the one that
///     failed — so the else side of an `&&` narrows nothing.
///   * `a || b` FAILS only when both fail: the mirror, and the shape a library
///     writes as `if (a == null || b == null) { return …; }`.
///   * `not a` swaps the two sides.
///
/// A name whose type is not an optional is skipped rather than refused: `x !=
/// null` on a non-optional is a comparison this function has no opinion about.
fn collectCondNarrowings(
    env: *Env,
    cond: ast.Expr,
    out: *std.ArrayListUnmanaged(CondNarrowing),
) InferError!void {
    // Only the narrowings THIS call appends may be rewritten by the combinator
    // below it: `a && (b || c)` must not let the `||` clear `a`'s half.
    const start = out.items.len;
    switch (cond) {
        .binaryOp => |b| switch (b.op) {
            .@"and", .@"or" => {
                try collectCondNarrowings(env, b.lhs.*, out);
                try collectCondNarrowings(env, b.rhs.*, out);
                for (out.items[start..]) |*n| {
                    if (b.op == .@"and") n.else_ = null else n.then_ = null;
                }
            },
            .eq, .ne => {
                const test_ = nullTestOf(cond) orelse return;
                const bound = env.lookup(test_.name) orelse return;
                const inner = optionalPayloadOf(bound) orelse return;
                try out.append(env.arena, if (test_.present_when_true)
                    .{ .name = test_.name, .then_ = inner }
                else
                    .{ .name = test_.name, .else_ = inner });
            },
            else => {},
        },
        .unaryOp => |u| {
            if (u.op != .not) return;
            try collectCondNarrowings(env, u.expr.*, out);
            for (out.items[start..]) |*n| {
                const held = n.then_;
                n.then_ = n.else_;
                n.else_ = held;
            }
        },
        else => {},
    }
}

/// Rebind `name` to its narrowed type for one branch, remembering what it was.
/// A `val` stays a `val`: `env.bind` drops the marker decision 38 reads, and a
/// narrowed name is still the same binding, not a new assignable one.
fn bindNarrowed(
    env: *Env,
    name: []const u8,
    ty: *T.Type,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    try snapshots.append(env.arena, .{ .name = name, .previous = env.lookup(name) });
    if (env.isVal(name)) try env.bindVal(name, ty) else try env.bind(name, ty);
}

/// A statement list that cannot fall through: its last statement is a `return`,
/// `throw`, `break` or `continue`. That is all the early-return shape needs —
/// a body ending any other way reaches the code below its `if`.
fn stmtsAlwaysExit(stmts: []const ast.Stmt) bool {
    if (stmts.len == 0) return false;
    const last = stmts[stmts.len - 1].expr;
    if (last != .jump) return false;
    return switch (last.jump.kind) {
        .@"return", .throw_, .@"break", .@"continue" => true,
        else => false,
    };
}

/// The early-exit shape: `if (x == null) { return …; }` and then the REST of
/// the block, where `x` holds a value because the branch that did not left.
/// The narrowing outlives the `if`, so unlike the two branch shapes it is
/// applied by the statement walker and restored at the end of the block.
///
/// Only a `val` narrows here. A `var` may be assigned below the `if` — the
/// branch shapes restore before the next statement and never meet that, this
/// one would carry a type the name no longer has.
fn narrowAfterEarlyExit(
    env: *Env,
    stmt: ast.Expr,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    if (stmt != .branch or stmt.branch.kind != .if_) return;
    const i = stmt.branch.kind.if_;
    if (i.binding != null or i.else_ != null) return;
    if (!stmtsAlwaysExit(i.then_)) return;
    var narrowings: std.ArrayListUnmanaged(CondNarrowing) = .empty;
    defer narrowings.deinit(env.arena);
    try collectCondNarrowings(env, i.cond.*, &narrowings);
    for (narrowings.items) |n| {
        const ty = n.else_ orelse continue;
        if (!env.isVal(n.name)) continue;
        try bindNarrowed(env, n.name, ty, snapshots);
    }
}

fn requireNumericOperand(env: *Env, ty: *T.Type, op: []const u8, loc: ast.Loc) InferError!void {
    const t = ty.deref();
    if (t.* != .named) return;
    // §2.2 — arithmetic is refused on `unknown` for its own reason, not as a
    // "takes numbers" mismatch: the value may well be a number, and what is
    // wrong is that nothing has established it.
    try refuseUnknownUse(env, ty, loc, "do arithmetic on");
    const n = t.named.name;
    const eq = std.mem.eql;
    if (!(eq(u8, n, "string") or eq(u8, n, "bool") or eq(u8, n, "void") or eq(u8, n, "array"))) return;
    var e = TypeError.custom(
        try std.fmt.allocPrint(env.arena, "`{s}` takes numbers, not `{s}`", .{ op, n }),
        "Arithmetic is defined on the integer and float types. `+` also concatenates strings; the other operators do not.",
    );
    env.lastError = e.withLoc(loc);
    return error.TypeError;
}

/// The named types that hold no variant at all: a variant pattern asserted
/// against one of them can never match. Every other unregistered name stays
/// permissive (a forward reference, or an imported type).
const scalar_type_names = [_][]const u8{
    "i8",    "u8",       "i16", "u16", "i32",  "u32",    "i64",  "u64",
    "isize", "usize",    "f32", "f64", "bool", "string", "void", "v128",
    "any",   "noreturn",
};

/// Decision 8 § 9 — a `val assert` variant pattern must name a variant the
/// subject's type can actually hold. Permissive while the subject's type is
/// still an unresolved type variable (an inference gap must not red), and for
/// every non-variant pattern, whose shapes (`42`, `"hi"`, `[a, ..]`) the
/// backends test at run time.
fn checkAssertPatternSubject(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    loc: ast.Loc,
    fatal: bool,
    catchLoc: ?ast.Loc,
) InferError!void {
    const name = switch (pattern) {
        .variant => |v| v.name,
        else => return,
    };
    const st = subjectType.deref();
    if (st.* != .named) return;
    const eq = std.mem.eql;
    const n = st.named;
    // Decision 8 § 9 — `val assert Ok(n) = parse("42") catch 0;` is an error:
    // `catch` is what turns a `@Result` into its success value, so a `@Result`
    // subject and a handler cannot both be written. The handler-less form is
    // the one that asserts a variant, and its failure is fatal.
    if (!fatal and eq(u8, n.name, "Result")) {
        var ce = TypeError.custom(
            "after `catch` the value is not a @Result — a `val assert` over a `@Result` takes no `catch`",
            "`catch` already yields the success value, so the pattern would be asserted against the unwrapped one. Write `val assert Ok(n) = parse(s);` — a failure is a fatal assert (decision 8 § 9).",
        );
        // 01 R9 — the caret is on the `catch` that makes it an error.
        env.lastError = ce.withLoc(catchLoc orelse loc);
        return error.TypeError;
    }
    const known = blk: {
        if (eq(u8, n.name, "Result")) break :blk eq(u8, name, "Ok") or eq(u8, name, "Err") or eq(u8, name, "Error");
        if (eq(u8, n.name, "optional")) break :blk eq(u8, name, "Some") or eq(u8, name, "None");
        if (env.lookupTypeDef(n.name)) |td| switch (td) {
            .enum_ => |en| {
                for (en.variants) |vd| {
                    if (eq(u8, vd.name, name)) break :blk true;
                }
                break :blk false;
            },
            // A record's own constructor is its only "variant"; a struct is
            // opened by name too.
            .record => break :blk eq(u8, n.name, name),
            .struct_ => break :blk eq(u8, n.name, name),
        };
        // No typedef: a primitive holds no variant at all, anything else is a
        // forward reference or an imported type C10 has yet to register — stay
        // permissive there.
        for (scalar_type_names) |p| {
            if (eq(u8, n.name, p)) break :blk false;
        }
        return;
    };
    if (known) return;
    var e = TypeError.custom(
        try std.fmt.allocPrint(env.arena, "`{s}` names no variant of `{s}`", .{ name, n.name }),
        "The pattern of a `val assert` has to be able to match its subject. After `catch` the value is the unwrapped one, so `val assert Ok(n) = parse(s) catch 0;` asserts `Ok(…)` against an `i32` — drop the `catch` (decision 8 § 9: a failure is a fatal assert).",
    );
    env.lastError = e.withLoc(loc);
    return error.TypeError;
}

/// Decision 54 — the `null` pattern. The parser lands it as `.ident` carrying
/// the keyword's own lexeme (`parser/patterns.zig`), so `null` is never a
/// binding: no source can spell a binder with that name, `null` being a keyword
/// token. This predicate is the only reader of that spelling.
fn isNullPattern(pattern: ast.Pattern) bool {
    return pattern == .ident and std.mem.eql(u8, pattern.ident, "null");
}

/// The `T` of a `?T`, or null when the type is not an optional.
fn optionalInner(ty: *T.Type) ?*T.Type {
    const d = ty.deref();
    if (d.* != .named) return null;
    if (!std.mem.eql(u8, d.named.name, "optional") or d.named.args.len != 1) return null;
    return d.named.args[0];
}

/// The name a pattern binds when it is the binder half of decision 54's `?T`
/// form: a plain lower-case name, or `""` for `_`. Null when the pattern is
/// anything else.
fn optionalBinderName(pattern: ast.Pattern) ?[]const u8 {
    return switch (pattern) {
        .wildcard => "",
        .ident => |n| if (isNullPattern(pattern) or std.mem.indexOfScalar(u8, n, '.') != null)
            null
        else
            n,
        else => null,
    };
}

/// Decision 54 — a `case` over a `?T` has exactly one spelling:
/// `case x { null { … } v { … } }`. This validates it and answers the binder's
/// name, or reds with a located diagnostic. Called only when an arm's pattern
/// is `null`; the arms are the untyped ones, since the shape is a property of
/// what was written.
///
/// Three things are refused here, and each names the form it wants:
///   * a `null` arm over a subject that is not an optional;
///   * a `case` over a `?T` whose arms are not exactly `null` then a binder
///     (a third arm, a guard, a reversed order, a payload pattern);
///   * the arms' bodies taking a parameter (`v { n -> … }`) — §5.1 P1's
///     whole-value binder means nothing here, where the binder is the payload.
fn optionalNullCaseBinder(
    env: *Env,
    subjectType: *T.Type,
    arms: []const ast.CaseArm,
    loc: ast.Loc,
) InferError!?[]const u8 {
    var nullArm: ?usize = null;
    for (arms, 0..) |arm, i| {
        if (isNullPattern(arm.pattern)) {
            nullArm = i;
            break;
        }
    }
    const nullIdx = nullArm orelse return null;

    if (optionalInner(subjectType) == null) {
        env.lastError = TypeError.custom(
            "`null` is a pattern only over an optional",
            "`case x { null { … } v { … } }` matches a `?T` (decision 54). This subject is not one.",
        ).withLoc(arms[nullIdx].patternLoc);
        return error.TypeError;
    }

    const shapeError = "an optional is matched by `null` and a binder, in that order";
    const shapeHint = "Decision 54: a `?T` has one pattern form — `case x { null { … } v { … } }`, two arms, no guards. `null` first, because a binder written first would match the absent value too.";

    if (arms.len != 2 or nullIdx != 0 or arms[0].guard != null or arms[1].guard != null) {
        env.lastError = TypeError.custom(shapeError, shapeHint).withLoc(loc);
        return error.TypeError;
    }
    const binder = optionalBinderName(arms[1].pattern) orelse {
        env.lastError = TypeError.custom(shapeError, shapeHint).withLoc(arms[1].patternLoc);
        return error.TypeError;
    };
    for (arms) |arm| {
        if (arm.body == .function and arm.body.function.kind.params.len > 0) {
            env.lastError = TypeError.custom(
                "an arm of a `?T` `case` takes no parameter",
                "The binder is the payload already: `case x { null { … } v { … } }` binds `v` to the value inside the optional.",
            ).withLoc(arm.body.getLoc());
            return error.TypeError;
        }
    }
    return binder;
}

/// Decision 54 — `.Some(v)` / `.None` over a `?T` is a **located error**. The
/// optional is not a variant: the checker still models `?T` as having `Some`
/// and `None` (`variantPayloadTypes`), which is why the spelling compiled and
/// then answered four different things on four backends. It is refused here,
/// at the arm, naming the form the language does have.
fn refuseVariantPatternOverOptional(
    env: *Env,
    subjectType: *T.Type,
    arms: []const ast.CaseArm,
) InferError!void {
    if (optionalInner(subjectType) == null) return;
    for (arms) |arm| {
        const isVariantShaped = switch (arm.pattern) {
            // A path is never a binder (§5.1 P8), and a bare `Some` / `None`
            // is the spelling the decision names: both are variant patterns
            // over a value that has no variants.
            .ident => |n| isVariantPath(n) or
                std.mem.eql(u8, n, "Some") or std.mem.eql(u8, n, "None"),
            // `.Some(v)`, `Option.Some(value: v)`, `Circle(r)` — a payload
            // pattern. `#(a, b)` and `1...9` ride the same node under `shape`
            // and are not variants, so they are left alone.
            .variant => |v| v.shape == .variant and v.name.len > 0,
            else => false,
        };
        if (!isVariantShaped) continue;
        env.lastError = TypeError.custom(
            "an optional is matched by `null`, not by a variant",
            "Decision 54: write `case x { null { … } v { … } }` — the shape `??` and `?.` already use. `Some` and `None` are not spellings this language has.",
        ).withLoc(arm.patternLoc);
        return error.TypeError;
    }
}

/// Decision 8 §5.1 P7 — without a trailing `..` a variant pattern names every
/// field of the variant. `.Rect(width: w)` over `Rect(width: i32, height: i32)`
/// is a missing field, not a shorthand: the fields it does not name would be
/// silently dropped, and `..` is the spelling that says "drop them".
///
/// Only a written variant payload is judged. A whole-payload binding (`Ok ok`)
/// stands for the payload entire, a tuple or range rides the same node under
/// `shape`, and a variant whose declaration is not resolvable is left alone.
fn checkCaseArmArity(
    env: *Env,
    subjectType: *T.Type,
    arms: []const ast.CaseArm,
) InferError!void {
    for (arms) |arm| {
        const v = switch (arm.pattern) {
            .variant => |vv| vv,
            else => continue,
        };
        if (v.shape != .variant or v.rest or v.name.len == 0) continue;
        const written: usize = switch (v.payload) {
            .fields => |f| f.len,
            .literals => |l| l.len,
            .binding => continue,
        };
        const declared = (try variantPayloadFieldNames(env, subjectType, v.name)) orelse continue;
        if (written >= declared.len) continue;
        env.lastError = TypeError
            .missingField(bareVariantName(v.name), declared[written])
            .withLoc(arm.patternLoc);
        return error.TypeError;
    }
}

/// The declared field names of `writtenName`'s variant on `subjectType`, or
/// null when the subject's type or the variant is not resolvable.
fn variantPayloadFieldNames(env: *Env, subjectType: *T.Type, writtenName: []const u8) InferError!?[]const []const u8 {
    const st = subjectType.deref();
    if (st.* != .named) return null;
    const td = env.lookupTypeDef(st.named.name) orelse return null;
    if (td != .enum_) return null;
    const variantName = bareVariantName(writtenName);
    for (td.enum_.variants) |vd| {
        if (!std.mem.eql(u8, vd.name, variantName)) continue;
        const out = try env.arena.alloc([]const u8, vd.fields.len);
        for (vd.fields, 0..) |f, i| out[i] = f.name;
        return out;
    }
    return null;
}

fn bindCaseArmPatternNames(
    env: *Env,
    pattern: ast.Pattern,
    typedSubjects: []const ast.TypedExpr,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    if (pattern == .multi) {
        const patterns = pattern.multi;
        for (patterns, 0..) |p, i| {
            const subjectTy = if (i < typedSubjects.len) typedSubjects[i].getType() else try env.freshVar();
            try bindPatternNamesForSubject(env, p, subjectTy, snapshots);
        }
        return;
    }
    const subjectTy = if (typedSubjects.len > 0) typedSubjects[0].getType() else try env.freshVar();
    try bindPatternNamesForSubject(env, pattern, subjectTy, snapshots);
}

fn namesContain(list: []const []const u8, name: []const u8) bool {
    for (list) |n| {
        if (std.mem.eql(u8, n, name)) return true;
    }
    return false;
}

/// True when `pattern`, as a top-level case arm, binds the whole subject and so
/// matches any value of an enum/string domain — i.e. it is a catch-all. A `_`
/// wildcard, or an identifier that is NOT one of the subject enum's variant
/// names, both bind unconditionally. An OR pattern is a catch-all if any
/// alternative is.
fn patternIsCatchAll(env: *Env, pattern: ast.Pattern, subjectType: *T.Type) bool {
    return switch (pattern) {
        .wildcard => true,
        // §5.1 P8 — a name carrying a `.` is a variant path and never a binder,
        // so it is never a catch-all even when it names no variant of the
        // subject (that case is a mistake the coverage walk reports).
        //
        // §5.2 / §5.4 — nor is a **type pattern**. `i32 { n -> … }` tests the
        // value; whether it happens to cover the subject whole is the coverage
        // walk's question (`caseSubjectDomain`), not a catch-all's.
        .ident => |name| !isVariantPath(name) and
            !isEnumVariantNameForSubject(env, subjectType, name) and
            typePatternName(env, pattern, subjectType) == null,
        .@"or" => |pats| blk: {
            for (pats) |p| {
                if (patternIsCatchAll(env, p, subjectType)) break :blk true;
            }
            break :blk false;
        },
        else => false,
    };
}

/// True when a variant pattern's payload matches *every* value of that variant,
/// so the variant is fully covered. Refined payloads like `Ok(1)` do not; a
/// payload of only bindings / wildcards (e.g. `Err(_)`, `Rgb(r, g, b)`) does.
/// Decision 8 §5.1 — does this pattern match **every** value of its type?
///
/// A binder and a `_` do; a literal, a range, a list and a variant path do not
/// (each selects some values and not others). A tuple pattern (§5.1 P6) matches
/// every tuple when each of its elements does — which is what
/// `.Some(#(a, b))` needs: the payload is one tuple pattern, all binders, so
/// the `Some` variant is fully covered. The `.literals` walk used to answer
/// `false` for every nested pattern, so an enum matched that way read as
/// uncovered ("missing variant(s) Some").
///
/// `elemType` is the type the pattern is matched against, when it is known: an
/// `.ident` is a binder unless it names a variant of that type, which is how a
/// section refinement (`Text(Bold)`) is told from a binding (N28).
fn patternIsIrrefutable(env: *Env, pattern: ast.Pattern, elemType: ?*T.Type) InferError!bool {
    return switch (pattern) {
        .wildcard => true,
        .ident => |nm| blk: {
            if (isVariantPath(nm)) break :blk false;
            const ty = elemType orelse break :blk true;
            break :blk !isEnumVariantNameForSubject(env, ty, nm);
        },
        .variant => |v| switch (v.shape) {
            // `#(a, b)` / `#(a, ..)` — every tuple of the right shape matches
            // when each element pattern does. `..` drops the rest, which is
            // exactly what makes the remainder irrefutable (P7).
            .tuple => blk: {
                const elemTypes: ?[]*T.Type = if (elemType) |t| tupleElementTypes(t) else null;
                switch (v.payload) {
                    .literals => |args| {
                        for (args, 0..) |a, i| {
                            const at: ?*T.Type = if (elemTypes != null and i < elemTypes.?.len)
                                elemTypes.?[i]
                            else
                                null;
                            if (!try patternIsIrrefutable(env, a, at)) break :blk false;
                        }
                        break :blk true;
                    },
                    // A whole-payload binder or a field list over a tuple binds
                    // names and tests nothing.
                    .binding, .fields => break :blk true,
                }
            },
            // A variant path selects one variant; a range selects an interval.
            .variant, .range => false,
        },
        .numberLit, .stringLit, .list => false,
        // An OR is irrefutable only if some alternative is, and an alternative
        // that is makes the others unreachable — the reachability walk reports
        // that separately, so answering on the whole is enough here.
        .@"or" => |pats| blk: {
            for (pats) |alt| {
                if (try patternIsIrrefutable(env, alt, elemType)) break :blk true;
            }
            break :blk false;
        },
        .multi => false,
    };
}

/// The element types of a tuple type, or null when the type is not a tuple (or
/// is not known yet).
fn tupleElementTypes(ty: *T.Type) ?[]*T.Type {
    const d = ty.deref();
    if (d.* != .named or !std.mem.eql(u8, d.named.name, "tuple")) return null;
    return d.named.args;
}

fn variantPayloadIrrefutable(
    env: *Env,
    subjectType: *T.Type,
    variantName: []const u8,
    payload: anytype,
) InferError!bool {
    return switch (payload) {
        // A single-name payload (`Text(Bold)`) is a binder unless the name is a
        // variant of the payload's own type — inside a section wrapper it is a
        // refinement, not a binding.
        .binding => |name| blk: {
            const payloadTypes = try variantPayloadTypes(env, subjectType, variantName);
            if (payloadTypes) |p| {
                if (p.len == 1 and isEnumVariantNameForSubject(env, p[0], name)) break :blk false;
            }
            break :blk true;
        },
        .fields => |names| blk: {
            const payloadTypes = try variantPayloadTypes(env, subjectType, variantName);
            if (payloadTypes) |p| {
                for (names, 0..) |name, i| {
                    if (i < p.len and isEnumVariantNameForSubject(env, p[i], name)) break :blk false;
                }
            }
            break :blk true;
        },
        .literals => |args| blk: {
            // N28 — an `.ident` arg is a binder (`Ok(v)`, irrefutable) *unless*
            // it names a variant of the payload's own type, as it does inside a
            // section wrapper (`Text(Bold)`). That match refines the section,
            // so the wrapper variant stays open: counting it as full coverage
            // would let a `case` skip the section's other variants in silence
            // (decision 8 §5.4).
            const payloadTypes = try variantPayloadTypes(env, subjectType, variantName);
            for (args, 0..) |a, i| {
                const argTy: ?*T.Type = if (payloadTypes != null and i < payloadTypes.?.len)
                    payloadTypes.?[i]
                else
                    null;
                if (!try patternIsIrrefutable(env, a, argTy)) break :blk false;
            }
            break :blk true;
        },
    };
}

/// Append to `covered` every enum variant that `pattern` *fully* covers (an
/// irrefutable variant match). Refined matches (`Ok(1)`) are skipped so the
/// variant stays "open".
fn collectFullyCoveredVariants(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    covered: *std.ArrayListUnmanaged([]const u8),
) InferError!void {
    switch (pattern) {
        .ident => |name| {
            const bare = bareVariantName(name);
            if (isEnumVariantNameForSubject(env, subjectType, name) and !namesContain(covered.items, bare)) {
                try covered.append(env.arena, bare);
            }
        },
        .variant => |v| {
            const bare = bareVariantName(v.name);
            if (try variantPayloadIrrefutable(env, subjectType, v.name, v.payload) and !namesContain(covered.items, bare)) {
                try covered.append(env.arena, bare);
            }
        },
        .@"or" => |pats| {
            for (pats) |p| try collectFullyCoveredVariants(env, p, subjectType, covered);
        },
        else => {},
    }
}

/// When `pattern` is a *single* irrefutable variant match whose variant is
/// already covered, return that variant's name (the arm is unreachable). OR
/// patterns are skipped — one covered alternative does not make the arm dead.
fn alreadyCoveredVariant(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    covered: []const []const u8,
) InferError!?[]const u8 {
    switch (pattern) {
        .ident => |name| {
            const bare = bareVariantName(name);
            if (isEnumVariantNameForSubject(env, subjectType, name) and namesContain(covered, bare)) return bare;
        },
        .variant => |v| {
            const bare = bareVariantName(v.name);
            if (try variantPayloadIrrefutable(env, subjectType, v.name, v.payload) and namesContain(covered, bare)) return bare;
        },
        else => {},
    }
    return null;
}

/// Decision 8 §5.4 — the set of values a `case` subject draws from, and what it
/// takes to cover that set.
const CaseDomain = union(enum) {
    /// A `type` with variants: covered when every variant is.
    enum_: []const []const u8,
    /// `A | B` (§3.3): covered when every member is named by a type pattern.
    /// The identity of a union *is* its members, so the members are the domain.
    union_: []*T.Type,
    /// `string`, `i32`, `unknown` — an unbounded set of values no finite list of
    /// literal arms reaches. Only `_`, or a type pattern naming the subject's own
    /// type (§5.4's "a type covered whole"), covers it. `unknown` has no such
    /// type pattern, which is why §5.4 always requires `_` over it.
    open,
};

/// The two open domains §5.4 names by hand, beside `unknown`. Deliberately not
/// every scalar: widening the rule to `f64`, `bool` and the sized integers turns
/// every `case` on one of them that has no `_` into an error, and §5.4 states
/// the rule for `i32` and `string`. The rest is reported, not assumed.
const open_case_domain_names = [_][]const u8{ "i32", "string" };

/// Resolve a `case` subject's domain, or null when the subject is not
/// exhaustiveness-checked at all (a record, a generic, an array, a `?T`, an
/// unresolved type variable).
fn caseSubjectDomain(env: *Env, resolved: *T.Type) InferError!?CaseDomain {
    // §3.3 — a `case` covering every member of a union needs no `_`.
    if (resolved.* == .union_) return CaseDomain{ .union_ = resolved.union_ };
    if (resolved.* != .named) return null;
    // §5.4 — `unknown` always needs `_`: no type pattern covers it, because a
    // value of any other type is still a possibility the arm did not test.
    if (unifyMod.isUnknown(resolved)) return CaseDomain.open;
    const name = resolved.named.name;
    if (env.lookupTypeDef(name)) |td| {
        switch (td) {
            .enum_ => |en| {
                const names = try env.arena.alloc([]const u8, en.variants.len);
                for (en.variants, 0..) |v, i| names[i] = v.name;
                return CaseDomain{ .enum_ = names };
            },
            else => return null,
        }
    }
    for (open_case_domain_names) |p| {
        if (std.mem.eql(u8, name, p)) return CaseDomain.open;
    }
    return null;
}

/// A printable label for a `case` subject: a named type's own name, or a union
/// spelled out `i32 | string` — "union" on its own names nothing the author
/// wrote. Owned by `env.arena`.
fn caseSubjectLabel(env: *Env, ty: *T.Type) InferError![]const u8 {
    const d = ty.deref();
    if (d.* != .union_) return switch (d.*) {
        .named => |n| n.name,
        else => "value",
    };
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    for (d.union_, 0..) |m, i| {
        if (i > 0) try buf.appendSlice(env.arena, " | ");
        try buf.appendSlice(env.arena, try caseSubjectLabel(env, m));
    }
    return buf.toOwnedSlice(env.arena);
}

/// True when the type a type pattern tests is the same named type as `member` —
/// the only way a union member is covered arm by arm (§3.3).
fn sameNamedType(a: *T.Type, b: *T.Type) bool {
    const da = a.deref();
    const db = b.deref();
    if (da.* != .named or db.* != .named) return false;
    return std.mem.eql(u8, da.named.name, db.named.name);
}

/// Full exhaustiveness + reachability analysis for a `case`. Sets
/// `env.lastError` and returns `error.TypeError` on the first problem: an
/// unreachable arm, an open domain with no `_`, a union with an uncovered member,
/// or an enum with uncovered variants. Subjects whose type names no domain
/// (`caseSubjectDomain`) are not checked.
fn checkCaseExhaustiveness(
    env: *Env,
    subjectType: *T.Type,
    arms: []const ast.CaseArm,
    loc: ast.Loc,
) InferError!void {
    const resolved = subjectType.deref();
    const domain = (try caseSubjectDomain(env, resolved)) orelse return;
    const typeName = try caseSubjectLabel(env, resolved);

    var covered: std.ArrayListUnmanaged([]const u8) = .empty;
    defer covered.deinit(env.arena);
    var hasCatchAll = false;
    // §5.4 — a type pattern naming the subject's own type covers it whole
    // (`case n { i32 { m -> … } }` on an `i32`).
    var wholeTypeCovered = false;
    // §3.3 — one flag per union member, set by the arm that tests that member.
    const memberCovered: []bool = switch (domain) {
        .union_ => |members| blk: {
            const flags = try env.arena.alloc(bool, members.len);
            @memset(flags, false);
            break :blk flags;
        },
        else => &.{},
    };

    for (arms) |arm| {
        const guarded = arm.guard != null;

        // Any unguarded arm following an unguarded catch-all can never run.
        if (hasCatchAll and !guarded) {
            env.lastError = TypeError.redundantPattern(typeName, "this arm").withLoc(arm.body.getLoc());
            return error.TypeError;
        }

        // §5.3 / §5.4 — a guarded arm may fail its guard, so it neither covers
        // anything for exhaustiveness nor shadows a later arm.
        if (guarded) continue;

        if (patternIsCatchAll(env, arm.pattern, resolved)) {
            hasCatchAll = true;
            continue;
        }

        // §5.2 / §5.4 — a type pattern. What it covers depends on the domain: the
        // subject's own type covers an open domain whole, and a union member
        // covers that member. Over `unknown` it covers nothing.
        if (try typePatternType(env, arm.pattern, resolved)) |tested| {
            switch (domain) {
                .open => if (!unifyMod.isUnknown(resolved) and sameNamedType(tested, resolved)) {
                    wholeTypeCovered = true;
                },
                .union_ => |members| for (members, 0..) |m, i| {
                    if (sameNamedType(tested, m)) memberCovered[i] = true;
                },
                .enum_ => {},
            }
            continue;
        }

        if (try alreadyCoveredVariant(env, arm.pattern, resolved, covered.items)) |dup| {
            const desc = try std.fmt.allocPrint(env.arena, "variant '{s}'", .{dup});
            env.lastError = TypeError.redundantPattern(typeName, desc).withLoc(arm.body.getLoc());
            return error.TypeError;
        }

        try collectFullyCoveredVariants(env, arm.pattern, resolved, &covered);
    }

    if (hasCatchAll) return;

    switch (domain) {
        .open => {
            if (wholeTypeCovered) return;
            env.lastError = TypeError.nonExhaustive(typeName, &.{}).withLoc(loc);
            return error.TypeError;
        },
        .union_ => |members| {
            var missing: std.ArrayListUnmanaged([]const u8) = .empty;
            for (members, 0..) |m, i| {
                if (!memberCovered[i]) try missing.append(env.arena, try caseSubjectLabel(env, m));
            }
            if (missing.items.len > 0) {
                env.lastError = TypeError
                    .nonExhaustiveOf(typeName, try missing.toOwnedSlice(env.arena), "member(s)")
                    .withLoc(loc);
                return error.TypeError;
            }
        },
        .enum_ => |variantNames| {
            var missing: std.ArrayListUnmanaged([]const u8) = .empty;
            for (variantNames) |name| {
                if (!namesContain(covered.items, name)) try missing.append(env.arena, name);
            }
            if (missing.items.len > 0) {
                env.lastError = TypeError.nonExhaustive(typeName, try missing.toOwnedSlice(env.arena)).withLoc(loc);
                return error.TypeError;
            }
        },
    }
}

/// Infer the type of `expr` AND build the fully-annotated `TypedExpr` in one
/// pass.  Every child node is recursively typed before its parent is built, so
/// no expression is visited more than once.  All allocations go into env.arena.
pub fn inferExprTyped(env: *Env, expr: ast.Expr) InferError!TypedExpr {
    // 00 · 01-checker — an expectation belongs to the position it was set for.
    // Only an identifier chain reads it (a leading-dot enum path) and only an
    // array literal passes it on (to its elements); every other node clears it
    // so a nested expression never inherits its parent's expected type. A
    // leading-dot call (`.Circle(radius: 1)`) reads it too: its head is the
    // same path, and `inferCallExpr` clears it before the arguments.
    const outer_expected = env.expectedType;
    defer env.expectedType = outer_expected;
    switch (expr) {
        .identifier, .collection => {},
        .call => |c| if (!isLeadingDotCall(c)) {
            env.expectedType = null;
        },
        else => env.expectedType = null,
    }
    return switch (expr) {
        // ── literals ──────────────────────────────────────────────────────────
        .literal => |l| inferLiteralExpr(env, l, l.loc),

        // ── identifiers ───────────────────────────────────────────────────────
        .identifier => |i| inferIdentifierExpr(env, i, i.loc),

        // ── binary operations ───────────────────────────────────────────────────
        .binaryOp => |b| inferBinaryOpExpr(env, b, b.loc),

        // ── unary operations ──────────────────────────────────────────────────
        .unaryOp => |u| inferUnaryOpExpr(env, u, u.loc),

        // ── control flow ──────────────────────────────────────────────────────
        .jump => |j| inferJumpExpr(env, j, j.loc),
        .branch => |b| inferBranchExpr(env, b, b.loc),
        .loop => |lp| inferLoopExpr(env, lp, lp.loc),

        // ── binding expressions ────────────────────────────────────────────────
        .binding => |b| inferBindingExpr(env, b, b.loc),

        // ── use-hook expressions (@Context F7) ────────────────────────────────
        .useHook => |uh| inferUseHookExpr(env, uh, uh.loc),

        // ── call expressions ───────────────────────────────────────────────────
        .call => |c| inferCallExpr(env, c, c.loc),

        // ── function definition expressions ────────────────────────────────────
        .function => |f| inferFunctionExpr(env, f, f.loc),

        // ── collection expressions ─────────────────────────────────────────────
        .collection => |co| inferCollectionExpr(env, co, co.loc),

        // ── comptime expressions ───────────────────────────────────────────────
        .comptime_ => |a| inferComptimeExpr(env, a, a.loc),
    };
}

/// Infer `expr` in a position whose type the site already knows (00 ·
/// 01-checker). The expectation is only a hint — `tryResolveEnumSectionPath`
/// is its one reader — and the caller's own expectation is restored on the way
/// out, so a site can set one per sub-expression.
fn inferExprTypedExpecting(env: *Env, expr: ast.Expr, expected: ?*T.Type) InferError!TypedExpr {
    const prev = env.expectedType;
    defer env.expectedType = prev;
    env.expectedType = expected;
    return inferExprTyped(env, expr);
}

/// `inferExprTypedExpecting` for the untyped inference path.
fn inferExprExpecting(env: *Env, expr: ast.Expr, expected: ?*T.Type) InferError!*T.Type {
    const prev = env.expectedType;
    defer env.expectedType = prev;
    env.expectedType = expected;
    return inferExpr(env, expr);
}

// ── Helper functions for each expression category ───────────────────────────

/// Infer type for literal expressions (strings, numbers, null, comments)
fn inferLiteralExpr(env: *Env, lit: ast.LiteralExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (lit.kind) {
        .stringLit => |s| TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType("string"), .kind = .{ .stringLit = s } } },
        .stringTemplate => |t| {
            // Desugar `"a ${x} b"` into the concatenation chain `"a " + x + " b"`
            // (same semantics as written-out string `+`, incl. coercion). The
            // typed AST therefore never contains a stringTemplate node, so
            // transform/eval/codegen stay untouched.
            var acc: ?*ast.Expr = null;
            if (t.parts.len > 0 and t.parts[0] == .expr) {
                // Force a string-typed result when the template starts with a hole.
                const empty = try env.arena.create(ast.Expr);
                empty.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = "" } } };
                acc = empty;
            }
            for (t.parts) |p| {
                const operand: *ast.Expr = switch (p) {
                    .text => |txt| blk: {
                        const e = try env.arena.create(ast.Expr);
                        e.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = txt } } };
                        break :blk e;
                    },
                    .expr => |e| e,
                };
                if (acc) |lhs| {
                    const bin = try env.arena.create(ast.Expr);
                    bin.* = .{ .binaryOp = .{ .loc = loc, .op = .add, .lhs = lhs, .rhs = operand } };
                    acc = bin;
                } else {
                    acc = operand;
                }
            }
            return inferExprTyped(env, acc.?.*);
        },
        .numberLit => |n| blk: {
            const isFloat = std.mem.indexOfScalar(u8, n, '.') != null;
            break :blk TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType(if (isFloat) "f64" else "i32"), .kind = .{ .numberLit = n } } };
        },
        .null_ => blk: {
            const innerVar = try env.freshVar();
            const optArgs = try env.arena.alloc(*T.Type, 1);
            optArgs[0] = innerVar;
            break :blk TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedTypeArgs("optional", optArgs), .kind = .null_ } };
        },
        .comment => |c| TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .comment = c } } },
    };
}

/// Infer type for identifier expressions (ident, dotIdent, identAccess)
fn inferIdentifierExpr(env: *Env, ident: ast.IdentifierExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (ident.kind) {
        .ident => |name| {
            if (env.lookup(name)) |ty| {
                // A generic fn referenced as a value (`val f = identity;`,
                // `xs.map(identity)`) gets its own instantiation — the
                // scheme's `.generic` vars must never reach `unify`.
                const inst = try instantiateGenericType(env, ty);
                return TypedExpr{ .identifier = .{ .loc = loc, .type_ = inst, .kind = .{ .ident = name } } };
            }
            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
            return error.TypeError;
        },
        .dotIdent => |name| {
            if (env.lookup(name)) |ty| return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .dotIdent = name } } };
            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
            return error.TypeError;
        },
        .identAccess => |ia| {
            // §enum-sections F2 — path-access via dot-shorthand chain.
            // `.Color.Red.500` parses as `identAccess(identAccess(dotIdent(Color),
            // Red), 500)`. When the chain root is a `dotIdent`, the chain may
            // resolve as a section path into an enum that carries sections:
            // walk the chain through the parent enum's section tree and lower
            // to nested constructor calls.
            if (try tryResolveEnumSectionPath(env, ia.member, ia.receiver, loc)) |resolved| return resolved;

            // When receiver is an identifier, check if it's a type name rather than a variable.
            // This handles enum/record/struct constructor access like Color.Red, Option.None
            if (ia.receiver.* == .identifier) {
                if (ia.receiver.*.identifier.kind == .ident) {
                    const receiverName = ia.receiver.*.identifier.kind.ident;
                    // Check if this identifier is a registered type definition
                    if (env.lookupTypeDef(receiverName)) |td| {
                        switch (td) {
                            .enum_ => |en| {
                                var found = false;
                                for (en.variants) |v| {
                                    if (std.mem.eql(u8, v.name, ia.member)) {
                                        found = true;
                                        break;
                                    }
                                }
                                if (!found) {
                                    env.lastError = TypeError.unknownField(receiverName, ia.member).withLoc(loc);
                                    return error.TypeError;
                                }
                                // C7: a generic enum's unit variant carries one
                                // fresh var per declared generic param, so
                                // `val n: Option<i32> = Option.None` unifies.
                                const ty = if (en.genericParams.len == 0)
                                    try env.namedType(receiverName)
                                else blk: {
                                    const args = try env.arena.alloc(*T.Type, en.genericParams.len);
                                    for (args) |*a| a.* = try env.freshVar();
                                    break :blk try env.namedTypeArgs(receiverName, args);
                                };
                                const recvTyped = try makeTypedPtr(env, TypedExpr{ .identifier = .{
                                    .loc = ia.receiver.*.getLoc(),
                                    .type_ = ty,
                                    .kind = .{ .ident = receiverName },
                                } });
                                return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .identAccess = .{
                                    .receiver = recvTyped,
                                    .member = ia.member,
                                } } } };
                            },
                            else => {},
                        }
                    }
                }
            }
            // Regular instance field access on a variable/instance.
            // Optional chaining (`a?.b`): the receiver may be `?T` — resolve the
            // member on the inner `T` and wrap the result back into an optional
            // (already-optional member types are not double-wrapped).
            const recvTyped = try inferExprTyped(env, ia.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            var recvType = recvTyped.getType().deref();
            if (ia.optional) {
                if (recvType.* == .named and std.mem.eql(u8, recvType.named.name, "optional") and
                    recvType.named.args.len >= 1)
                {
                    recvType = recvType.named.args[0].deref();
                }
            }
            // Decision 8 §2.2 — an `unknown` receiver has no members. Without
            // this the field falls through every arm below and lands on a fresh
            // variable, so `a.x` on an `unknown` checks silently.
            try refuseUnknownUse(env, recvType, loc, "read a field of");
            var outType: *T.Type = try env.freshVar();
            // Anonymous structural record: resolve the field directly.
            if (recvType.* == .record) {
                const fields = recvType.record;
                var found = false;
                for (fields) |f| {
                    if (std.mem.eql(u8, f.name, ia.member)) {
                        outType = f.type_;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    env.lastError = TypeError.unknownField("record", ia.member).withLoc(loc);
                    return error.TypeError;
                }
            }
            // Tuple element access: `t._0`, `t._1`, … on a `#(A, B, …)` value.
            // The element type comes from the tuple's positional type args.
            if (recvType.* == .named and std.mem.eql(u8, recvType.named.name, "tuple")) {
                const idxStr = if (ia.member.len > 0 and ia.member[0] == '_') ia.member[1..] else ia.member;
                if (std.fmt.parseInt(usize, idxStr, 10)) |idx| {
                    if (idx < recvType.named.args.len) outType = recvType.named.args[idx];
                } else |_| {
                    // Decision 8 §6 T4: `row.pop` names an element by its label.
                    // The label exists only here — record the positional rewrite
                    // (`row._1`) for the transform, so every backend sees an index.
                    const idx = tupleLabelIndex(recvType.named.labels, ia.member) orelse {
                        env.lastError = TypeError.custom(
                            try std.fmt.allocPrint(env.arena, "this tuple has no element labeled `{s}`", .{ia.member}),
                            "labels come from the tuple's written type or from the variables it was built from; use the position instead: `._0`, `._1`, …",
                        ).withLoc(loc);
                        return error.TypeError;
                    };
                    outType = recvType.named.args[idx];
                    const rewrite = try env.arena.create(ast.Expr);
                    rewrite.* = .{ .identifier = .{ .loc = loc, .kind = .{ .identAccess = .{
                        .receiver = ia.receiver,
                        .member = try std.fmt.allocPrint(env.arena, "_{d}", .{idx}),
                        .optional = ia.optional,
                    } } } };
                    try env.enumSectionRewrites.put(loc, rewrite);
                }
            }
            if (recvType.* == .named) {
                const recvNamed = recvType.named;
                // `arr.length` / `s.length` / `arr.len`: the host length op
                // (`length(Arr)` / `string:length(S)` / `.length` in JS), NOT a
                // map field read. Record the primitive kind so the non-JS
                // backends lower the field access correctly.
                if ((std.mem.eql(u8, recvNamed.name, "array") or std.mem.eql(u8, recvNamed.name, "string")) and
                    (std.mem.eql(u8, ia.member, "length") or std.mem.eql(u8, ia.member, "len")))
                {
                    const k: envMod.PrimKind = if (std.mem.eql(u8, recvNamed.name, "string")) .string else .array;
                    try env.instanceLowerings.put(loc, .{ .prim = k });
                    outType = try env.namedType("i32");
                }
                // Tuple index access (`t._0`, `t._1`, …): resolve to the Nth
                // element type so a `?T` element keeps its `@Option` method
                // surface (`.unwrapOr`) — without this the element gets a fresh
                // var and the method-call lowering can't fire.
                else if (std.mem.eql(u8, recvNamed.name, "tuple")) {
                    if (tupleMemberIndex(ia.member)) |idx| {
                        if (idx < recvNamed.args.len) outType = recvNamed.args[idx];
                    }
                } else if (env.lookupTypeDef(recvNamed.name)) |td| {
                    switch (td) {
                        .record, .struct_ => {
                            if (td.findField(ia.member)) |f| {
                                // The receiver's type, for the backends that
                                // store a record positionally — erlang and beam
                                // under decision 21 read `element(N + 1, V)`,
                                // and the field's NAME does not carry N.
                                try env.instanceLowerings.put(loc, .{ .field_of = recvNamed.name });
                                // Generic instance: substitute the registered
                                // cells with the instance's type args.
                                outType = try instantiateFieldType(env, recvNamed.name, recvNamed.args, f.type_);
                            } else {
                                env.lastError = TypeError.unknownField(recvNamed.name, ia.member).withLoc(loc);
                                return error.TypeError;
                            }
                        },
                        .enum_ => {
                            env.lastError = TypeError.unknownField(recvNamed.name, ia.member).withLoc(loc);
                            return error.TypeError;
                        },
                    }
                }
            }
            if (ia.optional) {
                const outDeref = outType.deref();
                const alreadyOptional = outDeref.* == .named and
                    std.mem.eql(u8, outDeref.named.name, "optional");
                if (!alreadyOptional) {
                    outType = try env.namedTypeArgs("optional", &.{outType});
                }
            }
            return TypedExpr{ .identifier = .{ .loc = loc, .type_ = outType, .kind = .{ .identAccess = .{
                .receiver = recvPtr,
                .member = ia.member,
                .optional = ia.optional,
            } } } };
        },
    };
}

/// Infer type for binary operation expressions
fn inferBinaryOpExpr(env: *Env, binop: ast.BinOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const lhsTyped = try inferExprTyped(env, binop.lhs.*);

    // AND condition narrowing: `x && x.field` — if LHS is an optional variable,
    // narrow it before inferring the RHS so `.field` access resolves.
    var andSnapshots: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
    defer andSnapshots.deinit(env.arena);
    if (binop.op == .@"and") {
        if (binop.lhs.* == .identifier and binop.lhs.identifier.kind == .ident) {
            const varName = binop.lhs.identifier.kind.ident;
            const lhsTy = lhsTyped.getType().deref();
            if (lhsTy.* == .named and std.mem.eql(u8, lhsTy.named.name, "optional") and lhsTy.named.args.len >= 1) {
                const innerTy = lhsTy.named.args[0];
                const old = env.lookup(varName);
                try andSnapshots.append(env.arena, .{ .name = varName, .previous = old });
                try env.bind(varName, innerTy);
            }
        }
    }

    const rhsTyped = try inferExprTyped(env, binop.rhs.*);

    // Restore after RHS inference.
    if (andSnapshots.items.len > 0) {
        try restorePatternBindings(env, andSnapshots.items);
    }
    const lhsPtr = try makeTypedPtr(env, lhsTyped);
    const rhsPtr = try makeTypedPtr(env, rhsTyped);

    // Determine result type based on operator
    const resultType: *T.Type = switch (binop.op) {
        // §2.2 — `==` and `!=` are the two comparisons an `unknown` answers
        // (they compare by value, §2.3). An ordering comparison is arithmetic:
        // it is not in §2.2's allowed list, and it reads the value's magnitude
        // exactly as `+` does.
        .lt, .gt, .lte, .gte => blk: {
            try refuseUnknownUse(env, lhsTyped.getType(), binop.lhs.getLoc(), "compare");
            try refuseUnknownUse(env, rhsTyped.getType(), binop.rhs.getLoc(), "compare");
            break :blk try env.namedType("bool");
        },
        .eq, .ne => try env.namedType("bool"),
        .@"and", .@"or" => blk: {
            // 06 C3 — `unifyAt(env, a, b, loc)` is TARGET-first: `a` is what
            // the context expects, `b` what was written
            // (`typeMismatch(a, b)` renders "expected a, got b"). These two
            // passed the operand as `a`, so `1 && true` read "expected i32,
            // got bool". The caret is on the OPERAND, not the whole expression.
            try unifyAt(env, try env.namedType("bool"), lhsTyped.getType(), binop.lhs.getLoc());
            try unifyAt(env, try env.namedType("bool"), rhsTyped.getType(), binop.rhs.getLoc());
            break :blk try env.namedType("bool");
        },
        .add => blk: {
            // String + anything → string (coercion)
            const lhsTy = lhsTyped.getType();
            const rhsTy = rhsTyped.getType();
            // §2.2 — `+` is the one arithmetic operator `requireNumericOperand`
            // below does not guard, because it also concatenates strings. An
            // `unknown` operand is refused here for both readings at once:
            // nothing has established that it is either.
            try refuseUnknownUse(env, lhsTy, binop.lhs.getLoc(), "do arithmetic on");
            try refuseUnknownUse(env, rhsTy, binop.rhs.getLoc(), "do arithmetic on");
            if (lhsTy.isNamed("string") or rhsTy.isNamed("string")) break :blk try env.namedType("string");
            // Numeric promotion: float wins over int
            if (isFloatType(lhsTy) and isIntType(rhsTy)) break :blk lhsTy;
            if (isIntType(lhsTy) and isFloatType(rhsTy)) break :blk rhsTy;
            try unify(env, lhsTy, rhsTy);
            break :blk lhsTy;
        },
        .sub, .mul, .div, .mod => blk: {
            const lhsTy = lhsTyped.getType();
            const rhsTy = rhsTyped.getType();
            // 06 C3 — both operands must be numeric. `unify(lhs, rhs)` alone
            // accepted `"a" * "b"`: two strings agree with each other.
            const opName = switch (binop.op) {
                .sub => "-",
                .mul => "*",
                .div => "/",
                else => "%",
            };
            try requireNumericOperand(env, lhsTy, opName, binop.lhs.getLoc());
            try requireNumericOperand(env, rhsTy, opName, binop.rhs.getLoc());
            if (isFloatType(lhsTy) and isIntType(rhsTy)) break :blk lhsTy;
            if (isIntType(lhsTy) and isFloatType(rhsTy)) break :blk rhsTy;
            try unify(env, lhsTy, rhsTy);
            break :blk lhsTy;
        },
    };
    return TypedExpr{ .binaryOp = .{
        .loc = loc,
        .type_ = resultType,
        .op = binop.op,
        .lhs = lhsPtr,
        .rhs = rhsPtr,
    } };
}

/// Infer type for unary operation expressions
fn inferUnaryOpExpr(env: *Env, unaryop: ast.UnaryOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const operandTyped = try inferExprTyped(env, unaryop.expr.*);
    const operandPtr = try makeTypedPtr(env, operandTyped);
    return switch (unaryop.op) {
        .not => blk: {
            // 06 C3 — target-first, located at the operand (see the `&&`/`||`
            // note in `inferBinaryOpExpr`).
            try unifyAt(env, try env.namedType("bool"), operandTyped.getType(), unaryop.expr.getLoc());
            break :blk TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = try env.namedType("bool"), .op = .not, .expr = operandPtr } };
        },
        // 06 C3 — `-x` applied no constraint at all, so `-"s"` checked.
        .neg => blk: {
            try requireNumericOperand(env, operandTyped.getType(), "-", unaryop.expr.getLoc());
            break :blk TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = operandTyped.getType(), .op = .neg, .expr = operandPtr } };
        },
    };
}

/// Returns the called member name when `expr` is `<wrapper>.<member>(...)`
/// AND `member` appears in `members`. Otherwise null. Syntactic check —
/// no type inference required. Drives the §1 / §1F manual-construction
/// rejections (R11 / R12 / RF1 / RF2 / RF5).
fn wrapperMemberCallName(expr: ast.Expr, wrapper: []const u8, members: []const []const u8) ?[]const u8 {
    if (expr != .call) return null;
    const call = expr.call;
    if (call.kind != .call) return null;
    const cc = call.kind.call;
    const recv = cc.receiver orelse return null;
    if (recv.* != .identifier) return null;
    if (recv.identifier.kind != .ident) return null;
    if (!std.mem.eql(u8, recv.identifier.kind.ident, wrapper)) return null;
    for (members) |m| {
        if (std.mem.eql(u8, cc.callee, m)) return cc.callee;
    }
    return null;
}

/// Returns the `Result` variant name when `expr` is the form
/// `Result.Ok(...)` / `Result.Error(...)` (§1 / §2 R11–R12 detection).
fn resultVariantCallName(expr: ast.Expr) ?[]const u8 {
    return wrapperMemberCallName(expr, "Result", &.{ "Ok", "Error" });
}

/// Returns the `Future` constructor name when `expr` is the form
/// `Future.resolved(...)` / `Future.rejected(...)` (§1F / §2 RF1/RF2/RF5
/// detection).
fn futureConstructorCallName(expr: ast.Expr) ?[]const u8 {
    return wrapperMemberCallName(expr, "Future", &.{ "resolved", "rejected" });
}

/// True when `env` is currently inside a body whose `#[@<effect>]` matches `kind`.
fn inEffectContext(env: *Env, kind: ast.EffectKind) bool {
    const ctx = env.starFn orelse return false;
    return ctx.effect == kind;
}

/// The refusal for `what` written outside a generator scope: the three
/// annotations that open one, on a fn or on a `loop`, read off the chain.
fn generatorScopeRefusal(env: *Env, code: []const u8, what: []const u8) ![]const u8 {
    var buf: [6]ast.EffectKind = undefined;
    const granting = effectChain.grantingEffects(.yield_, &buf);
    var names: std.ArrayListUnmanaged(u8) = .empty;
    for (granting, 0..) |e, i| {
        if (i > 0) try names.appendSlice(env.arena, if (i + 1 == granting.len) " or " else ", ");
        try names.appendSlice(env.arena, try std.fmt.allocPrint(env.arena, "`#[@{s}]`", .{e.annotationName()}));
    }
    const body: []const u8 = if (env.fnEffect) |e|
        try std.fmt.allocPrint(env.arena, "`#[@{s}]` is `@{s}`, which is no generator", .{ e.annotationName(), e.returnWrapper() })
    else
        "this body carries no generator annotation";
    return std.fmt.allocPrint(
        env.arena,
        "{s}: {s} needs a generator scope — {s} on the fn, or on a `loop`; {s}",
        .{ code, what, names.items, body },
    );
}

/// Infer type for jump expressions (return, throw, try, break, continue, yield)
fn inferJumpExpr(env: *Env, j: ast.MakeExpr(.untyped, ast.JumpExprOf(.untyped)), loc: ast.Loc) InferError!TypedExpr {
    return switch (j.kind) {
        .@"return" => |r| {
            // R11 (§2) — `return Result.Ok(<r>);` / `return Result.Error(<e>);`
            // inside a `#[@result]` body is the manual wrapping form that the
            // auto-wrap contract forbids: the @Result variants are constructed
            // by `return` / `throw` ALONE, never by the author.
            if (env.throwContext == .result) {
                if (r) |rv| {
                    if (resultVariantCallName(rv.*)) |variant| {
                        if (std.mem.eql(u8, variant, "Ok")) {
                            env.lastError = TypeError.custom(
                                diagnostics.return_must_be_bare_R ++
                                    ": a #[@result] fn must `return` a value of type R; the @Result::Ok wrapping is implicit.",
                                "Drop the `Result.Ok(...)` wrapping — write `return <r>;` directly.",
                            ).withLoc(loc);
                        } else {
                            env.lastError = TypeError.custom(
                                diagnostics.result_return_type_mismatch ++
                                    ": a #[@result] fn returns R via `return`; use `throw` for the error variant.",
                                "If the value is an error, change `return Result.Error(<e>);` to `throw <e>;`.",
                            ).withLoc(loc);
                        }
                        return error.TypeError;
                    }
                }
            }
            // RI1 (§1I / §2 R14) — `return <expr>;` inside `#[@iterator]` /
            // `#[@futureGenerator]` is forbidden: the iterator/futureGenerator
            // protocol carries no `R` channel. The author uses `break` for a
            // clean end and `break <C>` for a completion value. Bare `return;`
            // (no value, an implicit clean end) stays legal.
            if (r != null and
                (inEffectContext(env, .iterator) or
                    inEffectContext(env, .futureGenerator)))
            {
                env.lastError = TypeError.custom(
                    diagnostics.iterator_return_forbidden ++
                        ": use `break <C>` to deliver an iterator's completion value, or bare `break` for a clean end. Plain `return <expr>` is only valid in #[@generator].",
                    "Replace `return <expr>;` with `break <expr>;` (the third generic of @Iterator<T, E, C> declares the completion-value type).",
                ).withLoc(loc);
                return error.TypeError;
            }
            // RF1 (§1F / §2 R17) — `return Future.resolved(<t>);` /
            // `return Future.rejected(<e>);` inside a `#[@future]` body forbids
            // the manual wrapping. The auto-wrap rewrites bare `return <t>;`
            // to `@Future.resolved(<t>)` at AST level.
            if (inEffectContext(env, .future)) {
                if (r) |rv| {
                    if (futureConstructorCallName(rv.*)) |ctor| {
                        if (std.mem.eql(u8, ctor, "resolved")) {
                            env.lastError = TypeError.custom(
                                diagnostics.future_return_must_be_bare_T ++
                                    ": a #[@future] fn must `return` a value of type T; the @Future.resolved wrapping is implicit.",
                                "Drop the `Future.resolved(...)` wrapping — write `return <t>;` directly.",
                            ).withLoc(loc);
                        } else {
                            env.lastError = TypeError.custom(
                                diagnostics.future_return_type_mismatch ++
                                    ": a #[@future] fn resolves T via `return`; use `throw` for the rejection variant.",
                                "If the value is the rejection payload, change `return Future.rejected(<e>);` to `throw <e>;`.",
                            ).withLoc(loc);
                        }
                        return error.TypeError;
                    }
                }
            }
            // 00 · 01-checker — the body's return target is the expected type
            // of a returned value (`fn pick() -> Token { return .Color.Red.500; }`).
            const valPtr: ?*TypedExpr = if (r) |rv| try makeTypedPtr(env, try inferExprTypedExpecting(env, rv.*, env.returnTarget)) else null;
            // Inside a `-> @Result<…>` fn, a returned plain value must be wrapped
            // into `{ok, V}` by the transform pass (`__bp_ok`). Skip values that
            // are already a `@Result` (passthrough) and `try`/`catch` forms —
            // those have dedicated statement-level lowerings in each backend.
            if (env.throwContext == .result) {
                if (r) |rv| {
                    const isCatchForm = rv.* == .branch and rv.branch.kind == .tryCatch;
                    const isTryJump = rv.* == .jump and rv.jump.kind == .try_;
                    const valIsResult = blk: {
                        const vt = valPtr.?.getType().deref();
                        break :blk vt.* == .named and std.mem.eql(u8, vt.named.name, "Result");
                    };
                    if (isTryJump) {
                        // `return try f()` — unwrap-then-rewrap is the identity;
                        // the transform returns `f()`'s Result directly.
                        try env.result_jump_lowerings.put(loc, .unwrap_passthrough);
                    } else if (!isCatchForm and !valIsResult) {
                        try env.result_jump_lowerings.put(loc, .wrap_ok);
                    }
                } else {
                    // A bare `return;` is the `ok` position of a
                    // `-> @Result<void, E>` (decision 74): `{ok, null}`.
                    try env.result_jump_lowerings.put(loc, .wrap_ok);
                }
            }
            // §1F F4F-T1 — inside `#[@future]`, a bare `return <t>;` is the
            // resolved-future shape. The transform wraps it in a
            // `__bp_future_resolved(<t>)` call; commonJS strips that back to
            // `return <t>;` (the `async function` machinery is the wrap).
            // Skip values that are already a `@Future` (passthrough — the
            // outer fn returns the inner future directly).
            if (r != null and inEffectContext(env, .future)) {
                const valIsFuture = blk: {
                    const vt = valPtr.?.getType().deref();
                    break :blk vt.* == .named and std.mem.eql(u8, vt.named.name, "Future");
                };
                if (!valIsFuture) {
                    try env.future_jump_lowerings.put(loc, .wrap_resolved);
                }
            }
            // C1 — unify the returned value with the body's return target.
            // A value that is already the wrapper (a `@Result` / `@Future`
            // passthrough, `try` / `catch` forms) is not unwrapped here.
            if (env.returnTarget) |target| {
                if (valPtr) |vp| {
                    const rv = r.?.*;
                    const passthrough = blk: {
                        if (rv == .branch and rv.branch.kind == .tryCatch) break :blk true;
                        if (rv == .jump and rv.jump.kind == .try_) break :blk true;
                        const vt = vp.getType().deref();
                        if (vt.* == .named and (env.throwContext == .result or inEffectContext(env, .future))) {
                            if (std.mem.eql(u8, vt.named.name, "Result") or std.mem.eql(u8, vt.named.name, "Future")) break :blk true;
                        }
                        break :blk false;
                    };
                    // A value that is already the declared wrapper (`return
                    // state(start)` in a `-> @Context<B, X>` hook) unifies with
                    // the whole declared return type.
                    const whole: ?*T.Type = blk: {
                        const w = env.returnWhole orelse break :blk null;
                        const wd = w.deref();
                        const vt = vp.getType().deref();
                        if (wd.* == .named and vt.* == .named and w != target and
                            std.mem.eql(u8, wd.named.name, vt.named.name)) break :blk w;
                        break :blk null;
                    };
                    if (whole) |w| {
                        try unifyAt(env, w, vp.getType(), rv.getLoc());
                    } else if (!passthrough and !behaviorCoercion(env, target, vp.getType())) {
                        try unifyAt(env, target, vp.getType(), rv.getLoc());
                    }
                } else if (env.returnBareIsVoid) {
                    try unifyAt(env, target, try env.namedType("void"), loc);
                }
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"return" = valPtr } } };
        },
        .throw_ => |e| {
            // R11-mirror (§2) — `throw Result.Error(<e>)` / `throw Result.Ok(<r>)`
            // inside a `#[@result]` body forbids the manual wrapping by §1.
            if (env.throwContext == .result) {
                if (e) |ev| {
                    if (resultVariantCallName(ev.*)) |variant| {
                        if (std.mem.eql(u8, variant, "Error")) {
                            env.lastError = TypeError.custom(
                                diagnostics.throw_must_be_bare_E ++
                                    ": a #[@result] fn must `throw` a value of type E; the @Result::Err wrapping is implicit.",
                                "Drop the `Result.Error(...)` wrapping — write `throw <e>;` directly.",
                            ).withLoc(loc);
                        } else {
                            env.lastError = TypeError.custom(
                                diagnostics.result_throw_type_mismatch ++
                                    ": a #[@result] fn raises E via `throw`; use `return` for the success variant.",
                                "If the value is the success payload, change `throw Result.Ok(<r>);` to `return <r>;`.",
                            ).withLoc(loc);
                        }
                        return error.TypeError;
                    }
                }
            }
            // RF2 (§1F / §2 R17) — `throw Future.rejected(<e>);` /
            // `throw Future.resolved(<t>);` inside a `#[@future]` body forbids
            // the manual wrapping. The auto-wrap rewrites bare `throw <e>;`
            // to `@Future.rejected(<e>)` at AST level.
            if (inEffectContext(env, .future)) {
                if (e) |ev| {
                    if (futureConstructorCallName(ev.*)) |ctor| {
                        if (std.mem.eql(u8, ctor, "rejected")) {
                            env.lastError = TypeError.custom(
                                diagnostics.future_throw_must_be_bare_E ++
                                    ": a #[@future] fn must `throw` a value of type E; the @Future.rejected wrapping is implicit.",
                                "Drop the `Future.rejected(...)` wrapping — write `throw <e>;` directly.",
                            ).withLoc(loc);
                        } else {
                            env.lastError = TypeError.custom(
                                diagnostics.future_throw_type_mismatch ++
                                    ": a #[@future] fn rejects E via `throw`; use `return` for the resolved variant.",
                                "If the value is the success payload, change `throw Future.resolved(<t>);` to `return <t>;`.",
                            ).withLoc(loc);
                        }
                        return error.TypeError;
                    }
                }
            }
            const valPtr: ?*TypedExpr = if (e) |ev| try makeTypedPtr(env, try inferExprTyped(env, ev.*)) else null;
            // Validate the thrown value against the enclosing fn's error type.
            switch (env.throwContext) {
                .result => |errType| {
                    if (valPtr) |vp| {
                        // Order matters: `errType` is the expected `E`, the thrown
                        // value is what we got — so unify(expected, got).
                        try unifyAt(env, errType, vp.getType(), loc);
                        // `throw e` in a `-> @Result<…>` fn produces the value
                        // `{error, E}` — the transform rewrites it to
                        // `return __bp_error(e)`.
                        try env.result_jump_lowerings.put(loc, .wrap_error);
                    }
                },
                .plain => {
                    env.lastError = TypeError.throwWithoutResult().withLoc(loc);
                    return error.TypeError;
                },
                .unchecked => {},
            }
            // §1F F4F-T1 — inside `#[@future]`, a bare `throw <e>;` is the
            // rejected-future shape. The transform rewrites it as
            // `return __bp_future_rejected(<e>);`; commonJS strips that back
            // to `throw <e>;` (the `async function` machinery turns the throw
            // into a rejected promise).
            if (e != null and inEffectContext(env, .future)) {
                try env.future_jump_lowerings.put(loc, .wrap_rejected);
            }
            // §1I F4I-tail — inside `#[@iterator]` / `#[@futureGenerator]`, a
            // `throw <e>;` lands in the iterator-error channel. The transform
            // rewrites it as `return @IteratorStep.Error(<e>);` so the
            // consumer can pattern-match on the step variant; the existing
            // enum codegen materialises the value.
            if (e != null and inEffectContext(env, .iterator)) {
                try env.iterator_jump_lowerings.put(loc, .wrap_error);
            }
            if (e != null and inEffectContext(env, .futureGenerator)) {
                try env.iterator_jump_lowerings.put(loc, .wrap_error);
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .throw_ = valPtr } } };
        },
        .try_ => |e| {
            const valPtr: ?*TypedExpr = if (e) |ev| try makeTypedPtr(env, try inferExprTyped(env, ev.*)) else null;
            const rawTy = if (valPtr) |vp| vp.getType() else try env.freshVar();
            const ty = try tryUnwrapOrError(env, rawTy, loc);
            // Decision 95 — bare `try` PROPAGATES: it returns the `Error` out of
            // the enclosing function, so the body needs an error channel, which
            // is `@Result` and everything that extends it. `#[@generator]` does
            // not (question 97 — `@Generator<T, R>` has no error channel) and a
            // plain `fn` does not either. `try … catch` is a different node
            // (`branch.tryCatch`): it supplies its own fallback, propagates
            // nothing and is not gated here. The check runs AFTER the operand
            // is known to be a `@Result`, so `try <non-result>` keeps its own,
            // more specific refusal.
            //
            // The gate reads `throwContext` for the same reason `throw` does: it
            // is `.plain` exactly where a declared return type carries no error
            // channel, and `.unchecked` in a body with no declared return type
            // (a lambda, a `test` block), which stays lenient.
            if (env.throwContext == .plain and !effectChain.grants(env.fnEffect, .try_)) {
                env.lastError = TypeError.custom(
                    try effectChain.refusal(env.arena, diagnostics.effect_try_without_fallible_channel, .try_, env.fnEffect),
                    "Use `try <expr> catch <fallback>`, which handles the error here and needs no channel, or give the enclosing fn one.",
                ).withLoc(loc);
                return error.TypeError;
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = ty, .kind = .{ .try_ = valPtr } } };
        },
        .@"break" => |b| {
            // Decision 105 — a bare `break` leaves the nearest loop, or ends
            // the generator scope when no loop encloses it; `break <value>`
            // emits the value and ends the nearest generator scope — an
            // annotated fn or an annotated `loop` — and needs one, unless it
            // is the value of a `comptime` block or a `case` arm's block
            // (decision 2). A label names an enclosing loop; the generator
            // scope's own label (a fn's signature label, an annotated loop's)
            // names it for `break :label <value>`.
            const ctx = env.starFn;
            const inGenerator = ctx != null and ctx.?.allowsYield;
            if (b.label) |lbl| {
                for (env.closedLabels) |outer| {
                    if (std.mem.eql(u8, outer, lbl)) {
                        env.lastError = TypeError.custom(
                            try std.fmt.allocPrint(env.arena, "{s}: `break :{s}` crosses the border of a `#[@{s}] loop` — its body is a closure and cannot leave a loop outside it", .{ diagnostics.generator_loop_closed_scope, lbl, ctx.?.effect.annotationName() }),
                            "End the annotated loop (`break`) and leave the outer loop after it.",
                        ).withLoc(loc);
                        return error.TypeError;
                    }
                }
                if (!env.hasLabel(lbl)) {
                    env.lastError = TypeError.custom(
                        diagnostics.break_label_unbound ++
                            ": `break :<label>` targets an unknown label",
                        "Label a loop (`for :name (…)`, `while :name (…)`, `loop :name {`) or a generator scope (`fn … -> @Generator<…> :name`, `#[@generator] loop :name {`).",
                    ).withLoc(loc);
                    return error.TypeError;
                }
            }
            if (b.value) |expr| {
                const targetsGenerator = inGenerator and (b.label == null or
                    (ctx.?.fnLabel != null and std.mem.eql(u8, b.label.?, ctx.?.fnLabel.?)));
                if (targetsGenerator) {
                    const typedPtr = try makeTypedPtr(env, try inferExprTyped(env, expr.*));
                    if (ctx.?.iterItem) |item| try unifyAt(env, typedPtr.getType(), item, loc);
                    return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"break" = .{ .label = b.label, .value = typedPtr } } } };
                }
                if (b.label == null and env.breakScope == .valueBlock) {
                    const typedPtr = try makeTypedPtr(env, try inferExprTyped(env, expr.*));
                    return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"break" = .{ .label = null, .value = typedPtr } } } };
                }
                env.lastError = TypeError.custom(
                    try generatorScopeRefusal(env, diagnostics.break_value_outside_generator, "`break <value>`"),
                    "`break <value>` emits the value and ends the generator; a loop is a statement and has no value. Collect in a `var`, or with `map` / `filter`; end a loop with a bare `break`.",
                ).withLoc(loc);
                return error.TypeError;
            }
            // A bare `break` at loop depth 0 ends the generator scope; with
            // no loop, no generator scope and no value block there is nothing
            // to leave.
            if (b.label == null and env.loopDepth == 0) {
                if (inGenerator) {
                    try env.iterator_jump_lowerings.put(loc, .wrap_done_void);
                } else if (env.breakScope != .valueBlock) {
                    env.lastError = TypeError.custom(
                        diagnostics.break_outside_loop ++ ": `break` outside a loop",
                        "A `break` leaves the nearest `for` / `while` / `loop`, or ends a generator scope.",
                    ).withLoc(loc);
                    return error.TypeError;
                }
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"break" = .{ .label = b.label, .value = null } } } };
        },
        .await_ => |e| {
            // R7, as decision 95 rewrites it — `await` belongs to `@Future`,
            // so every effect whose wrapper extends `@Future` answers it:
            // `#[@future]`, `#[@futureGenerator]` and `#[@context]`.
            if (env.starFn == null or !env.starFn.?.allowsAwait) {
                env.lastError = TypeError.custom(
                    try effectChain.refusal(env.arena, diagnostics.effect_await_without_future, .await_, env.fnEffect),
                    "Mark the enclosing fn `#[@future]` (`-> @Future<…>`), `#[@futureGenerator]` (`-> @FutureGenerator<…>`) or `#[@context]`.",
                ).withLoc(loc);
                return error.TypeError;
            }
            const valPtr = try makeTypedPtr(env, try inferExprTyped(env, e.*));
            const rawTy = valPtr.getType();
            // `await @Future<T>` yields `T`. A resolved non-`@Future` named type is
            // an error; an unresolved type variable stays lenient.
            const deref = rawTy.deref();
            if (deref.* == .named and !std.mem.eql(u8, deref.named.name, "Future")) {
                env.lastError = TypeError.custom(
                    "`await` expects a `@Future<_>` value",
                    null,
                ).withLoc(loc);
                return error.TypeError;
            }
            const ty = unwrapFutureType(rawTy) orelse rawTy;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = ty, .kind = .{ .await_ = valPtr } } };
        },
        .@"continue" => {
            if (env.loopDepth == 0) {
                env.lastError = TypeError.custom(
                    diagnostics.continue_outside_loop ++ ": `continue` outside a loop",
                    "`continue` starts the next round of the nearest `for` / `while` / `loop`.",
                ).withLoc(loc);
                return error.TypeError;
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .@"continue" } };
        },
        .yield => |y| {
            // Decision 105 — `yield` feeds the NEAREST generator scope, an
            // annotated fn or an annotated `loop`, through every unannotated
            // loop between them; there is no other target. R8 as decision 95
            // rewrites it: the scope is one whose wrapper the chain lets
            // `yield`, and a body without one — a plain `fn`, a `#[@future]`,
            // a `#[@result]` — refuses it naming the three annotations.
            const ctx = env.starFn orelse null;
            if (ctx == null or !ctx.?.allowsYield) {
                env.lastError = TypeError.custom(
                    try effectChain.refusal(env.arena, diagnostics.yield_without_generator, .yield_, env.fnEffect),
                    "A `yield` feeds the nearest generator scope: mark the fn `#[@generator]` (`-> @Generator<T>`) or write the loop as `#[@generator] loop { … }` (decision 105).",
                ).withLoc(loc);
                return error.TypeError;
            }
            // `yield :label` names the generator scope — the fn's signature
            // label or the annotated loop's — never a plain loop.
            if (y.label) |lbl| {
                const names_scope = if (ctx.?.fnLabel) |fl| std.mem.eql(u8, lbl, fl) else false;
                if (!names_scope) {
                    if (env.hasLabel(lbl)) {
                        env.lastError = TypeError.custom(
                            diagnostics.yield_label_not_generator ++ ": `yield :<label>` names a loop, and a `yield` feeds a generator scope",
                            "Label the scope it feeds: `fn … -> @Generator<T> :name` or `#[@generator] loop :name { … }`; an unlabelled `yield` feeds the nearest one.",
                        ).withLoc(loc);
                        return error.TypeError;
                    }
                    env.lastError = TypeError.custom(
                        diagnostics.yield_label_unbound ++
                            ": `yield` targets an unknown label",
                        "Label a generator fn (`fn … -> @Generator<T> :name`) or an annotated loop (`#[@generator] loop :name { … }`).",
                    ).withLoc(loc);
                    return error.TypeError;
                }
            }
            const typedPtr: ?*TypedExpr = if (y.value) |expr| try makeTypedPtr(env, try inferExprTyped(env, expr.*)) else null;
            if (ctx.?.iterItem) |item| {
                if (typedPtr) |vp| try unifyAt(env, vp.getType(), item, loc);
            }
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .yield = .{ .label = y.label, .value = typedPtr } } } };
        },
    };
}

/// Infer type for branch expressions (if and try-catch)
fn inferBranchExpr(env: *Env, b: ast.MakeExpr(.untyped, ast.BranchExprOf(.untyped)), loc: ast.Loc) InferError!TypedExpr {
    return switch (b.kind) {
        .if_ => |i| {
            const condTyped = try inferExprTyped(env, i.cond.*);
            const condPtr = try makeTypedPtr(env, condTyped);

            // Every name this condition narrows, and the type it takes on
            // each side of it. It is still ONE channel — `x is T`, a type-guard
            // call and the null test all write here — but it holds a LIST now:
            // `if (a != null && b != null)` narrows two names, and one slot
            // could only ever have narrowed the last of them.
            var narrowings: std.ArrayListUnmanaged(CondNarrowing) = .empty;
            defer narrowings.deinit(env.arena);

            if (i.binding) |binding_name| {
                // Null-check form: `if (x) { e -> ... }` — condition is optional, not bool.
                // Bind the unwrapped inner type to `binding_name`.
                const condTy = condTyped.getType().deref();
                const innerTy: *T.Type = switch (condTy.*) {
                    .named => |n| if (std.mem.eql(u8, n.name, "optional") and n.args.len == 1)
                        n.args[0]
                    else
                        try env.freshVar(),
                    else => try env.freshVar(),
                };
                try env.bind(binding_name, innerTy);
            } else {
                // Check for type guard call: `if (guardName(arg, ...))`
                // Narrow the argument's type in the then-branch.
                // Decision 8 §4 — `if (x is T)` narrows `x` to `T` inside the
                // branch. It is the same channel C5 built for the type-guard fn
                // form (`-> x is T`), which is why both write into
                // `narrowings` rather than growing a second narrowing
                // mechanism — and so does the null test below it.
                if (isNarrowingOf(i.cond.*)) |n| {
                    try narrowings.append(env.arena, .{ .name = n.name, .then_ = try resolveTypeRef(env, n.ref) });
                }
                // The null test: `if (x != null)` rebinds `x` to the `?T`'s
                // payload inside the branch, `if (x == null)` rebinds it in the
                // ELSE branch, and `&&` / `||` / `not` combine them. Before
                // this the body still saw a `?Record`, so a field read off it
                // was a fresh type variable and commonJS — which needs the
                // receiver's type to know `.length()` is a PROPERTY — emitted a
                // call on a number where erlang, dispatching dynamically,
                // happened to answer.
                try collectCondNarrowings(env, i.cond.*, &narrowings);
                if (i.cond.* == .call) {
                    const ci = i.cond.call.kind.call;
                    if (env.typeGuardFns.get(ci.callee)) |guardInfo| {
                        if (guardInfo.paramIndex < ci.args.len) {
                            const argExpr = ci.args[guardInfo.paramIndex].value.*;
                            if (argExpr == .identifier and argExpr.identifier.kind == .ident) {
                                const guardArgName = argExpr.identifier.kind.ident;
                                const argTyped = try inferExprTyped(env, argExpr);
                                const argTy = argTyped.getType().deref();
                                const narrowed: *T.Type = switch (argTy.*) {
                                    .named => |n| if (std.mem.eql(u8, n.name, "optional") and n.args.len == 1)
                                        n.args[0]
                                    else if (std.mem.eql(u8, n.name, guardInfo.narrowedTypeName))
                                        argTy
                                    else
                                        try env.namedType(guardInfo.narrowedTypeName),
                                    else => try env.namedType(guardInfo.narrowedTypeName),
                                };
                                try narrowings.append(env.arena, .{ .name = guardArgName, .then_ = narrowed });
                            }
                        }
                    }
                }
                try unifyAt(env, try env.namedType("bool"), condTyped.getType(), loc);
            }

            // Narrow for the then-branch, restore, then narrow for the else.
            var snapshots: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
            defer snapshots.deinit(env.arena);
            for (narrowings.items) |n| {
                if (n.then_) |ty| try bindNarrowed(env, n.name, ty, &snapshots);
            }

            const thenTyped = try inferStmtsTyped(env, i.then_);

            try restorePatternBindings(env, snapshots.items);
            snapshots.clearAndFree(env.arena);

            const elseTyped = if (i.else_) |els| blk: {
                for (narrowings.items) |n| {
                    if (n.else_) |ty| try bindNarrowed(env, n.name, ty, &snapshots);
                }
                const typed = try inferStmtsTyped(env, els);
                try restorePatternBindings(env, snapshots.items);
                snapshots.clearAndFree(env.arena);
                break :blk typed;
            } else null;

            const bodyType = if (thenTyped.len > 0) thenTyped[thenTyped.len - 1].expr.getType() else try env.namedType("void");
            const elseType = if (elseTyped) |els| blk: {
                if (els.len > 0) break :blk els[els.len - 1].expr.getType();
                break :blk try env.namedType("void");
            } else try env.namedType("void");

            // Decision 2 — a block is not a value, so the branches of an `if`
            // only have to agree when the `if` is used as one. A branch whose
            // last statement is a STATEMENT (an assignment, a `val`/`var`
            // binding, a loop) has no value to agree with, and unifying the
            // two used to red a legitimate shape:
            //
            //     if (pred(x)) { out = out.append([x]); } else { taking = false; }
            //
            // — "expected array, got bool". A library in this repository
            // writes it in a `takeWhile` / `skipWhile`, and so does a plain
            // fn of the same shape. Only the row that removes
            // block-as-value outright can delete the unification entirely; this
            // narrows it to the branches that do produce a value.
            //
            // Decision 8 §3.2 — when both branches DO produce a value and the
            // two disagree, that is not an error: the `if` is their union, the
            // same answer `caseTypeFromArms` already gives a `case`. Branches
            // that agree still unify, so a branch pins the other's type
            // variables exactly as before.
            var ifType = bodyType;
            if (elseTyped != null and stmtsYieldValue(thenTyped) and stmtsYieldValue(elseTyped.?)) {
                if (caseArmTypesAgree(bodyType, elseType)) {
                    try unify(env, bodyType, elseType);
                } else {
                    ifType = try unionOf(env, &.{ bodyType, elseType });
                }
            }
            return TypedExpr{ .branch = .{ .loc = loc, .type_ = ifType, .kind = .{ .if_ = .{
                .cond = condPtr,
                .binding = i.binding,
                .then_ = thenTyped,
                .else_ = elseTyped,
            } } } };
        },

        .tryCatch => |tc| {
            const exprTyped = try inferExprTyped(env, tc.expr.*);
            const exprPtr = try makeTypedPtr(env, exprTyped);
            const handlerTyped = try inferExprTyped(env, tc.handler.*);
            const handlerPtr = try makeTypedPtr(env, handlerTyped);
            const rawTy = exprTyped.getType();
            const resultTy = try tryUnwrapOrError(env, rawTy, loc);
            const handlerTy = handlerTyped.getType().deref();
            const effectiveTy = switch (handlerTy.*) {
                .func => |f| f.ret,
                else => handlerTyped.getType(),
            };
            if (!effectiveTy.isNamed("void")) {
                try unify(env, resultTy, effectiveTy);
            }
            return TypedExpr{ .branch = .{ .loc = loc, .type_ = resultTy, .kind = .{ .tryCatch = .{
                .expr = exprPtr,
                .handler = handlerPtr,
            } } } };
        },
    };
}

/// Decision 105 — the three loop keywords are statements typed `void`; the
/// annotated `loop` is an expression worth its wrapper (`inferGeneratorLoop`).
fn inferLoopExpr(env: *Env, lp: ast.LoopExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    if (lp.generator) |eff| return inferGeneratorLoop(env, lp, eff, loc);
    const iterTyped = try inferExprTyped(env, lp.iter.*);
    const iterPtr = try makeTypedPtr(env, iterTyped);
    const iterTy = iterTyped.getType().deref();

    // The `for` parameter binds the ITEM of what is iterated: the element of
    // an array, the integer of a range, the `T` of a generator. Nothing else
    // is iterable, and a `bool` is a `while`. An unresolved type variable
    // stays lenient, as every effect check does.
    var itemTy: ?*T.Type = null;
    if (lp.condition) {
        // `while (cond) { … }` / `loop { … }` — the condition is a `bool`.
        try unifyAt(env, try env.namedType("bool"), iterTyped.getType(), loc);
    } else if (lp.awaitLoop) {
        // `for await (gen) { x -> … }` — an `@FutureGenerator<T, E>` in a body
        // that grants `await`; the loop param binds `T`.
        if (env.starFn == null or !env.starFn.?.allowsAwait) {
            env.lastError = TypeError.custom(
                try effectChain.refusal(env.arena, diagnostics.effect_await_without_future, .await_, env.fnEffect),
                "`for await` suspends at every item: mark the enclosing fn `#[@future]` (`-> @Future<…>`) or `#[@futureGenerator]`, or write the loop as a `#[@futureGenerator] loop { … }`.",
            ).withLoc(loc);
            return error.TypeError;
        }
        if (iterTy.* == .named and std.mem.eql(u8, iterTy.named.name, "FutureGenerator") and iterTy.named.args.len >= 1) {
            itemTy = iterTy.named.args[0];
        } else if (iterTy.* != .typeVar) {
            env.lastError = TypeError.custom(
                diagnostics.for_await_expects_future_generator ++ ": `for await` expects an `@FutureGenerator<T, E>` value",
                "A `@Generator<T>` or a `@ResultGenerator<T, E>` is iterated by `for (gen) { x -> … }`; only a `@FutureGenerator` suspends between items.",
            ).withLoc(loc);
            return error.TypeError;
        }
    } else if (iterTy.isNamed("bool")) {
        env.lastError = TypeError.custom(
            diagnostics.for_over_condition ++ ": `for` iterates a collection, a range or a generator — a condition is a `while`",
            "Write `while (cond) { … }`; it repeats while the condition holds and binds nothing.",
        ).withLoc(loc);
        return error.TypeError;
    } else if (iterTy.* == .named) {
        const n = iterTy.named;
        if (std.mem.eql(u8, n.name, "Range")) {
            // `for (a..b) { i -> … }` — a range counts in integers.
            itemTy = try env.namedType("i32");
        } else if (n.args.len >= 1 and std.mem.eql(u8, n.name, "array")) {
            itemTy = n.args[0];
        } else if (n.args.len >= 1 and effectChain.grants(effectOfWrapper(n.name), .yield_)) {
            // A generator (decision 103): `@Generator<T>` in any body; one that
            // implements `@Result` is an implicit `try` at every item and needs
            // a body that grants `try`; one that implements `@Future` needs
            // `for await`.
            if (effectChain.wrapperImplements(n.name, "Future")) {
                env.lastError = TypeError.custom(
                    diagnostics.for_over_future_generator ++ ": a `@FutureGenerator` suspends between items — iterate it with `for await`",
                    "`for await (gen) { x -> … }` in a body that grants `await`.",
                ).withLoc(loc);
                return error.TypeError;
            }
            // The same gate bare `try` answers to: a body with a declared
            // return type and no `try`-granting effect refuses; a `test`
            // block, a lambda and a fn without a return type stay lenient.
            if (effectChain.wrapperImplements(n.name, "Result") and env.throwContext == .plain and !effectChain.grants(env.fnEffect, .try_)) {
                const msg = try std.fmt.allocPrint(
                    env.arena,
                    "{s}: `for` over a `@{s}` is an implicit `try` at every item, and this body grants no `try`",
                    .{ diagnostics.for_over_fallible_generator, n.name },
                );
                env.lastError = TypeError.custom(
                    msg,
                    try effectChain.refusal(env.arena, diagnostics.for_over_fallible_generator, .try_, env.fnEffect),
                ).withLoc(loc);
                return error.TypeError;
            }
            itemTy = n.args[0];
        }
    }
    for (lp.params) |p| try env.bind(p, itemTy orelse try env.freshVar());

    // The loop's own label is a `break :label` / `continue :label` target for
    // its body; the body is one loop deeper and a bare `break` leaves it.
    const prevLabelsLen = env.labelStack.items.len;
    defer env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    if (lp.label) |lbl| try env.labelStack.append(env.arena, lbl);
    const prevBreakScope = env.breakScope;
    env.breakScope = .loop;
    env.loopDepth += 1;
    defer {
        env.loopDepth -= 1;
        env.breakScope = prevBreakScope;
    }
    const typedBody = try inferStmtsTyped(env, lp.body);
    return TypedExpr{ .loop = .{
        .loc = loc,
        .type_ = try env.namedType("void"),
        .keyword = lp.keyword,
        .generator = null,
        .iter = iterPtr,
        .indexRange = null,
        .params = lp.params,
        .paramsLoc = lp.paramsLoc,
        .condition = lp.condition,
        .body = typedBody,
        .awaitLoop = lp.awaitLoop,
        .label = lp.label,
    } };
}

/// The effect whose return wrapper is `name`, or null — the chain is asked
/// about wrappers through their effect, and a name that is no wrapper grants
/// nothing.
fn effectOfWrapper(name: []const u8) ?ast.EffectKind {
    for (ast.EffectKind.all) |e| {
        if (std.mem.eql(u8, e.returnWrapper(), name)) return e;
    }
    return null;
}

/// The wrapper an annotated loop is worth: `T` fresh (the type of its `yield`
/// / `break v`), `E` fresh when the wrapper implements `@Result` (the type of
/// its `throw`), and the wrapper's remaining defaults filled as a written
/// `@Wrapper<T>` fills them.
fn generatorLoopWrapper(env: *Env, eff: ast.EffectKind) InferError!*T.Type {
    const name = eff.returnWrapper();
    var args: std.ArrayListUnmanaged(*T.Type) = .empty;
    try args.append(env.arena, try env.freshVar());
    if (effectChain.wrapperImplements(name, "Result")) try args.append(env.arena, try env.freshVar());
    if (builtinDefaultFilledArgs(env, name, args.items.len)) |names| {
        for (names[args.items.len..]) |n| try args.append(env.arena, try env.namedType(n));
    }
    return env.namedTypeArgs(name, args.items);
}

/// Decision 105 — `#[@generator] loop { … }`: the body is a generator scope
/// with exactly the annotation's capabilities, worth the annotation's wrapper.
/// The scope is closed: the enclosing fn's effect, labels, `use` anchor and
/// throw channel are all replaced for the body and restored after it, so a
/// `use` or an `await` the annotation does not grant is refused inside it
/// whatever the fn grants, and a `break :outer` / `continue :outer` naming an
/// enclosing loop is refused as crossing the border. The loop itself is one
/// loop deep for its body: a bare `break` ends it (and so the generator), a
/// `continue` starts its next round.
fn inferGeneratorLoop(env: *Env, lp: ast.LoopExprOf(.untyped), eff: ast.EffectKind, loc: ast.Loc) InferError!TypedExpr {
    const wrapper = try generatorLoopWrapper(env, eff);
    const iterTyped = try inferExprTyped(env, lp.iter.*);
    const iterPtr = try makeTypedPtr(env, iterTyped);

    const prevStarFn = env.starFn;
    const prevFnEffect = env.fnEffect;
    const prevThrowCtx = env.throwContext;
    const prevUseAnchor = env.useAnchor;
    const prevInContextFn = env.inContextFn;
    const prevLoopDepth = env.loopDepth;
    const prevBreakScope = env.breakScope;
    const prevClosedLabels = env.closedLabels;
    const prevLabels = try env.arena.dupe([]const u8, env.labelStack.items);
    defer {
        env.starFn = prevStarFn;
        env.fnEffect = prevFnEffect;
        env.throwContext = prevThrowCtx;
        env.useAnchor = prevUseAnchor;
        env.inContextFn = prevInContextFn;
        env.loopDepth = prevLoopDepth;
        env.breakScope = prevBreakScope;
        env.closedLabels = prevClosedLabels;
        env.labelStack.shrinkRetainingCapacity(0);
        env.labelStack.appendSlice(env.arena, prevLabels) catch {};
        env.generatorLoopDepth -= 1;
    }
    env.closedLabels = prevLabels;
    env.labelStack.shrinkRetainingCapacity(0);
    if (lp.label) |lbl| try env.labelStack.append(env.arena, lbl);
    env.starFn = starCtxFromEffect(eff, wrapper, lp.label);
    env.fnEffect = eff;
    // `throw` lands in the wrapper's error channel when it has one (the
    // transform's auto-wrap, as for the annotated fn); a wrapper without one
    // refuses it at the site.
    env.throwContext = if (effectChain.grants(eff, .try_)) .unchecked else .plain;
    env.useAnchor = null;
    env.inContextFn = false;
    env.loopDepth = 1;
    env.breakScope = .loop;
    env.generatorLoopDepth += 1;

    const typedBody = try inferStmtsTyped(env, lp.body);
    return TypedExpr{ .loop = .{
        .loc = loc,
        .type_ = wrapper,
        .keyword = lp.keyword,
        .generator = eff,
        .iter = iterPtr,
        .indexRange = null,
        .params = lp.params,
        .paramsLoc = lp.paramsLoc,
        .condition = true,
        .body = typedBody,
        .awaitLoop = false,
        .label = lp.label,
    } };
}
/// Infer type for binding expressions (variable declarations and assignments)
fn inferBindingExpr(env: *Env, b: ast.BindingExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (b.kind) {
        .localBind => |lb| {
            // 01 R8 — a refusal in the annotation needs a location; the
            // binding carries none of its own for the annotation, so an
            // unlocated one reds at the `val`. (Setting `typeRefLoc` instead
            // would also enter every unresolved name into C10's pending list.)
            const annType: ?*T.Type = if (lb.typeAnnotation) |ann|
                resolveTypeRef(env, ann) catch |err| return locateTypeRefError(env, err, loc)
            else
                null;
            // Feed a `fn(...) -> ...` annotation into a lambda RHS so its
            // params are typed from context (mirrors `inferDeclTyped`).
            const valTyped = if (annType != null and lb.value.* == .function)
                try inferFunctionExprExpected(env, lb.value.function, lb.value.function.loc, annType, false)
            else
                // 00 · 01-checker — the annotation is this position's expected
                // type (`val t: Token = .Color.Red.500;`).
                try inferExprTypedExpecting(env, lb.value.*, annType);
            const valPtr = try makeTypedPtr(env, valTyped);
            if (annType) |at| try unifyAt(env, at, valTyped.getType(), lb.value.getLoc());
            // The annotation is the DECLARED type — bind it, not the RHS type
            // (`val head: ?i32 = 5;` must bind `?i32`).
            const bindTy = annType orelse valTyped.getType();
            try noteTypeValue(env, lb.name, lb.value.*, annType == null and !lb.mutable);
            if (lb.mutable) try env.bind(lb.name, bindTy) else try env.bindVal(lb.name, bindTy);
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = bindTy, .kind = .{ .localBind = .{
                .name = lb.name,
                .value = valPtr,
                .mutable = lb.mutable,
                .typeAnnotation = lb.typeAnnotation,
            } } } };
        },

        .assign => |a| {
            const valTyped = try inferExprTyped(env, a.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);

            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .assign = .{
                .target = switch (a.target) {
                    .name => |name| blk: {
                        if (env.lookup(name)) |ty| {
                            try refuseValAssign(env, name, loc);
                            try unifyAt(env, ty, valTyped.getType(), loc);
                        } else {
                            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
                            return error.TypeError;
                        }
                        break :blk .{ .name = name };
                    },
                    .fieldAccess => |fa| blk: {
                        const recvTyped = try inferExprTyped(env, fa.receiver.*);
                        try refuseRecordFieldAssign(env, fa.receiver.*, recvTyped.getType(), fa.field, loc);
                        const recvPtr = try makeTypedPtr(env, recvTyped);
                        break :blk .{ .fieldAccess = .{ .receiver = recvPtr, .field = fa.field } };
                    },
                },
                .op = a.op,
                .value = valPtr,
            } } } };
        },

        .localBindDestruct => |lb| {
            const valTyped = try inferExprTyped(env, lb.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            // Destructuring a hook (`val {v, s} = use state(0)`) is lenient: the
            // hook's Return type `R` need not be a record, so unknown fields bind
            // to fresh type vars rather than triggering a `notARecord` error.
            if (isUseHookValue(lb.value)) {
                try bindUseDestructure(env, lb.pattern, valTyped.getType(), loc);
                return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .localBindDestruct = .{
                    .pattern = lb.pattern,
                    .value = valPtr,
                    .mutable = lb.mutable,
                } } } };
            }
            // Bind destructured names into the environment.
            const derefedTy = valTyped.getType().deref();
            switch (lb.pattern) {
                .names => |n| {
                    const typeName: []const u8 = switch (derefedTy.*) {
                        .named => |nm| nm.name,
                        else => "",
                    };
                    const maybeDef = env.typeDefs.get(typeName);
                    // For concrete named types that are not records/structs, reject destructuring.
                    if (maybeDef == null and typeName.len > 0 and derefedTy.* == .named) {
                        env.lastError = TypeError.notARecord(typeName).withLoc(loc);
                        return error.TypeError;
                    }
                    for (n.fields) |fld| {
                        const fieldTy = if (maybeDef) |td|
                            if (td.findField(fld.field_name)) |f| f.type_ else try env.freshVar()
                        else
                            try env.freshVar();
                        try env.bind(fld.bind_name, fieldTy);
                    }
                },
                .tuple_ => |t| {
                    const tupleArgs: []*T.Type = switch (derefedTy.*) {
                        .named => |n| if (std.mem.eql(u8, n.name, "tuple")) n.args else &.{},
                        else => &.{},
                    };
                    for (t, 0..) |nm, i| {
                        const elemTy = if (i < tupleArgs.len) tupleArgs[i] else try env.freshVar();
                        try env.bind(nm, elemTy);
                    }
                },
                // 01 R5 — `val Circle(r) = s;` / `val [..rest] = xs;` bind
                // through the walk a `case` arm uses, typed by the subject.
                .list, .ctor => |pat| try bindDestructPattern(env, pat, valTyped.getType(), lb.mutable, loc),
            }
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .localBindDestruct = .{
                .pattern = lb.pattern,
                .value = valPtr,
                .mutable = lb.mutable,
            } } } };
        },
    };
}

/// 01 R5 — a pattern in binding position: `val Circle(r) = s;`,
/// `val Person(name, age) = p;`, `val [..rest] = xs;`.
///
/// The bare form has no failure path of its own, so it is legal only where the
/// pattern matches **every** value of the subject's type: a one-variant `type`,
/// a record's own constructor, a list pattern that is only a spread. Anything
/// that can fail to match is refused at the binding (`refutable-val-pattern`),
/// naming the two forms that say what a mismatch does — `val assert <Pattern>
/// = e;` (fatal) and `case`. Nothing is left for a backend to decide: every
/// program that checks destructures without a test.
///
/// The names land in the enclosing scope — the snapshots the walk collects
/// are dropped, as `val assert` does — and a `val` binds them as `val`s.
fn bindDestructPattern(env: *Env, pattern: ast.Pattern, subjectType: *T.Type, mutable: bool, loc: ast.Loc) InferError!void {
    var snapshots: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
    defer snapshots.deinit(env.arena);
    const st = subjectType.deref();
    const covers: bool = switch (pattern) {
        .list => |lst| lst.elems.len == 0 and lst.spread != null and
            st.* == .named and std.mem.eql(u8, st.named.name, "array"),
        .variant => |v| blk: {
            if (v.shape != .variant or st.* != .named) break :blk false;
            const bare = bareVariantName(v.name);
            const td = env.lookupTypeDef(st.named.name) orelse break :blk false;
            switch (td) {
                .enum_ => |en| {
                    if (en.variants.len != 1 or !std.mem.eql(u8, en.variants[0].name, bare)) break :blk false;
                    if (!try variantPayloadIrrefutable(env, subjectType, v.name, v.payload)) break :blk false;
                    try bindPatternNamesForSubject(env, pattern, subjectType, &snapshots);
                    break :blk true;
                },
                .record => |rec| {
                    if (!std.mem.eql(u8, rec.name, bare) or v.payload != .literals) break :blk false;
                    const args = v.payload.literals;
                    if (args.len > rec.fields.len or (args.len < rec.fields.len and !v.rest)) break :blk false;
                    for (args, 0..) |a, i| {
                        // A generic record's field types are its declaration's
                        // cells; the subject's instantiation is not read here.
                        const fieldTy = if (rec.genericParams.len == 0) rec.fields[i].type_ else try env.freshVar();
                        if (!try patternIsIrrefutable(env, a, fieldTy)) break :blk false;
                        try bindPatternNamesForSubject(env, a, fieldTy, &snapshots);
                    }
                    break :blk true;
                },
                .struct_ => break :blk false,
            }
        },
        else => false,
    };
    if (!covers) {
        const msg = try std.fmt.allocPrint(
            env.arena,
            "{s}: `val <Pattern> = e;` needs a pattern that matches every value of `{s}`, and this one can fail",
            .{ diagnostics.refutable_val_pattern, try snapshotMod.typeNameOf(env.arena, subjectType) },
        );
        env.lastError = TypeError.custom(
            msg,
            "write `val assert <Pattern> = e;` (a mismatch is a fatal assert) or a `case` that says what a mismatch does",
        ).withLoc(loc);
        return error.TypeError;
    }
    if (!mutable) {
        for (snapshots.items) |sn| {
            if (env.lookup(sn.name)) |ty| try env.bindVal(sn.name, ty);
        }
    }
}

/// `.Circle(…)` — a call chained onto a leading-dot head.
fn isLeadingDotCall(c: ast.CallExprOf(.untyped)) bool {
    if (c.kind != .call) return false;
    const ce = c.kind.call.calleeExpr orelse return false;
    return ce.* == .identifier and ce.identifier.kind == .dotIdent;
}

/// The name of the enum the expected type names, when it declares a variant
/// called `variant` (front 15 handover, `.Circle(radius: 1)`).
fn expectedEnumDeclaring(env: *Env, variant: []const u8) ?[]const u8 {
    const exp = env.expectedType orelse return null;
    const d = exp.deref();
    if (d.* != .named) return null;
    const td = env.lookupTypeDef(d.named.name) orelse return null;
    if (td != .enum_) return null;
    for (td.enum_.variants) |v| {
        if (std.mem.eql(u8, v.name, variant)) return d.named.name;
    }
    return null;
}

/// 01 R8 — give an annotation's unlocated error the binding's location.
fn locateTypeRefError(env: *Env, err: InferError, loc: ast.Loc) InferError {
    if (env.lastError) |*e| {
        if (e.loc == null) e.loc = loc;
    }
    return err;
}

/// 01 R8 — record whether `val name = value` binds a TYPE: `value` is a name
/// that is itself a type (a primitive, a declared `type`/`behavior`, an
/// imported constructor, or another such `val`). Checked before `name` is
/// bound, so `val T = T;` cannot vouch for itself. A binding that is not one
/// clears the mark, so a value shadowing a type alias is a value.
fn noteTypeValue(env: *Env, name: []const u8, value: ast.Expr, eligible: bool) InferError!void {
    const isType = eligible and blk: {
        if (value != .identifier or value.identifier.kind != .ident) break :blk false;
        const n = value.identifier.kind.ident;
        if (env.typeDefs.contains(n) or env.assocInterfaceDecls.contains(n) or env.typeValueNames.contains(n)) break :blk true;
        const ty = env.lookup(n) orelse break :blk false;
        const d = ty.deref();
        if (d.* == .func and d.func.ret.isNamed(n)) break :blk true;
        break :blk d.isNamed(n);
    };
    if (isType) try env.typeValueNames.put(name, {}) else _ = env.typeValueNames.remove(name);
}

fn containsStr(haystack: []const []const u8, needle: []const u8) bool {
    for (haystack) |s| if (std.mem.eql(u8, s, needle)) return true;
    return false;
}

/// The nominal type name of `ty`, or null if `ty` is not a named type.
fn nominalName(ty: *T.Type) ?[]const u8 {
    const d = ty.deref();
    return switch (d.*) {
        .named => |n| n.name,
        else => null,
    };
}

/// C-04 (01 step 7) — the callee's parameters AS WRITTEN, for a call whose
/// arity is about to be judged. A `T.func` carries no `default` expressions, so
/// this is the only thing that can tell an omitted trailing default (N1) from a
/// missing required argument (N2). `null` when the declaration is not reachable
/// from here — the arity check then stays exactly what it was.
fn calleeParams(env: *Env, callee: []const u8) ?[]const ast.Param {
    if (env.fnParams.get(callee)) |ps| return ps;
    if (env.ctorParams.get(callee)) |ps| return ps;
    if (env.stdlibFnDecls.get(callee)) |fd| return fd.params;
    return null;
}

/// 00 · 01-checker — which parameter each ARGUMENT of a call lands in, when
/// that is not simply its own index.
///
/// A label claims the parameter it names (C-04), so `f(y: <path>)` against
/// `fn f(x: i32 = 0, y: Token)` writes the SECOND parameter from its FIRST
/// argument. `planDefaultFill` is the one thing that knows that mapping, so
/// this inverts its plan rather than working a second one out — the two could
/// then disagree, and the expectation would name the wrong enum.
///
/// `null` is the ordinary answer and means "argument `i` is parameter `i`":
/// every call that writes its arguments positionally, which is nearly all of
/// them, allocates nothing here. A returned slice carries a parameter index
/// per argument, or `params.len` for an argument whose parameter is not
/// knowable — a full-arity labelled call, which the arity arm below zips
/// positionally and which a reordered label would not survive either. Reading
/// no expectation is right there: a wrong one would pick an enum.
fn argumentParamSlots(
    env: *Env,
    params: []const ast.Param,
    args: []const ast.CallArg,
) InferError!?[]const usize {
    var labelled = false;
    for (args) |a| {
        if (a.label != null) {
            labelled = true;
            break;
        }
    }
    if (!labelled) return null;

    const labels = try env.arena.alloc(?[]const u8, args.len);
    for (args, 0..) |a, i| labels[i] = a.label;
    const unknown = try env.arena.alloc(usize, args.len);
    @memset(unknown, params.len);
    const planned = envMod.planDefaultFill(env.arena, params, labels) catch return unknown;
    const fill = planned orelse return unknown;

    const slots = try env.arena.alloc(usize, args.len);
    @memset(slots, params.len);
    for (fill.slots, 0..) |slot, pi| {
        const ai = slot orelse continue;
        if (ai < slots.len) slots[ai] = pi;
    }
    return slots;
}

/// C-04 — plan the fill for a short call and record it under the call's loc for
/// `transform.zig`. Answers the plan, or `null` when the call cannot be filled:
/// that is N2, and the caller then raises the arity error it always raised.
fn recordDefaultFill(
    env: *Env,
    loc: ast.Loc,
    params: []const ast.Param,
    typedArgs: []const ast.CallArgOf(.typed),
) InferError!?envMod.DefaultFill {
    const labels = try env.arena.alloc(?[]const u8, typedArgs.len);
    for (typedArgs, 0..) |ta, i| labels[i] = ta.label;
    const planned = envMod.planDefaultFill(env.arena, params, labels) catch |e| switch (e) {
        error.CannotFill => return null,
        else => |rest| return rest,
    };
    const fill = planned orelse return null;
    try env.defaultInjections.put(loc, fill);
    return fill;
}

/// C-04 — unify a filled call's arguments with the parameters they actually
/// landed in. `P(y: 2)` against `type P(x: i32 = 0, y: i32)` puts its one
/// argument in the SECOND slot; zipping positionally would check it against `x`.
fn unifyFilledArgs(
    env: *Env,
    fill: envMod.DefaultFill,
    paramTypes: []const *T.Type,
    typedArgs: []ast.CallArgOf(.typed),
) InferError!void {
    for (fill.slots, 0..) |slot, pi| {
        const ai = slot orelse continue;
        if (pi >= paramTypes.len) continue;
        try unifyArgument(env, paramTypes[pi], typedArgs[ai].value.getType(), typedArgs[ai].value.getLoc());
    }
}

/// Build a typed method-call node, preserving the surface `recv.callee(args)`
/// shape (`recvPtr` is the typed receiver expression). External dispatch
/// (rewriting to `Sym.callee(recv, args)`) is recorded separately in
/// `env.dispatchRewrites` and applied by the transform pass.
fn makeMethodCall(
    env: *Env,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!TypedExpr {
    // C-04 / N1 — an instance call may omit an argument whose parameter
    // declares a default. Inference never arity-checked this shape, so there is
    // no error to keep honest here; what was missing is the fill, and without it
    // `b.bump()` reached node as `bump()` and answered `NaN`.
    if (typedTrailing.len == 0) {
        if (recvPtr) |rp| if (nominalName(rp.getType())) |tn| {
            if (env.getInherentMethodParams(tn, callee)) |declared| {
                if (declared.len > 0 and std.mem.eql(u8, declared[0].name, "self")) {
                    _ = try recordDefaultFill(env, loc, declared[1..], typedArgs);
                }
            }
        };
    }
    const retType = try methodCallReturnType(env, recvPtr, callee, typedArgs, typedTrailing, loc);
    return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Recover the return type of an inherent-method call `recv.callee(args)` from
/// the registered signature. The signature's type-level generics (the record's
/// `<T>` cells, `Self`, method generics) are instantiated fresh per call site;
/// the self param is unified with the receiver type and the remaining params
/// with the arguments, propagating concrete types into the return. Falls back
/// to a fresh var when no signature is registered (extension dispatch, etc.).
fn methodCallReturnType(
    env: *Env,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!*T.Type {
    const recv = recvPtr orelse return env.freshVar();
    const recvType = recv.getType();
    const typeName = nominalName(recvType) orelse return env.freshVar();
    const sigRaw = env.getInherentMethodType(typeName, callee) orelse return env.freshVar();

    // Fresh per-call-site copy so the shared registration cells never collapse.
    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    const sig = try instantiateType(env, sigRaw, &seen, .allVars);
    const fn_ = sig.deref();
    if (fn_.* != .func or fn_.func.params.len == 0) return env.freshVar();

    // params[0] is `self` — bind the type's generics to the receiver instance.
    try unifyAt(env, fn_.func.params[0], recvType, loc);
    // Unify positional args when the (self-excluded) arity matches and there
    // are no trailing lambdas (whose value type isn't available here). The
    // self-unification alone already propagates the receiver's type args into
    // the return type; arg unification refines method-generic params.
    const rest = fn_.func.params[1..];
    if (typedTrailing.len == 0 and rest.len == typedArgs.len) {
        for (typedArgs, rest) |ta, p| {
            try unifyAt(env, p, ta.value.getType(), ta.value.getLoc());
        }
    } else if (typedTrailing.len == 0) {
        // C-04 — a short call whose omitted parameters take their declared
        // defaults: unify each argument with the parameter it landed in.
        if (env.defaultInjections.get(loc)) |fill| try unifyFilledArgs(env, fill, rest, typedArgs);
    }
    return fn_.func.ret;
}

/// Decision 62 — the return type of a **type-qualified** call to one of a type's
/// own methods (`Counter.zero()`, and the explicit-receiver spelling of an
/// instance method, `Counter.bump(c)`). Null when the type declares no such
/// method, or declares it without a return-type annotation — in which case the
/// caller's fresh-var fallback still stands, exactly as it does for the instance
/// form (`registerInherentMethodTypes` only stores an annotated signature).
///
/// The signature is instantiated fresh per call site, like
/// `methodCallReturnType`, so the type's shared generic cells never collapse
/// across two calls. Unlike that function there is no receiver value to unify
/// `self` against: every declared parameter lines up with an argument, so the
/// arity must match exactly for the signature to be read at all.
fn associatedCallReturnType(
    env: *Env,
    typeName: []const u8,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
) InferError!?*T.Type {
    if (!env.hasInherentMethod(typeName, callee)) return null;
    const sigRaw = env.getInherentMethodType(typeName, callee) orelse return null;

    var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
    defer seen.deinit();
    const sig = try instantiateType(env, sigRaw, &seen, .allVars);
    const fn_ = sig.deref();
    if (fn_.* != .func) return null;
    // A trailing lambda's value type is not available here, and a mismatched
    // arity is the plain-call path's diagnostic, not this one's — leave both to
    // the fallback rather than unify against the wrong slots.
    if (typedTrailing.len > 0 or fn_.func.params.len != typedArgs.len) return null;
    for (typedArgs, fn_.func.params) |ta, p| {
        try unifyAt(env, p, ta.value.getType(), ta.value.getLoc());
    }
    return fn_.func.ret;
}

/// Resolve a builtin `result` namespace qualified call:
/// `result.map(r, f)` / `result.then(r, f)` / `result.unwrap(r, fallback)` /
/// `result.isOk(r)` / `result.isError(r)`. The subject `@Result<R, E>` value
/// arrives as the first positional argument. Records a `qualified`
/// MethodLowering at `loc` so the transform rewrites to the same
/// `__bp_result_<op>(args…)` builtin the method form uses — every backend
/// lowers it inline (no module emitted, no import required).
fn inferResultNamespaceCall(
    env: *Env,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!TypedExpr {
    const op: envMod.MethodLowering.Op = blk: {
        if (std.mem.eql(u8, callee, "map")) break :blk .map;
        if (std.mem.eql(u8, callee, "then")) break :blk .flatMap;
        if (std.mem.eql(u8, callee, "unwrap")) break :blk .unwrapOr;
        if (std.mem.eql(u8, callee, "isOk")) break :blk .isOk;
        if (std.mem.eql(u8, callee, "isError")) break :blk .isError;
        env.lastError = TypeError.custom(
            "unknown `result` namespace function",
            "Available: map, then, unwrap, isOk, isError.",
        ).withLoc(loc);
        return error.TypeError;
    };

    const wantArity: usize = switch (op) {
        .map, .flatMap, .unwrapOr => 2,
        .isOk, .isError => 1,
    };
    const total = typedArgs.len + typedTrailing.len;
    if (total != wantArity) {
        env.lastError = TypeError.arityMismatch(callee, wantArity, total).withLoc(loc);
        return error.TypeError;
    }

    // The subject `@Result<R, E>` is the first positional argument.
    const okTy = try env.freshVar();
    const errTy = try env.freshVar();
    const subjectShape = try env.namedTypeArgs("Result", &.{ okTy, errTy });
    try unifyAt(env, subjectShape, typedArgs[0].value.getType(), typedArgs[0].value.getLoc());

    const arg1: ?*T.Type = if (typedArgs.len >= 2) typedArgs[1].value.getType() else null;

    const retType: *T.Type = switch (op) {
        .map => blk: {
            const r2 = try env.freshVar();
            if (arg1) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, r2), loc);
            break :blk try env.namedTypeArgs("Result", &.{ r2, errTy });
        },
        .flatMap => blk: {
            const r2 = try env.freshVar();
            const resTy = try env.namedTypeArgs("Result", &.{ r2, errTy });
            if (arg1) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, resTy), loc);
            break :blk resTy;
        },
        .unwrapOr => blk: {
            if (arg1) |a| try unifyAt(env, a, okTy, loc);
            break :blk okTy;
        },
        .isOk, .isError => try env.namedType("bool"),
    };

    try env.method_lowerings.put(loc, .{ .domain = .result, .op = op, .qualified = true });

    return ast.TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Resolve a builtin method call on a `@Result<R, E>` or `@Option<T>` receiver
/// (`.map` / `.flatMap` / `.unwrapOr` / `.isOk` / `.isError`).
///
/// Returns the typed call node (with the correct result type) and records a
/// lowering decision in `env.method_lowerings` keyed by `loc`, so the AST
/// transform can rewrite it into a `__bp_<domain>_<op>(receiver, arg)` builtin
/// call. Returns `null` when the receiver is not a Result/Option or the method
/// is unknown — the caller then falls back to permissive method typing.
fn inferResultOptionMethod(
    env: *Env,
    recvPtr: *ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?ast.TypedExpr {
    const recvTy = recvPtr.getType().deref();
    if (recvTy.* != .named) return null;
    const named = recvTy.named;
    const isResult = std.mem.eql(u8, named.name, "Result");
    const isOption = std.mem.eql(u8, named.name, "optional");
    if (!isResult and !isOption) return null;

    // F11 — `expect` was `unwrapOr` under a name that says the opposite, and
    // is gone. The refusal is explicit because the fallback for an unknown
    // method on a `?T` is permissive typing: without it, `.expect(…)` would
    // still compile and fail at run time, which is worse than the alias was.
    if (isOption and std.mem.eql(u8, callee, "expect")) {
        env.lastError = TypeError.custom(
            diagnostics.option_expect_removed ++
                ": `?T` has no `expect` — it was an alias of `unwrapOr` under a name that says the absent branch is unreachable",
            "Write `unwrapOr(<default>)`, which is what it did. There is no assert-shaped unwrap on `?T`: `case` the optional, or `@panic` in the absent arm.",
        ).withLoc(loc);
        return error.TypeError;
    }

    const op: envMod.MethodLowering.Op =
        if (std.mem.eql(u8, callee, "map")) .map else if (std.mem.eql(u8, callee, "flatMap")) .flatMap else if (std.mem.eql(u8, callee, "unwrapOr")) .unwrapOr else if (isResult and std.mem.eql(u8, callee, "isOk")) .isOk else if (isResult and std.mem.eql(u8, callee, "isError")) .isError else return null;

    // The success-payload type: `R` for `Result<R, E>`, `T` for `Option<T>`.
    const okTy: *T.Type = if (named.args.len >= 1) named.args[0] else try env.freshVar();
    const errTy: *T.Type = if (isResult and named.args.len >= 2) named.args[1] else try env.freshVar();

    // The functional / default argument arrives as the first positional arg.
    const arg0: ?*T.Type = if (typedArgs.len >= 1) typedArgs[0].value.getType() else null;

    const retType: *T.Type = switch (op) {
        .map => blk: {
            const r2 = try env.freshVar();
            if (arg0) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, r2), loc);
            break :blk if (isResult)
                try env.namedTypeArgs("Result", &.{ r2, errTy })
            else
                try env.namedTypeArgs("optional", &.{r2});
        },
        .flatMap => blk: {
            const r2 = try env.freshVar();
            const resTy = if (isResult)
                try env.namedTypeArgs("Result", &.{ r2, errTy })
            else
                try env.namedTypeArgs("optional", &.{r2});
            if (arg0) |a| try unifyAt(env, a, try env.funcType(&.{okTy}, resTy), loc);
            break :blk resTy;
        },
        .unwrapOr => blk: {
            if (arg0) |a| try unifyAt(env, a, okTy, loc);
            break :blk okTy;
        },
        .isOk, .isError => try env.namedType("bool"),
    };

    try env.method_lowerings.put(loc, .{ .domain = if (isResult) .result else .option, .op = op });

    return ast.TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Resolve a compiler-provided template method (expr-templates F4):
/// `text`/`parts`/`lookup`/`fail`/`failAt` on an `expr` receiver, plus
/// `ref()` on a `Binding`.
///
/// The data model (`Span`, `Part`, `Binding`) lives in `std.syntax`
/// (libs/std/src/syntax.bp); these methods are inference-resolved like the
/// `@Result`/`@Option` builtins — no runtime dispatch table — and recorded in
/// `env.templateLowerings` (keyed by call loc) for the expansion pass (F6).
/// Instances only exist at comptime; no codegen backend ever sees these calls.
/// Returns null when the receiver is not an `expr`/`Binding` or the method is
/// unknown — the caller falls back to permissive method typing.
fn inferTemplateMethod(
    env: *Env,
    recvPtr: *ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?ast.TypedExpr {
    const recvTy = recvPtr.getType().deref();
    if (recvTy.* != .named) return null;
    const named = recvTy.named;

    const unifyArg = struct {
        fn unifyArg(e: *Env, args: []ast.CallArgOf(.typed), i: usize, expected: *T.Type) InferError!void {
            if (i >= args.len) return;
            try unifyAt(e, expected, args[i].value.getType(), args[i].value.getLoc());
        }
    }.unifyArg;

    var op: envMod.TemplateOp = undefined;
    var retType: *T.Type = undefined;

    if (std.mem.eql(u8, named.name, "Expr")) {
        if (std.mem.eql(u8, callee, "value")) {
            // The expression's value type slot — what the code evaluates to.
            op = .value;
            retType = if (named.args.len >= 1) named.args[0] else try env.freshVar();
        } else if (std.mem.eql(u8, callee, "text")) {
            op = .text;
            retType = try env.namedType("string");
        } else if (std.mem.eql(u8, callee, "parts")) {
            op = .parts;
            retType = try env.namedTypeArgs("array", &.{try env.namedType("Part")});
        } else if (std.mem.eql(u8, callee, "source")) {
            // Declaration position — where the expression was written.
            op = .source;
            retType = try env.namedType("Source");
        } else if (std.mem.eql(u8, callee, "context")) {
            // The full second-layer input: source + text + shape. The record is
            // `ExprContext`, not `Context`: `@Context<Base, Return>` is the hook
            // wrapper and one name cannot mean both (front 20 F1).
            op = .context;
            retType = try env.namedType("ExprContext");
        } else if (std.mem.eql(u8, callee, "bindings")) {
            // Enumerate the origin scope (top-level decls + imports, V1).
            op = .bindings;
            retType = try env.namedTypeArgs("array", &.{try env.namedType("Binding")});
        } else if (std.mem.eql(u8, callee, "build")) {
            // Parse source text into an expression carrying the receiver's
            // origin scope + provenance — how a second-layer language emits
            // code without quoting (`expr { … }` covers the pattern case).
            op = .build;
            try unifyArg(env, typedArgs, 0, try env.namedType("string"));
            retType = try env.namedTypeArgs("Expr", &.{try env.freshVar()});
        } else if (std.mem.eql(u8, callee, "custom")) {
            // Pack a reference `CustomNode` tree + executable `code` into the
            // `@ExprCustom<R>` carrier (expr-custom). The `code`'s value type `R`
            // is revealed at expansion; the tree is stored by call-location for
            // tooling. Generic — the core never inspects `kind`/`label`.
            op = .custom;
            const r = try env.freshVar();
            try unifyArg(env, typedArgs, 0, try env.namedType("CustomNode"));
            try unifyArg(env, typedArgs, 1, try env.namedTypeArgs("Expr", &.{r}));
            retType = try env.namedTypeArgs("CustomExpr", &.{r});
        } else if (std.mem.eql(u8, callee, "lookup")) {
            op = .lookup;
            try unifyArg(env, typedArgs, 0, try env.namedType("string"));
            retType = try env.namedTypeArgs("optional", &.{try env.namedType("Binding")});
        } else if (std.mem.eql(u8, callee, "fail")) {
            op = .fail;
            try unifyArg(env, typedArgs, 0, try env.namedType("string"));
            // `fail` never returns — a fresh var unifies with any context.
            retType = try env.freshVar();
        } else if (std.mem.eql(u8, callee, "failAt")) {
            op = .failAt;
            try unifyArg(env, typedArgs, 0, try env.namedType("Span"));
            try unifyArg(env, typedArgs, 1, try env.namedType("string"));
            retType = try env.freshVar();
        } else return null;
    } else if (std.mem.eql(u8, named.name, "Binding")) {
        if (!std.mem.eql(u8, callee, "ref")) return null;
        op = .ref;
        // A spliceable reference: `expr` of a type revealed at expansion.
        retType = try env.namedTypeArgs("Expr", &.{try env.freshVar()});
    } else return null;

    try env.templateLowerings.put(loc, op);

    return ast.TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Resolve `recv.callee(args)` against inherent methods and activated extensions.
///
/// Returns the typed call on success, or null when there is no method/extension
/// match (the caller then falls back to a plain callee lookup). Raises
/// `error.TypeError` for the diagnostic cases: not-active, and ambiguity.
fn resolveReceiverCall(
    env: *Env,
    recv: []const u8,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?TypedExpr {
    // (a) Qualified call: receiver is an extension symbol, e.g. `PatoNada.swim(donald)`.
    //     Qualified calls resolve without activation.
    if (env.extensions.get(recv)) |ext| {
        if (!containsStr(ext.methods, callee)) return null;
        return try makeMethodCall(env, recvPtr, callee, typedArgs, typedTrailing, loc);
    }

    // A type-qualified call (`EnumType.Variant(args)`, struct static call) is not an
    // instance dispatch — leave it to the constructor-resolution path.
    if (env.lookupTypeDef(recv) != null) return null;

    // (b) Instance call: `recv` is a value; dispatch on its nominal type.
    const recvType = env.lookup(recv) orelse return null;
    const typeName = nominalName(recvType) orelse return null;

    // Rule 1 — inherent method (declared on the type or inline `implement`).
    if (env.hasInherentMethod(typeName, callee)) {
        try recordInstanceCall(env, loc, typeName);
        return try makeMethodCall(env, recvPtr, callee, typedArgs, typedTrailing, loc);
    }

    // Rule 2 — an `implement` block providing `callee` for this type. Every entry
    // in `env.extensions` is declared in the current module (imports do not register
    // here), so all are auto-applied: no activation is required (Rule B). Two local
    // impls of the same method for the same type are ambiguous.
    var matchSym: ?[]const u8 = null;
    var ambiguousWith: ?[]const u8 = null;
    var it = env.extensions.valueIterator();
    while (it.next()) |ext| {
        if (!std.mem.eql(u8, ext.target, typeName)) continue;
        if (!containsStr(ext.methods, callee)) continue;
        if (matchSym == null) {
            matchSym = ext.name;
        } else if (ambiguousWith == null) {
            ambiguousWith = ext.name;
        }
    }

    if (matchSym) |sym| {
        if (ambiguousWith) |other| {
            env.lastError = TypeError.ambiguousExtension(typeName, callee, sym, other).withLoc(loc);
            return error.TypeError;
        }
        // External dispatch: lower `recv.callee(args)` → `sym.callee(recv, args)`.
        try env.dispatchRewrites.put(loc, sym);
        return try makeMethodCall(env, recvPtr, callee, typedArgs, typedTrailing, loc);
    }

    return null;
}

/// Resolve `xs.method(args)` where `xs: Array<T>` against the `list` stdlib
/// module's exported functions. Returns a typed call on success, null when no
/// match. Records a `StdArrayLowering` so the transform rewrites to the
/// qualified `list.method(xs, args)` form (no explicit import needed).
fn resolveStdArrayMethod(
    env: *Env,
    recv: *ast.Expr,
    recvPtr: ?*ast.TypedExpr,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
    loc: ast.Loc,
) InferError!?TypedExpr {
    _ = recv;
    // Don't dispatch inside stdlib modules themselves — they implement the methods.
    if (std.mem.startsWith(u8, env.modulePath, "std/")) return null;
    const rp = recvPtr orelse return null;
    const recvType = rp.getType().deref();
    if (recvType.* != .named) return null;

    // Map the receiver's primitive type to its interface, then resolve `callee`
    // against that interface's `default fn` instance methods, following the
    // `extends` chain. Only `default fn` methods are materialized; `@[external]`
    // methods (`map`, `abs`, …) and unknown methods fall through to the permissive
    // path. (Numeric tower deferred until `@[external]` method lowering lands —
    // its `default fn`s like `clamp` call host-backed `min`/`max`.)
    const ifaceName = primitiveInterfaceName(recvType.named.name) orelse return null;
    const found = findInterfaceDefaultFn(env, ifaceName, callee) orelse return null;
    const im = found.method;

    // Mark the owning interface used so codegen emits its prototype methods.
    try env.usedAssocInterfaces.put(found.owner, {});

    // Per-call generic scope: `Self` = the receiver array, `T` = its element.
    var gm = std.StringHashMap(*T.Type).init(env.arena);
    defer gm.deinit();
    try gm.put("Self", recvType);
    if (recvType.named.args.len >= 1) try gm.put("T", recvType.named.args[0]);
    for (im.genericParams) |gp| try gm.put(gp.name, try env.freshVar());

    const restParams = im.params[1..]; // drop `self`
    const total = typedArgs.len + typedTrailing.len;
    // C-04 / N1 — `s.slice(1)` against `slice(self, start: i32, end: ?i32 = null)`.
    // The interface declares the default; the call may omit it.
    var fillPlan: ?envMod.DefaultFill = null;
    if (restParams.len != total) {
        if (typedTrailing.len == 0) fillPlan = try recordDefaultFill(env, loc, restParams, typedArgs);
        // N2 — anything the defaults do not cover is still the arity error.
        if (fillPlan == null) {
            env.lastError = TypeError.arityMismatch(callee, restParams.len, total).withLoc(loc);
            return error.TypeError;
        }
    }
    if (fillPlan) |fill| {
        for (fill.slots, restParams) |slot, p| {
            const ai = slot orelse continue;
            const pType = try paramTypeInContext(env, p, gm);
            try unifyAt(env, pType, typedArgs[ai].value.getType(), typedArgs[ai].value.getLoc());
        }
    } else for (restParams[0..typedArgs.len], typedArgs) |p, ta| {
        const pType = try paramTypeInContext(env, p, gm);
        try unifyAt(env, pType, ta.value.getType(), ta.value.getLoc());
    }
    for (typedTrailing, 0..) |tl, i| {
        const pType = try paramTypeInContext(env, restParams[typedArgs.len + i], gm);
        const lamParams = try env.arena.alloc(*T.Type, tl.params.len);
        for (lamParams) |*lp| lp.* = try env.freshVar();
        try unifyAt(env, pType, try env.funcType(lamParams, try env.freshVar()), loc);
    }
    const retType = if (im.returnType) |rt| try resolveTypeRefInContext(env, rt, gm) else try env.namedType("void");

    if (primKindOfName(recvType.named.name) != null) try recordInstanceCall(env, loc, recvType.named.name);

    return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
        .receiver = recvPtr,
        .callee = callee,
        .is_builtin = false,
        .args = typedArgs,
        .trailing = typedTrailing,
    } } } };
}

/// Map a builtin-primitive type name to its `PrimKind` family, or null when the
/// name is not a primitive (a record/struct/enum/type variable). Used to record
/// how a value-receiver instance call lowers on the non-JS backends.
fn primKindOfName(typeName: []const u8) ?envMod.PrimKind {
    const map = [_]struct { t: []const u8, k: envMod.PrimKind }{
        .{ .t = "array", .k = .array },
        .{ .t = "string", .k = .string },
        .{ .t = "bool", .k = .bool },
        .{ .t = "i32", .k = .int },
        .{ .t = "i64", .k = .int },
        .{ .t = "u32", .k = .int },
        .{ .t = "u64", .k = .int },
        .{ .t = "f32", .k = .float },
        .{ .t = "f64", .k = .float },
    };
    for (map) |e| if (std.mem.eql(u8, typeName, e.t)) return e.k;
    return null;
}

/// The return type of a builtin-primitive method call derived from its declared
/// signature in `primitives.d.bp` (`Self` substitutes to the receiver, `T` to its
/// first type arg, and any method-level `<U>` becomes a fresh var). Lets a chained
/// call keep tracking its type (`xs.filter(f).at(0)` → `?T`). Returns null when
/// the method is unknown to the interface; the caller then types it permissively.
/// Two intrinsic shapes don't map to a `fn` slot: a `val name: T` interface field
/// (e.g. `Array.length` — a property, not a fn) and the `len`/`size` aliases for
/// that same length property — both are read off the interface field directly.
fn primMethodReturnTypeFromIface(env: *Env, recvTy: *T.Type, callee: []const u8) InferError!?*T.Type {
    const ifaceName = primitiveInterfaceName(recvTy.named.name) orelse return null;
    var current: ?[]const u8 = ifaceName;
    var guard: usize = 0;
    while (current) |cname| {
        if (guard >= 16) break;
        guard += 1;
        const decl = env.assocInterfaceDecls.get(cname) orelse return null;

        // (a) Declared `fn` method (host-backed or `default fn`) — derive its
        // return type via the same generic-substitution path the stdlib lib
        // dispatch uses, so `map<U>(…) -> Array<U>` yields a fresh-var element.
        for (decl.methods) |m| {
            if (!std.mem.eql(u8, m.name, callee)) continue;
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            var gm = std.StringHashMap(*T.Type).init(env.arena);
            defer gm.deinit();
            try gm.put("Self", recvTy);
            if (recvTy.named.args.len >= 1) try gm.put("T", recvTy.named.args[0]);
            for (m.genericParams) |gp| try gm.put(gp.name, try env.freshVar());
            return if (m.returnType) |rt|
                try resolveTypeRefInContext(env, rt, gm)
            else
                try env.namedType("void");
        }

        // (b) `val name: T` interface field accessed as `recv.name()`. The
        // `length` rename routes both `xs.len()` and `xs.size()` to the same
        // intrinsic property, so they share the field's declared type.
        const field_name: []const u8 = if (std.mem.eql(u8, callee, "len") or std.mem.eql(u8, callee, "size"))
            "length"
        else
            callee;
        for (decl.fields) |f| {
            if (std.mem.eql(u8, f.name, field_name)) return try env.namedType(f.typeName);
        }

        current = if (decl.extends.len > 0) decl.extends[0] else null;
    }
    return null;
}

/// The declared parameter types of a builtin-primitive method, `self` dropped
/// and resolved against the receiver: `Array<Item>.filter` answers
/// `[fn(Item) -> bool]`. Same interface walk and same generic substitution as
/// `primMethodReturnTypeFromIface` — `Self` is the receiver, `T` its first type
/// argument, a method-level `<U>` a fresh var. Null when the receiver is not a
/// builtin primitive or the interface does not declare `callee`.
///
/// Read before the call's arguments are inferred, so a lambda argument's
/// parameters are bound to the element type instead of a fresh var. Without it
/// `xs.filter({ e -> e.name.contains("x") })` typed `e` as an unresolved
/// variable, the `contains` receiver never reached `.named`, and the
/// `@External.Node("includes")` rename never fired — commonJS emitted
/// `.contains(…)`, which node refuses.
fn primMethodParamTypes(env: *Env, recvTy: *T.Type, callee: []const u8) InferError!?[]*T.Type {
    const rt = recvTy.deref();
    if (rt.* != .named) return null;
    if (primKindOfName(rt.named.name) == null) return null;
    const ifaceName = primitiveInterfaceName(rt.named.name) orelse return null;
    var current: ?[]const u8 = ifaceName;
    var guard: usize = 0;
    while (current) |cname| {
        if (guard >= 16) break;
        guard += 1;
        const decl = env.assocInterfaceDecls.get(cname) orelse return null;
        for (decl.methods) |m| {
            if (!std.mem.eql(u8, m.name, callee)) continue;
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            var gm = std.StringHashMap(*T.Type).init(env.arena);
            defer gm.deinit();
            try gm.put("Self", rt);
            if (rt.named.args.len >= 1) try gm.put("T", rt.named.args[0]);
            for (m.genericParams) |gp| try gm.put(gp.name, try env.freshVar());
            const out = try env.arena.alloc(*T.Type, m.params.len - 1);
            // `paramTypeInContext` — not `resolveTypeRefInContext` — because a
            // fn-typed param (`pred: fn(item: T) -> bool`) carries its
            // signature in `Param.fnType`, not in `typeRef`.
            for (m.params[1..], 0..) |p, i| {
                out[i] = try paramTypeInContext(env, p, gm);
            }
            return out;
        }
        current = if (decl.extends.len > 0) decl.extends[0] else null;
    }
    return null;
}

/// True when `ty` carries no type variable anywhere — the receiver's element
/// type is actually KNOWN. `primMethodParamTypes`' answer is only pushed into a
/// lambda when the declared PARAMETERS are ground: an element type that is
/// still a variable tells the lambda nothing it did not already have, and
/// unifying the lambda's parameter with it adds edges that are not the method's
/// meaning — `Query<T>.min`'s `var best = keys.at(0); keys.forEach({ k -> …
/// best = k; })` becomes `?K = K` and reds "recursive type detected". The
/// declared RETURN is not checked: `map<U>(self, transform: fn(item: T) -> U)`
/// has a fresh `U` by construction, and `params_only` drops it anyway.
fn typeIsGround(ty: *T.Type, depth: usize) bool {
    if (depth > 8) return false;
    const d = ty.deref();
    return switch (d.*) {
        .typeVar => false,
        .named => |n| blk: {
            for (n.args) |a| if (!typeIsGround(a, depth + 1)) break :blk false;
            break :blk true;
        },
        .func => |f| blk: {
            for (f.params) |a| if (!typeIsGround(a, depth + 1)) break :blk false;
            break :blk typeIsGround(f.ret, depth + 1);
        },
        .union_ => |ms| blk: {
            for (ms) |m| if (!typeIsGround(m, depth + 1)) break :blk false;
            break :blk true;
        },
        .record => |fs| blk: {
            for (fs) |f| if (!typeIsGround(f.type_, depth + 1)) break :blk false;
            break :blk true;
        },
    };
}

/// Record how a value-receiver instance call `recv.callee(args)` lowers on the
/// backends without native method dispatch (erlang/beam/wasm). A primitive
/// receiver records its `PrimKind`; any other nominal type records as a record
/// method carrying its type name (the backend resolves local vs imported owner).
/// commonJS ignores the table (it dispatches natively).
fn recordInstanceCall(env: *Env, loc: ast.Loc, typeName: []const u8) InferError!void {
    if (primKindOfName(typeName)) |k| {
        try env.instanceLowerings.put(loc, .{ .prim = k });
    } else {
        try env.instanceLowerings.put(loc, .{ .type_ = typeName });
    }
}

/// Map a primitive type name to its controller interface in `primitives.d.bp`.
/// Numeric widths are intentionally excluded for now (their `default fn`s call
/// host-backed `@[external]` methods that codegen doesn't materialize yet).
fn primitiveInterfaceName(typeName: []const u8) ?[]const u8 {
    const map = [_]struct { t: []const u8, i: []const u8 }{
        .{ .t = "array", .i = "Array" },
        .{ .t = "bool", .i = "Bool" },
        .{ .t = "string", .i = "String" },
        .{ .t = "i32", .i = "I32" },
        .{ .t = "i64", .i = "I64" },
        .{ .t = "u32", .i = "U32" },
        .{ .t = "u64", .i = "U64" },
        .{ .t = "f32", .i = "F32" },
        .{ .t = "f64", .i = "F64" },
    };
    for (map) |e| if (std.mem.eql(u8, typeName, e.t)) return e.i;
    return null;
}

/// JS prototype-method rename driven by the 2-arg `@external(node, "X")`
/// annotation on a primitive-receiver interface method. Returns the host
/// symbol `X` when it differs from `callee` (the call site emits
/// `recv.X(args)` instead of `recv.callee(args)`); returns null when there is
/// no node annotation, when the module is non-empty (3-arg Math/relative form),
/// or when the symbol carries a call template (`"sym(a, self)"`) — those are
/// not call-site renames. Walks the receiver's interface and its `extends`
/// chain so an annotation on `Number.toString` covers every numeric width.
fn primMethodNodeRename(env: *Env, recvTy: *T.Type, callee: []const u8) InferError!?[]const u8 {
    const ifaceName = primitiveInterfaceName(recvTy.named.name) orelse return null;
    var current: ?[]const u8 = ifaceName;
    var guard: usize = 0;
    while (current) |cname| {
        if (guard >= 16) break;
        guard += 1;
        const decl = env.assocInterfaceDecls.get(cname) orelse return null;
        for (decl.methods) |m| {
            if (!std.mem.eql(u8, m.name, callee)) continue;
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            const ref = m.externalFor("node") orelse return null;
            if (ref.module.len != 0) return null;
            if (std.mem.indexOfScalar(u8, ref.symbol, '(') != null) return null;
            if (std.mem.eql(u8, ref.symbol, callee)) return null;
            return ref.symbol;
        }
        current = if (decl.extends.len > 0) decl.extends[0] else null;
    }
    return null;
}

const FoundMethod = struct { method: ast.BehaviorMethod, owner: []const u8 };

/// Find an instance method (`self` receiver) named `callee` in interface
/// `ifaceName`, following its `extends` chain. Matches `default fn` methods (their
/// body is materialized) and `@[external]` declarations that bind to a JS global
/// namespace (`Math`) — those lower to `Math.sym(self, …)`. `@[external]` methods
/// backed by a relative companion (`./gleam_stdlib.mjs`, e.g. `map`/`filter`/
/// `join`/`split`) are left to the permissive path (native JS handles them), so
/// this doesn't intercept array/string methods that already work.
fn findInterfaceDefaultFn(env: *Env, ifaceName: []const u8, callee: []const u8) ?FoundMethod {
    var current: ?[]const u8 = ifaceName;
    var guard: usize = 0;
    while (current) |cname| {
        if (guard >= 16) break;
        guard += 1;
        const decl = env.assocInterfaceDecls.get(cname) orelse return null;
        for (decl.methods) |m| {
            if (!std.mem.eql(u8, m.name, callee)) continue;
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            if (m.is_default) return .{ .method = m, .owner = cname };
            if (m.externalFor("node")) |ref| {
                // Template-form annotation (`$0`/`$1`/… markers): the
                // commonJS prototype patcher (§F1) renders the template into a
                // `Owner.prototype.<m>` body, so dispatch resolution should run
                // here too (marks the interface used so codegen walks it). The
                // 1-arg form has `module == ""` + `symbol = <template>`, so
                // this case takes precedence over the §A4 native-prototype
                // skip (which `continue`s on `ref.module.len == 0`).
                if (primOpTemplate.looksLikeTemplate(ref.symbol)) {
                    return .{ .method = m, .owner = cname };
                }
                // A JS global namespace (`Math`) lowers as `Math.sym(self, …)`,
                // dispatched through the stdlib lib path. The §A4 2-arg shorthand
                // (`@external(node, "X")`, module empty) names a native prototype
                // method — that case is handled by the prim-block rename, NOT here.
                if (ref.module.len == 0) continue;
                const is_global = std.mem.indexOfScalar(u8, ref.module, '/') == null and
                    std.mem.indexOfScalar(u8, ref.module, '.') == null;
                if (is_global) return .{ .method = m, .owner = cname };
            }
        }
        current = if (decl.extends.len > 0) decl.extends[0] else null;
    }
    return null;
}

/// Resolve a method/param's type within a generic context, handling both
/// fn-typed params (`f: fn(a: A) -> B`) and ordinary type-ref params.
fn paramTypeInContext(env: *Env, p: ast.Param, gm: std.StringHashMap(*T.Type)) InferError!*T.Type {
    if (p.fnType) |ft| {
        const fparams = try env.arena.alloc(*T.Type, ft.params.len);
        for (ft.params, 0..) |fp, j| {
            fparams[j] = gm.get(fp.typeName) orelse try env.namedType(fp.typeName);
        }
        const fret = if (ft.returnType) |rn|
            gm.get(rn) orelse try env.namedType(rn)
        else
            try env.namedType("void");
        return try env.funcType(fparams, fret);
    }
    return try resolveParamType(env, p, gm);
}

/// Infer type for `use`-hook expressions (@Context F7).
///
/// The enclosing function's return type decides whether `use` is allowed and which
/// ContextBase the hook expression must agree on. The capability was recorded in
/// `env.fnContext` by `inferFnDecl` before the body was visited.
fn inferUseHookExpr(env: *Env, uh: ast.UseHookExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    // Decision 105 — an annotated loop's body runs later, on demand: a `use`
    // inside it would activate a hook outside the render. Closed, whatever
    // the enclosing fn grants.
    if (env.generatorLoopDepth > 0) {
        env.lastError = TypeError.custom(
            diagnostics.generator_loop_closed_scope ++ ": `use` cannot activate inside an annotated `loop` — its body runs on demand, at each `next`",
            "Activate the hook before the loop and read its value inside; the annotated loop has only its own annotation's capabilities.",
        ).withLoc(loc);
        return error.TypeError;
    }
    const fc = env.fnContext orelse {
        env.lastError = TypeError.useNotAllowed("void").withLoc(loc);
        return error.TypeError;
    };
    if (!fc.implementsContext) {
        env.lastError = TypeError.useNotAllowed(fc.returnDisplay).withLoc(loc);
        return error.TypeError;
    }
    // Decision 88 — the return type owns a context, but a body activates a
    // hook only under an effect annotation: `#[@context]`, or (decision 90) a
    // wrapper effect whose unwrapped return type owns the context. With no
    // annotation the fn is an ordinary fn (a bare `-> Element` renders once, a
    // bare `-> @Context<B, R>` is a hook declaration, and neither writes `use`).
    if (!fc.annotated) {
        env.lastError = TypeError.useWithoutContextEffect(fc.fnName, fc.returnDisplay).withLoc(loc);
        return error.TypeError;
    }

    // `use <hookcall>` — infer the wrapped call, check it yields the right
    // ContextBase, and expose its Return type `R` as the prefix's type. Any
    // binding/destructuring is performed by the enclosing `val`/`var`.
    const valTyped = try inferExprTyped(env, uh.kind.inner.*);
    const valPtr = try makeTypedPtr(env, valTyped);
    try validateUseBase(env, valTyped.getType(), fc, loc);
    const srcTy = bindingSourceType(valTyped.getType());
    return TypedExpr{ .useHook = .{ .loc = loc, .type_ = srcTy, .kind = .{ .inner = valPtr } } };
}

/// True when a binding's value is a `use`-hook prefix expression.
fn isUseHookValue(value: *const ast.ExprOf(.untyped)) bool {
    return value.* == .useHook;
}

/// Verify a `use` expression returns `@Context<B, _>` whose `B` is the one
/// base this body resolves every `use` against (decision 96).
///
/// Two questions, in this order. RC2 first: the enclosing function DECLARED a
/// base in its return type, and a hook anchored elsewhere disagrees with the
/// declaration — that is the older refusal and the one a single `use` hits.
/// Then decision 96's: the anchor is a property of the BODY, fixed by its first
/// `use`, so a second `use` anchored elsewhere reds at its own site with both
/// bases and the line that fixed the first. The two coincide whenever the
/// return type names a base, which is every shape that parses today; the anchor
/// is what holds the rule up where the declaration cannot answer, and it is
/// what makes the diagnostic say which `use` the body is committed to.
fn validateUseBase(env: *Env, valTy: *T.Type, fc: envMod.FnContext, loc: ast.Loc) InferError!void {
    const useBase = contextBaseOfType(env, valTy) orelse {
        const disp = baseNameOfType(valTy) orelse "value";
        env.lastError = TypeError.useNotContext(disp).withLoc(loc);
        return error.TypeError;
    };
    if (env.useAnchor) |anchor| {
        // Decision 96 — the body is already committed. This is the refusal the
        // decision legislates, and it is the one a reader meets: both bases,
        // and the `use` that chose the first.
        if (!std.mem.eql(u8, anchor.base, useBase)) {
            env.lastError = TypeError.contextBaseMixed(anchor.base, anchor.line, useBase).withLoc(loc);
            return error.TypeError;
        }
        return;
    }
    // The first `use` of the body. It fixes the anchor, and before it may do so
    // it has to agree with the base the return type DECLARED — RC2, the older
    // refusal, which is what a single misanchored `use` hits.
    if (fc.base) |fnBase| {
        if (!std.mem.eql(u8, fnBase, useBase)) {
            env.lastError = TypeError.contextMismatch(fnBase, useBase).withLoc(loc);
            return error.TypeError;
        }
    }
    env.useAnchor = .{ .base = useBase, .line = loc.line };
}

/// Bind the names introduced by a destructuring `val { … } = use …` /
/// `val #(…) = use …` against the hook's Return type `R`.
///
/// The record form is lenient — `R` need not be a record, so a field `R` does
/// not declare binds a fresh type var. The tuple form is not (front 19 step 3,
/// decision 67): each name is bound to the element of `R` at its position, and
/// a pattern of another arity, or a hook whose `R` is no tuple at all, is
/// refused at the binding (`use-tuple-arity`). An `R` still unresolved — a
/// generic hook whose instantiation left the tuple open — is committed to a
/// tuple of the pattern's arity, so every element is one variable shared with
/// the hook's own type, never a fresh one unrelated to it.
fn bindUseDestructure(env: *Env, pattern: ast.ParamDestruct, srcTy: *T.Type, loc: ast.Loc) InferError!void {
    const derefed = srcTy.deref();
    switch (pattern) {
        .names => |n| {
            const typeName: []const u8 = switch (derefed.*) {
                .named => |nm| nm.name,
                else => "",
            };
            const maybeDef = env.typeDefs.get(typeName);
            for (n.fields) |fld| {
                const fieldTy = if (maybeDef) |td|
                    if (td.findField(fld.field_name)) |f| f.type_ else try env.freshVar()
                else
                    try env.freshVar();
                try env.bind(fld.bind_name, fieldTy);
            }
        },
        .tuple_ => |t| {
            switch (derefed.*) {
                .named => |n| if (std.mem.eql(u8, n.name, "tuple")) {
                    if (n.args.len != t.len) {
                        env.lastError = TypeError.useTupleArity(t.len, n.args.len, srcTy).withLoc(loc);
                        return error.TypeError;
                    }
                    for (t, n.args) |nm, elemTy| try env.bind(nm, elemTy);
                    return;
                },
                .typeVar => {
                    const elems = try env.arena.alloc(*T.Type, t.len);
                    for (elems) |*e| e.* = try env.freshVar();
                    try unifyAt(env, srcTy, try env.namedTypeArgs("tuple", elems), loc);
                    for (t, elems) |nm, elemTy| try env.bind(nm, elemTy);
                    return;
                },
                else => {},
            }
            env.lastError = TypeError.useTupleArity(t.len, null, srcTy).withLoc(loc);
            return error.TypeError;
        },
        .list, .ctor => {},
    }
}

/// C-02 (decision 63, amended 2026-09-19) — **an index is a method call.**
///
/// The index expression has no typing rule of its own. `xs[k]` **is**
/// `xs.at(k)`, `xs[a..b]` is `xs.slice(a, b)` and `xs[1..]` is
/// `xs.slice(1, null)`; the type of the expression is whatever the method
/// answers, which for `Index<K, V>.at` is `?V`.
///
/// So indexing stops being a privilege of the three built-in collections: a
/// library's own `Matrix`, `Row` or `Buffer` answers `at` / `slice` — ambient
/// behaviors, like `Display`, so the syntax finds the method with nothing
/// imported — and is indexable **with no compiler change**.
///
/// Two halves meet at ONE loc. This function records the untyped method call
/// under the index node's own loc (`env.indexRewrites`) and types that call;
/// `comptime/transform.zig` splices it into the untyped AST before codegen.
/// Because the spliced call keeps the index's loc, every loc-keyed plan
/// inference made while typing it — the method lowering, C-04's default fill —
/// still finds its node. **No backend learns a new rule**: all four already
/// emit a method call, and none of them is touched by this row.
///
/// A range second argument is the slice — one AST node serves indexing and
/// slicing because the index is an ordinary expression (`ast.zig`'s contract) —
/// and an open end travels as `null`, because `start..end` is an AST node and
/// not a value: there is no `Range` type to pass.
fn inferIndexExpr(env: *Env, call: anytype, loc: ast.Loc) InferError!TypedExpr {
    if (call.args.len != 2) {
        env.lastError = TypeError.custom(
            "an index expression carries a receiver and an index",
            "This is the parser's own sugar (`xs[0]`); reaching here with another shape is a compiler bug.",
        ).withLoc(loc);
        return error.TypeError;
    }
    const recvExpr = call.args[0].value;
    const idxExpr = call.args[1].value;

    // The receiver is typed once, HERE, because only its type tells a tuple
    // from everything else — and a tuple is the one receiver the behavior
    // cannot cover. Everything else re-reads it through the rewritten call,
    // which is the ordinary method path and owes nothing to this row.
    const typedRecv = try inferExprTyped(env, recvExpr.*);
    const recvType = typedRecv.getType().deref();
    if (recvType.* == .named and std.mem.eql(u8, recvType.named.name, "tuple")) {
        return inferTupleIndexExpr(env, recvType.named.args, recvExpr, idxExpr, loc);
    }

    const rewrite = try env.arena.create(ast.Expr);
    if (idxExpr.* == .collection and idxExpr.collection.kind == .range) {
        const r = idxExpr.collection.kind.range;
        const args = try env.arena.alloc(ast.CallArgOf(.untyped), 2);
        args[0] = .{ .label = null, .value = r.start };
        args[1] = .{ .label = null, .value = r.end orelse blk: {
            const nullLit = try env.arena.create(ast.Expr);
            nullLit.* = .{ .literal = .{ .loc = idxExpr.collection.loc, .kind = .null_ } };
            break :blk nullLit;
        } };
        rewrite.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = recvExpr,
            .callee = index_slice_method,
            .is_builtin = false,
            .args = args,
            .trailing = &.{},
        } } } };
    } else {
        const args = try env.arena.alloc(ast.CallArgOf(.untyped), 1);
        args[0] = .{ .label = null, .value = idxExpr };
        rewrite.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = recvExpr,
            .callee = index_at_method,
            .is_builtin = false,
            .args = args,
            .trailing = &.{},
        } } } };
    }
    try env.indexRewrites.put(loc, rewrite);
    return inferExprTyped(env, rewrite.*);
}

/// The two method names the index expression rewrites to — the ones
/// `Index<K, V>` and `Slice<V>` declare in `libs/std/src/builtins.d.bp`.
const index_at_method = "at";
const index_slice_method = "slice";

/// A tuple index — the checker's one special case, and the reason the ambient
/// behavior covers the other three receivers and not this one: `t[0]` needs a
/// **constant** index and answers a type **per position**, which
/// `at(key: K) -> ?V` cannot say with a single `V`.
///
/// It rewrites to the positional member access the checker already types and
/// all four backends already emit (`t[0]` → `t._0`), so the special case costs
/// a checker arm and no backend arm — the same bargain as the method rewrite,
/// through a different door.
fn inferTupleIndexExpr(
    env: *Env,
    elems: []*T.Type,
    recvExpr: *ast.Expr,
    idxExpr: *ast.Expr,
    loc: ast.Loc,
) InferError!TypedExpr {
    const digits: []const u8 = if (idxExpr.* == .literal and idxExpr.literal.kind == .numberLit)
        idxExpr.literal.kind.numberLit
    else {
        env.lastError = TypeError.custom(
            "a tuple index must be a constant — a tuple answers a type per position",
            "Write the position (`t[0]`, `t[1]`) or read the element by its label (`t.pop`); an array or a `Dict` is the indexable a computed key belongs to.",
        ).withLoc(loc);
        return error.TypeError;
    };
    const idx = std.fmt.parseInt(usize, digits, 10) catch {
        env.lastError = TypeError.custom(
            "a tuple index must be a constant — a tuple answers a type per position",
            "Write the position (`t[0]`, `t[1]`) or read the element by its label (`t.pop`).",
        ).withLoc(loc);
        return error.TypeError;
    };
    if (idx >= elems.len) {
        env.lastError = TypeError.custom(
            try std.fmt.allocPrint(
                env.arena,
                "this tuple has {d} element(s), so `[{d}]` names no position",
                .{ elems.len, idx },
            ),
            "A tuple's positions are fixed by its type; the last one is one less than its length.",
        ).withLoc(loc);
        return error.TypeError;
    }
    const rewrite = try env.arena.create(ast.Expr);
    rewrite.* = .{ .identifier = .{ .loc = loc, .kind = .{ .identAccess = .{
        .receiver = recvExpr,
        .member = try std.fmt.allocPrint(env.arena, "_{d}", .{idx}),
        .optional = false,
    } } } };
    try env.indexRewrites.put(loc, rewrite);
    return inferExprTyped(env, rewrite.*);
}

/// Infer type for call expressions (function/method invocations and pipelines)
fn inferCallExpr(env: *Env, c: ast.CallExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    // R12 (§2) — manual `Result.Ok(...)` / `Result.Error(...)` construction
    // anywhere inside a `#[@result]` body is forbidden by the auto-wrap
    // contract: the @Result type is opaque inside the body and is constructed
    // by `return` / `throw` ALONE. Direct `return Result.Ok(...)` / `throw
    // Result.Error(...)` forms are caught at the jump site with the dedicated
    // R11 / `throw-must-be-bare-E` diagnostics; anything else reaching here is
    // a let-binding, an argument, a nested expression, etc.
    if (env.throwContext == .result) {
        if (resultVariantCallName(.{ .call = c })) |_| {
            env.lastError = TypeError.custom(
                diagnostics.result_manual_construction_forbidden ++
                    ": the @Result type variants are only constructed by `return` / `throw` inside #[@result]; outside that the type is treated as opaque.",
                "Replace the manual `Result.Ok(...)` / `Result.Error(...)` with the implicit form (`return <r>;` / `throw <e>;`), or move the construction outside the #[@result] body.",
            ).withLoc(loc);
            return error.TypeError;
        }
    }
    // RF5 (§1F / §2 R17) — same shape for `#[@future]`: manual
    // `Future.resolved(...)` / `Future.rejected(...)` calls anywhere inside
    // the body are forbidden; the auto-wrap owns construction.
    if (inEffectContext(env, .future)) {
        if (futureConstructorCallName(.{ .call = c })) |_| {
            env.lastError = TypeError.custom(
                diagnostics.future_manual_construction_forbidden ++
                    ": the @Future type variants are only constructed by `return` / `throw` inside #[@future]; outside that the type is treated as opaque.",
                "Replace the manual `Future.resolved(...)` / `Future.rejected(...)` with the implicit form (`return <t>;` / `throw <e>;`), or move the construction outside the #[@future] body.",
            ).withLoc(loc);
            return error.TypeError;
        }
    }
    return switch (c.kind) {
        .call => |call| {
            // Front 15 handover — `.Circle(radius: 1)`: the parser chains the
            // call onto a `.dotIdent` head, so the callee arrives as an
            // expression with `callee == ""`. It is the variant constructor
            // the leading dot names: `Shape.Circle(…)` when the expected type
            // is an enum declaring that variant, and a located refusal when
            // nothing says which type (decision 67 — no guess). The
            // rewrite is recorded like `xs[k]`'s, so no backend learns a shape.
            if (call.calleeExpr) |ce| {
                if (ce.* == .identifier and ce.identifier.kind == .dotIdent) {
                    const name = ce.identifier.kind.dotIdent;
                    var direct = c;
                    direct.kind.call.calleeExpr = null;
                    direct.kind.call.callee = name;
                    const en = expectedEnumDeclaring(env, name) orelse {
                        const msg = try std.fmt.allocPrint(
                            env.arena,
                            "`.{s}(…)` names a variant by its leading dot, and nothing here says which type declares it",
                            .{name},
                        );
                        const hint = try std.fmt.allocPrint(
                            env.arena,
                            "give the position a type that declares `{s}` (`val v: T = .{s}(…);`, a typed parameter or array), or write `T.{s}(…)`",
                            .{ name, name, name },
                        );
                        env.lastError = TypeError.custom(msg, hint).withLoc(ce.identifier.loc);
                        return error.TypeError;
                    };
                    env.expectedType = null;
                    const recv = try env.arena.create(ast.Expr);
                    recv.* = .{ .identifier = .{ .loc = ce.identifier.loc, .kind = .{ .ident = en } } };
                    direct.kind.call.receiver = recv;
                    // The backends read the untyped program: the transform
                    // splices the named call in, through the index channel.
                    const spliced = try env.arena.create(ast.Expr);
                    spliced.* = .{ .call = direct };
                    spliced.call.loc = loc;
                    try env.indexRewrites.put(loc, spliced);
                    return inferCallExpr(env, direct, loc);
                }
            }
            // C-02 (decision 63, amended 2026-09-19) — `xs[k]` IS `xs.at(k)`.
            // First of all, and before the arguments are inferred: the index
            // has no typing rule of its own, so there is nothing here to type
            // until it has become the method call it is.
            if (call.is_builtin and std.mem.eql(u8, call.callee, ast.index_builtin_name)) {
                return inferIndexExpr(env, call, loc);
            }
            // `@src()` (1.0.10-beta decision 73) — before the arguments are
            // inferred, so `@src(x)` reports the builtin's rule and not `x`.
            if (call.is_builtin and std.mem.eql(u8, call.callee, "src")) {
                return inferSrcBuiltin(env, call, loc);
            }
            // A hand-written `SourceLocation(file: …, …)` needs the record
            // declaration spliced in exactly like the rewrite does.
            if (call.receiver == null and !call.is_builtin and std.mem.eql(u8, call.callee, source_location_type_name)) {
                env.usesSourceLocation = true;
            }
            // Method calls carry a receiver expression — infer it first.
            // Exception: a `"std"` module receiver (`bool.negate(x)`) or the
            // builtin `result` namespace (`result.map(r, f)`) is a namespace,
            // not a value binding — synthesize its typed node instead of
            // looking it up (it would be an unbound variable).
            const typedReceiver: ?*ast.TypedExpr = if (call.receiver) |recvExpr| blk: {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const rn = recvExpr.*.identifier.kind.ident;
                    // An explicit `from "std"` import wins over same-named value
                    // bindings (e.g. the primitive type name `bool`); the builtin
                    // `result` namespace is shadowable by a local binding.
                    if (env.stdImports.contains(rn) or
                        (env.lookup(rn) == null and std.mem.eql(u8, rn, "result")))
                    {
                        break :blk try makeTypedPtr(env, TypedExpr{ .identifier = .{
                            .loc = recvExpr.*.identifier.loc,
                            .type_ = try env.namedType("#std_module"),
                            .kind = .{ .ident = rn },
                        } });
                    }
                    // Associated interface fn receiver (`Pair.of`): `rn` names an
                    // interface (a type, not a value). Synthesize the receiver
                    // node; the call resolves to the registered `rn.callee` below.
                    if (env.lookup(rn) == null) {
                        const qn = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ rn, call.callee });
                        if (env.lookup(qn) != null) {
                            break :blk try makeTypedPtr(env, TypedExpr{ .identifier = .{
                                .loc = recvExpr.*.identifier.loc,
                                .type_ = try env.namedType(rn),
                                .kind = .{ .ident = rn },
                            } });
                        }
                    }
                }
                break :blk try makeTypedPtr(env, try inferExprTyped(env, recvExpr.*));
            } else null;

            // A builtin-primitive receiver declares its own signature in
            // `primitives.bp`, and the receiver is already inferred here — so a
            // lambda argument can be typed from the receiver's element type
            // BEFORE its body is inferred. Anything else keeps the permissive
            // fresh-var path.
            const primParams: ?[]*T.Type = if (typedReceiver) |rp|
                try primMethodParamTypes(env, rp.getType(), call.callee)
            else
                null;

            // C-04 — the callee's parameters AS WRITTEN, read once here and
            // used twice: 00 · 01-checker's expectation just below, and the
            // default fill the arity arm plans further down.
            const declParamsAst: ?[]const ast.Param = calleeParams(env, call.callee);

            // 00 · 01-checker — the DECLARED parameter types of a plain call,
            // read only as the expectation an argument is inferred under
            // (`tokenDeclarations(.Color.Red.500)` resolves the path on the
            // parameter's enum). Nothing is unified from here — the arm that
            // types the call still unifies each argument with its parameter.
            const declParamTypes: ?[]*T.Type = blk: {
                if (call.receiver != null or call.is_builtin) break :blk null;
                const calleeTy = env.lookup(call.callee) orelse break :blk null;
                const d = calleeTy.deref();
                if (d.* != .func) break :blk null;
                break :blk d.func.params;
            };
            // Which parameter each argument lands in. Null is the ordinary
            // answer — argument `i` is parameter `i` — and a slice appears
            // only when a label moved one (C-04).
            const argParamIndex: ?[]const usize = if (declParamTypes != null)
                if (declParamsAst) |ps| try argumentParamSlots(env, ps, call.args) else null
            else
                null;

            const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), call.args.len);
            for (call.args, 0..) |arg, i| {
                // Only the declared PARAMETER types are pushed down
                // (`params_only`). The declared RETURN is not a constraint the
                // lambda has to meet here — `Array.forEach`'s `action` is
                // declared `fn(item: T)`, and every `xs.forEach({ p -> <value> })`
                // in `libs/std` would red against its `void` — and the call's
                // own type is `primMethodReturnTypeFromIface`'s answer anyway.
                // Ground only: every parameter of the declared fn-typed param
                // must mention no type variable (`typeIsGround`). An element
                // type still unresolved tells the lambda nothing, and unifying
                // against it adds edges the method never meant.
                const expected: ?*T.Type = if (primParams) |ps| blk: {
                    if (i >= ps.len) break :blk null;
                    const d = ps[i].deref();
                    if (d.* != .func) break :blk null;
                    for (d.func.params) |fp| if (!typeIsGround(fp, 0)) break :blk null;
                    break :blk ps[i];
                } else null;
                const argExpected: ?*T.Type = if (declParamTypes) |ps| blk: {
                    const pi = if (argParamIndex) |slots|
                        (if (i < slots.len) slots[i] else ps.len)
                    else
                        i;
                    if (pi >= ps.len) break :blk null;
                    break :blk ps[pi];
                } else null;
                const val = if (expected != null and arg.value.* == .function)
                    try inferFunctionExprExpected(env, arg.value.*.function, arg.value.*.function.loc, expected.?, true)
                else
                    try inferExprTypedExpecting(env, arg.value.*, argExpected);
                typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
            }
            const typedTrailing = try inferTrailingLambdasTyped(env, call.trailing);

            // 01 handover 15 — `adder(3)(4)`: what is called is the result of
            // the previous call, carried in `calleeExpr` with `callee == ""`.
            // Type that expression and apply it: it must be a function taking
            // the written arguments (trailing lambdas after them), and the
            // call's type is its return.
            if (call.calleeExpr) |ce| {
                const calleeTyped = try inferExprTyped(env, ce.*);
                const argTypes = try env.arena.alloc(*T.Type, typedArgs.len + typedTrailing.len);
                for (typedArgs, 0..) |a, i| argTypes[i] = a.value.getType();
                for (typedTrailing, 0..) |_, i| argTypes[typedArgs.len + i] = try env.freshVar();
                const ret = try env.freshVar();
                const expectedFn = try env.funcType(argTypes, ret);
                const got = calleeTyped.getType().deref();
                if (got.* == .func and got.func.params.len != argTypes.len) {
                    env.lastError = TypeError.arityMismatch("the called value", got.func.params.len, argTypes.len).withLoc(loc);
                    return error.TypeError;
                }
                try unifyAt(env, got, expectedFn, loc);
                return TypedExpr{ .call = .{ .loc = loc, .type_ = ret, .kind = .{ .call = .{
                    .receiver = null,
                    .callee = call.callee,
                    .is_builtin = false,
                    .args = typedArgs,
                    .trailing = typedTrailing,
                    .calleeExpr = try makeTypedPtr(env, calleeTyped),
                } } } };
            }

            if (call.is_builtin) {
                // Decision 8 §4 — `x is T`. The parser lands it as the `is`
                // builtin with the tested type in the call's `isType` slot;
                // nothing typed it, so `inferBuiltinCallReturnType` had no arm
                // for the name and the call came out `void`.
                if (std.mem.eql(u8, call.callee, ast.is_builtin_name)) {
                    if (call.isType) |tested| try checkIsTestableType(env, tested, loc);
                    return TypedExpr{
                        .call = .{
                            .loc = loc,
                            .type_ = try env.namedType("bool"),
                            .kind = .{
                                .call = .{
                                    .receiver = null,
                                    .callee = call.callee,
                                    .is_builtin = true,
                                    .args = typedArgs,
                                    .trailing = typedTrailing,
                                    // The tested type is what the backends lower the run-time
                                    // test from; dropping it here left them nothing to read.
                                    .isType = call.isType,
                                },
                            },
                        },
                    };
                }
                // `@makeRecord(fields)` — when fields is a literal array of RecordField
                // values, evaluate at inference time and create a synthetic record type.
                if (std.mem.eql(u8, call.callee, "makeRecord") and call.args.len >= 1) {
                    if (try tryEvalMakeRecord(env, call.args[0].value.*, loc)) |result| {
                        return result;
                    }
                }
                const retType = try inferBuiltinCallReturnType(env, call.callee, typedArgs, typedTrailing, loc);
                return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                    .receiver = null,
                    .callee = call.callee,
                    .is_builtin = call.is_builtin,
                    .args = typedArgs,
                    .trailing = typedTrailing,
                } } } };
            }
            // Comptime type-manipulation functions (§1.0.0-beta Steps 4-6):
            // `mergeRecords`, `mapFields`, `partial`, `omit`, `pick` — resolved
            // entirely during inference; produce zero runtime code. Only a bare
            // call the scope does not bind reaches the intercept: a user or std
            // declaration of the same name (`random.pick`) and a method call
            // (`xs.pick()`) keep their normal dispatch.
            if (call.receiver == null and env.lookup(call.callee) == null) {
                if (try tryResolveTypeManipulationCall(env, call.callee, typedArgs, typedTrailing, loc)) |result| {
                    return result;
                }
            }
            // Builtin `result` namespace: `result.map(r, f)`, `result.unwrap(r, 0)`,
            // `result.isOk(r)`… — qualified surface over the built-in
            // `@Result` method ops. No import needed (builtin, not a "std" module);
            // a local value binding named `result` shadows the namespace.
            if (call.receiver) |recvExpr| {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const recvName = recvExpr.*.identifier.kind.ident;
                    if (env.lookup(recvName) == null and std.mem.eql(u8, recvName, "result")) {
                        return try inferResultNamespaceCall(env, typedReceiver, call.callee, typedArgs, typedTrailing, loc);
                    }
                    // Associated interface fn (`Pair.of(a, b)`, `Array.range(0, n)`,
                    // `Function.compose(f, g)`): `recvName.callee` is registered by
                    // `registerInterfaceAssociatedFns`. Each call instantiates fresh
                    // generics. Guarded by `lookup(recvName) == null` so value
                    // bindings of the same name keep their normal method dispatch.
                    //
                    // 01 R6 — a behavior's own name is bound too (std's `Array`
                    // is a function-typed binding), and that binding is not a
                    // value that shadows the behavior: without this the
                    // associated call (`Array.range(0, 3)`) fell through to a
                    // fresh var, and the method on its result (`.map`) recorded
                    // no lowering — erlang's `'__bp_prim_map'` run-time helper.
                    const behaviorName = env.assocInterfaceDecls.contains(recvName) and !env.isVal(recvName);
                    if (env.lookup(recvName) == null or behaviorName) {
                        const qn = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ recvName, call.callee });
                        if (env.lookup(qn)) |fnTy| {
                            return try inferAssociatedFnCall(env, recvName, call.callee, fnTy, typedReceiver, typedArgs, typedTrailing, loc);
                        }
                    }
                    // Decision 62 — a type's own associated fn, called through the
                    // type (`Counter.zero()`). Its result reached here as a fresh
                    // var, so `val c = Counter.zero(); c.bump()` recorded no
                    // `instanceLowerings` entry for `bump`: beam answered
                    // `{unresolved_method, bump, 1}` and wasm trapped, while
                    // commonJS and erlang happened to be right because neither
                    // needs the type. The signature is already registered by
                    // `registerInherentMethodTypes` (with `Self` resolved to the
                    // type) — it was simply never read for the type-qualified form.
                    if (env.lookupTypeDef(recvName) != null) {
                        if (try associatedCallReturnType(env, recvName, call.callee, typedArgs, typedTrailing)) |ret| {
                            return TypedExpr{ .call = .{ .loc = loc, .type_ = ret, .kind = .{ .call = .{
                                .receiver = typedReceiver,
                                .callee = call.callee,
                                .is_builtin = false,
                                .args = typedArgs,
                                .trailing = typedTrailing,
                            } } } };
                        }
                    }
                }
            }

            // `"std"` package qualified call (F2a): `bool.negate(x)` where
            // `bool` was imported via `import {bool} from "std"`. The explicit
            // import wins over same-named value bindings (e.g. the primitive
            // type name `bool`). The callee resolves in the module's exports
            // table; the fn type is instantiated per call site.
            if (call.receiver) |recvExpr| {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const recvName = recvExpr.*.identifier.kind.ident;
                    if (env.stdImports.get(recvName)) |std_key| {
                        if (env.stdModules.get(std_key)) |exports| {
                            const exported = exports.get(call.callee) orelse {
                                var e = TypeError.custom(
                                    "this \"std\" module has no such public function",
                                    "Check the function name against the module's exports.",
                                );
                                e = e.withLoc(loc);
                                env.lastError = e;
                                return error.TypeError;
                            };
                            var seen = std.AutoHashMap(*T.TypeCell, *T.Type).init(env.arena);
                            defer seen.deinit();
                            const instantiated = try instantiateType(env, exported, &seen, .allVars);
                            const retType: *T.Type = switch (instantiated.deref().*) {
                                .func => |f| blk: {
                                    const total = typedArgs.len + typedTrailing.len;
                                    if (f.params.len != total) {
                                        env.lastError = TypeError.arityMismatch(call.callee, f.params.len, total).withLoc(loc);
                                        return error.TypeError;
                                    }
                                    for (typedArgs, f.params[0..typedArgs.len]) |ta, p| {
                                        try unifyAt(env, p, ta.value.getType(), ta.value.getLoc());
                                    }
                                    break :blk f.ret;
                                },
                                else => try env.freshVar(),
                            };
                            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                                .receiver = typedReceiver,
                                .callee = call.callee,
                                .is_builtin = false,
                                .args = typedArgs,
                                .trailing = typedTrailing,
                            } } } };
                        }
                    }
                }
            }

            // Static extension dispatch (F6): `obj.method(args)` resolved via
            // inherent methods, activated `implement`/`extend` blocks, or a
            // qualified call `Sym.method(obj)`. Only bare-identifier receivers
            // dispatch this way; a null result falls through to Result/Option
            // builtins and feat's permissive method typing below.
            if (call.receiver) |recvExpr| {
                if (recvExpr.* == .identifier and recvExpr.*.identifier.kind == .ident) {
                    const recvName = recvExpr.*.identifier.kind.ident;
                    if (try resolveReceiverCall(env, recvName, typedReceiver, call.callee, typedArgs, typedTrailing, loc)) |te| {
                        return te;
                    }
                }
            }

            // Stdlib array method dispatch: `xs.method(args)` where `xs: Array<T>`
            // and `method` is defined in the `list` stdlib module. Rewired by the
            // transform to `list.method(xs, args)` — no explicit import needed.
            if (call.receiver) |recvExpr| {
                if (try resolveStdArrayMethod(env, recvExpr, typedReceiver, call.callee, typedArgs, typedTrailing, loc)) |te| {
                    return te;
                }
            }

            if (typedReceiver) |recvPtr| {
                // Qualified constructor / static call: `EnumType.Variant(args)`.
                // The receiver names a type definition, so the callee is a global
                // constructor binding (not a method) — resolve it the same way as
                // a plain call and keep the receiver for codegen (`Color.Rgb(..)`).
                if (call.receiver) |re| {
                    if (re.* == .identifier and re.*.identifier.kind == .ident and
                        env.lookupTypeDef(re.*.identifier.kind.ident) != null)
                    {
                        if (env.lookup(call.callee)) |calleeTypeRaw| {
                            // Generic enum variant constructor — instantiate per
                            // call site (the receiver names the type def).
                            const calleeType = try instantiateCtorType(env, re.*.identifier.kind.ident, calleeTypeRaw);
                            const resolved = calleeType.deref();
                            const retType: *T.Type = switch (resolved.*) {
                                .func => |f| blk: {
                                    if (f.params.len == typedArgs.len) {
                                        for (typedArgs, f.params) |ta, p|
                                            try unifyAt(env, p, ta.value.getType(), ta.value.getLoc());
                                    }
                                    break :blk f.ret;
                                },
                                .named => resolved,
                                else => try env.freshVar(),
                            };
                            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                                .receiver = recvPtr,
                                .callee = call.callee,
                                .is_builtin = false,
                                .args = typedArgs,
                                .trailing = typedTrailing,
                            } } } };
                        }
                    }
                }

                // 06 N24 / decision 8 §6 — a tuple element of function type
                // called like a method (`#(value: i32, set: fn(…))`, `c.set(9)`).
                // The label→index rewrite the member-access path records
                // (`row.pop` → `row._1`) never fired for a CALL, so every
                // backend emitted `c.set(9)` on a value that is a tuple —
                // `c.set is not a function` on commonJS.
                if (try inferTupleLabelCall(env, recvPtr, call.receiver, call.callee, typedArgs, typedTrailing, loc)) |dispatched| {
                    return dispatched;
                }

                // Builtin `@Result` / `@Option` methods — type-check and record
                // the lowering decision.
                if (try inferResultOptionMethod(env, recvPtr, call.callee, typedArgs, typedTrailing, loc)) |dispatched| {
                    return dispatched;
                }

                // Compiler-provided template methods on `expr` / `Binding`
                // receivers (expr-templates F4) — comptime-only.
                if (try inferTemplateMethod(env, recvPtr, call.callee, typedArgs, typedTrailing, loc)) |dispatched| {
                    return dispatched;
                }

                // Inherent method on the receiver's nominal type, for ANY
                // receiver expression (chained calls `a.b().c()`, field access)
                // — `resolveReceiverCall` above only fires for bare-identifier
                // receivers. This recovers the method's real return type so a
                // `Queue<i32>` chain keeps tracking `?i32` through `.peek()`.
                if (nominalName(recvPtr.getType())) |tn| {
                    if (env.hasInherentMethod(tn, call.callee)) {
                        try recordInstanceCall(env, loc, tn);
                        return try makeMethodCall(env, recvPtr, call.callee, typedArgs, typedTrailing, loc);
                    }
                }

                // A builtin-primitive receiver (`xs.map(f)`, `s.split(sep)`) has
                // no native method dispatch on erlang/beam/wasm — record the
                // primitive family so those backends lower it to the host op,
                // and recover the method's real return type so a chained call
                // (`xs.filter(f).at(0)`) keeps tracking the element/array type.
                {
                    const recvTy = recvPtr.getType().deref();
                    if (recvTy.* == .named and primKindOfName(recvTy.named.name) != null) {
                        try recordInstanceCall(env, loc, recvTy.named.name);
                        // `arr.len()`/`.size()`/`.length()` and `str.length()` are
                        // the native JS `.length` PROPERTY (commonJS emits it
                        // without call parens); erlang/beam lower them to the host
                        // length op. Recording the rename only on a typed array/
                        // string receiver keeps it safe — a `record` with a `len`/
                        // `size`/`length` method is never renamed.
                        const pk = primKindOfName(recvTy.named.name).?;
                        if ((pk == .array or pk == .string) and
                            (std.mem.eql(u8, call.callee, "len") or
                                std.mem.eql(u8, call.callee, "size") or
                                std.mem.eql(u8, call.callee, "length")))
                        {
                            try env.jsMethodRenames.put(loc, "length");
                        }
                        // §A4: per-call-site JS prototype rename driven by the
                        // 2-arg `@external(node, "X")` annotation on the method
                        // (`String.contains` ⇒ `includes`, `Array.append` ⇒
                        // `concat`, …). When the annotated symbol equals the
                        // method name nothing is recorded — call site emits the
                        // bare name unchanged. The rename is gated on a typed
                        // primitive receiver, so a user record method like
                        // `Set.contains` is never renamed.
                        if (try primMethodNodeRename(env, recvTy, call.callee)) |rn| {
                            try env.jsMethodRenames.put(loc, rn);
                        }
                        if (try primMethodReturnTypeFromIface(env, recvTy, call.callee)) |ret| {
                            return TypedExpr{ .call = .{ .loc = loc, .type_ = ret, .kind = .{ .call = .{
                                .receiver = recvPtr,
                                .callee = call.callee,
                                .is_builtin = false,
                                .args = typedArgs,
                                .trailing = typedTrailing,
                            } } } };
                        }
                    }
                }

                // The same `.length` rename through ONE optional layer.
                // `xs.at(0)?.key` is a `?string`, and a `!= null` narrowing
                // does not rewrite the type either, so neither reached the
                // typed-primitive branch above and the call site kept its
                // parens: commonJS emitted `x.length()` against JavaScript's
                // `length` PROPERTY (`TypeError: … is not a function`, exit 1)
                // where erlang printed the number. Only the RENAME is taken
                // from the unwrapped type — the call's own type is whatever
                // the branches below give it.
                if (env.jsMethodRenames.get(loc) == null and
                    (std.mem.eql(u8, call.callee, "len") or
                        std.mem.eql(u8, call.callee, "size") or
                        std.mem.eql(u8, call.callee, "length")))
                {
                    if (optionalInner(recvPtr.getType())) |inner| {
                        const innerTy = inner.deref();
                        if (innerTy.* == .named) {
                            if (primKindOfName(innerTy.named.name)) |pk| {
                                if (pk == .array or pk == .string) try env.jsMethodRenames.put(loc, "length");
                            }
                        }
                    }
                }

                // 06 C9 — a receiver whose type is a nominal the env actually
                // registered has a closed method surface: nothing above matched,
                // so the method does not exist. `d.swim()` on a `type D(id: i32)`
                // used to be typed `freshVar()` and compile.
                //
                // Everything else stays permissive, which is what the fresh var
                // was for: a receiver still an unresolved type variable (an
                // inference gap must not red), and a named type the env cannot
                // open — an imported record whose typedef lives in its own
                // module, a `@Result`/`?T` wrapper, a forward reference.
                // §2.2 — an `unknown` receiver answers no method. It has to be
                // refused before the permissive fresh-var tail below, which is
                // what let `a.len()` check.
                try refuseUnknownUse(env, recvPtr.getType(), loc, "call a method on");
                if (nominalName(recvPtr.getType())) |tn| {
                    if (env.lookupTypeDef(tn)) |td| if (!typeAnswersMember(env, td, call.callee)) {
                        var ext_err: ?TypeError = null;
                        var it = env.extensions.iterator();
                        while (it.next()) |e| {
                            const entry = e.value_ptr.*;
                            if (!std.mem.eql(u8, entry.target, tn)) continue;
                            if (!namesContain(entry.methods, call.callee)) continue;
                            if (env.isActivated(entry.name)) continue;
                            ext_err = TypeError.methodNotActive(tn, call.callee, entry.name);
                            break;
                        }
                        var err = ext_err orelse TypeError.unknownMethod(tn, call.callee);
                        env.lastError = err.withLoc(loc);
                        return error.TypeError;
                    };
                }

                // Other method calls (struct getters, activated extensions) are
                // handled by sibling work — type them permissively as a fresh var
                // so they don't error here.
                return TypedExpr{ .call = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .call = .{
                    .receiver = recvPtr,
                    .callee = call.callee,
                    .is_builtin = false,
                    .args = typedArgs,
                    .trailing = typedTrailing,
                } } } };
            }

            const calleeTypeRaw = if (env.lookup(call.callee)) |ty| ty else {
                env.lastError = TypeError.unboundVariable(call.callee).withLoc(loc);
                return error.TypeError;
            };
            // Generic record/struct/enum constructor: instantiate per call site
            // so the registration-time cells never unify destructively.
            const ctorInstantiated = try instantiateCtorType(env, call.callee, calleeTypeRaw);
            // Generic fn (declared `<T, …>`): standard HM instantiation — each
            // call site gets fresh vars for the fn's `.generic` params, so two
            // calls with different concrete types in one scope never conflict.
            const calleeType = try instantiateGenericType(env, ctorInstantiated);
            const resolved = calleeType.deref();
            const retType: *T.Type = switch (resolved.*) {
                .func => |f| blk: {
                    // Constrained comptime typeparam args are validated against their
                    // declared constraints; their param slots skip ordinary unification.
                    const typeparams = env.lookupTypeparams(call.callee);
                    if (typeparams) |constraints| try validateTypeparams(env, constraints, typedArgs);
                    // `expr` meta-kind params capture their argument unevaluated
                    // instead of unifying it against `expr T` (expr-templates F4).
                    const exprParams = env.lookupExprParams(call.callee);

                    var spreadCount: usize = 0;
                    var nonSpreadCount: usize = 0;
                    for (typedArgs) |ta| {
                        if (ta.label) |lbl| {
                            if (std.mem.eql(u8, lbl, "..")) {
                                spreadCount += 1;
                                continue;
                            }
                        }
                        nonSpreadCount += 1;
                    }

                    if (spreadCount == 0) {
                        if (f.params.len != call.args.len) {
                            // C-04 / N1 — a call may omit an argument whose
                            // parameter declares a default. The fill is planned
                            // here and materialised in `transform.zig`, so all
                            // four backends see a complete call and none of them
                            // learns a new rule. A comptime / `@Expr` / template
                            // callee keeps the exact check: its own machinery is
                            // driven by the argument INDEX, and a short call has
                            // never reached it.
                            const filled: ?envMod.DefaultFill = fillBlk: {
                                if (call.args.len > f.params.len) break :fillBlk null;
                                if (typeparams != null or exprParams != null) break :fillBlk null;
                                if (env.templateFns.get(call.callee) != null) break :fillBlk null;
                                const declared = declParamsAst orelse break :fillBlk null;
                                if (declared.len != f.params.len) break :fillBlk null;
                                break :fillBlk try recordDefaultFill(env, loc, declared, typedArgs);
                            };
                            if (filled) |fill| {
                                try unifyFilledArgs(env, fill, f.params, typedArgs);
                                break :blk f.ret;
                            }
                            // N2 — a missing REQUIRED argument is the arity
                            // error it has always been, word for word.
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, call.args.len).withLoc(loc);
                            return error.TypeError;
                        }
                        // Look up the template fn before the loop so non-@Expr
                        // params can also be collected as plain arg bindings.
                        const maybeTfn: ?ast.FnDecl = env.templateFns.get(call.callee);
                        var captures: std.ArrayListUnmanaged(template.CapturedExpr) = .empty;
                        var plainArgs: std.ArrayListUnmanaged(template.PlainArg) = .empty;
                        for (typedArgs, f.params, 0..) |ta, paramType, i| {
                            if (typeparams) |constraints| if (isTypeparamIndex(constraints, i)) continue;
                            if (exprParams) |eps| if (exprParamAt(eps, i)) |ep| {
                                try captures.append(env.arena, try captureExprArg(env, call.callee, ep, call.args[i].value, ta, paramType));
                                continue;
                            };
                            try unifyArgument(env, paramType, ta.value.getType(), ta.value.getLoc());
                            // For template fns: collect the arg value as a JS literal.
                            if (maybeTfn != null and i < maybeTfn.?.params.len) {
                                const jsVal = try literalSourceAlloc(env.arena, call.args[i].value) orelse {
                                    env.lastError = TypeError.custom(
                                        "non-`@Expr` parameter of a template function must receive a literal value at the call site",
                                        "Pass a string, integer, or boolean literal directly; runtime values have no compile-time meaning (V1).",
                                    ).withLoc(ta.value.getLoc());
                                    return error.TypeError;
                                };
                                try plainArgs.append(env.arena, .{
                                    .paramName = maybeTfn.?.params[i].name,
                                    .source = jsVal,
                                });
                            }
                        }
                        const capturedSlice: []const template.CapturedExpr = if (captures.items.len > 0)
                            try captures.toOwnedSlice(env.arena)
                        else
                            &.{};
                        const plainSlice: []const template.PlainArg = if (plainArgs.items.len > 0)
                            try plainArgs.toOwnedSlice(env.arena)
                        else
                            &.{};
                        if (capturedSlice.len > 0) {
                            try env.exprCaptures.put(loc, capturedSlice);
                        }
                        // Call-site expansion (F6): a call to a template fn
                        // (`-> @Expr<T>`) is replaced by its expansion,
                        // re-type-checked in the caller's environment.
                        if (maybeTfn) |tfn| {
                            return try expandTemplateCall(env, tfn, capturedSlice, plainSlice, f.ret, loc);
                        }
                        break :blk f.ret;
                    }

                    // C11: a call carrying a `..` spread on a record constructor
                    // is a record *update*: the spread must be that record, and
                    // each labelled arg is matched to the field its label names.
                    if (spreadCount == 1) updBlk: {
                        const td = env.lookupTypeDef(call.callee) orelse break :updBlk;
                        const fields = switch (td) {
                            .record => |r| r.fields,
                            .struct_ => |st| st.fields,
                            .enum_ => break :updBlk,
                        };
                        if (fields.len != f.params.len) break :updBlk;
                        for (typedArgs, 0..) |ta, ai| {
                            const lbl = ta.label orelse {
                                // Positional args beside a spread have no field to name.
                                env.lastError = TypeError.custom(
                                    "a record update names its fields",
                                    "Write `Name(..base, field: value)`.",
                                ).withLoc(ta.value.getLoc());
                                return error.TypeError;
                            };
                            if (std.mem.eql(u8, lbl, "..")) {
                                try unifyAt(env, f.ret, ta.value.getType(), ta.value.getLoc());
                                continue;
                            }
                            const idx = for (fields, 0..) |fd, fi| {
                                if (std.mem.eql(u8, fd.name, lbl)) break fi;
                            } else {
                                const vloc = call.args[ai].value.getLoc();
                                const labelCol = if (vloc.col > lbl.len + 2) vloc.col - lbl.len - 2 else vloc.col;
                                env.lastError = TypeError.unknownField(call.callee, lbl).withLoc(.{ .line = vloc.line, .col = labelCol });
                                return error.TypeError;
                            };
                            try unifyArgument(env, f.params[idx], ta.value.getType(), ta.value.getLoc());
                        }
                        break :blk f.ret;
                    }

                    // Keep the historical spread behavior (and snapshots) for narrow update/error cases.
                    if (spreadCount != 1 or nonSpreadCount < 2) {
                        if (f.params.len != call.args.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, call.args.len).withLoc(loc);
                            return error.TypeError;
                        }
                        for (typedArgs, f.params, 0..) |ta, paramType, i| {
                            if (typeparams) |constraints| if (isTypeparamIndex(constraints, i)) continue;
                            try unifyArgument(env, paramType, ta.value.getType(), ta.value.getLoc());
                        }
                        break :blk f.ret;
                    }

                    if (nonSpreadCount > f.params.len) {
                        env.lastError = TypeError.arityMismatch(call.callee, f.params.len, nonSpreadCount).withLoc(loc);
                        return error.TypeError;
                    }

                    var paramIndex: usize = 0;
                    for (typedArgs) |ta| {
                        if (ta.label) |lbl| {
                            if (std.mem.eql(u8, lbl, "..")) continue;
                        }
                        if (paramIndex >= f.params.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, nonSpreadCount).withLoc(loc);
                            return error.TypeError;
                        }
                        try unifyArgument(env, f.params[paramIndex], ta.value.getType(), ta.value.getLoc());
                        paramIndex += 1;
                    }
                    break :blk f.ret;
                },
                .named => resolved,
                else => try env.freshVar(),
            };
            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                .receiver = null,
                .callee = call.callee,
                .is_builtin = call.is_builtin,
                .args = typedArgs,
                .trailing = typedTrailing,
            } } } };
        },
        .pipeline => |p| {
            const lhsTyped = try inferExprTyped(env, p.lhs.*);
            const lhsPtr = try makeTypedPtr(env, lhsTyped);
            // When the RHS is a plain call, the LHS value is the first argument.
            // Build the typed RHS manually to avoid the arity check in inferCallExpr.
            if (p.rhs.* == .call and p.rhs.*.call.kind == .call) {
                const call = p.rhs.*.call.kind.call;
                const calleeTypeRaw = if (env.lookup(call.callee)) |ty| ty else try env.freshVar();
                // Generic fn in pipeline position gets the same per-call-site
                // instantiation as a plain call.
                const calleeType = try instantiateGenericType(env, calleeTypeRaw);
                const resolved = calleeType.deref();
                const retType: *T.Type = switch (resolved.*) {
                    .func => |f| blk: {
                        const totalArgs = call.args.len + 1 + call.trailing.len;
                        // C12: a pipeline whose RHS does not take the piped
                        // value plus its own arguments is an arity error at
                        // the RHS, not a silently skipped unification.
                        if (f.params.len != totalArgs) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, totalArgs).withLoc(p.rhs.*.getLoc());
                            return error.TypeError;
                        }
                        try unifyAt(env, f.params[0], lhsTyped.getType(), loc);
                        for (call.args, 1..) |arg, i| {
                            const argTyped = try inferExprTyped(env, arg.value.*);
                            try unifyAt(env, f.params[i], argTyped.getType(), loc);
                        }
                        break :blk f.ret;
                    },
                    else => try env.freshVar(),
                };
                // Build a typed call node for the RHS (with pipeline arity).
                const typedCallArgs = try env.arena.alloc(ast.CallArgOf(.typed), call.args.len);
                for (call.args, 0..) |arg, i| {
                    const val = try inferExprTyped(env, arg.value.*);
                    typedCallArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
                }
                const typedTrailing = try inferTrailingLambdasTyped(env, call.trailing);
                const rhsNode = TypedExpr{ .call = .{ .loc = p.rhs.*.getLoc(), .type_ = retType, .kind = .{ .call = .{
                    .receiver = null,
                    .callee = call.callee,
                    .is_builtin = call.is_builtin,
                    .args = typedCallArgs,
                    .trailing = typedTrailing,
                } } } };
                const rhsPtr = try makeTypedPtr(env, rhsNode);
                return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .pipeline = .{
                    .lhs = lhsPtr,
                    .rhs = rhsPtr,
                    .comment = p.comment,
                } } } };
            }
            const rhsTyped = try inferExprTyped(env, p.rhs.*);
            const rhsPtr = try makeTypedPtr(env, rhsTyped);
            // C12: `lhs |> f` with `f` a function is the call `f(lhs)`: its
            // type is `f`'s return, and `f` must take exactly one argument.
            const pipeType: *T.Type = switch (rhsTyped.getType().deref().*) {
                .func => |f| blk: {
                    if (f.params.len != 1) {
                        const name = switch (p.rhs.*) {
                            .identifier => |id| switch (id.kind) {
                                .ident => |n| n,
                                else => "|>",
                            },
                            else => "|>",
                        };
                        env.lastError = TypeError.arityMismatch(name, f.params.len, 1).withLoc(p.rhs.*.getLoc());
                        return error.TypeError;
                    }
                    try unifyAt(env, f.params[0], lhsTyped.getType(), loc);
                    break :blk f.ret;
                },
                else => rhsTyped.getType(),
            };
            return TypedExpr{ .call = .{ .loc = loc, .type_ = pipeType, .kind = .{ .pipeline = .{
                .lhs = lhsPtr,
                .rhs = rhsPtr,
                .comment = p.comment,
            } } } };
        },
    };
}

/// True when an untyped `case` arm body is a block (`_ -> { … }`), which the
/// parser represents as a zero-parameter lambda.
fn isBlockArmBody(body: ast.Expr) bool {
    return body == .function and body.function.kind.syntax == .lambda and body.function.kind.params.len == 0;
}

/// Decision 8 §5.1 P3 — the arm body forms that are a lambda node: the block
/// arm (`_ -> { … }`, no parameter) and the decision-8 binder arm
/// (`i32 { n -> … }`, exactly one). Both are arm bodies, so both keep the
/// enclosing fn's return target.
fn isArmBodyLambda(body: ast.Expr) bool {
    if (body != .function or body.function.kind.syntax != .lambda) return false;
    return body.function.kind.params.len <= 1;
}

/// Infer an arm's body, binding a single-parameter binder arm's parameter to
/// the matched value's type (§5.1 P1/P5) instead of to a fresh variable.
fn inferCaseArmBody(
    env: *Env,
    arm: ast.CaseArm,
    typedSubjects: []const ast.TypedExpr,
) InferError!TypedExpr {
    const body = arm.body;
    const isBinderArm = body == .function and
        body.function.kind.syntax == .lambda and
        body.function.kind.params.len == 1;
    if (!isBinderArm or typedSubjects.len != 1) return inferExprTyped(env, body);
    // The subject **as this arm's pattern narrowed it** (§5.1 P1/P5). A type
    // pattern (`i32 { n -> … }`) makes the binder that type; every other
    // pattern leaves the subject's own, which is P5's answer for them — a
    // variant payload's own binding comes from the pattern instead, and
    // `bindCaseArmPatternNames` has already bound it.
    const subjectTy = typedSubjects[0].getType();
    const narrowed = (try typePatternType(env, arm.pattern, subjectTy)) orelse subjectTy;
    const expected = try env.funcType(&.{narrowed}, try env.freshVar());
    return inferFunctionExprExpected(env, body.function, body.getLoc(), expected, false);
}

/// C2a — the value an arm contributes to its `case`'s type, or null when it
/// contributes nothing: a jump arm, a `void` arm, a block arm without a
/// top-level `break <value>` (decision 2: a block's value comes from `break`).
fn caseArmValueType(env: *Env, body: ast.TypedExpr) InferError!?*T.Type {
    if (body == .jump) return null;
    // Decision 8 §5.1 P3 — `Pattern { body }` lands as the same lambda node the
    // older block arm produced, and the body **is** a lambda body: its last
    // expression is the arm's value. Only the `break` half was read, so
    // `0 { "zero" }` contributed nothing at all and the `case` typed `void`,
    // while `_ { n -> … }` was unified as a `function`.
    if (body == .function and body.function.kind.syntax == .lambda) {
        var found: ?*T.Type = null;
        for (body.function.kind.body) |stmt| {
            const e = stmt.expr;
            if (e != .jump) continue;
            switch (e.jump.kind) {
                // A `break <value>` names the arm's value explicitly and wins
                // over the tail; that is the block arm's own rule (06 C2a).
                .@"break" => |b| if (b.value) |v| {
                    if (found) |f| try unify(env, f, v.getType()) else found = v.getType();
                },
                else => {},
            }
        }
        if (found) |f| return f;
        const stmts = body.function.kind.body;
        if (stmts.len == 0) return null;
        const tail = stmts[stmts.len - 1].expr;
        // §3.2 — an arm whose body jumps (`return`/`throw`/`continue`) does not
        // contribute to the `case`'s type.
        if (tail == .jump) return null;
        return nonVoid(tail.getType());
    }
    return nonVoid(body.getType());
}

/// The type, unless it is `void` — a statement arm contributes nothing.
fn nonVoid(t: *T.Type) ?*T.Type {
    const d = t.deref();
    if (d.* == .named and std.mem.eql(u8, d.named.name, "void")) return null;
    return t;
}

/// Decision 8 §3 — add one member to a union under construction, flattening a
/// nested union (`(A | B) | C` is `A | B | C`) and dropping a duplicate. Union
/// membership is set-like: the members are what the value may be, and saying
/// one of them twice says nothing more.
fn appendUnionMember(
    env: *Env,
    into: *std.ArrayListUnmanaged(*T.Type),
    member: *T.Type,
) InferError!void {
    const m = member.deref();
    if (m.* == .union_) {
        for (m.union_) |inner| try appendUnionMember(env, into, inner);
        return;
    }
    // A variable inference has not decided is not a distinct alternative. It
    // joins whatever is already there instead of standing beside it, so a
    // union never carries a `?` member that says nothing.
    if (m.isUnbound() and into.items.len > 0) return unify(env, into.items[0], m);
    for (into.items) |existing| {
        if (sameTypeShape(existing, m)) return;
        if (existing.isUnbound()) return unify(env, existing, m);
    }
    try into.append(env.arena, m);
}

/// Decision 8 §3.2/§3.4 — finish a union that `appendUnionMember` has already
/// flattened and de-duplicated.
///
/// `?T` **absorbs**: a `null` branch makes the whole thing optional, so
/// `if (c) { 1 } else { null }` is `?i32` and not `i32 | ?_`. Recursively, that
/// is also §3.4's `Option<A> | Option<B>` → `Option<A | B>`.
///
/// No other head joins here. §3.4 also lists `Box`, `@Result` and `Dict`, but a
/// join is only sound when the type's parameter is **read** and never written:
/// joining `Box<i32> | Box<string>` into `Box<i32 | string>` would let a
/// `set(v: T)` store a `string` in what is really a `Box<i32>`. The "only read"
/// test is a member-signature walk this front has not built; until it exists
/// those members stay side by side, which refuses more than §3.4 and is never
/// wrong. Arrays never join at all — that is §3.4's own rule.
fn finishUnion(env: *Env, members: []*T.Type) InferError!*T.Type {
    if (members.len == 0) return env.namedType("void");
    if (members.len == 1) return members[0];
    for (members, 0..) |m, idx| {
        const d = m.deref();
        if (d.* != .named) continue;
        if (!std.mem.eql(u8, d.named.name, "optional") or d.named.args.len != 1) continue;
        var inner: std.ArrayListUnmanaged(*T.Type) = .empty;
        try appendUnionMember(env, &inner, d.named.args[0]);
        for (members, 0..) |other, j| {
            if (j != idx) try appendUnionMember(env, &inner, other);
        }
        // Each step consumes one optional member, so the recursion is finite.
        const innerTy = try finishUnion(env, inner.items);
        const args = try env.arena.alloc(*T.Type, 1);
        args[0] = innerTy;
        return env.namedTypeArgs("optional", args);
    }
    return env.unionType(try env.arena.dupe(*T.Type, members));
}

/// The union of `members`, flattened, de-duplicated and normalised.
fn unionOf(env: *Env, members: []const *T.Type) InferError!*T.Type {
    var flat: std.ArrayListUnmanaged(*T.Type) = .empty;
    for (members) |m| try appendUnionMember(env, &flat, m);
    return finishUnion(env, flat.items);
}

/// Two types are the same union member. Structural and conservative: it decides
/// membership, so it must never call two members the same when a value could
/// tell them apart, and it must not unify (a probe that mutated would leave the
/// failed alternative linked).
fn sameTypeShape(a: *T.Type, b: *T.Type) bool {
    const da = a.deref();
    const db = b.deref();
    if (da == db) return true;
    return switch (da.*) {
        .named => |na| switch (db.*) {
            .named => |nb| blk: {
                if (!std.mem.eql(u8, na.name, nb.name)) break :blk false;
                if (na.args.len != nb.args.len) break :blk false;
                for (na.args, nb.args) |x, y| {
                    if (!sameTypeShape(x, y)) break :blk false;
                }
                break :blk true;
            },
            else => false,
        },
        .func => |fa| switch (db.*) {
            .func => |fb| blk: {
                if (fa.params.len != fb.params.len) break :blk false;
                for (fa.params, fb.params) |x, y| {
                    if (!sameTypeShape(x, y)) break :blk false;
                }
                break :blk sameTypeShape(fa.ret, fb.ret);
            },
            else => false,
        },
        .union_ => |ua| switch (db.*) {
            .union_ => |ub| blk: {
                if (ua.len != ub.len) break :blk false;
                for (ua, ub) |x, y| {
                    if (!sameTypeShape(x, y)) break :blk false;
                }
                break :blk true;
            },
            else => false,
        },
        .record => |fa| switch (db.*) {
            .record => |fb| blk: {
                if (fa.len != fb.len) break :blk false;
                for (fa, fb) |x, y| {
                    if (!std.mem.eql(u8, x.name, y.name)) break :blk false;
                    if (!sameTypeShape(x.type_, y.type_)) break :blk false;
                }
                break :blk true;
            },
            else => false,
        },
        // Two distinct variables are not the same member: nothing has said so.
        .typeVar => false,
    };
}

/// C2a — unify the arms that agree; distinct named types become union members.
fn caseTypeFromArms(env: *Env, arms: []const ast.CaseArmOf(.typed)) InferError!*T.Type {
    var members: std.ArrayListUnmanaged(*T.Type) = .empty;
    for (arms) |arm| {
        const t = (try caseArmValueType(env, arm.body)) orelse continue;
        var merged = false;
        for (members.items) |m| {
            if (caseArmTypesAgree(m, t)) {
                try unify(env, m, t);
                merged = true;
                break;
            }
        }
        if (!merged) try members.append(env.arena, t);
    }
    return finishUnion(env, members.items);
}

/// Two arm types agree (and are unified) when either is still a type
/// variable or both name the same type constructor with the same arity.
fn caseArmTypesAgree(a: *T.Type, b: *T.Type) bool {
    const da = a.deref();
    const db = b.deref();
    if (da.* == .typeVar or db.* == .typeVar) return true;
    if (da.* == .named and db.* == .named) {
        return std.mem.eql(u8, da.named.name, db.named.name) and da.named.args.len == db.named.args.len;
    }
    return false;
}

/// Infer type for function definition expressions (lambdas and anonymous functions)
fn inferFunctionExpr(env: *Env, func: ast.FunctionExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return inferFunctionExprExpected(env, func, loc, null, false);
}

/// Infer a lambda / anonymous-function expression. When `expected` is a
/// function type (e.g. from a `val f: fn(A, B) -> R = ...` annotation, or a
/// `fn`-typed parameter), the lambda's parameters are bound to the expected
/// parameter types *before* the body is inferred — so the body can resolve
/// member calls and operators against the annotated types — and the body's
/// result is unified with the expected return type.
///
/// `params_only` keeps the parameter half and drops the return half: the
/// lambda's return type stays free. A caller that only wants the parameters
/// typed (a builtin-primitive method's declared signature — see
/// `primMethodParamTypes`) must use it, because a body whose every path
/// `return`s types its TAIL as void while the `return`s have already fixed the
/// return target, and unifying the two would red a correct lambda
/// (`xs.map({ x -> if (c) { return a; } else { return b; } })`).
fn inferFunctionExprExpected(
    env: *Env,
    func: ast.FunctionExprOf(.untyped),
    loc: ast.Loc,
    expected: ?*T.Type,
    params_only: bool,
) InferError!TypedExpr {
    // A nested function expression has no declared return type, so `throw`
    // inside it is not checked against the enclosing fn's `E`.
    const savedThrowCtx = env.throwContext;
    env.throwContext = .unchecked;
    defer env.throwContext = savedThrowCtx;

    // A nested function gets its own async/label scope: it does not inherit
    // the enclosing fn's `await`/`yield`/label context.
    const prevStarFn = env.starFn;
    const prevLabelsLen = env.labelStack.items.len;
    defer {
        env.starFn = prevStarFn;
        env.labelStack.shrinkRetainingCapacity(prevLabelsLen);
    }
    env.labelStack.shrinkRetainingCapacity(0);
    // A lambda body is another function: no loop of the enclosing body is
    // left by a `break` inside it (decision 105), and only a `case` arm's
    // block keeps the value-block scope it was opened in.
    const prevLoopDepth = env.loopDepth;
    const prevBreakScope = env.breakScope;
    env.loopDepth = 0;
    if (env.breakScope != .valueBlock) env.breakScope = .none;
    defer {
        env.loopDepth = prevLoopDepth;
        env.breakScope = prevBreakScope;
    }

    const fk = func.kind;
    // Anonymous function expressions never carry an effect annotation, so the
    // async/generator context is always cleared inside them. (The deprecated
    // `*fn(...)` anonymous-generator form was removed in v0.beta.19.)
    env.starFn = null;

    // Pull expected param/return types out of `expected`, but only when it is a
    // function type whose arity matches this lambda. This lets `val f: fn(A, B)
    // -> R = { a, b -> ... }` bind the params to A/B before the body is inferred.
    var expParams: ?[]*T.Type = null;
    var expRet: ?*T.Type = null;
    if (expected) |e| {
        const d = e.deref();
        if (d.* == .func and d.func.params.len == fk.params.len) {
            expParams = d.func.params;
            if (!params_only) expRet = d.func.ret;
        }
    }

    const params = try env.arena.alloc(*T.Type, fk.params.len);
    for (fk.params, 0..) |p, i| {
        params[i] = if (expParams) |ep| ep[i] else try env.freshVar();
        try env.bind(p, params[i]);
    }
    // C1 — a lambda's `return`s unify with the expected return type, or with
    // each other through a shared fresh var; it never inherits the enclosing
    // fn's return target.
    const savedReturnTarget = env.returnTarget;
    const savedReturnBareIsVoid = env.returnBareIsVoid;
    const savedReturnWhole = env.returnWhole;
    defer {
        env.returnTarget = savedReturnTarget;
        env.returnBareIsVoid = savedReturnBareIsVoid;
        env.returnWhole = savedReturnWhole;
    }
    // A `case` block arm keeps the enclosing fn's return target.
    const keep = env.keepReturnTarget;
    env.keepReturnTarget = false;
    if (!keep) {
        env.returnTarget = expRet orelse try env.freshVar();
        env.returnBareIsVoid = false;
        env.returnWhole = null;
    }
    const bodyTyped = try inferStmtsTyped(env, fk.body);
    // The lambda's return type is its tail expression's type; an explicit
    // `return expr` tail types as void, so use the returned value's type.
    const retType = if (bodyTyped.len > 0) blk: {
        const tail = bodyTyped[bodyTyped.len - 1].expr;
        if (tail == .jump and tail.jump.kind == .@"return") {
            break :blk if (tail.jump.kind.@"return") |rv| rv.getType() else try env.namedType("void");
        }
        break :blk tail.getType();
    } else try env.namedType("void");
    if (expRet) |er| try unifyAt(env, retType, er, loc);
    const funcType = try env.funcType(params, retType);
    return TypedExpr{ .function = .{ .loc = loc, .type_ = funcType, .kind = .{
        .syntax = fk.syntax,
        .params = fk.params,
        .body = bodyTyped,
    } } };
}

/// Infer type for collection expressions (arrays, tuples, ranges, case, block, grouped)
fn inferCollectionExpr(env: *Env, col: ast.CollectionExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (col.kind) {
        .arrayLit => |al| {
            // 00 · 01-checker — an expected `Array<T>` makes `T` the expected
            // type of every element (`val ts: Array<Token> = [.Color.Red.500];`).
            const elemExpected: ?*T.Type = blk: {
                const want = (env.expectedType orelse break :blk null).deref();
                if (want.* != .named) break :blk null;
                if (!std.mem.eql(u8, want.named.name, "array") and !std.mem.eql(u8, want.named.name, "Array")) break :blk null;
                if (want.named.args.len != 1) break :blk null;
                break :blk want.named.args[0];
            };
            const typedElems = try env.arena.alloc(ast.TypedExpr, al.elems.len);
            for (al.elems, 0..) |elem, i| {
                typedElems[i] = try inferExprTypedExpecting(env, elem, elemExpected);
            }
            const elemType = if (typedElems.len > 0) typedElems[0].getType() else try env.freshVar();
            for (typedElems) |elem| {
                try unify(env, elemType, elem.getType());
            }
            const arrayArgs = try env.arena.alloc(*T.Type, 1);
            arrayArgs[0] = elemType;
            const arrayType = try env.namedTypeArgs("array", arrayArgs);
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = arrayType, .kind = .{ .arrayLit = .{
                .elems = typedElems,
                .spread = al.spread,
                .spreadExpr = if (al.spreadExpr) |se| try makeTypedPtr(env, try inferExprTyped(env, se.*)) else null,
                .comments = al.comments,
                .commentsPerElem = al.commentsPerElem,
                .trailingComma = al.trailingComma,
            } } } };
        },

        .tupleLit => |tl| {
            const typedElems = try env.arena.alloc(ast.TypedExpr, tl.elems.len);
            const elemTypes = try env.arena.alloc(*T.Type, tl.elems.len);
            // Decision 8 §6 T1: an element that is a plain variable lends its
            // name as the element's label (`#(name, pop)`); others stay
            // unlabeled. A compiler-built literal (a lifted template value)
            // carries its labels already.
            const labels = try env.arena.alloc([]const u8, tl.elems.len);
            var anyLabel = false;
            for (tl.elems, 0..) |elem, i| {
                typedElems[i] = try inferExprTyped(env, elem);
                elemTypes[i] = typedElems[i].getType();
                labels[i] = if (tl.labels.len == tl.elems.len)
                    tl.labels[i]
                else if (elem == .identifier and elem.identifier.kind == .ident)
                    elem.identifier.kind.ident
                else
                    "";
                if (labels[i].len > 0) anyLabel = true;
            }
            const tupleType = try env.namedTypeArgs("tuple", elemTypes);
            if (anyLabel) tupleType.named.labels = labels;
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = tupleType, .kind = .{ .tupleLit = .{
                .elems = typedElems,
                .comments = tl.comments,
                .commentsPerElem = tl.commentsPerElem,
            } } } };
        },

        .range => |r| {
            const startTyped = try inferExprTyped(env, r.start.*);
            const startPtr = try makeTypedPtr(env, startTyped);
            const endPtr = if (r.end) |e| try makeTypedPtr(env, try inferExprTyped(env, e.*)) else null;
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = try env.namedType("Range"), .kind = .{ .range = .{
                .start = startPtr,
                .end = endPtr,
                .inclusive = r.inclusive,
            } } } };
        },

        .case => |c| {
            const typedSubjects = try env.arena.alloc(ast.TypedExpr, c.subjects.len);
            for (c.subjects, 0..) |subj, i| {
                typedSubjects[i] = try inferExprTyped(env, subj);
            }

            // Decision 54 — the optional's pattern form. `optionalNullCaseBinder`
            // validates the whole `case` when any arm is `null` and answers the
            // binder's name; `refuseVariantPatternOverOptional` refuses the
            // spelling the decision rejected. Both run before the arms are
            // typed, so a wrong shape reds at the shape rather than inside a
            // body that was never going to mean anything.
            const subjectTy: ?*T.Type = if (typedSubjects.len == 1) typedSubjects[0].getType() else null;
            var optionalBinder: ?[]const u8 = null;
            if (subjectTy) |st| {
                optionalBinder = try optionalNullCaseBinder(env, st, c.arms, loc);
                if (optionalBinder == null) try refuseVariantPatternOverOptional(env, st, c.arms);
            } else for (c.arms) |arm| {
                if (isNullPattern(arm.pattern)) {
                    env.lastError = TypeError.custom(
                        "`null` is a pattern only over an optional",
                        "`case x { null { … } v { … } }` matches one `?T` subject (decision 54).",
                    ).withLoc(arm.patternLoc);
                    return error.TypeError;
                }
            }

            const typedArms = try env.arena.alloc(ast.CaseArmOf(.typed), c.arms.len);
            // An arm's block takes `break <value>` as its value (decision 2).
            const prevBreakScope = env.breakScope;
            env.breakScope = .valueBlock;
            defer env.breakScope = prevBreakScope;
            for (c.arms, 0..) |arm, i| {
                var snapshots: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
                defer snapshots.deinit(env.arena);
                if (optionalBinder) |binder| {
                    // The binder is the payload, narrowed (decision 54): `v` is
                    // the `T` of the `?T`, not the optional itself. The `null`
                    // arm binds nothing.
                    if (i == 1 and binder.len > 0) {
                        try saveAndBindPatternName(env, &snapshots, binder, optionalInner(subjectTy.?).?);
                    }
                } else try bindCaseArmPatternNames(env, arm.pattern, typedSubjects, &snapshots);

                // A guard clause must type-check to a boolean, with the
                // pattern's bindings in scope.
                var guardTyped: ?ast.TypedExpr = null;
                if (arm.guard) |g| {
                    const gt = inferExprTyped(env, g) catch |err| {
                        try restorePatternBindings(env, snapshots.items);
                        return err;
                    };
                    unifyAt(env, gt.getType(), try env.namedType("bool"), g.getLoc()) catch |err| {
                        try restorePatternBindings(env, snapshots.items);
                        return err;
                    };
                    guardTyped = gt;
                }

                // A block arm (`_ -> { … }`) is a zero-param lambda in the AST,
                // but its `return`s leave the enclosing fn, not the block. So do
                // a decision-8 arm's: `{ n -> … }` is an arm body too, not a
                // function value the arm happens to produce.
                env.keepReturnTarget = isArmBodyLambda(arm.body);
                // §5.1 P1/P5 — `{ n -> … }` binds the WHOLE matched value,
                // already narrowed by this arm's pattern. Its parameter is not a
                // fresh variable: it is the subject. Passing it as the expected
                // parameter type binds it before the body is inferred, so the
                // body resolves methods and operators against the real type.
                const bodyTyped = inferCaseArmBody(env, arm, typedSubjects) catch |err| {
                    env.keepReturnTarget = false;
                    try restorePatternBindings(env, snapshots.items);
                    return err;
                };
                env.keepReturnTarget = false;
                try restorePatternBindings(env, snapshots.items);
                typedArms[i] = .{
                    .pattern = arm.pattern,
                    .body = bodyTyped,
                    .guard = guardTyped,
                    .emptyLinesBefore = arm.emptyLinesBefore,
                };
            }

            // A single-subject `case` on an enum or string must cover every
            // possibility (or carry a wildcard), and no arm may be unreachable.
            // Decision 54's form covers its `?T` by construction — `null` and a
            // binder are the two halves of an optional — and its `null` arm is
            // not a catch-all, so the walk would read it as uncovered.
            if (typedSubjects.len == 1 and optionalBinder == null) {
                try checkCaseArmArity(env, typedSubjects[0].getType(), c.arms);
                try checkCaseExhaustiveness(env, typedSubjects[0].getType(), c.arms, loc);
            }
            if (optionalBinder) |binder| try env.optionalNullCases.put(loc, binder);
            // C2a — the `case` is typed from its arms: arms that agree unify,
            // arms of different types make a union (decision 8 §3.2). A jump arm
            // (`return`/`throw`/`break`/`continue`) and a statement arm (`void`, a
            // block without `break <value>`) contribute nothing.
            const caseType = try caseTypeFromArms(env, typedArms);
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = caseType, .kind = .{ .case = .{
                .subjects = typedSubjects,
                .arms = typedArms,
                .trailingComments = c.trailingComments,
            } } } };
        },

        .grouped => |e| {
            return try inferExprTyped(env, e.*);
        },

        .behaviorLit => |il| {
            // Interface literal: @InterfaceName(field: value, …).
            // Each field is typed independently; the result type is the named interface.
            const typedFields = try env.arena.alloc(ast.RecordLitFieldOf(.typed), il.fields.len);
            for (il.fields, 0..) |f, i| {
                const typedValue = try inferExprTyped(env, f.value.*);
                typedFields[i] = .{ .name = f.name, .value = try makeTypedPtr(env, typedValue) };
            }
            const ifaceTy = try env.namedType(il.name);
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = ifaceTy, .kind = .{ .behaviorLit = .{
                .name = il.name,
                .fields = typedFields,
            } } } };
        },
    };
}

/// Infer type for comptime expressions (comptime, assert, assertPattern).
fn inferComptimeExpr(env: *Env, ct: ast.ComptimeExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (ct.kind) {
        .comptimeExpr => |e| {
            const typed = try inferExprTyped(env, e.*);
            const typedPtr = try makeTypedPtr(env, typed);
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = typed.getType(), .kind = .{ .comptimeExpr = typedPtr } } };
        },

        .comptimeBlock => |cb| {
            const prevBreakScope = env.breakScope;
            env.breakScope = .valueBlock;
            defer env.breakScope = prevBreakScope;
            const typedBody = try inferStmtsTyped(env, cb.body);
            // C2b — a `comptime { … }` block's value is its `break <value>`
            // (`eval.zig` `blockValue`'s rule), `void` when there is none.
            const bodyType = blk: {
                var found: ?*T.Type = null;
                for (typedBody) |st| {
                    if (st.expr != .jump) continue;
                    switch (st.expr.jump.kind) {
                        .@"break" => |b| if (b.value) |v| {
                            if (found) |f| try unifyAt(env, f, v.getType(), v.getLoc()) else found = v.getType();
                        },
                        else => {},
                    }
                }
                break :blk found orelse try env.namedType("void");
            };
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = bodyType, .kind = .{ .comptimeBlock = .{
                .body = typedBody,
            } } } };
        },

        .assert => |a| {
            const condTyped = try inferExprTyped(env, a.condition.*);
            // The asserted condition must be a bool.
            try unifyAt(env, try env.namedType("bool"), condTyped.getType(), a.condition.getLoc());
            const condPtr = try makeTypedPtr(env, condTyped);
            const msgPtr = if (a.message) |msg| try makeTypedPtr(env, try inferExprTyped(env, msg.*)) else null;
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .assert = .{
                .condition = condPtr,
                .message = msgPtr,
            } } } };
        },

        .assertPattern => |ap| {
            // 06 C12 — the subject and the handler are inferred like any other
            // expression. Both used to swallow `error.TypeError` into a fresh
            // type variable, so `val assert 42 = answer catch 0;` compiled with
            // `answer` bound to nothing and only aborted at run time.
            const exprTyped = try inferExprTyped(env, ap.expr.*);
            const exprPtr = try makeTypedPtr(env, exprTyped);
            // Decision 8 § 9 — the pattern has to be able to match the
            // subject. This is what makes
            // `val assert Ok(n) = parse("42") catch 0;` the error the
            // decision writes: after `catch` the value is an `i32`, and
            // `Ok(…)` names no variant of it.
            try checkAssertPatternSubject(env, ap.pattern, exprTyped.getType(), ap.expr.getLoc(), ap.fatal, ap.catchLoc);
            // Decision 8 § 9 — the pattern's names are bound in the ENCLOSING
            // scope (`val assert Ok(n) = parse("42"); @print(n);`), so the
            // snapshots a case arm would restore are deliberately dropped.
            var bound: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
            try bindPatternNamesForSubject(env, ap.pattern, exprTyped.getType(), &bound);
            const handlerExpr = ap.handler.*;
            const handlerTyped = try inferExprTyped(env, handlerExpr);
            const handlerPtr = try makeTypedPtr(env, handlerTyped);
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = exprTyped.getType(), .kind = .{ .assertPattern = .{
                .pattern = ap.pattern,
                .expr = exprPtr,
                .handler = handlerPtr,
                .fatal = ap.fatal,
            } } } };
        },
    };
}

pub fn freshEnv(a: std.mem.Allocator, gpa: std.mem.Allocator) !Env {
    // Lazy-init a process-lifetime template (parses + infers stdlib ONCE)
    // and clone its hashmaps onto the per-test env. The full `registerStdlib`
    // path used to run on every call — ~83ms — even though stdlib never
    // changes between calls. Cloning the populated hashmaps is ~µs and
    // produces a byte-equivalent env (modulo arena ownership: `*Type`
    // pointers still reference the template's process-lifetime arena).
    const tmpl = try comptimeMod.getStdlibTemplate(gpa);
    return Env.cloneFromTemplate(tmpl, a);
}
