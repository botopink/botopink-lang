//! The lazy generator runtime of the erlang and beam targets (decision 105,
//! 144 B-128): Erlang text both backends emit as helper functions of the
//! module that reaches them — `erlang.zig` as the body of a form
//! `'<name>'(__BpA0, …) -> <text>.`, `beam_asm.zig` through its template
//! compiler (`compiledTemplate`, `erl_template.zig` / `erl_lower.zig`). One
//! text, so the two targets cannot answer differently.
//!
//! **A generator is a process.** Its body runs in a process of its own that
//! waits for a request before it starts and between two items, so each `next`
//! runs the body up to the next `yield` and an endless body is consumed one
//! item at a time. The value is `{'__bp_gen', Pid}` — a handle, stateful as a
//! commonJS generator object is: a second `for` over it reads on from where the
//! first stopped. The body is the scope's code as it was lowered eagerly, its
//! `yield v` a call of `Yield(v)` that sends the item and blocks.
//!
//! The protocol (only one of the two processes runs at a time, so they behave
//! as one):
//!
//!   * a request `{'__bp_gen', next | close, From, Ref, Dict}`;
//!   * a reply `{Ref, item, V, Dict}`, `{Ref, done, Dict}` or
//!     `{Ref, raise, Class, Reason, Stack, Dict}` — a raise in the body is
//!     raised again in the consumer;
//!   * `Ref` is the consumer's monitor of the generator, so a request to one
//!     that already ended answers `done`;
//!   * `Dict` is the sender's process dictionary, which the receiver takes
//!     whole: a module `var` (`ProcessDict`), a `defer`'s watched names and an
//!     `iter` loop's captured `var`s (a cell each, `erlang.zig`'s `GenCell`) read the same on both
//!     sides. The generator's own reply address, `'__bp_gen_self'`, never
//!     travels.
//!
//! `close` (a `for` left by `break`, `return` or a raise; `take` past its
//! count) makes the suspended `yield` throw `'__bp_gen_closed'`: the body
//! unwinds through its `defer`s, as commonJS's `return()` runs a generator's
//! `finally`, and the reply is `done`. A consumer that never closes does
//! not leak it: the generator monitors its creator (`GenNew` captures
//! `erlang:self()`) and, on the creator's `'DOWN'`, ends in either of its two
//! `receive`s — before the first request it just ends, suspended at a `yield`
//! it unwinds as a `close` does (144 B-133) and exits normally, with nobody to
//! answer (no reply address, so no `badmatch` crash report). The monitor reference lives under
//! `'__bp_gen_mon'`, which like `'__bp_gen_self'` never travels.
//!
//! A list stays a list: every consumer helper answers a list receiver as the
//! eager lowering did (`lists:foreach/2`, `lists:sublist/2`, …).
const std = @import("std");

/// The process dictionary, the generator's own reply address left out.
const dict =
    \\Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
    \\
;

/// Takes a received dictionary whole, keeping this process's own reply
/// address (a generator consuming another one).
const load =
    \\Load = fun(LD) ->
    \\    LOwn = erlang:get('__bp_gen_self'),
    \\    LMon = erlang:get('__bp_gen_mon'),
    \\    erlang:erase(),
    \\    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    \\    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    \\    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
    \\end,
    \\
;

