//! codegen: module-level `var` storage on the BEAM — front 17 steps 4–5
//! (`@BeamMemory`, decisions 39, 40 and 43). A module `var` is one value per
//! execution context, which on the BEAM is the PROCESS; `#[@BeamMemory.Ets]`
//! and `#[@BeamMemory.PersistentTerm]` widen it to the node. Every fixture
//! here runs its program and asserts what it PRINTED, because the property is
//! behaviour across processes: the three modes are indistinguishable in one
//! process, and a mode that silently fell back to another would still print
//! the right number there.
//!
//! The processes are `std/async`'s: `runAll` spawns one per task on erlang and
//! gathers the replies, which is what makes "five requests" five processes.

const std = @import("std");
const h = @import("helpers.zig");

// `ProcessDict` (the default, said out loud): each spawned request starts
// from the declaration's value and sees only its own three writes; the
// process that spawned them never sees any of them.
test "erlang: beam memory ---- a ProcessDict var is one value per process" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {async} from "std";
        \\
        \\#[@BeamMemory.ProcessDict]
        \\var hits: i32 = 0;
        \\
        \\fn request() -> @Task<i32> {
        \\    hits = hits + 1;
        \\    hits = hits + 1;
        \\    hits = hits + 1;
        \\    return hits;
        \\}
        \\
        \\fn main() -> @Task<void> {
        \\    val seen = await async.runAll([{ -> request() }, { -> request() }, { -> request() }, { -> request() }, { -> request() }]);
        \\    @print(seen);
        \\    @print(hits);
        \\}
    , "[3, 3, 3, 3, 3]\n0\n", &.{
        "std@beam:pdGet(",
        "std@beam:pdPut(",
    });
}

// Decision 39's fixture: five requests × three increments on one `Ets` var
// read `15`. Without the registered owner the table died with whichever
// request created it — each request read `3` and the counter ended at `0`.
// `hits = hits + 1` is the increment form, lowered to the host's atomic
// counter (decision 40).
test "erlang: beam memory ---- an Ets var is one value per node, and survives the process that created it" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {async} from "std";
        \\
        \\#[@BeamMemory.Ets]
        \\var hits: i32 = 0;
        \\
        \\fn request() -> @Task<i32> {
        \\    hits = hits + 1;
        \\    hits = hits + 1;
        \\    hits += 1;
        \\    return 0;
        \\}
        \\
        \\fn main() -> @Task<void> {
        \\    val done = await async.runAll([{ -> request() }, { -> request() }, { -> request() }, { -> request() }, { -> request() }]);
        \\    @print(done.length());
        \\    @print(hits);
        \\}
    , "5\n15\n", &.{
        "std@beam:etsBump(",
        "'__bp_ets_owner'(Name, Seed) ->",
    });
}

// A whole-value write under `Ets` (`hits = 40`) is a put, not an increment,
// and the next reader — in any process — sees it.
test "erlang: beam memory ---- an Ets var written whole is read back from another process" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {async} from "std";
        \\
        \\#[@BeamMemory.Ets]
        \\var hits: i32 = 0;
        \\
        \\fn read() -> @Task<i32> {
        \\    return hits;
        \\}
        \\
        \\fn main() -> @Task<void> {
        \\    hits = 40;
        \\    hits = hits - 2;
        \\    val seen = await async.runAll([{ -> read() }]);
        \\    @print(seen);
        \\}
    , "[38]\n", &.{
        "std@beam:etsPut(",
    });
}

// `PersistentTerm`: put once, at load, by the module's `-on_load` function —
// which is why a process spawned later reads it, and why the checker refuses
// a write after load.
test "erlang: beam memory ---- a PersistentTerm var is put at load and read from any process" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {async} from "std";
        \\
        \\#[@BeamMemory.PersistentTerm]
        \\var version: i32 = 101;
        \\
        \\fn read() -> @Task<i32> {
        \\    return version;
        \\}
        \\
        \\fn main() -> @Task<void> {
        \\    val seen = await async.runAll([{ -> read() }, { -> read() }]);
        \\    @print(seen);
        \\    @print(version);
        \\}
    , "[101, 101]\n101\n", &.{
        "-on_load('__bp_load'/0).",
        "std@beam:ptGet(",
    });
}

// Decision 168 — `keyed = true` stores the `Dict` one ETS row per key: two
// processes each writing their own key keep both, where a whole-value write
// would put one process's stale row back over the other's. The seed is the
// table's rows, a repeated key keeping its last value (decision 174), and a
// key with no row reads `null`.
const keyed_program =
    \\import {async, collections.Dict} from "std";
    \\
    \\#[@BeamMemory.Ets(keyed = true)]
    \\var counts: Dict<string, i32> = Dict.ofEntries([#("seed", 1), #("seed", 7)]);
    \\
    \\fn writer(key: string) -> @Task<i32> {
    \\    var i = 0;
    \\    while (i < 2000) {
    \\        i += 1;
    \\        counts = counts.insert(key, i);
    \\    }
    \\    return i;
    \\}
    \\
    \\fn main() -> @Task<void> {
    \\    val done = await async.runAll([{ -> writer("a") }, { -> writer("b") }]);
    \\    @print(done);
    \\    @print(counts.at("a"), counts.at("b"), counts.at("seed"), counts.at("none"));
    \\}
;

test "erlang: beam memory ---- a keyed Ets var writes and reads one row per key" {
    try h.assertErlangRunLog(std.testing.allocator, keyed_program, "[2000, 2000]\n2000 2000 7 null\n", &.{
        "'__bp_ets_row'(test@main@@counts, [{<<\"seed\">>, 7}], {Key, I@2})",
        "'__bp_ets_at'(Name, Rows, Key) ->",
        "std@beam:etsLookup(",
        "{'__bp_rows', Rows} -> Rows;",
    });
}

test "beam: beam memory ---- a keyed Ets var writes and reads one row per key" {
    try h.assertBeamRunLog(std.testing.allocator, keyed_program, "[2000, 2000]\n2000 2000 7 null\n", &.{
        "{function, '__bp_ets_at', 3,",
        "{function, '__bp_ets_row', 3,",
        "{extfunc, std@beam, etsLookup, 2}",
        "{test, is_tagged_tuple, {f, ",
    });
}
