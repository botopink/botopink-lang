----- SOURCE CODE -- std/path.bp
```botopink
//// std/path — pure-botopink path manipulation (posix forward-slash).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/path.html
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html
////
//// Lib-self-contained: every operation composes `String` methods (`split`,
//// `slice`, `length`, `startsWith`), so the module works on every backend
//// including wat. Forward-slash separator only — Windows backslash paths
//// are not normalised here (the spec keeps `path` posix-shaped; a
//// `path_win32` sibling can land later if a target needs it).

pub val separator: string = "/";

pub val delimiter: string = ":";

// Split a path into its non-empty components. Leading-`/` paths drop the
// empty head; trailing-`/` paths drop the empty tail. A path made of pure
// separators yields the empty array. Uses `filter` rather than
// `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store
// (`out ++ [p]` discarded) on Erlang because the immutable runtime never
// rebinds `Out`; `filter` round-trips through `lists:filter/2` and
// `Array.prototype.filter` directly.
pub fn split(path: string) -> string[] {
    val raw = path.split(separator);
    return raw.filter({ p -> p != "" });
}

// True when `path` starts with `/` — the posix absolute-path marker.
pub fn isAbsolute(path: string) -> bool {
    return path.startsWith(separator);
}

// The last non-empty component of `path` (the file name, in the common
// case). Returns "" for the empty path and for pure-separator paths.
pub fn basename(path: string) -> string {
    val parts = split(path);
    val n = parts.length;
    if (n == 0) return "";
    return parts.at(n - 1) ?? "";
}

// Everything except the basename — the parent directory portion. For an
// absolute path this preserves the leading `/`. For a path with no
// separator (`"foo"`), returns `""`.
pub fn dirname(path: string) -> string {
    val parts = split(path);
    val n = parts.length;
    if (n <= 1) return if (isAbsolute(path)) separator else "";
    val head = parts.slice(0, n - 1);
    val joined = head.join(separator);
    // String `+` lowers to numeric `+` on Erlang (badarith on binaries);
    // use a 2-element array `.join("")` to concat instead — that goes
    // through `lists:join("", …)` + `iolist_to_binary` on Erlang and
    // `Array.prototype.join("")` on Node, both string-safe.
    return if (isAbsolute(path)) [separator, joined].join("") else joined;
}

// The trailing extension on the basename — the substring from the LAST
// `.` to the end, including the dot. Returns `""` when the basename has
// no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).
pub fn extname(path: string) -> string {
    val base = basename(path);
    val pieces = base.split(".");
    val n = pieces.length;
    if (n <= 1) return "";
    val head = pieces.at(0) ?? "";
    val tail = pieces.at(n - 1) ?? "";
    // Dotfiles like ".bashrc" split into ["", "bashrc"] — no extension.
    val isDotfile = head == "" && n == 2;
    return if (isDotfile) "" else [".", tail].join("");
}

// Join a list of path segments with the separator. Leading separator on
// the first segment is preserved; intra-segment slashes are normalised
// (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
// `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
// on `Array<T>` default-fn bodies that lower to a `var` + `push` shape,
// which lowers to a dead store on Erlang's immutable runtime (the same
// trap `split` sidesteps).
pub fn join(parts: string[]) -> string {
    val isAbs = if (parts.length == 0) false else isAbsolute(parts.at(0) ?? "");
    val collapsed = parts.map({ p -> split(p).join(separator) });
    val joined = collapsed.filter({ p -> p != "" }).join(separator);
    return if (isAbs) [separator, joined].join("") else joined;
}

// Collapse `//` and drop `.` segments via a `filter` over the split
// pieces. Full `..` pop semantics are deferred: they need a stack-shaped
// accumulator and `var` reassignment, which lowers to a dead store on
// Erlang's immutable runtime (the same trap `split`/`join` sidestep with
// `filter`/`flatMap`).
pub fn normalize(path: string) -> string {
    if (path == "") return ".";
    val isAbs = isAbsolute(path);
    val pieces = split(path).filter({ p -> p != "." });
    val joined = pieces.join(separator);
    return if (isAbs)
        [separator, joined].join("")
    else if (joined == "")
        "."
    else
        joined;
}

// Internal: count how many leading components two split paths share. Tail-
// recursive on `i` so the accumulator never needs a `var` rebind (which
// lowers to a dead store on Erlang's immutable runtime).
fn commonPrefixCount(a: string[], b: string[], i: i32) -> i32 {
    if (i >= a.length) return i;
    if (i >= b.length) return i;
    val ai = a.at(i) ?? "";
    val bi = b.at(i) ?? "";
    return if (ai == bi) commonPrefixCount(a, b, i + 1) else i;
}

// Internal: build an array of `n` ".." strings via head/tail recursion.
// Avoids a `var` + `push` accumulator (the Erlang dead-store trap).
fn makeUps(n: i32) -> string[] {
    return if (n <= 0) [] else makeUps(n - 1).prepend("..");
}

// The relative path from `src` to `dst` — the path you would prefix to
// `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`
// fallback — that belongs in `process` once it lands). Returns "." when
// the paths point at the same location.
//
// `src` is named `src` rather than `from` because `from` is a reserved
// keyword (the `import { … } from "<lib>"` syntax) — it does not parse
// as a parameter name.
pub fn relative(src: string, dst: string) -> string {
    val srcParts = split(src);
    val dstParts = split(dst);
    val common = commonPrefixCount(srcParts, dstParts, 0);
    val ups = makeUps(srcParts.length - common);
    val downs = dstParts.slice(common, dstParts.length);
    val combined = ups.append(downs);
    val joined = combined.join(separator);
    return if (joined == "") "." else joined;
}

// Internal accumulator for `resolve`: a list of normalised path parts
// plus whether the resolved-so-far path is absolute. The record carries
// the state through the tail-recursive `resolveAll` so no `var` is
// needed.
type PathAccum(
    isAbs: bool,
    parts: string[],
)

// Internal: apply each component of one segment (post-split) to the
// accumulator, popping for `..` and appending the rest. Head/tail
// recursive — no `var` rebinds.
fn applyPieces(acc: string[], pieces: string[]) -> string[] {
    if (pieces.length == 0) return acc;
    val p = pieces.at(0) ?? "";
    val rest = pieces.slice(1, pieces.length);
    val nextAcc = if (p == "..") {
        if (acc.length == 0) acc else acc.slice(0, acc.length - 1);
    } else acc.append([p]);
    return applyPieces(nextAcc, rest);
}

fn resolveStep(state: PathAccum, seg: string) -> PathAccum {
    val pieces = split(seg);
    val nextIsAbs = isAbsolute(seg) || state.isAbs;
    val baseParts = if (isAbsolute(seg)) [] else state.parts;
    return PathAccum(isAbs: nextIsAbs, parts: applyPieces(baseParts, pieces));
}

fn resolveAll(segments: string[], i: i32, state: PathAccum) -> PathAccum {
    if (i >= segments.length) return state;
    val seg = segments.at(i) ?? "";
    val next = resolveStep(state, seg);
    return resolveAll(segments, i + 1, next);
}

// Resolve a list of path segments into a single normalised path.
// Absolute segments restart the accumulator (matches Node's
// `path.resolve`); `..` pops one component; `.` drops out (already
// filtered by `split`). The empty input resolves to ".".
pub fn resolve(segments: string[]) -> string {
    val finalState = resolveAll(
        segments,
        0,
        PathAccum(isAbs: false, parts: []),
    );
    val joined = finalState.parts.join(separator);
    return if (finalState.isAbs)
        [separator, joined].join("")
    else if (joined == "")
        "."
    else
        joined;
}

// ── 1.0.10-beta front 01 additions ───────────────────────────────────────────

// `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`
// → `archive.tar`, `noext` → `noext`. The extension is what `extname`
// answers, so a dotfile keeps its name.
pub fn withoutExtension(p: string) -> string {
    val ext = extname(p);
    val n = p.length;
    val stem = if (ext == "") p else p.slice(0, n - ext.length);
    return stem;
}

// True when `child` resolves inside `parent` — the traversal guard front 22
// applies before it turns a request path into a file path. Both sides go
// through `resolve`, which pops `..` (`normalize` does not), and a relative
// `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is
// true and `isInside("/app", "blog/../../etc")` is false. A parent is inside
// itself. The check reads the first component of the relative path: `..`
// exactly, or `../…` — a component that merely starts with two dots
// (`..foo`) is a name, not an escape.
pub fn isInside(parent: string, child: string) -> bool {
    val up = resolve([parent]);
    val down = resolve([parent, child]);
    val rel = relative(up, down);
    val escapes = rel == ".." || rel.startsWith("../");
    return escapes == false;
}

// ── tests ────────────────────────────────────────────────────────────────────

test "path.separator is forward slash" {
    assert separator == "/";
}

test "path.isAbsolute distinguishes leading slash" {
    assert isAbsolute("/usr/bin");
    assert isAbsolute("foo/bar").negate();
}

test "path.split drops empties" {
    val s = split("/usr//bin/");
    assert s.length == 2;
    assert s.at(0) ?? "" == "usr";
    assert s.at(1) ?? "" == "bin";
}

test "path.basename returns the last component" {
    assert basename("/usr/bin/zig") == "zig";
    assert basename("foo") == "foo";
    assert basename("") == "";
}

test "path.dirname returns the parent" {
    assert dirname("/usr/bin/zig") == "/usr/bin";
    assert dirname("foo/bar") == "foo";
    assert dirname("foo") == "";
    assert dirname("/foo") == "/";
}

test "path.extname returns the trailing suffix" {
    assert extname("file.txt") == ".txt";
    assert extname("archive.tar.gz") == ".gz";
    assert extname("README") == "";
    assert extname(".bashrc") == "";
}

