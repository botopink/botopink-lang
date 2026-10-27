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

// ── identifiers ──────────────────────────────────────────────────────────────

/// `{f}` formatter for the text after a `$`. A name that holds a backtick
/// identifier (decision 561 — `` `add one` ``, also inside a name the codegen
/// composed around one) is escaped: every byte that is no WAT `idchar`, and
/// `\` itself, becomes `\` and two hex digits (`` $`add\20one` ``). Only such
/// a name holds a backtick, so the escaped name meets no other name of the
/// module, and two names escape alike only when they are one name. Any other
/// name is written as it is.
pub fn id(name: []const u8) IdFormatter {
    return .{ .name = name };
}

pub const IdFormatter = struct {
    name: []const u8,

    pub fn format(self: IdFormatter, w: *Writer) Writer.Error!void {
        if (std.mem.indexOfScalar(u8, self.name, '`') == null) return w.writeAll(self.name);
        for (self.name) |c| {
            if (c != '\\' and isIdChar(c)) try w.writeByte(c) else try w.print("\\{x:0>2}", .{c});
        }
    }
};

/// The WAT text format's `idchar`.
fn isIdChar(c: u8) bool {
    if (std.ascii.isAlphanumeric(c)) return true;
    return std.mem.indexOfScalar(u8, "!#$%&'*+-./:<=>?@\\^_`|~", c) != null;
}

// ── entry points ─────────────────────────────────────────────────────────────

