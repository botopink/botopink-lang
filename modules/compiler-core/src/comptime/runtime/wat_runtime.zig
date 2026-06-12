//! WAT prelude — the in-WAT analogue of `template_eval.zig`'s JS prelude.
//!
//! When `template_eval.evaluate` and `decorator_eval.evaluate` run on the
//! wat path, the comptime surface (`__expr` / `__code` / `Span` /
//! `CustomNode` / `__failRaw` / `__capture` + its 13 methods / `__decl` +
//! its 2 methods) lives inside the compiled WAT module so the template body
//! can call into it directly — the same way the JS body `require`s the
//! prelude today.
//!
//! ## Architecture (3-layer prelude)
//!
//! The prelude is assembled from two sources and merged:
//!
//! 1. **rawInfra()** — ~160 lines of WAT that bp can't express (fd_write import,
//!    memory declaration, bump allocator, `__failRaw`, `__compilerError`,
//!    outcome envelopes, descriptor walker: `__str_eq`, `__capture__lookup`,
//!    `__capture__bindings`, `__capture__context`, `__capture__parts`).
//!
//! 2. **compileBpBodies()** — compiles `libs/std/src/template_runtime.bp` through
//!    the wat backend. Methods marked `#[@Host]` (lookup, bindings, context,
//!    failRaw, compilerError) are skipped; all others (records, field getters,
//!    constructors, build/custom) are compiled to WAT.
//!
//! 3. **merge** in `prelude()` — strips the bp module wrapper, drops the bp
//!    `(memory ...)` and `$__heap_ptr` global, renames `$__heap_ptr` →
//!    `$__bp_heap_ptr` (shared heap!), renames bp-mangled names
//!    (`$Capture_text` → `$__capture__text`, `$DeclHandle_fail` →
//!    `$__decl__fail`, etc.), then concatenates rawInfra + bp bodies.
//!
//! ## Descriptor format (F2)
//!
//! `appendDescriptorBytes` emits a binary layout consumed by the descriptor
//! walker functions:
//!
//! ```
//! [text-len: i32][text bytes...]
//! [file-len: i32][file bytes...]
//! [line: i32][col: i32][multiline: i32]
//! [scope-count: i32][scope-entry...]
//!   scope-entry = [name-len: i32][name bytes...][kind: i32]
//! [parts-count: i32][part-entry...]
//!   part-entry = [kind: i32][text-len: i32][text bytes...]
//! ```
//!
//! ## Status
//!
//! **F12 complete** — descriptor walker (`__str_eq`, `__capture__lookup`,
//! `__capture__bindings`, `__capture__context`, `__capture__parts`) shipped.
//! F13 complete — parts offset computed from descriptor.
//! Remaining: F14 (method reflection for `decl.methods`), F15 (custom AST
//! serialiser), F16 (LSP sublanguage).

const std = @import("std");
const template = @import("../template.zig");
const comptimeMod = @import("../../comptime.zig");
const wat = @import("../../codegen/wat.zig");
const configMod = @import("../../codegen/config.zig");

/// The bp source for the wat3 comptime prelude (`libs/std/src/template_runtime.bp`),
/// embedded via `std_prelude.template_runtime_src`. F2 will compile this source
/// through the wat backend, strip the `(module …)` wrapper, rename the bp-mangled
/// fn names (`$Capture_…` → `$__capture__…`, `$DeclHandle_…` → `$__decl__…`,
/// `$make<X>` → `$<X>`), and splice the result into `prelude()` ahead of the
/// raw-infra block. Today the byte slice is only read by the F2-prep verification
/// test below — `prelude()` keeps emitting the hand-rolled WAT verbatim until F2
/// flips the switch.
pub const template_runtime_bp_src: []const u8 = comptimeMod.template_runtime_src;

/// Emit the static WAT prelude bytes. Called by `template_eval.evaluate` /
/// `decorator_eval.evaluate` (F8/F9) to prepend the prelude to the user's
/// template body before handing the combined source to
/// `wat.codegenEmitTemplate(...)`.
///
/// Memory layout
/// =================
///
/// The prelude uses a bump heap that starts at `__BP_HEAP_BASE` (256, leaving
/// the first page-prefix slot for static structures) and grows up via the
/// `$__bp_heap_ptr` global. Each constructor allocates a 4-byte-slot record
/// in source-text field order, exactly matching `wat.zig`'s `allocSlots` +
/// `storeSlotConst` machinery so the runtime layout is byte-identical
/// regardless of whether a record is built by the user's `record { ... }`
/// literal or by a prelude constructor.
///
/// Heap allocator (mirrored in WAT below):
///
///   $__bp_alloc(nbytes) -> i32
///     base = $__bp_heap_ptr
///     $__bp_heap_ptr += nbytes
///     return base
///
/// Error register: `$__bp_err i32 mut` (0 = no error). `__failRaw` stores
/// the message pointer there and immediately traps via `unreachable`; F8's
/// dispatcher catches the trap and inspects the register so the host sees
/// the rich `{ message, param, span }` payload.
///
/// **Bodies that are stubbed today**: the `__capture__*` methods that walk
/// the descriptor JSON (lookup/bindings/parts/text/source/context) and the
/// `__decl__*` reflection cluster (F7) return `i32.const 0` (placeholder
/// pointer). The shape is correct enough that a template body whose only
/// surface is `__expr` / `__code` / `Span` / `CustomNode` / `__failRaw` /
/// `__capture` (factory call only) compiles + runs end-to-end through the
/// new path. Templates that consume `e.text()` / `e.lookup(...)` etc.
/// receive `i32.const 0` and lower to a deterministic empty result — the
/// JS-fallback path under `template_eval.evaluate` stays available for
/// those.