/// One request to a generator: `[V]` for an item, `[]` when it is done; a raise
/// of its body is raised here.
const call =
    \\Call = fun(CPid, CCmd) ->
    \\    CM = erlang:monitor(process, CPid),
    \\    erlang:send(CPid, {'__bp_gen', CCmd, erlang:self(), CM, Dict()}),
    \\    receive
    \\        {CM, item, CV, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [CV];
    \\        {CM, done, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [];
    \\        {CM, raise, CC, CR, CS, CD} -> erlang:demonitor(CM, [flush]), Load(CD), erlang:raise(CC, CR, CS);
    \\        {'DOWN', CM, process, _, _} -> []
    \\    end
    \\end,
    \\
;

/// `yield v` inside a generator's process: the item goes to whoever asked, and
/// the body waits for the next request — a `close` throws `'__bp_gen_closed'`.
const yield_ =
    \\Yield = fun(YV) ->
    \\    {YFrom, YM} = erlang:erase('__bp_gen_self'),
    \\    erlang:send(YFrom, {YM, item, YV, Dict()}),
    \\    YMon = erlang:get('__bp_gen_mon'),
    \\    receive
    \\        {'DOWN', YMon, process, _, _} -> erlang:throw('__bp_gen_closed');
    \\        {'__bp_gen', YCmd, YFrom2, YM2, YD} ->
    \\            Load(YD),
    \\            erlang:put('__bp_gen_self', {YFrom2, YM2}),
    \\            case YCmd of next -> undefined; close -> erlang:throw('__bp_gen_closed') end
    \\    end
    \\end,
    \\
;

/// A generator over the body `GBody` (a fun of no argument): a process that
/// waits for its first request before the body runs.
const gen_new =
    \\GenNew = fun(GBody) ->
    \\    GCreator = erlang:self(),
    \\    {'__bp_gen', erlang:spawn(fun() ->
    \\        GMon = erlang:monitor(process, GCreator),
    \\        erlang:put('__bp_gen_mon', GMon),
    \\        receive
    \\            {'DOWN', GMon, process, _, _} -> ok;
    \\            {'__bp_gen', GCmd, GFrom, GM, GD} ->
    \\                Load(GD),
    \\                erlang:put('__bp_gen_self', {GFrom, GM}),
    \\                case GCmd of
    \\                    close -> ok;
    \\                    next ->
    \\                        try GBody() catch
    \\                            throw:'__bp_gen_closed' -> ok;
    \\                            GC:GR:GS ->
    \\                                case erlang:erase('__bp_gen_self') of
    \\                                    {GF0, GM0} -> erlang:send(GF0, {GM0, raise, GC, GR, GS, Dict()});
    \\                                    undefined -> ok
    \\                                end,
    \\                                erlang:exit(normal)
    \\                        end
    \\                end,
    \\                case erlang:erase('__bp_gen_self') of
    \\                    {GF, GM1} -> erlang:send(GF, {GM1, done, Dict()});
    \\                    undefined -> ok
    \\                end
    \\        end
    \\    end)}
    \\end,
    \\
;

const consumer = dict ++ load ++ call;
const producer = dict ++ load ++ call ++ yield_ ++ gen_new;

/// A derived generator (`map`, `filter`, `take`, `drop`) over the source
/// `{'__bp_gen', P}`: `walk` is the body's loop, named `W`; closing or a raise
/// closes the source too.
fn derived(comptime walk: []const u8) []const u8 {
    return producer ++
        "GenNew(fun() ->\n" ++
        "    W = " ++ walk ++ ",\n" ++
        "    try W() catch WC:WR:WS -> Call(P, close), erlang:raise(WC, WR, WS) end\n" ++
        "end)";
}

/// A consumer that walks the whole source (`walk`, named `W`, of no argument)
/// and closes it when the walk raises.
fn consuming(comptime walk: []const u8) []const u8 {
    return consumer ++
        "W = " ++ walk ++ ",\n" ++
        "try W() catch WC:WR:WS -> Call(P, close), erlang:raise(WC, WR, WS) end";
}

pub const Helper = enum {
    /// `(Body)` → a generator over the fun `Body`.
    gen_new,
    /// `(V)` → hands `V` to the consumer and waits (inside a generator's body).
    gen_yield,
    /// `(It)` → `[V | Rest]` or `[]`: a list itself, a generator's next item
    /// before itself.
    step,
    /// `(It)` → `ok`, a generator closed.
    close,
    /// `(It, F)` → `F(It)`, closing a generator `It` when `F` raises.
    with,
    /// `(F, It)` → `lists:foreach/2` over a list or a generator.
    foreach,
    /// `(F, Acc, It)` → `lists:foldl/3` over a list or a generator.
    foldl,
    /// `(It, F)` → a generator of `F(x)`.
    map,
    /// `(It, F)` → a generator of the `x` with `F(x)`.
    filter,
    /// `(It, N)` → the first `N` items: a list's `lists:sublist/2`.
    take,
    /// `(It, N)` → what follows the first `N` items: a list's `lists:nthtail/2`.
    drop,
    /// `(It)` → the items as a list.
    to_array,
    /// `(It, F, Init)` → `F(…F(Init, x0)…, xn)`.
    reduce,
    /// `(It, F)` → whether some `F(x)` holds.
    some,
    /// `(It, F)` → whether every `F(x)` holds.
    every,
    /// `(It, F)` → the first `x` with `F(x)`, else `undefined`.
    find,

    /// The helper's function name in the erlang module.
    pub fn name(h: Helper) []const u8 {
        return switch (h) {
            .gen_new => "__bp_gen_new",
            .gen_yield => "__bp_gen_yield",
            .step => "__bp_iter_step",
            .close => "__bp_iter_close",
            .with => "__bp_iter_with",
            .foreach => "__bp_iter_foreach",
            .foldl => "__bp_iter_foldl",
            .map => "__bp_iter_map",
            .filter => "__bp_iter_filter",
            .take => "__bp_iter_take",
            .drop => "__bp_iter_drop",
            .to_array => "__bp_iter_to_array",
            .reduce => "__bp_iter_reduce",
            .some => "__bp_iter_some",
            .every => "__bp_iter_every",
            .find => "__bp_iter_find",
        };
    }

    pub fn arity(h: Helper) usize {
        return switch (h) {
            .gen_new, .gen_yield, .step, .close, .to_array => 1,
            .with, .foreach, .map, .filter, .take, .drop, .some, .every, .find => 2,
            .foldl, .reduce => 3,
        };
    }

    /// The helper's body: Erlang over its parameters `__BpA0`, `__BpA1`, …,
    /// with no trailing `.`.
    pub fn text(h: Helper) []const u8 {
        return switch (h) {
            inline else => |c| comptime textOf(c),
        };
    }

    fn textOf(comptime h: Helper) []const u8 {
        return switch (h) {
            .gen_new => dict ++ load ++ gen_new ++ "GenNew(__BpA0)",
            .gen_yield => dict ++ load ++ yield_ ++ "Yield(__BpA0)",
            .step => "case __BpA0 of\n{'__bp_gen', P} = G ->\n" ++ consumer ++
                "case Call(P, next) of [V] -> [V | G]; [] -> [] end;\nL -> L\nend",
            .close => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++ consumer ++
                "Call(P, close), ok;\n_ -> ok\nend",
            .with => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++ consumer ++
                "try __BpA1(__BpA0) catch WC:WR:WS -> Call(P, close), erlang:raise(WC, WR, WS) end;\n" ++
                "_ -> __BpA1(__BpA0)\nend",
            .foreach => "case __BpA1 of\n{'__bp_gen', P} ->\n" ++
                consuming("fun WF() -> case Call(P, next) of [V] -> __BpA0(V), WF(); [] -> ok end end") ++
                ";\nL -> lists:foreach(__BpA0, L)\nend",
            .foldl => "case __BpA2 of\n{'__bp_gen', P} ->\n" ++ consumer ++
                "W = fun WF(A) -> case Call(P, next) of [V] -> WF(__BpA0(V, A)); [] -> A end end,\n" ++
                "try W(__BpA1) catch WC:WR:WS -> Call(P, close), erlang:raise(WC, WR, WS) end;\n" ++
                "L -> lists:foldl(__BpA0, __BpA1, L)\nend",
            .map => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                derived("fun WF() -> case Call(P, next) of [V] -> Yield(__BpA1(V)), WF(); [] -> ok end end") ++
                ";\nL -> lists:map(__BpA1, L)\nend",
            .filter => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                derived("fun WF() -> case Call(P, next) of [V] -> case __BpA1(V) of true -> Yield(V); _ -> ok end, WF(); [] -> ok end end") ++
                ";\nL -> lists:filter(__BpA1, L)\nend",
            .take => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                derived("fun() -> WT = fun WF(K) -> case K =< 0 of true -> Call(P, close), ok; false -> case Call(P, next) of [V] -> Yield(V), WF(K - 1); [] -> ok end end end, WT(__BpA1) end") ++
                ";\nL -> lists:sublist(L, __BpA1)\nend",
            .drop => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                derived("fun() -> WD = fun WF(K) -> case Call(P, next) of [V] -> case K > 0 of true -> WF(K - 1); false -> Yield(V), WF(0) end; [] -> ok end end, WD(__BpA1) end") ++
                ";\nL -> lists:nthtail(__BpA1, L)\nend",
            .to_array => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                consuming("fun() -> WA = fun WF(A) -> case Call(P, next) of [V] -> WF([V | A]); [] -> lists:reverse(A) end end, WA([]) end") ++
                ";\nL -> L\nend",
            .reduce => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                consuming("fun() -> WR0 = fun WF(A) -> case Call(P, next) of [V] -> WF(__BpA1(A, V)); [] -> A end end, WR0(__BpA2) end") ++
                ";\nL -> lists:foldl(fun(X, A) -> __BpA1(A, X) end, __BpA2, L)\nend",
            .some => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                consuming("fun WF() -> case Call(P, next) of [V] -> case __BpA1(V) of true -> Call(P, close), true; _ -> WF() end; [] -> false end end") ++
                ";\nL -> lists:any(__BpA1, L)\nend",
            .every => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                consuming("fun WF() -> case Call(P, next) of [V] -> case __BpA1(V) of true -> WF(); _ -> Call(P, close), false end; [] -> true end end") ++
                ";\nL -> lists:all(__BpA1, L)\nend",
            .find => "case __BpA0 of\n{'__bp_gen', P} ->\n" ++
                consuming("fun WF() -> case Call(P, next) of [V] -> case __BpA1(V) of true -> Call(P, close), V; _ -> WF() end; [] -> undefined end end") ++
                ";\nL -> case lists:search(__BpA1, L) of {value, V} -> V; false -> undefined end\nend",
        };
    }

    /// The method a generator answers by this helper — `xs.take(n)` — with its
    /// argument count, receiver first in the helper's parameters.
    pub fn ofMethod(method: []const u8, argc: usize) ?Helper {
        const table = [_]struct { []const u8, usize, Helper }{
            .{ "take", 1, .take },     .{ "drop", 1, .drop },        .{ "map", 1, .map },
            .{ "filter", 1, .filter }, .{ "toArray", 0, .to_array }, .{ "reduce", 2, .reduce },
            .{ "some", 1, .some },     .{ "every", 1, .every },      .{ "find", 1, .find },
        };
        for (table) |row| if (argc == row[1] and std.mem.eql(u8, method, row[0])) return row[2];
        return null;
    }
};

test "every helper's text names only its own parameters" {
    inline for (std.meta.fields(Helper)) |f| {
        const h: Helper = @enumFromInt(f.value);
        const t = h.text();
        var i: usize = h.arity();
        while (i < 4) : (i += 1) {
            var buf: [8]u8 = undefined;
            const hole = try std.fmt.bufPrint(&buf, "__BpA{d}", .{i});
            try std.testing.expect(std.mem.indexOf(u8, t, hole) == null);
        }
    }
}

test "a generator ends with its creator, started or not (144 B-133)" {
    // Two generators made by a process that then ends: one suspended at a
    // `yield` (its first item taken), one never asked. Both must be dead soon
    // after, with no request and no `close`.
    const io = std.testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const eval = try std.fmt.allocPrint(arena,
        \\Gen = fun(__BpA0) -> {s} end,
        \\Yld = fun(__BpA0) -> {s} end,
        \\Stp = fun(__BpA0) -> {s} end,
        \\Self = erlang:self(),
        \\erlang:spawn(fun() ->
        \\    XA = Gen(fun() -> Yld(1), Yld(2) end),
        \\    XB = Gen(fun() -> Yld(1) end),
        \\    [1 | _] = Stp(XA),
        \\    {{'__bp_gen', PA}} = XA,
        \\    {{'__bp_gen', PB}} = XB,
        \\    Self ! {{pids, PA, PB}}
        \\end),
        \\receive {{pids, QA, QB}} -> ok end,
        \\Wait = fun(WP) ->
        \\    WM = erlang:monitor(process, WP),
        \\    receive {{'DOWN', WM, process, _, _}} -> dead after 5000 -> alive end
        \\end,
        \\io:format("~p ~p~n", [Wait(QA), Wait(QB)]),
        \\erlang:halt().
    , .{ Helper.gen_new.text(), Helper.gen_yield.text(), Helper.step.text() });
    const res = std.process.run(arena, io, .{
        .argv = &.{ "erl", "-noshell", "-eval", eval },
    }) catch return;
    // Each ends normally: no crash report on either stream.
    try std.testing.expectEqualStrings("dead dead\n", res.stdout);
    try std.testing.expect(std.mem.indexOf(u8, res.stderr, "ERROR REPORT") == null);
}
