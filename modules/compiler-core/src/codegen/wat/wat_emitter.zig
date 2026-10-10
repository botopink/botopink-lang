//! WebAssembly-text emitter — the only place that writes `.wat` text.
//!
//! It renders the `wat_ast.zig` model: s-expression layout, indentation,
//! `$`-prefixed identifiers, folded vs flat instruction form, and data-segment
//! escaping. `codegen/wat.zig` builds nodes and never prints, the way
//! `codegen/erlang.zig` builds `erl_ast` nodes for `erl_emitter.zig`.
//!
//! Every module is validated before a byte is written (`wat_ast.validateModule`):
//! a `call` that names nothing the module declares, a body that does not match
//! its `(result …)`, an unnamed parameter — all are refused here rather than
//! surviving into text that `wasmtime` rejects.

const std = @import("std");
const ast = @import("wat_ast.zig");

const Writer = std.Io.Writer;

pub const Error = Writer.Error || ast.Invalid;

// ── entry points ─────────────────────────────────────────────────────────────

/// Render a whole `(module …)` form.
pub fn renderModule(w: *Writer, m: ast.Module) Error!void {
    try ast.validateModule(m);
    try w.writeAll("(module\n");
    for (m.items) |it| try renderItem(w, it);
    try w.writeAll(")\n");
}

// ── the WASI preview 2 component (decision 334, front `01-compiler/140`) ─────

/// The preview 1 functions the component's adapter implements over WASI
/// preview 2 — every `wasi_snapshot_preview1` import the backend emits
/// (`wat_prelude.zig`: `fd_write` for the print helpers, `random_get` for
/// `wasi:random_f64`). A module importing another one is refused here, never
/// wrapped with the import left unsatisfied.
pub const preview1_adapted = [_][]const u8{ "fd_write", "random_get" };

pub const ComponentError = Error || std.mem.Allocator.Error || error{UnadaptedPreview1Import};

/// Render `m` as a WASI preview 2 component — what a wasm build for the
/// `wasi` host writes, and what `wasmtime run` runs (decision 334).
///
/// The module is embedded as `$main`, unchanged but for its `(start …)`: a
/// start function runs while the module is instantiated, before the adapter
/// that serves its `wasi_snapshot_preview1` imports exists, so the start is
/// dropped and its function exported as `__bp_init`, which the component's
/// `wasi:cli/run` export calls before `_start`. Around it, a fixed frame:
///
///   * the preview 2 interfaces imported — `wasi:io/{error,streams}`,
///     `wasi:cli/{stdout,stderr}`, `wasi:random/random` (`@0.2.0`);
///   * `$p1_shim` — the preview 1 functions `$main` imports, as trampolines
///     through a table (`$main` needs them to be instantiated; their
///     implementation needs `$main`'s memory);
///   * `$p1_adapter` — the preview 1 adapter: `fd_write` copies each iovec
///     from `$main`'s memory into a scratch memory 4096 bytes at a time and
///     writes it with `blocking-write-and-flush` on stdout (fd 1) or stderr
///     (fd 2), any other fd `EBADF`, a failed write `EIO`; `random_get` fills
///     the buffer from `get-random-u64`; `run` calls `__bp_init` and `_start`;
///   * `$p1_fixup` — fills the shim's table with the adapter's functions;
///   * the `wasi:cli/run@0.2.0` export, when `$main` exports `_start`.
pub fn renderComponent(alloc: std.mem.Allocator, w: *Writer, module: ast.Module) ComponentError!void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const m = try ast.startAsExport(arena_state.allocator(), module);
    try ast.validateModule(m);
    var has_init = false;
    var has_start = false;
    var has_host = false;
    for (m.items) |it| switch (it) {
        .import => |im| if (std.mem.eql(u8, im.module, "wasi_snapshot_preview1")) {
            for (preview1_adapted) |n| {
                if (std.mem.eql(u8, n, im.name)) break;
            } else return error.UnadaptedPreview1Import;
        } else if (std.mem.eql(u8, im.module, "bp_host")) {
            has_host = true;
        },
        .func => |f| for (f.exports) |e| {
            if (std.mem.eql(u8, e, "_start")) has_start = true;
            if (std.mem.eql(u8, e, ast.host_init_export)) has_init = true;
        },
        else => {},
    };

    try w.writeAll(component_imports);
    if (has_host) try w.writeAll(component_host_imports);
    try w.writeAll("  (core module $main\n");
    for (m.items) |it| try renderItem(w, it);
    try w.writeAll("  )\n");
    try w.writeAll(component_adapter_head);
    if (has_host) try w.writeAll(component_host_shim);
    try w.writeAll(if (has_host) component_main_hosted else component_main_plain);
    try w.writeAll(component_adapter_rest);
    if (has_init) try w.writeAll("    (import \"main\" \"__bp_init\" (func $init))\n");
    if (has_start) try w.writeAll("    (import \"main\" \"_start\" (func $start))\n");
    try w.writeAll(component_adapter_body);
    if (has_init) try w.writeAll("      call $init\n");
    if (has_start) try w.writeAll("      call $start\n");
    try w.writeAll(component_adapter_tail);
    if (has_host) try w.writeAll(component_host_adapter);
    if (has_start) try w.writeAll(component_run_export);
    try w.writeAll(")\n");
}