pub fn prelude(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    const bp_wat = compileBpBodies(allocator, io) catch {
        var aw: std.Io.Writer.Allocating = .init(allocator);
        defer aw.deinit();
        try aw.writer.writeAll(rawInfra());
        return aw.toOwnedSlice();
    };
    defer allocator.free(bp_wat);

    var rest = bp_wat;
    if (std.mem.indexOf(u8, rest, "(module")) |idx| {
        rest = rest[idx + "(module".len ..];
    }
    if (std.mem.lastIndexOf(u8, rest, ")")) |idx| {
        rest = rest[0..idx];
    }

    var trimmed = try std.ArrayList(u8).initCapacity(allocator, rest.len);
    defer trimmed.deinit(allocator);
    var lines = std.mem.splitScalar(u8, rest, '\n');
    while (lines.next()) |line| {
        const t = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, t, "(memory ") or
            std.mem.startsWith(u8, t, "(global $__heap_ptr"))
        {
            continue;
        }
        try trimmed.appendSlice(allocator, line);
        try trimmed.append(allocator, '\n');
    }

    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    try aw.writer.writeAll(rawInfra());

    var current = try allocator.dupe(u8, trimmed.items);
    defer allocator.free(current);

    const renames = [_][2][]const u8{
        .{ "$__heap_ptr", "$__bp_heap_ptr" },
        .{ "$makeExpr", "$__expr" },
        .{ "$makeCode", "$__code" },
        .{ "$makeCapture", "$__capture" },
        .{ "$makeSpan", "$Span" },
        .{ "$makeCustomNode", "$CustomNode" },
        .{ "$failRaw", "$__failRaw" },
        .{ "$compilerError", "$__compilerError" },
        .{ "$Capture_value", "$__capture__value" },
        .{ "$Capture_text", "$__capture__text" },
        .{ "$Capture_parts", "$__capture__parts" },
        .{ "$Capture_source", "$__capture__source" },
        .{ "$Capture_context", "$__capture__context" },
        .{ "$Capture_lookup", "$__capture__lookup" },
        .{ "$Capture_bindings", "$__capture__bindings" },
        .{ "$Capture_build", "$__capture__build" },
        .{ "$Capture_custom", "$__capture__custom" },
        .{ "$Capture_fail", "$__capture__fail" },
        .{ "$Capture_failAt", "$__capture__failAt" },
        .{ "$DeclHandle_kind", "$__decl__kind" },
        .{ "$DeclHandle_name", "$__decl__name" },
        .{ "$DeclHandle_fields", "$__decl__fields" },
        .{ "$DeclHandle_methods", "$__decl__methods" },
        .{ "$DeclHandle_returnType", "$__decl__returnType" },
        .{ "$DeclHandle_annotations", "$__decl__annotations" },
        .{ "$DeclHandle_fail", "$__decl__fail" },
        .{ "$DeclHandle_failAt", "$__decl__failAt" },
    };
    for (renames) |rename| {
        const count = std.mem.count(u8, current, rename[0]);
        if (count == 0) continue;
        const delta: isize = @as(isize, @intCast(rename[1].len)) - @as(isize, @intCast(rename[0].len));
        if (delta > 0) {
            const next_len = current.len + @as(usize, @intCast(delta)) * count;
            const next = try allocator.alloc(u8, next_len);
            _ = std.mem.replace(u8, current, rename[0], rename[1], next);
            allocator.free(current);
            current = next;
        } else {
            _ = std.mem.replace(u8, current, rename[0], rename[1], current);
        }
    }

    try aw.writer.writeAll(current);
    return aw.toOwnedSlice();
}

pub fn compileBpBodies(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    var session = try comptimeMod.compile(
        allocator,
        &.{.{ .path = "template_runtime", .source = template_runtime_bp_src }},
        io,
        null,
        "wasm",
    );
    defer session.deinit(allocator);

    var codegen_outputs = try wat.codegenEmit(allocator, session.outputs.items, .{ .targetSource = .wasm });
    defer {
        for (codegen_outputs.items) |*co| co.result.deinit(allocator);
        codegen_outputs.deinit(allocator);
    }

    for (codegen_outputs.items) |co| {
        if (std.mem.eql(u8, co.name, "template_runtime") and co.result.js.len > 0) {
            return allocator.dupe(u8, co.result.js);
        }
    }
    return error.BpCompileFailed;
}

