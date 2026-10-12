/// The code cache, level A (decision 509 of 1.0.12-beta): one cache, the
/// CLI's, for every target's toolchain step after the codegen — and only for a
/// DEPENDENCY's modules. What a test exercises never comes from it: the
/// package under test (a cell's own package, the member whose tests run, the
/// project being built or run) is always analysed, generated, compiled and
/// run; std, a `path` or `git` dependency, a library may come from here.
///
/// **What is stored.** On erlang, the `.beam` of a dependency's `.erl`; on
/// beam, the `.beam` of a dependency's `.S` (`erlc +from_asm`'s step). An
/// entry is keyed by the SHA-256 of the input's bytes and of the tool's
/// version — the compile options, the OTP release, the erts / `compiler` /
/// `stdlib` versions and `ERL_COMPILER_OPTIONS` (the key the former
/// `cache/erlcheck` verdicts and `cache/beam` `.beam`s shared, with one label
/// now) — and stored by that hash, never by a package or a module name:
/// `<root>/.botopinkbuild/cache/code/<k[0..2]>/<k>.beam` (`dir`), `<root>` the
/// cache root of decision 225 (the workspace root, else the project's own;
/// a cell's is its `conformance/modules/` workspace, `root_override`).
///
/// A dependency's module is compiled `deterministic` (its `.beam` names its
/// source file alone, not the directory it was compiled in), so an entry is
/// the same bytes wherever it is used: it is **materialised** into the
/// project's own output — a hard link, else a copy, staged and renamed —
/// and a program never runs from the cache. A source whose output depends on
/// more than its bytes — an `-include` / `-include_lib` attribute (another
/// file's bytes; matched at the start of a line, so a string that merely holds
/// the word is bytes like any other), a `parse_transform` (another module's
/// code), `?FILE` (the path it is compiled at) — is never looked up nor
/// stored, and only a success is stored;
/// nothing is when the key cannot be computed (no `crypto`). Writers stage
/// under a unique name and rename, entries read-only, no lock: two writers of
/// one key leave one whole entry. A hit refreshes the entry's time; each job
/// reaps one of the 256 shards at random (entries unused for 7 days, staging
/// files older than a day).
///
/// **wasm and commonJS.** commonJS has no step after the codegen (`node` reads
/// the emitted `.js`). wasm's module assembly runs inside the codegen and its
/// output is one module for the whole program — the package under test inside
/// it — so it has no dependency-only step to cache yet.
///
/// **`--cold`** (`cold`): `build`, `run`, `test` and `cell check` read nothing
/// and write what they ran.
///
/// `closureKey` is the key of level B (B-60): a package's files, its
/// dependencies' closure keys, the target and the compiler by backend
/// partition (decision 249) — a function, nothing stored by it yet.
const std = @import("std");
const builtin = @import("builtin");
const bp = @import("botopink");
const manifest = @import("manifest");
const build_stamp = @import("build_stamp");
const config = @import("./config.zig");

/// The store's name under `<root>/.botopinkbuild/cache/`.
pub const STORE = "code";

/// `--cold`: read nothing, write what ran. Set by the command that parsed it.
pub var cold: bool = false;

/// The cache root a command uses instead of its project's (decision 509 (4)):
/// `botopink cell check` builds each cell in a scratch copy, and the cell's
/// root is where the cell lives — its `conformance/modules/` workspace.
pub var root_override: ?[]const u8 = null;

/// `<root>/.botopinkbuild/cache/code` for `proj` — `root_override` when set,
/// else `manifest.cacheRoot` over the workspace `config.load` found.
pub fn dir(arena: std.mem.Allocator, proj: config.ProjectConfig) ![]const u8 {
    const root = root_override orelse manifest.cacheRoot(proj.dir, proj.workspace);
    return manifest.cacheDir(arena, root, STORE);
}

/// The plain argument a job reads as `CacheMode`.
pub fn mode() []const u8 {
    return if (cold) "cold" else "warm";
}

/// `<pkg>@` — the start of every erlang / BEAM module atom of the package
/// `package` (decision 109): an emitted module (or a `type` unit of one) whose
/// atom does not start with it, and that carries an `@` at all (a host
/// sidecar module does not), is a dependency's.
pub fn ownAtomPrefix(arena: std.mem.Allocator, package: []const u8) ![]const u8 {
    const atom = try bp.codegen.crossModule.erlAtom(arena, .{ .path = "x", .package = package });
    return atom[0 .. atom.len - 1];
}

