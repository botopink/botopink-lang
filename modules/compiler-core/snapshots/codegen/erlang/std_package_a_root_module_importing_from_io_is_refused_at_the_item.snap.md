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
// on `array<T>` default-fn bodies that lower to a `var` + `push` shape,
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

%% behavior string

%% behavior bool

%% behavior array

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

% on `array<T>` default-fn bodies that lower to a `var` + `push` shape,

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

----- SOURCE CODE -- std/failure.bp
```botopink
//// std/failure — the two records a failure that is not a typed error carries
//// (decisions 431, 492).
////
//// `HostError` is what a host binding that writes `result: true` answers on
//// the `Error` side: the host's message and `kind`, always `"host"`.
//// `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
//// (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
//// from a binding without `result: true`) or `crash` (a VM or emitted-code
//// fault, a wasm trap).
////
//// `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
//// for a raise it caught — the one way to contain a crash (decision 431 (3)).
//// `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
//// awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
//// back by `await` like any failing task (decision 432). The kinds
//// (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
//// and an integer overflow or division by zero are `panic`, their message
//// the text the program wrote. A raise of a binding declared outside std without
//// `result: true` is `host` (decision 546), its message the host's text — on
//// commonJS an `Error`'s `message`, else `String(e)`, the call run through
//// `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
//// `crash`, its message the same text. On erlang and beam a
//// host raise is the raise of a binding declared outside std without `result:
//// true` — a library's or the program's, whose calls are wrapped to mark it
//// (decision 546) — its message the reason by `~tp` (decision 489's reading);
//// a raise nothing marked, a failing match or a std binding's, is `crash`,
//// its message the reason by `~tp` too.
////
//// Both are bodyless: each backend wraps the call (a JavaScript `try` /
//// rejection handler, an erlang `try … catch`; beam compiles the erlang
//// form). On wasm (decision 518) each is a private body over `caught`, the
//// `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
//// catches the program's aborts (wasm exception handling), so the binding
//// declares `needs: [.Exceptions]` and a program reaching it runs with the
//// host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
//// is `panic`; a trap (an overflow or a division by zero there, a host
//// fault) is no exception and is not caught. `attemptTask` contains what
//// the thunk raises before the task's first `await`.

import {compiler};

pub type HostErrorName {
    Error,
    Throw,
    Exit,
}

pub type HostError(message: string, kind: string, name: HostErrorName, detail: ?string)

pub type Failure(message: string, kind: string)

// Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
// with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
// Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
// inside std); `panic("not implemented")` is what `todo` was.
#[compiler.external(
    .Erlang("erlang:error({panic, $0})"),
    .JavaScript("(() => { throw Object.defineProperty(new Error($0), '__bp_panic', { value: true }) })()"),
)]
pub declare fn panic(message: string = "panic") -> noreturn;

// The Node forms read an abort by the `__bp_panic` mark the backend puts on
// every one it raises — `panic`, `@todo`, an integer overflow or division
// by zero, a failed `assert` (whose mark carries its message) — or a test
// body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
// backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
// M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
// (decision 432): marked `__bp_fails`, resolved with the value, rejected with
// the `Failure` (`__bp_failure`); a failing task `f` answers is read as
// `await` reads it.
#[compiler.external(
    .JavaScript("""((__f, __k) => { try { return { ok: __f() }; } catch (__e) { return { error: __k(__e) }; } })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptOnWasm),
)]
pub declare fn attempt<T>(f: fn() -> T) -> Result<T, Failure>;

#[compiler.external(
    .JavaScript("""((__f, __k) => { const __t = (async () => { const __x = __f(); return (__x != null && __x.__bp_fails === true) ? await __x.then((__v) => ({ ok: __v }), (__e) => { if (__x.__bp_failure === true) { return { error: __e }; } throw __e; }) : await __x; })().then((__v) => __v, (__e) => { __t.__bp_failure = true; throw __k(__e); }); __t.__bp_fails = true; __t.catch(() => {}); return __t; })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptTaskOnWasm),
)]
pub declare fn attemptTask<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>>;

// wasm's form (decision 518): the thunk's value, or the message of the abort
// it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
// The bodies over it are compiled on every target, so it has a form on each;
// only wasm calls it (`attempt`'s own forms answer elsewhere).
#[compiler.external(
    .JavaScript("""((__f) => { try { return { ok: __f() }; } catch (__e) { return { error: (__e instanceof Error) ? __e.message : String(__e) }; } })($0)"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)($0)"""),
    .Wasm(wasi: .Attempt, needs: [.Exceptions]),
)]
declare fn caught<T>(f: fn() -> T) -> Result<T, string>;

fn attemptOnWasm<T>(f: fn() -> T) -> Result<T, Failure> {
    case caught(f) {
        Ok(v) -> return v;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

// The task the thunk started — or the `Failure` it raised before its first
// `await` — and then its value.
async fn attemptTaskOnWasm<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>> {
    case caught(f) {
        Ok(t) -> return await t;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

```

----- ERLANG -- std/failure.erl
```erlang
-module(std@failure).
-export([panic/1, attempt/1, attemptTask/1, '__bp_priv__attemptOnWasm'/1, '__bp_priv__attemptTaskOnWasm'/1]).

%%% std/failure — the two records a failure that is not a typed error carries

%%% (decisions 431, 492).

%%% 

%%% `HostError` is what a host binding that writes `result: true` answers on

%%% the `Error` side: the host's message and `kind`, always `"host"`.

%%% `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`

%%% (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise

%%% from a binding without `result: true`) or `crash` (a VM or emitted-code

%%% fault, a wasm trap).

%%% 

%%% `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`

%%% for a raise it caught — the one way to contain a crash (decision 431 (3)).

%%% `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,

%%% awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read

%%% back by `await` like any failing task (decision 432). The kinds

%%% (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`

%%% and an integer overflow or division by zero are `panic`, their message

%%% the text the program wrote. A raise of a binding declared outside std without

%%% `result: true` is `host` (decision 546), its message the host's text — on

%%% commonJS an `Error`'s `message`, else `String(e)`, the call run through

%%% `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is

%%% `crash`, its message the same text. On erlang and beam a

%%% host raise is the raise of a binding declared outside std without `result:

%%% true` — a library's or the program's, whose calls are wrapped to mark it

%%% (decision 546) — its message the reason by `~tp` (decision 489's reading);

%%% a raise nothing marked, a failing match or a std binding's, is `crash`,

%%% its message the reason by `~tp` too.

%%% 

%%% Both are bodyless: each backend wraps the call (a JavaScript `try` /

%%% rejection handler, an erlang `try … catch`; beam compiles the erlang

%%% form). On wasm (decision 518) each is a private body over `caught`, the

%%% `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that

%%% catches the program's aborts (wasm exception handling), so the binding

%%% declares `needs: [.Exceptions]` and a program reaching it runs with the

%%% host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort

%%% is `panic`; a trap (an overflow or a division by zero there, a host

%%% fault) is no exception and is not caught. `attemptTask` contains what

%%% the thunk raises before the task's first `await`.

%% type HostErrorName
%%   Error
%%   Throw
%%   Exit

%% type HostError: message, kind, name, detail

%% type Failure: message, kind

% Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops

% with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.

% Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`

% inside std); `panic("not implemented")` is what `todo` was.

%% external fn panic -> erlang template
panic(Message) ->
    erlang:error({panic, Message}).

% The Node forms read an abort by the `__bp_panic` mark the backend puts on

% every one it raises — `panic`, `@todo`, an integer overflow or division

% by zero, a failed `assert` (whose mark carries its message) — or a test

% body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the

% backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,

% M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task

% (decision 432): marked `__bp_fails`, resolved with the value, rejected with

% the `Failure` (`__bp_failure`); a failing task `f` answers is read as

% `await` reads it.

%% external fn attempt -> erlang template
attempt(F) ->
    (fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)(F).

%% external fn attemptTask -> erlang template
attemptTask(F) ->
    (fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)(F).

% wasm's form (decision 518): the thunk's value, or the message of the abort

% it raised — `Error` of the abort's text, which `attempt` makes a `panic`.

% The bodies over it are compiled on every target, so it has a form on each;

% only wasm calls it (`attempt`'s own forms answer elsewhere).

%% external fn caught -> erlang template

attemptOnWasm(F) ->
    case (fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)(F) of
        {ok, V} ->
            {ok, V};
        {error, M} ->
            {error, {std@failure@@Failure, M, <<"panic">>}}
    end.

% The task the thunk started — or the `Failure` it raised before its first

% `await` — and then its value.

%% @Async — eager lowering
attemptTaskOnWasm(F) ->
    case (fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)(F) of
        {ok, T} ->
            {ok, T};
        {error, M} ->
            {error, {std@failure@@Failure, M, <<"panic">>}}
    end.

'__bp_priv__attemptOnWasm'(A0) -> attemptOnWasm(A0).

'__bp_priv__attemptTaskOnWasm'(A0) -> attemptTaskOnWasm(A0).
```

----- ERLANG -- std@failure@@HostErrorName.erl
```erlang
-module(std@failure@@HostErrorName).
-export(['__bp_format'/1]).

'__bp_format'(std@failure@@HostErrorName__v__error) -> {variant, "HostErrorName.Error", []};
'__bp_format'(std@failure@@HostErrorName__v__throw) -> {variant, "HostErrorName.Throw", []};
'__bp_format'(std@failure@@HostErrorName__v__exit) -> {variant, "HostErrorName.Exit", []}.
```

----- ERLANG -- std@failure@@HostError.erl
```erlang
-module(std@failure@@HostError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, kind) -> erlang:element(3, V);
'__bp_get'(V, name) -> erlang:element(4, V);
'__bp_get'(V, detail) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "HostError", [{"message", erlang:element(2, V)}, {"kind", erlang:element(3, V)}, {"name", erlang:element(4, V)}, {"detail", erlang:element(5, V)}]}.
```

----- ERLANG -- std@failure@@Failure.erl
```erlang
-module(std@failure@@Failure).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, kind) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Failure", [{"message", erlang:element(2, V)}, {"kind", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/io/random.bp
```botopink
//// std/io/random — pseudo-random number primitives (cross-backend).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (the `Math.random` global)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html
////
//// `float()` returns a uniform `[0.0, 1.0)` sample on every backend.
//// Higher-level helpers (`coin`/`pick`) compose `float()` — portable +
//// no host call beyond the uniform sample. Seedable RNGs are deferred:
//// Node has no built-in seedable PRNG behind `Math.random`, so any
//// seed/state surface needs a userland PRNG; ship that in a follow-up
//// once the test infra is ready for reproducible draws.
////
//// NOT A CSPRNG: everything above `secureToken` is `Math.random` /
//// `rand:uniform`, predictable to anyone who sees enough draws. A token, a
//// session id, a nonce or a UUID comes from `secureToken` / `uuidV4`, which
//// read the host's cryptographic source (`crypto.randomBytes`,
//// `crypto:strong_rand_bytes/1`) — or `crypto.randomBytes` for hex.

import {compiler};

#[compiler.external(.JavaScript("Math.random()"), .Erlang("rand:uniform()"), .Wasm(std: "random.float"))]
pub declare fn float() -> f64;

// Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar
// at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`
// draws from the reproducible stream. `float()` itself stays on
// `Math.random`; explicit-stream callers opt into determinism by using
// `seededFloat` after `seed`.
// Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar
// shipper copies the `.mjs` next to the emitted module.
// Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`
// triple. `S` is folded to an integer via the i64 input.
#[compiler.external(
    .JavaScript("""require('./sidecars/random.mjs').seed($0)"""),
    .Erlang("""(fun(__S) -> rand:seed(exsplus, {__S, __S, __S}) end)($0)"""),
    .Wasm(std: "random.seed"),
)]
pub declare fn seed(s: i32) -> void;

// Draw from the seeded PRNG when a `seed` call has been made; otherwise
// falls through to the unseeded `float()` baseline. Erlang's `rand`
// module reads from the process dictionary's seed state directly, so
// the same `rand:uniform/0` call after `seed` produces the reproducible
// stream automatically.
#[compiler.external(
    .JavaScript("""require('./sidecars/random.mjs').seededFloat()"""),
    .Erlang("rand:uniform()"),
    .Wasm(std: "random.seededFloat"),
)]
pub declare fn seededFloat() -> f64;

// 50/50 boolean draw. `float() >= 0.5` picks the upper half of the
// uniform sample — identically distributed on every backend that has
// a uniform `float()`.
pub fn coin() -> bool {
    return float() >= 0.5;
}

// Random integer in the closed interval `[lo, hi]`. When `lo > hi` the
// range is empty and the result is `lo` (a defensive default — the
// alternative is to `panic`, which the @assert-style tests would
// rather catch at the call site).
pub fn intInRange(lo: i32, hi: i32) -> i32 {
    if (lo >= hi) return lo;
    val span = (hi - lo) + 1;
    val product = float() * span;
    val offset = floorWalk(0, 1.0, product, span);
    return lo + offset;
}

// Pick a random element from a non-empty array. Returns `null` for the
// empty array — the call site should default with `?? …` rather
// than panic. Uses a walk-up integer floor (no `Math.floor` import) so
// the body stays self-contained.
pub fn pick<T>(xs: array<T>) -> ?T {
    val n = xs.length;
    if (n == 0) return null;
    // `float() * n` mixes f64 × i32 — inference promotes to f64.
    val product = float() * n;
    val idx = floorWalk(0, 1.0, product, n);
    return xs.at(idx);
}

// Internal: integer floor of a non-negative `product` < `upper`. Walks
// `start` up from 0 while `threshold (= start + 1)` still fits below
// `product`. O(upper) — fine for the small `array<T>` arities `pick`
// targets in tests.
fn floorWalk(start: i32, threshold: f64, product: f64, upper: i32) -> i32 {
    if (start + 1 > upper) return start;
    if (threshold > product) return start;
    return floorWalk(start + 1, threshold + 1.0, product, upper);
}

// Fisher-Yates shuffle. Returns a fresh array whose elements are a
// permutation of `xs`. The pure-bp shape was deferred (the deferral
// note used to live here) because `array<T>::at(i)` returns `?T` and
// extracting T without a sentinel value of T is circular. Solution:
// host-backed `pub declare fn shuffle<T>(xs)` — the host owns the
// in-place swap; the bp side only declares the signature and the
// per-target template.
//
// Node: classic Fisher-Yates over the input array, returning a fresh
// copy (the input is not mutated — matches the immutable-by-default
// botopink contract for return values). `random.seed` from this same
// module seeds the sidecar PRNG; subsequent `shuffle` draws are
// reproducible after `seed(s)`.
//
// Erlang: `[X || {_, X} <- lists:sort([{rand:uniform(), Y} || Y <- $0])]`
// — the Schwartzian-transform shuffle: pair each element with a
// random key, sort by key, strip the keys. Stable across `rand:seed`
// state (the same `rand` server `seed/2` controls both `uniform/0`
// here and `seededFloat()` above).
//
// Beam/wasm: out of scope at v1 (no `lists:sort` template, no
// `Math.random` equivalent in wat3); the matrix will report
// `MissingExternalTarget` on a `shuffle(...)` call from those backends
// until the corresponding shim lands.
#[compiler.external(
    .JavaScript("""(function(__A){ var __O = __A.slice(); for (var __I = __O.length - 1; __I > 0; __I--) { var __J = Math.floor(Math.random() * (__I + 1)); var __T = __O[__I]; __O[__I] = __O[__J]; __O[__J] = __T; } return __O; })($0)"""),
    .Erlang("""[__X || {_, __X} <- lists:sort([{rand:uniform(), __Y} || __Y <- $0])]"""),
    .Wasm(body: shuffleBody),
)]
pub declare fn shuffle<T>(xs: array<T>) -> array<T>;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
//
// The CSPRNG half. Everything ABOVE is `Math.random` / `rand:uniform` — fine
// for a shuffle, wrong for anything an attacker must not guess. A token, a
// session id, a nonce or a UUID comes from the two functions below, which
// read the host's cryptographically strong source.

// `bytes` strong random bytes as base64url without padding — URL-, cookie-
// and header-safe. 32 bytes answer 43 characters.
// Node: `crypto.randomBytes(n).toString('base64url')`.
// Erlang: `crypto:strong_rand_bytes/1` + `base64:encode/2` in `urlsafe`
// mode without padding (OTP 26+).
#[compiler.external(
    .JavaScript("""require('crypto').randomBytes($0).toString('base64url')"""),
    .Erlang("""base64:encode(crypto:strong_rand_bytes($0), #{mode => urlsafe, padding => false})"""),
    .Wasm(body: secureTokenBody),
)]
pub declare fn secureToken(bytes: i32) -> string;

// A random (version 4) UUID, lowercase: 122 strong random bits with the
// version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).
// Node: `crypto.randomUUID()`.
// Erlang: 16 strong random bytes, the version/variant bits rewritten in the
// binary pattern — the bit work lives in the template because botopink has
// no bitwise operators (`language-gaps.md`).
#[compiler.external(
    .JavaScript("""require('crypto').randomUUID()"""),
    .Erlang("""(fun() -> <<__A:32, __B:16, _:4, __C:12, _:2, __D:14, __E:48>> = crypto:strong_rand_bytes(16), iolist_to_binary(io_lib:format("~8.16.0b-~4.16.0b-4~3.16.0b-~4.16.0b-~12.16.0b", [__A, __B, __C, __D bor 16#8000, __E])) end)()"""),
    .Wasm(body: uuidV4Body),
)]
pub declare fn uuidV4() -> string;

// ── tests ────────────────────────────────────────────────────────────────────

test "random.float lies in [0.0, 1.0)" {
    val r = float();
    assert r >= 0.0;
    assert r < 1.0;
}

test "random.coin draws either truth value" {
    val b = coin();
    assert b == true || b == false;
}

test "random.pick from non-empty array returns a member" {
    val xs = [1, 2, 3];
    val r = pick(xs) ?? 99;
    assert r >= 1;
    assert r <= 3;
}

test "random.pick from empty array returns null" {
    val empty: array<i32> = [];
    assert pick(empty) ?? 99 == 99;
}

test "random.intInRange yields a value in the closed interval" {
    val r = intInRange(1, 6);
    assert r >= 1;
    assert r <= 6;
}

test "random.intInRange on a one-element range returns that element" {
    assert intInRange(7, 7) == 7;
}

test "random.intInRange on an inverted range returns the low bound" {
    assert intInRange(10, 5) == 10;
}

test "random.seed + seededFloat draws are reproducible" {
    seed(42);
    val a = seededFloat();
    seed(42);
    val b = seededFloat();
    assert a == b;
}

test "random.seededFloat lies in [0.0, 1.0)" {
    val r = seededFloat();
    assert r >= 0.0;
    assert r < 1.0;
}

test "random.shuffle preserves length" {
    val xs = [1, 2, 3, 4, 5];
    val ys = shuffle(xs);
    assert ys.length == 5;
}

test "random.shuffle preserves the multiset (sum)" {
    val xs = [1, 2, 3, 4, 5];
    val ys = shuffle(xs);
    // Sum is permutation-invariant — every element still appears once.
    var s = 0;
    ys.forEach({ y ->
        s = s + y;
    });
    assert s == 15;
}

test "random.shuffle of an empty array is empty" {
    val empty: array<i32> = [];
    assert shuffle(empty).length == 0;
}

test "random.shuffle of a single-element array preserves it" {
    val xs = [42];
    val ys = shuffle(xs);
    assert ys.length == 1;
    assert ys.at(0) ?? 0 == 42;
}

test "random.secureToken(32) is 43 base64url characters" {
    val t = secureToken(32);
    assert t.length == 43;
    assert t.contains("+").negate();
    assert t.contains("/").negate();
    assert t.contains("=").negate();
}

test "random.secureToken draws differ" {
    assert secureToken(16) != secureToken(16);
    assert secureToken(0) == "";
}