fn rawInfra() []const u8 {
    return (
        \\(import "wasi_snapshot_preview1" "fd_write"
        \\  (func $__bp_fd_write (param i32 i32 i32 i32) (result i32)))
        \\(memory (export "memory") 1)
        \\(global $__bp_heap_ptr (mut i32) (i32.const 256))
        \\(global $__bp_err      (mut i32) (i32.const 0))
        \\(global $__bp_ast_ptr  (mut i32) (i32.const 0))
        \\(global $__bp_outcome_kind (mut i32) (i32.const 0))  ;; 0=code 1=value 2=capture 3=custom
        \\
        \\;; Bump allocator: `$__bp_alloc(nbytes) -> base`.
        \\(func $__bp_alloc (param $n i32) (result i32)
        \\  (local $base i32)
        \\  global.get $__bp_heap_ptr
        \\  local.set $base
        \\  global.get $__bp_heap_ptr
        \\  local.get $n
        \\  i32.add
        \\  global.set $__bp_heap_ptr
        \\  local.get $base)
        \\
        \\;; __emit_raw(ptr, len) — write `len` bytes starting at `ptr` to fd 1.
        \\(func $__emit_raw (export "__emit_raw") (param $ptr i32) (param $len i32)
        \\  i32.const 200
        \\  local.get $ptr
        \\  i32.store
        \\  i32.const 204
        \\  local.get $len
        \\  i32.store
        \\  i32.const 1
        \\  i32.const 200
        \\  i32.const 1
        \\  i32.const 212
        \\  call $__bp_fd_write
        \\  drop)
        \\
        \\;; Outcome JSON envelope data — static prefix/suffix strings.
        \\(data (i32.const 220) "{\22kind\22:\22code\22,\22source\22:\22")
        \\(data (i32.const 246) "\22}")
        \\(data (i32.const 248) "{\22kind\22:\22capture\22,\22param\22:\22")
        \\(data (i32.const 275) "{\22kind\22:\22error\22,\22message\22:\22")
        \\(data (i32.const 335) "{\22kind\22:\22value\22,\22value\22:null}")
        \\
        \\;; __emit_outcome_code / capture / error / value — write JSON envelope via __emit_raw.
        \\(func $__emit_outcome_code (export "__emit_outcome_code") (param $src_ptr i32) (param $src_len i32)
        \\  i32.const 220
        \\  i32.const 25
        \\  call $__emit_raw
        \\  local.get $src_ptr
        \\  local.get $src_len
        \\  call $__emit_raw
        \\  i32.const 246
        \\  i32.const 2
        \\  call $__emit_raw)
        \\(func $__emit_outcome_capture (export "__emit_outcome_capture") (param $param_ptr i32) (param $param_len i32)
        \\  i32.const 248
        \\  i32.const 27
        \\  call $__emit_raw
        \\  local.get $param_ptr
        \\  local.get $param_len
        \\  call $__emit_raw
        \\  i32.const 246
        \\  i32.const 2
        \\  call $__emit_raw)
        \\(func $__emit_outcome_error (export "__emit_outcome_error") (param $msg_ptr i32) (param $msg_len i32)
        \\  i32.const 275
        \\  i32.const 27
        \\  call $__emit_raw
        \\  local.get $msg_ptr
        \\  local.get $msg_len
        \\  call $__emit_raw
        \\  i32.const 246
        \\  i32.const 2
        \\  call $__emit_raw)
        \\
        \\;; __emit_outcome_value() — emits {"kind":"value","value":null}.
        \\;; Full record serialization deferred (needs Zig-side schema).
        \\(func $__emit_outcome_value (export "__emit_outcome_value")
        \\  i32.const 335
        \\  i32.const 28
        \\  call $__emit_raw)
        \\
        \\;; __str_concat_rt(a, b) — concatenate two length-prefixed strings.
        \\;; Allocates via $__bp_alloc, copies bytes, returns new string pointer.
        \\(func $__str_concat_rt (export "__str_concat_rt") (param $a i32) (param $b i32) (result i32)
        \\  (local $alen i32) (local $blen i32) (local $base i32)
        \\  local.get $a
        \\  i32.load
        \\  local.set $alen
        \\  local.get $b
        \\  i32.load
        \\  local.set $blen
        \\  global.get $__bp_heap_ptr
        \\  local.set $base
        \\  global.get $__bp_heap_ptr
        \\  i32.const 4
        \\  local.get $alen
        \\  i32.add
        \\  local.get $blen
        \\  i32.add
        \\  global.set $__bp_heap_ptr
        \\  local.get $base
        \\  local.get $alen
        \\  local.get $blen
        \\  i32.add
        \\  i32.store
        \\  local.get $base
        \\  i32.const 4
        \\  i32.add
        \\  local.get $a
        \\  i32.const 4
        \\  i32.add
        \\  local.get $alen
        \\  memory.copy
        \\  local.get $base
        \\  i32.const 4
        \\  local.get $alen
        \\  i32.add
        \\  i32.add
        \\  local.get $b
        \\  i32.const 4
        \\  i32.add
        \\  local.get $blen
        \\  memory.copy
        \\  local.get $base)
        \\
        \\;; __expr(v) — `{ __lift: v }`. One-slot record. Sets outcome kind=1.
        \\(func $__expr (export "__expr") (param $v i32) (result i32)
        \\  (local $p i32)
        \\  i32.const 4
        \\  call $__bp_alloc
        \\  local.tee $p
        \\  local.get $v
        \\  i32.store
        \\  i32.const 1
        \\  global.set $__bp_outcome_kind
        \\  local.get $p)
        \\
        \\;; __code(s) — `{ __code: s }`. One-slot record. Sets outcome kind=0.
        \\(func $__code (export "__code") (param $s i32) (result i32)
        \\  (local $p i32)
        \\  i32.const 4
        \\  call $__bp_alloc
        \\  local.tee $p
        \\  local.get $s
        \\  i32.store
        \\  i32.const 0
        \\  global.set $__bp_outcome_kind
        \\  local.get $p)
        \\
        \\;; __failRaw(message, param, span) — manual unwind.
        \\(func $__failRaw (export "__failRaw") (param $message i32) (param $param i32) (param $span i32)
        \\  (local $p i32)
        \\  i32.const 12
        \\  call $__bp_alloc
        \\  local.tee $p
        \\  local.get $message
        \\  i32.store
        \\  local.get $p
        \\  local.get $param
        \\  i32.store offset=4
        \\  local.get $p
        \\  local.get $span
        \\  i32.store offset=8
        \\  local.get $p
        \\  global.set $__bp_err
        \\  unreachable)
        \\
        \\;; __compilerError(message) — sugar for __failRaw(message, 0, 0).
        \\(func $__compilerError (export "__compilerError") (param $message i32)
        \\  local.get $message
        \\  i32.const 0
        \\  i32.const 0
        \\  call $__failRaw)
        \\
        \\;; ── F2 descriptor walker ─────────────────────────────────────────────
        \\
        \\;; __str_eq(a, b) — compare two length-prefixed strings.
        \\;; Returns 1 if equal, 0 otherwise.
        \\(func $__str_eq (param $a i32) (param $b i32) (result i32)
        \\  (local $alen i32) (local $blen i32) (local $i i32)
        \\  local.get $a
        \\  i32.load
        \\  local.tee $alen
        \\  local.get $b
        \\  i32.load
        \\  local.tee $blen
        \\  i32.ne
        \\  if (result i32)
        \\    i32.const 0
        \\    return
        \\  end
        \\  i32.const 0
        \\  local.set $i
        \\  block
        \\    loop
        \\      local.get $i
        \\      local.get $alen
        \\      i32.ge_s
        \\      br_if 1
        \\      local.get $a
        \\      local.get $i
        \\      i32.add
        \\      i32.const 4
        \\      i32.add
        \\      i32.load8_u
        \\      local.get $b
        \\      local.get $i
        \\      i32.add
        \\      i32.const 4
        \\      i32.add
        \\      i32.load8_u
        \\      i32.ne
        \\      if
        \\        i32.const 0
        \\        return
        \\      end
        \\      local.get $i
        \\      i32.const 1
        \\      i32.add
        \\      local.set $i
        \\      br 0
        \\    end
        \\  end
        \\  i32.const 1
        \\)
        \\
        \\;; Helper: skip past a length-prefixed string field.
        \\;; Returns (base + 4 + len), i.e. pointer to the next field.
        \\(func $__skip_str (param $p i32) (result i32)
        \\  local.get $p
        \\  i32.load
        \\  local.get $p
        \\  i32.add
        \\  i32.const 4
        \\  i32.add
        \\)
        \\
        \\;; __capture__context(desc) — return pointer to file section (context).
        \\;; Skips past the text section.
        \\(func $__capture__context (export "__capture__context") (param $desc i32) (result i32)
        \\  local.get $desc
        \\  call $__skip_str
        \\)
        \\
        \\;; __capture__lookup(desc, name_ptr) — walk scope entries.
        \\;; Returns pointer to the matched scope entry (name-len field), or 0 on miss.
        \\(func $__capture__lookup (export "__capture__lookup") (param $desc i32) (param $name_ptr i32) (result i32)
        \\  (local $p i32) (local $count i32) (local $i i32) (local $entry i32)
        \\  local.get $desc
        \\  call $__skip_str
        \\  call $__skip_str
        \\  i32.const 12
        \\  i32.add
        \\  local.set $p
        \\  local.get $p
        \\  i32.load
        \\  local.tee $count
        \\  i32.const 0
        \\  i32.eq
        \\  if (result i32)
        \\    i32.const 0
        \\    return
        \\  end
        \\  local.get $p
        \\  i32.const 4
        \\  i32.add
        \\  local.set $p
        \\  i32.const 0
        \\  local.set $i
        \\  block
        \\    loop
        \\      local.get $i
        \\      local.get $count
        \\      i32.ge_u
        \\      br_if 1
        \\      local.get $p
        \\      local.set $entry
        \\      local.get $p
        \\      local.get $name_ptr
        \\      call $__str_eq
        \\      if
        \\        local.get $entry
        \\        return
        \\      end
        \\      local.get $p
        \\      call $__skip_str
        \\      i32.const 4
        \\      i32.add
        \\      local.set $p
        \\      local.get $i
        \\      i32.const 1
        \\      i32.add
        \\      local.set $i
        \\      br 0
        \\    end
        \\  end
        \\  i32.const 0
        \\)
        \\
        \\;; __binding_ref(entry) — wrap the binding's name in a __code record.
        \\;; entry points to a scope entry: [name-len: i32][name bytes...][kind: i32].
        \\;; Returns a __code record wrapping a copy of the name string.
        \\(func $__binding_ref (export "__binding_ref") (param $entry i32) (result i32)
        \\  (local $len i32) (local $p i32)
        \\  local.get $entry
        \\  i32.load
        \\  local.tee $len
        \\  i32.const 4
        \\  i32.add
        \\  call $__bp_alloc
        \\  local.tee $p
        \\  local.get $len
        \\  i32.store
        \\  local.get $p
        \\  i32.const 4
        \\  i32.add
        \\  local.get $entry
        \\  i32.const 4
        \\  i32.add
        \\  local.get $len
        \\  memory.copy
        \\  i32.const 0
        \\  global.set $__bp_outcome_kind
        \\  local.get $p
        \\  call $__code)
        \\
        \\;; __capture__bindings(desc) — return pointer to scope section.
        \\(func $__capture__bindings (export "__capture__bindings") (param $desc i32) (result i32)
        \\  local.get $desc
        \\  call $__skip_str
        \\  call $__skip_str
        \\  i32.const 12
        \\  i32.add
        \\)
        \\
        \\;; __capture__parts(desc) — return pointer to parts section.
        \\;; Skips text, file, line/col/multiline, and scope entries.
        \\(func $__capture__parts (export "__capture__parts") (param $desc i32) (result i32)
        \\  (local $p i32) (local $count i32) (local $i i32)
        \\  local.get $desc
        \\  call $__skip_str
        \\  call $__skip_str
        \\  i32.const 12
        \\  i32.add
        \\  local.set $p
        \\  local.get $p
        \\  i32.load
        \\  local.set $count
        \\  local.get $p
        \\  i32.const 4
        \\  i32.add
        \\  local.set $p
        \\  block
        \\    loop
        \\      local.get $i
        \\      local.get $count
        \\      i32.ge_u
        \\      br_if 1
        \\      local.get $p
        \\      call $__skip_str
        \\      i32.const 4
        \\      i32.add
        \\      local.set $p
        \\      local.get $i
        \\      i32.const 1
        \\      i32.add
        \\      local.set $i
        \\      br 0
        \\    end
        \\  end
        \\  local.get $p
        \\)
        \\
        \\;; ── custom outcome emission ─────────────────────────────────────────
        \\
        \\(data (i32.const 300) "{\22kind\22:\22custom\22,\22source\22:\22")
        \\
        \\;; __emit_outcome_custom(code_ptr, code_len, ast_ptr, ast_len) — write
        \\;; {"kind":"custom","source":"<code>"} via __emit_raw.
        \\;; ast is reserved for F20 (Zig-side CustomNode reader).
        \\(func $__emit_outcome_custom (export "__emit_outcome_custom") (param $code_ptr i32) (param $code_len i32) (param $ast_ptr i32) (param $ast_len i32)
        \\  i32.const 300
        \\  i32.const 27
        \\  call $__emit_raw
        \\  local.get $code_ptr
        \\  local.get $code_len
        \\  call $__emit_raw
        \\  i32.const 246
        \\  i32.const 2
        \\  call $__emit_raw)
        \\
        \\;; __capture__custom(self, ast, code) — allocate { code, ast } record.
        \\;; The wrapper reads this and calls __emit_outcome_custom.
        \\(func $__capture__custom (export "__capture__custom") (param $self i32) (param $ast i32) (param $code i32) (result i32)
        \\  (local $p i32)
        \\  i32.const 8
        \\  call $__bp_alloc
        \\  local.tee $p
        \\  local.get $code
        \\  i32.store
        \\  local.get $p
        \\  local.get $ast
        \\  i32.store offset=4
        \\  local.get $p)
        \\
        \\;; ── decorator @emit support ─────────────────────────────────────────
        \\
        \\(global $__bp_emit_len (mut i32) (i32.const 0))
        \\(data (i32.const 340) "{\22kind\22:\22ok\22,\22contributions\22:[")
        \\
        \\;; __emit(str) — append a quoted, comma-separated string from a
        \\;; length-prefixed bp string to the emit buffer at offset 400.
        \\(func $__emit (export "__emit") (param $str i32)
        \\  (local $ptr i32) (local $len i32) (local $off i32)
        \\  local.get $str
        \\  i32.load
        \\  local.set $len
        \\  local.get $str
        \\  i32.const 4
        \\  i32.add
        \\  local.set $ptr
        \\  global.get $__bp_emit_len
        \\  local.tee $off
        \\  i32.const 0
        \\  i32.eq
        \\  if
        \\    ;; first emit — write opening quote at offset 400
        \\    i32.const 400
        \\    i32.const 34
        \\    i32.store8
        \\    i32.const 1
        \\    global.set $__bp_emit_len
        \\    i32.const 401
        \\    local.set $off
        \\  else
        \\    ;; subsequent emit — write ," at current position
        \\    i32.const 400
        \\    local.get $off
        \\    i32.add
        \\    i32.const 44
        \\    i32.store8
        \\    i32.const 400
        \\    local.get $off
        \\    i32.add
        \\    i32.const 1
        \\    i32.add
        \\    i32.const 34
        \\    i32.store8
        \\    local.get $off
        \\    i32.const 2
        \\    i32.add
        \\    local.set $off
        \\  end
        \\  ;; copy source bytes
        \\  local.get $ptr
        \\  i32.const 400
        \\  local.get $off
        \\  i32.add
        \\  local.get $len
        \\  memory.copy
        \\  ;; write closing quote
        \\  local.get $off
        \\  local.get $len
        \\  i32.add
        \\  local.tee $off
        \\  i32.const 400
        \\  i32.add
        \\  i32.const 34
        \\  i32.store8
        \\  local.get $off
        \\  i32.const 1
        \\  i32.add
        \\  global.set $__bp_emit_len)
        \\
        \\;; __emit_flush() — write {"kind":"ok","contributions":[...]} to stdout.
        \\;; Called by the decorator wrapper after the body returns.
        \\(func $__emit_flush (export "__emit_flush")
        \\  i32.const 340
        \\  i32.const 29
        \\  call $__emit_raw
        \\  ;; buffer content (skip leading quote = 401)
        \\  i32.const 401
        \\  global.get $__bp_emit_len
        \\  i32.const 1
        \\  i32.sub
        \\  call $__emit_raw
        \\  i32.const 246
        \\  i32.const 2
        \\  call $__emit_raw)
        \\
    );
}

