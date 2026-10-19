//! The embedded prelude, `primitives.bp` and its compiler section (the latter with std's
//! `print` and `panic`), parsed once for
//! the life of the process — what the emitters read a `default fn`'s helpers
//! from (`stringSlice0`'s declared return, its `.Wasm(…)` cell) and the
//! prelude's declarations' implementations (`ast.Implementation`, decision
//! 575 (6)): no emitter parses the prelude itself.
//!
//! `emitErlangModule` re-lexed and re-parsed it (`collectPrimErlangDispatch`)
//! on EVERY emission, and the source is a comptime-embedded string — the same
//! bytes, the same parse, every time. On a
//! comptime-heavy build that is one whole parse per evaluated declaration
//! (handed over by `14-comptime-on-beam`, whose step 2 left this as the other
//! half of the per-evaluation cost).
//!
//! The memo is safe because nothing writes to what it holds: the AST borrows
//! only comptime source, and every caller deep-copies what it keeps into its
//! own allocator. It has its own arena over the page allocator rather than a
//! caller's, so a test allocator never sees it and the lifetime is the
//! process's, not one module's. The lock is a spin over `std.atomic.Mutex`'s
//! `tryLock` — zig 0.16 has no blocking mutex outside `std.Io`, and there is
//! nothing to contend for after the first parse — because the test runner
//! compiles on several threads and an arena is not thread-safe.
const std = @import("std");
const ast = @import("../ast.zig");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const prelude = @import("std_prelude");

var mutex: std.atomic.Mutex = .unlocked;
var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var primitives_tried: bool = false;
var primitives_program: ?ast.Program = null;
var builtins_tried: bool = false;
var builtins_program: ?ast.Program = null;

fn lock() void {
    while (!mutex.tryLock()) std.atomic.spinLoopHint();
}

/// The parsed `primitives.bp`, or null when it does not parse — the callers
/// have always swallowed a prelude parse failure, and `primErlangDispatchCount`
/// pins what that would cost.
pub fn primitives() ?ast.Program {
    lock();
    defer mutex.unlock();
    if (primitives_tried) return primitives_program;
    primitives_tried = true;
    const a = arena.allocator();
    var lx = lexerMod.Lexer.init(prelude.primitives);
    const tokens = lx.scanAll(a) catch return null;
    var p = parserMod.Parser.init(tokens);
    primitives_program = p.parse(a) catch null;
    return primitives_program;
}

/// The parsed `primitives.bp`'s compiler section, with std's `print` and `panic` as their modules
/// write them (`io/terminal.bp`, `failure.bp`, decision 606 (2)) — the
/// implementations the backends dispatch those calls by —, or null when it
/// does not parse.
pub fn builtins() ?ast.Program {
    lock();
    defer mutex.unlock();
    if (builtins_tried) return builtins_program;
    builtins_tried = true;
    const a = arena.allocator();
    const fns = (@import("../comptime/std_calls.zig").declarationsText(a) catch return null) orelse return null;
    const text = std.mem.concat(a, u8, &.{ prelude.builtins, "\n", fns }) catch return null;
    var lx = lexerMod.Lexer.init(text);
    const tokens = lx.scanAll(a) catch return null;
    var p = parserMod.Parser.init(tokens);
    const parsed = p.parse(a) catch return null;
    // `panic` keeps the backends' own per-arity dispatch (its default).
    var kept: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (parsed.decls) |d| {
        if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, "panic")) continue;
        kept.append(a, d) catch return null;
    }
    builtins_program = .{ .decls = kept.items };
    return builtins_program;
}

/// The prelude's free `fn` named `name` (`stringSlice0`), or null.
pub fn freeFn(name: []const u8) ?ast.FnDecl {
    const prog = primitives() orelse return null;
    for (prog.decls) |d| if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, name)) return d.@"fn";
    return null;
}
