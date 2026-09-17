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

/// Final per-module output after all pipeline stages.
/// `js` and `comptime_script` are heap-allocated; call `deinit` when done.
/// `comptime_err` is set (and `js` is empty) when comptime validation failed.
/// `run_output` contains stdout/stderr from executing the generated code.
pub const GenerateResult = struct {
    js: []u8,
    typedef: ?[]u8 = null,
    comptime_script: ?[]u8,
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
        if (self.typedef) |t| allocator.free(t);
        if (self.comptime_script) |s| allocator.free(s);
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