const component_imports =
    \\(component
    \\  (import "wasi:io/error@0.2.0" (instance $error
    \\    (export "error" (type (sub resource)))
    \\  ))
    \\  (alias export $error "error" (type $error_t))
    \\  (import "wasi:io/streams@0.2.0" (instance $streams
    \\    (export "error" (type $err (eq $error_t)))
    \\    (export "output-stream" (type $os (sub resource)))
    \\    (type $se (variant (case "last-operation-failed" (own $err)) (case "closed")))
    \\    (export "stream-error" (type $se2 (eq $se)))
    \\    (export "[method]output-stream.blocking-write-and-flush"
    \\      (func (param "self" (borrow $os)) (param "contents" (list u8)) (result (result (error $se2)))))
    \\  ))
    \\  (alias export $streams "output-stream" (type $os_t))
    \\  (import "wasi:cli/stdout@0.2.0" (instance $stdout
    \\    (export "output-stream" (type $os (eq $os_t)))
    \\    (export "get-stdout" (func (result (own $os))))
    \\  ))
    \\  (import "wasi:cli/stderr@0.2.0" (instance $stderr
    \\    (export "output-stream" (type $os (eq $os_t)))
    \\    (export "get-stderr" (func (result (own $os))))
    \\  ))
    \\  (import "wasi:random/random@0.2.0" (instance $random
    \\    (export "get-random-u64" (func (result u64)))
    \\  ))
    \\
;

const component_adapter_head =
    \\  (core module $p1_shim
    \\    (type $fd_write (func (param i32 i32 i32 i32) (result i32)))
    \\    (type $random_get (func (param i32 i32) (result i32)))
    \\    (table (export "$imports") 2 2 funcref)
    \\    (func (export "fd_write") (type $fd_write)
    \\      local.get 0 local.get 1 local.get 2 local.get 3 i32.const 0 call_indirect (type $fd_write))
    \\    (func (export "random_get") (type $random_get)
    \\      local.get 0 local.get 1 i32.const 1 call_indirect (type $random_get))
    \\  )
    \\  (core instance $shim (instantiate $p1_shim))
    \\
;

const component_main_plain =
    \\  (core instance $main (instantiate $main (with "wasi_snapshot_preview1" (instance $shim))))
    \\
;

const component_main_hosted =
    \\  (core instance $main (instantiate $main (with "wasi_snapshot_preview1" (instance $shim)) (with "bp_host" (instance $bp_shim))))
    \\
;

const component_adapter_rest =
    \\  (core module $p1_scratch (memory (export "memory") 1))
    \\  (core instance $scratch (instantiate $p1_scratch))
    \\  (alias core export $scratch "memory" (core memory $scratch_memory))
    \\  (core func $get_stdout (canon lower (func $stdout "get-stdout")))
    \\  (core func $get_stderr (canon lower (func $stderr "get-stderr")))
    \\  (core func $write (canon lower (func $streams "[method]output-stream.blocking-write-and-flush") (memory $scratch_memory)))
    \\  (core func $drop_stream (canon resource.drop $os_t))
    \\  (core func $random_u64 (canon lower (func $random "get-random-u64")))
    \\  (core module $p1_adapter
    \\    (import "main" "memory" (memory $m 0))
    \\    (import "scratch" "memory" (memory $s 1))
    \\    (import "p2" "get-stdout" (func $get_stdout (result i32)))
    \\    (import "p2" "get-stderr" (func $get_stderr (result i32)))
    \\    (import "p2" "write" (func $write (param i32 i32 i32 i32)))
    \\    (import "p2" "drop-stream" (func $drop_stream (param i32)))
    \\    (import "p2" "random-u64" (func $random_u64 (result i64)))
    \\
;

const component_adapter_body =
    \\    (func (export "fd_write") (param $fd i32) (param $iovs i32) (param $n i32) (param $written i32) (result i32)
    \\      (local $stream i32) (local $total i32) (local $ptr i32) (local $len i32) (local $chunk i32)
    \\      (block $bad
    \\        (block $out
    \\          (block $err
    \\            local.get $fd i32.const 1 i32.eq
    \\            (if (then call $get_stdout local.set $stream)
    \\              (else
    \\                local.get $fd i32.const 2 i32.ne br_if $bad
    \\                call $get_stderr local.set $stream))
    \\            (block $iovs_done
    \\              (loop $each_iov
    \\                local.get $n i32.eqz br_if $iovs_done
    \\                local.get $iovs i32.load $m local.set $ptr
    \\                local.get $iovs i32.load $m offset=4 local.set $len
    \\                (block $iov_done
    \\                  (loop $each_chunk
    \\                    local.get $len i32.eqz br_if $iov_done
    \\                    local.get $len i32.const 4096 local.get $len i32.const 4096 i32.lt_u select local.set $chunk
    \\                    i32.const 16 local.get $ptr local.get $chunk memory.copy $s $m
    \\                    local.get $stream i32.const 16 local.get $chunk i32.const 0 call $write
    \\                    i32.const 0 i32.load8_u $s br_if $err
    \\                    local.get $ptr local.get $chunk i32.add local.set $ptr
    \\                    local.get $len local.get $chunk i32.sub local.set $len
    \\                    local.get $total local.get $chunk i32.add local.set $total
    \\                    br $each_chunk))
    \\                local.get $iovs i32.const 8 i32.add local.set $iovs
    \\                local.get $n i32.const 1 i32.sub local.set $n
    \\                br $each_iov))
    \\            br $out)
    \\          local.get $stream call $drop_stream
    \\          i32.const 29 return)
    \\        local.get $written local.get $total i32.store $m
    \\        local.get $stream call $drop_stream
    \\        i32.const 0 return)
    \\      i32.const 8)
    \\    (func (export "random_get") (param $buf i32) (param $len i32) (result i32)
    \\      (local $v i64)
    \\      (block $whole
    \\        (loop $words
    \\          local.get $len i32.const 8 i32.lt_u br_if $whole
    \\          local.get $buf call $random_u64 i64.store $m
    \\          local.get $buf i32.const 8 i32.add local.set $buf
    \\          local.get $len i32.const 8 i32.sub local.set $len
    \\          br $words))
    \\      call $random_u64 local.set $v
    \\      (block $done
    \\        (loop $bytes
    \\          local.get $len i32.eqz br_if $done
    \\          local.get $buf local.get $v i64.store8 $m
    \\          local.get $v i64.const 8 i64.shr_u local.set $v
    \\          local.get $buf i32.const 1 i32.add local.set $buf
    \\          local.get $len i32.const 1 i32.sub local.set $len
    \\          br $bytes))
    \\      i32.const 0)
    \\    (func (export "run") (result i32)
    \\
;

const component_adapter_tail =
    \\      i32.const 0)
    \\  )
    \\  (core instance $p2 (export "get-stdout" (func $get_stdout)) (export "get-stderr" (func $get_stderr)) (export "write" (func $write)) (export "drop-stream" (func $drop_stream)) (export "random-u64" (func $random_u64)))
    \\  (core instance $adapter (instantiate $p1_adapter
    \\    (with "main" (instance $main))
    \\    (with "scratch" (instance $scratch))
    \\    (with "p2" (instance $p2))))
    \\  (core module $p1_fixup
    \\    (import "" "$imports" (table 2 2 funcref))
    \\    (import "" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
    \\    (import "" "random_get" (func $random_get (param i32 i32) (result i32)))
    \\    (elem (i32.const 0) func $fd_write $random_get))
    \\  (core instance (instantiate $p1_fixup (with "" (instance
    \\    (export "$imports" (table $shim "$imports"))
    \\    (export "fd_write" (func $adapter "fd_write"))
    \\    (export "random_get" (func $adapter "random_get"))))))
    \\
;

// ── the host tasks' adapter (decisions 392–394, front 140 step 4) ───────────
//
// A module whose tasks wait on the host imports `bp_host`: `delay(ms) -> h`,
// `wait(handles, n, ready) -> k` and `drop(h)` (`wat_prelude.zig`). On `wasi`
// they are `wasi:clocks/monotonic-clock`'s `subscribe-duration`,
// `wasi:io/poll`'s `poll` and the pollable's drop, through trampolines the
// fixup fills once `$main`'s memory exists — the preview 1 adapter's shape.
// `poll` reads its list from, and writes its answer into, a scratch memory of
// its own (`$bp_scratch`, whose `realloc` answers one fixed region: a poll
// answers one list, copied out before the next).

const component_host_imports =
    \\  (import "wasi:io/poll@0.2.0" (instance $poll
    \\    (export "pollable" (type $p (sub resource)))
    \\    (export "poll" (func (param "in" (list (borrow $p))) (result (list u32))))
    \\  ))
    \\  (alias export $poll "pollable" (type $pollable_t))
    \\  (import "wasi:clocks/monotonic-clock@0.2.0" (instance $clock
    \\    (export "pollable" (type $p (eq $pollable_t)))
    \\    (export "subscribe-duration" (func (param "when" u64) (result (own $p))))
    \\  ))
    \\
;

const component_host_shim =
    \\  (core module $bp_shim_m
    \\    (type $delay (func (param i32) (result i32)))
    \\    (type $wait (func (param i32 i32 i32) (result i32)))
    \\    (type $drop (func (param i32)))
    \\    (table (export "$imports") 3 3 funcref)
    \\    (func (export "delay") (type $delay)
    \\      local.get 0 i32.const 0 call_indirect (type $delay))
    \\    (func (export "wait") (type $wait)
    \\      local.get 0 local.get 1 local.get 2 i32.const 1 call_indirect (type $wait))
    \\    (func (export "drop") (type $drop)
    \\      local.get 0 i32.const 2 call_indirect (type $drop))
    \\  )
    \\  (core instance $bp_shim (instantiate $bp_shim_m))
    \\
;

const component_host_adapter =
    \\  (core module $bp_scratch_m
    \\    (memory (export "memory") 1)
    \\    (func (export "realloc") (param i32 i32 i32 i32) (result i32) i32.const 32768))
    \\  (core instance $bp_scratch (instantiate $bp_scratch_m))
    \\  (alias core export $bp_scratch "memory" (core memory $bp_scratch_memory))
    \\  (alias core export $bp_scratch "realloc" (core func $bp_realloc))
    \\  (core func $subscribe (canon lower (func $clock "subscribe-duration")))
    \\  (core func $poll_list (canon lower (func $poll "poll") (memory $bp_scratch_memory) (realloc $bp_realloc)))
    \\  (core func $drop_pollable (canon resource.drop $pollable_t))
    \\  (core module $bp_adapter_m
    \\    (import "main" "memory" (memory $m 0))
    \\    (import "scratch" "memory" (memory $s 1))
    \\    (import "p2" "subscribe" (func $subscribe (param i64) (result i32)))
    \\    (import "p2" "poll" (func $poll (param i32 i32 i32)))
    \\    (import "p2" "drop" (func $drop (param i32)))
    \\    (func (export "delay") (param $ms i32) (result i32)
    \\      local.get $ms i64.extend_i32_u i64.const 1000000 i64.mul call $subscribe)
    \\    (func (export "wait") (param $handles i32) (param $n i32) (param $ready i32) (result i32)
    \\      (local $list i32) (local $k i32)
    \\      i32.const 8192 local.get $handles local.get $n i32.const 4 i32.mul memory.copy $s $m
    \\      i32.const 8192 local.get $n i32.const 0 call $poll
    \\      i32.const 0 i32.load $s local.set $list
    \\      i32.const 4 i32.load $s local.set $k
    \\      local.get $ready local.get $list local.get $k i32.const 4 i32.mul memory.copy $m $s
    \\      local.get $k)
    \\    (func (export "drop") (param $h i32)
    \\      local.get $h call $drop)
    \\  )
    \\  (core instance $bp_p2 (export "subscribe" (func $subscribe)) (export "poll" (func $poll_list)) (export "drop" (func $drop_pollable)))
    \\  (core instance $bp_adapter (instantiate $bp_adapter_m
    \\    (with "main" (instance $main))
    \\    (with "scratch" (instance $bp_scratch))
    \\    (with "p2" (instance $bp_p2))))
    \\  (core module $bp_fixup
    \\    (import "" "$imports" (table 3 3 funcref))
    \\    (import "" "delay" (func $delay (param i32) (result i32)))
    \\    (import "" "wait" (func $wait (param i32 i32 i32) (result i32)))
    \\    (import "" "drop" (func $drop (param i32)))
    \\    (elem (i32.const 0) func $delay $wait $drop))
    \\  (core instance (instantiate $bp_fixup (with "" (instance
    \\    (export "$imports" (table $bp_shim "$imports"))
    \\    (export "delay" (func $bp_adapter "delay"))
    \\    (export "wait" (func $bp_adapter "wait"))
    \\    (export "drop" (func $bp_adapter "drop"))))))
    \\
;

const component_run_export =
    \\  (func $run (result (result)) (canon lift (core func $adapter "run")))
    \\  (instance $run_instance (export "run" (func $run)))
    \\  (export "wasi:cli/run@0.2.0" (instance $run_instance))
    \\
;

/// One top-level form, in the module's two-space item column.
fn renderItem(w: *Writer, it: ast.Item) Error!void {
    switch (it) {
        .import => |im| try import(w, im),
        .memory => |mem| try memory(w, mem),
        .start => |name| try w.print("  (start ${s})\n", .{name}),
        .table => |names| {
            try w.writeAll("  (table funcref (elem");
            for (names) |n| try w.print(" ${s}", .{n});
            try w.writeAll("))\n");
        },
        .data => |d| try dataSegment(w, d),
        .global => |g| try global(w, g),
        .func => |f| try func(w, f),
        .comment => |text| try w.print("  ;; {s}\n", .{text}),
    }
}

// ── forms ────────────────────────────────────────────────────────────────────

fn import(w: *Writer, im: ast.Import) Error!void {
    try w.print("  (import \"{s}\" \"{s}\" (func ${s}", .{ im.module, im.name, im.func });
    if (im.type.params.len > 0) {
        try w.writeAll(" (param");
        for (im.type.params) |p| try w.print(" {s}", .{p.text()});
        try w.writeAll(")");
    }
    if (im.type.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("))\n");
}

fn memory(w: *Writer, mem: ast.Memory) Error!void {
    try w.writeAll("  (memory");
    if (mem.@"export") |e| try w.print(" (export \"{s}\")", .{e});
    try w.print(" {d})\n", .{mem.min_pages});
}

fn global(w: *Writer, g: ast.Global) Error!void {
    try w.print("  (global ${s}", .{g.name});
    for (g.exports) |e| try w.print(" (export \"{s}\")", .{e});
    if (g.mutable)
        try w.print(" (mut {s})", .{g.ty.text()})
    else
        try w.print(" {s}", .{g.ty.text()});
    try w.print(" ({s}.const {s}))\n", .{ g.ty.text(), g.init });
}

fn func(w: *Writer, f: ast.Func) Error!void {
    try w.print("  (func ${s}", .{f.name});
    for (f.exports) |e| try w.print(" (export \"{s}\")", .{e});
    for (f.params) |p| try w.print(" (param ${s} {s})", .{ p.name, p.ty.text() });
    if (f.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("\n");
    // `(local …)` lives between the signature and the first instruction — the
    // only place WAT accepts it, and the reason locals are a field of the
    // function node instead of an instruction.
    for (f.locals) |group| {
        try w.writeAll("    ");
        for (group, 0..) |l, i| {
            if (i > 0) try w.writeAll(" ");
            try w.print("(local ${s} {s})", .{ l.name, l.ty.text() });
        }
        try w.writeAll("\n");
    }
    try seq(w, f.body);
    try w.writeAll("  )\n");
}

/// `(data (i32.const off) "…")` — the four-byte little-endian length prefix
/// every string carries, then the bytes.
fn dataSegment(w: *Writer, d: ast.DataSegment) Error!void {
    try w.print("  (data (i32.const {d}) \"", .{d.offset});
    const prefix = [4]u8{
        @truncate(d.len_prefix),
        @truncate(d.len_prefix >> 8),
        @truncate(d.len_prefix >> 16),
        @truncate(d.len_prefix >> 24),
    };
    for (prefix) |c| try w.print("\\{x:0>2}", .{c});
    // A segment that is no UTF-8 text — a `bigint` literal's limbs (decision
    // 332) — writes every byte past ASCII escaped: the text format is UTF-8.
    const binary = !std.unicode.utf8ValidateSlice(d.bytes);
    for (d.bytes) |c| switch (c) {
        '\n' => try w.writeAll("\\n"),
        '"' => try w.writeAll("\\\""),
        '\\' => try w.writeAll("\\\\"),
        '\t' => try w.writeAll("\\t"),
        '\r' => try w.writeAll("\\r"),
        else => if (c < 0x20 or (binary and c >= 0x7f))
            try w.print("\\{x:0>2}", .{c})
        else
            try w.writeByte(c),
    };
    try w.writeAll("\")\n");
}

// ── instructions ─────────────────────────────────────────────────────────────

fn seq(w: *Writer, s: ast.Seq) Error!void {
    for (s.lines) |l| try line(w, l);
}

fn indent(w: *Writer, n: u8) Error!void {
    for (0..n) |_| try w.writeAll(" ");
}

fn line(w: *Writer, l: ast.Line) Error!void {
    switch (l.instr) {
        .@"if" => |n| return ifForm(w, l.indent, n),
        .block => |b| return blockForm(w, l.indent, b),
        .comment => |text| {
            try indent(w, l.indent);
            return w.print(";; {s}\n", .{text});
        },
        else => {},
    }
    try indent(w, l.indent);
    if (l.folded) try w.writeAll("(");
    try instr(w, l.instr);
    if (l.folded) try w.writeAll(")");
    if (l.comment) |c| try w.print(" ;; {s}", .{c});
    try w.writeAll("\n");
}

fn ifForm(w: *Writer, col: u8, n: ast.If) Error!void {
    try indent(w, col);
    try w.writeAll("(if");
    if (n.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("\n");
    try arm(w, col + 2, "then", n.then);
    if (n.@"else") |e| try arm(w, col + 2, "else", e);
    try indent(w, col);
    try w.writeAll(")\n");
}

fn arm(w: *Writer, col: u8, keyword: []const u8, a: ast.If.Arm) Error!void {
    try indent(w, col);
    try w.print("({s}", .{keyword});
    switch (a.layout) {
        .inline_ => {
            for (a.seq.lines) |l| {
                try w.writeAll(" ");
                try instr(w, l.instr);
            }
            try w.writeAll(")\n");
        },
        .block => {
            try w.writeAll("\n");
            try seq(w, a.seq);
            try indent(w, col);
            try w.writeAll(")\n");
        },
    }
}

fn blockForm(w: *Writer, col: u8, b: ast.Block) Error!void {
    try indent(w, col);
    try w.print("({s}", .{@tagName(b.kind)});
    if (b.label) |l| try w.print(" ${s}", .{l});
    if (b.result) |r| try w.print(" (result {s})", .{r.text()});
    try w.writeAll("\n");
    try seq(w, b.body);
    try indent(w, col);
    try w.writeAll(")\n");
}

/// The instruction itself, with no indentation, comment or newline — so an
/// inline `if` arm can put several on one line.
fn instr(w: *Writer, i: ast.Instr) Error!void {
    switch (i) {
        .@"const" => |c| try w.print("{s}.const {s}", .{ c.ty.text(), c.text }),
        .local_get => |n| try w.print("local.get ${s}", .{n}),
        .local_set => |n| try w.print("local.set ${s}", .{n}),
        .local_tee => |n| try w.print("local.tee ${s}", .{n}),
        .global_get => |n| try w.print("global.get ${s}", .{n}),
        .global_set => |n| try w.print("global.set ${s}", .{n}),
        .op => |o| try w.print("{s}.{s}", .{ o.ty.text(), o.name }),
        .convert => |o| try w.writeAll(o),
        .load => |m| {
            try w.print("{s}.load", .{m.ty.text()});
            if (m.width == .byte) try w.writeAll("8_u");
            if (m.offset != 0) try w.print(" offset={d}", .{m.offset});
        },
        .store => |m| {
            try w.print("{s}.store", .{m.ty.text()});
            if (m.width == .byte) try w.writeAll("8");
            if (m.offset != 0) try w.print(" offset={d}", .{m.offset});
        },
        .call => |n| try w.print("call ${s}", .{n}),
        .call_indirect => |t| {
            try w.writeAll("call_indirect");
            if (t.params.len > 0) {
                try w.writeAll(" (param");
                for (t.params) |p| try w.print(" {s}", .{p.text()});
                try w.writeAll(")");
            }
            if (t.result) |r| try w.print(" (result {s})", .{r.text()});
        },
        .br => |l| try w.print("br ${s}", .{l}),
        .br_if => |l| try w.print("br_if ${s}", .{l}),
        .drop => try w.writeAll("drop"),
        .@"return" => try w.writeAll("return"),
        .@"unreachable" => try w.writeAll("unreachable"),
        .memory_copy => try w.writeAll("memory.copy"),
        .memory_size => try w.writeAll("memory.size"),
        .memory_grow => try w.writeAll("memory.grow"),
        .comment => |text| try w.print(";; {s}", .{text}),
        // Structured forms own their own lines; `line`/`arm` never reach here.
        .@"if", .block => unreachable,
    }
}

// ── tests ────────────────────────────────────────────────────────────────────

fn renderToString(alloc: std.mem.Allocator, m: ast.Module) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(alloc);
    errdefer aw.deinit();
    try renderModule(&aw.writer, m);
    return aw.toOwnedSlice();
}

test "a module renders imports, data, globals and functions in item order" {
    const alloc = std.testing.allocator;

    // `(if (result i32) (then i32.const 0) (else …))`: an inline arm and a
    // block arm side by side, plus a `block`/`loop` pair and an indented body.
    const then_arm: ast.If.Arm = .{
        .layout = .inline_,
        .seq = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        } },
    };
    const else_arm: ast.If.Arm = .{ .seq = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .indent = 8, .instr = .{ .local_get = "p" } },
        .{ .indent = 8, .instr = .{ .load = .{ .offset = 4 } }, .comment = ".x" },
    } } };

    const loop_body: ast.Seq = .{ .stack = .terminated, .lines = &.{
        .{ .indent = 8, .instr = .{ .local_get = "p" } },
        .{ .indent = 8, .instr = .{ .br_if = "done" } },
        .{ .indent = 8, .instr = .{ .br = "again" } },
    } };

    const body: ast.Seq = .{ .stack = .{ .value = .i32 }, .lines = &.{
        .{ .instr = .{ .comment = "a note" } },
        .{ .instr = .{ .block = .{ .kind = .block, .label = "done", .body = .{
            .stack = .none,
            .lines = &.{.{ .indent = 6, .instr = .{ .block = .{
                .kind = .loop,
                .label = "again",
                .body = loop_body,
            } } }},
        } } } },
        .{ .instr = .{ .local_get = "p" } },
        .{ .instr = .{ .@"if" = .{ .result = .i32, .then = then_arm, .@"else" = else_arm } } },
    } };

    const m: ast.Module = .{ .items = &.{
        .{ .import = .{
            .module = "wasi_snapshot_preview1",
            .name = "fd_write",
            .func = "fd_write",
            .type = .{ .params = &.{ .i32, .i32 }, .result = .i32 },
        } },
        .{ .memory = .{ .@"export" = "memory", .min_pages = 1 } },
        .{ .start = "__init_globals" },
        .{ .data = .{ .offset = 256, .len_prefix = 3, .bytes = "a\"b" } },
        .{ .global = .{ .name = "__heap_ptr", .ty = .i32, .mutable = true, .init = "264" } },
        .{ .global = .{ .name = "PI", .exports = &.{"PI"}, .ty = .f64, .init = "3.14" } },
        .{ .comment = "a form-level note" },
        .{ .func = .{
            .name = "f",
            .exports = &.{"f"},
            .params = &.{.{ .name = "p", .ty = .i32 }},
            .result = .i32,
            .locals = &.{ &.{.{ .name = "a", .ty = .i32 }}, &.{ .{ .name = "b", .ty = .i32 }, .{ .name = "c", .ty = .f32 } } },
            .body = body,
        } },
    } };

    const out = try renderToString(alloc, m);
    defer alloc.free(out);

    try std.testing.expectEqualStrings(
        \\(module
        \\  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (start $__init_globals)
        \\  (data (i32.const 256) "\03\00\00\00a\"b")
        \\  (global $__heap_ptr (mut i32) (i32.const 264))
        \\  (global $PI (export "PI") f64 (f64.const 3.14))
        \\  ;; a form-level note
        \\  (func $f (export "f") (param $p i32) (result i32)
        \\    (local $a i32)
        \\    (local $b i32) (local $c f32)
        \\    ;; a note
        \\    (block $done
        \\      (loop $again
        \\        local.get $p
        \\        br_if $done
        \\        br $again
        \\      )
        \\    )
        \\    local.get $p
        \\    (if (result i32)
        \\      (then i32.const 0)
        \\      (else
        \\        local.get $p
        \\        i32.load offset=4 ;; .x
        \\      )
        \\    )
        \\  )
        \\)
        \\
    , out);
}

