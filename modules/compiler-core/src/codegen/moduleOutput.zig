const std = @import("std");
const comptimeMod = @import("../comptime.zig");

/// The located error that stopped a module before codegen: it did not lex or
/// parse (`syntax`), or did not type-check (`type`). Owned by its
/// `GenerateResult` — the comptime session that produced it is freed before a
/// driver reads it, so every slice is copied (a type error is rendered to its
/// message here, while its types are still alive).
pub const Diagnostic = union(enum) {
    syntax: comptimeMod.SyntaxError,
    type: TypeDiagnostic,

    pub const TypeDiagnostic = struct {
        message: []u8,
        loc: @FieldType(comptimeMod.TypeError, "loc"),
    };

    /// The owned diagnostic of a `.parseError` or `.typeError` outcome; null
    /// for any other outcome.
    pub fn of(allocator: std.mem.Allocator, outcome: comptimeMod.ComptimeOutput.Outcome) !?Diagnostic {
        return switch (outcome) {
            .parseError => |se| .{ .syntax = switch (se) {
                .lex => se,
                .parse => |info| .{ .parse = if (info) |i| blk: {
                    var copy = i;
                    copy.lexeme = try allocator.dupe(u8, i.lexeme);
                    errdefer allocator.free(copy.lexeme);
                    copy.detail = if (i.detail) |d| try allocator.dupe(u8, d) else null;
                    break :blk copy;
                } else null },
            } },
            .typeError => |te| .{ .type = .{ .message = try te.message(allocator), .loc = te.loc } },
            .ok, .validationError => null,
        };
    }

    pub fn deinit(self: *Diagnostic, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .syntax => |se| switch (se) {
                .lex => {},
                .parse => |info| if (info) |i| {
                    allocator.free(i.lexeme);
                    if (i.detail) |d| allocator.free(d);
                },
            },
            .type => |t| allocator.free(t.message),
        }
    }
};

/// The host-backed fn a backend could not lower: it carries no
/// `#[@External.<Target>(…)]` for the target being emitted. Every backend that
/// raises `error.MissingExternalTarget` fills one first, so the failure reaches
/// the driver as a LOCATED diagnostic naming the function and the target
/// instead of the bare error name (06 C13).
/// A bare variant name more than one enum of the program declares, written
/// where nothing says which enum is meant. The emit refuses instead of tagging
/// it with one of the two: decision 21 gives every variant its enum's module in
/// its atom, so picking the wrong enum is a value no `case` over the right one
/// can match (`case_clause` at run time, measured), and the WRITER is the only
/// one who knows which was meant.
pub const AmbiguousVariant = struct {
    /// The bare variant name (`Circle`).
    variant: []const u8,
    /// Two of the enums declaring it.
    a: []const u8,
    b: []const u8,

    pub fn diagnostic(self: AmbiguousVariant, allocator: std.mem.Allocator) !Diagnostic {
        return .{ .type = .{
            .message = try std.fmt.allocPrint(
                allocator,
                "`{s}` is a variant of `{s}` and of `{s}`, and nothing here says which — write `{s}.{s}` or `{s}.{s}`",
                .{ self.variant, self.a, self.b, self.a, self.variant, self.b, self.variant },
            ),
            .loc = null,
        } };
    }
};

pub const MissingExternal = struct {
    /// The called function's name.
    name: []const u8,
    /// The backend that has no target for it (`erlang`, `node`, `beam`).
    target: []const u8,
    /// The call site.
    loc: @FieldType(comptimeMod.TypeError, "loc") = null,
    /// Set when the target exists but its `#[@External.Erlang]` template does
    /// not compile for the beam backend: the construct the reader or the
    /// lowering refused, by name (decision 140).
    refusal: ?[]const u8 = null,

    /// This as the diagnostic a failed module carries. The message is owned by
    /// `allocator`, like every other `Diagnostic.type`.
    pub fn diagnostic(self: MissingExternal, allocator: std.mem.Allocator) !Diagnostic {
        if (self.refusal) |why| return .{ .type = .{
            .message = try std.fmt.allocPrint(
                allocator,
                "`{s}`'s `#[@External.Erlang(…)]` template does not compile for the {s} backend: {s}",
                .{ self.name, self.target, why },
            ),
            .loc = self.loc,
        } };
        return .{ .type = .{
            .message = try std.fmt.allocPrint(
                allocator,
                "`{s}` has no `#[@External.<Target>(…)]` for the {s} backend",
                .{ self.name, self.target },
            ),
            .loc = self.loc,
        } };
    }
};