/// Render a whole `(module …)` form.
pub fn renderModule(w: *Writer, m: ast.Module) Error!void {
    try ast.validateModule(m);
    try w.writeAll("(module\n");
    const defs = ast.typesOf(m);
    for (m.items) |it| try renderItem(w, defs, it);
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
    var has_fs = false;
    for (m.items) |it| switch (it) {
        .import => |im| if (std.mem.eql(u8, im.module, "wasi_snapshot_preview1")) {
            for (preview1_adapted) |n| {
                if (std.mem.eql(u8, n, im.name)) break;
            } else return error.UnadaptedPreview1Import;
        } else if (std.mem.eql(u8, im.module, "bp_host")) {
            has_host = true;
        } else if (std.mem.eql(u8, im.module, "bp_fs")) {
            has_fs = true;
        },
        .func => |f| for (f.exports) |e| {
            if (std.mem.eql(u8, e, "_start")) has_start = true;
            if (std.mem.eql(u8, e, ast.host_init_export)) has_init = true;
        },
        else => {},
    };

    try w.writeAll(component_imports);
    if (has_host) try w.writeAll(component_host_imports);
    if (has_fs) try w.writeAll(component_fs_imports);
    try w.writeAll("  (core module $main\n");
    const defs = ast.typesOf(m);
    for (m.items) |it| try renderItem(w, defs, it);
    try w.writeAll("  )\n");
    try w.writeAll(component_adapter_head);
    if (has_host) try w.writeAll(component_host_shim);
    if (has_fs) try w.writeAll(component_fs_shim);
    try w.writeAll("  (core instance $main (instantiate $main (with \"wasi_snapshot_preview1\" (instance $shim))");
    if (has_host) try w.writeAll(" (with \"bp_host\" (instance $bp_shim))");
    if (has_fs) try w.writeAll(" (with \"bp_fs\" (instance $fs_shim))");
    try w.writeAll("))\n");
    try w.writeAll(component_adapter_rest);
    if (has_init) try w.writeAll("    (import \"main\" \"__bp_init\" (func $init))\n");
    if (has_start) try w.writeAll("    (import \"main\" \"_start\" (func $start))\n");
    try w.writeAll(component_adapter_body);
    if (has_init) try w.writeAll("      call $init\n");
    if (has_start) try w.writeAll("      call $start\n");
    try w.writeAll(component_adapter_tail);
    if (has_host) try w.writeAll(component_host_adapter);
    if (has_fs) try w.writeAll(component_fs_adapter);
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

// ── the file system's adapter (decision 992) ─────────────────────────────────────
//
// A module whose leaves reach the file system imports `bp_fs` (`wat_prelude.fs_imports`):
// open, close, read, write, stat, stat_at, readdir_open, readdir_next, readdir_close, mkdir,
// rmdir, unlink, symlink, getenv and cwd, over `(pointer, length)` paths relative to the root
// the host preopens (`wasmtime run --dir /::/ --dir <cwd>::<cwd>`: the root, and the working
// directory under its own absolute path). On `wasi` they are `wasi:filesystem`'s `descriptor`'s
// methods, `preopens` and `wasi:cli/environment`, through trampolines the fixup fills once
// `$main`'s memory exists — the preview 1 adapter's shape. Every host call reads its strings from,
// and writes its answer into, a scratch memory of its own (`$fs_scratch_m`, whose `realloc` is a
// bump the adapter puts back before each call): a path is copied in before the call, a read's
// bytes and a stat copied out after it. An answer is `-(1 + error-code)` when the host failed.

const component_fs_imports =
    \\  (import "wasi:clocks/wall-clock@0.2.0" (instance $wall
    \\    (type $dt (record (field "seconds" u64) (field "nanoseconds" u32)))
    \\    (export "datetime" (type $dt2 (eq $dt)))
    \\  ))
    \\  (alias export $wall "datetime" (type $datetime_t))
    \\  (import "wasi:filesystem/types@0.2.0" (instance $fst
    \\    (export "descriptor" (type $descriptor (sub resource)))
    \\    (export "directory-entry-stream" (type $dstream (sub resource)))
    \\    (type $dtype_t (enum "unknown" "block-device" "character-device" "directory" "fifo" "symbolic-link" "regular-file" "socket"))
    \\    (export "descriptor-type" (type $dtype (eq $dtype_t)))
    \\    (type $dflags_t (flags "read" "write" "file-integrity-sync" "data-integrity-sync" "requested-write-sync" "mutate-directory"))
    \\    (export "descriptor-flags" (type $dflags (eq $dflags_t)))
    \\    (type $pflags_t (flags "symlink-follow"))
    \\    (export "path-flags" (type $pflags (eq $pflags_t)))
    \\    (type $oflags_t (flags "create" "directory" "exclusive" "truncate"))
    \\    (export "open-flags" (type $oflags (eq $oflags_t)))
    \\    (type $ec_t (enum "access" "would-block" "already" "bad-descriptor" "busy" "deadlock" "quota" "exist" "file-too-large" "illegal-byte-sequence" "in-progress" "interrupted" "invalid" "io" "is-directory" "loop" "too-many-links" "message-size" "name-too-long" "no-device" "no-entry" "no-lock" "insufficient-memory" "insufficient-space" "not-directory" "not-empty" "not-recoverable" "unsupported" "no-tty" "no-such-device" "overflow" "not-permitted" "pipe" "read-only" "invalid-seek" "text-file-busy" "cross-device"))
    \\    (export "error-code" (type $ec (eq $ec_t)))
    \\    (type $stat_t (record (field "type" $dtype) (field "link-count" u64) (field "size" u64) (field "data-access-timestamp" (option $datetime_t)) (field "data-modification-timestamp" (option $datetime_t)) (field "status-change-timestamp" (option $datetime_t))))
    \\    (export "descriptor-stat" (type $stat (eq $stat_t)))
    \\    (type $entry_t (record (field "type" $dtype) (field "name" string)))
    \\    (export "directory-entry" (type $entry (eq $entry_t)))
    \\    (export "[method]descriptor.open-at"
    \\      (func (param "self" (borrow $descriptor)) (param "path-flags" $pflags) (param "path" string) (param "open-flags" $oflags) (param "flags" $dflags) (result (result (own $descriptor) (error $ec)))))
    \\    (export "[method]descriptor.read"
    \\      (func (param "self" (borrow $descriptor)) (param "length" u64) (param "offset" u64) (result (result (tuple (list u8) bool) (error $ec)))))
    \\    (export "[method]descriptor.write"
    \\      (func (param "self" (borrow $descriptor)) (param "buffer" (list u8)) (param "offset" u64) (result (result u64 (error $ec)))))
    \\    (export "[method]descriptor.stat"
    \\      (func (param "self" (borrow $descriptor)) (result (result $stat (error $ec)))))
    \\    (export "[method]descriptor.stat-at"
    \\      (func (param "self" (borrow $descriptor)) (param "path-flags" $pflags) (param "path" string) (result (result $stat (error $ec)))))
    \\    (export "[method]descriptor.read-directory"
    \\      (func (param "self" (borrow $descriptor)) (result (result (own $dstream) (error $ec)))))
    \\    (export "[method]directory-entry-stream.read-directory-entry"
    \\      (func (param "self" (borrow $dstream)) (result (result (option $entry) (error $ec)))))
    \\    (export "[method]descriptor.create-directory-at"
    \\      (func (param "self" (borrow $descriptor)) (param "path" string) (result (result (error $ec)))))
    \\    (export "[method]descriptor.remove-directory-at"
    \\      (func (param "self" (borrow $descriptor)) (param "path" string) (result (result (error $ec)))))
    \\    (export "[method]descriptor.unlink-file-at"
    \\      (func (param "self" (borrow $descriptor)) (param "path" string) (result (result (error $ec)))))
    \\    (export "[method]descriptor.symlink-at"
    \\      (func (param "self" (borrow $descriptor)) (param "old-path" string) (param "new-path" string) (result (result (error $ec)))))
    \\  ))
    \\  (alias export $fst "descriptor" (type $desc_t))
    \\  (alias export $fst "directory-entry-stream" (type $dstream_t))
    \\  (import "wasi:filesystem/preopens@0.2.0" (instance $pre
    \\    (export "descriptor" (type $d (eq $desc_t)))
    \\    (export "get-directories" (func (result (list (tuple (own $d) string)))))
    \\  ))
    \\  (import "wasi:cli/environment@0.2.0" (instance $envi
    \\    (export "get-environment" (func (result (list (tuple string string)))))
    \\  ))
    \\
;

const component_fs_shim =
    \\  (core module $fs_shim_m
    \\    (type $open (func (param i32 i32 i32) (result i32)))
    \\    (type $one (func (param i32)))
    \\    (type $rw (func (param i32 i64 i32 i32) (result i32)))
    \\    (type $two (func (param i32 i32) (result i32)))
    \\    (type $four (func (param i32 i32 i32 i32) (result i32)))
    \\    (table (export "$imports") 15 15 funcref)
    \\    (func (export "open") (type $open)
    \\      local.get 0 local.get 1 local.get 2 i32.const 0 call_indirect (type $open))
    \\    (func (export "close") (type $one)
    \\      local.get 0 i32.const 1 call_indirect (type $one))
    \\    (func (export "read") (type $rw)
    \\      local.get 0 local.get 1 local.get 2 local.get 3 i32.const 2 call_indirect (type $rw))
    \\    (func (export "write") (type $rw)
    \\      local.get 0 local.get 1 local.get 2 local.get 3 i32.const 3 call_indirect (type $rw))
    \\    (func (export "stat") (type $two)
    \\      local.get 0 local.get 1 i32.const 4 call_indirect (type $two))
    \\    (func (export "stat_at") (type $four)
    \\      local.get 0 local.get 1 local.get 2 local.get 3 i32.const 5 call_indirect (type $four))
    \\    (func (export "readdir_open") (type $two)
    \\      local.get 0 local.get 1 i32.const 6 call_indirect (type $two))
    \\    (func (export "readdir_next") (type $open)
    \\      local.get 0 local.get 1 local.get 2 i32.const 7 call_indirect (type $open))
    \\    (func (export "readdir_close") (type $one)
    \\      local.get 0 i32.const 8 call_indirect (type $one))
    \\    (func (export "mkdir") (type $two)
    \\      local.get 0 local.get 1 i32.const 9 call_indirect (type $two))
    \\    (func (export "rmdir") (type $two)
    \\      local.get 0 local.get 1 i32.const 10 call_indirect (type $two))
    \\    (func (export "unlink") (type $two)
    \\      local.get 0 local.get 1 i32.const 11 call_indirect (type $two))
    \\    (func (export "symlink") (type $four)
    \\      local.get 0 local.get 1 local.get 2 local.get 3 i32.const 12 call_indirect (type $four))
    \\    (func (export "getenv") (type $four)
    \\      local.get 0 local.get 1 local.get 2 local.get 3 i32.const 13 call_indirect (type $four))
    \\    (func (export "cwd") (type $two)
    \\      local.get 0 local.get 1 i32.const 14 call_indirect (type $two))
    \\  )
    \\  (core instance $fs_shim (instantiate $fs_shim_m))
    \\
;

const component_fs_adapter =
    \\  (core module $fs_scratch_m
    \\    (memory (export "memory") 4)
    \\    (global $bump (mut i32) (i32.const 65536))
    \\    (func (export "reset") i32.const 65536 global.set $bump)
    \\    (func (export "realloc") (param $old i32) (param $osz i32) (param $align i32) (param $nsz i32) (result i32)
    \\      (local $p i32)
    \\      global.get $bump local.get $align i32.const 1 i32.sub i32.add local.get $align i32.const 1 i32.sub i32.const -1 i32.xor i32.and local.set $p
    \\      local.get $p local.get $nsz i32.add global.set $bump
    \\      local.get $p))
    \\  (core instance $fs_scratch (instantiate $fs_scratch_m))
    \\  (alias core export $fs_scratch "memory" (core memory $fs_memory))
    \\  (alias core export $fs_scratch "realloc" (core func $fs_realloc))
    \\  (core func $fs_preopens (canon lower (func $pre "get-directories") (memory $fs_memory) (realloc $fs_realloc)))
    \\  (core func $fs_environment (canon lower (func $envi "get-environment") (memory $fs_memory) (realloc $fs_realloc)))
    \\  (core func $fs_open_at (canon lower (func $fst "[method]descriptor.open-at") (memory $fs_memory)))
    \\  (core func $fs_drop_descriptor (canon resource.drop $desc_t))
    \\  (core func $fs_read (canon lower (func $fst "[method]descriptor.read") (memory $fs_memory) (realloc $fs_realloc)))
    \\  (core func $fs_write (canon lower (func $fst "[method]descriptor.write") (memory $fs_memory)))
    \\  (core func $fs_stat (canon lower (func $fst "[method]descriptor.stat") (memory $fs_memory)))
    \\  (core func $fs_stat_at (canon lower (func $fst "[method]descriptor.stat-at") (memory $fs_memory)))
    \\  (core func $fs_read_directory (canon lower (func $fst "[method]descriptor.read-directory") (memory $fs_memory)))
    \\  (core func $fs_read_entry (canon lower (func $fst "[method]directory-entry-stream.read-directory-entry") (memory $fs_memory) (realloc $fs_realloc)))
    \\  (core func $fs_drop_stream (canon resource.drop $dstream_t))
    \\  (core func $fs_mkdir_at (canon lower (func $fst "[method]descriptor.create-directory-at") (memory $fs_memory)))
    \\  (core func $fs_rmdir_at (canon lower (func $fst "[method]descriptor.remove-directory-at") (memory $fs_memory)))
    \\  (core func $fs_unlink_at (canon lower (func $fst "[method]descriptor.unlink-file-at") (memory $fs_memory)))
    \\  (core func $fs_symlink_at (canon lower (func $fst "[method]descriptor.symlink-at") (memory $fs_memory)))
    \\  (core module $fs_adapter_m
    \\    (import "main" "memory" (memory $m 0))
    \\    (import "scratch" "memory" (memory $s 4))
    \\    (import "scratch" "reset" (func $reset))
    \\    (import "p2" "preopens" (func $preopens (param i32)))
    \\    (import "p2" "environment" (func $environment (param i32)))
    \\    (import "p2" "open-at" (func $open_at (param i32 i32 i32 i32 i32 i32 i32)))
    \\    (import "p2" "drop-descriptor" (func $drop_descriptor (param i32)))
    \\    (import "p2" "read" (func $p2_read (param i32 i64 i64 i32)))
    \\    (import "p2" "write" (func $p2_write (param i32 i32 i32 i64 i32)))
    \\    (import "p2" "stat" (func $p2_stat (param i32 i32)))
    \\    (import "p2" "stat-at" (func $p2_stat_at (param i32 i32 i32 i32 i32)))
    \\    (import "p2" "read-directory" (func $read_directory (param i32 i32)))
    \\    (import "p2" "read-entry" (func $read_entry (param i32 i32)))
    \\    (import "p2" "drop-stream" (func $drop_stream (param i32)))
    \\    (import "p2" "mkdir-at" (func $mkdir_at (param i32 i32 i32 i32)))
    \\    (import "p2" "rmdir-at" (func $rmdir_at (param i32 i32 i32 i32)))
    \\    (import "p2" "unlink-at" (func $unlink_at (param i32 i32 i32 i32)))
    \\    (import "p2" "symlink-at" (func $symlink_at (param i32 i32 i32 i32 i32 i32)))
    \\    (global $root (mut i32) (i32.const -1))
    \\    (global $cwdlen (mut i32) (i32.const -100))
    \\    ;; The preopens, read once: the root the host preopens is the entry named `/` (not-permitted, -32, when there is none), the working
    \\    ;; directory the first other one, whose name — its absolute path as the host sees it — is kept at 53248.
    \\    (func $getroot (result i32)
    \\      (local $p i32) (local $n i32) (local $i i32) (local $e i32) (local $len i32)
    \\      global.get $root i32.const 0 i32.ge_s (if (then global.get $root return))
    \\      call $reset
    \\      i32.const 256 call $preopens
    \\      i32.const 256 i32.load $s local.set $p
    \\      i32.const 260 i32.load $s local.set $n
    \\      (loop $each
    \\        local.get $i local.get $n i32.ge_u
    \\        (if (then global.get $root i32.const 0 i32.lt_s (if (then i32.const -32 return)) global.get $root return))
    \\        local.get $p local.get $i i32.const 12 i32.mul i32.add local.set $e
    \\        local.get $e i32.load $s offset=8 local.set $len
    \\        local.get $len i32.const 1 i32.eq
    \\        local.get $e i32.load $s offset=4 i32.load8_u $s i32.const 47 i32.eq
    \\        i32.and
    \\        (if
    \\          (then global.get $root i32.const 0 i32.lt_s (if (then local.get $e i32.load $s global.set $root)))
    \\          (else
    \\            global.get $cwdlen i32.const 0 i32.lt_s
    \\            local.get $len i32.const 4000 i32.le_u
    \\            i32.and
    \\            (if (then
    \\              i32.const 53248 local.get $e i32.load $s offset=4 local.get $len memory.copy $s $s
    \\              local.get $len global.set $cwdlen))))
    \\        local.get $i i32.const 1 i32.add local.set $i
    \\        br $each)
    \\      unreachable)
    \\    ;; `len` bytes at `src` of the program's memory into the scratch at `dst`; the empty path is `.`. Answers the length.
    \\    (func $stage (param $dst i32) (param $src i32) (param $len i32) (result i32)
    \\      local.get $len i32.eqz
    \\      (if (then local.get $dst i32.const 46 i32.store8 $s i32.const 1 return))
    \\      local.get $dst local.get $src local.get $len memory.copy $s $m
    \\      local.get $len)
    \\    ;; The failure `ec` as an answer: -(1 + ec).
    \\    (func $fail (param $ec i32) (result i32)
    \\      i32.const -1 local.get $ec i32.sub)
    \\    (func (export "open") (param $path i32) (param $len i32) (param $mode i32) (result i32)
    \\      (local $r i32) (local $oflags i32) (local $dflags i32)
    \\      local.get $len i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      call $getroot local.tee $r i32.const 0 i32.lt_s (if (then local.get $r return))
    \\      call $reset
    \\      i32.const 4096 local.get $path local.get $len call $stage local.set $len
    \\      i32.const 0 local.set $oflags
    \\      i32.const 1 local.set $dflags
    \\      local.get $mode i32.const 1 i32.eq (if (then i32.const 9 local.set $oflags i32.const 2 local.set $dflags))
    \\      local.get $mode i32.const 2 i32.eq (if (then i32.const 1 local.set $oflags i32.const 2 local.set $dflags))
    \\      local.get $mode i32.const 3 i32.eq (if (then i32.const 2 local.set $oflags i32.const 1 local.set $dflags))
    \\      local.get $r i32.const 1 i32.const 4096 local.get $len local.get $oflags local.get $dflags i32.const 256 call $open_at
    \\      i32.const 256 i32.load8_u $s
    \\      (if (result i32)
    \\        (then i32.const 260 i32.load8_u $s call $fail)
    \\        (else i32.const 260 i32.load $s)))
    \\    (func (export "close") (param $h i32)
    \\      local.get $h call $drop_descriptor)
    \\    (func (export "read") (param $h i32) (param $off i64) (param $ptr i32) (param $n i32) (result i32)
    \\      (local $len i32)
    \\      local.get $n i32.const 131072 i32.gt_u (if (then i32.const 131072 local.set $n))
    \\      call $reset
    \\      local.get $h local.get $n i64.extend_i32_u local.get $off i32.const 256 call $p2_read
    \\      i32.const 256 i32.load8_u $s
    \\      (if (then i32.const 260 i32.load8_u $s call $fail return))
    \\      i32.const 264 i32.load $s local.set $len
    \\      local.get $ptr i32.const 260 i32.load $s local.get $len memory.copy $m $s
    \\      local.get $len)
    \\    (func (export "write") (param $h i32) (param $off i64) (param $ptr i32) (param $n i32) (result i32)
    \\      (local $total i32) (local $chunk i32) (local $done i32)
    \\      (block $out
    \\        (loop $each
    \\          local.get $n i32.eqz br_if $out
    \\          local.get $n i32.const 32768 local.get $n i32.const 32768 i32.lt_u select local.set $chunk
    \\          call $reset
    \\          i32.const 16384 local.get $ptr local.get $chunk memory.copy $s $m
    \\          local.get $h i32.const 16384 local.get $chunk local.get $off i32.const 256 call $p2_write
    \\          i32.const 256 i32.load8_u $s
    \\          (if (then i32.const 264 i32.load8_u $s call $fail return))
    \\          i32.const 264 i64.load $s i32.wrap_i64 local.set $done
    \\          ;; a host that writes nothing would never finish: io
    \\          local.get $done i32.eqz (if (then i32.const 13 call $fail return))
    \\          local.get $off local.get $done i64.extend_i32_u i64.add local.set $off
    \\          local.get $ptr local.get $done i32.add local.set $ptr
    \\          local.get $total local.get $done i32.add local.set $total
    \\          local.get $n local.get $done i32.sub local.set $n
    \\          br $each))
    \\      local.get $total)
    \\    ;; The stat at 264 of the scratch (a `result<descriptor-stat, error-code>` at 256) as `out`.
    \\    (func $put_stat (param $out i32) (result i32)
    \\      i32.const 256 i32.load8_u $s
    \\      (if (then i32.const 264 i32.load8_u $s call $fail return))
    \\      local.get $out i32.const 264 i32.load8_u $s i32.store $m
    \\      local.get $out i32.const 280 i64.load $s i64.store $m offset=8
    \\      local.get $out
    \\      i32.const 312 i32.load8_u $s
    \\      (if (result i64) (then i32.const 320 i64.load $s) (else i64.const 0))
    \\      i64.store $m offset=16
    \\      i32.const 0)
    \\    (func (export "stat") (param $h i32) (param $out i32) (result i32)
    \\      call $reset
    \\      local.get $h i32.const 256 call $p2_stat
    \\      local.get $out call $put_stat)
    \\    (func (export "stat_at") (param $path i32) (param $len i32) (param $follow i32) (param $out i32) (result i32)
    \\      (local $r i32)
    \\      local.get $len i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      call $getroot local.tee $r i32.const 0 i32.lt_s (if (then local.get $r return))
    \\      call $reset
    \\      i32.const 4096 local.get $path local.get $len call $stage local.set $len
    \\      local.get $r local.get $follow i32.const 4096 local.get $len i32.const 256 call $p2_stat_at
    \\      local.get $out call $put_stat)
    \\    (func (export "readdir_open") (param $path i32) (param $len i32) (result i32)
    \\      (local $r i32) (local $d i32)
    \\      local.get $len i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      call $getroot local.tee $r i32.const 0 i32.lt_s (if (then local.get $r return))
    \\      call $reset
    \\      i32.const 4096 local.get $path local.get $len call $stage local.set $len
    \\      local.get $r i32.const 1 i32.const 4096 local.get $len i32.const 2 i32.const 1 i32.const 256 call $open_at
    \\      i32.const 256 i32.load8_u $s
    \\      (if (then i32.const 260 i32.load8_u $s call $fail return))
    \\      i32.const 260 i32.load $s local.set $d
    \\      local.get $d i32.const 256 call $read_directory
    \\      i32.const 256 i32.load8_u $s
    \\      (if (then i32.const 260 i32.load8_u $s local.set $r local.get $d call $drop_descriptor local.get $r call $fail return))
    \\      local.get $d call $drop_descriptor
    \\      i32.const 260 i32.load $s)
    \\    (func (export "readdir_next") (param $stream i32) (param $ptr i32) (param $cap i32) (result i32)
    \\      (local $len i32)
    \\      call $reset
    \\      local.get $stream i32.const 256 call $read_entry
    \\      i32.const 256 i32.load8_u $s
    \\      (if (then i32.const 260 i32.load8_u $s call $fail return))
    \\      i32.const 260 i32.load8_u $s i32.eqz (if (then i32.const -100 return))
    \\      i32.const 272 i32.load $s local.set $len
    \\      local.get $len i32.const 4 i32.add local.get $cap i32.gt_u (if (then i32.const 18 call $fail return))
    \\      local.get $ptr i32.const 264 i32.load8_u $s i32.store $m
    \\      local.get $ptr i32.const 4 i32.add i32.const 268 i32.load $s local.get $len memory.copy $m $s
    \\      local.get $len)
    \\    (func (export "readdir_close") (param $stream i32)
    \\      local.get $stream call $drop_stream)
    \\    ;; `create-directory-at` / `remove-directory-at` / `unlink-file-at`: a `result<_, error-code>` at 256.
    \\    (func $unit (result i32)
    \\      i32.const 256 i32.load8_u $s
    \\      (if (result i32) (then i32.const 257 i32.load8_u $s call $fail) (else i32.const 0)))
    \\    (func (export "mkdir") (param $path i32) (param $len i32) (result i32)
    \\      (local $r i32)
    \\      local.get $len i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      call $getroot local.tee $r i32.const 0 i32.lt_s (if (then local.get $r return))
    \\      call $reset
    \\      i32.const 4096 local.get $path local.get $len call $stage local.set $len
    \\      local.get $r i32.const 4096 local.get $len i32.const 256 call $mkdir_at
    \\      call $unit)
    \\    (func (export "rmdir") (param $path i32) (param $len i32) (result i32)
    \\      (local $r i32)
    \\      local.get $len i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      call $getroot local.tee $r i32.const 0 i32.lt_s (if (then local.get $r return))
    \\      call $reset
    \\      i32.const 4096 local.get $path local.get $len call $stage local.set $len
    \\      local.get $r i32.const 4096 local.get $len i32.const 256 call $rmdir_at
    \\      call $unit)
    \\    (func (export "unlink") (param $path i32) (param $len i32) (result i32)
    \\      (local $r i32)
    \\      local.get $len i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      call $getroot local.tee $r i32.const 0 i32.lt_s (if (then local.get $r return))
    \\      call $reset
    \\      i32.const 4096 local.get $path local.get $len call $stage local.set $len
    \\      local.get $r i32.const 4096 local.get $len i32.const 256 call $unlink_at
    \\      call $unit)
    \\    (func (export "symlink") (param $target i32) (param $tlen i32) (param $link i32) (param $llen i32) (result i32)
    \\      (local $r i32)
    \\      local.get $tlen i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      local.get $llen i32.const 4095 i32.gt_u (if (then i32.const 18 call $fail return))
    \\      call $getroot local.tee $r i32.const 0 i32.lt_s (if (then local.get $r return))
    \\      call $reset
    \\      i32.const 4096 local.get $target local.get $tlen call $stage local.set $tlen
    \\      i32.const 8192 local.get $link local.get $llen call $stage local.set $llen
    \\      local.get $r i32.const 4096 local.get $tlen i32.const 8192 local.get $llen i32.const 256 call $symlink_at
    \\      call $unit)
    \\    ;; The working directory's absolute path: its length (all of it, however much of it `cap` held), -100 when the host preopens none.
    \\    (func (export "cwd") (param $ptr i32) (param $cap i32) (result i32)
    \\      (local $len i32)
    \\      call $getroot drop
    \\      global.get $cwdlen local.set $len
    \\      local.get $len i32.const 0 i32.lt_s (if (then i32.const -100 return))
    \\      local.get $ptr i32.const 53248 local.get $len local.get $cap local.get $len local.get $cap i32.lt_u select memory.copy $m $s
    \\      local.get $len)
    \\    ;; The value of the variable named `name`: its length (all of it, however much of it `cap` held), -100 when it is not set.
    \\    (func (export "getenv") (param $name i32) (param $nlen i32) (param $ptr i32) (param $cap i32) (result i32)
    \\      (local $p i32) (local $n i32) (local $i i32) (local $e i32) (local $j i32) (local $same i32) (local $vlen i32)
    \\      local.get $nlen i32.const 4095 i32.gt_u (if (then i32.const -100 return))
    \\      call $reset
    \\      i32.const 4096 local.get $name local.get $nlen memory.copy $s $m
    \\      i32.const 256 call $environment
    \\      i32.const 256 i32.load $s local.set $p
    \\      i32.const 260 i32.load $s local.set $n
    \\      (loop $each
    \\        local.get $i local.get $n i32.ge_u (if (then i32.const -100 return))
    \\        local.get $p local.get $i i32.const 16 i32.mul i32.add local.set $e
    \\        local.get $e i32.load $s offset=4 local.get $nlen i32.eq
    \\        (if (then
    \\          i32.const 1 local.set $same
    \\          i32.const 0 local.set $j
    \\          (block $cmp (loop $bytes
    \\            local.get $j local.get $nlen i32.ge_u br_if $cmp
    \\            local.get $e i32.load $s local.get $j i32.add i32.load8_u $s
    \\            i32.const 4096 local.get $j i32.add i32.load8_u $s
    \\            i32.ne (if (then i32.const 0 local.set $same br $cmp))
    \\            local.get $j i32.const 1 i32.add local.set $j
    \\            br $bytes))
    \\          local.get $same
    \\          (if (then
    \\            local.get $e i32.load $s offset=12 local.set $vlen
    \\            local.get $ptr local.get $e i32.load $s offset=8
    \\            local.get $vlen local.get $cap local.get $vlen local.get $cap i32.lt_u select
    \\            memory.copy $m $s
    \\            local.get $vlen return))))
    \\        local.get $i i32.const 1 i32.add local.set $i
    \\        br $each)
    \\      unreachable)
    \\  )
    \\  (core instance $fs_p2
    \\    (export "preopens" (func $fs_preopens))
    \\    (export "environment" (func $fs_environment))
    \\    (export "open-at" (func $fs_open_at))
    \\    (export "drop-descriptor" (func $fs_drop_descriptor))
    \\    (export "read" (func $fs_read))
    \\    (export "write" (func $fs_write))
    \\    (export "stat" (func $fs_stat))
    \\    (export "stat-at" (func $fs_stat_at))
    \\    (export "read-directory" (func $fs_read_directory))
    \\    (export "read-entry" (func $fs_read_entry))
    \\    (export "drop-stream" (func $fs_drop_stream))
    \\    (export "mkdir-at" (func $fs_mkdir_at))
    \\    (export "rmdir-at" (func $fs_rmdir_at))
    \\    (export "unlink-at" (func $fs_unlink_at))
    \\    (export "symlink-at" (func $fs_symlink_at)))
    \\  (core instance $fs_adapter (instantiate $fs_adapter_m
    \\    (with "main" (instance $main))
    \\    (with "scratch" (instance $fs_scratch))
    \\    (with "p2" (instance $fs_p2))))
    \\  (core module $fs_fixup
    \\    (import "" "$imports" (table 15 15 funcref))
    \\    (import "" "open" (func $open (param i32 i32 i32) (result i32)))
    \\    (import "" "close" (func $close (param i32)))
    \\    (import "" "read" (func $read (param i32 i64 i32 i32) (result i32)))
    \\    (import "" "write" (func $write (param i32 i64 i32 i32) (result i32)))
    \\    (import "" "stat" (func $stat (param i32 i32) (result i32)))
    \\    (import "" "stat_at" (func $stat_at (param i32 i32 i32 i32) (result i32)))
    \\    (import "" "readdir_open" (func $readdir_open (param i32 i32) (result i32)))
    \\    (import "" "readdir_next" (func $readdir_next (param i32 i32 i32) (result i32)))
    \\    (import "" "readdir_close" (func $readdir_close (param i32)))
    \\    (import "" "mkdir" (func $mkdir (param i32 i32) (result i32)))
    \\    (import "" "rmdir" (func $rmdir (param i32 i32) (result i32)))
    \\    (import "" "unlink" (func $unlink (param i32 i32) (result i32)))
    \\    (import "" "symlink" (func $symlink (param i32 i32 i32 i32) (result i32)))
    \\    (import "" "getenv" (func $getenv (param i32 i32 i32 i32) (result i32)))
    \\    (import "" "cwd" (func $cwd (param i32 i32) (result i32)))
    \\    (elem (i32.const 0) func $open $close $read $write $stat $stat_at $readdir_open $readdir_next $readdir_close $mkdir $rmdir $unlink $symlink $getenv $cwd))
    \\  (core instance (instantiate $fs_fixup (with "" (instance
    \\    (export "$imports" (table $fs_shim "$imports"))
    \\    (export "open" (func $fs_adapter "open"))
    \\    (export "close" (func $fs_adapter "close"))
    \\    (export "read" (func $fs_adapter "read"))
    \\    (export "write" (func $fs_adapter "write"))
    \\    (export "stat" (func $fs_adapter "stat"))
    \\    (export "stat_at" (func $fs_adapter "stat_at"))
    \\    (export "readdir_open" (func $fs_adapter "readdir_open"))
    \\    (export "readdir_next" (func $fs_adapter "readdir_next"))
    \\    (export "readdir_close" (func $fs_adapter "readdir_close"))
    \\    (export "mkdir" (func $fs_adapter "mkdir"))
    \\    (export "rmdir" (func $fs_adapter "rmdir"))
    \\    (export "unlink" (func $fs_adapter "unlink"))
    \\    (export "symlink" (func $fs_adapter "symlink"))
    \\    (export "getenv" (func $fs_adapter "getenv"))
    \\    (export "cwd" (func $fs_adapter "cwd"))))))
    \\
;

const component_run_export =
    \\  (func $run (result (result)) (canon lift (core func $adapter "run")))
    \\  (instance $run_instance (export "run" (func $run)))
    \\  (export "wasi:cli/run@0.2.0" (instance $run_instance))
    \\
;

/// One top-level form, in the module's two-space item column.
fn renderItem(w: *Writer, defs: Defs, it: ast.Item) Error!void {
    switch (it) {
        .types => |types| try recGroup(w, types),
        .import => |im| try import(w, defs, im),
        .memory => |mem| try memory(w, mem),
        .start => |name| try w.print("  (start ${f})\n", .{id(name)}),
        .table => |names| {
            try w.writeAll("  (table funcref (elem");
            for (names) |n| try w.print(" ${f}", .{id(n)});
            try w.writeAll("))\n");
        },
        .data => |d| try dataSegment(w, d),
        .global => |g| try global(w, defs, g),
        .func => |f| try func(w, defs, f),
        .comment => |text| try w.print("  ;; {s}\n", .{text}),
        .tag => |t| {
            try w.print("  (tag ${f}", .{id(t.name)});
            if (t.params.len > 0) {
                try w.writeAll(" (param");
                for (t.params) |p| try typeText(w, defs, p, " ");
                try w.writeAll(")");
            }
            try w.writeAll(")\n");
        },
        .custom => |c| {
            try w.print("  (@custom \"{s}\" \"", .{c.name});
            for (c.bytes) |b| if (b < 0x20 or b >= 0x7f or b == '"' or b == '\\')
                try w.print("\\{x:0>2}", .{b})
            else
                try w.writeByte(b);
            try w.writeAll("\")\n");
        },
    }
}

// ── forms ────────────────────────────────────────────────────────────────────

fn import(w: *Writer, defs: Defs, im: ast.Import) Error!void {
    try w.print("  (import \"{s}\" \"{s}\" (func ${f}", .{ im.module, im.name, id(im.func) });
    if (im.type.params.len > 0) {
        try w.writeAll(" (param");
        for (im.type.params) |p| try typeText(w, defs, p, " ");
        try w.writeAll(")");
    }
    if (im.type.result) |r| try resultText(w, defs, r);
    try w.writeAll("))\n");
}

fn memory(w: *Writer, mem: ast.Memory) Error!void {
    try w.writeAll("  (memory");
    if (mem.@"export") |e| try w.print(" (export \"{s}\")", .{e});
    try w.print(" {d}", .{mem.min_pages});
    if (mem.max_pages) |max| try w.print(" {d}", .{max});
    try w.writeAll(")\n");
}

fn global(w: *Writer, defs: Defs, g: ast.Global) Error!void {
    try w.print("  (global ${f}", .{id(g.name)});
    for (g.exports) |e| try w.print(" (export \"{s}\")", .{e});
    if (g.mutable) {
        try w.writeAll(" (mut");
        try typeText(w, defs, g.ty, " ");
        try w.writeAll(")");
    } else try typeText(w, defs, g.ty, " ");
    // A reference global starts null (WasmGC); a number at its numeral.
    if (g.ty.isRef()) {
        try w.writeAll(" (ref.null");
        try heapText(w, defs, g.ty);
        try w.writeAll("))\n");
    } else try w.print(" ({s}.const {s}))\n", .{ g.ty.text(), g.init });
}

fn func(w: *Writer, defs: Defs, f: ast.Func) Error!void {
    try w.print("  (func ${f}", .{id(f.name)});
    for (f.exports) |e| try w.print(" (export \"{s}\")", .{e});
    for (f.params) |p| {
        try w.print(" (param ${f}", .{id(p.name)});
        try typeText(w, defs, p.ty, " ");
        try w.writeAll(")");
    }
    if (f.result) |r| try resultText(w, defs, r);
    try w.writeAll("\n");
    // `(local …)` lives between the signature and the first instruction — the
    // only place WAT accepts it, and the reason locals are a field of the
    // function node instead of an instruction.
    for (f.locals) |group| {
        try w.writeAll("    ");
        for (group, 0..) |l, i| {
            if (i > 0) try w.writeAll(" ");
            try w.print("(local ${f}", .{id(l.name)});
            try typeText(w, defs, l.ty, " ");
            try w.writeAll(")");
        }
        try w.writeAll("\n");
    }
    try seq(w, defs, f.body);
    try w.writeAll("  )\n");
}

// ── GC types (WasmGC, decision 544) ─────────────────────────────────────────

/// The module's GC types, by index — what spells a `(ref null $t)`.
const Defs = []const ast.TypeDef;

/// A value or storage type, after `sep`: its keyword, or `(ref null $t)`.
fn typeText(w: *Writer, defs: Defs, t: ast.ValType, sep: []const u8) Error!void {
    try w.writeAll(sep);
    if (t.defIndex()) |k| {
        if (k >= defs.len) return error.UndefinedType;
        return w.print("(ref null ${f})", .{id(defs[k].name)});
    }
    try w.writeAll(t.text());
}

fn resultText(w: *Writer, defs: Defs, t: ast.ValType) Error!void {
    try w.writeAll(" (result");
    try typeText(w, defs, t, " ");
    try w.writeAll(")");
}

/// A heap type after a space: `any`, `eq`, … or `$t`.
fn heapText(w: *Writer, defs: Defs, t: ast.ValType) Error!void {
    if (t.defIndex()) |k| {
        if (k >= defs.len) return error.UndefinedType;
        return w.print(" ${f}", .{id(defs[k].name)});
    }
    try w.print(" {s}", .{t.heapText() orelse return error.UndefinedType});
}

fn typeName(defs: Defs, k: u16) Error![]const u8 {
    if (k >= defs.len) return error.UndefinedType;
    return defs[k].name;
}

/// `$f` for a named field, its index otherwise.
fn fieldText(w: *Writer, defs: Defs, r: ast.FieldRef) Error!void {
    const fields = switch (defs[r.ty].kind) {
        .@"struct" => |f| f,
        .array => return error.UndefinedType,
    };
    if (fields[r.field].name) |n| return w.print(" ${f}", .{id(n)});
    try w.print(" {d}", .{r.field});
}

fn fieldType(w: *Writer, defs: Defs, f: ast.Field) Error!void {
    if (f.mutable) {
        try w.writeAll("(mut");
        try typeText(w, defs, f.ty, " ");
        try w.writeAll(")");
    } else try typeText(w, defs, f.ty, "");
}

/// `(rec (type $a (struct (field $x i32) …)) (type $s (array (mut i8))) …)`.
fn recGroup(w: *Writer, types: []const ast.TypeDef) Error!void {
    try w.writeAll("  (rec\n");
    for (types) |t| {
        try w.print("    (type ${f} ", .{id(t.name)});
        const sub = !t.final or t.super != null;
        if (sub) {
            try w.writeAll("(sub ");
            if (t.final) try w.writeAll("final ");
            if (t.super) |k| try w.print("${f} ", .{id(types[k].name)});
        }
        switch (t.kind) {
            .@"struct" => |fields| {
                try w.writeAll("(struct");
                for (fields) |f| {
                    try w.writeAll(" (field");
                    if (f.name) |n| try w.print(" ${f}", .{id(n)});
                    try w.writeAll(" ");
                    try fieldType(w, types, f);
                    try w.writeAll(")");
                }
                try w.writeAll(")");
            },
            .array => |f| {
                try w.writeAll("(array ");
                try fieldType(w, types, f);
                try w.writeAll(")");
            },
        }
        if (sub) try w.writeAll(")");
        try w.writeAll(")\n");
    }
    try w.writeAll("  )\n");
}

/// `(data (i32.const off) "…")` — the four-byte little-endian length prefix
/// every string carries, then the bytes; a raw segment (no prefix) is its
/// bytes alone.
fn dataSegment(w: *Writer, d: ast.DataSegment) Error!void {
    if (d.passive) |n|
        try w.print("  (data ${f} \"", .{id(n)})
    else
        try w.print("  (data (i32.const {d}) \"", .{d.offset});
    if (d.len_prefix) |len| {
        const prefix = [4]u8{ @truncate(len), @truncate(len >> 8), @truncate(len >> 16), @truncate(len >> 24) };
        for (prefix) |c| try w.print("\\{x:0>2}", .{c});
    }
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

fn seq(w: *Writer, defs: Defs, s: ast.Seq) Error!void {
    for (s.lines) |l| try line(w, defs, l);
}

fn indent(w: *Writer, n: u8) Error!void {
    for (0..n) |_| try w.writeAll(" ");
}

fn line(w: *Writer, defs: Defs, l: ast.Line) Error!void {
    switch (l.instr) {
        .@"if" => |n| return ifForm(w, defs, l.indent, n),
        .block => |b| return blockForm(w, defs, l.indent, b),
        .comment => |text| {
            try indent(w, l.indent);
            return w.print(";; {s}\n", .{text});
        },
        else => {},
    }
    try indent(w, l.indent);
    if (l.folded) try w.writeAll("(");
    try instr(w, defs, l.instr);
    if (l.folded) try w.writeAll(")");
    if (l.comment) |c| try w.print(" ;; {s}", .{c});
    try w.writeAll("\n");
}

fn ifForm(w: *Writer, defs: Defs, col: u8, n: ast.If) Error!void {
    try indent(w, col);
    try w.writeAll("(if");
    if (n.label) |l| try w.print(" ${f}", .{id(l)});
    if (n.result) |r| try resultText(w, defs, r);
    try w.writeAll("\n");
    try arm(w, defs, col + 2, "then", n.then);
    if (n.@"else") |e| try arm(w, defs, col + 2, "else", e);
    try indent(w, col);
    try w.writeAll(")\n");
}

fn arm(w: *Writer, defs: Defs, col: u8, keyword: []const u8, a: ast.If.Arm) Error!void {
    try indent(w, col);
    try w.print("({s}", .{keyword});
    switch (a.layout) {
        .inline_ => {
            for (a.seq.lines) |l| {
                try w.writeAll(" ");
                try instr(w, defs, l.instr);
            }
            try w.writeAll(")\n");
        },
        .block => {
            try w.writeAll("\n");
            try seq(w, defs, a.seq);
            try indent(w, col);
            try w.writeAll(")\n");
        },
    }
}

fn blockForm(w: *Writer, defs: Defs, col: u8, b: ast.Block) Error!void {
    try indent(w, col);
    try w.print("({s}", .{@tagName(b.kind)});
    if (b.label) |l| try w.print(" ${f}", .{id(l)});
    if (b.result) |r| try resultText(w, defs, r);
    for (b.catches) |c| try w.print(" (catch ${f} ${f})", .{ id(c.tag), id(c.label) });
    try w.writeAll("\n");
    try seq(w, defs, b.body);
    try indent(w, col);
    try w.writeAll(")\n");
}

/// The instruction itself, with no indentation, comment or newline — so an
/// inline `if` arm can put several on one line.
fn instr(w: *Writer, defs: Defs, i: ast.Instr) Error!void {
    switch (i) {
        .@"const" => |c| try w.print("{s}.const {s}", .{ c.ty.text(), c.text }),
        .local_get => |n| try w.print("local.get ${f}", .{id(n)}),
        .local_set => |n| try w.print("local.set ${f}", .{id(n)}),
        .local_tee => |n| try w.print("local.tee ${f}", .{id(n)}),
        .global_get => |n| try w.print("global.get ${f}", .{id(n)}),
        .global_set => |n| try w.print("global.set ${f}", .{id(n)}),
        .op => |o| try w.print("{s}.{s}", .{ o.ty.text(), o.name }),
        .convert => |o| try w.writeAll(o),
        .load => |m| {
            try w.print("{s}.load", .{m.ty.text()});
            if (m.width.bits()) |b| try w.print("{d}_{s}", .{ b, if (m.signed) "s" else "u" });
            if (m.offset != 0) try w.print(" offset={d}", .{m.offset});
        },
        .store => |m| {
            try w.print("{s}.store", .{m.ty.text()});
            if (m.width.bits()) |b| try w.print("{d}", .{b});
            if (m.offset != 0) try w.print(" offset={d}", .{m.offset});
        },
        .call => |n| try w.print("call ${f}", .{id(n)}),
        .call_indirect => |t| {
            try w.writeAll("call_indirect");
            if (t.params.len > 0) {
                try w.writeAll(" (param");
                for (t.params) |p| try typeText(w, defs, p, " ");
                try w.writeAll(")");
            }
            if (t.result) |r| try resultText(w, defs, r);
        },
        .br => |l| try w.print("br ${f}", .{id(l)}),
        .br_if => |l| try w.print("br_if ${f}", .{id(l)}),
        .drop => try w.writeAll("drop"),
        .@"return" => try w.writeAll("return"),
        .@"unreachable" => try w.writeAll("unreachable"),
        .memory_copy => try w.writeAll("memory.copy"),
        .memory_fill => try w.writeAll("memory.fill"),
        .select => try w.writeAll("select"),
        .br_table => |t| {
            try w.writeAll("br_table");
            for (t.labels) |l| try w.print(" ${f}", .{id(l)});
            try w.print(" ${f}", .{id(t.default)});
        },
        .memory_size => try w.writeAll("memory.size"),
        .memory_grow => try w.writeAll("memory.grow"),
        .throw => |t| try w.print("throw ${f}", .{id(t)}),
        .comment => |text| try w.print(";; {s}", .{text}),
        .struct_new => |k| try w.print("struct.new ${f}", .{id(try typeName(defs, k))}),
        .struct_new_default => |k| try w.print("struct.new_default ${f}", .{id(try typeName(defs, k))}),
        .struct_get => |r| {
            try w.print("struct.get{s} ${f}", .{ extText(r.ext), id(try typeName(defs, r.ty)) });
            try fieldText(w, defs, r);
        },
        .struct_set => |r| {
            try w.print("struct.set ${f}", .{id(try typeName(defs, r.ty))});
            try fieldText(w, defs, r);
        },
        .array_new => |k| try w.print("array.new ${f}", .{id(try typeName(defs, k))}),
        .array_new_default => |k| try w.print("array.new_default ${f}", .{id(try typeName(defs, k))}),
        .array_new_fixed => |a| try w.print("array.new_fixed ${f} {d}", .{ id(try typeName(defs, a.ty)), a.n }),
        .array_new_data => |a| try w.print("array.new_data ${f} ${f}", .{ id(try typeName(defs, a.ty)), id(a.data) }),
        .array_get => |a| try w.print("array.get{s} ${f}", .{ extText(a.ext), id(try typeName(defs, a.ty)) }),
        .array_set => |k| try w.print("array.set ${f}", .{id(try typeName(defs, k))}),
        .array_len => try w.writeAll("array.len"),
        .array_copy => |a| try w.print("array.copy ${f} ${f}", .{ id(try typeName(defs, a.dst)), id(try typeName(defs, a.src)) }),
        .array_fill => |k| try w.print("array.fill ${f}", .{id(try typeName(defs, k))}),
        .ref_null => |t| {
            try w.writeAll("ref.null");
            try heapText(w, defs, t);
        },
        .ref_is_null => try w.writeAll("ref.is_null"),
        .ref_eq => try w.writeAll("ref.eq"),
        .ref_as_non_null => try w.writeAll("ref.as_non_null"),
        .ref_test => |t| {
            try w.writeAll("ref.test (ref null");
            try heapText(w, defs, t);
            try w.writeAll(")");
        },
        .ref_cast => |t| {
            try w.writeAll("ref.cast (ref null");
            try heapText(w, defs, t);
            try w.writeAll(")");
        },
        .ref_i31 => try w.writeAll("ref.i31"),
        .i31_get => |signed| try w.writeAll(if (signed) "i31.get_s" else "i31.get_u"),
        // Structured forms own their own lines; `line`/`arm` never reach here.
        .@"if", .block => unreachable,
    }
}

fn extText(e: ast.Ext) []const u8 {
    return switch (e) {
        .none => "",
        .s => "_s",
        .u => "_u",
    };
}

// ── tests ────────────────────────────────────────────────────────────────────

fn renderToString(alloc: std.mem.Allocator, m: ast.Module) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(alloc);
    errdefer aw.deinit();
    try renderModule(&aw.writer, m);
    return aw.toOwnedSlice();
}

test "wat_emitter: a backtick name is escaped to WAT idchars" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try aw.writer.print("${f} ${f} ${f}", .{ id("`add one`"), id("`a\\b`"), id("plain_name") });
    try std.testing.expectEqualStrings("$`add\\20one` $`a\\5cb` $plain_name", aw.written());
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
        // `wat.zig`'s decision 442 (1): a print helper calls std-wasm for a
        // number's text, transpiled in; std-wasm calls the program's allocator.
        var std_arena = std.heap.ArenaAllocator.init(alloc);
        defer std_arena.deinit();
        var wanted: std.ArrayListUnmanaged([]const u8) = .empty;
        for (prelude.order) |og| if (set.has(og)) try wanted.appendSlice(std_arena.allocator(), og.stdCalls());
        if (wanted.items.len > 0) set.require(.alloc);
        var items: std.ArrayListUnmanaged(ast.Item) = .empty;
        defer items.deinit(alloc);
        // Front 164 s2: a GC module's group names `$str`, the first type of its group.
        if (set.has(.std_marshal)) try items.append(alloc, .{ .types = &.{prelude.gc_str_def} });
        if (set.has(.print)) try items.append(alloc, .{ .import = prelude.fd_write_import });
        if (set.has(.wasi_random_f64)) try items.append(alloc, .{ .import = prelude.random_get_import });
        if (set.has(.fs_host)) for (prelude.fs_imports) |im| try items.append(alloc, .{ .import = im });
        if (set.has(.task_host)) {
            try items.append(alloc, .{ .import = prelude.bp_host_delay_import });
            try items.append(alloc, .{ .import = prelude.bp_host_wait_import });
            try items.append(alloc, .{ .import = prelude.bp_host_drop_import });
        }
        // Decision 518: a module raising its aborts declares the tag
        // (`wat.zig` adds it with `Emitter.exceptions`).
        if (set.has(.panic_raise) or set.has(.wasi_attempt)) try items.append(alloc, .{ .tag = prelude.panic_tag });
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
        if (wanted.items.len > 0) {
            var diag: @import("std_wasm_link.zig").Diag = .{};
            const l = try @import("std_wasm_link.zig").link(std_arena.allocator(), wanted.items, 256, &diag);
            try items.appendSlice(alloc, l.items);
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

test "GC types render as one rec group, a reference by its type's name (decision 544)" {
    const alloc = std.testing.allocator;
    const out = try renderToString(alloc, @import("wasm_binary_emitter.zig").gc_test_module);
    defer alloc.free(out);
    try std.testing.expectEqualStrings(
        \\(module
        \\  (rec
        \\    (type $str (array (mut i8)))
        \\    (type $pt (struct (field $x i32) (field $s (ref null $str))))
        \\  )
        \\  (data $hi "hi")
        \\  (func $f (export "f") (result i32)
        \\    (local $p (ref null $pt))
        \\    i32.const 7
        \\    i32.const 0
        \\    i32.const 2
        \\    array.new_data $str $hi
        \\    struct.new $pt
        \\    local.set $p
        \\    local.get $p
        \\    struct.get $pt $s
        \\    array.len
        \\    local.get $p
        \\    struct.get $pt $x
        \\    i32.add
        \\  )
        \\)
        \\
    , out);
}
