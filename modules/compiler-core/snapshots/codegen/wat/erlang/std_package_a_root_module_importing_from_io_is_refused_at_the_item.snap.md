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
    return parts.at(n - 1).unwrapOr("");
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
    val head = pieces.at(0).unwrapOr("");
    val tail = pieces.at(n - 1).unwrapOr("");
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
    val isAbs = if (parts.length == 0)
        false
    else
        isAbsolute(parts.at(0).unwrapOr(""));
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
    val ai = a.at(i).unwrapOr("");
    val bi = b.at(i).unwrapOr("");
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
    val p = pieces.at(0).unwrapOr("");
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
    val seg = segments.at(i).unwrapOr("");
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
    assert s.at(0).unwrapOr("") == "usr";
    assert s.at(1).unwrapOr("") == "bin";
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
-export([split/1, isAbsolute/1, basename/1, dirname/1, extname/1, join/1, normalize/1, relative/2, resolve/1, withoutExtension/1, isInside/2, separator/0, delimiter/0]).

%% behavior String

%% behavior Bool

%% behavior Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
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
            (fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV0 -> __BpV0 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts, '__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:40:23">>)))
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
            Head = (fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV0 -> __BpV0 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, 0)),
            Tail = (fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV1 -> __BpV1 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, '__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:68:28">>))),
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
            isAbsolute((fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV0 -> __BpV0 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts, 0)))
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
                    Ai = (fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV0 -> __BpV0 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(A, I)),
                    Bi = (fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV1 -> __BpV1 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(B, I)),
                    case (Ai =:= Bi) of
                        true ->
                            commonPrefixCount(A, B, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/path.bp:117:52">>));
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
            [<<"..">> | makeUps('__bp_int'((N - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:123:42">>))]
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
    Ups = makeUps('__bp_int'((erlang:length(SrcParts) - Common), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:138:39">>)),
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
            P = (fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV0 -> __BpV0 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, 0)),
            Rest = array_slice(Pieces, 1, erlang:length(Pieces)),
            NextAcc = case (P =:= <<"..">>) of
                true ->
                    case (erlang:length(Acc) =:= 0) of
                        true ->
                            Acc;
                        false ->
                            array_slice(Acc, 0, '__bp_int'((erlang:length(Acc) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:162:63">>))
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
            Seg = (fun(__BpO) -> case __BpO of undefined -> (<<"">>); __BpV0 -> __BpV0 end end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Segments, I)),
            Next = resolveStep(State, Seg),
            resolveAll(Segments, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/path.bp:178:35">>), Next)
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
            string_slice(P, 0, '__bp_int'((N - erlang:length(unicode:characters_to_list(Ext))), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/path.bp:208:51">>))
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

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
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
//// std/io/fs — synchronous filesystem primitives, cross-backend.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/fs.html
////              (`readFileSync`, `writeFileSync`, `existsSync`,
////               `readdirSync`, `mkdirSync`, `rmSync`, `statSync`,
////               `copyFileSync`)
////   Erlang   — https://www.erlang.org/doc/man/file.html
////              (`file:read_file/1`, `file:write_file/2`,
////               `filelib:is_regular/1`, `file:list_dir/1`,
////               `file:make_dir/1`, `file:delete/1`,
////               `file:read_file_info/1`, `file:copy/2`)
////
//// All operations are synchronous (`*Sync` on Node, blocking BIFs on
//// Erlang). Each fallible operation returns `@Result<R, string>` via
//// the §A3 `declare fn` template-owned wrapper — the host
//// template wraps the call in try/catch and lifts the error to the
//// `{error, <message>}` channel.

import {path.relative};

pub type FileStat(
    size: i64,
    mtime: i64,
    isDir: bool,
)

// Read the entire file as a UTF-8 string. Reds with the host's I/O
// error message on missing file / permission denied / etc.
// Node: `require('fs').readFileSync($0, 'utf8')`.
// Erlang: `file:read_file/1` returns `{ok, Bin}` or `{error, Reason}`.
#[@External.Node("""(() => { try { return { ok: require('fs').readFileSync($0, 'utf8') } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn readText(path: string) -> @Result<string, string>;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[@External.Node("""(() => { try { require('fs').writeFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0, $1)""")]
pub declare fn writeText(
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
#[@External.Node("""(() => { try { return { ok: require('fs').readdirSync($0) } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn list(path: string) -> @Result<string[], string>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents (the spec's `recursive: bool = true` overload
// gates on default-fn-param-default support landing).
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[@External.Node("""(() => { try { require('fs').mkdirSync($0); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn mkdir(path: string) -> @Result<i32, string>;

// Delete the FILE at `path`. A directory — empty or not — is an `Error` on
// both hosts (`ERR_FS_EISDIR` / `eperm`); `removeTree` removes one.
// Node: `require('fs').rmSync($0)`.
// Erlang: `file:delete/1`.
#[@External.Node("""(() => { try { require('fs').rmSync($0); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn rm(path: string) -> @Result<i32, string>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[@External.Node("""(() => { try { require('fs').copyFileSync($0, $1); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0, $1)""")]
pub declare fn copy(src: string, dest: string) -> @Result<i32, string>;

// File metadata. Returns a `FileStat { size, mtime, isDir }` on
// success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
// `size` is in bytes.
// Node: `(() => { const s = require('fs').statSync($0); return { size: s.size, mtime: Math.floor(s.mtimeMs), isDir: s.isDirectory() } })()`.
// Erlang: `file:read_file_info/1` returns a `#file_info` record; the
// template projects the `size`, `mtime`, and `type` fields.
#[@External.Node("""(() => { try { const __s = require('fs').statSync($0); return { ok: { size: __s.size, mtime: Math.floor(__s.mtimeMs), isDir: __s.isDirectory() } } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn stat(path: string) -> @Result<FileStat, string>;

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
#[@External.Node("""(() => { try { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync($0, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; for (const __f of __all) { const __s = __fs.statSync(__p.join($0, __f), { throwIfNoEntry: false }); if (__s === undefined) return { error: 'fs.walk: dangling link "' + __f + '"' }; if (__s.isFile()) __out.push(__f) } return { ok: __out } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, <<"enotdir">>}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, iolist_to_binary(io_lib:format("~p", [__Y]))} end end end)($0)""")]
pub declare fn walk(root: string) -> @Result<string[], string>;

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
#[@External.Node("""(() => { try { const __fs = require('fs'); const __p = require('path'); const __root = $1; const __pat = String($0); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return { ok: Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, {ok, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))]} end)($0, $1)""")]
pub declare fn glob(pattern: string, root: string) -> @Result<string[], string>;

// Remove `path` and everything under it: a file, a link (the link, never its
// target) or a directory tree. A path that is not there is `Ok` too — the
// caller wanted it gone. What a test fixture is cleared with, and what the
// snapshot engine's tests clear their scratch directories with (1.0.11-beta
// front 97).
// Node: `rmSync(path, { recursive: true, force: true })`.
// Erlang: `file:del_dir_r/1`.
#[@External.Node("""(() => { try { require('fs').rmSync($0, { recursive: true, force: true }); return { ok: 0 } } catch (__e) { return { error: __e && __e.message ? __e.message : String(__e) } } })()""")]
#[@External.Erlang("""(fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)($0)""")]
pub declare fn removeTree(path: string) -> @Result<i32, string>;

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

test "fs.list of the host '/' resolves Ok" {
    val r = list("/");
    assert r.isOk();
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
        Error(reason) -> reason;
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

```

----- ERLANG -- std/io/fs.erl
```erlang
-module(std@io@fs).
-export([readText/1, writeText/2, exists/1, list/1, mkdir/1, rm/1, copy/2, stat/1, walk/1, glob/2, removeTree/1]).

%% behavior Bool

%%% std/io/fs — synchronous filesystem primitives, cross-backend.

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/fs.html

%%%              (`readFileSync`, `writeFileSync`, `existsSync`,

%%%               `readdirSync`, `mkdirSync`, `rmSync`, `statSync`,

%%%               `copyFileSync`)

%%%   Erlang   — https://www.erlang.org/doc/man/file.html

%%%              (`file:read_file/1`, `file:write_file/2`,

%%%               `filelib:is_regular/1`, `file:list_dir/1`,

%%%               `file:make_dir/1`, `file:delete/1`,

%%%               `file:read_file_info/1`, `file:copy/2`)

%%% 

%%% All operations are synchronous (`*Sync` on Node, blocking BIFs on

%%% Erlang). Each fallible operation returns `@Result<R, string>` via

%%% the §A3 `declare fn` template-owned wrapper — the host

%%% template wraps the call in try/catch and lifts the error to the

%%% `{error, <message>}` channel.

%% import relative

%% type FileStat: size, mtime, isDir

% Read the entire file as a UTF-8 string. Reds with the host's I/O

% error message on missing file / permission denied / etc.

% Node: `require('fs').readFileSync($0, 'utf8')`.

% Erlang: `file:read_file/1` returns `{ok, Bin}` or `{error, Reason}`.

%% external fn readText -> erlang template
readText(Path) ->
    (fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Path).

% Write `contents` to `path`, creating or truncating. Reds with the

% host's I/O error message.

% Node: `require('fs').writeFileSync($0, $1)`.

% Erlang: `file:write_file/2`.

%% external fn writeText -> erlang template
writeText(Path, Contents) ->
    (fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Path, Contents).

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

%% external fn list -> erlang template
list(Path) ->
    (fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, [list_to_binary(__N) || __N <- __L]}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Path).

% Create directory at `path`. Use `mkdirRecursive` to create

% intermediate parents (the spec's `recursive: bool = true` overload

% gates on default-fn-param-default support landing).

% Node: `require('fs').mkdirSync($0)`.

% Erlang: `file:make_dir/1`.

%% external fn mkdir -> erlang template
mkdir(Path) ->
    (fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Path).

% Delete the FILE at `path`. A directory — empty or not — is an `Error` on

% both hosts (`ERR_FS_EISDIR` / `eperm`); `removeTree` removes one.

% Node: `require('fs').rmSync($0)`.

% Erlang: `file:delete/1`.

%% external fn rm -> erlang template
rm(Path) ->
    (fun(__P) -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Path).

% Copy file from `src` to `dest`. Reds when `src` is missing or

% `dest` already exists (Node's default `copyFileSync` semantics).

% Node: `require('fs').copyFileSync($0, $1)`.

% Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).

%% external fn copy -> erlang template
copy(Src, Dest) ->
    (fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Src, Dest).

% File metadata. Returns a `FileStat { size, mtime, isDir }` on

% success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);

% `size` is in bytes.

% Node: `(() => { const s = require('fs').statSync($0); return { size: s.size, mtime: Math.floor(s.mtimeMs), isDir: s.isDirectory() } })()`.

% Erlang: `file:read_file_info/1` returns a `#file_info` record; the

% template projects the `size`, `mtime`, and `type` fields.

%% external fn stat -> erlang template
stat(Path) ->
    '__bp_adopt'((fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Path), std@io@fs@@FileStat, [size, mtime, isDir]).

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

%% external fn walk -> erlang template
walk(Root) ->
    (fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, <<"enotdir">>}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, iolist_to_binary(io_lib:format("~p", [__Y]))} end end end)(Root).

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

%% external fn glob -> erlang template
glob(Pattern, Root) ->
    (fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, {ok, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))]} end)(Pattern, Root).

% Remove `path` and everything under it: a file, a link (the link, never its

% target) or a directory tree. A path that is not there is `Ok` too — the

% caller wanted it gone. What a test fixture is cleared with, and what the

% snapshot engine's tests clear their scratch directories with (1.0.11-beta

% front 97).

% Node: `rmSync(path, { recursive: true, force: true })`.

% Erlang: `file:del_dir_r/1`.

%% external fn removeTree -> erlang template
removeTree(Path) ->
    (fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Path).

% Internal, test scaffolding: a fresh, unique, empty directory under the

% host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in

% one of these and removes it with `removeTree`, so a run leaves nothing under

% the host's tmpdir.

%% external fn scratchDir -> erlang template

% Internal, test scaffolding: the working directory (what a relative root is

% read against) and a symbolic link `link` → `target`.

%% external fn workingDir -> erlang template

%% external fn linkTo -> erlang template

% ── tests ────────────────────────────────────────────────────────────────────

% (Inline tests are smoke-grade — they require the host filesystem to be

% writable at the host's `tmpdir()`. The lib-test harness runs each

% inline test as a separate process; the temp filenames are seeded with

% `time.nowMillis()` for cross-run uniqueness.)





% Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,

% `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.

makeFixtureTree(Dir) ->
    (fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app">>])))),
    (fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog">>])))),
    (fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/page.bp">>]))), <<"root page">>),
    (fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog/page.bp">>]))), <<"blog page">>),
    (fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog/notes.md">>]))), <<"notes">>).

% Internal, test scaffolding: what `walk` answers for the fixture tree when

% its root is spelled `<scratch dir><suffix>` — every spelling of one root has

% to answer the same three relative paths.

walkFixture(Suffix) ->
    Dir = (fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)(),
    makeFixtureTree(Dir),
    Walked = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ([<<"<error>">>]) end end)((fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, <<"enotdir">>}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, iolist_to_binary(io_lib:format("~p", [__Y]))} end end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, Suffix]))))),
    (fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Dir),
    iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Walked))).

% Internal, test scaffolding: the same, with the root spelled relative to the

% working directory — `<prefix><path from the cwd to the fixture>`.

walkFixtureFromCwd(Prefix) ->
    Dir = (fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)(),
    makeFixtureTree(Dir),
    Root = iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Prefix, std@path:relative((fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)(), Dir), <<"/app">>]))),
    Walked = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ([<<"<error>">>]) end end)((fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, <<"enotdir">>}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, iolist_to_binary(io_lib:format("~p", [__Y]))} end end end)(Root)),
    (fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Dir),
    iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Walked))).










% Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.

walkRefusal(Root) ->
    case (fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, <<"enotdir">>}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> throw({bp_fs_walk, __E}); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> throw({bp_fs_walk, __X}) end end, __Acc, __Names) end end, try __Found = __Walk(__Root, [], []), case lists:sort([__D || {dangling, __D} <- __Found]) of [__First | _] -> {error, <<"fs.walk: dangling link ", 34, __First/binary, 34>>}; [] -> {ok, lists:sort([__F || {file, __F} <- __Found])} end catch throw:{bp_fs_walk, __Y} -> {error, iolist_to_binary(io_lib:format("~p", [__Y]))} end end end)(Root) of
        {ok, _} ->
            <<"">>;
        {error, Reason} ->
            Reason
    end.







% Internal, test scaffolding: the fixture tree plus the names decision 177 is

% about — a dot file and a dot directory, a link to a directory, a link to a

% file and a dangling link, all under `<dir>/app`.

makeGlobTree(Dir) ->
    makeFixtureTree(Dir),
    (fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/.cache">>])))),
    (fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/.cache/page.bp">>]))), <<"cached">>),
    (fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/.hidden.bp">>]))), <<"hidden">>),
    (fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/blog/.draft.md">>]))), <<"draft">>),
    (fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)(<<"blog">>, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/linked">>])))),
    (fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)(<<"page.bp">>, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/alias.bp">>])))),
    (fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)(<<"missing.bp">>, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app/gone.bp">>])))).

% Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over

% `makeGlobTree`, joined by `,`.

globbed(Pattern) ->
    Dir = (fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)(),
    makeGlobTree(Dir),
    Found = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ([<<"<error>">>]) end end)((fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, {ok, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))]} end)(Pattern, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [Dir, <<"/app">>]))))),
    (fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, iolist_to_binary(io_lib:format("~p", [__R]))} end end)(Dir),
    iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Found))).









'__bp_adopt'(V, T, Ks) when erlang:is_map(V) -> erlang:list_to_tuple([T | [maps:get(K, V, undefined) || K <- Ks]]);
'__bp_adopt'(V, T, Ks) when erlang:is_list(V) -> ['__bp_adopt'(E, T, Ks) || E <- V];
'__bp_adopt'({ok, V}, T, Ks) -> {ok, '__bp_adopt'(V, T, Ks)};
'__bp_adopt'(V, _, _) -> V.
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