test "a call to a function the module does not declare is refused" {
    const calls_missing: ast.Module = .{ .items = &.{
        .{ .func = .{ .name = "f", .body = .{ .lines = &.{
            .{ .instr = .{ .call = "nope" } },
        } } } },
    } };
    var discard: std.Io.Writer.Discarding = .init(&.{});
    try std.testing.expectError(error.UndefinedCall, renderModule(&discard.writer, calls_missing));

    // The same call is fine once the module defines the symbol.
    const defines_it: ast.Module = .{ .items = &.{
        calls_missing.items[0],
        .{ .func = .{ .name = "nope" } },
    } };
    try renderModule(&discard.writer, defines_it);
}

test "a body's stack has to match the signature" {
    const b: ast.Builder = .{ .arena = std.testing.allocator };

    // A void function may not leave a value behind.
    try std.testing.expectError(error.ResultMismatch, b.func(.{
        .name = "void_leaks",
        .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
        } },
    }));

    // …and a function that produces one may not go without a `(result …)`,
    // which is the same check: the specialisation pass used to clear the
    // declared return type and leave the `return <v>` in place.
    try std.testing.expectError(error.ResultMismatch, b.func(.{
        .name = "specialised",
        .result = null,
        .body = .{ .stack = .{ .value = .i32 } },
    }));

    // A terminated body fits either signature.
    const term = try b.func(.{ .name = "t", .result = .f64, .body = .{ .stack = .terminated } });
    try std.testing.expect(term.result.? == .f64);
}