test "random.uuidV4 has the version 4 layout" {
    val u = uuidV4();
    val groups = u.split("-");
    assert u.length == 36;
    assert groups.length == 5;
    assert (groups.at(0) ?? "").length == 8;
    assert (groups.at(1) ?? "").length == 4;
    assert (groups.at(2) ?? "").length == 4;
    assert (groups.at(3) ?? "").length == 4;
    assert (groups.at(4) ?? "").length == 12;
    assert (groups.at(2) ?? "").startsWith("4");
    val variant = (groups.at(3) ?? "").slice(0, 1);
    assert "89ab".contains(variant);
    assert u.split("").filter({ c -> "0123456789abcdef-".contains(c) }).length
        == 36;
    assert uuidV4() != u;
}

// ── randomBytes (was `crypto.randomBytes`) ───────────────────────────────────

// `n` cryptographically-secure random bytes as a hex string of length
// `2 * n` (each byte rendered as two lowercase hex chars). The hex shape
// sidesteps the `array<u8>` cross-backend representation gap — Node
// `Buffer` and Erlang `binary()` don't share a bp-side type. Callers
// that need bytes parse the hex back themselves.
// Node: `require('crypto').randomBytes(n).toString('hex')`.
// Erlang: `crypto:strong_rand_bytes/1` + the same per-byte hex format
// string used by the hashes above.
#[compiler.external(
    .JavaScript("""require('crypto').randomBytes($0).toString('hex')"""),
    .Erlang("""list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:strong_rand_bytes($0))])"""),
    .Wasm(body: randomBytesBody),
)]
pub declare fn randomBytes(n: i32) -> string;

test "random.randomBytes(16) returns 32 hex chars" {
    val h = randomBytes(16);
    assert h.length == 32;
}

test "random.randomBytes(0) is empty" {
    val h = randomBytes(0);
    assert h.length == 0;
}

// ── the wasm bodies (decision 238) ──────────────────────────────────────────
// wasm has no host for these cells, so each names one of the private bodies
// below with `#[compiler.external(.Wasm(fn: …))]`; commonJS and erlang call their
// host. On wasm `float()` is `std: "random.float"` — 53 bits of WASI's
// `random_get`, the host's cryptographic source — so the token, UUID and
// byte bodies draw from it a byte at a time (`randomByte`: ⌊u · 256⌋ of a
// 53-bit uniform `u` is exactly uniform). `seed` / `seededFloat` are
// std-wasm's seeded stream (decision 451, `std: "random.…"`), drawn as the
// commonJS sidecar does (Mulberry32): the same draws after the same `seed`; a
// draw before any seed is the host's (`float()`'s source). At comptime the
// same cells answer, and a draw before any seed is refused — a build has no
// entropy.

// Selection shuffle: each step moves a uniformly drawn element of what is
// left to the output — a uniform permutation, as the Node cell's
// Fisher-Yates; the elements are moved as one-element slices, never read.
fn shuffleBody<T>(xs: array<T>) -> array<T> {
    var rest = xs;
    var out = xs.slice(0, 0);
    while (rest.length > 0) {
        val j = wholeOf((float() * rest.length).floor());
        out = out.append(rest.slice(j, j + 1));
        rest = rest.slice(0, j).append(rest.slice(j + 1, rest.length));
    }
    return out;
}

fn secureTokenBody(bytes: i32) -> string {
    return base64UrlOf(randomBytesOf(bytes));
}

// RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.
fn uuidV4Body() -> string {
    val b = randomBytesOf(16);
    val version = 64 + b.at(6) ?? 0 % 16;
    val variant = 128 + b.at(8) ?? 0 % 64;
    return hexOf(b.slice(0, 4))
        + "-"
        + hexOf(b.slice(4, 6))
        + "-"
        + hexOf([version, b.at(7) ?? 0])
        + "-"
        + hexOf([variant, b.at(9) ?? 0])
        + "-"
        + hexOf(b.slice(10, 16));
}

fn randomBytesBody(n: i32) -> string {
    return hexOf(randomBytesOf(n));
}

fn randomByte() -> i32 {
    return wholeOf((float() * 256.0).floor());
}

fn randomBytesOf(n: i32) -> array<i32> {
    var out: array<i32> = [];
    var i = 0;
    while (i < n) {
        out = out.append([randomByte()]);
        i = i + 1;
    }
    return out;
}

fn hexDigit(n: i32) -> string {
    return "0123456789abcdef".at(n) ?? "";
}

fn hexOf(bytes: array<i32>) -> string {
    return bytes.map({ b -> hexDigit(b / 16) + hexDigit(b % 16) }).join("");
}

// RFC 4648 §5 base64url, unpadded.
fn base64UrlOf(bytes: array<i32>) -> string {
    val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    var out = "";
    var g = 0;
    while (3 * g < bytes.length) {
        val n = bytes.length - 3 * g;
        val b0 = bytes.at(3 * g) ?? 0;
        val b1 = if (n > 1) {
            bytes.at(3 * g + 1) ?? 0;
        } else 0;
        val b2 = if (n > 2) {
            bytes.at(3 * g + 2) ?? 0;
        } else 0;
        out = out
            + alphabet.at(b0 / 4) ?? ""
            + alphabet.at((b0 % 4) * 16 + b1 / 16) ?? "";
        if (n > 1) out = out + alphabet.at((b1 % 16) * 4 + b2 / 64) ?? "";
        if (n > 2) out = out + alphabet.at(b2 % 64) ?? "";
        g = g + 1;
    }
    return out;
}

// A whole `v` in [0, 2^31) as an `i32`.
fn wholeOf(v: f64) -> i32 {
    var r = 0;
    var rest = v;
    var bit = 1073741824;
    var weight = 1073741824.0;
    while (bit > 0) {
        if (rest >= weight) {
            r = r + bit;
            rest = rest - weight;
        }
        bit = bit / 2;
        weight = weight / 2.0;
    }
    return r;
}

