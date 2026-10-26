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