test "path.join concatenates with separator" {
    assert join(["foo", "bar", "baz"]) == "foo/bar/baz";
    assert join(["/foo", "bar"]) == "/foo/bar";
    assert join(["foo/", "/bar"]) == "foo/bar";
}

test "path.normalize collapses doubles" {
    assert normalize("/foo//bar") == "/foo/bar";
    assert normalize("foo/./bar") == "foo/bar";
}

test "path.normalize on empty is dot" {
    assert normalize("") == ".";
}

test "path.relative same dir" {
    assert relative("/a/b/c", "/a/b/c") == ".";
}

test "path.relative up one" {
    assert relative("/a/b/c", "/a/b") == "..";
}

test "path.resolve absolute" {
    assert resolve(["/a", "b", "c"]) == "/a/b/c";
}

test "path.resolve with double-dot" {
    assert resolve(["/a", "b", "..", "c"]) == "/a/c";
}

test "path.withoutExtension strips the trailing extension only" {
    assert withoutExtension("page.bp") == "page";
    assert withoutExtension("archive.tar.gz") == "archive.tar";
    assert withoutExtension("noext") == "noext";
    assert withoutExtension(".bashrc") == ".bashrc";
    assert withoutExtension("app/blog/page.bp") == "app/blog/page";
}

test "path.isInside accepts a descendant and the parent itself" {
    assert isInside("/app", "/app/blog/page.bp");
    assert isInside("/app", "blog/page.bp");
    assert isInside("/app", "/app");
}

test "path.isInside rejects a path that escapes the parent" {
    assert isInside("/app", "/app/../etc/passwd").negate();
    assert isInside("/app", "/app/blog/../../etc").negate();
    assert isInside("/app", "/application/x").negate();
    assert isInside("/app", "/etc").negate();
}

test "path.isInside treats a name starting with two dots as a name" {
    assert isInside("/app", "/app/..hidden/x");
}

```

----- ERLANG -- std/path.erl
```erlang
-module(std@path).
-export([split/1, isAbsolute/1, basename/1, dirname/1, extname/1, join/1, normalize/1, relative/2, resolve/1, withoutExtension/1, isInside/2, separator/0, delimiter/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__commonPrefixCount'/3, '__bp_priv__makeUps'/1, '__bp_priv__applyPieces'/2, '__bp_priv__resolveStep'/2, '__bp_priv__resolveAll'/3, '__bp_priv__array_slice'/3, '__bp_priv__string_slice'/3]).

%% behavior String

%% behavior Bool

%% behavior Array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

%%% std/path — pure-botopink path manipulation (posix forward-slash).

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/path.html

%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html

%%% 

%%% Lib-self-contained: every operation composes `String` methods (`split`,

%%% `slice`, `length`, `startsWith`), so the module works on every backend

%%% including wat. Forward-slash separator only — Windows backslash paths

%%% are not normalised here (the spec keeps `path` posix-shaped; a

%%% `path_win32` sibling can land later if a target needs it).

separator() ->
    <<"/">>.

delimiter() ->
    <<":">>.

% Split a path into its non-empty components. Leading-`/` paths drop the

% empty head; trailing-`/` paths drop the empty tail. A path made of pure

% separators yields the empty array. Uses `filter` rather than

% `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store

% (`out ++ [p]` discarded) on Erlang because the immutable runtime never

% rebinds `Out`; `filter` round-trips through `lists:filter/2` and

% `Array.prototype.filter` directly.

split(Path) ->
    Raw = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Path, separator()),
    lists:filter(fun(P) ->
        (P =/= <<"">>)
    end, Raw).

% True when `path` starts with `/` — the posix absolute-path marker.

isAbsolute(Path) ->
    (string:prefix(Path, separator()) =/= nomatch).

% The last non-empty component of `path` (the file name, in the common

% case). Returns "" for the empty path and for pure-separator paths.

basename(Path) ->
    Parts = split(Path),
    N = erlang:length(Parts),
    case (N =:= 0) of
        true ->
            <<"">>;
        _ ->
            case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts, '__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:40:23">>)) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end
    end.

% Everything except the basename — the parent directory portion. For an

% absolute path this preserves the leading `/`. For a path with no

% separator (`"foo"`), returns `""`.

dirname(Path) ->
    Parts = split(Path),
    N = erlang:length(Parts),
    case (N =< 1) of
        true ->
            case isAbsolute(Path) of
                true ->
                    separator();
                false ->
                    <<"">>
            end;
        _ ->
            Head = array_slice(Parts, 0, '__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:50:33">>)),
            Joined = iolist_to_binary(lists:join(separator(), lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Head))),
            % String `+` lowers to numeric `+` on Erlang (badarith on binaries);
            % use a 2-element array `.join("")` to concat instead — that goes
            % through `lists:join("", …)` + `iolist_to_binary` on Erlang and
            % `Array.prototype.join("")` on Node, both string-safe.
            case isAbsolute(Path) of
                true ->
                    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [separator(), Joined])));
                false ->
                    Joined
            end
    end.

% The trailing extension on the basename — the substring from the LAST

% `.` to the end, including the dot. Returns `""` when the basename has

% no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).

extname(Path) ->
    Base = basename(Path),
    Pieces = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Base, <<".">>),
    N = erlang:length(Pieces),
    case (N =< 1) of
        true ->
            <<"">>;
        _ ->
            Head = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, 0) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end,
            Tail = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, '__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:68:28">>)) of
                undefined ->
                    <<"">>;
                __bp_nullish@1 ->
                    __bp_nullish@1
            end,
            % Dotfiles like ".bashrc" split into ["", "bashrc"] — no extension.
            IsDotfile = ((Head =:= <<"">>) andalso (N =:= 2)),
            case IsDotfile of
                true ->
                    <<"">>;
                false ->
                    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<".">>, Tail])))
            end
    end.

% Join a list of path segments with the separator. Leading separator on

% the first segment is preserved; intra-segment slashes are normalised

% (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses

% `map` + `filter` + `join` rather than `fold` / `flatMap`: those land

% on `Array<T>` default-fn bodies that lower to a `var` + `push` shape,

% which lowers to a dead store on Erlang's immutable runtime (the same

% trap `split` sidesteps).

join(Parts) ->
    IsAbs = case (erlang:length(Parts) =:= 0) of
        true ->
            false;
        false ->
            isAbsolute(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts, 0) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end)
    end,
    Collapsed = lists:map(fun(P) ->
        iolist_to_binary(lists:join(separator(), lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, split(P))))
    end, Parts),
    Joined = iolist_to_binary(lists:join(separator(), lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:filter(fun(P) ->
        (P =/= <<"">>)
    end, Collapsed)))),
    case IsAbs of
        true ->
            iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [separator(), Joined])));
        false ->
            Joined
    end.

% Collapse `//` and drop `.` segments via a `filter` over the split

% pieces. Full `..` pop semantics are deferred: they need a stack-shaped

% accumulator and `var` reassignment, which lowers to a dead store on

% Erlang's immutable runtime (the same trap `split`/`join` sidestep with

% `filter`/`flatMap`).

normalize(Path) ->
    case (Path =:= <<"">>) of
        true ->
            <<".">>;
        _ ->
            IsAbs = isAbsolute(Path),
            Pieces = lists:filter(fun(P) ->
                (P =/= <<".">>)
            end, split(Path)),
            Joined = iolist_to_binary(lists:join(separator(), lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Pieces))),
            case IsAbs of
                true ->
                    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [separator(), Joined])));
                false ->
                    case (Joined =:= <<"">>) of
                        true ->
                            <<".">>;
                        false ->
                            Joined
                    end
            end
    end.

% Internal: count how many leading components two split paths share. Tail-

