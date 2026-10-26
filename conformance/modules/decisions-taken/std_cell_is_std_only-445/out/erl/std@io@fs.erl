-module(std@io@fs).
-export([readBytes/1, readText/1, writeBytes/2, writeText/2, appendText/2, stat/1, list/1, mkdir/1, mkdirRecursive/1, rm/1, removeTree/1, copy/2, walk/1, glob/2, open/1, create/1, openAsset/1, exists/1, lift/2, decode/2, '__bp_priv__fsError'/2, '__bp_priv__statOr'/1, '__bp_priv__makeFixtureTree'/1, '__bp_priv__walkFixture'/1, '__bp_priv__walkFixtureFromCwd'/1, '__bp_priv__walkRefusal'/1, '__bp_priv__describe'/1, '__bp_priv__makeGlobTree'/1, '__bp_priv__globbed'/1, '__bp_priv__variantOf'/1, '__bp_priv__noFile'/0]).

%% behavior bool

%% behavior bytes

%% behavior Integer

%%% std/io/fs — the file system, cross-backend (decision 540).

%%% 

%%% Reference:

%%%   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,

%%%              `File`, `io::ErrorKind`)

%%%   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html

%%%   Erlang   — https://www.erlang.org/doc/man/file.html

%%%   Node.js  — https://nodejs.org/api/fs.html

%%% 

%%% Every function that can fail answers `Result<…, FsError>`: the same OS error is

%%% the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),

%%% and `Other.message` is the host's own text. The whole-file shortcuts

%%% (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and

%%% the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,

%%% `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`

%%% and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.

%%% 

%%% The host cells (`raw…`) write `result: true` (decisions 431, 490) and answer

%%% `Result<R, HostError>` — Node's `ENOENT: …`, erlang's `enoent` as its `message` —

%%% and `lift` reads that message as the `FsError` of the path the caller wrote

%%% (decision 486); no cell catches by hand. All operations are synchronous

%%% (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here

%%% (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).

%% import relative, HostError

% The error of every `io.fs` function (decision 540). `path` is the path the

% caller wrote (for `copy`, the source; for `walk`, the root).

%% type FsError
%%   NotFound(path)
%%   PermissionDenied(path)
%%   IsDirectory(path)
%%   NotDirectory(path)
%%   AlreadyExists(path)
%%   InvalidUtf8(path, offset)
%%   Other(path, message)

%% type FileStat: size, mtime, isDir

% Read the whole file as bytes.

% Node: `readFileSync($0)` copied into a plain `Uint8Array`.

% Erlang: `file:read_file/1`.

%% external fn rawReadBytes -> erlang template

% Write `contents` to `path`, creating or truncating.

% Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.

%% external fn rawWriteBytes -> erlang template

% Append `contents` to `path`, creating it when it is not there.

% Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.

%% external fn rawAppendText -> erlang template

% The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence

% starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),

% or -1 when every byte is part of a valid sequence — the same offset on every target.

% Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.

%% external fn utf8Offset -> erlang template

% `line` without its line terminator: one trailing `\n`, and the `\r` before it.

% Node: `subarray`. Erlang: `binary:part/3`.

%% external fn stripEol -> erlang template

% The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts

% (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,

% mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).

%% external fn rawOpen -> erlang template

% The handle of the file at `path`, open for writing: created, or truncated.

%% external fn rawCreate -> erlang template

% A handle over bytes held in memory — what an `Asset` opens as. The position is a field

% on Node and a `counters` cell on Erlang.

%% external fn memHandle -> erlang template

% The size of the file behind `handle`, in bytes. On Erlang it reads `path`.

%% external fn rawSize -> erlang template

% Up to `n` bytes (n > 0) from the handle's position; empty at the end.

%% external fn rawRead -> erlang template

% Every byte from the handle's position to the end.

%% external fn rawReadAll -> erlang template

% The next line, terminator included; empty at the end.

%% external fn rawReadLine -> erlang template

% The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,

% whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the

% position undefined (OTP moves it), so the position is read first and restored.

%% external fn rawHash -> erlang template

% Write `bytes` at the handle's position; answers how many.

%% external fn rawWrite -> erlang template

% Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).

%% external fn rawClose -> erlang template

% Write `contents` to `path`, creating or truncating. Reds with the

% host's I/O error message.

% Node: `require('fs').writeFileSync($0, $1)`.

% Erlang: `file:write_file/2`.

%% external fn rawWriteText -> erlang template

% Whether a path exists, of any kind: a regular file, a directory, a