test "an if arm has to fill the result it promises, and an unnamed param is refused" {
    try std.testing.expectError(error.BranchMismatch, ast.validateFunc(.{
        .name = "f",
        .result = .i32,
        .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = .{ .stack = .none } },
                .@"else" = .{ .seq = .{ .stack = .{ .value = .i32 } } },
            } } },
        } },
    }));

    try std.testing.expectError(error.MissingElse, ast.validateFunc(.{
        .name = "f",
        .result = .i32,
        .body = .{ .stack = .{ .value = .i32 }, .lines = &.{
            .{ .instr = .{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = .{ .stack = .{ .value = .i32 } } },
            } } },
        } },
    }));

    try std.testing.expectError(error.UnnamedParam, ast.validateFunc(.{
        .name = "f",
        .params = &.{.{ .name = "", .ty = .i32 }},
    }));
}

test "a helper can only be named by requesting it" {
    var b: ast.Builder = .{ .arena = std.testing.allocator };
    try std.testing.expect(!b.helpers.has(.print));

    const call = b.helper(.print_str);
    try std.testing.expectEqualStrings("__print_str", call.call);
    try std.testing.expect(b.helpers.has(.print_str));
    // `$__print_str` ends in `$__print_nl`, so its group pulls `print` in.
    try std.testing.expect(b.helpers.has(.print));
    try std.testing.expect(!b.helpers.has(.str_eq));
}