% recursive on `i` so the accumulator never needs a `var` rebind (which

% lowers to a dead store on Erlang's immutable runtime).

commonPrefixCount(A, B, I) ->
    case (I >= erlang:length(A)) of
        true ->
            I;
        _ ->
            case (I >= erlang:length(B)) of
                true ->
                    I;
                _ ->
                    Ai = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(A, I) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end,
                    Bi = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, I) of
                        undefined ->
                            <<"">>;
                        __bp_nullish@1 ->
                            __bp_nullish@1
                    end,
                    case (Ai =:= Bi) of
                        true ->
                            commonPrefixCount(A, B, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/path.bp:114:52">>));
                        false ->
                            I
                    end
            end
    end.

% Internal: build an array of `n` ".." strings via head/tail recursion.

% Avoids a `var` + `push` accumulator (the Erlang dead-store trap).

makeUps(N) ->
    case (N =< 0) of
        true ->
            [];
        false ->
            [<<"..">> | makeUps('__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:120:42">>))]
    end.

% The relative path from `src` to `dst` — the path you would prefix to

% `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`

% fallback — that belongs in `process` once it lands). Returns "." when

% the paths point at the same location.

% 

% `src` is named `src` rather than `from` because `from` is a reserved

% keyword (the `import { … } from "<lib>"` syntax) — it does not parse

% as a parameter name.

relative(Src, Dst) ->
    SrcParts = split(Src),
    DstParts = split(Dst),
    Common = commonPrefixCount(SrcParts, DstParts, 0),
    Ups = makeUps('__bp_int'((erlang:length(SrcParts) - Common), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:135:39">>)),
    Downs = array_slice(DstParts, Common, erlang:length(DstParts)),
    Combined = (Ups ++ Downs),
    Joined = iolist_to_binary(lists:join(separator(), lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Combined))),
    case (Joined =:= <<"">>) of
        true ->
            <<".">>;
        false ->
            Joined
    end.

% Internal accumulator for `resolve`: a list of normalised path parts

% plus whether the resolved-so-far path is absolute. The record carries

% the state through the tail-recursive `resolveAll` so no `var` is

% needed.

%% type PathAccum: isAbs, parts

% Internal: apply each component of one segment (post-split) to the

% accumulator, popping for `..` and appending the rest. Head/tail

% recursive — no `var` rebinds.

applyPieces(Acc, Pieces) ->
    case (erlang:length(Pieces) =:= 0) of
        true ->
            Acc;
        _ ->
            P = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, 0) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end,
            Rest = array_slice(Pieces, 1, erlang:length(Pieces)),
            NextAcc = case (P =:= <<"..">>) of
                true ->
                    case (erlang:length(Acc) =:= 0) of
                        true ->
                            Acc;
                        false ->
                            array_slice(Acc, 0, '__bp_int'((erlang:length(Acc) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:159:63">>))
                    end;
                false ->
                    (Acc ++ [P])
            end,
            applyPieces(NextAcc, Rest)
    end.

resolveStep(State, Seg) ->
    Pieces = split(Seg),
    NextIsAbs = (isAbsolute(Seg) orelse erlang:element(2, State)),
    BaseParts = case isAbsolute(Seg) of
        true ->
            [];
        false ->
            erlang:element(3, State)
    end,
    {std@path@@PathAccum, NextIsAbs, applyPieces(BaseParts, Pieces)}.

resolveAll(Segments, I, State) ->
    case (I >= erlang:length(Segments)) of
        true ->
            State;
        _ ->
            Seg = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Segments, I) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end,
            Next = resolveStep(State, Seg),
            resolveAll(Segments, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/path.bp:175:35">>), Next)
    end.

% Resolve a list of path segments into a single normalised path.

% Absolute segments restart the accumulator (matches Node's

% `path.resolve`); `..` pops one component; `.` drops out (already

% filtered by `split`). The empty input resolves to ".".

resolve(Segments) ->
    FinalState = resolveAll(Segments, 0, {std@path@@PathAccum, false, []}),
    Joined = iolist_to_binary(lists:join(separator(), lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, erlang:element(3, FinalState)))),
    case erlang:element(2, FinalState) of
        true ->
            iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [separator(), Joined])));
        false ->
            case (Joined =:= <<"">>) of
                true ->
                    <<".">>;
                false ->
                    Joined
            end
    end.

% ── 1.0.10-beta front 01 additions ───────────────────────────────────────────

% `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`

% → `archive.tar`, `noext` → `noext`. The extension is what `extname`

% answers, so a dotfile keeps its name.

withoutExtension(P) ->
    Ext = extname(P),
    N = erlang:length(unicode:characters_to_list(P)),
    Stem = case (Ext =:= <<"">>) of
        true ->
            P;
        false ->
            string_slice(P, 0, '__bp_int'((N - erlang:length(unicode:characters_to_list(Ext))), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:205:51">>))
    end,
    Stem.

% True when `child` resolves inside `parent` — the traversal guard front 22

% applies before it turns a request path into a file path. Both sides go

% through `resolve`, which pops `..` (`normalize` does not), and a relative

% `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is

% true and `isInside("/app", "blog/../../etc")` is false. A parent is inside

% itself. The check reads the first component of the relative path: `..`

% exactly, or `../…` — a component that merely starts with two dots

% (`..foo`) is a name, not an escape.

isInside(Parent, Child) ->
    Up = resolve([Parent]),
    Down = resolve([Parent, Child]),
    Rel = relative(Up, Down),
    Escapes = ((Rel =:= <<"..">>) orelse (string:prefix(Rel, <<"../">>) =/= nomatch)),
    (Escapes =:= false).

% ── tests ────────────────────────────────────────────────────────────────────


















array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__commonPrefixCount'(A0, A1, A2) -> commonPrefixCount(A0, A1, A2).

'__bp_priv__makeUps'(A0) -> makeUps(A0).

'__bp_priv__applyPieces'(A0, A1) -> applyPieces(A0, A1).

'__bp_priv__resolveStep'(A0, A1) -> resolveStep(A0, A1).

'__bp_priv__resolveAll'(A0, A1, A2) -> resolveAll(A0, A1, A2).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
```

----- ERLANG -- std@path@@PathAccum.erl
```erlang
-module(std@path@@PathAccum).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, isAbs) -> erlang:element(2, V);
'__bp_get'(V, parts) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "PathAccum", [{"isAbs", erlang:element(2, V)}, {"parts", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/io/fs.bp
```botopink
//// std/io/fs — the file system, cross-backend (decision 540).
////
//// Reference:
////   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,
////              `File`, `io::ErrorKind`)
////   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html
////   Erlang   — https://www.erlang.org/doc/man/file.html
////   Node.js  — https://nodejs.org/api/fs.html
////
//// Every function that can fail answers `@Result<…, FsError>`: the same OS error is
//// the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
//// and `Other.message` is the host's own text. The whole-file shortcuts
//// (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
//// the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
//// `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
//// and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
////
//// The host cells (`raw…`) answer `@Result<R, string>` whose error is
//// `<kind>|<host text>` — `kind` one of `notfound`, `denied`, `isdir`, `notdir`,
//// `exists`, `other` (or `dangling`, a `walk`'s own) — and `lift` turns it into the
//// `FsError` of the path the caller wrote. All operations are synchronous
//// (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here
//// (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).

import {path.relative};

// The error of every `io.fs` function (decision 540). `path` is the path the
// caller wrote (for `copy`, the source; for `walk`, the root).
pub type FsError {
    NotFound(path: string),
    PermissionDenied(path: string),
    IsDirectory(path: string),
    NotDirectory(path: string),
    AlreadyExists(path: string),
    // `readText` / `text` / `lines` on bytes that are not UTF-8: `offset` is
    // the byte, in what was read, where the first invalid sequence starts.
    InvalidUtf8(path: string, offset: i64),
    // Any other host error; `message` is the host's text.
    Other(path: string, message: string),

    // The error's text (decision 563): `<what>: <path>`, the same on every target.
    pub fn message(self: Self) -> string {
        return case self {
            NotFound(path: path) -> "not found: " + path;
            PermissionDenied(path: path) -> "permission denied: " + path;
            IsDirectory(path: path) -> "is a directory: " + path;
            NotDirectory(path: path) -> "not a directory: " + path;
            AlreadyExists(path: path) -> "already exists: " + path;
            InvalidUtf8(path: path, offset: offset) -> "not UTF-8: "
                + path
                + " at byte "
                + offset.toString();
            Other(path: path, message: message) -> path + ": " + message;
        };
    }
}

pub type FileStat(
    size: i64,
    mtime: i64,
    isDir: bool,
)

// Read the whole file as bytes.
// Node: `readFileSync($0)` copied into a plain `Uint8Array`.
// Erlang: `file:read_file/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { return { ok: new Uint8Array(require('fs').readFileSync($0)) } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawReadBytes(path: string) -> @Result<Bytes, string>;

// Write `contents` to `path`, creating or truncating.
// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').writeFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawWriteBytes(path: string, contents: Bytes) -> @Result<i32, string>;

// Append `contents` to `path`, creating it when it is not there.
// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').appendFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawAppendText(path: string, contents: string) -> @Result<i32, string>;

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
// or -1 when every byte is part of a valid sequence — the same offset on every target.
// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
#[@External.Node("""((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })($0)""")]
#[@External.Erlang("""(fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)($0)""")]
declare fn utf8Offset(bytes: Bytes) -> i64;

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.
// Node: `subarray`. Erlang: `binary:part/3`.
#[@External.Node("""((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })($0)""")]
#[@External.Erlang("""(fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)($0)""")]
declare fn stripEol(line: Bytes) -> Bytes;

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
// (Node opens one; the template refuses it). The handle is host-owned and opaque: a
// `{ fd, mem, pos, buf }` object on Node, the raw file descriptor on Erlang.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = $0; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); return { error: 'isdir|EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p) } } return { ok: { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:open(__P, [read, binary, raw, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawOpen(path: string) -> @Result<unknown, string>;

// The handle of the file at `path`, open for writing: created, or truncated.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fd = require('fs').openSync($0, 'w'); return { ok: { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawCreate(path: string) -> @Result<unknown, string>;

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field
// on Node and a `counters` cell on Erlang.
#[@External.Node("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })""")]
#[@External.Erlang("""{mem, $0, counters:new(1, [])}""")]
declare fn memHandle(bytes: Bytes) -> unknown;

// The size of the file behind `handle`, in bytes. Erlang's raw descriptor has no `fstat`, so it reads `path`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = $0; return { ok: __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H, __P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __Ek(__R)} end end end)($0, $1)""")]
declare fn rawSize(handle: unknown, path: string) -> @Result<i64, string>;

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = $0; const __n = $1; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return { ok: __o } } return { ok: new Uint8Array(__more(__h, __n)) } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H, __N) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __Ek(__R)} end end end)($0, $1)""")]
declare fn rawRead(handle: unknown, n: i32) -> @Result<Bytes, string>;

// Every byte from the handle's position to the end.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = $0; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return { ok: __o } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __Ek(__R)} end end)([]) end end)($0)""")]
declare fn rawReadAll(handle: unknown) -> @Result<Bytes, string>;