/// One EXTRA module a source file produced on a BEAM target — policy 3 of
/// `13-module-identity`: every `type` declared in a file is its own erlang/BEAM
/// module, named by `crossModule.typeAtom` (`app@models@@Person`, decision 109), holding
/// the type's methods. `atom` is the rendered module atom, which is also the
/// artifact's basename (`out/erl/<atom>.erl`, `out/beam/<atom>.S`); `code` is
/// the module's text in the target's language. Both owned by the
/// `GenerateResult`. commonJS and wasm produce none: a class already is the
/// type's identity there (decision 5), and wasm is single-module.
pub const Unit = struct {
    atom: []u8,
    code: []u8,
};

/// Final per-module output after all pipeline stages.
/// `js` and `comptime_script` are heap-allocated; call `deinit` when done.
/// `comptime_err` is set (and `js` is empty) when comptime validation failed.
/// `run_output` contains stdout/stderr from executing the generated code.
pub const GenerateResult = struct {
    js: []u8,
    typedef: ?[]u8 = null,
    /// The per-`type` modules beside the file's own (`Unit`); empty on commonJS
    /// and wasm. Written, compiled and loaded wherever `js` is.
    units: []Unit = &.{},
    comptime_script: ?[]u8,
    /// The binary module of a `wasm`-target output (`js` is its `.wat` text);
    /// null on the other targets. Rendered from the same model as the text
    /// (`wat/wasm_binary_emitter.zig`), so the two cannot disagree.
    wasm: ?[]u8 = null,
    /// `COMPTIME ERLANG` / `COMPTIME REPLY` sections of the module's decorator
    /// and template evaluations (`comptime/trace.zig`), null when there are none.
    comptime_trace: ?[]u8 = null,
    comptime_err: ?comptimeMod.ComptimeError = null,
    /// Set (and `js` is empty) when the module did not lex, parse or type-check.
    diagnostic: ?Diagnostic = null,
    run_output: ?[]u8 = null,

    /// The module produced no artifact: a comptime validation error or a
    /// lex/parse/type diagnostic.
    pub fn failed(self: GenerateResult) bool {
        return self.comptime_err != null or self.diagnostic != null;
    }

    pub fn deinit(self: *GenerateResult, allocator: std.mem.Allocator) void {
        allocator.free(self.js);
        for (self.units) |u| {
            allocator.free(u.atom);
            allocator.free(u.code);
        }
        if (self.units.len > 0) allocator.free(self.units);
        if (self.typedef) |t| allocator.free(t);
        if (self.comptime_script) |s| allocator.free(s);
        if (self.wasm) |w| allocator.free(w);
        if (self.comptime_trace) |s| allocator.free(s);
        if (self.run_output) |o| allocator.free(o);
        if (self.diagnostic) |*d| d.deinit(allocator);
    }
};

/// One entry in the list returned by `codegen.generate`.
/// `src` is a borrowed reference to the caller-owned `Module.source`.
/// `result` is owned; call `result.deinit(allocator)` when done.
pub const ModuleOutput = struct {
    name: []const u8,
    src: []const u8,
    result: GenerateResult,

    /// The entry of a module whose outcome is `.parseError` or `.typeError`:
    /// no artifact, the diagnostic that stopped it. Every backend's
    /// `codegenEmit` appends one instead of skipping the module.
    pub fn failedModule(allocator: std.mem.Allocator, ct: comptimeMod.ComptimeOutput) !ModuleOutput {
        const js = try allocator.dupe(u8, "");
        errdefer allocator.free(js);
        return .{
            .name = ct.name,
            .src = ct.src,
            .result = .{
                .js = js,
                .comptime_script = null,
                .diagnostic = try Diagnostic.of(allocator, ct.outcome),
            },
        };
    }
};