```

----- ERLANG -- std/io/random.erl
```erlang
-module(std@io@random).
-export([coin/0, intInRange/2, pick/1, float/0, seed/1, seededFloat/0, shuffle/1, secureToken/1, uuidV4/0, randomBytes/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__floorWalk'/4, '__bp_priv__shuffleBody'/1, '__bp_priv__secureTokenBody'/1, '__bp_priv__uuidV4Body'/0, '__bp_priv__randomBytesBody'/1, '__bp_priv__randomByte'/0, '__bp_priv__randomBytesOf'/1, '__bp_priv__hexDigit'/1, '__bp_priv__hexOf'/1, '__bp_priv__base64UrlOf'/1, '__bp_priv__wholeOf'/1, '__bp_priv__array_slice'/3]).

%% behavior string

%% behavior bool

%% behavior array

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

%% behavior Float

%%% std/io/random — pseudo-random number primitives (cross-backend).

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/  (the `Math.random` global)

%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html

%%% 

%%% `float()` returns a uniform `[0.0, 1.0)` sample on every backend.

%%% Higher-level helpers (`coin`/`pick`) compose `float()` — portable +

%%% no host call beyond the uniform sample. Seedable RNGs are deferred:

%%% Node has no built-in seedable PRNG behind `Math.random`, so any

%%% seed/state surface needs a userland PRNG; ship that in a follow-up

%%% once the test infra is ready for reproducible draws.

%%% 

%%% NOT A CSPRNG: everything above `secureToken` is `Math.random` /

%%% `rand:uniform`, predictable to anyone who sees enough draws. A token, a

%%% session id, a nonce or a UUID comes from `secureToken` / `uuidV4`, which

%%% read the host's cryptographic source (`crypto.randomBytes`,

%%% `crypto:strong_rand_bytes/1`) — or `crypto.randomBytes` for hex.

%% external fn float -> erlang template
float() ->
    rand:uniform().

% Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar

% at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`

% draws from the reproducible stream. `float()` itself stays on

% `Math.random`; explicit-stream callers opt into determinism by using

% `seededFloat` after `seed`.

% Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar

% shipper copies the `.mjs` next to the emitted module.

% Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`

% triple. `S` is folded to an integer via the i64 input.

%% external fn seed -> erlang template
seed(S) ->
    (fun(__S) -> rand:seed(exsplus, {__S, __S, __S}) end)(S).

% Draw from the seeded PRNG when a `seed` call has been made; otherwise

% falls through to the unseeded `float()` baseline. Erlang's `rand`

% module reads from the process dictionary's seed state directly, so

% the same `rand:uniform/0` call after `seed` produces the reproducible

% stream automatically.

%% external fn seededFloat -> erlang template
seededFloat() ->
    rand:uniform().

% 50/50 boolean draw. `float() >= 0.5` picks the upper half of the

% uniform sample — identically distributed on every backend that has

% a uniform `float()`.

coin() ->
    (rand:uniform() >= 0.5).

% Random integer in the closed interval `[lo, hi]`. When `lo > hi` the

% range is empty and the result is `lo` (a defensive default — the

% alternative is to `panic`, which the @assert-style tests would

% rather catch at the call site).

intInRange(Lo, Hi) ->
    case (Lo >= Hi) of
        true ->
            Lo;
        _ ->
            Span = '__bp_int'((('__bp_int'((Hi - Lo), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/random.bp:66:20">>)) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:66:26">>),
            Product = (rand:uniform() * Span),
            Offset = floorWalk(0, 1.0, Product, Span),
            '__bp_int'((Lo + Offset), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:69:15">>)
    end.

% Pick a random element from a non-empty array. Returns `null` for the

% empty array — the call site should default with `?? …` rather

% than panic. Uses a walk-up integer floor (no `Math.floor` import) so

% the body stays self-contained.

pick(Xs) ->
    N = erlang:length(Xs),
    case (N =:= 0) of
        true ->
            undefined;
        _ ->
            % `float() * n` mixes f64 × i32 — inference promotes to f64.
            Product = (rand:uniform() * N),
            Idx = floorWalk(0, 1.0, Product, N),
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, Idx)
    end.

% Internal: integer floor of a non-negative `product` < `upper`. Walks

% `start` up from 0 while `threshold (= start + 1)` still fits below

% `product`. O(upper) — fine for the small `array<T>` arities `pick`

% targets in tests.

floorWalk(Start, Threshold, Product, Upper) ->
    case ('__bp_int'((Start + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:90:15">>) > Upper) of
        true ->
            Start;
        _ ->
            case (Threshold > Product) of
                true ->
                    Start;
                _ ->
                    floorWalk('__bp_int'((Start + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:92:28">>), (Threshold + 1.0), Product, Upper)
            end
    end.

% Fisher-Yates shuffle. Returns a fresh array whose elements are a

% permutation of `xs`. The pure-bp shape was deferred (the deferral

% note used to live here) because `array<T>::at(i)` returns `?T` and

% extracting T without a sentinel value of T is circular. Solution:

% host-backed `pub declare fn shuffle<T>(xs)` — the host owns the

% in-place swap; the bp side only declares the signature and the

% per-target template.

% 

% Node: classic Fisher-Yates over the input array, returning a fresh

% copy (the input is not mutated — matches the immutable-by-default

% botopink contract for return values). `random.seed` from this same

% module seeds the sidecar PRNG; subsequent `shuffle` draws are

% reproducible after `seed(s)`.

% 

% Erlang: `[X || {_, X} <- lists:sort([{rand:uniform(), Y} || Y <- $0])]`

% — the Schwartzian-transform shuffle: pair each element with a

% random key, sort by key, strip the keys. Stable across `rand:seed`

% state (the same `rand` server `seed/2` controls both `uniform/0`

% here and `seededFloat()` above).

% 

% Beam/wasm: out of scope at v1 (no `lists:sort` template, no

% `Math.random` equivalent in wat3); the matrix will report

% `MissingExternalTarget` on a `shuffle(...)` call from those backends

% until the corresponding shim lands.

%% external fn shuffle -> erlang template
shuffle(Xs) ->
    [__X || {_, __X} <- lists:sort([{rand:uniform(), __Y} || __Y <- Xs])].

% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

% 

% The CSPRNG half. Everything ABOVE is `Math.random` / `rand:uniform` — fine

% for a shuffle, wrong for anything an attacker must not guess. A token, a

% session id, a nonce or a UUID comes from the two functions below, which

% read the host's cryptographically strong source.

% `bytes` strong random bytes as base64url without padding — URL-, cookie-

% and header-safe. 32 bytes answer 43 characters.

% Node: `crypto.randomBytes(n).toString('base64url')`.

% Erlang: `crypto:strong_rand_bytes/1` + `base64:encode/2` in `urlsafe`

% mode without padding (OTP 26+).

%% external fn secureToken -> erlang template
secureToken(Bytes) ->
    base64:encode(crypto:strong_rand_bytes(Bytes), #{mode => urlsafe, padding => false}).

% A random (version 4) UUID, lowercase: 122 strong random bits with the

% version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).

% Node: `crypto.randomUUID()`.

% Erlang: 16 strong random bytes, the version/variant bits rewritten in the

% binary pattern — the bit work lives in the template because botopink has

% no bitwise operators (`language-gaps.md`).

%% external fn uuidV4 -> erlang template
uuidV4() ->
    (fun() -> <<__A:32, __B:16, _:4, __C:12, _:2, __D:14, __E:48>> = crypto:strong_rand_bytes(16), iolist_to_binary(io_lib:format("~8.16.0b-~4.16.0b-4~3.16.0b-~4.16.0b-~12.16.0b", [__A, __B, __C, __D bor 16#8000, __E])) end)().

% ── tests ────────────────────────────────────────────────────────────────────

















% ── randomBytes (was `crypto.randomBytes`) ───────────────────────────────────

% `n` cryptographically-secure random bytes as a hex string of length

% `2 * n` (each byte rendered as two lowercase hex chars). The hex shape

% sidesteps the `array<u8>` cross-backend representation gap — Node

% `Buffer` and Erlang `binary()` don't share a bp-side type. Callers

% that need bytes parse the hex back themselves.

% Node: `require('crypto').randomBytes(n).toString('hex')`.

% Erlang: `crypto:strong_rand_bytes/1` + the same per-byte hex format

% string used by the hashes above.

%% external fn randomBytes -> erlang template
randomBytes(N) ->
    list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:strong_rand_bytes(N))]).



% ── the wasm bodies (decision 238) ──────────────────────────────────────────

% wasm has no host for these cells, so each names one of the private bodies

% below with `#[compiler.external(.Wasm(fn: …))]`; commonJS and erlang call their

% host. On wasm `float()` is `std: "random.float"` — 53 bits of WASI's

% `random_get`, the host's cryptographic source — so the token, UUID and

% byte bodies draw from it a byte at a time (`randomByte`: ⌊u · 256⌋ of a

% 53-bit uniform `u` is exactly uniform). `seed` / `seededFloat` are

% std-wasm's seeded stream (decision 451, `std: "random.…"`), drawn as the

% commonJS sidecar does (Mulberry32): the same draws after the same `seed`; a

% draw before any seed is the host's (`float()`'s source). At comptime the

% same cells answer, and a draw before any seed is refused — a build has no

% entropy.

% Selection shuffle: each step moves a uniformly drawn element of what is

% left to the output — a uniform permutation, as the Node cell's

% Fisher-Yates; the elements are moved as one-element slices, never read.

shuffleBody(Xs) ->
    Rest = Xs,
    Out = array_slice(Xs, 0, 0),
    {Out@3, Rest@3} = (fun __BpLoop({Out@1, Rest@1}) ->
        case (erlang:length(Rest@1) > 0) of
            true ->
                J = wholeOf(math:floor(((rand:uniform() * erlang:length(Rest@1))))),
                Out@2 = (Out@1 ++ array_slice(Rest@1, J, '__bp_int'((J + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:319:42">>))),
                Rest@2 = (array_slice(Rest@1, 0, J) ++ array_slice(Rest@1, '__bp_int'((J + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:320:53">>), erlang:length(Rest@1))),
                __BpLoop({Out@2, Rest@2});
            _ -> {Out@1, Rest@1}
        end
    end)({Out, Rest}),
    Out@3.

secureTokenBody(Bytes) ->
    base64UrlOf(randomBytesOf(Bytes)).

% RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.

uuidV4Body() ->
    B = randomBytesOf(16),
    Version = '__bp_int'((64 + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, 6) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end rem 16)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:332:22">>),
    Variant = '__bp_int'((128 + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, 8) of
        undefined ->
            0;
        __bp_nullish@1 ->
            __bp_nullish@1
    end rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:333:23">>),
    <<(hexOf(array_slice(B, 0, 4)))/binary, "-", (hexOf(array_slice(B, 4, 6)))/binary, "-", (hexOf([Version, case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, 7) of
        undefined ->
            0;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]))/binary, "-", (hexOf([Variant, case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, 9) of
        undefined ->
            0;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]))/binary, "-", (hexOf(array_slice(B, 10, 16)))/binary>>.

randomBytesBody(N) ->
    hexOf(randomBytesOf(N)).

randomByte() ->
    wholeOf(math:floor(((rand:uniform() * 256.0)))).

randomBytesOf(N) ->
    Out = [],
    I = 0,
    {Out@3, I@3} = (fun __BpLoop({Out@1, I@1}) ->
        case (I@1 < N) of
            true ->
                Out@2 = (Out@1 ++ [randomByte()]),
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:358:15">>),
                __BpLoop({Out@2, I@2});
            _ -> {Out@1, I@1}
        end
    end)({Out, I}),
    Out@3.

hexDigit(N) ->
    case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(<<"0123456789abcdef">>, N) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end.

hexOf(Bytes) ->
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(B) ->
        <<(hexDigit('__bp_int'((B div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/io/random.bp:368:40">>)))/binary, (hexDigit((B rem 16)))/binary>>
    end, Bytes)))).

% RFC 4648 §5 base64url, unpadded.

base64UrlOf(Bytes) ->
    Alphabet = <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_">>,
    Out = <<"">>,
    G = 0,
    {Out@7, G@3} = (fun __BpLoop({Out@1, G@1}) ->
        case ('__bp_int'((3 * G@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/io/random.bp:376:14">>) < erlang:length(Bytes)) of
            true ->
                N = '__bp_int'((erlang:length(Bytes) - '__bp_int'((3 * G@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/io/random.bp:377:34">>)), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/random.bp:377:30">>),
                B0 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'((3 * G@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/io/random.bp:378:29">>)) of
                    undefined ->
                        0;
                    __bp_nullish ->
                        __bp_nullish
                end,
                B1 = case (N > 1) of
                    true ->
                        case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'(('__bp_int'((3 * G@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/io/random.bp:380:24">>) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:380:28">>)) of
                            undefined ->
                                0;
                            __bp_nullish@1 ->
                                __bp_nullish@1
                        end;
                    false ->
                        0
                end,
                B2 = case (N > 2) of
                    true ->
                        case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'(('__bp_int'((3 * G@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/io/random.bp:383:24">>) + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:383:28">>)) of
                            undefined ->
                                0;
                            __bp_nullish@2 ->
                                __bp_nullish@2
                        end;
                    false ->
                        0
                end,
                Out@2 = <<Out@1/binary, ('__bp_text'(case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'((B0 div 4), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/io/random.bp:386:30">>)) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@3 ->
                        __bp_nullish@3
                end))/binary, ('__bp_text'(case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'(('__bp_int'((((B0 rem 4)) * 16), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/io/random.bp:387:36">>) + '__bp_int'((B1 div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/io/random.bp:387:46">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:387:41">>)) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@4 ->
                        __bp_nullish@4
                end))/binary>>,
                Out@4 = case (N > 1) of
                    true ->
                        Out@3 = <<Out@2/binary, ('__bp_text'(case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'(('__bp_int'((((B1 rem 16)) * 4), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/io/random.bp:388:54">>) + '__bp_int'((B2 div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/io/random.bp:388:63">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:388:58">>)) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@5 ->
                                __bp_nullish@5
                        end))/binary>>,
                        Out@3;
                    _ ->
                        Out@2
                end,
                Out@6 = case (N > 2) of
                    true ->
                        Out@5 = <<Out@4/binary, ('__bp_text'(case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, (B2 rem 64)) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@6 ->
                                __bp_nullish@6
                        end))/binary>>,
                        Out@5;
                    _ ->
                        Out@4
                end,
                G@2 = '__bp_int'((G@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:390:15">>),
                __BpLoop({Out@6, G@2});
            _ -> {Out@1, G@1}
        end
    end)({Out, G}),
    Out@7.

% A whole `v` in [0, 2^31) as an `i32`.

wholeOf(V) ->
    R = 0,
    Rest = V,
    Bit = 1073741824,
    Weight = 1073741824.0,
    {R@4, Rest@4, Bit@3, Weight@3} = (fun __BpLoop({R@1, Rest@1, Bit@1, Weight@1}) ->
        case (Bit@1 > 0) of
            true ->
                {R@3, Rest@3} = case (Rest@1 >= Weight@1) of
                    true ->
                        R@2 = '__bp_int'((R@1 + Bit@1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/random.bp:403:19">>),
                        Rest@2 = (Rest@1 - Weight@1),
                        {R@2, Rest@2};
                    _ ->
                        {R@1, Rest@1}
                end,
                Bit@2 = '__bp_int'((Bit@1 div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/io/random.bp:406:19">>),
                Weight@2 = (Weight@1 / 2.0),
                __BpLoop({R@3, Rest@3, Bit@2, Weight@2});
            _ -> {R@1, Rest@1, Bit@1, Weight@1}
        end
    end)({R, Rest, Bit, Weight}),
    R@4.

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__floorWalk'(A0, A1, A2, A3) -> floorWalk(A0, A1, A2, A3).

'__bp_priv__shuffleBody'(A0) -> shuffleBody(A0).

'__bp_priv__secureTokenBody'(A0) -> secureTokenBody(A0).

'__bp_priv__uuidV4Body'() -> uuidV4Body().

'__bp_priv__randomBytesBody'(A0) -> randomBytesBody(A0).

'__bp_priv__randomByte'() -> randomByte().

'__bp_priv__randomBytesOf'(A0) -> randomBytesOf(A0).

'__bp_priv__hexDigit'(A0) -> hexDigit(A0).

'__bp_priv__hexOf'(A0) -> hexOf(A0).

'__bp_priv__base64UrlOf'(A0) -> base64UrlOf(A0).

'__bp_priv__wholeOf'(A0) -> wholeOf(A0).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).
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
//// Every function that can fail answers `Result<…, FsError>`: the same OS error is
//// the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
//// and `Other.message` is the host's own text. The whole-file shortcuts
//// (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
//// the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
//// `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
//// and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
////
//// The host cells (`raw…`) write `result: true` (decisions 431, 490) and answer
//// `Result<R, HostError>` — Node's `ENOENT: …`, erlang's `enoent` as its `message` —
//// and `lift` reads that message as the `FsError` of the path the caller wrote
//// (decision 486); no cell catches by hand. All operations are synchronous
//// (`*Sync` on Node, blocking BIFs on Erlang, `wasi:filesystem` on wasm: the runner
//// preopens the root and the working directory, decision 992), and a path is read as
//// the process reads it — a relative one against the working directory — on every target.

import {path.relative, failure, failure.HostError, failure.HostErrorName, io.random, compiler};

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
#[compiler.external(
    .JavaScript("""(() => { return new Uint8Array(require('fs').readFileSync($0)) })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: readBytesWasm),
)]
declare fn rawReadBytes(path: string) -> Result<bytes, HostError>;

// Write `contents` to `path`, creating or truncating.
// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeBytesWasm),
)]
declare fn rawWriteBytes(path: string, contents: bytes) -> Result<i32, HostError>;

// Append `contents` to `path`, creating it when it is not there.
// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').appendFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: appendTextWasm),
)]
declare fn rawAppendText(path: string, contents: string) -> Result<i32, HostError>;

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
// or -1 when every byte is part of a valid sequence — the same offset on every target.
// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
#[compiler.external(
    .JavaScript("""((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })($0)"""),
    .Erlang("""(fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)($0)"""),
    .Wasm(body: utf8OffsetWasm),
)]
declare fn utf8Offset(bytes: bytes) -> i64;

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.
// Node: `subarray`. Erlang: `binary:part/3`.
#[compiler.external(
    .JavaScript("""((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })($0)"""),
    .Erlang("""(fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)($0)"""),
    .Wasm(body: stripEolWasm),
)]
declare fn stripEol(line: bytes) -> bytes;

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
// (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
// mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = $0; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); throw new Error('EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p)) } return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [read, binary, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: openWasm),
)]
declare fn rawOpen(path: string) -> Result<unknown, HostError>;

// The handle of the file at `path`, open for writing: created, or truncated.
#[compiler.external(
    .JavaScript("""(() => { const __fd = require('fs').openSync($0, 'w'); return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: createWasm),
)]
declare fn rawCreate(path: string) -> Result<unknown, HostError>;

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field
// on Node and a `counters` cell on Erlang.
#[compiler.external(
    .JavaScript("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })"""),
    .Erlang("""{mem, $0, counters:new(1, [])}"""),
    .Wasm(body: memHandleWasm),
)]
declare fn memHandle(bytes: bytes) -> unknown;

// The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; return __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size })()""", result: true),
    .Erlang("""(fun(__H, __P) -> case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
    .Wasm(body: sizeWasm),
)]
declare fn rawSize(handle: unknown, path: string) -> Result<i64, HostError>;

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __n = $1; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return __o } return new Uint8Array(__more(__h, __n)) })()""", result: true),
    .Erlang("""(fun(__H, __N) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
    .Wasm(body: readWasm),
)]
declare fn rawRead(handle: unknown, n: i32) -> Result<bytes, HostError>;

// Every byte from the handle's position to the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return __o })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __R} end end)([]) end end)($0)""", result: true),
    .Wasm(body: readAllWasm),
)]
declare fn rawReadAll(handle: unknown) -> Result<bytes, HostError>;

// The next line, terminator included; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return __l } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return __l } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: readLineWasm),
)]
declare fn rawReadLine(handle: unknown) -> Result<bytes, HostError>;

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
// whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the
// position undefined (OTP moves it), so the position is read first and restored.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return __hs.digest('hex') })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> {ok, __Cur} = file:position(__H, cur), __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> erlang:error(__R) end end, __Digest = __L(0, crypto:hash_init(sha256)), {ok, _} = file:position(__H, __Cur), {ok, string:lowercase(binary:encode_hex(__Digest))} end end)($0)""", result: true),
    .Wasm(body: hashWasm),
)]
declare fn rawHash(handle: unknown) -> Result<string, HostError>;

// Write `bytes` at the handle's position; answers how many.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __b = $1; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return __b.length })()""", result: true),
    .Erlang("""(fun(__H, __B) -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeWasm),
)]
declare fn rawWrite(handle: unknown, bytes: bytes) -> Result<i32, HostError>;

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; if (!__h.mem) require('fs').closeSync(__h.fd); return 0 })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, _, _} -> {ok, 0}; _ -> case file:close(__H) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: closeWasm),
)]
declare fn rawClose(handle: unknown) -> Result<i32, HostError>;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeTextWasm),
)]
declare fn rawWriteText(
    path: string,
    contents: string,
) -> Result<i32, HostError>;

// Whether a path exists, of any kind: a regular file, a directory, a
// character or block device (`/dev/null`), a FIFO or a socket. A symbolic
// link is followed — one whose target is missing is `false`, the answer
// every read through it would give.
// Node: `require('fs').existsSync($0)` (a `stat`).
// Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
// replaces, answers only regular files and directories, so `/dev/null`
// was `false` on erlang and `true` on commonJS).
#[compiler.external(
    .JavaScript("""require('fs').existsSync($0)"""),
    .Erlang("""(case file:read_file_info($0) of {ok, _} -> true; _ -> false end)"""),
    .Wasm(body: existsWasm),
)]
pub declare fn exists(path: string) -> bool;

// List the names of the directory entries at `path` (relative).
// Node: `require('fs').readdirSync($0)`.
// Erlang: `file:list_dir/1` returns `{ok, [string()]}`, in the directory's
// order: sorted here by bytes (`lists:sort` on binaries), as `readdirSync` and
// wasm's `listWasm` answer them, so every target lists one order (decision 992).
#[compiler.external(
    .JavaScript("""(() => { return require('fs').readdirSync($0) })()""", result: true),
    .Erlang("""(fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, lists:sort([list_to_binary(__N) || __N <- __L])}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: listWasm),
)]
declare fn rawList(path: string) -> Result<string[], HostError>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents.
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').mkdirSync($0); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: mkdirWasm),
)]
declare fn rawMkdir(path: string) -> Result<i32, HostError>;

// Create the directory at `path` and every missing directory above it. A
// directory that is already there is `Ok` too; a path that exists as anything
// else (a file) is an `Error`. What the snapshot library (`snap`) makes the
// directory of a `.snap` with (decision 391).
// Node: `require('fs').mkdirSync($0, { recursive: true })`.
// Erlang: `filelib:ensure_path/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').mkdirSync($0, { recursive: true }); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: mkdirRecursiveWasm),
)]
declare fn rawMkdirRecursive(path: string) -> Result<i32, HostError>;

// Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
// both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
// a `read_link_info`, so the variant is the same); `removeTree` removes one.
// Node: `require('fs').rmSync($0)`.
// Erlang: `file:delete/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').rmSync($0); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, eisdir}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: rmWasm),
)]
declare fn rawRm(path: string) -> Result<i32, HostError>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[compiler.external(
    .JavaScript("""(() => { require('fs').copyFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: copyWasm),
)]
declare fn rawCopy(src: string, dest: string) -> Result<i32, HostError>;

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
#[compiler.external(
    .JavaScript("""(() => { const __s = require('fs').statSync($0, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { size: __c(__s.size), mtime: __c(((__ns - (((__ns % 1000000000n) + 1000000000n) % 1000000000n)) / 1000000000n) * 1000n), isDir: __s.isDirectory() } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: statWasm),
)]
declare fn rawStat(path: string) -> Result<FileStat, HostError>;

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
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync($0, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; const __dng = []; for (const __f of __all) { const __s = __fs.statSync(__p.join($0, __f), { throwIfNoEntry: false }); if (__s === undefined) { __dng.push(__f); continue } if (__s.isFile()) __out.push(__f) } return { files: __out, dangling: __dng } })()""", result: true),
    .Erlang("""(fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> erlang:error(__E); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> erlang:error(__X) end end, __Acc, __Names) end end, __Found = __Walk(__Root, [], []), {ok, #{files => lists:sort([__F || {file, __F} <- __Found]), dangling => lists:sort([__D || {dangling, __D} <- __Found])}} end end)($0)""", result: true),
    .Wasm(body: walkWasm),
)]
declare fn rawWalk(root: string) -> Result<Walked, HostError>;

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
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = require('path'); const __root = $1; const __pat = String($0); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() })()"""),
    .Erlang("""(fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))] end)($0, $1)"""),
    .Wasm(body: globWasm),
)]
declare fn rawGlob(pattern: string, root: string) -> string[];

// Remove `path` and everything under it: a file, a link (the link, never its
// target) or a directory tree. A path that is not there is `Ok` too — the
// caller wanted it gone. What a test fixture is cleared with, and what the
// snapshot engine's tests clear their scratch directories with (1.0.11-beta
// front 97).
// Node: `rmSync(path, { recursive: true, force: true })`.
// Erlang: `file:del_dir_r/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').rmSync($0, { recursive: true, force: true }); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: removeTreeWasm),
)]
declare fn rawRemoveTree(path: string) -> Result<i32, HostError>;

// Internal, test scaffolding: a fresh, unique, empty directory under the
// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
// one of these and removes it with `removeTree`, so a run leaves nothing under
// the host's tmpdir.
#[compiler.external(
    .JavaScript("""require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'))"""),
    .Erlang("""(fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)()"""),
    .Wasm(body: scratchDirWasm),
)]
declare fn scratchDir() -> string;

// Internal, test scaffolding: the working directory (what a relative root is
// read against) and a symbolic link `link` → `target`.
#[compiler.external(
    .JavaScript("process.cwd()"),
    .Erlang("""(fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)()"""),
    .Wasm(body: workingDirWasm),
)]
declare fn workingDir() -> string;

#[compiler.external(
    .JavaScript("""require('fs').symlinkSync($0, $1)"""),
    .Erlang("""(fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)($0, $1)"""),
    .Wasm(body: linkToWasm),
)]
declare fn linkTo(target: string, link: string) -> void;

// ── the typed error ──────────────────────────────────────────────────────────

// The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.
fn fsError(path: string, e: HostError) -> FsError {
    val u = e.message.toUpper();
    if (u.startsWith("ENOENT")) return FsError.NotFound(path: path);
    if (u.startsWith("EACCES") || u.startsWith("EPERM"))
        return FsError.PermissionDenied(path: path);
    if (u.startsWith("EISDIR") || u.startsWith("PATH IS A DIRECTORY"))
        return FsError.IsDirectory(path: path);
    if (u.startsWith("ENOTDIR")) return FsError.NotDirectory(path: path);
    if (u.startsWith("EEXIST")) return FsError.AlreadyExists(path: path);
    return FsError.Other(path: path, message: e.message);
}

// A host cell's answer, its failure read as an `FsError` of `path`.
fn lift<T>(path: string, r: Result<T, HostError>) -> Result<T, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

// `lift` for each answer type: the generic one is the wasm backend's to specialise, and a
// `bytes` or a handle it does not (decision 992).
fn liftBytes(path: string, r: Result<bytes, HostError>) -> Result<bytes, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftI32(path: string, r: Result<i32, HostError>) -> Result<i32, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftI64(path: string, r: Result<i64, HostError>) -> Result<i64, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftString(path: string, r: Result<string, HostError>) -> Result<string, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftStrings(path: string, r: Result<string[], HostError>) -> Result<string[], FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftStat(path: string, r: Result<FileStat, HostError>) -> Result<FileStat, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftWalked(path: string, r: Result<Walked, HostError>) -> Result<Walked, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftHandle(path: string, r: Result<unknown, HostError>) -> Result<unknown, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

// The text of `b`, or `InvalidUtf8` at the first invalid byte.
fn decode(path: string, b: bytes) -> Result<string, FsError> {
    val offset = utf8Offset(b);
    if (offset >= 0l) throw FsError.InvalidUtf8(path: path, offset: offset);
    return b.toUtf8().unwrapOr("");
}

// What `rawWalk` finds under a root: the regular files, and the links whose
// target is missing, both as paths relative to the root, sorted.
type Walked(
    files: string[],
    dangling: string[],
)

// Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.
#[compiler.external(
    .JavaScript("""(($0).mem != null)"""),
    .Erlang("""(case $0 of {mem, _, _} -> true; _ -> false end)"""),
    .Wasm(body: readOnlyWasm),
)]
declare fn rawReadOnly(handle: unknown) -> bool;

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.
pub fn readBytes(path: string) -> Result<bytes, FsError> {
    val b = try liftBytes(path, rawReadBytes(path));
    return b;
}

// The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
// target — never node's silent U+FFFD nor erlang's unchecked binary.
pub fn readText(path: string) -> Result<string, FsError> {
    val b = try readBytes(path);
    val s = try decode(path, b);
    return s;
}

// Write `contents` to `path`, creating or truncating.
pub fn writeBytes(path: string, contents: bytes) -> Result<i32, FsError> {
    val n = try liftI32(path, rawWriteBytes(path, contents));
    return n;
}

pub fn writeText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawWriteText(path, contents));
    return n;
}

// Append `contents`, creating the file when it is not there.
pub fn appendText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawAppendText(path, contents));
    return n;
}

// ── metadata and directories ─────────────────────────────────────────────────

pub fn stat(path: string) -> Result<FileStat, FsError> {
    val s = try liftStat(path, rawStat(path));
    return s;
}

pub fn list(path: string) -> Result<string[], FsError> {
    val names = try liftStrings(path, rawList(path));
    return names;
}

pub fn mkdir(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawMkdir(path));
    return n;
}

pub fn mkdirRecursive(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawMkdirRecursive(path));
    return n;
}

pub fn rm(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawRm(path));
    return n;
}

pub fn removeTree(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawRemoveTree(path));
    return n;
}

pub fn copy(src: string, dest: string) -> Result<i32, FsError> {
    val n = try liftI32(src, rawCopy(src, dest));
    return n;
}

pub fn walk(root: string) -> Result<string[], FsError> {
    val found = try liftWalked(root, rawWalk(root));
    if (found.dangling.length > 0) {
        val first = found.dangling.at(0) ?? "";
        throw FsError.Other(path: root, message: ["fs.walk: dangling link \"", first, "\""].join(""));
    }
    return found.files;
}

pub fn glob(pattern: string, root: string) -> Result<string[], FsError> {
    return rawGlob(pattern, root);
}

// The host's handle over embedded bytes: read like a file, never closed on disk.
#[compiler.external(
    .JavaScript("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })"""),
    .Erlang("""{mem, $0, counters:new(1, [])}"""),
    .Wasm(body: memHandleWasm),
)]
declare fn memoryHandle(bytes: bytes) -> unknown;

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
    pub fn size(self: Self) -> Result<i64, FsError> {
        val n = try liftI64(self.location, rawSize(self.handle, self.location));
        return n;
    }

    // Up to `n` bytes from the position; empty at the end of the file.
    pub fn read(self: Self, n: i32) -> Result<bytes, FsError> {
        if (n <= 0) return bytes.fromUtf8("");
        val b = try liftBytes(self.location, rawRead(self.handle, n));
        return b;
    }

    // Every byte from the position to the end.
    pub fn bytes(self: Self) -> Result<bytes, FsError> {
        val b = try liftBytes(self.location, rawReadAll(self.handle));
        return b;
    }

    // The rest of the file as UTF-8 text (`InvalidUtf8` otherwise).
    pub fn text(self: Self) -> Result<string, FsError> {
        val b = try self.bytes();
        val s = try decode(self.location, b);
        return s;
    }

    // The rest of the file in pieces of at most `size` bytes. An error ends the stream.
    pub async iter fn chunks(self: Self, size: i32 = 65536) -> AsyncIter<Result<bytes, FsError>> {
        while (true) {
            val b = try self.read(size);
            if (b.length == 0) break;
            yield b;
        }
    }

    // The rest of the file line by line, `\n` and `\r\n` stripped. A line that is not
    // UTF-8 ends the stream with `InvalidUtf8`, its offset counted from the first
    // line this call read.
    pub async iter fn lines(self: Self) -> AsyncIter<Result<string, FsError>> {
        var consumed = 0;
        while (true) {
            val raw = try liftBytes(self.location, rawReadLine(self.handle));
            if (raw.length == 0) break;
            val line = stripEol(raw);
            val offset = utf8Offset(line);
            if (offset >= 0l)
                throw FsError.InvalidUtf8(path: self.location, offset: consumed.toI64()
                    + offset);
            val width: i32 = raw.length;
            consumed = consumed + width;
            yield line.toUtf8().unwrapOr("");
        }
    }

    // The SHA-256 of the whole file, lowercase hex.
    pub fn hash(self: Self) -> Result<string, FsError> {
        val h = try liftString(self.location, rawHash(self.handle));
        return h;
    }

    // Write `b` at the position; answers the number of bytes written.
    pub fn write(self: Self, b: bytes) -> Result<i32, FsError> {
        if (rawReadOnly(self.handle))
            throw FsError.Other(path: self.location, message: "the file is open for reading");
        val n = try liftI32(self.location, rawWrite(self.handle, b));
        return n;
    }

    // Close the file. Closing twice is harmless; a failure to close is not reported.
    pub fn close(self: Self) -> void {
        val closed = rawClose(self.handle);
    }
}

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.
pub fn open(path: string) -> Result<File, FsError> {
    val h = try liftHandle(path, rawOpen(path));
    return File(location: path, handle: h);
}