// The next line, terminator included; empty at the end.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; try { const __h = $0; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return { ok: __l } } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return { ok: __l } } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __Ek(__R)} end end end)($0)""")]
declare fn rawReadLine(handle: unknown) -> @Result<Bytes, string>;

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
// whatever the position, which it leaves where it was.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = $0; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return { ok: __hs.digest('hex') } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> throw({bp_fs_hash, __R}) end end, try {ok, string:lowercase(binary:encode_hex(__L(0, crypto:hash_init(sha256))))} catch throw:{bp_fs_hash, __Y} -> {error, __Ek(__Y)} end end end)($0)""")]
declare fn rawHash(handle: unknown) -> @Result<string, string>;

// Write `bytes` at the handle's position; answers how many.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __h = $0; const __b = $1; if (__h.mem) return { error: 'other|the file is open for reading' }; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return { ok: __b.length } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__H, __B) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, _, _} -> {error, <<"other|the file is open for reading">>}; _ -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __Ek(__R)} end end end)($0, $1)""")]
declare fn rawWrite(handle: unknown, bytes: Bytes) -> @Result<i32, string>;

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
#[@External.Node("""(() => { try { const __h = $0; if (!__h.mem) require('fs').closeSync(__h.fd) } catch (__e) {} })()""")]
#[@External.Erlang("""(fun(__H) -> case __H of {mem, _, _} -> ok; _ -> _ = file:close(__H), ok end end)($0)""")]
declare fn rawClose(handle: unknown) -> void;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').writeFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawWriteText(
    path: string,
    contents: string,
) -> @Result<i32, string>;

// Whether a path exists, of any kind: a regular file, a directory, a
// character or block device (`/dev/null`), a FIFO or a socket. A symbolic
// link is followed — one whose target is missing is `false`, the answer
// every read through it would give.
// Node: `require('fs').existsSync($0)` (a `stat`).
// Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
// replaces, answers only regular files and directories, so `/dev/null`
// was `false` on erlang and `true` on commonJS).
#[@External.Node("""require('fs').existsSync($0)""")]
#[@External.Erlang("""(case file:read_file_info($0) of {ok, _} -> true; _ -> false end)""")]
pub declare fn exists(path: string) -> bool;

// List the names of the directory entries at `path` (relative).
// Node: `require('fs').readdirSync($0)`.
// Erlang: `file:list_dir/1` returns `{ok, [string()]}`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { return { ok: require('fs').readdirSync($0) } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawList(path: string) -> @Result<string[], string>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents.
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').mkdirSync($0); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawMkdir(path: string) -> @Result<i32, string>;

// Create the directory at `path` and every missing directory above it. A
// directory that is already there is `Ok` too; a path that exists as anything
// else (a file) is an `Error`. What the snapshot library (`snap`) makes the
// directory of a `.snap` with (decision 391).
// Node: `require('fs').mkdirSync($0, { recursive: true })`.
// Erlang: `filelib:ensure_path/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').mkdirSync($0, { recursive: true }); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawMkdirRecursive(path: string) -> @Result<i32, string>;

// Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
// both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
// a `read_link_info`, so the variant is the same); `removeTree` removes one.
// Node: `require('fs').rmSync($0)`.
// Erlang: `file:delete/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').rmSync($0); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, __Ek(eisdir)}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end end)($0)""")]
declare fn rawRm(path: string) -> @Result<i32, string>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').copyFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__S, __D) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0, $1)""")]
declare fn rawCopy(src: string, dest: string) -> @Result<i32, string>;

// File metadata. Returns a `FileStat { size, mtime, isDir }` on
// success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
// `size` is in bytes.
// Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
// `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
// seconds, × 1000, and both answer decision 319's canonical form (a `number`
// within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
// Erlang: `file:read_file_info/1` returns a `#file_info` record; the
// template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
// whole seconds × 1000. One value on every target: whole seconds (decision 499).
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __s = require('fs').statSync($0, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { ok: { size: __c(__s.size), mtime: __c(((__ns - (((__ns % 1000000000n) + 1000000000n) % 1000000000n)) / 1000000000n) * 1000n), isDir: __s.isDirectory() } } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawStat(path: string) -> @Result<FileStat, string>;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

// Every REGULAR FILE under `root`, recursively, as paths relative to `root`
// with `/` separators, sorted — the same set on both targets (the two hosts
// walk in different orders, so the list is sorted rather than left as found),
// and the same paths however the root is spelled: `dir`, `dir/`, `dir/.`,
// `./dir`, `dir/sub/..`, absolute or relative to the working directory.
// Directories are not listed; a link is followed (a link to a file is listed
// under its own name, a link to a directory is walked). An `Error`: a missing
// or non-directory `root`, a directory under it that cannot be read, and a
// DANGLING link (decision 178) — `fs.walk: dangling link "<relative path>"`,
// the same text on both targets, naming the first one in sorted order.
// Node: `readdirSync(root, { recursive: true })` answers files AND directories
// relative to `root`; the template sorts them, keeps the entries `statSync`
// says are files, and answers the dangling-link `Error` for the first entry
// `statSync` cannot find (`throwIfNoEntry: false`).
// Erlang: the template walks `file:list_dir/1` itself and BUILDS each relative
// path from the names it descended through. It never cuts a prefix off a full
// path: `filelib:fold_files/5` answers full paths `filename:join/2` has
// normalised (`dir/.` + `app` is `dir/app`), so a prefix measured on the root
// as written cut two characters too many when the root ended in `/.`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync($0, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join($0, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'dangling|fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__R) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, __Ek(case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end)}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"dangling|fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, __Ek(__Y)} end end end)($0)""")]
declare fn rawWalk(root: string) -> @Result<string[], string>;

// The entries under `root` matching the glob `pattern`, as paths relative to
// `root` with `/` separators, sorted, each once. The pattern is read segment
// by segment, by ONE rule on both targets (decision 177 — the narrower of what
// the two hosts did):
//   - `**` is zero or more directories; a segment with `*`, `?`, `[…]` or
//     `{a,b}` matches the names of one directory; any other segment is a name.
//   - `*` and `**` (and `?`, `[…]`, `{…}`) do NOT match a name that starts
//     with `.` — a segment matches one only when the segment itself starts
//     with the dot (`.*`, `.config/*.json`).
//   - the walk does NOT descend through a link to a directory: `**` and a
//     wildcard segment continue into real directories only. The link is still
//     a NAME — `*` lists it — and a segment that names it (`linked/*.bp`) goes
//     through it, because the pattern wrote it.
//   - the last segment matches an entry of any kind (file, directory, link,
//     dangling or not); a final `**` is every entry at every depth; a trailing
//     `/` keeps real directories only.
// An alternative of `{a,b}` cannot hold a `/` (the pattern is split first). A
// root that does not exist answers `Ok([])`; so does a directory that cannot
// be read. Both cells are the same walk; only the match of ONE segment against
// ONE directory is the host's — `fs.globSync(segment, { cwd })` (Node 22+),
// `filelib:wildcard/2` — with the dot rule applied over its answer, since
// `filelib:wildcard` matches dot names and `globSync` matches `{.a,b}`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { const __fs = require('fs'); const __p = require('path'); const __root = $1; const __pat = String($0); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return { ok: Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, {ok, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))]} end)($0, $1)""")]
declare fn rawGlob(pattern: string, root: string) -> @Result<string[], string>;

// Remove `path` and everything under it: a file, a link (the link, never its
// target) or a directory tree. A path that is not there is `Ok` too — the
// caller wanted it gone. What a test fixture is cleared with, and what the
// snapshot engine's tests clear their scratch directories with (1.0.11-beta
// front 97).
// Node: `rmSync(path, { recursive: true, force: true })`.
// Erlang: `file:del_dir_r/1`.
#[@External.Node("""(() => { const __ek = (__e) => { const __c = __e && __e.code; const __t = __c === 'ENOENT' ? 'notfound' : (__c === 'EACCES' || __c === 'EPERM') ? 'denied' : (__c === 'EISDIR' || __c === 'ERR_FS_EISDIR') ? 'isdir' : __c === 'ENOTDIR' ? 'notdir' : __c === 'EEXIST' ? 'exists' : 'other'; return __t + '|' + (__e && __e.message ? __e.message : String(__e)) }; try { require('fs').rmSync($0, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __ek(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)($0)""")]
declare fn rawRemoveTree(path: string) -> @Result<i32, string>;

// Internal, test scaffolding: a fresh, unique, empty directory under the
// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
// one of these and removes it with `removeTree`, so a run leaves nothing under
// the host's tmpdir.
#[@External.Node("""require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'))""")]
#[@External.Erlang("""(fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)()""")]
declare fn scratchDir() -> string;

// Internal, test scaffolding: the working directory (what a relative root is
// read against) and a symbolic link `link` → `target`.
#[@External.Node("process.cwd()")]
#[@External.Erlang("""(fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)()""")]
declare fn workingDir() -> string;

#[@External.Node("""require('fs').symlinkSync($0, $1)""")]
#[@External.Erlang("""(fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)($0, $1)""")]
declare fn linkTo(target: string, link: string) -> void;

// ── the typed error ──────────────────────────────────────────────────────────

// `<kind>|<host text>` → the `FsError` of `path`.
fn fsError(path: string, raw: string) -> FsError {
    val bar = raw.indexOf("|");
    val kind = raw.slice(0, bar);
    val message = raw.slice(bar + 1);
    if (kind == "notfound") return FsError.NotFound(path: path);
    if (kind == "denied") return FsError.PermissionDenied(path: path);
    if (kind == "isdir") return FsError.IsDirectory(path: path);
    if (kind == "notdir") return FsError.NotDirectory(path: path);
    if (kind == "exists") return FsError.AlreadyExists(path: path);
    return FsError.Other(path: path, message: message);
}

// A host cell's answer, its error read as an `FsError` of `path`.
fn lift<T>(path: string, r: @Result<T, string>) -> @Result<T, FsError> {
    case r {
        Ok(v) -> return v;
        Error(m) -> throw fsError(path, m);
    }
}

// The text of `b`, or `InvalidUtf8` at the first invalid byte.
fn decode(path: string, b: Bytes) -> @Result<string, FsError> {
    val offset = utf8Offset(b);
    if (offset >= 0l) throw FsError.InvalidUtf8(path: path, offset: offset);
    return b.toUtf8().unwrapOr("");
}

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.
pub fn readBytes(path: string) -> @Result<Bytes, FsError> {
    val b = try lift(path, rawReadBytes(path));
    return b;
}

// The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
// target — never node's silent U+FFFD nor erlang's unchecked binary.
pub fn readText(path: string) -> @Result<string, FsError> {
    val b = try readBytes(path);
    val s = try decode(path, b);
    return s;
}

// Write `contents` to `path`, creating or truncating.
pub fn writeBytes(path: string, contents: Bytes) -> @Result<i32, FsError> {
    val n = try lift(path, rawWriteBytes(path, contents));
    return n;
}

pub fn writeText(path: string, contents: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawWriteText(path, contents));
    return n;
}