/// Compute the byte offset of the parts section within a descriptor blob
/// produced by `appendDescriptorBytes`. Walks past text, file, line/col/multiline,
/// and scope entries to compute where the parts-count and parts array start.
/// Returns 0 if the descriptor has no parts section.
pub fn partsOffsetInDescriptor(blob: []const u8) u32 {
    if (blob.len < 4) return 0;
    var pos: u32 = 0;

    // Skip text: 4 bytes len + text bytes
    const text_len = std.mem.readInt(u32, blob[pos..][0..4], .little);
    pos += 4 + text_len;
    if (pos >= blob.len) return 0;

    // Skip file: 4 bytes len + file bytes
    const file_len = std.mem.readInt(u32, blob[pos..][0..4], .little);
    pos += 4 + file_len;
    if (pos + 12 > blob.len) return 0;

    // Skip line + col + multiline (3 × 4 = 12 bytes)
    pos += 12;
    if (pos + 4 > blob.len) return 0;

    // Read scope-count
    const scope_count = std.mem.readInt(u32, blob[pos..][0..4], .little);
    pos += 4;

    // Skip scope entries: each is name-len(4) + name + kind(4)
    var i: u32 = 0;
    while (i < scope_count) : (i += 1) {
        if (pos + 4 > blob.len) return 0;
        const name_len = std.mem.readInt(u32, blob[pos..][0..4], .little);
        pos += 4 + name_len + 4; // name-len + name bytes + kind
    }

    return pos;
}