test "every runtime helper group renders with its deps, and only with them" {
    const prelude = @import("wat_prelude.zig");
    const alloc = std.testing.allocator;
    for (std.enums.values(ast.HelperGroup)) |g| {
        var set: ast.HelperSet = .{};
        set.require(g);
        var items: std.ArrayListUnmanaged(ast.Item) = .empty;
        defer items.deinit(alloc);
        if (set.has(.print)) try items.append(alloc, .{ .import = prelude.fd_write_import });
        if (set.has(.wasi_random_f64)) try items.append(alloc, .{ .import = prelude.random_get_import });
        if (set.has(.task_host)) {
            try items.append(alloc, .{ .import = prelude.bp_host_delay_import });
            try items.append(alloc, .{ .import = prelude.bp_host_wait_import });
            try items.append(alloc, .{ .import = prelude.bp_host_drop_import });
        }
        try items.append(alloc, .{ .global = .{ .name = "__heap_ptr", .ty = .i32, .mutable = true, .init = "256" } });
        for (prelude.order) |og| {
            if (!set.has(og)) continue;
            // `wat.zig`'s substitution: the `wasi` host's poll beside host tasks.
            if (og == .task_poll and set.has(.task_host)) {
                try items.append(alloc, .{ .func = prelude.task_host_poll_wasi });
                continue;
            }
            // … and the `browser` host's export beside them.
            if (og == .task_host) try items.append(alloc, .{ .func = prelude.bp_ready });
            try items.appendSlice(alloc, prelude.items(og));
        }
        var discard: std.Io.Writer.Discarding = .init(&.{});
        renderModule(&discard.writer, .{ .items = items.items }) catch |err| {
            std.debug.print("helper group {s}: {s}\n", .{ @tagName(g), @errorName(err) });
            return err;
        };
    }
}