// Append `contents`, creating the file when it is not there.
pub fn appendText(path: string, contents: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawAppendText(path, contents));
    return n;
}

// ── metadata and directories ─────────────────────────────────────────────────

pub fn stat(path: string) -> @Result<FileStat, FsError> {
    val s = try lift(path, rawStat(path));
    return s;
}

pub fn list(path: string) -> @Result<string[], FsError> {
    val names = try lift(path, rawList(path));
    return names;
}

pub fn mkdir(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawMkdir(path));
    return n;
}

pub fn mkdirRecursive(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawMkdirRecursive(path));
    return n;
}

pub fn rm(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawRm(path));
    return n;
}

pub fn removeTree(path: string) -> @Result<i32, FsError> {
    val n = try lift(path, rawRemoveTree(path));
    return n;
}

pub fn copy(src: string, dest: string) -> @Result<i32, FsError> {
    val n = try lift(src, rawCopy(src, dest));
    return n;
}

pub fn walk(root: string) -> @Result<string[], FsError> {
    val paths = try lift(root, rawWalk(root));
    return paths;
}

pub fn glob(pattern: string, root: string) -> @Result<string[], FsError> {
    val paths = try lift(root, rawGlob(pattern, root));
    return paths;
}

// The host's handle over embedded bytes: read like a file, never closed on disk.
#[@External.Node("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })""")]
#[@External.Erlang("""{mem, $0, counters:new(1, [])}""")]
declare fn memoryHandle(bytes: Bytes) -> unknown;

// ── the handle ───────────────────────────────────────────────────────────────

// An open file (decision 540 (3)). `location` is the path it was opened with and
// `handle` the host's — opaque, never read by a program. Closed by the writer:
// `val f = try fs.open(p); defer f.close();`.
pub type File(location: string, handle: unknown) implement Closeable {
    // The path the file was opened with.
    pub fn path(self: Self) -> string {
        return self.location;
    }

    // The file's size in bytes.
    pub fn size(self: Self) -> @Result<i64, FsError> {
        val n = try lift(self.location, rawSize(self.handle, self.location));
        return n;
    }

    // Up to `n` bytes from the position; empty at the end of the file.
    pub fn read(self: Self, n: i32) -> @Result<Bytes, FsError> {
        if (n <= 0) return Bytes.fromUtf8("");
        val b = try lift(self.location, rawRead(self.handle, n));
        return b;
    }

    // Every byte from the position to the end.
    pub fn bytes(self: Self) -> @Result<Bytes, FsError> {
        val b = try lift(self.location, rawReadAll(self.handle));
        return b;
    }

    // The rest of the file as UTF-8 text (`InvalidUtf8` otherwise).
    pub fn text(self: Self) -> @Result<string, FsError> {
        val b = try self.bytes();
        val s = try decode(self.location, b);
        return s;
    }

    // The rest of the file in pieces of at most `size` bytes. An error ends the stream.
    pub fn chunks(self: Self, size: i32 = 65536) -> @Stream<@Result<Bytes, FsError>> {
        while (true) {
            val b = try self.read(size);
            if (b.length == 0) break;
            yield b;
        }
    }

    // The rest of the file line by line, `\n` and `\r\n` stripped. A line that is not
    // UTF-8 ends the stream with `InvalidUtf8`, its offset counted from the first
    // line this call read.
    pub fn lines(self: Self) -> @Stream<@Result<string, FsError>> {
        var consumed = 0l;
        while (true) {
            val raw = try lift(self.location, rawReadLine(self.handle));
            if (raw.length == 0) break;
            val line = stripEol(raw);
            val offset = utf8Offset(line);
            if (offset >= 0l)
                throw FsError.InvalidUtf8(path: self.location, offset: consumed
                    + offset);
            val width: i32 = raw.length;
            consumed = consumed + width.toI64();
            yield line.toUtf8().unwrapOr("");
        }
    }

    // The SHA-256 of the whole file, lowercase hex.
    pub fn hash(self: Self) -> @Result<string, FsError> {
        val h = try lift(self.location, rawHash(self.handle));
        return h;
    }

    // Write `b` at the position; answers the number of bytes written.
    pub fn write(self: Self, b: Bytes) -> @Result<i32, FsError> {
        val n = try lift(self.location, rawWrite(self.handle, b));
        return n;
    }

    // Close the file. Closing twice is harmless; a failure to close is not reported.
    pub fn close(self: Self) {
        rawClose(self.handle);
    }
}

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.
pub fn open(path: string) -> @Result<File, FsError> {
    val h = try lift(path, rawOpen(path));
    return File(location: path, handle: h);
}

// Open the file at `path` for writing: created, or truncated.
pub fn create(path: string) -> @Result<File, FsError> {
    val h = try lift(path, rawCreate(path));
    return File(location: path, handle: h);
}

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
// like a file on disk — no `@Result`, the build proved the file exists — and
// closing it is a no-op.
pub fn openAsset(asset: Asset) -> File {
    return File(location: asset.path, handle: memoryHandle(asset.bytes));
}

// ── tests ────────────────────────────────────────────────────────────────────
// (Inline tests are smoke-grade — they require the host filesystem to be
// writable at the host's `tmpdir()`. The lib-test harness runs each
// inline test as a separate process; the temp filenames are seeded with
// `time.nowMillis()` for cross-run uniqueness.)

test "fs.exists is false for a fixed-name path that doesn't exist" {
    val e = exists("/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert e.negate();
}

test "fs.exists is true for a path of any kind" {
    assert exists("/");
    assert exists("/dev/null");
    val dir = scratchDir();
    writeText([dir, "/file.txt"].join(""), "x");
    assert exists([dir, "/file.txt"].join(""));
    assert exists(dir);
    removeTree(dir);
    assert exists(dir).negate();
}

test "fs.removeTree removes a tree, a file and a link, and a missing path is Ok" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("blog", [dir, "/app/linked"].join(""));
    assert removeTree([dir, "/app/linked"].join("")).isOk();
    assert exists([dir, "/app/linked"].join("")).negate();
    assert exists([dir, "/app/blog/page.bp"].join(""));
    assert removeTree([dir, "/app/page.bp"].join("")).isOk();
    assert exists([dir, "/app/page.bp"].join("")).negate();
    assert removeTree([dir, "/app"].join("")).isOk();
    assert exists([dir, "/app"].join("")).negate();
    assert removeTree([dir, "/app"].join("")).isOk();
    assert removeTree(dir).isOk();
    assert exists(dir).negate();
}

test "fs.mkdirRecursive makes a directory with its parents and is Ok on one that is there" {
    val dir = scratchDir();
    val deep = [dir, "/a/b/c"].join("");
    assert mkdirRecursive(deep).isOk();
    assert stat(deep).unwrapOr(
        FileStat(size: 0l, mtime: 0l, isDir: false),
    ).isDir;
    assert mkdirRecursive(deep).isOk();
    writeText([dir, "/file.txt"].join(""), "x");
    assert mkdirRecursive([dir, "/file.txt"].join("")).isError();
    assert mkdirRecursive([dir, "/file.txt/sub"].join("")).isError();
    removeTree(dir);
}

test "fs.list of the host '/' resolves Ok" {
    val r = list("/");
    assert r.isOk();
}

// Internal, test scaffolding: `stat(p)`, or a stat no file has.
fn statOr(p: string) -> FileStat {
    return case stat(p) {
        Ok(s) -> s;
        Error(_) -> FileStat(size: -1l, mtime: -1l, isDir: false);
    };
}

test "fs.stat answers a file's size, a directory's kind and the mtime in epoch milliseconds" {
    val dir = scratchDir();
    writeText([dir, "/five.txt"].join(""), "12345");
    val file = statOr([dir, "/five.txt"].join(""));
    assert file.size == 5l;
    assert file.isDir == false;
    // After 2020-01-01T00:00:00Z and before 2100-01-01T00:00:00Z.
    assert file.mtime > 1577836800000l;
    assert file.mtime < 4102444800000l;
    // Whole seconds on every target (decision 499).
    assert file.mtime % 1000l == 0l;
    assert statOr(dir).isDir;
    assert stat([dir, "/missing.txt"].join("")).isError();
    removeTree(dir);
}

// Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
// `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.
fn makeFixtureTree(dir: string) -> void {
    mkdir([dir, "/app"].join(""));
    mkdir([dir, "/app/blog"].join(""));
    writeText([dir, "/app/page.bp"].join(""), "root page");
    writeText([dir, "/app/blog/page.bp"].join(""), "blog page");
    writeText([dir, "/app/blog/notes.md"].join(""), "notes");
}