/// Append the capture descriptor as a flat length-prefixed text blob
/// suitable for embedding as a wasm `(data ...)` segment.
///
/// **Format (v1)**: a length-prefixed string identical to what the wat
/// backend's `internString` produces — 4-byte little-endian length
/// followed by the raw bytes. The prelude's `__capture__text(self)`
/// returns this pointer as-is, so consumers see a real botopink string
/// (the same length-prefixed shape `s.len`/`s.slice(...)` operate on).
///
/// **Why not JSON anymore**: walking JSON in WAT was the F6 final
/// increment's biggest blocker. A flat length-prefixed buffer is what
/// `s.len`/`internString`/the F3 string ops already speak. The richer
/// fields (`file`/`line`/`col`/`multiline`/`scope`) get added as a
/// chained payload AFTER the text once their consumers (templates that
/// call `e.source()`/`e.lookup(...)`) need them — for now the audit's
/// most common shape is `e.text()` + `e.build(...)`, which only needs
/// the text bytes.
///
/// Caller owns the returned slice.
pub fn appendDescriptorBytes(
    allocator: std.mem.Allocator,
    capture: *const template.CapturedExpr,
) ![]u8 {
    // F2 extended binary layout:
    //   [text-len: i32][text bytes...]
    //   [file-len: i32][file bytes...]
    //   [line: i32][col: i32][multiline: i32]
    //   [scope-count: i32][scope-entry...]
    //     scope-entry = [name-len: i32][name bytes...][kind: i32]
    //   [parts-count: i32][part-entry...]
    //     part-entry = [kind: i32][text-len: i32][text bytes...]
    const text = capture.text orelse "";
    const file = capture.modulePath;
    const lineno: i32 = @intCast(capture.loc.line);
    const colno: i32 = @intCast(capture.loc.col);
    const multi: i32 = if (capture.multiline) @as(i32, 1) else 0;

    // Count scope entries.
    var scope_count: u32 = 0;
    var scope_bytes: u32 = 0;
    if (capture.scope) |scope| {
        var it = scope.entries.iterator();
        while (it.next()) |entry| {
            scope_count += 1;
            const name = entry.value_ptr.name;
            scope_bytes += 4 + @as(u32, @intCast(name.len)) + 4; // name-len + name + kind
        }
    }

    // Parts: for now emit a single Text part with the raw text,
    // or an empty parts array when text is null (template with holes).
    var parts_count: u32 = 0;
    var parts_bytes: u32 = 0;
    if (capture.text) |txt| {
        parts_count = 1;
        parts_bytes = 4 + 4 + @as(u32, @intCast(txt.len)); // kind + text-len + text
    }

    const total: u32 = 4 + @as(u32, @intCast(text.len)) + // text
        4 + @as(u32, @intCast(file.len)) + // file
        4 + 4 + 4 + // line + col + multiline
        4 + scope_bytes + // scope-count + entries
        4 + parts_bytes; // parts-count + entries

    var out = try allocator.alloc(u8, total);
    var pos: u32 = 0;

    // text
    std.mem.writeInt(u32, out[pos..][0..4], @intCast(text.len), .little);
    pos += 4;
    @memcpy(out[pos..][0..text.len], text);
    pos += @intCast(text.len);

    // file
    std.mem.writeInt(u32, out[pos..][0..4], @intCast(file.len), .little);
    pos += 4;
    @memcpy(out[pos..][0..file.len], file);
    pos += @intCast(file.len);

    // line, col, multiline
    std.mem.writeInt(i32, out[pos..][0..4], lineno, .little);
    pos += 4;
    std.mem.writeInt(i32, out[pos..][0..4], colno, .little);
    pos += 4;
    std.mem.writeInt(i32, out[pos..][0..4], multi, .little);
    pos += 4;

    // scope
    std.mem.writeInt(u32, out[pos..][0..4], scope_count, .little);
    pos += 4;
    if (capture.scope) |scope| {
        var it = scope.entries.iterator();
        while (it.next()) |entry| {
            const name = entry.value_ptr.name;
            const kind: i32 = switch (entry.value_ptr.kind) {
                .fn_ => 0,
                .val => 1,
                .struct_ => 2,
                .enum_ => 3,
                .interface => 4,
            };
            std.mem.writeInt(u32, out[pos..][0..4], @intCast(name.len), .little);
            pos += 4;
            @memcpy(out[pos..][0..name.len], name);
            pos += @intCast(name.len);
            std.mem.writeInt(i32, out[pos..][0..4], kind, .little);
            pos += 4;
        }
    }

    // parts
    std.mem.writeInt(u32, out[pos..][0..4], parts_count, .little);
    pos += 4;
    if (capture.text) |txt| {
        // kind = 0 (Text)
        std.mem.writeInt(i32, out[pos..][0..4], 0, .little);
        pos += 4;
        std.mem.writeInt(u32, out[pos..][0..4], @intCast(txt.len), .little);
        pos += 4;
        @memcpy(out[pos..][0..txt.len], txt);
        pos += @intCast(txt.len);
    }

    return out;
}