// Open the file at `path` for writing: created, or truncated.
pub fn create(path: string) -> Result<File, FsError> {
    val h = try liftHandle(path, rawCreate(path));
    return File(location: path, handle: h);
}

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
// like a file on disk — no `Result`, the build proved the file exists — and
// closing it is a no-op.
pub fn openAsset(asset: Asset) -> File {
    return File(location: asset.path, handle: memoryHandle(asset.bytes));
}

// ── the wasm bodies (decision 992) ───────────────────────────────────────────
// `io.fs` on wasm answers what it answers on commonJS, erlang and beam: the same functions
// over the file system of the process, the same paths (a relative one is read against the
// working directory, an absolute one as it is), the same answers and the same errors. The
// host is `wasi:filesystem`, reached through std-wasm's leaves (`modules/std-wasm/wat/fs.wat`;
// the `wasi…` declarations below), which the runner serves with the root and the working
// directory preopened (`needs: [.Filesystem]`, no flag). A leaf answers a host failure as
// `-(1 + code)`, `code` the ordinal of `wasi:filesystem`'s `error-code`, or as the `Error`
// of a `Result<_, i32>` holding the code; `wasiError` writes it as Node's text
// (`ENOENT: …`), which `fsError` reads as it reads every target's.

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.cwd", needs: [.Filesystem]),
)]
declare fn wasiCwd() -> string;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.getenv", needs: [.Filesystem]),
)]
declare fn wasiGetenv(name: string) -> string;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.open", needs: [.Filesystem]),
)]
declare fn wasiOpen(path: string, mode: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.openMem", needs: [.Filesystem]),
)]
declare fn wasiOpenMem(data: bytes) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.close", needs: [.Filesystem]),
)]
declare fn wasiClose(block: i32) -> void;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.isMem", needs: [.Filesystem]),
)]
declare fn wasiIsMem(block: i32) -> bool;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.tell", needs: [.Filesystem]),
)]
declare fn wasiTell(block: i32) -> i64;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.seek", needs: [.Filesystem]),
)]
declare fn wasiSeek(block: i32, position: i64) -> void;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.size", needs: [.Filesystem]),
)]
declare fn wasiSize(block: i32) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.sizeRaw", needs: [.Filesystem]),
)]
declare fn wasiSizeRaw(block: i32) -> i64;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.read", needs: [.Filesystem]),
)]
declare fn wasiRead(block: i32, n: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.readAll", needs: [.Filesystem]),
)]
declare fn wasiReadAll(block: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.readLine", needs: [.Filesystem]),
)]
declare fn wasiReadLine(block: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.write", needs: [.Filesystem]),
)]
declare fn wasiWrite(block: i32, data: bytes) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statKind", needs: [.Filesystem]),
)]
declare fn wasiStatKind(path: string, follow: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statSize", needs: [.Filesystem]),
)]
declare fn wasiStatSize(path: string) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statMtime", needs: [.Filesystem]),
)]
declare fn wasiStatMtime(path: string) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.list", needs: [.Filesystem]),
)]
declare fn wasiList(path: string) -> Result<string[], i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.mkdir", needs: [.Filesystem]),
)]
declare fn wasiMkdir(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.rmdir", needs: [.Filesystem]),
)]
declare fn wasiRmdir(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.unlink", needs: [.Filesystem]),
)]
declare fn wasiUnlink(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.symlink", needs: [.Filesystem]),
)]
declare fn wasiSymlink(target: string, link: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "bytes.at"),
)]
declare fn wasiByteAt(data: bytes, index: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "hash.sha256Hex"),
)]
declare fn wasiSha256(data: bytes) -> string;

// The POSIX name of the host's error `code`, and its text.
fn wasiName(code: i32) -> string {
    val names = [
        "EACCES", "EAGAIN", "EALREADY", "EBADF", "EBUSY", "EDEADLK", "EDQUOT", "EEXIST",
        "EFBIG", "EILSEQ", "EINPROGRESS", "EINTR", "EINVAL", "EIO", "EISDIR", "ELOOP",
        "EMLINK", "EMSGSIZE", "ENAMETOOLONG", "ENODEV", "ENOENT", "ENOLCK", "ENOMEM",
        "ENOSPC", "ENOTDIR", "ENOTEMPTY", "ENOTRECOVERABLE", "ENOTSUP", "ENOTTY",
        "ENXIO", "EOVERFLOW", "EPERM", "EPIPE", "EROFS", "ESPIPE", "ETXTBSY", "EXDEV",
    ];
    return names.at(code) ?? "EIO";
}

fn wasiText(code: i32) -> string {
    val texts = [
        "permission denied", "resource temporarily unavailable",
        "connection already in progress", "bad file descriptor", "resource busy or locked",
        "resource deadlock avoided", "disk quota exceeded", "file already exists",
        "file too large", "illegal byte sequence", "operation in progress",
        "interrupted system call", "invalid argument", "i/o error",
        "illegal operation on a directory", "too many symbolic links encountered",
        "too many links", "message too long", "name too long", "no such device",
        "no such file or directory", "no locks available", "not enough memory",
        "no space left on device", "not a directory", "directory not empty",
        "state not recoverable", "operation not supported",
        "inappropriate ioctl for device", "no such device or address",
        "value too large for defined data type", "operation not permitted", "broken pipe",
        "read-only file system", "invalid seek", "text file busy",
        "cross-device link not permitted",
    ];
    return texts.at(code) ?? "i/o error";
}

// The `HostError` of the host's error `code`: `ENOENT: no such file or directory`.
fn wasiError(code: i32) -> HostError {
    return HostError(
        message: wasiName(code) + ": " + wasiText(code),
        kind: "host",
        name: HostErrorName.Error,
        detail: null,
    );
}

// The `Ok` of a leaf's answer, its `Error` the `HostError` of the code.
fn okBytes(r: Result<bytes, i32>) -> Result<bytes, HostError> {
    case r {
        Ok(b) -> return b;
        Error(code) -> throw wasiError(code);
    }
}

fn okStrings(r: Result<string[], i32>) -> Result<string[], HostError> {
    case r {
        Ok(xs) -> return xs;
        Error(code) -> throw wasiError(code);
    }
}

fn okSize(r: Result<i64, i32>) -> Result<i64, HostError> {
    case r {
        Ok(n) -> return n;
        Error(code) -> throw wasiError(code);
    }
}

// `path` without the slashes it begins with: the host reads a path relative to the root it preopens.
fn withoutRoot(path: string) -> string {
    var p = path;
    while (p.startsWith("/")) {
        p = p.slice(1);
    }
    return p;
}

// `name` inside `dir`, `dir` empty being the root.
fn joinPath(dir: string, name: string) -> string {
    if (dir == "") return name;
    return dir + "/" + name;
}

// `path` as the host reads it: absolute, as it is; relative, from the working directory. The empty
// path is no file (`ENOENT`), as it is on every target.
fn resolve(path: string) -> Result<string, HostError> {
    if (path == "") throw wasiError(20);
    if (path.startsWith("/")) return withoutRoot(path);
    val cwd = wasiCwd();
    if (cwd == "" || cwd == "/") return path;
    return withoutRoot(cwd + "/" + path);
}

// The file a handle holds: the handle block `rawOpen`, `rawCreate` and `memHandle` answered.
fn blockOf(handle: unknown) -> i32 {
    var block = 0;
    if (handle is i32) {
        val b: i32 = handle;
        block = b;
    }
    return block;
}

// Whether `a` sorts before `b` by the bytes of their UTF-8 (string `<` is not a wasm GC operation).
fn bytesBefore(a: string, b: string) -> bool {
    val x = bytes.fromUtf8(a);
    val y = bytes.fromUtf8(b);
    val nx = x.length();
    val ny = y.length();
    var i = 0;
    while (i < nx && i < ny) {
        val cx = wasiByteAt(x, i);
        val cy = wasiByteAt(y, i);
        if (cx != cy) return cx < cy;
        i = i + 1;
    }
    return nx < ny;
}

// The names sorted by the bytes of their UTF-8, none twice: what `readdirSync` answers on Node.
fn sortedStrings(xs: array<string>) -> array<string> {
    var out: array<string> = [];
    var i = 0;
    while (i < xs.length) {
        val x = xs.at(i) ?? "";
        i = i + 1;
        var j = 0;
        while (j < out.length && bytesBefore(out.at(j) ?? "", x)) {
            j = j + 1;
        }
        if (j < out.length && (out.at(j) ?? "") == x) continue;
        out = out.slice(0, j).append([x]).append(out.slice(j));
    }
    return out;
}

fn readBytesWasm(path: string) -> Result<bytes, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 0);
    if (h < 0) throw wasiError(-1 - h);
    val r = wasiReadAll(h);
    wasiClose(h);
    val b = try okBytes(r);
    return b;
}

fn writeBytesWasm(path: string, contents: bytes) -> Result<i32, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 1);
    if (h < 0) throw wasiError(-1 - h);
    val n = wasiWrite(h, contents);
    wasiClose(h);
    if (n < 0) throw wasiError(-1 - n);
    return 0;
}

fn writeTextWasm(path: string, contents: string) -> Result<i32, HostError> {
    val n = try writeBytesWasm(path, bytes.fromUtf8(contents));
    return n;
}

fn appendTextWasm(path: string, contents: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 2);
    if (h < 0) throw wasiError(-1 - h);
    val at = wasiSizeRaw(h);
    if (at < 0l) {
        wasiClose(h);
        throw wasiError(13);
    }
    wasiSeek(h, at);
    val n = wasiWrite(h, bytes.fromUtf8(contents));
    wasiClose(h);
    if (n < 0) throw wasiError(-1 - n);
    return 0;
}

// The offset of the first byte that starts a sequence that is not UTF-8, `-1` when there is none.
fn utf8OffsetWasm(data: bytes) -> i64 {
    val n = data.length();
    var i = 0;
    while (i < n) {
        val c = wasiByteAt(data, i);
        if (c < 128) {
            i = i + 1;
            continue;
        }
        var k = 0;
        if (c >= 194 && c <= 223) {
            k = 1;
        } else if (c >= 224 && c <= 239) {
            k = 2;
        } else if (c >= 240 && c <= 244) {
            k = 3;
        } else {
            return i.toI64();
        }
        if (i + k >= n) return i.toI64();
        var lo = 128;
        var hi = 191;
        if (c == 224) {
            lo = 160;
        } else if (c == 237) {
            hi = 159;
        } else if (c == 240) {
            lo = 144;
        } else if (c == 244) {
            hi = 143;
        }
        val d = wasiByteAt(data, i + 1);
        if (d < lo || d > hi) return i.toI64();
        var j = 2;
        while (j <= k) {
            val e = wasiByteAt(data, i + j);
            if (e < 128 || e > 191) return i.toI64();
            j = j + 1;
        }
        i = i + k + 1;
    }
    return -1l;
}

fn stripEolWasm(line: bytes) -> bytes {
    var n = line.length();
    if (n > 0 && wasiByteAt(line, n - 1) == 10) {
        n = n - 1;
        if (n > 0 && wasiByteAt(line, n - 1) == 13) n = n - 1;
    }
    return line.slice(0, n);
}

fn openWasm(path: string) -> Result<unknown, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 0);
    if (h < 0) throw wasiError(-1 - h);
    val handle: unknown = h;
    return handle;
}

fn createWasm(path: string) -> Result<unknown, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 1);
    if (h < 0) throw wasiError(-1 - h);
    val handle: unknown = h;
    return handle;
}

fn memHandleWasm(data: bytes) -> unknown {
    val handle: unknown = wasiOpenMem(data);
    return handle;
}

fn sizeWasm(handle: unknown, path: string) -> Result<i64, HostError> {
    val n = try okSize(wasiSize(blockOf(handle)));
    return n;
}

fn readWasm(handle: unknown, n: i32) -> Result<bytes, HostError> {
    val b = try okBytes(wasiRead(blockOf(handle), n));
    return b;
}

fn readAllWasm(handle: unknown) -> Result<bytes, HostError> {
    val b = try okBytes(wasiReadAll(blockOf(handle)));
    return b;
}

fn readLineWasm(handle: unknown) -> Result<bytes, HostError> {
    val b = try okBytes(wasiReadLine(blockOf(handle)));
    return b;
}

// The SHA-256 of the whole file, the position where it was.
fn hashWasm(handle: unknown) -> Result<string, HostError> {
    val block = blockOf(handle);
    val at = wasiTell(block);
    wasiSeek(block, 0l);
    val r = wasiReadAll(block);
    wasiSeek(block, at);
    val b = try okBytes(r);
    return wasiSha256(b);
}

fn writeWasm(handle: unknown, data: bytes) -> Result<i32, HostError> {
    val n = wasiWrite(blockOf(handle), data);
    if (n < 0) throw wasiError(-1 - n);
    return n;
}

fn closeWasm(handle: unknown) -> Result<i32, HostError> {
    wasiClose(blockOf(handle));
    return 0;
}

fn readOnlyWasm(handle: unknown) -> bool {
    return wasiIsMem(blockOf(handle));
}

fn existsWasm(path: string) -> bool {
    return case resolve(path) {
        Ok(p) -> wasiStatKind(p, 1) >= 0;
        Error(_) -> false;
    };
}

fn listWasm(path: string) -> Result<string[], HostError> {
    val p = try resolve(path);
    val names = try okStrings(wasiList(p));
    return sortedStrings(names);
}

fn mkdirWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val r = wasiMkdir(p);
    if (r < 0) throw wasiError(-1 - r);
    return 0;
}

// The directory and every missing one above it. One that is there is `Ok`; a file in the way is
// `EEXIST` when it is the directory asked for, `ENOTDIR` when it is above it.
fn mkdirRecursiveWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    var parts: array<string> = [];
    val pieces = p.split("/");
    var i = 0;
    while (i < pieces.length) {
        val piece = pieces.at(i) ?? "";
        i = i + 1;
        if (piece != "" && piece != ".") parts = parts.append([piece]);
    }
    var prefix = "";
    var k = 0;
    while (k < parts.length) {
        prefix = joinPath(prefix, parts.at(k) ?? "");
        k = k + 1;
        val kind = wasiStatKind(prefix, 1);
        if (kind == 3) continue;
        if (kind >= 0) {
            if (k == parts.length) throw wasiError(7);
            throw wasiError(24);
        }
        val made = wasiMkdir(prefix);
        if (made < 0) throw wasiError(-1 - made);
    }
    return 0;
}

// The FILE at `path`: a directory is `EISDIR`, whatever it holds.
fn rmWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val kind = wasiStatKind(p, 0);
    if (kind < 0) throw wasiError(-1 - kind);
    if (kind == 3) throw wasiError(14);
    val r = wasiUnlink(p);
    if (r < 0) throw wasiError(-1 - r);
    return 0;
}

fn copyWasm(src: string, dest: string) -> Result<i32, HostError> {
    val contents = try readBytesWasm(src);
    val written = try writeBytesWasm(dest, contents);
    return 0;
}

fn statWasm(path: string) -> Result<FileStat, HostError> {
    val p = try resolve(path);
    val kind = wasiStatKind(p, 1);
    if (kind < 0) throw wasiError(-1 - kind);
    val size = try okSize(wasiStatSize(p));
    val seconds = try okSize(wasiStatMtime(p));
    return FileStat(size: size, mtime: seconds * 1000l, isDir: kind == 3);
}

// The regular files under `root` and the links whose target is missing, as paths relative to it, in
// directory order: a work list of directories, not a recursion (a recursive `try` is not lowered on wasm).
fn walkWasm(root: string) -> Result<Walked, HostError> {
    val p = try resolve(root);
    val kind = wasiStatKind(p, 1);
    if (kind < 0) throw wasiError(-1 - kind);
    if (kind != 3) throw wasiError(24);
    var dirs: array<string> = [p];
    var rels: array<string> = [""];
    var files: array<string> = [];
    var dangling: array<string> = [];
    var next = 0;
    while (next < dirs.length) {
        val dir = dirs.at(next) ?? "";
        val rel = rels.at(next) ?? "";
        next = next + 1;
        val names = try okStrings(wasiList(dir));
        var i = 0;
        while (i < names.length) {
            val name = names.at(i) ?? "";
            i = i + 1;
            val full = joinPath(dir, name);
            val sub = joinPath(rel, name);
            val entry = wasiStatKind(full, 1);
            if (entry < 0 && entry != -21) throw wasiError(-1 - entry);
            if (entry == 3) {
                dirs = dirs.append([full]);
                rels = rels.append([sub]);
            }
            if (entry == 6) files = files.append([sub]);
            if (entry == -21) dangling = dangling.append([sub]);
        }
    }
    return Walked(files: sortedStrings(files), dangling: sortedStrings(dangling));
}

// Whether the segment holds a wildcard.
fn isMagic(seg: string) -> bool {
    return seg.contains("*") || seg.contains("?") || seg.contains("[") || seg.contains("{");
}

// A segment with its `{a,b}` alternatives written out, nested ones too; one that is never closed is a name.
fn expandBraces(seg: string) -> array<string> {
    val cs = seg.chars();
    var open = -1;
    var i = 0;
    while (i < cs.length) {
        if ((cs.at(i) ?? "") == "{") {
            open = i;
            break;
        }
        i = i + 1;
    }
    if (open < 0) return [seg];
    var depth = 0;
    var close = -1;
    var cuts: array<i32> = [];
    var j = open;
    var closed = false;
    while (j < cs.length && !closed) {
        val c = cs.at(j) ?? "";
        // Separate `if`s, not an `else if` chain: wasm's GC lowering refuses
        // an `if` nesting one beside an `else if` that appends (B-170).
        if (c == "{") depth = depth + 1;
        if (c == "}") depth = depth - 1;
        if (c == "}" && depth == 0) {
            close = j;
            closed = true;
        }
        if (c == "," && depth == 1) cuts = cuts.append([j]);
        j = j + 1;
    }
    if (close < 0) return [seg];
    val head = cs.slice(0, open).join("");
    val tail = cs.slice(close + 1).join("");
    var out: array<string> = [];
    var start = open + 1;
    var k = 0;
    while (k <= cuts.length) {
        var stop = close;
        if (k < cuts.length) stop = cuts.at(k) ?? close;
        val alt = cs.slice(start, stop).join("");
        out = out.append(expandBraces(head + alt + tail));
        start = stop + 1;
        k = k + 1;
    }
    return out;
}

// The `]` that closes the class opened at `at`, `-1` when there is none (the `[` is then a name).
fn classEnd(pat: array<string>, at: i32) -> i32 {
    var j = at + 1;
    if (j < pat.length && ((pat.at(j) ?? "") == "!" || (pat.at(j) ?? "") == "^")) j = j + 1;
    if (j < pat.length && (pat.at(j) ?? "") == "]") j = j + 1;
    while (j < pat.length) {
        if ((pat.at(j) ?? "") == "]") return j;
        j = j + 1;
    }
    return -1;
}

// Whether `ch` is in the class written between `first` and `stop` (`!` or `^` first negates it, `a-z` is a range).
fn classHas(pat: array<string>, first: i32, stop: i32, ch: string) -> bool {
    var i = first;
    var negate = false;
    if (i < stop && ((pat.at(i) ?? "") == "!" || (pat.at(i) ?? "") == "^")) {
        negate = true;
        i = i + 1;
    }
    var found = false;
    while (i < stop) {
        val lo = pat.at(i) ?? "";
        if (i + 2 < stop && (pat.at(i + 1) ?? "") == "-") {
            val hi = pat.at(i + 2) ?? "";
            // By code point: a class range is one character each side, and
            // wasm lowers no ordering of strings (B-170).
            val c = ch.charCodeAt(0);
            if (lo.charCodeAt(0) <= c && c <= hi.charCodeAt(0)) found = true;
            i = i + 3;
        } else {
            if (lo == ch) found = true;
            i = i + 1;
        }
    }
    return found != negate;
}

