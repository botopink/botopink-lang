const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const tsEmit = @import("./typescript.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;

// ── public phase 2: codegen ───────────────────────────────────────────────────

/// Emit JavaScript for each module in `outputs`.
///
/// Frees `comptime_vals` and transfers ownership of `comptime_script`
/// into each `ModuleOutput.result`. Call `ComptimeSession.deinit` after this.
pub fn codegenEmit(
    allocator: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .validationError => |verr| {
                try results.append(allocator, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try allocator.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                const js = try emitJs(allocator, ok.transformed, ok.comptime_vals);

                // Generate TypeScript typedefs if configured.
                const typedef: ?[]u8 = if (config.typeDefLanguage) |_|
                    try emitTypeDef(allocator, ok.bindings)
                else
                    null;

                try results.append(allocator, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = js,
                        .typedef = typedef,
                        .comptime_script = if (ok.comptime_script) |s| try allocator.dupe(u8, s) else null,
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

fn emitJs(
    allocator: std.mem.Allocator,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
) ![]u8 {
    return try emitProgram(allocator, program, comptime_vals);
}

fn emitTypeDef(
    allocator: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
) ![]u8 {
    return try tsEmit.emitProgram(allocator, bindings);
}

// ── emit ──────────────────────────────────────────────────────────────────────

/// Zig-native JavaScript emitter for botopink.
///
/// Converts typed bindings directly to JavaScript source — no JSON
/// intermediate, no Node.js pipeline.  Comptime expression values
/// (pre-evaluated by running Node.js and capturing stdout) are injected
/// via `comptime_vals`.
// ── public surface ────────────────────────────────────────────────────────────

/// Returns true when the top-level typed expression is a comptime node.
pub fn isComptimeExpr(te: ast.TypedExpr) bool {
    return switch (te.kind) {
        .@"comptime", .comptimeBlock => true,
        else => false,
    };
}

/// Emit all declarations as JavaScript source.
///
/// `comptime_vals` maps IDs such as `"ct_0"` to pre-evaluated JS literal
/// strings such as `"6.28"`.
///
/// The `program` is the transformed AST with specialized functions already
/// injected as regular FnDecl nodes. The emitter just renders what it sees.
pub fn emitProgram(
    allocator: std.mem.Allocator,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    var em = Emitter.emitterInit(allocator, &aw.writer, comptime_vals);
    defer em.deinit();

    // Track which val names are comptime-only (consumed at compile time).
    var comptime_only = std.StringHashMap(void).init(allocator);
    defer comptime_only.deinit();

    // Map val_name → ct_id so we can emit resolved comptime values.
    // The ct_{N} ID comes from the binding index in the original bindings list.
    // Val and fn decls each consume one binding slot.
    var val_ct_map = std.StringHashMap([]const u8).init(allocator);
    defer {
        var it = val_ct_map.iterator();
        while (it.next()) |kv| allocator.free(kv.value_ptr.*);
        val_ct_map.deinit();
    }
    {
        var binding_idx: usize = 0;
        for (program.decls) |decl| {
            switch (decl) {
                .val => |v| {
                    if (isComptimeVal(v)) {
                        try comptime_only.put(v.name, {});
                        const ct_id = try std.fmt.allocPrint(allocator, "ct_{d}", .{binding_idx});
                        try val_ct_map.put(v.name, ct_id);
                    }
                    binding_idx += 1;
                },
                .@"fn" => binding_idx += 1,
                else => {},
            }
        }
    }

    // Emit declarations from the transformed program.
    var firstEmitted = true;
    for (program.decls) |decl| {
        switch (decl) {
            .val => |v| {
                if (comptime_only.contains(v.name)) {
                    // Emit resolved comptime value if available.
                    if (val_ct_map.get(v.name)) |ct_id| {
                        if (comptime_vals.get(ct_id)) |lit| {
                            if (!firstEmitted) try aw.writer.writeByte('\n');
                            try em.fmt("const {s} = {s};", .{ v.name, lit });
                            try aw.writer.writeByte('\n');
                            firstEmitted = false;
                        }
                    }
                    continue;
                }
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitValDecl(v);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .@"fn" => |f| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitFn(f);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .@"struct" => |s| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitStruct(s);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .record => |r| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitRecord(r);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .@"enum" => |e| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitEnum(e);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .interface => |i| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitInterface(i);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .implement => |im| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitImplement(im);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .use => |u| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitUse(u);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .delegate => |d| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.fmt("// delegate {s}", .{d.name});
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
        }
    }

    return aw.toOwnedSlice();
}

fn isComptimeVal(v: ast.ValDecl) bool {
    return switch (v.value.kind) {
        .@"comptime", .comptimeBlock => true,
        else => false,
    };
}

// ── emitter ───────────────────────────────────────────────────────────────────

/// Chainable JS code builder with automatic indentation.
///
/// Usage:
///   b.line("(() => {{"); b.indent(); b.newline();
///   b.line("const x = 1;"); b.newline();
///   b.open("if (x === 1)"); b.indent();
///   b.line("return x;"); b.newline();
///   b.close(); b.dedent();
///   b.line("})()");
const JsBuilder = struct {
    out: *std.Io.Writer,
    alloc: std.mem.Allocator,
    indent_level: usize = 0,
    tab: []const u8 = "    ",

    pub fn init(alloc: std.mem.Allocator, out: *std.Io.Writer) JsBuilder {
        return .{ .out = out, .alloc = alloc };
    }

    pub fn line(self: *JsBuilder, text: []const u8) void {
        for (0..self.indent_level) |_| self.out.writeAll(self.tab) catch {};
        self.out.writeAll(text) catch {};
    }
    pub fn fmtLine(self: *JsBuilder, comptime f: []const u8, args: anytype) void {
        for (0..self.indent_level) |_| self.out.writeAll(self.tab) catch {};
        self.out.print(f, args) catch {};
    }
    pub fn newline(self: *JsBuilder) void {
        self.out.writeByte('\n') catch {};
    }
    pub fn raw(self: *JsBuilder, text: []const u8) void {
        self.out.writeAll(text) catch {};
    }
    pub fn indent(self: *JsBuilder) void {
        self.indent_level += 1;
    }
    pub fn dedent(self: *JsBuilder) void {
        if (self.indent_level > 0) self.indent_level -= 1;
    }
    /// Write indent based on current level.
    pub fn writeIndent(self: *JsBuilder) void {
        for (0..self.indent_level) |_| self.out.writeAll(self.tab) catch {};
    }
    pub fn open(self: *JsBuilder, cond: []const u8) void {
        if (cond.len > 0) {
            self.fmtLine("if ({s}) {{", .{cond});
        } else {
            self.line("{");
        }
        self.newline();
        self.indent();
    }
    pub fn close(self: *JsBuilder) void {
        self.dedent();
        self.line("}");
    }
};

const Emitter = struct {
    out: *std.Io.Writer,
    alloc: std.mem.Allocator,
    cv: std.StringHashMap([]const u8),
    current_indent: usize = 0,

    fn emitterInit(
        alloc: std.mem.Allocator,
        out: *std.Io.Writer,
        cv: std.StringHashMap([]const u8),
    ) Emitter {
        return Emitter{
            .out = out,
            .alloc = alloc,
            .cv = cv,
        };
    }

    fn deinit(self: *Emitter) void {
        _ = self;
    }

    fn w(self: *Emitter, s: []const u8) !void {
        try self.out.writeAll(s);
    }
    fn fmt(self: *Emitter, comptime f: []const u8, args: anytype) !void {
        try self.out.print(f, args);
    }

    fn emitValDecl(self: *Emitter, v: ast.ValDecl) !void {
        if (isComptimeVal(v)) {
            // Will be handled via comptime_vals lookup at a higher level.
            return;
        }
        try self.fmt("const {s} = ", .{v.name});
        try self.emitExpr(v.value.*);
        try self.w(";");
    }

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        try self.fmt("function {s}(", .{f.name});
        try self.emitParams(f.params);
        try self.w(") {\n");
        const prev_fn_indent = self.current_indent;
        self.current_indent = 1;
        for (f.body) |s| {
            try self.w("    ");
            try self.emitStmt(s);
            try self.w("\n");
        }
        self.current_indent = prev_fn_indent;
        try self.w("}");
        if (f.isPub) try self.fmt("\nexports.{s} = {s};", .{ f.name, f.name });
    }

    fn emitStruct(self: *Emitter, s: ast.StructDecl) !void {
        try self.fmt("class {s} {{\n", .{s.name});
        for (s.members) |m| switch (m) {
            .field => |f| {
                try self.fmt("    {s}", .{f.name});
                if (f.init) |init| {
                    try self.w(" = ");
                    try self.emitExpr(init);
                }
                try self.w(";\n");
            },
            else => {},
        };
        for (s.members) |m| switch (m) {
            .field => {},
            .getter => |g| {
                try self.w("\n");
                try self.fmt("    get {s}() {{\n", .{g.name});
                self.current_indent = 2;
                for (g.body) |st| {
                    try self.w("        ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                self.current_indent = 0;
                try self.w("    }\n");
            },
            .setter => |sg| {
                try self.w("\n");
                const vp = for (sg.params) |p| {
                    if (!std.mem.eql(u8, p.name, "self")) break p.name;
                } else "value";
                try self.fmt("    set {s}({s}) {{\n", .{ sg.name, vp });
                self.current_indent = 2;
                for (sg.body) |st| {
                    try self.w("        ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                self.current_indent = 0;
                try self.w("    }\n");
            },
            .method => |m2| {
                if (m2.is_declare) continue;
                try self.w("\n");
                try self.fmt("    {s}(", .{m2.name});
                try self.emitParams(m2.params);
                try self.w(") {\n");
                self.current_indent = 2;
                for (m2.body orelse &.{}) |st| {
                    try self.w("        ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                self.current_indent = 0;
                try self.w("    }\n");
            },
        };
        try self.w("}");
    }

    fn emitRecord(self: *Emitter, r: ast.RecordDecl) !void {
        try self.fmt("class {s} {{\n", .{r.name});
        if (r.fields.len > 0) {
            try self.w("    constructor(");
            for (r.fields, 0..) |f, i| {
                if (i > 0) try self.w(", ");
                try self.w(f.name);
            }
            try self.w(") {\n");
            for (r.fields) |f| try self.fmt("        this.{s} = {s};\n", .{ f.name, f.name });
            try self.w("    }\n");
        }
        for (r.methods) |m| {
            if (m.is_declare) continue;
            try self.w("\n");
            try self.fmt("    {s}(", .{m.name});
            try self.emitParams(m.params);
            try self.w(") {\n");
            self.current_indent = 2;
            for (m.body orelse &.{}) |st| {
                try self.w("        ");
                try self.emitStmt(st);
                try self.w("\n");
            }
            self.current_indent = 0;
            try self.w("    }\n");
        }
        try self.w("}");
    }

    fn emitEnum(self: *Emitter, e: ast.EnumDecl) !void {
        try self.fmt("const {s} = Object.freeze({{\n", .{e.name});
        for (e.variants) |v| {
            if (v.fields.len == 0) {
                try self.fmt("    {s}: \"{s}\",\n", .{ v.name, v.name });
            } else {
                try self.fmt("    {s}: (", .{v.name});
                for (v.fields, 0..) |f, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(f.name);
                }
                try self.fmt(") => ({{ tag: \"{s}\"", .{v.name});
                for (v.fields) |f| try self.fmt(", {s}", .{f.name});
                try self.w(" }),\n");
            }
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            try self.fmt("    {s}: function(", .{m.name});
            try self.emitParams(m.params);
            try self.w(") {\n");
            self.current_indent = 2;
            for (m.body orelse &.{}) |st| {
                try self.w("        ");
                try self.emitStmt(st);
                try self.w("\n");
            }
            self.current_indent = 0;
            try self.w("    },\n");
        }
        try self.w("});");
    }

    fn emitInterface(self: *Emitter, i: ast.InterfaceDecl) !void {
        if (i.extends.len > 0) {
            try self.fmt("// interface {s} extends ", .{i.name});
            for (i.extends, 0..) |ext, j| {
                if (j > 0) try self.w(", ");
                try self.w(ext);
            }
        } else {
            try self.fmt("// interface {s}", .{i.name});
        }
        for (i.fields) |f| try self.fmt("\n//   {s}: {s}", .{ f.name, f.typeName });
        for (i.methods) |m| {
            if (m.is_default) {
                try self.fmt("\n//   default fn {s}(...)", .{m.name});
            } else {
                try self.fmt("\n//   fn {s}(...)", .{m.name});
            }
        }
    }

    fn emitImplement(self: *Emitter, im: ast.ImplementDecl) !void {
        try self.w("// implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try self.w(", ");
            try self.w(iface);
        }
        try self.fmt(" for {s}", .{im.target});
        for (im.methods) |m| {
            try self.w("\n");
            try self.fmt("{s}.prototype.{s} = function(", .{ im.target, m.name });
            var first = true;
            for (m.params) |p| {
                if (std.mem.eql(u8, p.name, "self")) continue;
                if (!first) try self.w(", ");
                try self.emitParam(p);
                first = false;
            }
            try self.w(") {\n");
            self.current_indent = 1;
            for (m.body) |st| {
                try self.w("    ");
                try self.emitStmt(st);
                try self.w("\n");
            }
            self.current_indent = 0;
            try self.w("};");
        }
    }

    fn emitUse(self: *Emitter, u: ast.UseDecl) !void {
        try self.w("const { ");
        for (u.imports, 0..) |name, i| {
            if (i > 0) try self.w(", ");
            try self.w(name);
        }
        try self.w(" } = ");
        switch (u.source) {
            .stringPath => |p| {
                try self.w("require(\"./");
                try self.w(p);
                try self.w(".js\");");
            },
            .functionCall => |name| try self.fmt("require({s}());", .{name}),
        }
    }

    // ── params ────────────────────────────────────────────────────────────────

    fn emitParams(self: *Emitter, params: []const ast.Param) !void {
        var first = true;
        for (params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            if (!first) try self.w(", ");
            try self.emitParam(p);
            first = false;
        }
    }

    fn emitParam(self: *Emitter, p: ast.Param) !void {
        if (p.destruct) |d| switch (d) {
            .record_ => |names| {
                try self.w("{ ");
                for (names, 0..) |n, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(n);
                }
                try self.w(" }");
            },
            .tuple_ => |names| {
                try self.w("[");
                for (names, 0..) |n, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(n);
                }
                try self.w("]");
            },
        } else try self.w(p.name);
    }

    // ── statements ──────────────────────────────────────────────────────────────

    fn emitStmt(self: *Emitter, stmt: ast.Stmt) anyerror!void {
        const e = stmt.expr;
        switch (e.kind) {
            .localBind => |lb| {
                const kw: []const u8 = if (lb.mutable) "let" else "const";
                try self.fmt("{s} {s} = ", .{ kw, lb.name });
                try self.emitExpr(lb.value.*);
                try self.w(";");
            },
            .localBindDestruct => |lb| {
                const kw: []const u8 = if (lb.mutable) "let" else "const";
                switch (lb.pattern) {
                    .record_ => |ns| {
                        try self.fmt("{s} {{ ", .{kw});
                        for (ns, 0..) |n, i| {
                            if (i > 0) try self.w(", ");
                            try self.w(n);
                        }
                        try self.w(" } = ");
                    },
                    .tuple_ => |ns| {
                        try self.fmt("{s} [", .{kw});
                        for (ns, 0..) |n, i| {
                            if (i > 0) try self.w(", ");
                            try self.w(n);
                        }
                        try self.w("] = ");
                    },
                }
                try self.emitExpr(lb.value.*);
                try self.w(";");
            },
            .@"return" => |r| {
                try self.w("return ");
                try self.emitExpr(r.*);
                try self.w(";");
            },
            .fieldAssign => |sfa| {
                if (sfa.receiver.kind == .ident and std.mem.eql(u8, sfa.receiver.kind.ident, "self")) {
                    try self.fmt("this.{s} = ", .{sfa.field});
                } else {
                    try self.emitExpr(sfa.receiver.*);
                    try self.fmt(".{s} = ", .{sfa.field});
                }
                try self.emitExpr(sfa.value.*);
                try self.w(";");
            },
            .fieldPlusEq => |sfpe| {
                if (sfpe.receiver.kind == .ident and std.mem.eql(u8, sfpe.receiver.kind.ident, "self")) {
                    try self.fmt("this.{s} += ", .{sfpe.field});
                } else {
                    try self.emitExpr(sfpe.receiver.*);
                    try self.fmt(".{s} += ", .{sfpe.field});
                }
                try self.emitExpr(sfpe.value.*);
                try self.w(";");
            },
            else => {
                try self.emitExpr(e);
                try self.w(";");
            },
        }
    }

    /// Emit the last stmt of an if-branch as a value expression.
    fn emitIfLast(self: *Emitter, stmt: ast.Stmt) !void {
        switch (stmt.expr.kind) {
            .@"return", .throw_ => try self.emitStmt(stmt),
            else => {
                try self.w("return ");
                try self.emitExpr(stmt.expr);
                try self.w(";");
            },
        }
    }

    // ── expressions (generic over phase) ─────────────────────────────────────

    fn emitExpr(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e.kind) {
            .numberLit => |n| try self.w(n),
            .stringLit => |s| try self.emitJsonString(s),
            .null_ => try self.w("null"),
            .ident => |n| try self.w(n),
            .identAccess => |ia| {
                if (ia.receiver.kind == .ident) {
                    const recv_name = ia.receiver.kind.ident;
                    if (std.mem.eql(u8, recv_name, "self")) {
                        try self.fmt("this.{s}", .{ia.member});
                        return;
                    }
                }
                try self.emitExpr(ia.receiver.*);
                try self.fmt(".{s}", .{ia.member});
            },
            .dotIdent => |n| try self.w(n),
            .todo => try self.w("(() => { throw new Error(\"not implemented\") })()"),

            .add => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" + ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .sub => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" - ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .mul => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" * ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .div => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" / ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .mod => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" % ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .lt => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" < ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .gt => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" > ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .lte => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" <= ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .gte => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" >= ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .eq => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" === ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },
            .ne => |b| {
                try self.w("(");
                try self.emitExpr(b.lhs.*);
                try self.w(" !== ");
                try self.emitExpr(b.rhs.*);
                try self.w(")");
            },

            .@"return" => |r| {
                try self.w("return ");
                try self.emitExpr(r.*);
            },
            .throw_ => |r| {
                try self.w("throw ");
                try self.emitExpr(r.*);
            },

            .fieldAssign => |sfa| {
                if (sfa.receiver.kind == .ident and std.mem.eql(u8, sfa.receiver.kind.ident, "self")) {
                    try self.fmt("this.{s} = ", .{sfa.field});
                } else {
                    try self.emitExpr(sfa.receiver.*);
                    try self.fmt(".{s} = ", .{sfa.field});
                }
                try self.emitExpr(sfa.value.*);
            },
            .fieldPlusEq => |sfpe| {
                if (sfpe.receiver.kind == .ident and std.mem.eql(u8, sfpe.receiver.kind.ident, "self")) {
                    try self.fmt("this.{s} += ", .{sfpe.field});
                } else {
                    try self.emitExpr(sfpe.receiver.*);
                    try self.fmt(".{s} += ", .{sfpe.field});
                }
                try self.emitExpr(sfpe.value.*);
            },

            .localBind => |lb| {
                const kw: []const u8 = if (lb.mutable) "let" else "const";
                try self.fmt("{s} {s} = ", .{ kw, lb.name });
                try self.emitExpr(lb.value.*);
            },
            .assign => |a| {
                try self.fmt("{s} = ", .{a.name});
                try self.emitExpr(a.value.*);
            },
            .localBindDestruct => |lb| {
                const kw: []const u8 = if (lb.mutable) "let" else "const";
                switch (lb.pattern) {
                    .record_ => |ns| {
                        try self.fmt("{s} {{ ", .{kw});
                        for (ns, 0..) |n, i| {
                            if (i > 0) try self.w(", ");
                            try self.w(n);
                        }
                        try self.w(" } = ");
                    },
                    .tuple_ => |ns| {
                        try self.fmt("{s} [", .{kw});
                        for (ns, 0..) |n, i| {
                            if (i > 0) try self.w(", ");
                            try self.w(n);
                        }
                        try self.w("] = ");
                    },
                }
                try self.emitExpr(lb.value.*);
            },

            .staticCall => |sc| {
                try self.fmt("{s}.{s}(", .{ sc.receiver, sc.method });
                try self.emitExpr(sc.arg.*);
                try self.w(")");
            },

            .call => |c| {
                if (c.receiver) |recv| {
                    try self.fmt("{s}.{s}(", .{ recv, c.callee });
                } else {
                    try self.fmt("{s}(", .{c.callee});
                }
                var first = true;
                for (c.args) |arg| {
                    if (!first) try self.w(", ");
                    try self.emitExpr(arg.value.*);
                    first = false;
                }
                for (c.trailing) |tl| {
                    if (!first) try self.w(", ");
                    first = false;
                    try self.w("(");
                    for (tl.params, 0..) |p, pi| {
                        if (pi > 0) try self.w(", ");
                        try self.w(p);
                    }
                    try self.w(") => {\n");
                    for (tl.body) |st| {
                        try self.w("    ");
                        try self.emitStmt(st);
                        try self.w("\n");
                    }
                    try self.w("}");
                }
                try self.w(")");
            },

            .builtinCall => |bc| {
                try self.fmt("{s}(", .{bc.name});
                for (bc.args, 0..) |arg, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitExpr(arg.value.*);
                }
                try self.w(")");
            },

            .lambda => |l| {
                try self.w("(");
                for (l.params, 0..) |p, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(p);
                }
                try self.w(") => {\n");
                for (l.body) |st| {
                    try self.w("    ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                try self.w("}");
            },

            .arrayLit => |elems| {
                try self.w("[");
                for (elems, 0..) |elem, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitExpr(elem);
                }
                try self.w("]");
            },
            .tupleLit => |elems| {
                try self.w("[");
                for (elems, 0..) |elem, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitExpr(elem);
                }
                try self.w("]");
            },

            .case => |c| try self.emitCase(c.subject.*, c.arms, null),

            .if_ => |i| {
                try self.w("(() => {");
                if (i.binding) |b| {
                    try self.fmt(" const {s} = ", .{b});
                    try self.emitExpr(i.cond.*);
                    try self.fmt("; if ({s} !== null) {{", .{b});
                } else {
                    try self.w(" if (");
                    try self.emitExpr(i.cond.*);
                    try self.w(") {");
                }
                const then = i.then_;
                const head_n = if (then.len > 0) then.len - 1 else 0;
                for (then[0..head_n]) |st| {
                    try self.w(" ");
                    try self.emitStmt(st);
                }
                if (then.len > 0) {
                    try self.w(" ");
                    try self.emitIfLast(then[then.len - 1]);
                }
                try self.w(" }");
                if (i.else_) |els| {
                    try self.w(" else {");
                    const ehead_n = if (els.len > 0) els.len - 1 else 0;
                    for (els[0..ehead_n]) |st| {
                        try self.w(" ");
                        try self.emitStmt(st);
                    }
                    if (els.len > 0) {
                        try self.w(" ");
                        try self.emitIfLast(els[els.len - 1]);
                    }
                    try self.w(" }");
                }
                try self.w(" })()");
            },

            .try_ => |t| try self.emitExpr(t.*),

            .tryCatch => |tc| {
                try self.w("(() => { try { return ");
                try self.emitExpr(tc.expr.*);
                try self.w("; } catch(_e) { return (");
                try self.emitExpr(tc.handler.*);
                try self.w(")(_e); } })()");
            },

            .@"comptime" => |inner| try self.emitExpr(inner.*),
            .comptimeBlock => |cb| {
                for (cb.body) |stmt| {
                    switch (stmt.expr.kind) {
                        .@"break" => |y| {
                            if (y) |yp| try self.emitExpr(yp.*);
                            return;
                        },
                        else => {},
                    }
                }
            },
            .@"break" => |y| if (y) |yp| try self.emitExpr(yp.*),
            .yield => |y| try self.emitExpr(y.*),
            .@"continue" => try self.w("continue"),

            .range => |r| {
                try self.emitExpr(r.start.*);
                try self.w("..");
                if (r.end) |end| try self.emitExpr(end.*);
            },

            .loop => |lp| {
                const has_yield = blk: {
                    for (lp.body) |stmt| {
                        if (stmt.expr.kind == .yield) break :blk true;
                    }
                    break :blk false;
                };

                if (has_yield) {
                    try self.emitExpr(lp.iter.*);
                    try self.w(".map((");
                    for (lp.params, 0..) |p, i| {
                        if (i > 0) try self.w(", ");
                        try self.w(p);
                    }
                    try self.w(") => {\n");
                    for (lp.body) |stmt| {
                        switch (stmt.expr.kind) {
                            .yield => |y| {
                                try self.w("    return ");
                                try self.emitExpr(y.*);
                                try self.w(";\n");
                            },
                            else => {
                                try self.w("    ");
                                try self.emitStmt(stmt);
                                try self.w("\n");
                            },
                        }
                    }
                    try self.w("})");
                } else {
                    try self.w("for (const [");
                    for (lp.params, 0..) |p, i| {
                        if (i > 0) try self.w(", ");
                        try self.w(p);
                    }
                    try self.w("] of Object.entries(");
                    try self.emitExpr(lp.iter.*);
                    try self.w(")) {\n");
                    for (lp.body) |stmt| {
                        try self.w("    ");
                        try self.emitStmt(stmt);
                        try self.w("\n");
                    }
                    try self.w("}");
                }
            },
        }
    }

    // ── case helper ───────────────────────────────────────────────────────────

    fn isLambdaBlock(e: ast.Expr) bool {
        return e.kind == .lambda;
    }

    fn emitCaseBody(self: *Emitter, body: ast.Expr, b: *JsBuilder) !void {
        if (body.kind == .lambda) {
            const l = body.kind.lambda;
            self.current_indent = b.indent_level;
            for (l.body) |st| {
                b.writeIndent();
                switch (st.expr.kind) {
                    .@"break" => |y| {
                        if (y) |yp| {
                            try self.w("return ");
                            try self.emitExpr(yp.*);
                            try self.w(";");
                        }
                    },
                    else => try self.emitStmt(st),
                }
                b.newline();
            }
            self.current_indent = b.indent_level;
        } else {
            try self.emitExpr(body);
        }
    }

    fn buildCondStr(self: *Emitter, pat: ast.Pattern) ![]const u8 {
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        defer buf.deinit();
        switch (pat) {
            .numberLit => |n| try buf.writer.print("_s === {s}", .{n}),
            .stringLit => |s| {
                try buf.writer.writeAll("_s === ");
                var sw = Emitter{ .out = &buf.writer, .alloc = self.alloc, .cv = self.cv };
                try sw.emitJsonString(s);
            },
            .ident => |n| try buf.writer.print("_s === \"{s}\"", .{n}),
            .@"or" => |pats| {
                for (pats, 0..) |p, pi| {
                    if (pi > 0) try buf.writer.writeAll(" || ");
                    try self.writePatternCond(&buf.writer, p);
                }
            },
            else => {},
        }
        return try buf.toOwnedSlice();
    }

    fn writePatternCond(self: *Emitter, wr: *std.Io.Writer, pat: ast.Pattern) !void {
        switch (pat) {
            .numberLit => |n| try wr.print("_s === {s}", .{n}),
            .stringLit => |s| {
                try wr.writeAll("_s === ");
                var sw = Emitter{ .out = wr, .alloc = self.alloc, .cv = self.cv };
                try sw.emitJsonString(s);
            },
            .ident => |n| try wr.print("_s === \"{s}\"", .{n}),
            else => try wr.writeAll("false"),
        }
    }

    fn emitCase(
        self: *Emitter,
        subject: ast.Expr,
        arms: []ast.CaseArm,
        _: ?*JsBuilder,
    ) !void {
        var b = JsBuilder.init(self.alloc, self.out);
        b.indent_level = self.current_indent;

        b.raw("(() => {"); b.newline();
        b.indent();
        b.line("const _s = ");
        try self.emitExpr(subject);
        b.raw(";"); b.newline();

        for (arms) |arm| {
            switch (arm.pattern) {
                .wildcard => {
                    if (isLambdaBlock(arm.body)) {
                        b.open("");
                        try self.emitCaseBody(arm.body, &b);
                        b.close(); b.newline();
                    } else {
                        b.line("return ");
                        try self.emitExpr(arm.body);
                        b.raw(";"); b.newline();
                    }
                },

                .ident, .numberLit, .stringLit, .@"or" => {
                    const cond = try self.buildCondStr(arm.pattern);
                    defer self.alloc.free(cond);
                    if (isLambdaBlock(arm.body)) {
                        b.open(cond);
                        try self.emitCaseBody(arm.body, &b);
                        b.close(); b.newline();
                    } else {
                        b.fmtLine("if ({s}) return ", .{cond});
                        try self.emitExpr(arm.body);
                        b.raw(";"); b.newline();
                    }
                },

                .variantFields => |vf| {
                    b.fmtLine("if (_s.tag === \"{s}\") {{", .{vf.name}); b.newline(); b.indent();
                    if (vf.bindings.len > 0) {
                        b.line("const { ");
                        for (vf.bindings, 0..) |bb, bi| {
                            if (bi > 0) b.raw(", ");
                            b.raw(bb);
                        }
                        b.raw(" } = _s;"); b.newline();
                    }
                    if (isLambdaBlock(arm.body)) {
                        try self.emitCaseBody(arm.body, &b);
                    } else {
                        b.line("return ");
                        try self.emitExpr(arm.body);
                        b.raw(";"); b.newline();
                    }
                    b.close(); b.newline();
                },

                .list => |lp| {
                    if (lp.spread) |sp| {
                        if (lp.elems.len == 0 and sp.len == 0) {
                            b.line("return ");
                            try self.emitExpr(arm.body);
                            b.raw(";"); b.newline();
                        } else {
                            b.fmtLine("if (_s.length >= {d}) {{", .{lp.elems.len}); b.newline(); b.indent();
                            if (sp.len > 0) { b.fmtLine("const {s} = _s.slice({d});", .{ sp, lp.elems.len }); b.newline(); }
                            for (lp.elems, 0..) |elem, ei| switch (elem) {
                                .bind => |bb| { b.fmtLine("const {s} = _s[{d}];", .{ bb, ei }); b.newline(); },
                                else => {},
                            };
                            b.line("return ");
                            try self.emitExpr(arm.body);
                            b.raw(";"); b.newline();
                            b.close(); b.newline();
                        }
                    } else if (lp.elems.len == 0) {
                        b.fmtLine("if (_s.length === 0) return ", .{});
                        try self.emitExpr(arm.body);
                        b.raw(";"); b.newline();
                    } else {
                        b.fmtLine("if (_s.length === {d}) {{", .{lp.elems.len}); b.newline(); b.indent();
                        for (lp.elems, 0..) |elem, ei| switch (elem) {
                            .bind => |bb| { b.fmtLine("const {s} = _s[{d}];", .{ bb, ei }); b.newline(); },
                            else => {},
                        };
                        b.line("return ");
                        try self.emitExpr(arm.body);
                        b.raw(";"); b.newline();
                        b.close(); b.newline();
                    }
                },
            }
        }

        b.dedent(); b.line("})()");
    }

    // ── string helper ─────────────────────────────────────────────────────────

    fn emitJsonString(self: *Emitter, s: []const u8) !void {
        try self.out.writeByte('"');
        for (s) |c| switch (c) {
            '"' => try self.out.writeAll("\\\""),
            '\\' => try self.out.writeAll("\\\\"),
            '\n' => try self.out.writeAll("\\n"),
            '\r' => try self.out.writeAll("\\r"),
            '\t' => try self.out.writeAll("\\t"),
            else => try self.out.writeByte(c),
        };
        try self.out.writeByte('"');
    }
};
