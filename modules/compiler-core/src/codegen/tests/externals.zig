//! codegen: `#[@External.<Target>(…)]` FFI declarations.
//! Erlang lowers calls to the remote `module:symbol(…)`; CommonJS imports the
//! host symbol under the fn name via `require`.

const std = @import("std");
const h = @import("helpers.zig");
const codegen = @import("../../codegen.zig");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");

// The module+symbol form names a module that exists on each host (the node
// builtin `node:path`, OTP's `filename`), so the RUN LOG is the call's value.
test "js: external ---- call emits module symbol" {
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang("filename", "basename"),
        \\  @External.Node("node:path", "basename")]
        \\pub declare fn basename(p: string) -> string;
        \\
        \\fn main() {
        \\    @print(basename("/tmp/notes.txt"));
        \\}
    );
}

test "js: external ---- global math" {
    // `Math` is a JS global, not a module — the node target must reference
    // it directly (`const floor = Math.floor;`), never `require("Math")`.
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang("math", "floor"),
        \\  @External.Node("Math", "floor")]
        \\pub declare fn floor(n: f64) -> f64;
        \\
        \\fn main() {
        \\    @print(floor(1.7));
        \\}
    );
}

test "js: external ---- import binds symbol" {
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang("filename", "extension"),
        \\  @External.Node("node:path", "extname")]
        \\pub declare fn extname(p: string) -> string;
        \\
        \\fn main() {
        \\    @print(extname("docs/readme.md"));
        \\}
    );
}

// ── External.<Target> typed-enum annotation form ────────────────────────────
// The enum-variant form (`#[@External.Erlang("template")]`) is the only
// form. Codegen reads `annotations[]` directly looking for `External.<target>`.

test "js: External.<Target> ---- template equivalent to @external(target, template)" {
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang("filename", "dirname"),
        \\  @External.Node("node:path", "dirname")]
        \\pub declare fn dirname(p: string) -> string;
        \\
        \\fn main() {
        \\    @print(dirname("/tmp/notes.txt"));
        \\}
    );
}

test "js: External.<Target> ---- mixed with @external() in one decl" {
    // Migration-friendly: a single decl may use the new form for one target
    // and the legacy form for another while a codebase migrates.
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang( "math", "floor"),
        \\  @External.Node("Math", "floor")]
        \\pub declare fn floor(n: f64) -> f64;
        \\
        \\fn main() {
        \\    @print(floor(1.7));
        \\}
    );
}

// net-new (A1): an `#[@External.<targert>(...)]` fn that declares a target only
// for another backend (erlang) has NO node target — calling it while generating
// commonJS fails. 06 C13: the failure is a LOCATED diagnostic naming the
// function and the backend, carried by the module like a type error, not the
// bare `error.MissingExternalTarget` that aborted the whole build and printed
// only its own name.
test "js: external ---- net-new: no target for the active backend errors" {
    const io = std.testing.io;
    const src =
        \\#[@External.Erlang( "string", "length")]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    @print(str_length("hello"));
        \\}
    ;
    // configs[0] is the commonJS/node target.
    // `generate` drops a module carrying a diagnostic; `generateWith` is the
    // entry that hands every module back, which is how the CLI reads them.
    var outputs = try codegen.generateWith(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        h.configs[0],
        .{ .execute = false },
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(std.testing.allocator);
        outputs.deinit(std.testing.allocator);
    }
    try std.testing.expectEqual(@as(usize, 1), outputs.items.len);
    const diag = outputs.items[0].result.diagnostic orelse return error.TestExpectedDiagnostic;
    try std.testing.expect(diag == .type);
    try std.testing.expect(std.mem.indexOf(u8, diag.type.message, "str_length") != null);
    try std.testing.expect(std.mem.indexOf(u8, diag.type.message, "node") != null);
    try std.testing.expect(diag.type.loc != null);
}