% character or block device (`/dev/null`), a FIFO or a socket. A symbolic

% link is followed — one whose target is missing is `false`, the answer

% every read through it would give.

% Node: `require('fs').existsSync($0)` (a `stat`).

% Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it

% replaces, answers only regular files and directories, so `/dev/null`

% was `false` on erlang and `true` on commonJS).

%% external fn exists -> erlang template
exists(Path) ->
    (case file:read_file_info(Path) of {ok, _} -> true; _ -> false end).

% List the names of the directory entries at `path` (relative).

% Node: `require('fs').readdirSync($0)`.

% Erlang: `file:list_dir/1` returns `{ok, [string()]}`.

%% external fn rawList -> erlang template

% Create directory at `path`. Use `mkdirRecursive` to create

% intermediate parents.

% Node: `require('fs').mkdirSync($0)`.

% Erlang: `file:make_dir/1`.

%% external fn rawMkdir -> erlang template

% Create the directory at `path` and every missing directory above it. A

% directory that is already there is `Ok` too; a path that exists as anything

% else (a file) is an `Error`. What the snapshot library (`snap`) makes the

% directory of a `.snap` with (decision 391).

% Node: `require('fs').mkdirSync($0, { recursive: true })`.

% Erlang: `filelib:ensure_path/1`.

%% external fn rawMkdirRecursive -> erlang template

% Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on

% both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after

% a `read_link_info`, so the variant is the same); `removeTree` removes one.

% Node: `require('fs').rmSync($0)`.

% Erlang: `file:delete/1`.

%% external fn rawRm -> erlang template

% Copy file from `src` to `dest`. Reds when `src` is missing or

% `dest` already exists (Node's default `copyFileSync` semantics).

% Node: `require('fs').copyFileSync($0, $1)`.

% Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).

%% external fn rawCopy -> erlang template

% File metadata. Returns a `FileStat { size, mtime, isDir }` on

% success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);

% `size` is in bytes.

% Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond

% `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole

% seconds, × 1000, and both answer decision 319's canonical form (a `number`

% within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.

% Erlang: `file:read_file_info/1` returns a `#file_info` record; the

% template projects the `size`, `mtime`, and `type` fields. Its `mtime` is

% whole seconds × 1000. One value on every target: whole seconds (decision 499).

%% external fn rawStat -> erlang template

% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

% Every REGULAR FILE under `root`, recursively, as paths relative to `root`

% with `/` separators, sorted — the same set on both targets (the two hosts

% walk in different orders, so the list is sorted rather than left as found),

% and the same paths however the root is spelled: `dir`, `dir/`, `dir/.`,

% `./dir`, `dir/sub/..`, absolute or relative to the working directory.

% Directories are not listed; a link is followed (a link to a file is listed

% under its own name, a link to a directory is walked). An `Error`: a missing

% or non-directory `root`, a directory under it that cannot be read, and a

% DANGLING link (decision 178) — `fs.walk: dangling link "<relative path>"`,

% the same text on both targets, naming the first one in sorted order.

% Node: `readdirSync(root, { recursive: true })` answers files AND directories

% relative to `root`; the template sorts them, keeps the entries `statSync`

% says are files, and answers the dangling-link `Error` for the first entry

% `statSync` cannot find (`throwIfNoEntry: false`).

% Erlang: the template walks `file:list_dir/1` itself and BUILDS each relative

% path from the names it descended through. It never cuts a prefix off a full

% path: `filelib:fold_files/5` answers full paths `filename:join/2` has

% normalised (`dir/.` + `app` is `dir/app`), so a prefix measured on the root

% as written cut two characters too many when the root ended in `/.`.

%% external fn rawWalk -> erlang template

% The entries under `root` matching the glob `pattern`, as paths relative to

% `root` with `/` separators, sorted, each once. The pattern is read segment

% by segment, by ONE rule on both targets (decision 177 — the narrower of what

% the two hosts did):

%   - `**` is zero or more directories; a segment with `*`, `?`, `[…]` or

%     `{a,b}` matches the names of one directory; any other segment is a name.

%   - `*` and `**` (and `?`, `[…]`, `{…}`) do NOT match a name that starts

%     with `.` — a segment matches one only when the segment itself starts

%     with the dot (`.*`, `.config/*.json`).

%   - the walk does NOT descend through a link to a directory: `**` and a

%     wildcard segment continue into real directories only. The link is still

%     a NAME — `*` lists it — and a segment that names it (`linked/*.bp`) goes

%     through it, because the pattern wrote it.

