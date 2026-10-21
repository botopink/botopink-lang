//! codegen: module-level `var` storage on the BEAM — front 17 steps 4–5
//! (`beamMemory`, decisions 39, 43, 547 and 877). A module `var` is one value
//! for the whole program: a one-row ETS table (`Ets`, the default) or a
//! `persistent_term` (`#[compiler.beamMemory(.PersistentTerm)]`). Every fixture
//! here runs its program and asserts what it PRINTED, because the property is
//! behaviour across processes: the three modes are indistinguishable in one
//! process, and a mode that silently fell back to another would still print
//! the right number there.
//!
//! The processes are `std/async`'s: `runAll` spawns one per task on erlang and
//! gathers the replies, which is what makes "five requests" five processes.

const std = @import("std");
const h = @import("helpers.zig");

// Decision 39's fixture: five requests × three increments on one `Ets` var
// read `15`. Without the registered owner the table died with whichever
// request created it — each request read `3` and the counter ended at `0`.
// `hits = hits + 1` reads the `var` it writes: a compare-and-swap
// (`etsSwap`, decision 547 (ii)), so no increment is lost.
test "erlang: beam memory ---- an Ets var is one value per node, and survives the process that created it" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {async} from "std";
        \\
        \\#[compiler.beamMemory(.Ets)]
        \\var hits: i32 = 0;
        \\
        \\async fn request() -> Async<i32> {
        \\    hits = hits + 1;
        \\    hits = hits + 1;
        \\    hits += 1;
        \\    return 0;
        \\}
        \\
        \\async fn main() -> Async<void> {
        \\    val done = await async.runAll([{ -> request() }, { -> request() }, { -> request() }, { -> request() }, { -> request() }]);
        \\    print(done.length());
        \\    print(hits);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "5\n15\n", &.{
        "std@beam:etsSwap(",
        "'__bp_ets_owner'(Name, Seed) ->",
    });
}

// A whole-value write under `Ets` (`hits = 40`) is a put, not a swap,
// and the next reader — in any process — sees it.
test "erlang: beam memory ---- an Ets var written whole is read back from another process" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {async} from "std";
        \\
        \\#[compiler.beamMemory(.Ets)]
        \\var hits: i32 = 0;
        \\
        \\async fn read() -> Async<i32> {
        \\    return hits;
        \\}
        \\
        \\async fn main() -> Async<void> {
        \\    hits = 40;
        \\    hits = hits - 2;
        \\    val seen = await async.runAll([{ -> read() }]);
        \\    print(seen);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "[38]\n", &.{
        "std@beam:etsPut(",
    });
}

// `PersistentTerm`: put once, at load, by the module's `-on_load` function —
// which is why a process spawned later reads it.
test "erlang: beam memory ---- a PersistentTerm var is put at load and read from any process" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {async} from "std";
        \\
        \\#[compiler.beamMemory(.PersistentTerm)]
        \\var version: i32 = 101;
        \\
        \\async fn read() -> Async<i32> {
        \\    return version;
        \\}
        \\
        \\async fn main() -> Async<void> {
        \\    val seen = await async.runAll([{ -> read() }, { -> read() }]);
        \\    print(seen);
        \\    print(version);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "[101, 101]\n101\n", &.{
        "-on_load('__bp_load'/0).",
        "std@beam:ptGet(",
    });
}

// Decisions 340, 547 (ii) — `counts = counts.bump(k, n)` on a module `var` is
// an `x = f(x)`, the compare-and-swap: two processes bumping the SAME key lose
// none, and an absent key counts from 0.
const bump_program =
    \\import {async, collections.Dict} from "std";
    \\
    \\var counts: Dict<string, i32> = Dict.ofEntries([#("seed", 10)]);
    \\
    \\async fn worker(n: i32) -> Async<i32> {
    \\    var i = 0;
    \\    while (i < 2000) {
    \\        i += 1;
    \\        counts = counts.bump("hot", n);
    \\    }
    \\    return i;
    \\}
    \\
    \\async fn main() -> Async<void> {
    \\    val done = await async.runAll([{ -> worker(1) }, { -> worker(2) }]);
    \\    counts = counts.bump("seed", 5);
    \\    print(done);
    \\    print(counts.at("hot"), counts.at("seed"), counts.at("none"));
    \\}
    \\
    \\import {io.terminal.print} from "std";
;

test "erlang: beam memory ---- Dict.bump on a module var loses no concurrent increment of one key" {
    try h.assertErlangRunLog(std.testing.allocator, bump_program, "[2000, 2000]\n6000 15 null\n", &.{
        "std@beam:etsSwap(",
    });
}

test "beam: beam memory ---- Dict.bump on a module var loses no concurrent increment of one key" {
    try h.assertBeamRunLog(std.testing.allocator, bump_program, "[2000, 2000]\n6000 15 null\n", &.{
        "{function, '__bp_swap_counts', 1,",
        "{extfunc, std@beam, etsSwap, 2}",
    });
}

// A module that imports nothing from std still reaches `std@beam`: the build
// embeds `std/beam` for any module declaring a `var` (`expandStdImports`), so
// the remote calls the reader and the writes lower to answer.
test "erlang: beam memory ---- a var in a module that imports nothing from std reaches std@beam" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\var hits: i32 = 0;
        \\
        \\fn main() -> void {
        \\    hits = hits + 1;
        \\    hits = hits + 1;
        \\    print(hits);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "2\n", &.{
        "std@beam:etsGet(",
        "std@beam:etsSwap(",
    });
}