// §A2: a chained host-call template (`Buffer.from($0).toString('base64')`)
// renders verbatim at the call site — no aliasing, no receiver-stripping.
// The 2-arg `#\[@External\.node("<template>")]` form is detected by the `$`
// marker; the template body lives in `user_node_templates` and renders
// inline (mirrors the erlang backend's existing template path).
test "js: external ---- A2 chained host call renders verbatim" {
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang("base64:encode($0)"),
        \\  @External.Node("""Buffer.from($0, 'utf8').toString('base64')""")]
        \\pub declare fn b64encode(s: string) -> string;
        \\
        \\fn main() {
        \\    @print(b64encode("hi"));
        \\}
    );
}

// §A2: an `#[@External.Node(…)]` template that resolves a method on a
// non-static global keeps the receiver bound (the legacy alias shape
// `const fn = JSON.stringify` would strip `this` on a method-on-class
// chain; the §A2 template renders the chain inline at every call).
// Uses `JSON.stringify($0)` (rather than `performance.now(...)`) so the
// run-log captures a deterministic value.
test "js: external ---- A2 method-on-global template keeps receiver bound" {
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang("iolist_to_binary(io_lib:format(\"~p\", [$0]))"),
        \\  @External.Node("JSON.stringify($0)")]
        \\declare fn stringify(value: i32) -> string;
        \\
        \\fn main() {
        \\    @print(stringify(42));
        \\}
    );
}

// §A3: a `declare fn` paired with `@external` accepts the
// effect annotation because the host template owns the wrapper shape.
// The fn's return type is `@Result<R, E>`; the template renders an
// `{ ok: ... } | { error: ... }` shape on Node and `{ok, _} | {error, _}`
// on Erlang. Without §A3 this declare reds at R1 (effect on declare).
test "js: external ---- A3 result-template-owned declare fn" {
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Erlang( """(fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)($0)"""),
        \\  @External.Node("""(() => { const __n = Number($0); return Number.isFinite(__n) ? { ok: __n } : { error: "not a number" } })()""")]
        \\pub declare fn parseInt(s: string) -> @Result<i32, string>;
        \\
        \\fn main() {
        \\    val r = parseInt("42");
        \\    @print(r.unwrapOr(-1));
        \\}
    );
}

// std-surface 6d: a `declare fn` whose `@External.Node` is a template renders
// at each call site — no import binding, no `require(…)`.
test "js: external ---- template declare fn emits no require" {
    const src =
        \\#[@External.Node("""Math.max($0, $1)""")]
        \\declare fn biggest(a: i32, b: i32) -> i32;
        \\
        \\fn main() {
        \\    @print(biggest(3, 9));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{"Math.max(3, 9)"});
    try h.assertJsNotContains(std.testing.allocator, src, &.{"require("});
}

// std-surface 6d: a 1-arg `@External.Node` without markers on a `declare fn`
// is a bare host expression (`process.cwd()` in `libs/std/src/process.bp`). It
// renders verbatim at the call site; it used to lower to the destructuring
// import `const { process.pid: pid } = require("");`, a SyntaxError.
test "js: external ---- 1-arg host expression declare fn emits no require" {
    const src =
        \\#[@External.Node("process.pid")]
        \\declare fn pid() -> i32;
        \\
        \\fn main() {
        \\    @print(pid() > 0);
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{"process.pid > 0"});
    try h.assertJsNotContains(std.testing.allocator, src, &.{ "require(", "const { process.pid" });
}

// A 1-arg `@External.Erlang` without markers on a `declare fn` is a bare host
// expression (`libs/std/src/process.bp`'s `pid`). It renders verbatim at the
// call site; as a `module:symbol` call with an empty module it came out
// `:expr()()`, which stopped std's env, os and process from compiling.
test "js: external ---- 1-arg host expression declare fn renders at the call site" {
    try h.assertJsRefusedOnWasm(std.testing.allocator, @src(),
        \\#[@External.Node("process.pid"),
        \\  @External.Erlang("list_to_integer(os:getpid())")]
        \\declare fn pid() -> i32;
        \\
        \\fn main() {
        \\    @print(pid() > 0);
        \\}
    );
}