// Internal, test scaffolding: what `walk` answers for the fixture tree when
// its root is spelled `<scratch dir><suffix>` — every spelling of one root has
// to answer the same three relative paths.
fn walkFixture(suffix: string) -> string {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val walked = walk([dir, suffix].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    return walked.join(",");
}

// Internal, test scaffolding: the same, with the root spelled relative to the
// working directory — `<prefix><path from the cwd to the fixture>`.
fn walkFixtureFromCwd(prefix: string) -> string {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val root = [prefix, relative(workingDir(), dir), "/app"].join("");
    val walked = walk(root).unwrapOr(["<error>"]);
    removeTree(dir);
    return walked.join(",");
}

test "fs.walk lists every regular file relative to the root, sorted" {
    assert walkFixture("/app") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a trailing slash answers the same paths" {
    assert walkFixture("/app/") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root ending in a dot segment answers the same paths" {
    assert walkFixture("/app/.") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a dot segment inside answers the same paths" {
    assert walkFixture("/./app") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a doubled separator answers the same paths" {
    assert walkFixture("//app//") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root ending in a parent segment answers the same paths" {
    assert walkFixture("/app/blog/..") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a relative root answers the same paths" {
    assert walkFixtureFromCwd("") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a relative root spelled with a leading dot answers the same paths" {
    assert walkFixtureFromCwd("./") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk follows a link to a file and a link to a directory" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("blog", [dir, "/app/linked"].join(""));
    linkTo("page.bp", [dir, "/app/alias.bp"].join(""));
    val walked = walk([dir, "/app"].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    assert walked.join(",")
        == "alias.bp,blog/notes.md,blog/page.bp,linked/notes.md,linked/page.bp,page.bp";
}

// Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.
fn walkRefusal(root: string) -> string {
    return case walk(root) {
        Ok(_) -> "";
        Error(e) -> describe(e);
    };
}

// Internal, test scaffolding: an `FsError` as one line — the variant, the path
// and the message where it holds one (a dangling link is `Other`, decision 178).
fn describe(e: FsError) -> string {
    return case e {
        FsError.NotFound(p) -> "NotFound " + p;
        FsError.PermissionDenied(p) -> "PermissionDenied " + p;
        FsError.IsDirectory(p) -> "IsDirectory " + p;
        FsError.NotDirectory(p) -> "NotDirectory " + p;
        FsError.AlreadyExists(p) -> "AlreadyExists " + p;
        FsError.InvalidUtf8(p, offset) -> "InvalidUtf8 "
            + p
            + " "
            + offset.toString();
        FsError.Other(p, message) -> message;
    };
}

test "fs.walk of a tree with a dangling link is an Error naming the link" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("missing.bp", [dir, "/app/gone.bp"].join(""));
    val refusal = walkRefusal([dir, "/app"].join(""));
    val dotted = walkRefusal([dir, "/app/."].join(""));
    removeTree(dir);
    assert refusal == "fs.walk: dangling link \"gone.bp\"";
    assert dotted == "fs.walk: dangling link \"gone.bp\"";
}

test "fs.walk names the first dangling link in sorted order, by its relative path" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("missing.bp", [dir, "/app/zz-gone.bp"].join(""));
    linkTo("missing.md", [dir, "/app/blog/gone.md"].join(""));
    val refusal = walkRefusal([dir, "/app"].join(""));
    removeTree(dir);
    assert refusal == "fs.walk: dangling link \"blog/gone.md\"";
}

test "fs.walk of a regular file is an Error" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val r = walk([dir, "/app/page.bp"].join(""));
    removeTree(dir);
    assert r.isError();
}

test "fs.walk of a missing root is an Error" {
    val r = walk("/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert r.isError();
}

test "fs.glob finds a nested file through a double-star pattern" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val found = glob("**/page.bp", [dir, "/app"].join("")).unwrapOr([]);
    removeTree(dir);
    assert found.join(",") == "blog/page.bp,page.bp";
}

test "fs.glob answers the empty list when nothing matches" {
    val dir = scratchDir();
    val found = glob("*.nothing", dir).unwrapOr(["x"]);
    removeTree(dir);
    assert found.length == 0;
}

// Internal, test scaffolding: the fixture tree plus the names decision 177 is
// about — a dot file and a dot directory, a link to a directory, a link to a
// file and a dangling link, all under `<dir>/app`.
fn makeGlobTree(dir: string) -> void {
    makeFixtureTree(dir);
    mkdir([dir, "/app/.cache"].join(""));
    writeText([dir, "/app/.cache/page.bp"].join(""), "cached");
    writeText([dir, "/app/.hidden.bp"].join(""), "hidden");
    writeText([dir, "/app/blog/.draft.md"].join(""), "draft");
    linkTo("blog", [dir, "/app/linked"].join(""));
    linkTo("page.bp", [dir, "/app/alias.bp"].join(""));
    linkTo("missing.bp", [dir, "/app/gone.bp"].join(""));
}

// Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
// `makeGlobTree`, joined by `,`.
fn globbed(pattern: string) -> string {
    val dir = scratchDir();
    makeGlobTree(dir);
    val found = glob(pattern, [dir, "/app"].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    return found.join(",");
}

test "fs.glob star matches every name but one that starts with a dot" {
    assert globbed("*") == "alias.bp,blog,gone.bp,linked,page.bp";
    assert globbed("*.bp") == "alias.bp,gone.bp,page.bp";
    assert globbed("blog/*") == "blog/notes.md,blog/page.bp";
}

test "fs.glob matches a dot name only when the segment writes the dot" {
    assert globbed(".*") == ".cache,.hidden.bp";
    assert globbed(".hidden.bp") == ".hidden.bp";
    assert globbed(".cache/*.bp") == ".cache/page.bp";
    assert globbed("blog/.*") == "blog/.draft.md";
    assert globbed("?hidden.bp") == "";
    assert globbed("[.]hidden.bp") == "";
    assert globbed("{.hidden,page}.bp") == "page.bp";
}

test "fs.glob double star does not enter a directory that starts with a dot" {
    assert globbed("**/page.bp") == "blog/page.bp,page.bp";
    assert globbed("**/*.md") == "blog/notes.md";
    assert globbed("**/.*") == ".cache,.hidden.bp,blog/.draft.md";
    assert globbed(".cache/**/*.bp") == ".cache/page.bp";
}

test "fs.glob does not descend through a link to a directory" {
    assert globbed("**/notes.md") == "blog/notes.md";
    assert globbed("*/notes.md") == "blog/notes.md";
    assert globbed("l*/notes.md") == "";
    assert globbed("**/*/notes.md") == "blog/notes.md";
}

test "fs.glob goes through a link the pattern names, and lists a link as a name" {
    assert globbed("linked/*.md") == "linked/notes.md";
    assert globbed("linked/**/*.bp") == "linked/page.bp";
    assert globbed("**/linked/*.md") == "linked/notes.md";
    assert globbed("linked") == "linked";
    assert globbed("l*") == "linked";
    assert globbed("gone.bp") == "gone.bp";
}

test "fs.glob final double star is every entry at every depth" {
    assert globbed("**")
        == "alias.bp,blog,blog/notes.md,blog/page.bp,gone.bp,linked,page.bp";
    assert globbed("blog/**") == "blog/notes.md,blog/page.bp";
}

test "fs.glob reads the classes, the alternatives and a trailing slash" {
    assert globbed("blo?/[np]*.md") == "blog/notes.md";
    assert globbed("{blog,nowhere}/page.bp") == "blog/page.bp";
    assert globbed("**/{notes,page}.*") == "blog/notes.md,blog/page.bp,page.bp";
    assert globbed("*/") == "blog";
    assert globbed("./blog//page.bp") == "blog/page.bp";
}

test "fs.glob of a root that does not exist answers the empty list" {
    val found = glob("**/*", "/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert found.unwrapOr(["x"]).length == 0;
}

// ── FsError, readText and the handle ─────────────────────────────────────────

// Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.
fn variantOf<T>(r: @Result<T, FsError>) -> string {
    return case r {
        Ok(_) -> "ok";
        Error(e) -> describe(e);
    };
}

test "fs answers the same FsError variant for the same OS error" {
    val dir = scratchDir();
    writeText([dir, "/file.txt"].join(""), "x");
    val missing = [dir, "/missing"].join("");
    val file = [dir, "/file.txt"].join("");
    assert variantOf(readText(missing)) == "NotFound " + missing;
    assert variantOf(readText(dir)) == "IsDirectory " + dir;
    assert variantOf(list(file)) == "NotDirectory " + file;
    assert variantOf(mkdir(dir)) == "AlreadyExists " + dir;
    assert variantOf(mkdir([dir, "/a/b"].join("")))
        == "NotFound " + [dir, "/a/b"].join("");
    assert variantOf(rm(dir)) == "IsDirectory " + dir;
    assert variantOf(open(missing)) == "NotFound " + missing;
    assert variantOf(open(dir)) == "IsDirectory " + dir;
    assert variantOf(create(dir)) == "IsDirectory " + dir;
    removeTree(dir);
}

test "fs.readText of bytes that are not UTF-8 is InvalidUtf8 at the first invalid byte" {
    val dir = scratchDir();
    val path = [dir, "/bad.bin"].join("");
    // "ok", then the first byte of a two-byte sequence, then "z".
    writeBytes(path, Bytes
        .fromUtf8("ok")
        .concat(Bytes.fromUtf8("é").slice(0, 1))
        .concat(Bytes.fromUtf8("z")));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 2";
    assert readBytes(path).isOk();
    // A sequence cut short at the end of the file.
    writeBytes(path, Bytes.fromUtf8("é").slice(0, 1));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 0";
    // A well-formed multi-byte file reads back whole.
    writeText(path, "héllo ✓");
    assert readText(path).unwrapOr("") == "héllo ✓";
    removeTree(dir);
}

test "fs.appendText adds to the end and creates the file" {
    val dir = scratchDir();
    val path = [dir, "/log.txt"].join("");
    appendText(path, "a");
    appendText(path, "b");
    assert readText(path).unwrapOr("") == "ab";
    removeTree(dir);
}

// Internal, test scaffolding: the file a failed `open` falls back to.
fn noFile() -> File {
    return File(location: "", handle: memHandle(Bytes.fromUtf8("")));
}

test "fs.File writes, then reads bytes, text, a size and a hash" {
    val dir = scratchDir();
    val path = [dir, "/data.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(Bytes.fromUtf8("hello ")).unwrapOr(-1) == 6;
    assert w.write(Bytes.fromUtf8("world")).unwrapOr(-1) == 5;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.path() == path;
    assert r.size().unwrapOr(-1l) == 11l;
    assert r.read(5).unwrapOr(Bytes.fromUtf8("")).toUtf8().unwrapOr("")
        == "hello";
    assert r.text().unwrapOr("") == " world";
    assert r.read(5).unwrapOr(Bytes.fromUtf8("x")).length == 0;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
    r.close();
    removeTree(dir);
}

// Internal, test scaffolding: take every permission from `path`; whether that
// denies this user anything (root is denied nothing), and give them back.
#[@External.Node("""(() => { require('fs').chmodSync($0, 0); return typeof process.getuid === 'function' ? process.getuid() !== 0 : false })()""")]
#[@External.Erlang("""(fun(__P) -> ok = file:change_mode(__P, 0), string:trim(os:cmd("id -u")) =/= "0" end)($0)""")]
declare fn denyAll(path: string) -> bool;

#[@External.Node("""require('fs').chmodSync($0, 0o700)""")]
#[@External.Erlang("""(fun(__P) -> ok = file:change_mode(__P, 8#700), ok end)($0)""")]
declare fn allowAll(path: string) -> void;

test "fs answers PermissionDenied for an OS permission error" {
    val dir = scratchDir();
    val locked = [dir, "/locked"].join("");
    mkdir(locked);
    writeText([locked, "/f.txt"].join(""), "x");
    val denied = denyAll(locked);
    val listed = variantOf(list(locked));
    val read = variantOf(readText([locked, "/f.txt"].join("")));
    allowAll(locked);
    removeTree(dir);
    // Run as root nothing is denied, and there is nothing to read.
    if (denied) {
        assert listed == "PermissionDenied " + locked;
        assert read == "PermissionDenied " + [locked, "/f.txt"].join("");
    }
}

```

----- ERLANG -- std/io/fs.erl
```erlang
-module(std@io@fs).
-export([readBytes/1, readText/1, writeBytes/2, writeText/2, appendText/2, stat/1, list/1, mkdir/1, mkdirRecursive/1, rm/1, removeTree/1, copy/2, walk/1, glob/2, open/1, create/1, openAsset/1, exists/1, lift/2, decode/2, '__bp_priv__fsError'/2, '__bp_priv__statOr'/1, '__bp_priv__makeFixtureTree'/1, '__bp_priv__walkFixture'/1, '__bp_priv__walkFixtureFromCwd'/1, '__bp_priv__walkRefusal'/1, '__bp_priv__describe'/1, '__bp_priv__makeGlobTree'/1, '__bp_priv__globbed'/1, '__bp_priv__variantOf'/1, '__bp_priv__noFile'/0, '__bp_priv__string_slice'/3]).

%% behavior String

%% behavior Bytes

%% behavior Bool

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

%%% Every function that can fail answers `@Result<…, FsError>`: the same OS error is

%%% the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),

%%% and `Other.message` is the host's own text. The whole-file shortcuts

%%% (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and

%%% the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,

%%% `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`

%%% and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.

%%% 

%%% The host cells (`raw…`) answer `@Result<R, string>` whose error is

%%% `<kind>|<host text>` — `kind` one of `notfound`, `denied`, `isdir`, `notdir`,

%%% `exists`, `other` (or `dangling`, a `walk`'s own) — and `lift` turns it into the

%%% `FsError` of the path the caller wrote. All operations are synchronous

%%% (`*Sync` on Node, blocking BIFs on Erlang); there is no wasm binding here

%%% (front 164: `wasi:filesystem` behind `needs: [.Filesystem]`).

%% import relative

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

% (Node opens one; the template refuses it). The handle is host-owned and opaque: a

% `{ fd, mem, pos, buf }` object on Node, the raw file descriptor on Erlang.

%% external fn rawOpen -> erlang template

% The handle of the file at `path`, open for writing: created, or truncated.

%% external fn rawCreate -> erlang template

% A handle over bytes held in memory — what an `Asset` opens as. The position is a field

% on Node and a `counters` cell on Erlang.

%% external fn memHandle -> erlang template

% The size of the file behind `handle`, in bytes. Erlang's raw descriptor has no `fstat`, so it reads `path`.

%% external fn rawSize -> erlang template

% Up to `n` bytes (n > 0) from the handle's position; empty at the end.

%% external fn rawRead -> erlang template

% Every byte from the handle's position to the end.

%% external fn rawReadAll -> erlang template

% The next line, terminator included; empty at the end.

%% external fn rawReadLine -> erlang template

% The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,

% whatever the position, which it leaves where it was.

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

% `<kind>|<host text>` → the `FsError` of `path`.

fsError(Path, Raw) ->
    Bar = (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(Raw, <<"|">>),
    Kind = string_slice(Raw, 0, Bar),
    Message = string_slice(Raw, '__bp_int'((Bar + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:316:33">>), undefined),
    case (Kind =:= <<"notfound">>) of
        true ->
            {std@io@fs@@FsError__v__notfound, Path};
        _ ->
            case (Kind =:= <<"denied">>) of
                true ->
                    {std@io@fs@@FsError__v__permissiondenied, Path};
                _ ->
                    case (Kind =:= <<"isdir">>) of
                        true ->
                            {std@io@fs@@FsError__v__isdirectory, Path};
                        _ ->
                            case (Kind =:= <<"notdir">>) of
                                true ->
                                    {std@io@fs@@FsError__v__notdirectory, Path};
                                _ ->
                                    case (Kind =:= <<"exists">>) of
                                        true ->
                                            {std@io@fs@@FsError__v__alreadyexists, Path};
                                        _ ->
                                            {std@io@fs@@FsError__v__other, Path, Message}
                                    end
                            end
                    end
            end
    end.

% A host cell's answer, its error read as an `FsError` of `path`.

lift(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, M} ->
            {error, fsError(Path, M)}
    end.

% The text of `b`, or `InvalidUtf8` at the first invalid byte.

decode(Path, B) ->
    Offset = (fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)(B),
    case (Offset >= 0) of
        true ->
            {error, {std@io@fs@@FsError__v__invalidutf8, Path, Offset}};
        _ ->
            {ok, (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (<<"">>) end end)((fun(__B) -> case unicode:characters_to_binary(__B) of __S when is_binary(__S) -> {ok, __S}; _ -> {error, <<"Bytes.toUtf8: not valid UTF-8">>} end end)(B))}
    end.

% ── whole-file shortcuts ─────────────────────────────────────────────────────

% The file's bytes.

readBytes(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __Ek(__R)} end end)(Path)) of
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
    case lift(Path, (fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

writeText(Path, Contents) ->
    case lift(Path, (fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

% Append `contents`, creating the file when it is not there.

appendText(Path, Contents) ->
    case lift(Path, (fun(__P, __C) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

% ── metadata and directories ─────────────────────────────────────────────────

stat(Path) ->
    case lift(Path, '__bp_adopt'((fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __Ek(__R)} end end)(Path), std@io@fs@@FileStat, [size, mtime, isDir])) of
        {ok, S} ->
            {ok, S};
        {error, _TryE0} -> {error, _TryE0}
    end.

list(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, __Ek(__R)} end end)(Path)) of
        {ok, Names} ->
            {ok, Names};
        {error, _TryE0} -> {error, _TryE0}
    end.

mkdir(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

mkdirRecursive(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

rm(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, __Ek(eisdir)}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

removeTree(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

copy(Src, Dest) ->
    case lift(Src, (fun(__S, __D) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __Ek(__R)} end end)(Src, Dest)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

walk(Root) ->
    case lift(Root, (fun(__R) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, __Ek(case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end)}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"dangling|fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, __Ek(__Y)} end end end)(Root)) of
        {ok, Paths} ->
            {ok, Paths};
        {error, _TryE0} -> {error, _TryE0}
    end.

glob(Pattern, Root) ->
    case lift(Root, (fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, {ok, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))]} end)(Pattern, Root)) of
        {ok, Paths} ->
            {ok, Paths};
        {error, _TryE0} -> {error, _TryE0}
    end.

% The host's handle over embedded bytes: read like a file, never closed on disk.

%% external fn memoryHandle -> erlang template

% ── the handle ───────────────────────────────────────────────────────────────

% An open file (decision 540 (3)). `location` is the path it was opened with and

% `handle` the host's — opaque, never read by a program. Closed by the writer:

% `val f = try fs.open(p); defer f.close();`.

%% type File: location, handle

% Open the file at `path` for reading. A directory is `IsDirectory` on every target.

open(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:open(__P, [read, binary, raw, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __Ek(__R)} end end)(Path)) of
        {ok, H} ->
            {ok, {std@io@fs@@File, Path, H}};
        {error, _TryE0} -> {error, _TryE0}
    end.

% Open the file at `path` for writing: created, or truncated.

create(Path) ->
    case lift(Path, (fun(__P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __Ek(__R)} end end)(Path)) of
        {ok, H} ->
            {ok, {std@io@fs@@File, Path, H}};
        {error, _TryE0} -> {error, _TryE0}
    end.

% An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read

% like a file on disk — no `@Result`, the build proved the file exists — and

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


string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
```

----- ERLANG -- std@io@fs@@FsError.erl
```erlang
-module(std@io@fs@@FsError).
-export([message/1, '__bp_format'/1]).

message(Self) ->
    case Self of
        {std@io@fs@@FsError__v__notfound, Path} ->
            <<"not found: ", ('__bp_text'(Path))/binary>>;
        {std@io@fs@@FsError__v__permissiondenied, Path@1} ->
            <<"permission denied: ", ('__bp_text'(Path@1))/binary>>;
        {std@io@fs@@FsError__v__isdirectory, Path@2} ->
            <<"is a directory: ", ('__bp_text'(Path@2))/binary>>;
        {std@io@fs@@FsError__v__notdirectory, Path@3} ->
            <<"not a directory: ", ('__bp_text'(Path@3))/binary>>;
        {std@io@fs@@FsError__v__alreadyexists, Path@4} ->
            <<"already exists: ", ('__bp_text'(Path@4))/binary>>;
        {std@io@fs@@FsError__v__invalidutf8, Path@5, Offset} ->
            <<"not UTF-8: ", ('__bp_text'(Path@5))/binary, " at byte ", ('__bp_text'(erlang:integer_to_binary(Offset)))/binary>>;
        {std@io@fs@@FsError__v__other, Path@6, Message} ->
            <<('__bp_text'(Path@6))/binary, ": ", ('__bp_text'(Message))/binary>>
    end.

'__bp_format'({std@io@fs@@FsError__v__notfound, F0}) -> {variant, "FsError.NotFound", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__permissiondenied, F0}) -> {variant, "FsError.PermissionDenied", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__isdirectory, F0}) -> {variant, "FsError.IsDirectory", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__notdirectory, F0}) -> {variant, "FsError.NotDirectory", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__alreadyexists, F0}) -> {variant, "FsError.AlreadyExists", [{"path", F0}]};
'__bp_format'({std@io@fs@@FsError__v__invalidutf8, F0, F1}) -> {variant, "FsError.InvalidUtf8", [{"path", F0}, {"offset", F1}]};
'__bp_format'({std@io@fs@@FsError__v__other, F0, F1}) -> {variant, "FsError.Other", [{"path", F0}, {"message", F1}]}.

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
```

----- ERLANG -- std@io@fs@@FileStat.erl
```erlang
-module(std@io@fs@@FileStat).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, size) -> erlang:element(2, V);
'__bp_get'(V, mtime) -> erlang:element(3, V);
'__bp_get'(V, isDir) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "FileStat", [{"size", erlang:element(2, V)}, {"mtime", erlang:element(3, V)}, {"isDir", erlang:element(4, V)}]}.
```

----- ERLANG -- std@io@fs@@File.erl
```erlang
-module(std@io@fs@@File).
-compile({no_auto_import,[size/1]}).
-export([path/1, size/1, read/2, bytes/1, text/1, chunks/2, lines/1, hash/1, write/2, close/1, '__bp_get'/2, '__bp_format'/1]).

path(Self) ->
    erlang:element(2, Self).

size(Self) ->
    case std@io@fs:lift(erlang:element(2, Self), (fun(__H, __P) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __Ek(__R)} end end end)(erlang:element(3, Self), erlang:element(2, Self))) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

read(Self, N) ->
    case (N =< 0) of
        true ->
            {ok, <<"">>};
        _ ->
            case std@io@fs:lift(erlang:element(2, Self), (fun(__H, __N) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __Ek(__R)} end end end)(erlang:element(3, Self), N)) of
                {ok, B} ->
                    {ok, B};
                {error, _TryE0} -> {error, _TryE0}
            end
    end.

bytes(Self) ->
    case std@io@fs:lift(erlang:element(2, Self), (fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __Ek(__R)} end end)([]) end end)(erlang:element(3, Self))) of
        {ok, B} ->
            {ok, B};
        {error, _TryE0} -> {error, _TryE0}
    end.

