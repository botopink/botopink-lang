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
