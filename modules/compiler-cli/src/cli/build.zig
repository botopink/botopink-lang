/// `botopink build` — compile the project to the configured target.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const sources = @import("./sources.zig");
const libs = @import("./libs.zig");
const diagnostics = @import("./diagnostics.zig");
const arglist = @import("./arglist.zig");
const otp = @import("./otp.zig");

const Module = bp.Module;

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    target: ?config.Target = null, // null → use project config
    out_dir: []const u8 = "out",
    typescript: bool = false,
};

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(
    gpa: std.mem.Allocator,
    io: std.Io,
    opts: Options,
    env_map: libs.EnvMap,
) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    // Load project config.
    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => {}, // refused — the located diagnostic is already printed
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const target = opts.target orelse proj.parsedTarget() orelse {
        reportUnsupportedTarget(proj.target);
        return 1;
    };
    // erlang and beam: the `erl` on PATH runs the OTP release the compiler
    // emits for, or nothing is built (decision 228, `otp.zig`).
    if ((target == .erlang or target == .beam) and !try otp.check(arena, io)) return 1;

    // Resolve project source files through the explicit module tree.
    // (`sources.load` reports resolution errors itself.)
    var loaded = sources.load(gpa, io, proj, proj.srcDir()) catch return 1;
    defer loaded.free(gpa);
    const project_modules = loaded.modules;

    if (project_modules.len == 0) {
        reporter.errMsg("no source files found in src/");
        reporter.hintMsg("create a .bp file, e.g. src/main.bp");
        return 1;
    }

    // Resolve declared external libs from disk (generic — `libs/<name>/`). The
    // core never names a lib; it only sees these as ordinary `Module[]` and
    // resolves `from "<lib>"` through the shared import registry. `std` is the
    // embedded exception and is not loaded here.
    const dep_modules = libs.loadDependencies(gpa, io, proj, env_map, &.{project_modules}) catch |err| {
        reportDependencyError(err);
        return 1;
    };
    defer libs.freeModules(gpa, dep_modules);

    // Compile dependency modules ahead of project modules (their types/decorators
    // must resolve before the project that imports them).
    const all_modules = try std.mem.concat(arena, Module, &.{ dep_modules, project_modules });

    reporter.compiling(all_modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    // A module that does not lex, parse or type-check is reported with its
    // location (below); the rest still compile.
    const modules = all_modules;

    // Build codegen config. The package names start every erlang/BEAM
    // module atom (decision 109).
    const cfg = bp.codegen.Config{
        .targetSource = targetSource(target),
        .typeDefLanguage = if (opts.typescript) .typescript else null,
        .build_root = ".botopinkbuild",
        .packages = try libs.packagesOf(arena, proj, dep_modules),
    };

    // Run the compiler. `build` emits only: the program is not executed.
    var outputs = bp.codegen.generateWith(gpa, modules, io, cfg, .{ .execute = false }) catch |err| {
        reporter.errMsg("compilation failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }

    const t1 = std.Io.Timestamp.now(io, .awake);

    // Every module comes back from the compiler; one that did not lex, parse,
    // type-check or pass comptime validation carries its diagnostic instead of
    // an artifact, rendered here.
    const failed = try diagnostics.failedOutputs(gpa, io, arena, modules, outputs.items);

    // Write what compiled; remove any previous artifact of a module that did not,
    // so nothing stale is left claiming to be current.
    writeOutputs(gpa, io, outputs.items, opts.out_dir, target, cfg.packages, env_map) catch |err| switch (err) {
        // A sidecar the build cannot ship: the located refusal is already
        // printed by the shipper, and the build ends here with exit 1.
        error.SidecarRefused => return 1,
        else => return err,
    };
    removeStaleArtifacts(arena, io, failed, opts.out_dir, target, cfg.packages);

    // erlang: emitted text is not yet a program — the OTP compiler must accept
    // it. Every `.erl` this build wrote is compiled (in memory, nothing is
    // written) and one it refuses fails the build, so "it builds on erlang"
    // means what it says.
    const erl_ok = if (target == .erlang)
        try checkErlang(arena, io, outputs.items, opts.out_dir, cfg.packages, try libs.cacheDir(arena, proj, "erlcheck"))
    else
        true;

    diagnostics.reportOrphans(arena, loaded.orphans.len);

    if (failed.len > 0) {
        diagnostics.reportFailedModules(arena, failed);
        return 1;
    }
    if (!erl_ok) return 1;

    reporter.compiled(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}

/// Compile every `.erl` this build wrote with the OTP compiler, in one `erl`
/// (one process per scheduler, `compile:file(F, [binary, return_errors])` —
/// in memory, so `out/` holds exactly what it held before), and print each
/// refusal as `<file>:<line>: <message>`. False when any module is refused, or
/// when `erl` cannot be run: a build that did not check its output does not
/// get to say it succeeded.
///
/// A build that only transpiles proved nothing about erlang: a module `erlc`
/// rejects wrote, exited 0, and a `botopink run` / `test` of the same program
/// then failed on it — and "it builds on that target" was read as evidence.
/// The warnings of generated code are not reported (`return_errors` alone).
///
/// **The verdict cache** (`cache_dir`, `libs.cacheDir(…, "erlcheck")`:
/// `<cache root>/.botopinkbuild/cache/erlcheck`, decision 225; null = none).
/// Every build of a project compiles its dependencies' `.erl` again —
/// rakun's build tests spawn `botopink build` 22 times in one cell, each over
/// the same rakun closure. A source the OTP compiler accepted is
/// therefore remembered as an empty `<cache_dir>/<k[0..2]>/<k>.ok`, `k` the
/// SHA-256 of the source bytes and of everything else the verdict depends on:
/// the options, the OTP release, the erts / `compiler` / `stdlib` versions and
/// `ERL_COMPILER_OPTIONS` — the key of `test_cmd.zig`'s `.beam` cache with
/// its own label. A source whose key is there is not compiled again: the same
/// bytes under the same compiler get the same verdict. Only an acceptance is
/// stored — a refusal is compiled, and printed, every time — and a source that
/// names `-include` or `parse_transform` (its verdict depends on other files)
/// is never looked up. The lookup is inside the same `erl`, so a build with no
/// working `erl` fails exactly as before. Markers are written by staging and
/// renaming; a hit refreshes the marker's mtime, and each check reaps one of
/// the 256 shards at random (markers unused for 7 days, staging files older
/// than a day).
fn checkErlang(
    arena: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    packages: bp.codegen.crossModule.Packages,
    cache_dir: ?[]const u8,
) !bool {
    // The files go through a list file, never the command line: one path per
    // module made `erl`'s argv grow with the program, and a 203-module build
    // with a deep `--out` passed macOS's 1 MiB `ARG_MAX` (`arglist.zig`).
    var files = std.ArrayListUnmanaged([]const u8).empty;
    for (outputs) |o| {
        if (o.result.failed()) continue;
        try files.append(arena, try artifactPath(arena, out_dir, .erlang, packages, o.name, ".erl"));
        for (o.result.units) |u| {
            try files.append(arena, try std.fmt.allocPrint(arena, "{s}/{s}{s}.erl", .{ out_dir, targetSubdir(.erlang), u.atom }));
        }
    }
    if (files.items.len == 0) return true;
    const list = try arglist.write(arena, io, files.items);
    defer arglist.remove(io, list);

    // The plain arguments are the verdict cache directory (`-` for none) and the list file.
    const argv: []const []const u8 = &.{ "erl", "-noshell", "-eval", ERLANG_CHECK_EVAL, "-extra", cache_dir orelse "-", list };
    const result = std.process.run(arena, io, .{
        .argv = argv,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    }) catch |err| {
        const msg = try std.fmt.allocPrint(arena, "`botopink build --target erlang` compiles what it emits with the OTP compiler, and {s}", .{arglist.spawnError(arena, "erl", argv, err)});
        reporter.errMsg(msg);
        if (err == error.FileNotFound) reporter.hintMsg("install Erlang/OTP 28+ and put `erl` on PATH");
        return false;
    };
    if (result.stdout.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stdout) catch {};
    if (result.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stderr) catch {};
    const code: u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => 1,
    };
    if (code == 0) return true;
    reporter.errMsg("the OTP compiler refused emitted erlang — the build is not a program");
    return false;
}

/// The check `checkErlang` runs in one `erl`: the plain arguments are the
/// verdict cache directory (`-` for none) and the list file naming the files
/// (`arglist.write`); the files are dealt
/// round-robin to one process per online scheduler, each compiling its share
/// in memory unless its verdict is cached; every refusal is printed as
/// `<file>:<line>: <message>`; exit 1 when there is any.
const ERLANG_CHECK_EVAL =
    \\[CacheArg, ListFile] = init:get_plain_arguments(),
++ arglist.READ_LIST("Files", "ListFile") ++
    \\Tag = case CacheArg of
    \\    "-" -> none;
    \\    _ ->
    \\        try
    \\            _ = crypto:hash(sha256, <<>>),
    \\            term_to_binary({<<"botopink-erl-check-1">>, [binary, return_errors],
    \\                            erlang:system_info(otp_release), erlang:system_info(version),
    \\                            filename:basename(code:lib_dir(compiler)),
    \\                            filename:basename(code:lib_dir(stdlib)),
    \\                            os:getenv("ERL_COMPILER_OPTIONS")})
    \\        catch _:_ -> none
    \\        end
    \\end,
    \\Marker = fun(F) ->
    \\    case Tag =/= none andalso file:read_file(F) of
    \\        {ok, Text} ->
    \\            case lists:all(fun(W) -> binary:match(Text, W) =:= nomatch end,
    \\                           [<<"-include">>, <<"parse_transform">>]) of
    \\                true ->
    \\                    Key = binary:encode_hex(crypto:hash(sha256, [Tag, Text]), lowercase),
    \\                    <<Shard:2/binary, _/binary>> = Key,
    \\                    filename:join([CacheArg, Shard, <<Key/binary, ".ok">>]);
    \\                false -> none
    \\            end;
    \\        _ -> none
    \\    end
    \\end,
    \\Accepted = fun(none) -> ok;
    \\              (Mk) ->
    \\                  Tmp = iolist_to_binary([Mk, ".", integer_to_list(erlang:unique_integer([positive])),
    \\                                          "-", os:getpid(), ".tmp"]),
    \\                  catch begin
    \\                      ok = filelib:ensure_dir(Mk),
    \\                      ok = file:write_file(Tmp, <<>>),
    \\                      case file:rename(Tmp, Mk) of ok -> ok; _ -> file:delete(Tmp) end
    \\                  end
    \\           end,
    \\N = erlang:max(1, erlang:system_info(schedulers_online)),
    \\Indexed = lists:zip(lists:seq(0, length(Files) - 1), Files),
    \\Parts = [[F || {I, F} <- Indexed, I rem N =:= K] || K <- lists:seq(0, N - 1)],
    \\Self = self(),
    \\Loc = fun({L, C}) -> io_lib:format("~p:~p", [L, C]); (none) -> "0"; (L) -> io_lib:format("~p", [L]) end,
    \\Compile = fun(F, Mk) ->
    \\    case catch compile:file(F, [binary, return_errors]) of
    \\        {ok, _, _} -> Accepted(Mk), [];
    \\        {ok, _, _, _} -> Accepted(Mk), [];
    \\        {error, Errors, _} ->
    \\            [io_lib:format("~ts:~ts: ~ts~n", [File, Loc(L), M:format_error(D)])
    \\             || {File, Items} <- Errors, {L, M, D} <- Items];
    \\        Other -> [io_lib:format("~ts: ~p~n", [F, Other])]
    \\    end
    \\end,
    \\Check = fun(F) ->
    \\    Mk = Marker(F),
    \\    case Mk =/= none andalso filelib:is_regular(Mk) of
    \\        true -> file:change_time(Mk, erlang:localtime()), [];
    \\        false -> Compile(F, Mk)
    \\    end
    \\end,
    \\Refs = [begin
    \\            R = make_ref(),
    \\            spawn(fun() -> Self ! {R, lists:append([Check(F) || F <- Part])} end),
    \\            R
    \\        end || Part <- Parts],
    \\Out = lists:append([receive {R, Lines} -> Lines end || R <- Refs]),
    \\io:put_chars(Out),
    \\case Tag of
    \\    none -> ok;
    \\    _ ->
    \\        catch begin
    \\            Pick = binary_to_list(binary:encode_hex(<<(rand:uniform(256) - 1)>>, lowercase)),
    \\            Now = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
    \\            Reap = fun(Pattern, MaxAge) ->
    \\                [case filelib:last_modified(F) of
    \\                     0 -> ok;
    \\                     T ->
    \\                         case Now - calendar:datetime_to_gregorian_seconds(T) > MaxAge of
    \\                             true -> file:delete(F);
    \\                             false -> ok
    \\                         end
    \\                 end || F <- filelib:wildcard(filename:join([CacheArg, Pick, Pattern]))]
    \\            end,
    \\            Reap("*.ok", 7 * 86400),
    \\            Reap("*.tmp", 86400)
    \\        end
    \\end,
    \\halt(case Out of [] -> 0; _ -> 1 end).
;

/// `botopink.json` names a target the compiler does not support.
pub fn reportUnsupportedTarget(name: []const u8) void {
    var buf: [256]u8 = undefined;
    reporter.errMsg(std.fmt.bufPrint(&buf, "botopink.json declares an unsupported target '{s}'", .{name}) catch "botopink.json declares an unsupported target");
    reporter.hintMsg("use one of commonJS, erlang, beam or wasm");
}

/// Shared message for a `libs.loadDependencies` failure.
pub fn reportDependencyError(err: anyerror) void {
    switch (err) {
        error.LibsRootNotFound => {
            reporter.errMsg("project declares dependencies but no libs/ directory was found in this or any parent directory");
            reporter.hintMsg("if your botopink.json uses the new object form ({\"<name>\": {\"git\": ...}}), run `bpmp install` to fetch deps into $BPMP_HOME first");
        },
        error.LibNotFound => reporter.hintMsg("libraries resolve from BOTOPINK_LIB_ROOTS, then <ancestor>/repository/botopink-lang/libs, <ancestor>/repository and <ancestor>/libs, then .botopinkbuild/deps (`bpmp install`)"),
        // Already rendered, located in the manifest that is wrong.
        error.LibManifestInvalid => {},
        // Already rendered with the path and the manifest line.
        error.LibFileNotFound => {},
        // Already rendered, located at the `dependencies` entry.
        error.BundledDependency => {},
        else => reporter.errMsg("failed to load project dependencies"),
    }
}

pub fn artifactExt(target: config.Target) []const u8 {
    return switch (target) {
        .commonJS => ".js",
        .erlang => ".erl",
        .beam => ".S",
        .wasm => ".wat",
    };
}

/// The codegen target a CLI target emits.
pub fn targetSource(target: config.Target) bp.codegen.TargetSource {
    return switch (target) {
        .commonJS => .commonJS,
        .erlang => .erlang,
        .beam => .beam,
        .wasm => .wasm,
    };
}

/// Where a target's artifacts live under `out/`.
///
/// `erlc` refuses a `-module` atom that differs from its file's basename, so an
/// erlang or BEAM artifact is named by the module ATOM (`std/math` →
/// `std@math.erl`) and the tree is FLAT — one directory per target, which is
/// also the only shape `erl -pa <one directory>` can load a multi-module program
/// from. commonJS, its `.d.ts` and wasm keep the mirrored module-path tree
/// directly under `out/`: a `require` target and a wasm import segment ARE the
/// module path, so flattening them would break every multi-module JS program.
pub fn targetSubdir(target: config.Target) []const u8 {
    return switch (target) {
        .erlang => "erl/",
        .beam => "beam/",
        .commonJS, .wasm => "",
    };
}

/// `<out_dir>/<subdir><stem><ext>` for one module — the stem is the module atom
/// for erlang and BEAM (its package first, decision 109), the module path for
/// commonJS and wasm. Caller owns it.
pub fn artifactPath(
    alloc: std.mem.Allocator,
    out_dir: []const u8,
    target: config.Target,
    packages: bp.codegen.crossModule.Packages,
    module_name: []const u8,
    ext: []const u8,
) ![]u8 {
    const stem = try bp.codegen.crossModule.outputStem(targetSource(target), alloc, packages.idOf(module_name));
    defer alloc.free(stem);
    return std.fmt.allocPrint(alloc, "{s}/{s}{s}{s}", .{ out_dir, targetSubdir(target), stem, ext });
}

/// Delete the artifact (and `.d.ts`) of every module that failed — and, on
/// erlang and BEAM, the per-`type` modules it wrote beside it when it last
/// succeeded (policy 3 of `13-module-identity`). A failed module carries no
/// `GenerateResult`, so its units cannot be named from the output; they are
/// found by their prefix instead, which is exactly this module's: every unit is
/// `<module atom>@@<Decl><ext>` (decision 109) and no other module can render
/// that stem: `@@` never occurs inside a module atom.
fn removeStaleArtifacts(arena: std.mem.Allocator, io: std.Io, failed: []const []const u8, out_dir: []const u8, target: config.Target, packages: bp.codegen.crossModule.Packages) void {
    for (failed) |name| {
        const exts = [_][]const u8{ artifactExt(target), ".d.ts" };
        for (exts) |ext| {
            const p = artifactPath(arena, out_dir, target, packages, name, ext) catch continue;
            std.Io.Dir.cwd().deleteFile(io, p) catch {};
        }
        removeStaleUnits(arena, io, packages, name, out_dir, target);
    }
}

/// The `<module atom>@@…<ext>` files of one failed module, deleted from the
/// flat per-target directory. A no-op on commonJS and wasm, which emit no units.
fn removeStaleUnits(arena: std.mem.Allocator, io: std.Io, packages: bp.codegen.crossModule.Packages, name: []const u8, out_dir: []const u8, target: config.Target) void {
    switch (target) {
        .erlang, .beam => {},
        .commonJS, .wasm => return,
    }
    const atom = bp.codegen.crossModule.erlAtom(arena, packages.idOf(name)) catch return;
    const prefix = std.fmt.allocPrint(arena, "{s}{s}", .{ atom, bp.codegen.crossModule.DECL_SEP }) catch return;
    const ext = artifactExt(target);
    const dir_path = std.fmt.allocPrint(arena, "{s}/{s}", .{ out_dir, targetSubdir(target) }) catch return;
    var dir = std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);
    var it = dir.iterate();
    while (it.next(io) catch null) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.startsWith(u8, entry.name, prefix)) continue;
        if (!std.mem.endsWith(u8, entry.name, ext)) continue;
        dir.deleteFile(io, entry.name) catch {};
    }
}