%   - the last segment matches an entry of any kind (file, directory, link,

%     dangling or not); a final `**` is every entry at every depth; a trailing

%     `/` keeps real directories only.

% An alternative of `{a,b}` cannot hold a `/` (the pattern is split first). A

% root that does not exist answers `Ok([])`; so does a directory that cannot

% be read. Both cells are the same walk; only the match of ONE segment against

% ONE directory is the host's — `fs.globSync(segment, { cwd })` (Node 22+),

% `filelib:wildcard/2` — with the dot rule applied over its answer, since

% `filelib:wildcard` matches dot names and `globSync` matches `{.a,b}`.

%% external fn rawGlob -> erlang template

% Remove `path` and everything under it: a file, a link (the link, never its

% target) or a directory tree. A path that is not there is `Ok` too — the

% caller wanted it gone. What a test fixture is cleared with, and what the

% snapshot engine's tests clear their scratch directories with (1.0.11-beta

% front 97).

% Node: `rmSync(path, { recursive: true, force: true })`.

% Erlang: `file:del_dir_r/1`.

%% external fn rawRemoveTree -> erlang template

% Internal, test scaffolding: a fresh, unique, empty directory under the

% host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in

% one of these and removes it with `removeTree`, so a run leaves nothing under

% the host's tmpdir.

%% external fn scratchDir -> erlang template

% Internal, test scaffolding: the working directory (what a relative root is

% read against) and a symbolic link `link` → `target`.

%% external fn workingDir -> erlang template

%% external fn linkTo -> erlang template

% ── the typed error ──────────────────────────────────────────────────────────

% The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.

fsError(Path, E) ->
    U = string:uppercase(erlang:element(2, E)),
    case (string:prefix(U, <<"ENOENT">>) =/= nomatch) of
        true ->
            {std@io@fs@@FsError__v__notfound, Path};
        _ ->
            case ((string:prefix(U, <<"EACCES">>) =/= nomatch) orelse (string:prefix(U, <<"EPERM">>) =/= nomatch)) of
                true ->
                    {std@io@fs@@FsError__v__permissiondenied, Path};
                _ ->
                    case ((string:prefix(U, <<"EISDIR">>) =/= nomatch) orelse (string:prefix(U, <<"PATH IS A DIRECTORY">>) =/= nomatch)) of
                        true ->
                            {std@io@fs@@FsError__v__isdirectory, Path};
                        _ ->
                            case (string:prefix(U, <<"ENOTDIR">>) =/= nomatch) of
                                true ->
                                    {std@io@fs@@FsError__v__notdirectory, Path};
                                _ ->
                                    case (string:prefix(U, <<"EEXIST">>) =/= nomatch) of
                                        true ->
                                            {std@io@fs@@FsError__v__alreadyexists, Path};
                                        _ ->
                                            {std@io@fs@@FsError__v__other, Path, erlang:element(2, E)}
                                    end
                            end
                    end
            end
    end.

% A host cell's answer, its failure read as an `FsError` of `path`.