text(Self) ->
    case bytes(Self) of
        {ok, B} ->
            case std@io@fs:decode(erlang:element(2, Self), B) of
                {ok, S} ->
                    {ok, S};
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

%% @Stream — eager lowering
chunks(Self, Size) ->
    __BpGen1 = erlang:make_ref(),
    erlang:put(__BpGen1, []),
    try
        try
            (fun __BpLoop() ->
                B = case read(Self, Size) of
                    {ok, _TryV0} -> _TryV0;
                    {error, _TryE0} -> erlang:throw({'__bp_gen_end', __BpGen1, ok, {error, _TryE0}})
                end,
                case (erlang:byte_size(B) =:= 0) of
                    true ->
                        erlang:throw({'__bp_cond_break', ok});
                    _ -> ok
                end,
                erlang:put(__BpGen1, [{ok, B} | erlang:get(__BpGen1)]),
                __BpLoop()
            end)()
        catch
            throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
        end
    catch
        throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> erlang:put(__BpGen1, [__BpGenV1 | erlang:get(__BpGen1)]), ok
    end,
    lists:reverse(erlang:erase(__BpGen1)).

%% @Stream — eager lowering
lines(Self) ->
    __BpGen2 = erlang:make_ref(),
    erlang:put(__BpGen2, []),
    try
        Consumed = 0,
        Consumed@3 = try
            (fun __BpLoop(Consumed@1) ->
                Raw = case std@io@fs:lift(erlang:element(2, Self), (fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __Ek(__R)} end end end)(erlang:element(3, Self))) of
                    {ok, _TryV0} -> _TryV0;
                    {error, _TryE0} -> erlang:throw({'__bp_gen_end', __BpGen2, ok, {error, _TryE0}})
                end,
                case (erlang:byte_size(Raw) =:= 0) of
                    true ->
                        erlang:throw({'__bp_cond_break', Consumed@1});
                    _ -> ok
                end,
                Line = (fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)(Raw),
                Offset = (fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)(Line),
                case (Offset >= 0) of
                    true ->
                        erlang:throw({'__bp_gen_end', __BpGen2, ok, {error, {std@io@fs@@FsError__v__invalidutf8, erlang:element(2, Self), '__bp_int'((Consumed@1 + Offset), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/io/fs.bp:483:21">>)}}});
                    _ -> ok
                end,
                Width = erlang:byte_size(Raw),
                Consumed@2 = '__bp_int'((Consumed@1 + (fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(Width)), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/io/fs.bp:485:33">>),
                erlang:put(__BpGen2, [{ok, (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (<<"">>) end end)((fun(__B) -> case unicode:characters_to_binary(__B) of __S when is_binary(__S) -> {ok, __S}; _ -> {error, <<"Bytes.toUtf8: not valid UTF-8">>} end end)(Line))} | erlang:get(__BpGen2)]),
                __BpLoop(Consumed@2)
            end)(Consumed)
        catch
            throw:{'__bp_cond_break', __BpGroup2} -> __BpGroup2
        end
    catch
        throw:{'__bp_gen_end', __BpGenK2, _, __BpGenV2} when (__BpGenK2 =:= __BpGen2) -> erlang:put(__BpGen2, [__BpGenV2 | erlang:get(__BpGen2)]), ok
    end,
    lists:reverse(erlang:erase(__BpGen2)).

hash(Self) ->
    case std@io@fs:lift(erlang:element(2, Self), (fun(__H) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> throw({bp_fs_hash, __R}) end end, try {ok, string:lowercase(binary:encode_hex(__L(0, crypto:hash_init(sha256))))} catch throw:{bp_fs_hash, __Y} -> {error, __Ek(__Y)} end end end)(erlang:element(3, Self))) of
        {ok, H} ->
            {ok, H};
        {error, _TryE0} -> {error, _TryE0}
    end.

write(Self, B) ->
    case std@io@fs:lift(erlang:element(2, Self), (fun(__H, __B) -> __Ek = fun(__Rs) -> __K = case __Rs of enoent -> <<"notfound">>; eacces -> <<"denied">>; eperm -> <<"denied">>; eisdir -> <<"isdir">>; enotdir -> <<"notdir">>; eexist -> <<"exists">>; _ -> <<"other">> end, unicode:characters_to_binary([__K, <<"|">>, io_lib:format("~tp", [__Rs])]) end, case __H of {mem, _, _} -> {error, <<"other|the file is open for reading">>}; _ -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __Ek(__R)} end end end)(erlang:element(3, Self), B)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

close(Self) ->
    (fun(__H) -> case __H of {mem, _, _} -> ok; _ -> _ = file:close(__H), ok end end)(erlang:element(3, Self)).

'__bp_get'(V, location) -> erlang:element(2, V);
'__bp_get'(V, handle) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "File", [{"location", erlang:element(2, V)}, {"handle", erlang:element(3, V)}]}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/probe.bp
```botopink
import {path: {join}, io.fs.readText};

pub fn peek(p: string) -> string {
    return readText(join([p, "a"]));
}
```

----- COMPILE DIAGNOSTIC -- std/probe
```text
error: std-root-imports-io: std module `probe` is at the root of std, which is pure; `io.fs.readText` imports from `io/`
  ┌─ std/probe.bp:1:23
  │
1 │ import {path: {join}, io.fs.readText};
  │                       ^

  hint: Move the module under `io/` (it talks to the world), or take the value it needs as a parameter.
```