test "a wasi build's module is wrapped as a WASI preview 2 component, its start called by run (decision 334)" {
    const alloc = std.testing.allocator;
    const m: ast.Module = .{ .items = &.{
        .{ .import = .{
            .module = "wasi_snapshot_preview1",
            .name = "fd_write",
            .func = "fd_write",
            .type = .{ .params = &.{ .i32, .i32, .i32, .i32 }, .result = .i32 },
        } },
        .{ .memory = .{ .@"export" = "memory", .min_pages = 1 } },
        .{ .start = "__init_globals" },
        .{ .func = .{ .name = "__init_globals" } },
        .{ .func = .{ .name = "_botopink_main", .exports = &.{ "_botopink_main", "_start" } } },
    } };
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    try renderComponent(alloc, &aw.writer, m);
    const out = aw.written();
    try std.testing.expect(std.mem.startsWith(u8, out, "(component\n"));
    // The module keeps its items, but for the start: its function is
    // exported for the adapter's `run`, which calls it before `_start`.
    try std.testing.expect(std.mem.indexOf(u8, out, "(start") == null);
    try std.testing.expect(std.mem.indexOf(u8, out,
        \\  (core module $main
        \\  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (func $__init_globals (export "__bp_init")
        \\  )
        \\  (func $_botopink_main (export "_botopink_main") (export "_start")
        \\  )
        \\  )
    ) != null);
    try std.testing.expect(std.mem.indexOf(u8, out,
        \\      call $init
        \\      call $start
        \\      i32.const 0)
    ) != null);
    try std.testing.expect(std.mem.endsWith(u8, out,
        \\  (export "wasi:cli/run@0.2.0" (instance $run_instance))
        \\)
        \\
    ));
}

test "a module importing a preview 1 function the adapter does not implement is not wrapped" {
    const m: ast.Module = .{ .items = &.{
        .{ .import = .{ .module = "wasi_snapshot_preview1", .name = "proc_exit", .func = "proc_exit", .type = .{ .params = &.{.i32} } } },
    } };
    var discard: std.Io.Writer.Discarding = .init(&.{});
    try std.testing.expectError(error.UnadaptedPreview1Import, renderComponent(std.testing.allocator, &discard.writer, m));
}

test {
    // The `browser` host's loader (decision 334) — a sibling this file's
    // tests carry, as `codegen/tests.zig` carries this one.
    _ = @import("browser_loader.zig");
}