lift(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

% The text of `b`, or `InvalidUtf8` at the first invalid byte.

decode(Path, B) ->
    Offset = (fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)(B),
    case (Offset >= 0) of
        true ->
            {error, {std@io@fs@@FsError__v__invalidutf8, Path, Offset}};
        _ ->
            {ok, (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (<<"">>) end end)((fun(__B) -> case unicode:characters_to_binary(__B) of __S when is_binary(__S) -> {ok, __S}; _ -> {error, <<"bytes.toUtf8: not valid UTF-8">>} end end)(B))}
    end.

% What `rawWalk` finds under a root: the regular files, and the links whose

% target is missing, both as paths relative to the root, sorted.

%% type Walked: files, dangling

% Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.

%% external fn rawReadOnly -> erlang template

% ── whole-file shortcuts ─────────────────────────────────────────────────────

% The file's bytes.

readBytes(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, B} ->
            {ok, B};
        {error, _TryE0} -> {error, _TryE0}
    end.

% The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every

% target — never node's silent U+FFFD nor erlang's unchecked binary.

readText(Path) ->
    case readBytes(Path) of
        {ok, B} ->
            case decode(Path, B) of
                {ok, S} ->
                    {ok, S};
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

% Write `contents` to `path`, creating or truncating.

writeBytes(Path, Contents) ->
    case lift(Path, (fun(__BpA0, __BpA1) -> try ((fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

writeText(Path, Contents) ->
    case lift(Path, (fun(__BpA0, __BpA1) -> try ((fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

% Append `contents`, creating the file when it is not there.

appendText(Path, Contents) ->
    case lift(Path, (fun(__BpA0, __BpA1) -> try ((fun(__P, __C) -> case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

% ── metadata and directories ─────────────────────────────────────────────────

stat(Path) ->
    case lift(Path, '__bp_adopt'((fun(__BpA0) -> try ((fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path), std@io@fs@@FileStat, [size, mtime, isDir])) of
        {ok, S} ->
            {ok, S};
        {error, _TryE0} -> {error, _TryE0}
    end.

list(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, Names} ->
            {ok, Names};
        {error, _TryE0} -> {error, _TryE0}
    end.

mkdir(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

mkdirRecursive(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

rm(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, eisdir}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

removeTree(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

copy(Src, Dest) ->
    case lift(Src, (fun(__BpA0, __BpA1) -> try ((fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Src, Dest)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

walk(Root) ->
    case lift(Root, '__bp_adopt'((fun(__BpA0) -> try ((fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> erlang:error(__E); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> erlang:error(__X) end end, __Acc, __Names) end end, __Found = __Walk(__Root, [], []), {ok, #{files => lists:sort([__F || {file, __F} <- __Found]), dangling => lists:sort([__D || {dangling, __D} <- __Found])}} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Root), std@io@fs@@Walked, [files, dangling])) of
        {ok, Found} ->
            case (erlang:length(erlang:element(3, Found)) > 0) of
                true ->
                    First = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(erlang:element(3, Found), 0) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end,
                    {error, {std@io@fs@@FsError__v__other, Root, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"fs.walk: dangling link \"">>, First, <<"\"">>])))}};
                _ ->
                    {ok, erlang:element(2, Found)}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

glob(Pattern, Root) ->
    {ok, (fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))] end)(Pattern, Root)}.

% The host's handle over embedded bytes: read like a file, never closed on disk.

%% external fn memoryHandle -> erlang template

% ── the handle ───────────────────────────────────────────────────────────────

% An open file (decision 540 (3)). `location` is the path it was opened with and

% `handle` the host's — opaque, never read by a program. Closed by the writer:

% `val f = try fs.open(p); defer f.close();`.

%% type File: location, handle

% Open the file at `path` for reading. A directory is `IsDirectory` on every target.

open(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:open(__P, [read, binary, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, H} ->
            {ok, {std@io@fs@@File, Path, H}};
        {error, _TryE0} -> {error, _TryE0}
    end.

% Open the file at `path` for writing: created, or truncated.

create(Path) ->
    case lift(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, H} ->
            {ok, {std@io@fs@@File, Path, H}};
        {error, _TryE0} -> {error, _TryE0}
    end.

% An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read

% like a file on disk — no `Result`, the build proved the file exists — and

% closing it is a no-op.

openAsset(Asset) ->
    {std@io@fs@@File, '__bp_field'(Asset, path), {mem, '__bp_field'(Asset, bytes), counters:new(1, [])}}.

% ── tests ────────────────────────────────────────────────────────────────────

% (Inline tests are smoke-grade — they require the host filesystem to be

% writable at the host's `tmpdir()`. The lib-test harness runs each

% inline test as a separate process; the temp filenames are seeded with

% `time.nowMillis()` for cross-run uniqueness.)






% Internal, test scaffolding: `stat(p)`, or a stat no file has.

statOr(P) ->
    case stat(P) of
        {ok, S} ->
            S;
        {error, _} ->
            {std@io@fs@@FileStat, (-1), (-1), false}
    end.


% Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,

% `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.

makeFixtureTree(Dir) ->
    mkdir(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app">>])))),
    mkdir(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog">>])))),
    writeText(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/page.bp">>]))), <<"root page">>),
    writeText(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog/page.bp">>]))), <<"blog page">>),
    writeText(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog/notes.md">>]))), <<"notes">>).

% Internal, test scaffolding: what `walk` answers for the fixture tree when

% its root is spelled `<scratch dir><suffix>` — every spelling of one root has

% to answer the same three relative paths.

walkFixture(Suffix) ->
    Dir = (fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)(),
    makeFixtureTree(Dir),
    Walked = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ([<<"<error>">>]) end end)(walk(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, Suffix]))))),
    removeTree(Dir),
    iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Walked))).

% Internal, test scaffolding: the same, with the root spelled relative to the

% working directory — `<prefix><path from the cwd to the fixture>`.

walkFixtureFromCwd(Prefix) ->
    Dir = (fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)(),
    makeFixtureTree(Dir),
    Root = iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Prefix, std@path:relative((fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)(), Dir), <<"/app">>]))),
    Walked = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ([<<"<error>">>]) end end)(walk(Root)),
    removeTree(Dir),
    iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Walked))).










% Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.

walkRefusal(Root) ->
    case walk(Root) of
        {ok, _} ->
            <<"">>;
        {error, E} ->
            describe(E)
    end.

% Internal, test scaffolding: an `FsError` as one line — the variant, the path

% and the message where it holds one (a dangling link is `Other`, decision 178).

describe(E) ->
    case E of
        {std@io@fs@@FsError__v__notfound, P} ->
            <<"NotFound ", ('__bp_text'(P))/binary>>;
        {std@io@fs@@FsError__v__permissiondenied, P@1} ->
            <<"PermissionDenied ", ('__bp_text'(P@1))/binary>>;
        {std@io@fs@@FsError__v__isdirectory, P@2} ->
            <<"IsDirectory ", ('__bp_text'(P@2))/binary>>;
        {std@io@fs@@FsError__v__notdirectory, P@3} ->
            <<"NotDirectory ", ('__bp_text'(P@3))/binary>>;
        {std@io@fs@@FsError__v__alreadyexists, P@4} ->
            <<"AlreadyExists ", ('__bp_text'(P@4))/binary>>;
        {std@io@fs@@FsError__v__invalidutf8, P@5, Offset} ->
            <<"InvalidUtf8 ", ('__bp_text'(P@5))/binary, " ", ('__bp_text'(erlang:integer_to_binary(Offset)))/binary>>;
        {std@io@fs@@FsError__v__other, P@6, Message} ->
            Message
    end.







% Internal, test scaffolding: the fixture tree plus the names decision 177 is

% about — a dot file and a dot directory, a link to a directory, a link to a

% file and a dangling link, all under `<dir>/app`.

makeGlobTree(Dir) ->
    makeFixtureTree(Dir),
    mkdir(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/.cache">>])))),
    writeText(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/.cache/page.bp">>]))), <<"cached">>),
    writeText(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/.hidden.bp">>]))), <<"hidden">>),
    writeText(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog/.draft.md">>]))), <<"draft">>),
    (fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)(<<"blog">>, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/linked">>])))),
    (fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)(<<"page.bp">>, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/alias.bp">>])))),
    (fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)(<<"missing.bp">>, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/gone.bp">>])))).

% Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over

% `makeGlobTree`, joined by `,`.

globbed(Pattern) ->
    Dir = (fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)(),
    makeGlobTree(Dir),
    Found = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ([<<"<error>">>]) end end)(glob(Pattern, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app">>]))))),
    removeTree(Dir),
    iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Found))).









% ── FsError, readText and the handle ─────────────────────────────────────────

% Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.

variantOf(R) ->
    case R of
        {ok, _} ->
            <<"ok">>;
        {error, E} ->
            describe(E)
    end.




% Internal, test scaffolding: the file a failed `open` falls back to.

noFile() ->
    {std@io@fs@@File, <<"">>, {mem, <<"">>, counters:new(1, [])}}.



% Internal, test scaffolding: take every permission from `path`; whether that

% denies this user anything (root is denied nothing), and give them back.

%% external fn denyAll -> erlang template

%% external fn allowAll -> erlang template


'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'__bp_adopt'(V, T, Ks) when erlang:is_map(V) -> erlang:list_to_tuple([T | [maps:get(K, V, undefined) || K <- Ks]]);
'__bp_adopt'(V, T, Ks) when erlang:is_list(V) -> ['__bp_adopt'(E, T, Ks) || E <- V];
'__bp_adopt'({ok, V}, T, Ks) -> {ok, '__bp_adopt'(V, T, Ks)};
'__bp_adopt'(V, _, _) -> V.

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'__bp_priv__fsError'(A0, A1) -> fsError(A0, A1).

'__bp_priv__statOr'(A0) -> statOr(A0).

'__bp_priv__makeFixtureTree'(A0) -> makeFixtureTree(A0).

'__bp_priv__walkFixture'(A0) -> walkFixture(A0).

'__bp_priv__walkFixtureFromCwd'(A0) -> walkFixtureFromCwd(A0).

'__bp_priv__walkRefusal'(A0) -> walkRefusal(A0).

'__bp_priv__describe'(A0) -> describe(A0).

'__bp_priv__makeGlobTree'(A0) -> makeGlobTree(A0).

'__bp_priv__globbed'(A0) -> globbed(A0).

'__bp_priv__variantOf'(A0) -> variantOf(A0).

'__bp_priv__noFile'() -> noFile().