/// Deprecated alias — keeps the previous F6 contract callable while
/// callers migrate. New code should use `appendDescriptorBytes`.
pub fn appendDescriptorJson(
    allocator: std.mem.Allocator,
    capture: *const template.CapturedExpr,
) ![]u8 {
    return template.contextJsonAlloc(capture, allocator);
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "prelude emits the full export list" {
    const allocator = std.testing.allocator;
    const out = try prelude(allocator, std.testing.io);
    defer allocator.free(out);

    // Spot-check that every documented export name appears at least once.
    // F7 field-getters (`__decl__kind` etc.) are removed — dot-access
    // (`decl.kind` → i32.load offset=0) replaces them; only methods
    // with real bodies (fail/failAt) survive as exports.
    const expected_exports = [_][]const u8{
        "__expr",        "__code",
        "Span",          "CustomNode",
        "__failRaw",     "__compilerError",
        "__capture",     "__capture__value",
        "__capture__text",       "__capture__parts",
        "__capture__source",     "__capture__context",
        "__capture__lookup",     "__capture__bindings",
        "__capture__build",      "__capture__custom",
        "__capture__fail",       "__capture__failAt",
        "__decl__fail",   "__decl__failAt",
    };
    for (expected_exports) |sym| {
        if (std.mem.indexOf(u8, out, sym) == null) {
            std.debug.print("missing export in prelude: {s}\n", .{sym});
            return error.MissingExport;
        }
    }
}

test "outcome JSON envelope parses as the canonical code Outcome" {
    const allocator = std.testing.allocator;
    const wasm3_host = @import("./wasm3_host.zig");

    // Build the same module the previous test exercises, then re-parse
    // its captured stdout through std.json. The host's parseOutcome
    // depends on this shape, so a regression here breaks the swap.
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    const bw = &aw.writer;

    try bw.writeAll("(module\n");
    const prelude_bytes = try prelude(allocator, std.testing.io);
    defer allocator.free(prelude_bytes);
    try bw.writeAll(prelude_bytes);

    try bw.writeAll(
        \\(data (i32.const 400) "let x = 1;")
        \\(func $_botopink_main (export "_botopink_main") (export "_start")
        \\  i32.const 400
        \\  i32.const 10
        \\  call $__emit_outcome_code)
        \\)
    );

    const wat_source = try aw.toOwnedSlice();
    defer allocator.free(wat_source);

    const captured = wasm3_host.runWat(allocator, wat_source) catch return error.RunWatFailed;
    defer allocator.free(captured);

    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();

    const parsed = try std.json.parseFromSliceLeaky(std.json.Value, arena.allocator(), captured, .{});
    const obj = switch (parsed) {
        .object => |o| o,
        else => return error.NotAnObject,
    };
    const kind = switch (obj.get("kind") orelse return error.MissingKind) {
        .string => |s| s,
        else => return error.KindNotString,
    };
    try std.testing.expectEqualStrings("code", kind);

    const src = switch (obj.get("source") orelse return error.MissingSource) {
        .string => |s| s,
        else => return error.SourceNotString,
    };
    try std.testing.expectEqualStrings("let x = 1;", src);
}