/// Whether the emitted file `path` (`<atom>.erl` / `<atom>.S`) is a
/// dependency's module, for a project whose atoms start with `own_prefix`.
pub fn isDependencyArtifact(path: []const u8, own_prefix: []const u8) bool {
    const base = std.fs.path.basename(path);
    const stem = base[0 .. std.mem.lastIndexOfScalar(u8, base, '.') orelse base.len];
    if (std.mem.indexOfScalar(u8, stem, '@') == null) return false;
    if (std.mem.startsWith(u8, stem, "bp@")) return false;
    return !std.mem.startsWith(u8, stem, own_prefix);
}

/// The Erlang half every job that compiles shares, spliced into its `-eval`
/// after `CacheDir` (the store's directory, `"-"` for none) and `CacheMode`
/// (`"warm"` / `"cold"`) are bound. It binds:
///
///   * `CodeDep(Src, Kind, Out)` — compile a dependency's `Src` (`Kind`
///     `erl` / `asm`), or answer it from the store: `ok` (the `.beam` placed
///     at `Out`, or — `Out` `none` — only accepted), `uncacheable` (no key:
///     compile it as before), `{error, _}` (refused: compile it as before, so
///     its refusal is printed as before);
///   * `CodeReap()` — reap one random shard.
pub const ERL_FUNS =
    \\CodeOpts = fun(asm) -> [from_asm, deterministic, binary, return_errors];
    \\              (_) -> [deterministic, binary, return_errors] end,
    \\CodeTag = fun(Opts) ->
    \\    case CacheDir of
    \\        "-" -> none;
    \\        _ ->
    \\            try
    \\                _ = crypto:hash(sha256, <<>>),
    \\                term_to_binary({<<"botopink-code-1">>, Opts,
    \\                                erlang:system_info(otp_release), erlang:system_info(version),
    \\                                filename:basename(code:lib_dir(compiler)),
    \\                                filename:basename(code:lib_dir(stdlib)),
    \\                                os:getenv("ERL_COMPILER_OPTIONS")})
    \\            catch _:_ -> none
    \\            end
    \\    end
    \\end,
    \\CodeEntry = fun(none, _) -> none;
    \\               (Tag, Text) ->
    \\    case binary:match(Text, [<<"\n-include">>, <<"parse_transform">>, <<"?FILE">>]) of
    \\        nomatch ->
    \\            Key = binary:encode_hex(crypto:hash(sha256, [Tag, Text]), lowercase),
    \\            <<Shard:2/binary, _/binary>> = Key,
    \\            filename:join([CacheDir, Shard, <<Key/binary, ".beam">>]);
    \\        _ -> none
    \\    end
    \\end,
    \\CodeStage = fun(Path) ->
    \\    iolist_to_binary([Path, ".", integer_to_list(erlang:unique_integer([positive])), "-", os:getpid(), ".tmp"])
    \\end,
    \\CodeKnown = fun(Entry) -> CacheMode =:= "warm" andalso filelib:is_regular(Entry) end,
    \\CodePlace = fun(Out, Bin) ->
    \\    Tmp = CodeStage(Out),
    \\    case file:write_file(Tmp, Bin) of
    \\        ok -> case file:rename(Tmp, Out) of ok -> ok; E -> file:delete(Tmp), E end;
    \\        E -> file:delete(Tmp), E
    \\    end
    \\end,
    \\CodeLink = fun(Entry, Out) ->
    \\    Tmp = CodeStage(Out),
    \\    Placed = case file:make_link(Entry, Tmp) of
    \\        ok -> ok;
    \\        _ -> case file:copy(Entry, Tmp) of {ok, _} -> ok; E -> E end
    \\    end,
    \\    case Placed =:= ok andalso file:rename(Tmp, Out) of
    \\        ok ->
    \\            %% `Out` already a link to `Entry`: POSIX `rename` leaves both names.
    \\            _ = file:delete(Tmp),
    \\            file:change_time(Entry, erlang:localtime()), ok;
    \\        _ -> file:delete(Tmp), miss
    \\    end
    \\end,
    \\CodeStore = fun(Entry, Bin) ->
    \\    catch begin
    \\        ok = filelib:ensure_dir(Entry),
    \\        Tmp = CodeStage(Entry),
    \\        case file:write_file(Tmp, Bin) of
    \\            ok ->
    \\                _ = file:change_mode(Tmp, 8#444),
    \\                case file:rename(Tmp, Entry) of ok -> ok; _ -> file:delete(Tmp) end;
    \\            _ -> file:delete(Tmp)
    \\        end
    \\    end
    \\end,
    \\CodeDep = fun(Src, Kind, Out) ->
    \\    case file:read_file(Src) of
    \\        {ok, Text} ->
    \\            Opts = CodeOpts(Kind),
    \\            case CodeEntry(CodeTag(Opts), Text) of
    \\                none -> uncacheable;
    \\                Entry ->
    \\                    Hit = CodeKnown(Entry) andalso (Out =:= none orelse CodeLink(Entry, Out) =:= ok),
    \\                    case Hit of
    \\                        true -> ok;
    \\                        false ->
    \\                            case catch compile:file(Src, Opts) of
    \\                                {ok, _, Bin} ->
    \\                                    case Out of none -> ok; _ -> ok = CodePlace(Out, Bin) end,
    \\                                    CodeStore(Entry, Bin),
    \\                                    ok;
    \\                                Other -> {error, Other}
    \\                            end
    \\                    end
    \\            end;
    \\        Err -> {error, Err}
    \\    end
    \\end,
    \\CodeReap = fun() ->
    \\    case CacheDir of
    \\        "-" -> ok;
    \\        _ ->
    \\            catch begin
    \\                Pick = binary_to_list(binary:encode_hex(<<(rand:uniform(256) - 1)>>, lowercase)),
    \\                Now = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
    \\                Reap = fun(Pattern, MaxAge) ->
    \\                    [case filelib:last_modified(F) of
    \\                         0 -> ok;
    \\                         T ->
    \\                             case Now - calendar:datetime_to_gregorian_seconds(T) > MaxAge of
    \\                                 true -> file:delete(F);
    \\                                 false -> ok
    \\                             end
    \\                     end || F <- filelib:wildcard(filename:join([CacheDir, Pick, Pattern]))]
    \\                end,
    \\                Reap("*.beam", 7 * 86400),
    \\                Reap("*.tmp", 86400)
    \\            end
    \\    end
    \\end,
    \\
;

// ── the closure key (level B's, decision 509 (3)) ─────────────────────────────

pub const KEY_HEX = 64;

/// One dependency of a package, by its import name and closure key.
pub const DepKey = struct {
    name: []const u8,
    key: [KEY_HEX]u8,
};

/// The compiler's part of a closure key on `target`: the sources the binary
/// was built from partitioned by backend (decision 249 — every shared source
/// and that target's emitter files, `build.zig` hashing them by
/// `codegen/backend-partition.txt`), and the build configuration (the Zig
/// version, the optimize mode, the machine).
pub fn compilerKey(target: config.Target) []const u8 {
    return switch (target) {
        .commonJS => build_stamp.partition_hash_commonJS,
        .erlang => build_stamp.partition_hash_erlang,
        .beam => build_stamp.partition_hash_beam,
        .wasm => build_stamp.partition_hash_wasm,
    };
}

/// The closure key of the package in `pkg_dir` (decision 509 (3)): a hash of
///
///   * its files by content — its manifest and every file under its `src`
///     (hidden entries skipped), each as `<path from the package> NUL <bytes>
///     NUL`, sorted by path;
///   * its dependencies' closure keys (Merkle): `<name> NUL <key> NUL`, sorted
///     by name, so the key of a package moves when any package below it moves;
///   * the target;
///   * the compiler on that target (`compilerKey`), never the binary's hash
///     alone.
///
/// Nothing is stored here: level B (B-60) keys a package's checked interface
/// and generated code by it, once its invariant is proved.
pub fn closureKey(
    arena: std.mem.Allocator,
    io: std.Io,
    pkg_dir: []const u8,
    m: manifest.Manifest,
    deps: []const DepKey,
    target: config.Target,
) ![KEY_HEX]u8 {
    return closureKeyWith(arena, io, pkg_dir, m, deps, target, compilerKey(target));
}

/// `closureKey` with the compiler's part given — what a test varies.
pub fn closureKeyWith(
    arena: std.mem.Allocator,
    io: std.Io,
    pkg_dir: []const u8,
    m: manifest.Manifest,
    deps: []const DepKey,
    target: config.Target,
    compiler: []const u8,
) ![KEY_HEX]u8 {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update("botopink-closure-1\x00");

    // The package's files by content.
    var files: std.ArrayListUnmanaged([]const u8) = .empty;
    try files.append(arena, manifest.FILENAME);
    const src = std.mem.trimEnd(u8, m.src, "/");
    try collectFiles(arena, io, pkg_dir, if (src.len == 0) "." else src, &files);
    std.mem.sort([]const u8, files.items, {}, lessThan);
    for (files.items) |rel| {
        const path = try std.fs.path.join(arena, &.{ pkg_dir, rel });
        const bytes = try std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited);
        h.update(rel);
        h.update(&.{0});
        h.update(bytes);
        h.update(&.{0});
    }

    // The dependencies' closure keys, by name.
    const sorted = try arena.dupe(DepKey, deps);
    std.mem.sort(DepKey, sorted, {}, struct {
        fn lt(_: void, a: DepKey, b: DepKey) bool {
            return std.mem.lessThan(u8, a.name, b.name);
        }
    }.lt);
    h.update("deps\x00");
    for (sorted) |d| {
        h.update(d.name);
        h.update(&.{0});
        h.update(&d.key);
        h.update(&.{0});
    }

    h.update("target\x00");
    h.update(target.toString());
    h.update(&.{0});
    h.update("compiler\x00");
    h.update(compiler);
    h.update(&.{0});
    h.update(builtin.zig_version_string);
    h.update(@tagName(builtin.mode));
    h.update(@tagName(builtin.cpu.arch));
    h.update(@tagName(builtin.os.tag));

    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

/// Every regular file under `<base>/<rel>`, as a path from `base`; hidden
/// entries skipped.
fn collectFiles(arena: std.mem.Allocator, io: std.Io, base: []const u8, rel: []const u8, out: *std.ArrayListUnmanaged([]const u8)) !void {
    const full = try std.fs.path.join(arena, &.{ base, rel });
    var d = std.Io.Dir.cwd().openDir(io, full, .{ .iterate = true }) catch return;
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |e| {
        if (e.name.len > 0 and e.name[0] == '.') continue;
        const child = if (std.mem.eql(u8, rel, ".")) try arena.dupe(u8, e.name) else try std.fmt.allocPrint(arena, "{s}/{s}", .{ rel, e.name });
        switch (e.kind) {
            .directory => try collectFiles(arena, io, base, child, out),
            .file => try out.append(arena, child),
            else => {},
        }
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;
const test_scratch = @import("test_scratch");

test "isDependencyArtifact: another package's module or unit, never the project's, a sidecar or bp's" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const own = try ownAtomPrefix(arena.allocator(), "alpha");
    try testing.expectEqualStrings("alpha@", own);
    try testing.expect(isDependencyArtifact("out/erl/emilia@theme.erl", own));
    try testing.expect(isDependencyArtifact("out/erl/std@io@fs@@File.erl", own));
    try testing.expect(isDependencyArtifact("out/beam/emilia@theme.S", own));
    try testing.expect(!isDependencyArtifact("out/erl/alpha@main.erl", own));
    try testing.expect(!isDependencyArtifact("out/erl/alpha@main@@Point.erl", own));
    try testing.expect(!isDependencyArtifact("out/erl/rakun_file_router.erl", own));
    try testing.expect(!isDependencyArtifact("out/erl/bp@comptime__ct__x.erl", own));
    // A package named with a dash: its atoms use `_`.
    try testing.expectEqualStrings("rakun_web@", try ownAtomPrefix(arena.allocator(), "rakun-web"));
}

test "closureKey: moves with a byte of the package, a dependency's key, the target and the compiler" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    test_scratch.remove(io, "closure-key");
    defer test_scratch.remove(io, "closure-key");
    const pkg = test_scratch.path(io, "closure-key/pkg");
    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, try std.fs.path.join(a, &.{ pkg, "src" }));
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(a, &.{ pkg, "botopink.json" }), .data = "{ \"name\": \"pkg\" }" });
    const main_bp = try std.fs.path.join(a, &.{ pkg, "src", "main.bp" });
    try cwd.writeFile(io, .{ .sub_path = main_bp, .data = "pub fn main() {}\n" });
    var err: ?manifest.Located = null;
    const m = try manifest.parse(a, "{ \"name\": \"pkg\" }", "botopink.json", &err);

    const dep: DepKey = .{ .name = "lib", .key = @splat('a') };
    const k0 = try closureKeyWith(a, io, pkg, m, &.{dep}, .erlang, "c1");
    // Deterministic.
    try testing.expectEqualStrings(&k0, &(try closureKeyWith(a, io, pkg, m, &.{dep}, .erlang, "c1")));
    // The target, the compiler, a dependency's key.
    try testing.expect(!std.mem.eql(u8, &k0, &(try closureKeyWith(a, io, pkg, m, &.{dep}, .beam, "c1"))));
    try testing.expect(!std.mem.eql(u8, &k0, &(try closureKeyWith(a, io, pkg, m, &.{dep}, .erlang, "c2"))));
    const dep2: DepKey = .{ .name = "lib", .key = @splat('b') };
    try testing.expect(!std.mem.eql(u8, &k0, &(try closureKeyWith(a, io, pkg, m, &.{dep2}, .erlang, "c1"))));
    // One byte of a source.
    try cwd.writeFile(io, .{ .sub_path = main_bp, .data = "pub fn main() {} \n" });
    try testing.expect(!std.mem.eql(u8, &k0, &(try closureKeyWith(a, io, pkg, m, &.{dep}, .erlang, "c1"))));
    // Something outside the package's files does not move it.
    try cwd.writeFile(io, .{ .sub_path = main_bp, .data = "pub fn main() {}\n" });
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(a, &.{ pkg, "docs.md" }), .data = "x" });
    try testing.expectEqualStrings(&k0, &(try closureKeyWith(a, io, pkg, m, &.{dep}, .erlang, "c1")));
}
