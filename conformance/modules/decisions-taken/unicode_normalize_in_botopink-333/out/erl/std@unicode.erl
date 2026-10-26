-module(std@unicode).
-export([fromCodepoint/1, firstCodepoint/1, normalize/2, codepoints/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__firstCodepointOrZeroBody'/1, '__bp_priv__codepointsBody'/1, '__bp_priv__hangulSBase'/0, '__bp_priv__hangulLBase'/0, '__bp_priv__hangulVBase'/0, '__bp_priv__hangulTBase'/0, '__bp_priv__hangulLCount'/0, '__bp_priv__hangulVCount'/0, '__bp_priv__hangulTCount'/0, '__bp_priv__hangulNCount'/0, '__bp_priv__hangulSCount'/0, '__bp_priv__isHangulSyllable'/1, '__bp_priv__hangulDecomposition'/1, '__bp_priv__fullDecomposition'/2, '__bp_priv__decompose'/2, '__bp_priv__canonicalOrder'/1, '__bp_priv__insertByClass'/3, '__bp_priv__recompose'/1, '__bp_priv__withStarter'/3, '__bp_priv__primaryComposite'/2, '__bp_priv__text'/1, '__bp_priv__codes'/1, '__bp_priv__array_all'/2, '__bp_priv__array_count'/2, '__bp_priv__array_slice'/3]).

%% behavior string

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

%%% std/unicode — Unicode codepoint primitives and normalization, cross-backend.

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/

%%%              (`String.prototype.codePointAt`, `String.fromCodePoint`)

%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/unicode.html

%%%              (`unicode:characters_to_list`)

%%%   UAX #15  — https://www.unicode.org/reports/tr15/ (normalization forms)

%%% 

%%% `codepoints(s)` decomposes a string into its sequence of Unicode

%%% codepoints (the i32 representation each backend hands back as an

%%% integer). `fromCodepoint(cp)` lifts a single codepoint to a string

%%% through the primitive `String.fromCodepoint` (a `fn:` body on every

%%% target); `firstCodepoint(s)` peeks the head. The carry-forward declares use

%%% the typed `#[compiler.external(.<Target>)]` annotation form (migrated in

%%% `external-target-libs-migration` F5-partial, c828308).

%%% 

%%% `normalize(s, form)` renders `s` under NFC, NFD, NFKC or NFKD by std's

%%% own botopink body on all four targets (decision 333 (A)) — no host

%%% normalizer is asked, so every target answers the same for every code

%%% point, under the one Unicode version `unicode_tables.bp` was generated

%%% from (`zig build gen-unicode`, `libs/std/AGENTS.md` § unicode): decompose

%%% (recursively; compatibility mappings too for NFKC / NFKD), put each run

%%% of non-starters in canonical order (a stable sort by combining class),

%%% then, for NFC / NFKC, recompose every unblocked pair whose primary

%%% composite is not excluded. Hangul syllables decompose and compose by the

%%% algorithm of Unicode §3.12, not by the tables.

%% import tables

% The one-character string of the scalar value `cp` (decision 262): every

% target runs this body, a call of the primitive `string.fromCodepoint`, so a

% `cp` that is no Unicode scalar value — negative, a surrogate, past U+10FFFF —

% aborts the program the same way everywhere.

fromCodepoint(Cp) ->
    <<(Cp)/utf8>>.

%% external fn firstCodepointOrZero -> erlang template

% wasm's cell: a wasm string is UTF-8 indexed by code point (decision 240),

% so `charCodeAt(0)` of its first character IS the code point.

firstCodepointOrZeroBody(S) ->
    case (erlang:length(unicode:characters_to_list(S)) =:= 0) of
        true ->
            0;
        _ ->
            (fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(S, 0)
    end.

% First codepoint of `s`, or `null` for the empty string. Implemented

% in pure botopink over `firstCodepointOrZero` + a length check —

% keeps the host call to a single template invocation and lets the

% option wrapping shape match the rest of std.

firstCodepoint(S) ->
    case (erlang:length(unicode:characters_to_list(S)) =:= 0) of
        true ->
            undefined;
        _ ->
            Cp = (fun(__S) -> case unicode:characters_to_list(__S, utf8) of [__C | _] -> __C; _ -> 0 end end)(S),
            Cp
    end.

% Decompose a string into its sequence of Unicode codepoints.

% Node: `Array.from($0).map(c => c.codePointAt(0))` — `Array.from` on

% a string iterates by codepoint (not by UTF-16 unit), and the comma

% operator inside the arrow body keeps the expression a single template

% substitution. Erlang: `unicode:characters_to_list/2` returns an

% integer list of codepoints when given a UTF-8 binary.

%% external fn codepoints -> erlang template
codepoints(S) ->
    unicode:characters_to_list(S, utf8).

% wasm's cell: one code point per character (decision 240).

codepointsBody(S) ->
    lists:map(fun(C) ->
        (fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(C, 0)
    end, [<<__C/utf8>> || __C <- unicode:characters_to_list(S, utf8)]).

% Which Unicode normalization form to apply (NFC, NFD, NFKC, NFKD).

%% type NormalizationForm
%%   NFC
%%   NFD
%%   NFKC
%%   NFKD

% Render `s` under the normalization form `form` (UAX #15). Text whose code

% points are all below U+00A0 is the same under every form and comes back

% as it is.

normalize(S, Form) ->
    Cps = unicode:characters_to_list(S, utf8),
    case array_all(Cps, fun(C) ->
        (C < 160)
    end) of
        true ->
            S;
        _ ->
            % One arm per form: beam lowers an or-pattern `NFKC | NFKD` to no test at
            % all (front 97's compiler residual 10).
            Compat = case Form of
                std@unicode@@NormalizationForm__v__nfkc ->
                    true;
                std@unicode@@NormalizationForm__v__nfkd ->
                    true;
                _ ->
                    false
            end,
            Compose = case Form of
                std@unicode@@NormalizationForm__v__nfc ->
                    true;
                std@unicode@@NormalizationForm__v__nfkc ->
                    true;
                _ ->
                    false
            end,
            Ordered = canonicalOrder(decompose(Cps, Compat)),
            Out = case Compose of
                true ->
                    recompose(Ordered);
                false ->
                    Ordered
            end,
            iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(C) ->
                fromCodepoint(C)
            end, Out))))
    end.

% ── the algorithm ────────────────────────────────────────────────────────────

% Hangul (Unicode §3.12): the syllables U+AC00…U+D7A3 are LV or LVT

% sequences of the conjoining jamo L U+1100…, V U+1161…, T U+11A7… (T index

% 0 is "no trailing consonant").

hangulSBase() ->
    44032.

hangulLBase() ->
    4352.

hangulVBase() ->
    4449.

hangulTBase() ->
    4519.

hangulLCount() ->
    19.

hangulVCount() ->
    21.

hangulTCount() ->
    28.

hangulNCount() ->
    588.

hangulSCount() ->
    11172.

isHangulSyllable(Cp) ->
    Above = (Cp >= hangulSBase()),
    (Above andalso (Cp < '__bp_int'((hangulSBase() + hangulSCount()), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/unicode.bp:132:38">>))).

hangulDecomposition(Cp) ->
    Index = '__bp_int'((Cp - hangulSBase()), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/unicode.bp:136:20">>),
    T = (Index rem '__bp_nz'(hangulTCount(), <<"integer division by zero: % on i32 at src/unicode.bp:137:19">>)),
    Vt = (Index rem '__bp_nz'(hangulNCount(), <<"integer division by zero: % on i32 at src/unicode.bp:138:20">>)),
    L = '__bp_int'((hangulLBase() + '__bp_int'((('__bp_int'((Index - Vt), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/unicode.bp:139:34">>)) div '__bp_nz'(hangulNCount(), <<"integer division by zero: / on i32 at src/unicode.bp:139:40">>)), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/unicode.bp:139:40">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/unicode.bp:139:25">>),
    V = '__bp_int'((hangulVBase() + '__bp_int'((('__bp_int'((Vt - T), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/unicode.bp:140:31">>)) div '__bp_nz'(hangulTCount(), <<"integer division by zero: / on i32 at src/unicode.bp:140:36">>)), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/unicode.bp:140:36">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/unicode.bp:140:25">>),
    case (T =:= 0) of
        true ->
            [L, V];
        _ ->
            [L, V, '__bp_int'((hangulTBase() + T), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/unicode.bp:142:31">>)]
    end.

% The full decomposition of `cp`: its mapping, decomposed again until no

% code point maps. A compatibility mapping is followed only when `compat`

% and the code point has no canonical one.

fullDecomposition(Cp, Compat) ->
    case isHangulSyllable(Cp) of
        true ->
            hangulDecomposition(Cp);
        _ ->
            Canonical = std@internal@unicode_tables:canonicalDecomposition(Cp),
            Mapping = case (erlang:length(Canonical) > 0) of
                true ->
                    Canonical;
                false ->
                    case Compat of
                        true ->
                            std@internal@unicode_tables:compatibilityDecomposition(Cp);
                        false ->
                            Canonical
                    end
            end,
            case (erlang:length(Mapping) =:= 0) of
                true ->
                    [Cp];
                _ ->
                    Out = [],
                    Out@3 = lists:foldl(fun(M, Out@1) ->
                        Out@2 = (Out@1 ++ fullDecomposition(M, Compat)),
                        Out@2
                    end, Out, Mapping),
                    Out@3
            end
    end.

decompose(Cps, Compat) ->
    Out = [],
    Out@3 = lists:foldl(fun(C, Out@1) ->
        Out@2 = (Out@1 ++ fullDecomposition(C, Compat)),
        Out@2
    end, Out, Cps),
    Out@3.

% The canonical ordering algorithm: every run of non-starters (combining

% class > 0) sorted by class, stably — marks of one class keep their order.

canonicalOrder(Cps) ->
    Out = [],
    Run = [],
    {Out@4, Run@5} = lists:foldl(fun(C, {Out@1, Run@1}) ->
        K = std@internal@unicode_tables:combiningClass(C),
        {Out@3, Run@4} = case (K =:= 0) of
            true ->
                Out@2 = ((Out@1 ++ Run@1) ++ [C]),
                Run@2 = [],
                {Out@2, Run@2};
            _ ->
                Run@3 = insertByClass(Run@1, C, K),
                {Out@1, Run@3}
        end,
        {Out@3, Run@4}
    end, {Out, Run}, Cps),
    (Out@4 ++ Run@5).

% `c` (of class `k`) placed into `run`, which is sorted by class, after

% every mark whose class is at most `k`.

insertByClass(Run, C, K) ->
    At = array_count(Run, fun(X) ->
        (std@internal@unicode_tables:combiningClass(X) =< K)
    end),
    ((array_slice(Run, 0, At) ++ [C]) ++ array_slice(Run, At, erlang:length(Run))).

% The canonical composition algorithm over a canonically ordered sequence:

% each character is composed with the last starter when nothing between

% them blocks it — no character in between, or the last one in between of

% a lower class than its own — and the pair has a primary composite.

% `pending` holds the characters after the starter that did not compose

% (all non-starters: a starter that does not compose becomes the next

% starter), `lastClass` the class of the last of them.

recompose(Cps) ->
    Out = [],
    Starter = (-1),
    Pending = [],
    LastClass = 0,
    {Starter@6, Out@5, Pending@6, LastClass@6} = lists:foldl(fun(C, {Starter@1, Out@1, Pending@1, LastClass@1}) ->
        K = std@internal@unicode_tables:combiningClass(C),
        Adjacent = (erlang:length(Pending@1) =:= 0),
        Unblocked = (Adjacent orelse (LastClass@1 < K)),
        Open = ((Starter@1 >= 0) andalso Unblocked),
        Composite = case Open of
            true ->
                primaryComposite(Starter@1, C);
            false ->
                0
        end,
        {Starter@5, Out@4, Pending@5, LastClass@5} = case (Composite =/= 0) of
            true ->
                Starter@2 = Composite,
                {Starter@2, Out@1, Pending@1, LastClass@1};
            _ ->
                {Out@3, Starter@4, Pending@4, LastClass@4} = case (K =:= 0) of
                    true ->
                        Out@2 = withStarter(Out@1, Starter@1, Pending@1),
                        Starter@3 = C,
                        Pending@2 = [],
                        LastClass@2 = 0,
                        {Out@2, Starter@3, Pending@2, LastClass@2};
                    _ ->
                        Pending@3 = (Pending@1 ++ [C]),
                        LastClass@3 = K,
                        {Out@1, Starter@1, Pending@3, LastClass@3}
                end,
                {Starter@4, Out@3, Pending@4, LastClass@4}
        end,
        {Starter@5, Out@4, Pending@5, LastClass@5}
    end, {Starter, Out, Pending, LastClass}, Cps),
    withStarter(Out@5, Starter@6, Pending@6).

% `out` followed by the starter (none when negative) and what followed it.

withStarter(Out, Starter, Pending) ->
    case (Starter < 0) of
        true ->
            (Out ++ Pending);
        _ ->
            ((Out ++ [Starter]) ++ Pending)
    end.

% The primary composite of `first` then `second`, or 0: Hangul LV and LVT by

% the algorithm, every other pair from the tables.

primaryComposite(First, Second) ->
    LIndex = '__bp_int'((First - hangulLBase()), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/unicode.bp:239:24">>),
    VIndex = '__bp_int'((Second - hangulVBase()), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/unicode.bp:240:25">>),
    IsL = ((LIndex >= 0) andalso (LIndex < hangulLCount())),
    IsV = ((VIndex >= 0) andalso (VIndex < hangulVCount())),
    case (IsL andalso IsV) of
        true ->
            '__bp_int'((hangulSBase() + '__bp_int'((('__bp_int'(('__bp_int'((LIndex * hangulVCount()), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/unicode.bp:244:38">>) + VIndex), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/unicode.bp:244:53">>)) * hangulTCount()), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/unicode.bp:244:63">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/unicode.bp:244:28">>);
        _ ->
            TIndex = '__bp_int'((Second - hangulTBase()), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/unicode.bp:245:25">>),
            IsLv = (isHangulSyllable(First) andalso ((('__bp_int'((First - hangulSBase()), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/unicode.bp:247:19">>)) rem '__bp_nz'(hangulTCount(), <<"integer division by zero: % on i32 at src/unicode.bp:247:34">>)) =:= 0)),
            IsT = ((TIndex > 0) andalso (TIndex < hangulTCount())),
            case (IsLv andalso IsT) of
                true ->
                    '__bp_int'((First + TIndex), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/unicode.bp:249:35">>);
                _ ->
                    std@internal@unicode_tables:primaryComposite(First, Second)
            end
    end.

% ── tests ────────────────────────────────────────────────────────────────────












% Non-ASCII text is built from code points: the erlang backend truncates a

% `\u{…}` literal above U+007F to one latin1 byte.

text(Cps) ->
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(C) ->
        fromCodepoint(C)
    end, Cps)))).

codes(S) ->
    iolist_to_binary(lists:join(<<" ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(C) ->
        erlang:integer_to_binary(C)
    end, unicode:characters_to_list(S, utf8))))).










array_all(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =:= erlang:length(Self)).

array_count(Self, Pred) ->
    erlang:length(lists:filter(Pred, Self)).

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

-compile({inline,['__bp_nz'/2]}).
'__bp_nz'(B, What) when B == 0 -> erlang:error({panic, What});
'__bp_nz'(B, _) -> B.

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__firstCodepointOrZeroBody'(A0) -> firstCodepointOrZeroBody(A0).

'__bp_priv__codepointsBody'(A0) -> codepointsBody(A0).

'__bp_priv__hangulSBase'() -> hangulSBase().

'__bp_priv__hangulLBase'() -> hangulLBase().

'__bp_priv__hangulVBase'() -> hangulVBase().

'__bp_priv__hangulTBase'() -> hangulTBase().

'__bp_priv__hangulLCount'() -> hangulLCount().

'__bp_priv__hangulVCount'() -> hangulVCount().

'__bp_priv__hangulTCount'() -> hangulTCount().

'__bp_priv__hangulNCount'() -> hangulNCount().

'__bp_priv__hangulSCount'() -> hangulSCount().

'__bp_priv__isHangulSyllable'(A0) -> isHangulSyllable(A0).

'__bp_priv__hangulDecomposition'(A0) -> hangulDecomposition(A0).

'__bp_priv__fullDecomposition'(A0, A1) -> fullDecomposition(A0, A1).

'__bp_priv__decompose'(A0, A1) -> decompose(A0, A1).

'__bp_priv__canonicalOrder'(A0) -> canonicalOrder(A0).

'__bp_priv__insertByClass'(A0, A1, A2) -> insertByClass(A0, A1, A2).

'__bp_priv__recompose'(A0) -> recompose(A0).

'__bp_priv__withStarter'(A0, A1, A2) -> withStarter(A0, A1, A2).

'__bp_priv__primaryComposite'(A0, A1) -> primaryComposite(A0, A1).

'__bp_priv__text'(A0) -> text(A0).

'__bp_priv__codes'(A0) -> codes(A0).

'__bp_priv__array_all'(A0, A1) -> array_all(A0, A1).

'__bp_priv__array_count'(A0, A1) -> array_count(A0, A1).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).