// `name` against one pattern without braces: `*`, `?`, `[…]`.
fn globMatch(pat: array<string>, begin: i32, name: array<string>, offset: i32) -> bool {
    var p = begin;
    var n = offset;
    while (p < pat.length) {
        val c = pat.at(p) ?? "";
        if (c == "*") {
            while (p < pat.length && (pat.at(p) ?? "") == "*") {
                p = p + 1;
            }
            if (p == pat.length) return true;
            var k = n;
            while (k <= name.length) {
                if (globMatch(pat, p, name, k)) return true;
                k = k + 1;
            }
            return false;
        }
        if (n >= name.length) return false;
        val ch = name.at(n) ?? "";
        if (c == "?") {
            p = p + 1;
            n = n + 1;
        } else if (c == "[") {
            val end = classEnd(pat, p);
            if (end < 0) {
                if (ch != "[") return false;
                p = p + 1;
                n = n + 1;
            } else {
                if (!classHas(pat, p + 1, end, ch)) return false;
                p = end + 1;
                n = n + 1;
            }
        } else {
            if (c != ch) return false;
            p = p + 1;
            n = n + 1;
        }
    }
    return n == name.length;
}

fn segmentMatches(seg: string, name: string) -> bool {
    val alts = expandBraces(seg);
    val chars = name.chars();
    var i = 0;
    while (i < alts.length) {
        if (globMatch((alts.at(i) ?? "").chars(), 0, chars, 0)) return true;
        i = i + 1;
    }
    return false;
}

// The names in `dir` the segment matches; a dot name only when the segment itself begins with the dot.
fn globNames(dir: string, seg: string) -> array<string> {
    val listed: array<string> = case wasiList(dir) {
        Ok(xs) -> xs;
        Error(_) -> [];
    };
    var out: array<string> = [];
    var i = 0;
    while (i < listed.length) {
        val name = listed.at(i) ?? "";
        i = i + 1;
        if (name.startsWith(".") && !seg.startsWith(".")) continue;
        if (seg == "*" || segmentMatches(seg, name)) out = out.append([name]);
    }
    return out;
}

// The entries `segs` from `i` match under `dir` (`rel` its path from the root of the glob), added to `out`. A
// wildcard continues into real directories only; a name goes through a link.
fn globWalk(segs: array<string>, i: i32, dir: string, rel: string, out: array<string>) -> array<string> {
    var acc = out;
    if (i == segs.length) {
        if (rel != "") acc = acc.append([rel]);
        return acc;
    }
    val seg = segs.at(i) ?? "";
    val last = i == segs.length - 1;
    if (seg == "**") {
        if (!last) acc = globWalk(segs, i + 1, dir, rel, acc);
        val names = globNames(dir, "*");
        var k = 0;
        while (k < names.length) {
            val name = names.at(k) ?? "";
            k = k + 1;
            val full = joinPath(dir, name);
            val sub = joinPath(rel, name);
            if (last) acc = acc.append([sub]);
            if (wasiStatKind(full, 0) == 3) acc = globWalk(segs, i, full, sub, acc);
        }
        return acc;
    }
    if (!isMagic(seg)) {
        val full = joinPath(dir, seg);
        val sub = joinPath(rel, seg);
        if (last) {
            if (wasiStatKind(full, 0) >= 0) acc = acc.append([sub]);
        } else if (wasiStatKind(full, 1) == 3) {
            acc = globWalk(segs, i + 1, full, sub, acc);
        }
        return acc;
    }
    val names = globNames(dir, seg);
    var k = 0;
    while (k < names.length) {
        val name = names.at(k) ?? "";
        k = k + 1;
        val full = joinPath(dir, name);
        val sub = joinPath(rel, name);
        if (last) {
            acc = acc.append([sub]);
        } else if (wasiStatKind(full, 0) == 3) {
            acc = globWalk(segs, i + 1, full, sub, acc);
        }
    }
    return acc;
}

fn globWasm(pattern: string, root: string) -> string[] {
    val resolved = resolve(root);
    if (resolved.isError()) return [];
    val base = resolved.unwrapOr("");
    var segs: array<string> = [];
    val pieces = pattern.split("/");
    var i = 0;
    while (i < pieces.length) {
        val piece = pieces.at(i) ?? "";
        i = i + 1;
        if (piece != "" && piece != ".") segs = segs.append([piece]);
    }
    val found = globWalk(segs, 0, base, "", []);
    var kept: array<string> = [];
    var k = 0;
    while (k < found.length) {
        val entry = found.at(k) ?? "";
        k = k + 1;
        if (!pattern.endsWith("/") || wasiStatKind(joinPath(base, entry), 0) == 3) kept = kept.append([entry]);
    }
    return sortedStrings(kept);
}

// A path that is not there is `Ok`: the caller wanted it gone. A link is removed, never followed. The
// directories are found first, then the files removed, then the directories from the deepest.
fn removeTreeWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val top = wasiStatKind(p, 0);
    if (top == -21) return 0;
    if (top < 0) throw wasiError(-1 - top);
    if (top != 3) {
        val r = wasiUnlink(p);
        if (r < 0) throw wasiError(-1 - r);
        return 0;
    }
    var dirs: array<string> = [p];
    var next = 0;
    while (next < dirs.length) {
        val dir = dirs.at(next) ?? "";
        next = next + 1;
        val names = try okStrings(wasiList(dir));
        var i = 0;
        while (i < names.length) {
            val full = joinPath(dir, names.at(i) ?? "");
            i = i + 1;
            val kind = wasiStatKind(full, 0);
            if (kind < 0 && kind != -21) throw wasiError(-1 - kind);
            if (kind == 3) dirs = dirs.append([full]);
            if (kind >= 0 && kind != 3) {
                val r = wasiUnlink(full);
                if (r < 0) throw wasiError(-1 - r);
            }
        }
    }
    var k = dirs.length;
    while (k > 0) {
        k = k - 1;
        val r = wasiRmdir(dirs.at(k) ?? "");
        if (r < 0) throw wasiError(-1 - r);
    }
    return 0;
}

// A fresh, unique, empty directory under the host's temporary directory.
fn scratchDirWasm() -> string {
    var base = wasiGetenv("TMPDIR");
    if (base == "") base = "/tmp";
    var attempt = 0;
    while (attempt < 100) {
        val dir = base + "/bp-std-fs-" + random.randomBytes(6);
        if (wasiMkdir(withoutRoot(dir)) == 0) return dir;
        attempt = attempt + 1;
    }
    failure.panic("io.fs: no scratch directory could be made");
    return base;
}

fn workingDirWasm() -> string {
    val cwd = wasiCwd();
    if (cwd == "") return "/";
    return cwd;
}

fn linkToWasm(target: string, link: string) -> void {
    val l = resolve(link);
    if (l.isError()) failure.panic("io.fs: no link path");
    val r = wasiSymlink(target, l.unwrapOr(""));
    if (r < 0) failure.panic(wasiError(-1 - r).message);
    return;
}

// A host without `chmod` denies this user nothing: the permission tests have nothing to check there.
fn denyAllWasm(path: string) -> bool {
    return false;
}