test "__emit_outcome_code wraps payload in canonical JSON envelope" {
    const allocator = std.testing.allocator;
    const wasm3_host = @import("./wasm3_host.zig");

    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    const bw = &aw.writer;

    try bw.writeAll("(module\n");
    const prelude_bytes = try prelude(allocator, std.testing.io);
    defer allocator.free(prelude_bytes);
    try bw.writeAll(prelude_bytes);

    try bw.writeAll(
        \\(data (i32.const 400) "x = 42")
        \\(func $_botopink_main (export "_botopink_main") (export "_start")
        \\  i32.const 400
        \\  i32.const 6
        \\  call $__emit_outcome_code)
        \\)
    );

    const wat_source = try aw.toOwnedSlice();
    defer allocator.free(wat_source);

    const captured = wasm3_host.runWat(allocator, wat_source) catch return error.RunWatFailed;
    defer allocator.free(captured);

    // Canonical envelope: prefix + payload + suffix.
    try std.testing.expectEqualStrings(
        "{\"kind\":\"code\",\"source\":\"x = 42\"}",
        captured,
    );
}

test "__emit_raw round-trips through wasm3: hello -> stdout" {
    const allocator = std.testing.allocator;
    const wasm3_host = @import("./wasm3_host.zig");

    // Build a module that calls __emit_raw with a static string
    // ("hello" lives in a data segment at offset 300).
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    const bw = &aw.writer;

    try bw.writeAll("(module\n");
    const prelude_bytes = try prelude(allocator, std.testing.io);
    defer allocator.free(prelude_bytes);
    try bw.writeAll(prelude_bytes);

    try bw.writeAll(
        \\(data (i32.const 300) "hello")
        \\(func $_botopink_main (export "_botopink_main") (export "_start")
        \\  i32.const 300
        \\  i32.const 5
        \\  call $__emit_raw)
        \\)
    );

    const wat_source = try aw.toOwnedSlice();
    defer allocator.free(wat_source);

    const captured = wasm3_host.runWat(allocator, wat_source) catch |err| {
        std.debug.print("runWat failed: {s}\n", .{@errorName(err)});
        return error.RunWatFailed;
    };
    defer allocator.free(captured);

    // The captured fd 1 bytes should equal "hello" — proving the prelude's
    // __emit_raw → fd_write path actually carries the body's output back.
    try std.testing.expectEqualStrings("hello", captured);
}

test "appendDescriptorBytes returns length-prefixed text" {
    const allocator = std.testing.allocator;
    const ast = @import("../../ast.zig");

    var lit_expr: ast.Expr = .{ .literal = .{
        .loc = .{ .line = 1, .col = 1 },
        .kind = .{ .stringLit = "hello world" },
    } };
    const cap = template.CapturedExpr{
        .callee = "q",
        .paramIndex = 0,
        .paramName = "template",
        .node = &lit_expr,
        .text = "hello world",
        .multiline = false,
        .loc = .{ .line = 7, .col = 3 },
        .modulePath = "main",
        .scope = null,
    };

    const blob = try appendDescriptorBytes(allocator, &cap);
    defer allocator.free(blob);

    // F2 extended layout: text + file + line/col/multiline + scope + parts.
    // text: 4 + 11 = 15 bytes ("hello world")
    // file: 4 + 4 = 8 bytes ("main")
    // line/col/multiline: 12 bytes (3 × i32)
    // scope-count: 4 bytes (0 entries)
    // parts-count + 1 Text part: 4 + 4 + 4 + 11 = 23 bytes
    const expected_len: u32 = 15 + 8 + 12 + 4 + 23;
    try std.testing.expectEqual(expected_len, blob.len);

    // Spot-check text at offset 0.
    const text_len = std.mem.readInt(u32, blob[0..4], .little);
    try std.testing.expectEqual(@as(u32, 11), text_len);
    try std.testing.expectEqualStrings("hello world", blob[4..][0..11]);
}