// ── Output writer ─────────────────────────────────────────────────────────────

fn writeOutputs(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    target: config.Target,
    packages: bp.codegen.crossModule.Packages,
    env_map: libs.EnvMap,
) !void {
    // Ensure output directory exists.
    std.Io.Dir.cwd().createDirPath(io, out_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const ext = artifactExt(target);

    for (outputs) |o| {
        // A validation error carries no artifact.
        if (o.result.failed()) continue;
        // erlang/BEAM: `out/<target>/<atom><ext>`, flat. commonJS/wasm:
        // `out/<module path><ext>`, so subdirectories may have to be created.
        const sub_path = try artifactPath(gpa, out_dir, target, packages, o.name, ext);
        defer gpa.free(sub_path);

        // Ensure parent directory exists.
        if (std.fs.path.dirname(sub_path)) |parent| {
            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }

        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sub_path, .data = o.result.js });

        // Policy 3 (`13-module-identity`): every `type` of the module is a
        // module of its own on erlang/beam — `out/<target>/<type atom><ext>`,
        // flat beside the file's, which is where `erl -pa` loads it from.
        for (o.result.units) |u| {
            const unit_path = try std.fmt.allocPrint(gpa, "{s}/{s}{s}{s}", .{ out_dir, targetSubdir(target), u.atom, ext });
            defer gpa.free(unit_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = unit_path, .data = u.code });
        }

        // Optional TypeScript typedef.
        if (o.result.typedef) |td| {
            const dts_path = try artifactPath(gpa, out_dir, target, packages, o.name, ".d.ts");
            defer gpa.free(dts_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = dts_path, .data = td });
        }
    }

    // Ship runtime `.mjs` sidecars (G2) so a built program resolves every
    // `#[@External.<targert>(...)]` `require("…/x.mjs")` — including a dependency's, whose
    // emitted module sits a directory deeper than in its own build.
    if (target == .commonJS) {
        try libs.shipMjsSidecars(gpa, io, outputs, packages, out_dir, ext, env_map);
    }
    // erlang and BEAM: a `#[@External.Erlang("host", …)]`'s `host.erl` goes
    // beside the emitted modules — `out/erl/`, where `botopink run` compiles
    // every `.erl` onto the code path, and `out/beam/`, where the assembled
    // entry's `'__bp_load_siblings'/0` compiles and loads every `.erl` beside
    // it. A host module that is neither shipped nor in the Erlang code path is
    // a located refusal here, not an `undef` at run time.
    switch (target) {
        .erlang, .beam => {
            const host_dir = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ out_dir, std.mem.trimEnd(u8, targetSubdir(target), "/") });
            defer gpa.free(host_dir);
            _ = try libs.shipErlSidecars(gpa, io, outputs, packages, host_dir, if (target == .beam) .beam else .erlang, env_map);
        },
        .commonJS, .wasm => {},
    }
}