fn allowAllWasm(path: string) -> void {
    return;
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
fn variantOf<T>(r: Result<T, FsError>) -> string {
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
    writeBytes(path, bytes
        .fromUtf8("ok")
        .concat(bytes.fromUtf8("é").slice(0, 1))
        .concat(bytes.fromUtf8("z")));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 2";
    assert readBytes(path).isOk();
    // A sequence cut short at the end of the file.
    writeBytes(path, bytes.fromUtf8("é").slice(0, 1));
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
    return File(location: "", handle: memHandle(bytes.fromUtf8("")));
}

test "fs.File writes, then reads bytes, text, a size and a hash" {
    val dir = scratchDir();
    val path = [dir, "/data.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(bytes.fromUtf8("hello ")).unwrapOr(-1) == 6;
    assert w.write(bytes.fromUtf8("world")).unwrapOr(-1) == 5;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.path() == path;
    assert r.size().unwrapOr(-1l) == 11l;
    assert r.read(5).unwrapOr(bytes.fromUtf8("")).toUtf8().unwrapOr("")
        == "hello";
    assert r.text().unwrapOr("") == " world";
    assert r.read(5).unwrapOr(bytes.fromUtf8("x")).length == 0;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
    r.close();
    removeTree(dir);
}

test "fs.File's hash leaves the position where it was" {
    val dir = scratchDir();
    val path = [dir, "/pos.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(bytes.fromUtf8("hello world")).unwrapOr(-1) == 11;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.read(5).unwrapOr(bytes.fromUtf8("")).length == 5;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
    assert r.text().unwrapOr("") == " world";
    r.close();
    removeTree(dir);
}

// Internal, test scaffolding: take every permission from `path`; whether that
// denies this user anything (root is denied nothing), and give them back.
#[compiler.external(
    .JavaScript("""(() => { require('fs').chmodSync($0, 0); return typeof process.getuid === 'function' ? process.getuid() !== 0 : false })()"""),
    .Erlang("""(fun(__P) -> ok = file:change_mode(__P, 0), string:trim(os:cmd("id -u")) =/= "0" end)($0)"""),
    .Wasm(body: denyAllWasm),
)]
declare fn denyAll(path: string) -> bool;

#[compiler.external(
    .JavaScript("""require('fs').chmodSync($0, 0o700)"""),
    .Erlang("""(fun(__P) -> ok = file:change_mode(__P, 8#700), ok end)($0)"""),
    .Wasm(body: allowAllWasm),
)]
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
-export([readBytes/1, readText/1, writeBytes/2, writeText/2, appendText/2, stat/1, list/1, mkdir/1, mkdirRecursive/1, rm/1, removeTree/1, copy/2, walk/1, glob/2, open/1, create/1, openAsset/1, exists/1, liftI64/2, liftBytes/2, decode/2, liftString/2, liftI32/2, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__fsError'/2, '__bp_priv__lift'/2, '__bp_priv__liftStrings'/2, '__bp_priv__liftStat'/2, '__bp_priv__liftWalked'/2, '__bp_priv__liftHandle'/2, '__bp_priv__wasiName'/1, '__bp_priv__wasiText'/1, '__bp_priv__wasiError'/1, '__bp_priv__okBytes'/1, '__bp_priv__okStrings'/1, '__bp_priv__okSize'/1, '__bp_priv__withoutRoot'/1, '__bp_priv__joinPath'/2, '__bp_priv__resolve'/1, '__bp_priv__blockOf'/1, '__bp_priv__bytesBefore'/2, '__bp_priv__sortedStrings'/1, '__bp_priv__readBytesWasm'/1, '__bp_priv__writeBytesWasm'/2, '__bp_priv__writeTextWasm'/2, '__bp_priv__appendTextWasm'/2, '__bp_priv__utf8OffsetWasm'/1, '__bp_priv__stripEolWasm'/1, '__bp_priv__openWasm'/1, '__bp_priv__createWasm'/1, '__bp_priv__memHandleWasm'/1, '__bp_priv__sizeWasm'/2, '__bp_priv__readWasm'/2, '__bp_priv__readAllWasm'/1, '__bp_priv__readLineWasm'/1, '__bp_priv__hashWasm'/1, '__bp_priv__writeWasm'/2, '__bp_priv__closeWasm'/1, '__bp_priv__readOnlyWasm'/1, '__bp_priv__existsWasm'/1, '__bp_priv__listWasm'/1, '__bp_priv__mkdirWasm'/1, '__bp_priv__mkdirRecursiveWasm'/1, '__bp_priv__rmWasm'/1, '__bp_priv__copyWasm'/2, '__bp_priv__statWasm'/1, '__bp_priv__walkWasm'/1, '__bp_priv__isMagic'/1, '__bp_priv__expandBraces'/1, '__bp_priv__classEnd'/2, '__bp_priv__classHas'/4, '__bp_priv__globMatch'/4, '__bp_priv__segmentMatches'/2, '__bp_priv__globNames'/2, '__bp_priv__globWalk'/5, '__bp_priv__globWasm'/2, '__bp_priv__removeTreeWasm'/1, '__bp_priv__scratchDirWasm'/0, '__bp_priv__workingDirWasm'/0, '__bp_priv__linkToWasm'/2, '__bp_priv__denyAllWasm'/1, '__bp_priv__allowAllWasm'/1, '__bp_priv__statOr'/1, '__bp_priv__makeFixtureTree'/1, '__bp_priv__walkFixture'/1, '__bp_priv__walkFixtureFromCwd'/1, '__bp_priv__walkRefusal'/1, '__bp_priv__describe'/1, '__bp_priv__makeGlobTree'/1, '__bp_priv__globbed'/1, '__bp_priv__variantOf'/1, '__bp_priv__noFile'/0, '__bp_priv__string_slice'/3, '__bp_priv__array_slice'/3, '__bp_priv__bytes_slice'/3]).

%% behavior string

%% behavior bool

%% behavior array

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

%%% (`*Sync` on Node, blocking BIFs on Erlang, `wasi:filesystem` on wasm: the runner

%%% preopens the root and the working directory, decision 992), and a path is read as

%%% the process reads it — a relative one against the working directory — on every target.

%% import relative, HostError, HostErrorName, random

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

% Erlang: `file:list_dir/1` returns `{ok, [string()]}`, in the directory's

% order: sorted here by bytes (`lists:sort` on binaries), as `readdirSync` and

% wasm's `listWasm` answer them, so every target lists one order (decision 992).

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

% `lift` for each answer type: the generic one is the wasm backend's to specialise, and a

% `bytes` or a handle it does not (decision 992).

liftBytes(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

liftI32(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

liftI64(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

liftString(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

liftStrings(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

liftStat(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

liftWalked(Path, R) ->
    case R of
        {ok, V} ->
            {ok, V};
        {error, E} ->
            {error, fsError(Path, E)}
    end.

liftHandle(Path, R) ->
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
    case liftBytes(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
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
    case liftI32(Path, (fun(__BpA0, __BpA1) -> try ((fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

writeText(Path, Contents) ->
    case liftI32(Path, (fun(__BpA0, __BpA1) -> try ((fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

% Append `contents`, creating the file when it is not there.

appendText(Path, Contents) ->
    case liftI32(Path, (fun(__BpA0, __BpA1) -> try ((fun(__P, __C) -> case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path, Contents)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

% ── metadata and directories ─────────────────────────────────────────────────

stat(Path) ->
    case liftStat(Path, '__bp_adopt'((fun(__BpA0) -> try ((fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path), std@io@fs@@FileStat, [size, mtime, isDir])) of
        {ok, S} ->
            {ok, S};
        {error, _TryE0} -> {error, _TryE0}
    end.

list(Path) ->
    case liftStrings(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, lists:sort([list_to_binary(__N) || __N <- __L])}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, Names} ->
            {ok, Names};
        {error, _TryE0} -> {error, _TryE0}
    end.

mkdir(Path) ->
    case liftI32(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

mkdirRecursive(Path) ->
    case liftI32(Path, (fun(__BpA0) -> try ((fun(__P) -> case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

rm(Path) ->
    case liftI32(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, eisdir}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

removeTree(Path) ->
    case liftI32(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

copy(Src, Dest) ->
    case liftI32(Src, (fun(__BpA0, __BpA1) -> try ((fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Src, Dest)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

walk(Root) ->
    case liftWalked(Root, '__bp_adopt'((fun(__BpA0) -> try ((fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> erlang:error(__E); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> erlang:error(__X) end end, __Acc, __Names) end end, __Found = __Walk(__Root, [], []), {ok, #{files => lists:sort([__F || {file, __F} <- __Found]), dangling => lists:sort([__D || {dangling, __D} <- __Found])}} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Root), std@io@fs@@Walked, [files, dangling])) of
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
    case liftHandle(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:open(__P, [read, binary, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, H} ->
            {ok, {std@io@fs@@File, Path, H}};
        {error, _TryE0} -> {error, _TryE0}
    end.

% Open the file at `path` for writing: created, or truncated.

create(Path) ->
    case liftHandle(Path, (fun(__BpA0) -> try ((fun(__P) -> case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Path)) of
        {ok, H} ->
            {ok, {std@io@fs@@File, Path, H}};
        {error, _TryE0} -> {error, _TryE0}
    end.

% An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read

% like a file on disk — no `Result`, the build proved the file exists — and

% closing it is a no-op.

openAsset(Asset) ->
    {std@io@fs@@File, '__bp_field'(Asset, path), {mem, '__bp_field'(Asset, bytes), counters:new(1, [])}}.

% ── the wasm bodies (decision 992) ───────────────────────────────────────────

% `io.fs` on wasm answers what it answers on commonJS, erlang and beam: the same functions

% over the file system of the process, the same paths (a relative one is read against the

% working directory, an absolute one as it is), the same answers and the same errors. The

% host is `wasi:filesystem`, reached through std-wasm's leaves (`modules/std-wasm/wat/fs.wat`;

% the `wasi…` declarations below), which the runner serves with the root and the working

% directory preopened (`needs: [.Filesystem]`, no flag). A leaf answers a host failure as

% `-(1 + code)`, `code` the ordinal of `wasi:filesystem`'s `error-code`, or as the `Error`

% of a `Result<_, i32>` holding the code; `wasiError` writes it as Node's text

% (`ENOENT: …`), which `fsError` reads as it reads every target's.

%% external fn wasiCwd -> erlang template

%% external fn wasiGetenv -> erlang template

%% external fn wasiOpen -> erlang template

%% external fn wasiOpenMem -> erlang template

%% external fn wasiClose -> erlang template

%% external fn wasiIsMem -> erlang template

%% external fn wasiTell -> erlang template

%% external fn wasiSeek -> erlang template

%% external fn wasiSize -> erlang template

%% external fn wasiSizeRaw -> erlang template

%% external fn wasiRead -> erlang template

%% external fn wasiReadAll -> erlang template

%% external fn wasiReadLine -> erlang template

%% external fn wasiWrite -> erlang template

%% external fn wasiStatKind -> erlang template

%% external fn wasiStatSize -> erlang template

%% external fn wasiStatMtime -> erlang template

%% external fn wasiList -> erlang template

%% external fn wasiMkdir -> erlang template

%% external fn wasiRmdir -> erlang template

%% external fn wasiUnlink -> erlang template

%% external fn wasiSymlink -> erlang template

%% external fn wasiByteAt -> erlang template

%% external fn wasiSha256 -> erlang template

% The POSIX name of the host's error `code`, and its text.

wasiName(Code) ->
    Names = [<<"EACCES">>, <<"EAGAIN">>, <<"EALREADY">>, <<"EBADF">>, <<"EBUSY">>, <<"EDEADLK">>, <<"EDQUOT">>, <<"EEXIST">>, <<"EFBIG">>, <<"EILSEQ">>, <<"EINPROGRESS">>, <<"EINTR">>, <<"EINVAL">>, <<"EIO">>, <<"EISDIR">>, <<"ELOOP">>, <<"EMLINK">>, <<"EMSGSIZE">>, <<"ENAMETOOLONG">>, <<"ENODEV">>, <<"ENOENT">>, <<"ENOLCK">>, <<"ENOMEM">>, <<"ENOSPC">>, <<"ENOTDIR">>, <<"ENOTEMPTY">>, <<"ENOTRECOVERABLE">>, <<"ENOTSUP">>, <<"ENOTTY">>, <<"ENXIO">>, <<"EOVERFLOW">>, <<"EPERM">>, <<"EPIPE">>, <<"EROFS">>, <<"ESPIPE">>, <<"ETXTBSY">>, <<"EXDEV">>],
    case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Names, Code) of
        undefined ->
            <<"EIO">>;
        __bp_nullish ->
            __bp_nullish
    end.

wasiText(Code) ->
    Texts = [<<"permission denied">>, <<"resource temporarily unavailable">>, <<"connection already in progress">>, <<"bad file descriptor">>, <<"resource busy or locked">>, <<"resource deadlock avoided">>, <<"disk quota exceeded">>, <<"file already exists">>, <<"file too large">>, <<"illegal byte sequence">>, <<"operation in progress">>, <<"interrupted system call">>, <<"invalid argument">>, <<"i/o error">>, <<"illegal operation on a directory">>, <<"too many symbolic links encountered">>, <<"too many links">>, <<"message too long">>, <<"name too long">>, <<"no such device">>, <<"no such file or directory">>, <<"no locks available">>, <<"not enough memory">>, <<"no space left on device">>, <<"not a directory">>, <<"directory not empty">>, <<"state not recoverable">>, <<"operation not supported">>, <<"inappropriate ioctl for device">>, <<"no such device or address">>, <<"value too large for defined data type">>, <<"operation not permitted">>, <<"broken pipe">>, <<"read-only file system">>, <<"invalid seek">>, <<"text file busy">>, <<"cross-device link not permitted">>],
    case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Texts, Code) of
        undefined ->
            <<"i/o error">>;
        __bp_nullish ->
            __bp_nullish
    end.

% The `HostError` of the host's error `code`: `ENOENT: no such file or directory`.

wasiError(Code) ->
    {std@failure@@HostError, <<(wasiName(Code))/binary, ": ", (wasiText(Code))/binary>>, <<"host">>, std@failure@@HostErrorName__v__error, undefined}.

% The `Ok` of a leaf's answer, its `Error` the `HostError` of the code.

okBytes(R) ->
    case R of
        {ok, B} ->
            {ok, B};
        {error, Code} ->
            {error, wasiError(Code)}
    end.

okStrings(R) ->
    case R of
        {ok, Xs} ->
            {ok, Xs};
        {error, Code} ->
            {error, wasiError(Code)}
    end.

okSize(R) ->
    case R of
        {ok, N} ->
            {ok, N};
        {error, Code} ->
            {error, wasiError(Code)}
    end.

% `path` without the slashes it begins with: the host reads a path relative to the root it preopens.

withoutRoot(Path) ->
    P = Path,
    P@3 = (fun __BpLoop(P@1) ->
        case (string:prefix(P@1, <<"/">>) =/= nomatch) of
            true ->
                P@2 = string_slice(P@1, 1, undefined),
                __BpLoop(P@2);
            _ -> P@1
        end
    end)(P),
    P@3.

% `name` inside `dir`, `dir` empty being the root.

joinPath(Dir, Name) ->
    case (Dir =:= <<"">>) of
        true ->
            Name;
        _ ->
            <<Dir/binary, "/", Name/binary>>
    end.

% `path` as the host reads it: absolute, as it is; relative, from the working directory. The empty

% path is no file (`ENOENT`), as it is on every target.

resolve(Path) ->
    case (Path =:= <<"">>) of
        true ->
            {error, wasiError(20)};
        _ ->
            case (string:prefix(Path, <<"/">>) =/= nomatch) of
                true ->
                    {ok, withoutRoot(Path)};
                _ ->
                    Cwd = erlang:error(wasm_only),
                    case ((Cwd =:= <<"">>) orelse (Cwd =:= <<"/">>)) of
                        true ->
                            {ok, Path};
                        _ ->
                            {ok, withoutRoot(<<Cwd/binary, "/", Path/binary>>)}
                    end
            end
    end.

% The file a handle holds: the handle block `rawOpen`, `rawCreate` and `memHandle` answered.

blockOf(Handle) ->
    Block = 0,
    Block@2 = case (((erlang:is_number(Handle) andalso (Handle == erlang:trunc(Handle))) andalso (Handle >= -2147483648)) andalso (Handle =< 2147483647)) of
        true ->
            Handle@1 = erlang:trunc(Handle),
            B = Handle@1,
            Block@1 = B,
            Block@1;
        _ ->
            Block
    end,
    Block@2.

% Whether `a` sorts before `b` by the bytes of their UTF-8 (string `<` is not a wasm GC operation).

bytesBefore(A, B) ->
    try
        X = A,
        Y = B,
        Nx = byte_size(X),
        Ny = byte_size(Y),
        I = 0,
        I@3 = (fun __BpLoop(I@1) ->
            case ((I@1 < Nx) andalso (I@1 < Ny)) of
                true ->
                    Cx = erlang:error(wasm_only),
                    Cy = erlang:error(wasm_only),
                    case (Cx =/= Cy) of
                        true ->
                            erlang:throw({'__bp_try', (Cx < Cy)});
                        _ -> ok
                    end,
                    I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:988:15">>),
                    __BpLoop(I@2);
                _ -> I@1
            end
        end)(I),
        (Nx < Ny)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The names sorted by the bytes of their UTF-8, none twice: what `readdirSync` answers on Node.

sortedStrings(Xs) ->
    Out = [],
    I = 0,
    {I@3, Out@3} = (fun __BpLoop({I@1, Out@1}) ->
        case (I@1 < erlang:length(Xs)) of
            true ->
                __BpLoop(try
                    X = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, I@1) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end,
                    I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:999:15">>),
                    J = 0,
                    J@3 = (fun __BpLoop1(J@1) ->
                        case ((J@1 < erlang:length(Out@1)) andalso bytesBefore(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Out@1, J@1) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@1 ->
                                __bp_nullish@1
                        end, X)) of
                            true ->
                                J@2 = '__bp_int'((J@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1002:19">>),
                                __BpLoop1(J@2);
                            _ -> J@1
                        end
                    end)(J),
                    case ((J@3 < erlang:length(Out@1)) andalso ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Out@1, J@3) of
                        undefined ->
                            <<"">>;
                        __bp_nullish@2 ->
                            __bp_nullish@2
                    end) =:= X)) of
                        true ->
                            erlang:throw({'__bp_cond_continue', {I@2, Out@1}});
                        _ -> ok
                    end,
                    Out@2 = ((array_slice(Out@1, 0, J@3) ++ [X]) ++ array_slice(Out@1, J@3, undefined)),
                    {I@2, Out@2}
                catch
                    throw:{'__bp_cond_continue', __BpGroup5} -> __BpGroup5
                end);
            _ -> {I@1, Out@1}
        end
    end)({I, Out}),
    Out@3.

readBytesWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            H = erlang:error(wasm_only),
            case (H < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - H), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1013:35">>))};
                _ ->
                    R = erlang:error(wasm_only),
                    erlang:error(wasm_only),
                    case okBytes(R) of
                        {ok, B} ->
                            {ok, B};
                        {error, _TryE1} -> {error, _TryE1}
                    end
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

writeBytesWasm(Path, Contents) ->
    case resolve(Path) of
        {ok, P} ->
            H = erlang:error(wasm_only),
            case (H < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - H), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1023:35">>))};
                _ ->
                    N = erlang:error(wasm_only),
                    erlang:error(wasm_only),
                    case (N < 0) of
                        true ->
                            {error, wasiError('__bp_int'(((-1) - N), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1026:35">>))};
                        _ ->
                            {ok, 0}
                    end
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

writeTextWasm(Path, Contents) ->
    case writeBytesWasm(Path, Contents) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

appendTextWasm(Path, Contents) ->
    case resolve(Path) of
        {ok, P} ->
            H = erlang:error(wasm_only),
            case (H < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - H), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1038:35">>))};
                _ ->
                    At = erlang:error(wasm_only),
                    case (At < 0) of
                        true ->
                            erlang:error(wasm_only),
                            {error, wasiError(13)};
                        _ ->
                            erlang:error(wasm_only),
                            N = erlang:error(wasm_only),
                            erlang:error(wasm_only),
                            case (N < 0) of
                                true ->
                                    {error, wasiError('__bp_int'(((-1) - N), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1047:35">>))};
                                _ ->
                                    {ok, 0}
                            end
                    end
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

% The offset of the first byte that starts a sequence that is not UTF-8, `-1` when there is none.

utf8OffsetWasm(Data) ->
    try
        N = byte_size(Data),
        I = 0,
        I@5 = (fun __BpLoop(I@1) ->
            case (I@1 < N) of
                true ->
                    __BpLoop(try
                        C = erlang:error(wasm_only),
                        I@3 = case (C < 128) of
                            true ->
                                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1058:19">>),
                                erlang:throw({'__bp_cond_continue', I@2}),
                                I@2;
                            _ ->
                                I@1
                        end,
                        K = 0,
                        K@6 = case ((C >= 194) andalso (C =< 223)) of
                            true ->
                                K@1 = 1,
                                K@1;
                            _ ->
                                K@5 = case ((C >= 224) andalso (C =< 239)) of
                                    true ->
                                        K@2 = 2,
                                        K@2;
                                    _ ->
                                        K@4 = case ((C >= 240) andalso (C =< 244)) of
                                            true ->
                                                K@3 = 3,
                                                K@3;
                                            _ ->
                                                erlang:throw({'__bp_try', (fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(I@3)}),
                                                K
                                        end,
                                        K@4
                                end,
                                K@5
                        end,
                        case ('__bp_int'((I@3 + K@6), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1071:15">>) >= N) of
                            true ->
                                erlang:throw({'__bp_try', (fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(I@3)});
                            _ -> ok
                        end,
                        Lo = 128,
                        Hi = 191,
                        {Lo@5, Hi@6} = case (C =:= 224) of
                            true ->
                                Lo@1 = 160,
                                {Lo@1, Hi};
                            _ ->
                                {Hi@5, Lo@4} = case (C =:= 237) of
                                    true ->
                                        Hi@1 = 159,
                                        {Hi@1, Lo};
                                    _ ->
                                        {Lo@3, Hi@4} = case (C =:= 240) of
                                            true ->
                                                Lo@2 = 144,
                                                {Lo@2, Hi};
                                            _ ->
                                                Hi@3 = case (C =:= 244) of
                                                    true ->
                                                        Hi@2 = 143,
                                                        Hi@2;
                                                    _ ->
                                                        Hi
                                                end,
                                                {Lo, Hi@3}
                                        end,
                                        {Hi@4, Lo@3}
                                end,
                                {Lo@4, Hi@5}
                        end,
                        D = erlang:error(wasm_only),
                        case ((D < Lo@5) orelse (D > Hi@6)) of
                            true ->
                                erlang:throw({'__bp_try', (fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(I@3)});
                            _ -> ok
                        end,
                        J = 2,
                        J@3 = (fun __BpLoop1(J@1) ->
                            case (J@1 =< K@6) of
                                true ->
                                    E = erlang:error(wasm_only),
                                    case ((E < 128) orelse (E > 191)) of
                                        true ->
                                            erlang:throw({'__bp_try', (fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(I@3)});
                                        _ -> ok
                                    end,
                                    J@2 = '__bp_int'((J@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1089:19">>),
                                    __BpLoop1(J@2);
                                _ -> J@1
                            end
                        end)(J),
                        I@4 = '__bp_int'(('__bp_int'((I@3 + K@6), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1091:15">>) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1091:19">>),
                        I@4
                    catch
                        throw:{'__bp_cond_continue', __BpGroup7} -> __BpGroup7
                    end);
                _ -> I@1
            end
        end)(I),
        (-1)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

stripEolWasm(Line) ->
    N = byte_size(Line),
    N@4 = case ((N > 0) andalso (erlang:error(wasm_only) =:= 10)) of
        true ->
            N@1 = '__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1099:15">>),
            N@3 = case ((N@1 > 0) andalso (erlang:error(wasm_only) =:= 13)) of
                true ->
                    N@2 = '__bp_int'((N@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1100:59">>),
                    N@2;
                _ ->
                    N@1
            end,
            N@3;
        _ ->
            N
    end,
    bytes_slice(Line, 0, N@4).

openWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            H = erlang:error(wasm_only),
            case (H < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - H), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1108:35">>))};
                _ ->
                    Handle = H,
                    {ok, Handle}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

createWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            H = erlang:error(wasm_only),
            case (H < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - H), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1116:35">>))};
                _ ->
                    Handle = H,
                    {ok, Handle}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

memHandleWasm(Data) ->
    Handle = erlang:error(wasm_only),
    Handle.

sizeWasm(Handle, Path) ->
    case okSize(erlang:error(wasm_only)) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

readWasm(Handle, N) ->
    case okBytes(erlang:error(wasm_only)) of
        {ok, B} ->
            {ok, B};
        {error, _TryE0} -> {error, _TryE0}
    end.

readAllWasm(Handle) ->
    case okBytes(erlang:error(wasm_only)) of
        {ok, B} ->
            {ok, B};
        {error, _TryE0} -> {error, _TryE0}
    end.

readLineWasm(Handle) ->
    case okBytes(erlang:error(wasm_only)) of
        {ok, B} ->
            {ok, B};
        {error, _TryE0} -> {error, _TryE0}
    end.

% The SHA-256 of the whole file, the position where it was.

hashWasm(Handle) ->
    Block = blockOf(Handle),
    At = erlang:error(wasm_only),
    erlang:error(wasm_only),
    R = erlang:error(wasm_only),
    erlang:error(wasm_only),
    case okBytes(R) of
        {ok, B} ->
            {ok, erlang:error(wasm_only)};
        {error, _TryE0} -> {error, _TryE0}
    end.

writeWasm(Handle, Data) ->
    N = erlang:error(wasm_only),
    case (N < 0) of
        true ->
            {error, wasiError('__bp_int'(((-1) - N), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1159:35">>))};
        _ ->
            {ok, N}
    end.

closeWasm(Handle) ->
    erlang:error(wasm_only),
    {ok, 0}.

readOnlyWasm(Handle) ->
    erlang:error(wasm_only).

existsWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            (erlang:error(wasm_only) >= 0);
        {error, _} ->
            false
    end.

listWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            case okStrings(erlang:error(wasm_only)) of
                {ok, Names} ->
                    {ok, sortedStrings(Names)};
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

mkdirWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            R = erlang:error(wasm_only),
            case (R < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - R), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1188:35">>))};
                _ ->
                    {ok, 0}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

% The directory and every missing one above it. One that is there is `Ok`; a file in the way is

% `EEXIST` when it is the directory asked for, `ENOTDIR` when it is above it.

mkdirRecursiveWasm(Path) ->
    try
        case resolve(Path) of
            {ok, P} ->
                Parts = [],
                Pieces = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(P, <<"/">>),
                I = 0,
                {I@3, Parts@4} = (fun __BpLoop({I@1, Parts@1}) ->
                    case (I@1 < erlang:length(Pieces)) of
                        true ->
                            Piece = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, I@1) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish ->
                                    __bp_nullish
                            end,
                            I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1201:15">>),
                            Parts@3 = case ((Piece =/= <<"">>) andalso (Piece =/= <<".">>)) of
                                true ->
                                    Parts@2 = (Parts@1 ++ [Piece]),
                                    Parts@2;
                                _ ->
                                    Parts@1
                            end,
                            __BpLoop({I@2, Parts@3});
                        _ -> {I@1, Parts@1}
                    end
                end)({I, Parts}),
                Prefix = <<"">>,
                K = 0,
                {Prefix@3, K@3} = (fun __BpLoop({Prefix@1, K@1}) ->
                    case (K@1 < erlang:length(Parts@4)) of
                        true ->
                            __BpLoop(try
                                Prefix@2 = joinPath(Prefix@1, case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts@4, K@1) of
                                    undefined ->
                                        <<"">>;
                                    __bp_nullish@1 ->
                                        __bp_nullish@1
                                end),
                                K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1208:15">>),
                                Kind = erlang:error(wasm_only),
                                case (Kind =:= 3) of
                                    true ->
                                        erlang:throw({'__bp_cond_continue', {Prefix@2, K@2}});
                                    _ -> ok
                                end,
                                case (Kind >= 0) of
                                    true ->
                                        case (K@2 =:= erlang:length(Parts@4)) of
                                            true ->
                                                erlang:throw({'__bp_try', {error, wasiError(7)}});
                                            _ -> ok
                                        end,
                                        erlang:throw({'__bp_try', {error, wasiError(24)}});
                                    _ -> ok
                                end,
                                Made = erlang:error(wasm_only),
                                case (Made < 0) of
                                    true ->
                                        erlang:throw({'__bp_try', {error, wasiError('__bp_int'(((-1) - Made), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1216:42">>))}});
                                    _ -> ok
                                end,
                                {Prefix@2, K@2}
                            catch
                                throw:{'__bp_cond_continue', __BpGroup10} -> __BpGroup10
                            end);
                        _ -> {Prefix@1, K@1}
                    end
                end)({Prefix, K}),
                {ok, 0};
            {error, _TryE0} -> {error, _TryE0}
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The FILE at `path`: a directory is `EISDIR`, whatever it holds.

rmWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            Kind = erlang:error(wasm_only),
            case (Kind < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - Kind), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1225:38">>))};
                _ ->
                    case (Kind =:= 3) of
                        true ->
                            {error, wasiError(14)};
                        _ ->
                            R = erlang:error(wasm_only),
                            case (R < 0) of
                                true ->
                                    {error, wasiError('__bp_int'(((-1) - R), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1228:35">>))};
                                _ ->
                                    {ok, 0}
                            end
                    end
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

copyWasm(Src, Dest) ->
    case readBytesWasm(Src) of
        {ok, Contents} ->
            case writeBytesWasm(Dest, Contents) of
                {ok, Written} ->
                    {ok, 0};
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

statWasm(Path) ->
    case resolve(Path) of
        {ok, P} ->
            Kind = erlang:error(wasm_only),
            case (Kind < 0) of
                true ->
                    {error, wasiError('__bp_int'(((-1) - Kind), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1241:38">>))};
                _ ->
                    case okSize(erlang:error(wasm_only)) of
                        {ok, Size} ->
                            case okSize(erlang:error(wasm_only)) of
                                {ok, Seconds} ->
                                    {ok, {std@io@fs@@FileStat, Size, '__bp_int'((Seconds * 1000), -9223372036854775808, 9223372036854775807, <<"integer overflow: * on i64 at src/io/fs.bp:1244:48">>), (Kind =:= 3)}};
                                {error, _TryE2} -> {error, _TryE2}
                            end;
                        {error, _TryE1} -> {error, _TryE1}
                    end
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

% The regular files under `root` and the links whose target is missing, as paths relative to it, in

% directory order: a work list of directories, not a recursion (a recursive `try` is not lowered on wasm).

walkWasm(Root) ->
    try
        case resolve(Root) of
            {ok, P} ->
                Kind = erlang:error(wasm_only),
                case (Kind < 0) of
                    true ->
                        {error, wasiError('__bp_int'(((-1) - Kind), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1252:38">>))};
                    _ ->
                        case (Kind =/= 3) of
                            true ->
                                {error, wasiError(24)};
                            _ ->
                                Dirs = [P],
                                Rels = [<<"">>],
                                Files = [],
                                Dangling = [],
                                Next = 0,
                                {Next@3, Dirs@6, Rels@6, Files@6, Dangling@6} = (fun __BpLoop({Next@1, Dirs@1, Rels@1, Files@1, Dangling@1}) ->
                                    case (Next@1 < erlang:length(Dirs@1)) of
                                        true ->
                                            Dir = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Dirs@1, Next@1) of
                                                undefined ->
                                                    <<"">>;
                                                __bp_nullish ->
                                                    __bp_nullish
                                            end,
                                            Rel = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Rels@1, Next@1) of
                                                undefined ->
                                                    <<"">>;
                                                __bp_nullish@1 ->
                                                    __bp_nullish@1
                                            end,
                                            Next@2 = '__bp_int'((Next@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1262:21">>),
                                            Names = case okStrings(erlang:error(wasm_only)) of
                                                {ok, _TryV1} -> _TryV1;
                                                {error, _TryE1} -> erlang:throw({'__bp_try', {error, _TryE1}})
                                            end,
                                            I = 0,
                                            {I@3, Dirs@5, Rels@5, Files@5, Dangling@5} = (fun __BpLoop1({I@1, Dirs@2, Rels@2, Files@2, Dangling@2}) ->
                                                case (I@1 < erlang:length(Names)) of
                                                    true ->
                                                        Name = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Names, I@1) of
                                                            undefined ->
                                                                <<"">>;
                                                            __bp_nullish@2 ->
                                                                __bp_nullish@2
                                                        end,
                                                        I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1267:19">>),
                                                        Full = joinPath(Dir, Name),
                                                        Sub = joinPath(Rel, Name),
                                                        Entry = erlang:error(wasm_only),
                                                        case ((Entry < 0) andalso (Entry =/= (-21))) of
                                                            true ->
                                                                erlang:throw({'__bp_try', {error, wasiError('__bp_int'(((-1) - Entry), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1271:63">>))}});
                                                            _ -> ok
                                                        end,
                                                        {Dirs@4, Rels@4} = case (Entry =:= 3) of
                                                            true ->
                                                                Dirs@3 = (Dirs@2 ++ [Full]),
                                                                Rels@3 = (Rels@2 ++ [Sub]),
                                                                {Dirs@3, Rels@3};
                                                            _ ->
                                                                {Dirs@2, Rels@2}
                                                        end,
                                                        Files@4 = case (Entry =:= 6) of
                                                            true ->
                                                                Files@3 = (Files@2 ++ [Sub]),
                                                                Files@3;
                                                            _ ->
                                                                Files@2
                                                        end,
                                                        Dangling@4 = case (Entry =:= (-21)) of
                                                            true ->
                                                                Dangling@3 = (Dangling@2 ++ [Sub]),
                                                                Dangling@3;
                                                            _ ->
                                                                Dangling@2
                                                        end,
                                                        __BpLoop1({I@2, Dirs@4, Rels@4, Files@4, Dangling@4});
                                                    _ -> {I@1, Dirs@2, Rels@2, Files@2, Dangling@2}
                                                end
                                            end)({I, Dirs@1, Rels@1, Files@1, Dangling@1}),
                                            __BpLoop({Next@2, Dirs@5, Rels@5, Files@5, Dangling@5});
                                        _ -> {Next@1, Dirs@1, Rels@1, Files@1, Dangling@1}
                                    end
                                end)({Next, Dirs, Rels, Files, Dangling}),
                                {ok, {std@io@fs@@Walked, sortedStrings(Files@6), sortedStrings(Dangling@6)}}
                        end
                end;
            {error, _TryE0} -> {error, _TryE0}
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% Whether the segment holds a wildcard.

isMagic(Seg) ->
    ((((string:find(Seg, <<"*">>) =/= nomatch) orelse (string:find(Seg, <<"?">>) =/= nomatch)) orelse (string:find(Seg, <<"[">>) =/= nomatch)) orelse (string:find(Seg, <<"{">>) =/= nomatch)).

% A segment with its `{a,b}` alternatives written out, nested ones too; one that is never closed is a name.

expandBraces(Seg) ->
    Cs = [<<__C/utf8>> || __C <- unicode:characters_to_list(Seg, utf8)],
    Open = (-1),
    I = 0,
    {Open@4, I@3} = try
        (fun __BpLoop({Open@1, I@1}) ->
            case (I@1 < erlang:length(Cs)) of
                true ->
                    Open@3 = case ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, I@1) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end) =:= <<"{">>) of
                        true ->
                            Open@2 = I@1,
                            erlang:throw({'__bp_cond_break', {Open@2, I@1}}),
                            Open@2;
                        _ ->
                            Open@1
                    end,
                    I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1298:15">>),
                    __BpLoop({Open@3, I@2});
                _ -> {Open@1, I@1}
            end
        end)({Open, I})
    catch
        throw:{'__bp_cond_break', __BpGroup13} -> __BpGroup13
    end,
    case (Open@4 < 0) of
        true ->
            [Seg];
        _ ->
            Depth = 0,
            Close = (-1),
            Cuts = [],
            J = Open@4,
            Closed = false,
            {Depth@6, Close@4, Closed@4, Cuts@4, J@3} = (fun __BpLoop({Depth@1, Close@1, Closed@1, Cuts@1, J@1}) ->
                case ((J@1 < erlang:length(Cs)) andalso (not Closed@1)) of
                    true ->
                        C = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, J@1) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@1 ->
                                __bp_nullish@1
                        end,
                        % Separate `if`s, not an `else if` chain: wasm's GC lowering refuses
                        % an `if` nesting one beside an `else if` that appends (B-170).
                        Depth@3 = case (C =:= <<"{">>) of
                            true ->
                                Depth@2 = '__bp_int'((Depth@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1310:37">>),
                                Depth@2;
                            _ ->
                                Depth@1
                        end,
                        Depth@5 = case (C =:= <<"}">>) of
                            true ->
                                Depth@4 = '__bp_int'((Depth@3 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1311:37">>),
                                Depth@4;
                            _ ->
                                Depth@3
                        end,
                        {Close@3, Closed@3} = case ((C =:= <<"}">>) andalso (Depth@5 =:= 0)) of
                            true ->
                                Close@2 = J@1,
                                Closed@2 = true,
                                {Close@2, Closed@2};
                            _ ->
                                {Close@1, Closed@1}
                        end,
                        Cuts@3 = case ((C =:= <<",">>) andalso (Depth@5 =:= 1)) of
                            true ->
                                Cuts@2 = (Cuts@1 ++ [J@1]),
                                Cuts@2;
                            _ ->
                                Cuts@1
                        end,
                        J@2 = '__bp_int'((J@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1317:15">>),
                        __BpLoop({Depth@5, Close@3, Closed@3, Cuts@3, J@2});
                    _ -> {Depth@1, Close@1, Closed@1, Cuts@1, J@1}
                end
            end)({Depth, Close, Closed, Cuts, J}),
            case (Close@4 < 0) of
                true ->
                    [Seg];
                _ ->
                    Head = iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, array_slice(Cs, 0, Open@4)))),
                    Tail = iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, array_slice(Cs, '__bp_int'((Close@4 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1321:31">>), undefined)))),
                    Out = [],
                    Start = '__bp_int'((Open@4 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1323:22">>),
                    K = 0,
                    {Out@3, Start@3, K@3} = (fun __BpLoop({Out@1, Start@1, K@1}) ->
                        case (K@1 =< erlang:length(Cuts@4)) of
                            true ->
                                Stop = Close@4,
                                Stop@2 = case (K@1 < erlang:length(Cuts@4)) of
                                    true ->
                                        Stop@1 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cuts@4, K@1) of
                                            undefined ->
                                                Close@4;
                                            __bp_nullish@2 ->
                                                __bp_nullish@2
                                        end,
                                        Stop@1;
                                    _ ->
                                        Stop
                                end,
                                Alt = iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, array_slice(Cs, Start@1, Stop@2)))),
                                Out@2 = (Out@1 ++ expandBraces('__bp_add'('__bp_add'(Head, Alt), Tail))),
                                Start@2 = '__bp_int'((Stop@2 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1330:22">>),
                                K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1331:15">>),
                                __BpLoop({Out@2, Start@2, K@2});
                            _ -> {Out@1, Start@1, K@1}
                        end
                    end)({Out, Start, K}),
                    Out@3
            end
    end.

% The `]` that closes the class opened at `at`, `-1` when there is none (the `[` is then a name).

classEnd(Pat, At) ->
    try
        J = '__bp_int'((At + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1338:16">>),
        J@2 = case ((J < erlang:length(Pat)) andalso ((((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, J) of
            undefined ->
                <<"">>;
            __bp_nullish@1 ->
                __bp_nullish@1
        end) =:= <<"!">>) orelse ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, J) of
            undefined ->
                <<"">>;
            __bp_nullish ->
                __bp_nullish
        end) =:= <<"^">>)))) of
            true ->
                J@1 = '__bp_int'((J + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1339:89">>),
                J@1;
            _ ->
                J
        end,
        J@4 = case ((J@2 < erlang:length(Pat)) andalso ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, J@2) of
            undefined ->
                <<"">>;
            __bp_nullish@2 ->
                __bp_nullish@2
        end) =:= <<"]">>)) of
            true ->
                J@3 = '__bp_int'((J@2 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1340:59">>),
                J@3;
            _ ->
                J@2
        end,
        J@7 = (fun __BpLoop(J@5) ->
            case (J@5 < erlang:length(Pat)) of
                true ->
                    case ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, J@5) of
                        undefined ->
                            <<"">>;
                        __bp_nullish@3 ->
                            __bp_nullish@3
                    end) =:= <<"]">>) of
                        true ->
                            erlang:throw({'__bp_try', J@5});
                        _ -> ok
                    end,
                    J@6 = '__bp_int'((J@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1343:15">>),
                    __BpLoop(J@6);
                _ -> J@5
            end
        end)(J@4),
        (-1)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% Whether `ch` is in the class written between `first` and `stop` (`!` or `^` first negates it, `a-z` is a range).

classHas(Pat, First, Stop, Ch) ->
    I = First,
    Negate = false,
    {Negate@2, I@2} = case ((I < Stop) andalso ((((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, I) of
        undefined ->
            <<"">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end) =:= <<"!">>) orelse ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, I) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end) =:= <<"^">>)))) of
        true ->
            Negate@1 = true,
            I@1 = '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1354:15">>),
            {Negate@1, I@1};
        _ ->
            {Negate, I}
    end,
    Found = false,
    {Found@7, I@7} = (fun __BpLoop({Found@1, I@3}) ->
        case (I@3 < Stop) of
            true ->
                Lo = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, I@3) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@2 ->
                        __bp_nullish@2
                end,
                {Found@6, I@6} = case (('__bp_int'((I@3 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1359:15">>) < Stop) andalso ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, '__bp_int'((I@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1359:39">>)) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@3 ->
                        __bp_nullish@3
                end) =:= <<"-">>)) of
                    true ->
                        Hi = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, '__bp_int'((I@3 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1360:31">>)) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@4 ->
                                __bp_nullish@4
                        end,
                        % By code point: a class range is one character each side, and
                        % wasm lowers no ordering of strings (B-170).
                        C = (fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(Ch, 0),
                        Found@3 = case (((fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(Lo, 0) =< C) andalso (C =< (fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(Hi, 0))) of
                            true ->
                                Found@2 = true,
                                Found@2;
                            _ ->
                                Found@1
                        end,
                        I@4 = '__bp_int'((I@3 + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1365:19">>),
                        {Found@3, I@4};
                    _ ->
                        Found@5 = case (Lo =:= Ch) of
                            true ->
                                Found@4 = true,
                                Found@4;
                            _ ->
                                Found@1
                        end,
                        I@5 = '__bp_int'((I@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1368:19">>),
                        {Found@5, I@5}
                end,
                __BpLoop({Found@6, I@6});
            _ -> {Found@1, I@3}
        end
    end)({Found, I@2}),
    (Found@7 =/= Negate@2).

% `name` against one pattern without braces: `*`, `?`, `[…]`.

globMatch(Pat, Begin, Name, Offset) ->
    try
        P = Begin,
        N = Offset,
        {P@13, N@9} = (fun __BpLoop({P@1, N@1}) ->
            case (P@1 < erlang:length(Pat)) of
                true ->
                    C = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, P@1) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end,
                    P@5 = case (C =:= <<"*">>) of
                        true ->
                            P@4 = (fun __BpLoop1(P@2) ->
                                case ((P@2 < erlang:length(Pat)) andalso ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pat, P@2) of
                                    undefined ->
                                        <<"">>;
                                    __bp_nullish@1 ->
                                        __bp_nullish@1
                                end) =:= <<"*">>)) of
                                    true ->
                                        P@3 = '__bp_int'((P@2 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1382:23">>),
                                        __BpLoop1(P@3);
                                    _ -> P@2
                                end
                            end)(P@1),
                            case (P@4 =:= erlang:length(Pat)) of
                                true ->
                                    erlang:throw({'__bp_try', true});
                                _ -> ok
                            end,
                            K = N@1,
                            K@3 = (fun __BpLoop1(K@1) ->
                                case (K@1 =< erlang:length(Name)) of
                                    true ->
                                        case globMatch(Pat, P@4, Name, K@1) of
                                            true ->
                                                erlang:throw({'__bp_try', true});
                                            _ -> ok
                                        end,
                                        K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1388:23">>),
                                        __BpLoop1(K@2);
                                    _ -> K@1
                                end
                            end)(K),
                            erlang:throw({'__bp_try', false}),
                            P@4;
                        _ ->
                            P@1
                    end,
                    case (N@1 >= erlang:length(Name)) of
                        true ->
                            erlang:throw({'__bp_try', false});
                        _ -> ok
                    end,
                    Ch = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Name, N@1) of
                        undefined ->
                            <<"">>;
                        __bp_nullish@2 ->
                            __bp_nullish@2
                    end,
                    {P@12, N@8} = case (C =:= <<"?">>) of
                        true ->
                            P@6 = '__bp_int'((P@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1395:19">>),
                            N@2 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1396:19">>),
                            {P@6, N@2};
                        _ ->
                            {P@11, N@7} = case (C =:= <<"[">>) of
                                true ->
                                    End = classEnd(Pat, P@5),
                                    {P@9, N@5} = case (End < 0) of
                                        true ->
                                            case (Ch =/= <<"[">>) of
                                                true ->
                                                    erlang:throw({'__bp_try', false});
                                                _ -> ok
                                            end,
                                            P@7 = '__bp_int'((P@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1401:23">>),
                                            N@3 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1402:23">>),
                                            {P@7, N@3};
                                        _ ->
                                            case (not classHas(Pat, '__bp_int'((P@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1404:38">>), End, Ch)) of
                                                true ->
                                                    erlang:throw({'__bp_try', false});
                                                _ -> ok
                                            end,
                                            P@8 = '__bp_int'((End + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1405:25">>),
                                            N@4 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1406:23">>),
                                            {P@8, N@4}
                                    end,
                                    {P@9, N@5};
                                _ ->
                                    case (C =/= Ch) of
                                        true ->
                                            erlang:throw({'__bp_try', false});
                                        _ -> ok
                                    end,
                                    P@10 = '__bp_int'((P@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1410:19">>),
                                    N@6 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1411:19">>),
                                    {P@10, N@6}
                            end,
                            {P@11, N@7}
                    end,
                    __BpLoop({P@12, N@8});
                _ -> {P@1, N@1}
            end
        end)({P, N}),
        (N@9 =:= erlang:length(Name))
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

segmentMatches(Seg, Name) ->
    try
        Alts = expandBraces(Seg),
        Chars = [<<__C/utf8>> || __C <- unicode:characters_to_list(Name, utf8)],
        I = 0,
        I@3 = (fun __BpLoop(I@1) ->
            case (I@1 < erlang:length(Alts)) of
                true ->
                    case globMatch([<<__C/utf8>> || __C <- unicode:characters_to_list((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Alts, I@1) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end), utf8)], 0, Chars, 0) of
                        true ->
                            erlang:throw({'__bp_try', true});
                        _ -> ok
                    end,
                    I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1423:15">>),
                    __BpLoop(I@2);
                _ -> I@1
            end
        end)(I),
        false
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The names in `dir` the segment matches; a dot name only when the segment itself begins with the dot.

globNames(Dir, Seg) ->
    Listed = case erlang:error(wasm_only) of
        {ok, Xs} ->
            Xs;
        {error, _} ->
            []
    end,
    Out = [],
    I = 0,
    {I@3, Out@4} = (fun __BpLoop({I@1, Out@1}) ->
        case (I@1 < erlang:length(Listed)) of
            true ->
                __BpLoop(try
                    Name = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Listed, I@1) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end,
                    I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1438:15">>),
                    case ((string:prefix(Name, <<".">>) =/= nomatch) andalso (not (string:prefix(Seg, <<".">>) =/= nomatch))) of
                        true ->
                            erlang:throw({'__bp_cond_continue', {I@2, Out@1}});
                        _ -> ok
                    end,
                    Out@3 = case ((Seg =:= <<"*">>) orelse segmentMatches(Seg, Name)) of
                        true ->
                            Out@2 = (Out@1 ++ [Name]),
                            Out@2;
                        _ ->
                            Out@1
                    end,
                    {I@2, Out@3}
                catch
                    throw:{'__bp_cond_continue', __BpGroup22} -> __BpGroup22
                end);
            _ -> {I@1, Out@1}
        end
    end)({I, Out}),
    Out@4.

% The entries `segs` from `i` match under `dir` (`rel` its path from the root of the glob), added to `out`. A

% wildcard continues into real directories only; a name goes through a link.

globWalk(Segs, I, Dir, Rel, Out) ->
    Acc = Out,
    case (I =:= erlang:length(Segs)) of
        true ->
            Acc@2 = case (Rel =/= <<"">>) of
                true ->
                    Acc@1 = (Acc ++ [Rel]),
                    Acc@1;
                _ ->
                    Acc
            end,
            Acc@2;
        _ ->
            Seg = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Segs, I) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end,
            Last = (I =:= '__bp_int'((erlang:length(Segs) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1454:33">>)),
            case (Seg =:= <<"**">>) of
                true ->
                    Acc@4 = case (not Last) of
                        true ->
                            Acc@3 = globWalk(Segs, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1456:43">>), Dir, Rel, Acc),
                            Acc@3;
                        _ ->
                            Acc
                    end,
                    Names = globNames(Dir, <<"*">>),
                    K = 0,
                    {K@3, Acc@10} = (fun __BpLoop({K@1, Acc@5}) ->
                        case (K@1 < erlang:length(Names)) of
                            true ->
                                Name = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Names, K@1) of
                                    undefined ->
                                        <<"">>;
                                    __bp_nullish@1 ->
                                        __bp_nullish@1
                                end,
                                K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1461:19">>),
                                Full = joinPath(Dir, Name),
                                Sub = joinPath(Rel, Name),
                                Acc@7 = case Last of
                                    true ->
                                        Acc@6 = (Acc@5 ++ [Sub]),
                                        Acc@6;
                                    _ ->
                                        Acc@5
                                end,
                                Acc@9 = case (erlang:error(wasm_only) =:= 3) of
                                    true ->
                                        Acc@8 = globWalk(Segs, I, Full, Sub, Acc@7),
                                        Acc@8;
                                    _ ->
                                        Acc@7
                                end,
                                __BpLoop({K@2, Acc@9});
                            _ -> {K@1, Acc@5}
                        end
                    end)({K, Acc@4}),
                    Acc@10;
                _ ->
                    case (not isMagic(Seg)) of
                        true ->
                            Full@1 = joinPath(Dir, Seg),
                            Sub@1 = joinPath(Rel, Seg),
                            Acc@15 = case Last of
                                true ->
                                    Acc@12 = case (erlang:error(wasm_only) >= 0) of
                                        true ->
                                            Acc@11 = (Acc ++ [Sub@1]),
                                            Acc@11;
                                        _ ->
                                            Acc
                                    end,
                                    Acc@12;
                                _ ->
                                    Acc@14 = case (erlang:error(wasm_only) =:= 3) of
                                        true ->
                                            Acc@13 = globWalk(Segs, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1475:36">>), Full@1, Sub@1, Acc),
                                            Acc@13;
                                        _ ->
                                            Acc
                                    end,
                                    Acc@14
                            end,
                            Acc@15;
                        _ ->
                            Names@1 = globNames(Dir, Seg),
                            K@4 = 0,
                            {K@7, Acc@21} = (fun __BpLoop({K@5, Acc@16}) ->
                                case (K@5 < erlang:length(Names@1)) of
                                    true ->
                                        Name@1 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Names@1, K@5) of
                                            undefined ->
                                                <<"">>;
                                            __bp_nullish@2 ->
                                                __bp_nullish@2
                                        end,
                                        K@6 = '__bp_int'((K@5 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1483:15">>),
                                        Full@2 = joinPath(Dir, Name@1),
                                        Sub@2 = joinPath(Rel, Name@1),
                                        Acc@20 = case Last of
                                            true ->
                                                Acc@17 = (Acc@16 ++ [Sub@2]),
                                                Acc@17;
                                            _ ->
                                                Acc@19 = case (erlang:error(wasm_only) =:= 3) of
                                                    true ->
                                                        Acc@18 = globWalk(Segs, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1489:36">>), Full@2, Sub@2, Acc@16),
                                                        Acc@18;
                                                    _ ->
                                                        Acc@16
                                                end,
                                                Acc@19
                                        end,
                                        __BpLoop({K@6, Acc@20});
                                    _ -> {K@5, Acc@16}
                                end
                            end)({K@4, Acc}),
                            Acc@21
                    end
            end
    end.

globWasm(Pattern, Root) ->
    Resolved = resolve(Root),
    case (fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(Resolved) of
        true ->
            [];
        _ ->
            Base = (fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (<<"">>) end end)(Resolved),
            Segs = [],
            Pieces = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Pattern, <<"/">>),
            I = 0,
            {I@3, Segs@4} = (fun __BpLoop({I@1, Segs@1}) ->
                case (I@1 < erlang:length(Pieces)) of
                    true ->
                        Piece = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, I@1) of
                            undefined ->
                                <<"">>;
                            __bp_nullish ->
                                __bp_nullish
                        end,
                        I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1504:15">>),
                        Segs@3 = case ((Piece =/= <<"">>) andalso (Piece =/= <<".">>)) of
                            true ->
                                Segs@2 = (Segs@1 ++ [Piece]),
                                Segs@2;
                            _ ->
                                Segs@1
                        end,
                        __BpLoop({I@2, Segs@3});
                    _ -> {I@1, Segs@1}
                end
            end)({I, Segs}),
            Found = globWalk(Segs@4, 0, Base, <<"">>, []),
            Kept = [],
            K = 0,
            {K@3, Kept@4} = (fun __BpLoop({K@1, Kept@1}) ->
                case (K@1 < erlang:length(Found)) of
                    true ->
                        Entry = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Found, K@1) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@1 ->
                                __bp_nullish@1
                        end,
                        K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1512:15">>),
                        Kept@3 = case ((not (fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Pattern, <<"/">>)) orelse (erlang:error(wasm_only) =:= 3)) of
                            true ->
                                Kept@2 = (Kept@1 ++ [Entry]),
                                Kept@2;
                            _ ->
                                Kept@1
                        end,
                        __BpLoop({K@2, Kept@3});
                    _ -> {K@1, Kept@1}
                end
            end)({K, Kept}),
            sortedStrings(Kept@4)
    end.

% A path that is not there is `Ok`: the caller wanted it gone. A link is removed, never followed. The

% directories are found first, then the files removed, then the directories from the deepest.

removeTreeWasm(Path) ->
    try
        case resolve(Path) of
            {ok, P} ->
                Top = erlang:error(wasm_only),
                case (Top =:= (-21)) of
                    true ->
                        {ok, 0};
                    _ ->
                        case (Top < 0) of
                            true ->
                                {error, wasiError('__bp_int'(((-1) - Top), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1524:37">>))};
                            _ ->
                                case (Top =/= 3) of
                                    true ->
                                        R = erlang:error(wasm_only),
                                        case (R < 0) of
                                            true ->
                                                {error, wasiError('__bp_int'(((-1) - R), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1527:39">>))};
                                            _ ->
                                                {ok, 0}
                                        end;
                                    _ ->
                                        Dirs = [P],
                                        Next = 0,
                                        {Next@3, Dirs@6} = (fun __BpLoop({Next@1, Dirs@1}) ->
                                            case (Next@1 < erlang:length(Dirs@1)) of
                                                true ->
                                                    Dir = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Dirs@1, Next@1) of
                                                        undefined ->
                                                            <<"">>;
                                                        __bp_nullish ->
                                                            __bp_nullish
                                                    end,
                                                    Next@2 = '__bp_int'((Next@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1534:21">>),
                                                    Names = case okStrings(erlang:error(wasm_only)) of
                                                        {ok, _TryV1} -> _TryV1;
                                                        {error, _TryE1} -> erlang:throw({'__bp_try', {error, _TryE1}})
                                                    end,
                                                    I = 0,
                                                    {I@3, Dirs@5} = (fun __BpLoop1({I@1, Dirs@2}) ->
                                                        case (I@1 < erlang:length(Names)) of
                                                            true ->
                                                                Full = joinPath(Dir, case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Names, I@1) of
                                                                    undefined ->
                                                                        <<"">>;
                                                                    __bp_nullish@1 ->
                                                                        __bp_nullish@1
                                                                end),
                                                                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1539:19">>),
                                                                Kind = erlang:error(wasm_only),
                                                                case ((Kind < 0) andalso (Kind =/= (-21))) of
                                                                    true ->
                                                                        erlang:throw({'__bp_try', {error, wasiError('__bp_int'(((-1) - Kind), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1541:61">>))}});
                                                                    _ -> ok
                                                                end,
                                                                Dirs@4 = case (Kind =:= 3) of
                                                                    true ->
                                                                        Dirs@3 = (Dirs@2 ++ [Full]),
                                                                        Dirs@3;
                                                                    _ ->
                                                                        Dirs@2
                                                                end,
                                                                case ((Kind >= 0) andalso (Kind =/= 3)) of
                                                                    true ->
                                                                        R@1 = erlang:error(wasm_only),
                                                                        case (R@1 < 0) of
                                                                            true ->
                                                                                erlang:throw({'__bp_try', {error, wasiError('__bp_int'(((-1) - R@1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1545:47">>))}});
                                                                            _ -> ok
                                                                        end;
                                                                    _ -> ok
                                                                end,
                                                                __BpLoop1({I@2, Dirs@4});
                                                            _ -> {I@1, Dirs@2}
                                                        end
                                                    end)({I, Dirs@1}),
                                                    __BpLoop({Next@2, Dirs@5});
                                                _ -> {Next@1, Dirs@1}
                                            end
                                        end)({Next, Dirs}),
                                        K = erlang:length(Dirs@6),
                                        K@3 = (fun __BpLoop(K@1) ->
                                            case (K@1 > 0) of
                                                true ->
                                                    K@2 = '__bp_int'((K@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1551:15">>),
                                                    R@2 = erlang:error(wasm_only),
                                                    case (R@2 < 0) of
                                                        true ->
                                                            erlang:throw({'__bp_try', {error, wasiError('__bp_int'(((-1) - R@2), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1553:39">>))}});
                                                        _ -> ok
                                                    end,
                                                    __BpLoop(K@2);
                                                _ -> K@1
                                            end
                                        end)(K),
                                        {ok, 0}
                                end
                        end
                end;
            {error, _TryE0} -> {error, _TryE0}
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% A fresh, unique, empty directory under the host's temporary directory.

scratchDirWasm() ->
    try
        Base = erlang:error(wasm_only),
        Base@2 = case (Base =:= <<"">>) of
            true ->
                Base@1 = <<"/tmp">>,
                Base@1;
            _ ->
                Base
        end,
        Attempt = 0,
        Attempt@3 = (fun __BpLoop(Attempt@1) ->
            case (Attempt@1 < 100) of
                true ->
                    Dir = <<Base@2/binary, "/bp-std-fs-", ('__bp_text'(std@io@random:randomBytes(6)))/binary>>,
                    case (erlang:error(wasm_only) =:= 0) of
                        true ->
                            erlang:throw({'__bp_try', Dir});
                        _ -> ok
                    end,
                    Attempt@2 = '__bp_int'((Attempt@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:1566:27">>),
                    __BpLoop(Attempt@2);
                _ -> Attempt@1
            end
        end)(Attempt),
        erlang:error({panic, <<"io.fs: no scratch directory could be made">>}),
        Base@2
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

workingDirWasm() ->
    Cwd = erlang:error(wasm_only),
    case (Cwd =:= <<"">>) of
        true ->
            <<"/">>;
        _ ->
            Cwd
    end.

linkToWasm(Target, Link) ->
    L = resolve(Link),
    case (fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(L) of
        true ->
            erlang:error({panic, <<"io.fs: no link path">>});
        _ -> ok
    end,
    R = erlang:error(wasm_only),
    case (R < 0) of
        true ->
            erlang:error({panic, erlang:element(2, wasiError('__bp_int'(((-1) - R), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/io/fs.bp:1582:43">>)))});
        _ -> ok
    end,
    undefined.

% A host without `chmod` denies this user nothing: the permission tests have nothing to check there.

denyAllWasm(Path) ->
    false.

allowAllWasm(Path) ->
    undefined.

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

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

bytes_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__B, __A, __E) -> __N = byte_size(__B), __S = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, binary:part(__B, __S, erlang:max(__F - __S, 0)) end)(Self, Start, End);
        false ->
            (fun(__B, __A) -> __N = byte_size(__B), __S = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, binary:part(__B, __S, __N - __S) end)(Self, Start)
    end.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__fsError'(A0, A1) -> fsError(A0, A1).

'__bp_priv__lift'(A0, A1) -> lift(A0, A1).

'__bp_priv__liftStrings'(A0, A1) -> liftStrings(A0, A1).

'__bp_priv__liftStat'(A0, A1) -> liftStat(A0, A1).

'__bp_priv__liftWalked'(A0, A1) -> liftWalked(A0, A1).

'__bp_priv__liftHandle'(A0, A1) -> liftHandle(A0, A1).

'__bp_priv__wasiName'(A0) -> wasiName(A0).

'__bp_priv__wasiText'(A0) -> wasiText(A0).

'__bp_priv__wasiError'(A0) -> wasiError(A0).

'__bp_priv__okBytes'(A0) -> okBytes(A0).

'__bp_priv__okStrings'(A0) -> okStrings(A0).

'__bp_priv__okSize'(A0) -> okSize(A0).

'__bp_priv__withoutRoot'(A0) -> withoutRoot(A0).

'__bp_priv__joinPath'(A0, A1) -> joinPath(A0, A1).

'__bp_priv__resolve'(A0) -> resolve(A0).

'__bp_priv__blockOf'(A0) -> blockOf(A0).

'__bp_priv__bytesBefore'(A0, A1) -> bytesBefore(A0, A1).

'__bp_priv__sortedStrings'(A0) -> sortedStrings(A0).

'__bp_priv__readBytesWasm'(A0) -> readBytesWasm(A0).

'__bp_priv__writeBytesWasm'(A0, A1) -> writeBytesWasm(A0, A1).

'__bp_priv__writeTextWasm'(A0, A1) -> writeTextWasm(A0, A1).

'__bp_priv__appendTextWasm'(A0, A1) -> appendTextWasm(A0, A1).

'__bp_priv__utf8OffsetWasm'(A0) -> utf8OffsetWasm(A0).

'__bp_priv__stripEolWasm'(A0) -> stripEolWasm(A0).

'__bp_priv__openWasm'(A0) -> openWasm(A0).

'__bp_priv__createWasm'(A0) -> createWasm(A0).

'__bp_priv__memHandleWasm'(A0) -> memHandleWasm(A0).

'__bp_priv__sizeWasm'(A0, A1) -> sizeWasm(A0, A1).

'__bp_priv__readWasm'(A0, A1) -> readWasm(A0, A1).

'__bp_priv__readAllWasm'(A0) -> readAllWasm(A0).

'__bp_priv__readLineWasm'(A0) -> readLineWasm(A0).

'__bp_priv__hashWasm'(A0) -> hashWasm(A0).

'__bp_priv__writeWasm'(A0, A1) -> writeWasm(A0, A1).

'__bp_priv__closeWasm'(A0) -> closeWasm(A0).

'__bp_priv__readOnlyWasm'(A0) -> readOnlyWasm(A0).

'__bp_priv__existsWasm'(A0) -> existsWasm(A0).

'__bp_priv__listWasm'(A0) -> listWasm(A0).

'__bp_priv__mkdirWasm'(A0) -> mkdirWasm(A0).

'__bp_priv__mkdirRecursiveWasm'(A0) -> mkdirRecursiveWasm(A0).

'__bp_priv__rmWasm'(A0) -> rmWasm(A0).

'__bp_priv__copyWasm'(A0, A1) -> copyWasm(A0, A1).

'__bp_priv__statWasm'(A0) -> statWasm(A0).

'__bp_priv__walkWasm'(A0) -> walkWasm(A0).

'__bp_priv__isMagic'(A0) -> isMagic(A0).

'__bp_priv__expandBraces'(A0) -> expandBraces(A0).

'__bp_priv__classEnd'(A0, A1) -> classEnd(A0, A1).

'__bp_priv__classHas'(A0, A1, A2, A3) -> classHas(A0, A1, A2, A3).

'__bp_priv__globMatch'(A0, A1, A2, A3) -> globMatch(A0, A1, A2, A3).

'__bp_priv__segmentMatches'(A0, A1) -> segmentMatches(A0, A1).

'__bp_priv__globNames'(A0, A1) -> globNames(A0, A1).

'__bp_priv__globWalk'(A0, A1, A2, A3, A4) -> globWalk(A0, A1, A2, A3, A4).

'__bp_priv__globWasm'(A0, A1) -> globWasm(A0, A1).

'__bp_priv__removeTreeWasm'(A0) -> removeTreeWasm(A0).

'__bp_priv__scratchDirWasm'() -> scratchDirWasm().

'__bp_priv__workingDirWasm'() -> workingDirWasm().

'__bp_priv__linkToWasm'(A0, A1) -> linkToWasm(A0, A1).

'__bp_priv__denyAllWasm'(A0) -> denyAllWasm(A0).

'__bp_priv__allowAllWasm'(A0) -> allowAllWasm(A0).

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

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).

'__bp_priv__bytes_slice'(A0, A1, A2) -> bytes_slice(A0, A1, A2).
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
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
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

----- ERLANG -- std@io@fs@@Walked.erl
```erlang
-module(std@io@fs@@Walked).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, files) -> erlang:element(2, V);
'__bp_get'(V, dangling) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Walked", [{"files", erlang:element(2, V)}, {"dangling", erlang:element(3, V)}]}.
```

----- ERLANG -- std@io@fs@@File.erl
```erlang
-module(std@io@fs@@File).
-compile({no_auto_import,[size/1]}).
-export([path/1, size/1, read/2, bytes/1, text/1, chunks/2, lines/1, hash/1, write/2, close/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

path(Self) ->
    erlang:element(2, Self).

size(Self) ->
    case std@io@fs:liftI64(erlang:element(2, Self), (fun(__BpA0, __BpA1) -> try ((fun(__H, __P) -> case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __R} end end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(erlang:element(3, Self), erlang:element(2, Self))) of
        {ok, N} ->
            {ok, N};
        {error, _TryE0} -> {error, _TryE0}
    end.

read(Self, N) ->
    case (N =< 0) of
        true ->
            {ok, <<"">>};
        _ ->
            case std@io@fs:liftBytes(erlang:element(2, Self), (fun(__BpA0, __BpA1) -> try ((fun(__H, __N) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(erlang:element(3, Self), N)) of
                {ok, B} ->
                    {ok, B};
                {error, _TryE0} -> {error, _TryE0}
            end
    end.

bytes(Self) ->
    case std@io@fs:liftBytes(erlang:element(2, Self), (fun(__BpA0) -> try ((fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __R} end end)([]) end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(erlang:element(3, Self))) of
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

%% @AsyncIter — lazy lowering
chunks(Self, Size) ->
    '__bp_gen_new'(fun() ->
        __BpGen1 = erlang:make_ref(),
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
                    '__bp_gen_yield'({ok, B}),
                    __BpLoop()
                end)()
            catch
                throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
            end
        catch
            throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> '__bp_gen_yield'(__BpGenV1), ok
        end
    end).

%% @AsyncIter — lazy lowering
lines(Self) ->
    '__bp_gen_new'(fun() ->
        __BpGen2 = erlang:make_ref(),
        try
            Consumed = 0,
            Consumed@3 = try
                (fun __BpLoop(Consumed@1) ->
                    Raw = case std@io@fs:liftBytes(erlang:element(2, Self), (fun(__BpA0) -> try ((fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(erlang:element(3, Self))) of
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
                            erlang:throw({'__bp_gen_end', __BpGen2, ok, {error, {std@io@fs@@FsError__v__invalidutf8, erlang:element(2, Self), '__bp_int'(((fun(__V) when __V >= -9223372036854775807 - 1, __V =< 9223372036854775807 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI64: ", (integer_to_binary(__V))/binary, " does not fit i64">>}) end)(Consumed@1) + Offset), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/io/fs.bp:653:21">>)}}});
                        _ -> ok
                    end,
                    Width = erlang:byte_size(Raw),
                    Consumed@2 = '__bp_int'((Consumed@1 + Width), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/fs.bp:655:33">>),
                    '__bp_gen_yield'({ok, (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (<<"">>) end end)((fun(__B) -> case unicode:characters_to_binary(__B) of __S when is_binary(__S) -> {ok, __S}; _ -> {error, <<"bytes.toUtf8: not valid UTF-8">>} end end)(Line))}),
                    __BpLoop(Consumed@2)
                end)(Consumed)
            catch
                throw:{'__bp_cond_break', __BpGroup2} -> __BpGroup2
            end
        catch
            throw:{'__bp_gen_end', __BpGenK2, _, __BpGenV2} when (__BpGenK2 =:= __BpGen2) -> '__bp_gen_yield'(__BpGenV2), ok
        end
    end).

hash(Self) ->
    case std@io@fs:liftString(erlang:element(2, Self), (fun(__BpA0) -> try ((fun(__H) -> case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> {ok, __Cur} = file:position(__H, cur), __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> erlang:error(__R) end end, __Digest = __L(0, crypto:hash_init(sha256)), {ok, _} = file:position(__H, __Cur), {ok, string:lowercase(binary:encode_hex(__Digest))} end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(erlang:element(3, Self))) of
        {ok, H} ->
            {ok, H};
        {error, _TryE0} -> {error, _TryE0}
    end.

write(Self, B) ->
    case (case erlang:element(3, Self) of {mem, _, _} -> true; _ -> false end) of
        true ->
            {error, {std@io@fs@@FsError__v__other, erlang:element(2, Self), <<"the file is open for reading">>}};
        _ ->
            case std@io@fs:liftI32(erlang:element(2, Self), (fun(__BpA0, __BpA1) -> try ((fun(__H, __B) -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __R} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(erlang:element(3, Self), B)) of
                {ok, N} ->
                    {ok, N};
                {error, _TryE0} -> {error, _TryE0}
            end
    end.

close(Self) ->
    Closed = (fun(__BpA0) -> try ((fun(__H) -> case __H of {mem, _, _} -> {ok, 0}; _ -> case file:close(__H) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(erlang:element(3, Self)).

'__bp_get'(V, location) -> erlang:element(2, V);
'__bp_get'(V, handle) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "File", [{"location", erlang:element(2, V)}, {"handle", erlang:element(3, V)}]}.

'__bp_behaviors'() -> [std@primitives@@Closeable].

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_gen_new'(__BpA0) ->
    Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
GenNew = fun(GBody) ->
    GCreator = erlang:self(),
    {'__bp_gen', erlang:spawn(fun() ->
        GMon = erlang:monitor(process, GCreator),
        erlang:put('__bp_gen_mon', GMon),
        receive
            {'DOWN', GMon, process, _, _} -> ok;
            {'__bp_gen', GCmd, GFrom, GM, GD} ->
                Load(GD),
                erlang:put('__bp_gen_self', {GFrom, GM}),
                case GCmd of
                    close -> ok;
                    next ->
                        try GBody() catch
                            throw:'__bp_gen_closed' -> ok;
                            GC:GR:GS ->
                                case erlang:erase('__bp_gen_self') of
                                    {GF0, GM0} -> erlang:send(GF0, {GM0, raise, GC, GR, GS, Dict()});
                                    undefined -> ok
                                end,
                                erlang:exit(normal)
                        end
                end,
                case erlang:erase('__bp_gen_self') of
                    {GF, GM1} -> erlang:send(GF, {GM1, done, Dict()});
                    undefined -> ok
                end
        end
    end)}
end,
GenNew(__BpA0).

'__bp_gen_yield'(__BpA0) ->
    Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
Yield = fun(YV) ->
    {YFrom, YM} = erlang:erase('__bp_gen_self'),
    erlang:send(YFrom, {YM, item, YV, Dict()}),
    YMon = erlang:get('__bp_gen_mon'),
    receive
        {'DOWN', YMon, process, _, _} -> erlang:throw('__bp_gen_closed');
        {'__bp_gen', YCmd, YFrom2, YM2, YD} ->
            Load(YD),
            erlang:put('__bp_gen_self', {YFrom2, YM2}),
            case YCmd of next -> undefined; close -> erlang:throw('__bp_gen_closed') end
    end
end,
Yield(__BpA0).
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