test "appendDescriptorJson round-trips template.contextJsonAlloc" {
    const allocator = std.testing.allocator;
    const ast = @import("../../ast.zig");

    // Minimal CapturedExpr — no scope, no parts, just enough fields the
    // descriptor JSON walker would consume.
    var lit_expr: ast.Expr = .{ .literal = .{
        .loc = .{ .line = 1, .col = 1 },
        .kind = .{ .stringLit = "hello" },
    } };
    const cap = template.CapturedExpr{
        .callee = "q",
        .paramIndex = 0,
        .paramName = "template",
        .node = &lit_expr,
        .text = "hello",
        .multiline = false,
        .loc = .{ .line = 7, .col = 3 },
        .modulePath = "main",
        .scope = null,
    };

    const blob = try appendDescriptorJson(allocator, &cap);
    defer allocator.free(blob);

    // Spot-check the JSON contents. The exact byte shape comes from
    // template.contextJsonAlloc — any drift there shows up here too.
    try std.testing.expect(std.mem.indexOf(u8, blob, "\"file\":\"main\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, blob, "\"line\":7") != null);
    try std.testing.expect(std.mem.indexOf(u8, blob, "\"col\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, blob, "\"multiline\":false") != null);
    try std.testing.expect(std.mem.indexOf(u8, blob, "\"text\":\"hello\"") != null);
}

test "prelude carries real bodies (no stub unreachable in the constructors)" {
    const allocator = std.testing.allocator;
    const out = try prelude(allocator, std.testing.io);
    defer allocator.free(out);

    // The 4 constructors + the alloc helper must have real bodies. A pure
    // `unreachable` stub would look like `(func $Foo (param ...) (result ...)
    // \n  unreachable)`. Walk forward from the fn name to the next
    // top-level `(func ` or end-of-prelude; the slice in between is the
    // full func definition.
    const must_have_real_body = [_][]const u8{
        "$__expr ",       "$__code ",
        "$Span ",         "$CustomNode ",
        "$__failRaw ",    "$__bp_alloc ",
        "$__capture ",
    };
    for (must_have_real_body) |fn_name| {
        const idx = std.mem.indexOf(u8, out, fn_name) orelse {
            std.debug.print("missing fn name {s}\n", .{fn_name});
            return error.MissingFn;
        };
        const after = out[idx + fn_name.len ..];
        const next_func = std.mem.indexOf(u8, after, "(func ") orelse after.len;
        const body = after[0..next_func];
        // A real body has at least one `local.tee`/`global.set`/`i32.store`/
        // `call $` marker. A pure `unreachable` body has none of those.
        const real =
            std.mem.indexOf(u8, body, "local.tee") != null or
            std.mem.indexOf(u8, body, "global.set") != null or
            std.mem.indexOf(u8, body, "i32.store") != null or
            std.mem.indexOf(u8, body, "call $") != null;
        if (!real) {
            std.debug.print("fn {s} still has stub unreachable body\n", .{fn_name});
            return error.StubBody;
        }
    }
}

test "template_runtime.bp source is reachable through std_prelude" {
    // F2 prep — the embedded bp source must be non-empty and carry the F1
    // record + factory surface (`Capture`, `DeclHandle`, `makeCapture`,
    // `failRaw`). A regression here means the build.zig `std_internal_files`
    // wiring or the `std_prelude.template_runtime_src` re-export dropped the
    // file; F2's compile step would silently emit nothing in that case.
    try std.testing.expect(template_runtime_bp_src.len > 0);
    const must_have = [_][]const u8{
        "pub record Capture",
        "pub record DeclHandle",
        "pub record Outcome",
        "pub fn makeExpr",
        "pub fn makeCode",
        "pub fn makeCapture",
        "pub fn failRaw",
        "pub fn compilerError",
    };
    for (must_have) |marker| {
        if (std.mem.indexOf(u8, template_runtime_bp_src, marker) == null) {
            std.debug.print("missing marker in template_runtime.bp: {s}\n", .{marker});
            return error.MissingMarker;
        }
    }
}

test "template_runtime.bp parses through the bare lexer + parser" {
    // F2 diagnostic — call lex + parse directly so we can pinpoint exactly
    // where the bp source breaks (the comptime.compile wrapper swallows
    // `error.UnexpectedToken` into a bare `.parseError`).
    const allocator = std.testing.allocator;
    const Lexer = @import("../../lexer.zig").Lexer;
    const Parser = @import("../../parser.zig").Parser;

    var arena: std.heap.ArenaAllocator = .init(allocator);
    defer arena.deinit();

    var lex = Lexer.init(template_runtime_bp_src);
    const toks = try lex.scanAll(arena.allocator());

    var parser = Parser.init(toks);
    _ = parser.parse(arena.allocator()) catch |err| {
        // Print the last-seen token and its location to localize the failure.
        std.debug.print(
            "parser failed with {s} near token #{d}\n",
            .{ @errorName(err), parser.current },
        );
        if (parser.current < toks.len) {
            const t = toks[parser.current];
            std.debug.print("  token at line {d} col {d}: kind={s}\n", .{ t.line, t.col, @tagName(t.kind) });
        }
        return err;
    };
}

test "template_runtime.bp parses + type-checks through comptime.compile" {
    // F2 gate — the embedded bp source must reach `Outcome.ok` through the
    // standard comptime pipeline (lex/parse/validate/infer). A parse or type
    // error here blocks F2's `wat.codegenEmit` step from producing the wat
    // bodies the prelude swap depends on.
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var session = try comptimeMod.compile(
        allocator,
        &.{.{ .path = "template_runtime", .source = template_runtime_bp_src }},
        io,
        null,
        "wasm",
    );
    defer session.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 1), session.outputs.items.len);
    const outcome = session.outputs.items[0].outcome;
    switch (outcome) {
        .ok => {},
        .parseError => {
            std.debug.print("template_runtime.bp failed to parse\n", .{});
            return error.ParseFailed;
        },
        .validationError => |verr| {
            std.debug.print("template_runtime.bp failed validation: '{s}' at line {d} col {d}\n", .{ verr.ident, verr.loc.line, verr.loc.col });
            return error.ValidationFailed;
        },
        .typeError => |te| {
            const msg = try te.message(allocator);
            defer allocator.free(msg);
            std.debug.print("template_runtime.bp failed type-check: {s}\n", .{msg});
            return error.TypeFailed;
        },
    }
}