// A host-backed `declare fn` renders its annotation at each call site, so its
// owner emits no function of that name — and erlang resolves a bare call in the
// CALLING module. Another module importing `hostKey` got `function hostKey/1
// undefined`, which is what kept every library whose host cells are template
// externals red on erlang. The owner now answers an imported external with a
// wrapper over its own parameters — the inline-template form and the
// `(module, symbol)` one alike — and the consumer calls that
// (`hostlib:hostKey(42)`). `nodeOnly` carries no erlang target: there is nothing
// to wrap, so it keeps its comment and is not exported, and a call to it stays
// bare for erlc to name.
// KNOWN (commonJS): a bare `import { … }` has no module path, so the consumer
// requires the project root placeholder (`require("./module")`) exactly as in
// `import_a_call_to_an_imported_fn_names_its_module`, and nothing runs — its
// RUN LOG is empty. Erlang runs and prints `42` / `2`; wasm is single-module
// and traps on the host-backed call, as its `declare fn` comment says.
test "js: external ---- an imported host-backed declare fn is wrapped by its owner" {
    try h.assertJsExpecting(std.testing.allocator, @src(), &.{
        .{
            .path = "hostlib",
            .source =
            \\#[@External.Node("String($0)"),
            \\  @External.Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))""")]
            \\pub declare fn hostKey(v: i32) -> string;
            \\
            \\#[@External.Node("$0.length"),
            \\  @External.Erlang("erlang", "length")]
            \\pub declare fn hostLen(xs: Array<string>) -> i32;
            \\
            \\#[@External.Node("console.log($0)")]
            \\pub declare fn nodeOnly(s: string) -> void;
            ,
        },
        .{
            .path = "main",
            .source =
            \\import { hostKey, hostLen, nodeOnly };
            \\
            \\pub fn main() {
            \\    @print(hostKey(42));
            \\    @print(hostLen(["a", "b"]));
            \\}
            ,
        },
    }, .refused_on_wasm);
}

// ── the prelude's own shape ──────────────────────────────────────────────────
// A `#[@External.Node("…$0…")]` template on a BEHAVIOR method becomes a
// `<Owner>.prototype.<m> = function(…)` patch (`commonJS.buildInterface`), so a
// template that calls the method it patches calls the patch it has just
// installed. `String.charCodeAt` read `(($0.charCodeAt($1) ?? -1) | 0)` and one
// `s.slice(…)` — enough to install the `String` prelude — made every
// `.charCodeAt(…)` in the program blow the stack, at run time, in a library
// that never named `charCodeAt` itself. The rule was already written down in
// `libs/std/AGENTS.md`; this is the gate that holds it, over the prelude the
// compiler actually embeds rather than over the file on disk.
test "js: external ---- no prelude template calls the method it patches" {
    const prelude = @import("std_prelude");
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = lexerMod.Lexer.init(prelude.primitives);
    const tokens = try lx.scanAll(alloc);
    var p = parserMod.Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var seen: usize = 0;
    for (program.decls) |decl| {
        if (decl != .behavior) continue;
        for (decl.behavior.methods) |m| {
            const ref = m.externalFor("node") orelse continue;
            if (std.mem.indexOfScalar(u8, ref.symbol, '$') == null) continue; // not a template
            seen += 1;
            const call = try std.fmt.allocPrint(alloc, ".{s}(", .{m.name});
            if (std.mem.indexOf(u8, ref.symbol, call) != null) {
                std.debug.print(
                    "\n{s}.{s}: the node template calls `{s}`, which is the prototype method it" ++
                        " patches — the patch would call itself:\n  {s}\n",
                    .{ decl.behavior.name, m.name, call, ref.symbol },
                );
                return error.SelfRecursivePrototypePatch;
            }
        }
    }
    // The scan is worthless if the prelude stopped parsing or stopped carrying
    // templates: `chars`, `lines`, `words`, `charCodeAt` and `Array.zip` are
    // five of them.
    try std.testing.expect(seen >= 5);
}
