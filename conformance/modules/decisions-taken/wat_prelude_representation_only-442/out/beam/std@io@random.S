{module, std@io@random}.
{exports, [{float, 0}, {seed, 1}, {seededFloat, 0}, {coin, 0}, {intInRange, 2}, {pick, 1}, {shuffle, 1}, {secureToken, 1}, {uuidV4, 0}, {randomBytes, 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__base64UrlOf', 1}, {'__bp_priv__floorWalk', 4}, {'__bp_priv__hexDigit', 1}, {'__bp_priv__hexOf', 1}, {'__bp_priv__randomByte', 0}, {'__bp_priv__randomBytesBody', 1}, {'__bp_priv__randomBytesOf', 1}, {'__bp_priv__secureTokenBody', 1}, {'__bp_priv__shuffleBody', 1}, {'__bp_priv__uuidV4Body', 0}, {'__bp_priv__wholeOf', 1}]}.
{attributes, []}.
{labels, 298}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@random.erl", 1}]}.
    {func_info, {atom, std@io@random}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 86}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 87}}.
  {label, 86}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 89}}.
  {label, 88}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 91}}.
  {label, 89}.
  {label, 87}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@io@random.erl", 2}]}.
    {func_info, {atom, std@io@random}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 92}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 91}}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 91}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 91}}.
  {label, 95}.
  {label, 93}.
    {deallocate, 6}.
    return.
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

{function, float, 0, 35}.
  {label, 34}.
    {line, [{location, "std@io@random.erl", 3}]}.
    {func_info, {atom, std@io@random}, {atom, float}, 0}.
  {label, 35}.
    {call_ext_only, 0, {extfunc, rand, uniform, 0}}.
% Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar
% at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`
% draws from the reproducible stream. `float()` itself stays on
% `Math.random`; explicit-stream callers opt into determinism by using
% `seededFloat` after `seed`.
% Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar
% shipper copies the `.mjs` next to the emitted module.
% Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`
% triple. `S` is folded to an integer via the i64 input.

{function, seed, 1, 43}.
  {label, 42}.
    {line, [{location, "std@io@random.erl", 4}]}.
    {func_info, {atom, std@io@random}, {atom, seed}, 1}.
  {label, 43}.
    {call_only, 1, {f, 37}}.
% Draw from the seeded PRNG when a `seed` call has been made; otherwise
% falls through to the unseeded `float()` baseline. Erlang's `rand`
% module reads from the process dictionary's seed state directly, so
% the same `rand:uniform/0` call after `seed` produces the reproducible
% stream automatically.

{function, seededFloat, 0, 45}.
  {label, 44}.
    {line, [{location, "std@io@random.erl", 5}]}.
    {func_info, {atom, std@io@random}, {atom, seededFloat}, 0}.
  {label, 45}.
    {call_ext_only, 0, {extfunc, rand, uniform, 0}}.
% 50/50 boolean draw. `float() >= 0.5` picks the upper half of the
% uniform sample — identically distributed on every backend that has
% a uniform `float()`.

{function, coin, 0, 7}.
  {label, 6}.
    {line, [{location, "std@io@random.erl", 6}]}.
    {func_info, {atom, std@io@random}, {atom, coin}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {test, is_ge, {f, 96}, [{x, 0}, {float, 0.5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 96}.
    {move, {atom, false}, {x, 0}}.
  {label, 97}.
    {deallocate, 0}.
    return.
% Random integer in the closed interval `[lo, hi]`. When `lo > hi` the
% range is empty and the result is `lo` (a defensive default — the
% alternative is to `panic`, which the @assert-style tests would
% rather catch at the call site).

{function, intInRange, 2, 9}.
  {label, 8}.
    {line, [{location, "std@io@random.erl", 7}]}.
    {func_info, {atom, std@io@random}, {atom, intInRange}, 2}.
  {label, 9}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 98}, [{y, 0}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 98}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 99}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 99}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/random.bp:66:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 100}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 101}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 101}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:66:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 102}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 3}, {x, 2}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 4, {f, 13}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 103}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 103}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:69:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 104}.
    {deallocate, 5}.
    return.
% Pick a random element from a non-empty array. Returns `null` for the
% empty array — the call site should default with `?? …` rather
% than panic. Uses a walk-up integer floor (no `Math.floor` import) so
% the body stays self-contained.

{function, pick, 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@random.erl", 8}]}.
    {func_info, {atom, std@io@random}, {atom, pick}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 105}, [{y, 1}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 105}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 3}}.
    {move, {y, 2}, {x, 2}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 4, {f, 13}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_last, 2, {f, 107}, 4}.
% Internal: integer floor of a non-negative `product` < `upper`. Walks
% `start` up from 0 while `threshold (= start + 1)` still fits below
% `product`. O(upper) — fine for the small `array<T>` arities `pick`
% targets in tests.

{function, floorWalk, 4, 13}.
  {label, 12}.
    {line, [{location, "std@io@random.erl", 9}]}.
    {func_info, {atom, std@io@random}, {atom, floorWalk}, 4}.
  {label, 13}.
    {allocate, 4, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 111}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 111}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:90:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 112}.
    {test, is_lt, {f, 110}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 110}.
    {test, is_lt, {f, 113}, [{y, 2}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 113}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 114}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 114}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 115}}.
  {label, 114}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:92:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 115}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {float, 1.0}], {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {move, {x, 1}, {x, 4}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 4}, {x, 0}}.
    {call_last, 4, {f, 13}, 4}.
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

{function, shuffle, 1, 59}.
  {label, 58}.
    {line, [{location, "std@io@random.erl", 10}]}.
    {func_info, {atom, std@io@random}, {atom, shuffle}, 1}.
  {label, 59}.
    {call_only, 1, {f, 47}}.
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

{function, secureToken, 1, 63}.
  {label, 62}.
    {line, [{location, "std@io@random.erl", 11}]}.
    {func_info, {atom, std@io@random}, {atom, secureToken}, 1}.
  {label, 63}.
    {call_only, 1, {f, 61}}.
% A random (version 4) UUID, lowercase: 122 strong random bits with the
% version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).
% Node: `crypto.randomUUID()`.
% Erlang: 16 strong random bytes, the version/variant bits rewritten in the
% binary pattern — the bit work lives in the template because botopink has
% no bitwise operators (`language-gaps.md`).

{function, uuidV4, 0, 75}.
  {label, 74}.
    {line, [{location, "std@io@random.erl", 12}]}.
    {func_info, {atom, std@io@random}, {atom, uuidV4}, 0}.
  {label, 75}.
    {call_only, 0, {f, 65}}.
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

{function, randomBytes, 1, 85}.
  {label, 84}.
    {line, [{location, "std@io@random.erl", 13}]}.
    {func_info, {atom, std@io@random}, {atom, randomBytes}, 1}.
  {label, 85}.
    {call_only, 1, {f, 77}}.
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

{function, shuffleBody, 1, 15}.
  {label, 14}.
    {line, [{location, "std@io@random.erl", 14}]}.
    {func_info, {atom, std@io@random}, {atom, shuffleBody}, 1}.
  {label, 15}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 0}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@io@random.erl", 15}]}.
  {label, 116}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 117}, [{integer, 0}, {x, 0}]}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 118}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 118}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 119}}.
  {label, 118}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:319:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 119}.
    {test, is_ne_exact, {f, 120}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 3}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 121}}.
  {label, 120}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 121}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ne_exact, {f, 122}, [{y, 3}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 123}}.
  {label, 122}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 123}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 124}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 124}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 125}}.
  {label, 124}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:320:53">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 125}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 126}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {integer, 1}], {x, 2}}.
    {gc_bif, '-', {f, 0}, 3, [{x, 0}, {x, 1}], {x, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 127}}.
  {label, 126}.
    {move, {x, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 127}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 116}}.
  {label, 117}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, secureTokenBody, 1, 17}.
  {label, 16}.
    {line, [{location, "std@io@random.erl", 15}]}.
    {func_info, {atom, std@io@random}, {atom, secureTokenBody}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 25}}.
    {call_last, 1, {f, 31}, 1}.
% RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.

{function, uuidV4Body, 0, 19}.
  {label, 18}.
    {line, [{location, "std@io@random.erl", 16}]}.
    {func_info, {atom, std@io@random}, {atom, uuidV4Body}, 0}.
  {label, 19}.
    {allocate, 14, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {integer, 16}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 128}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 129}}.
  {label, 128}.
    {move, {integer, 0}, {x, 0}}.
  {label, 129}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 64}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 130}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 130}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 131}}.
  {label, 130}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:332:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 131}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 8}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 132}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 133}}.
  {label, 132}.
    {move, {integer, 0}, {x, 0}}.
  {label, 133}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 134}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 134}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 135}}.
  {label, 134}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:333:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 135}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 10}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 16}, {integer, 10}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 136}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 137}}.
  {label, 136}.
    {move, {integer, 0}, {x, 0}}.
  {label, 137}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 7}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 138}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 139}}.
  {label, 138}.
    {move, {integer, 0}, {x, 0}}.
  {label, 139}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 4}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 6}, {integer, 4}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 4}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 14}.
    return.

{function, randomBytesBody, 1, 21}.
  {label, 20}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, randomBytesBody}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 25}}.
    {call_last, 1, {f, 29}, 1}.

{function, randomByte, 0, 23}.
  {label, 22}.
    {line, [{location, "std@io@random.erl", 18}]}.
    {func_info, {atom, std@io@random}, {atom, randomByte}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 256.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {call_last, 1, {f, 33}, 1}.

{function, randomBytesOf, 1, 25}.
  {label, 24}.
    {line, [{location, "std@io@random.erl", 19}]}.
    {func_info, {atom, std@io@random}, {atom, randomBytesOf}, 1}.
  {label, 25}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@io@random.erl", 20}]}.
  {label, 172}.
    {test, is_lt, {f, 173}, [{y, 2}, {y, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 23}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 174}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 174}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 175}}.
  {label, 174}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:358:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 175}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 172}}.
  {label, 173}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, hexDigit, 1, 27}.
  {label, 26}.
    {line, [{location, "std@io@random.erl", 20}]}.
    {func_info, {atom, std@io@random}, {atom, hexDigit}, 1}.
  {label, 27}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0123456789abcdef">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 176}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 200}}.
  {label, 176}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 200}.
    {deallocate, 2}.
    return.

{function, hexOf, 1, 29}.
  {label, 28}.
    {line, [{location, "std@io@random.erl", 21}]}.
    {func_info, {atom, std@io@random}, {atom, hexOf}, 1}.
  {label, 29}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 202}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 206}, 3}.
% RFC 4648 §5 base64url, unpadded.

{function, base64UrlOf, 1, 31}.
  {label, 30}.
    {line, [{location, "std@io@random.erl", 22}]}.
    {func_info, {atom, std@io@random}, {atom, base64UrlOf}, 1}.
  {label, 31}.
    {allocate, 18, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@io@random.erl", 23}]}.
  {label, 207}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 209}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 209}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 210}}.
  {label, 209}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:376:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 210}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 208}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 211}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 211}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 212}}.
  {label, 211}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:377:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 212}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 213}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 213}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 214}}.
  {label, 213}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/random.bp:377:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 214}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 216}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 216}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 217}}.
  {label, 216}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:378:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 217}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 215}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 218}}.
  {label, 215}.
    {move, {integer, 0}, {x, 0}}.
  {label, 218}.
    {move, {x, 0}, {y, 6}}.
    {test, is_lt, {f, 219}, [{integer, 1}, {y, 4}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 222}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 222}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 223}}.
  {label, 222}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:380:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 223}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 224}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 224}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 225}}.
  {label, 224}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:380:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 225}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 221}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 221}.
    {move, {integer, 0}, {x, 0}}.
  {label, 226}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {integer, 0}, {x, 0}}.
  {label, 220}.
    {move, {x, 0}, {y, 8}}.
    {test, is_lt, {f, 227}, [{integer, 2}, {y, 4}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 230}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 230}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 231}}.
  {label, 230}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:383:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 231}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 232}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 232}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 233}}.
  {label, 232}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:383:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 233}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 229}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 234}}.
  {label, 229}.
    {move, {integer, 0}, {x, 0}}.
  {label, 234}.
    {jump, {f, 228}}.
  {label, 227}.
    {move, {integer, 0}, {x, 0}}.
  {label, 228}.
    {move, {x, 0}, {y, 10}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 236}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 236}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 237}}.
  {label, 236}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:387:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 237}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 8}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 238}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 238}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 239}}.
  {label, 238}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:387:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 239}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 240}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 240}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 241}}.
  {label, 240}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:387:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 241}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 235}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 242}}.
  {label, 235}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 242}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 244}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 244}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 245}}.
  {label, 244}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:386:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 245}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 243}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 246}}.
  {label, 243}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 246}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 247}, [{integer, 1}, {y, 4}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 8}, {integer, 16}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 249}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 249}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 250}}.
  {label, 249}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:388:54">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 250}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 10}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 251}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 251}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 252}}.
  {label, 251}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:388:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 252}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 253}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 253}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 254}}.
  {label, 253}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:388:58">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 254}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 248}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 255}}.
  {label, 248}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 255}.
    {move, {y, 12}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 256}}.
  {label, 247}.
  {label, 256}.
    {test, is_lt, {f, 257}, [{integer, 2}, {y, 4}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 10}, {integer, 64}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 258}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 259}}.
  {label, 258}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 259}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 260}}.
  {label, 257}.
  {label, 260}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 261}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 261}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 262}}.
  {label, 261}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:390:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 262}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 207}}.
  {label, 208}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 18}.
    return.
% A whole `v` in [0, 2^31) as an `i32`.

{function, wholeOf, 1, 33}.
  {label, 32}.
    {line, [{location, "std@io@random.erl", 23}]}.
    {func_info, {atom, std@io@random}, {atom, wholeOf}, 1}.
  {label, 33}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 1073741824}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 1073741824.0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@io@random.erl", 24}]}.
  {label, 263}.
    {test, is_lt, {f, 264}, [{integer, 0}, {y, 3}]}.
    {test, is_ge, {f, 265}, [{y, 2}, {y, 4}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 266}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 266}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 267}}.
  {label, 266}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:403:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 267}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 268}}.
  {label, 265}.
  {label, 268}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 269}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 269}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 270}}.
  {label, 269}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:406:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 270}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 4}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 263}}.
  {label, 264}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_priv__array_range', 2, 273}.
  {label, 272}.
    {line, [{location, "std@io@random.erl", 25}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 273}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 275}.
  {label, 274}.
    {line, [{location, "std@io@random.erl", 26}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 275}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__base64UrlOf', 1, 277}.
  {label, 276}.
    {line, [{location, "std@io@random.erl", 27}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__base64UrlOf'}, 1}.
  {label, 277}.
    {call_only, 1, {f, 31}}.

{function, '__bp_priv__floorWalk', 4, 279}.
  {label, 278}.
    {line, [{location, "std@io@random.erl", 28}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__floorWalk'}, 4}.
  {label, 279}.
    {call_only, 4, {f, 13}}.

{function, '__bp_priv__hexDigit', 1, 281}.
  {label, 280}.
    {line, [{location, "std@io@random.erl", 29}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__hexDigit'}, 1}.
  {label, 281}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__hexOf', 1, 283}.
  {label, 282}.
    {line, [{location, "std@io@random.erl", 30}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__hexOf'}, 1}.
  {label, 283}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv__randomByte', 0, 285}.
  {label, 284}.
    {line, [{location, "std@io@random.erl", 31}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__randomByte'}, 0}.
  {label, 285}.
    {call_only, 0, {f, 23}}.

{function, '__bp_priv__randomBytesBody', 1, 287}.
  {label, 286}.
    {line, [{location, "std@io@random.erl", 32}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__randomBytesBody'}, 1}.
  {label, 287}.
    {call_only, 1, {f, 21}}.

{function, '__bp_priv__randomBytesOf', 1, 289}.
  {label, 288}.
    {line, [{location, "std@io@random.erl", 33}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__randomBytesOf'}, 1}.
  {label, 289}.
    {call_only, 1, {f, 25}}.

{function, '__bp_priv__secureTokenBody', 1, 291}.
  {label, 290}.
    {line, [{location, "std@io@random.erl", 34}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__secureTokenBody'}, 1}.
  {label, 291}.
    {call_only, 1, {f, 17}}.

{function, '__bp_priv__shuffleBody', 1, 293}.
  {label, 292}.
    {line, [{location, "std@io@random.erl", 35}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__shuffleBody'}, 1}.
  {label, 293}.
    {call_only, 1, {f, 15}}.

{function, '__bp_priv__uuidV4Body', 0, 295}.
  {label, 294}.
    {line, [{location, "std@io@random.erl", 36}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__uuidV4Body'}, 0}.
  {label, 295}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__wholeOf', 1, 297}.
  {label, 296}.
    {line, [{location, "std@io@random.erl", 37}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__wholeOf'}, 1}.
  {label, 297}.
    {call_only, 1, {f, 33}}.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 41}.
  {label, 40}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, exsplus}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, rand, seed, 2}, 2}.

{function, '__bp_tpl_0', 1, 37}.
  {label, 36}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_0'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1', 1, 47}.
  {label, 46}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_1'}, 1}.
  {label, 47}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 4}}.
    {move, {y, 1}, {y, 5}}.
  {label, 52}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 53}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 5}}.
    {move, {y, 6}, {y, 0}}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 7}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 52}}.
  {label, 53}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nil, {f, 54}, [{x, 0}]}.
    {jump, {f, 51}}.
  {label, 54}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 51}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 55}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 56}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 55}, [{x, 0}]}.
    {test, test_arity, {f, 55}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 55}}.
  {label, 56}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 57}, [{x, 0}]}.
    {jump, {f, 50}}.
  {label, 57}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 50}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_2', 1, 61}.
  {label, 60}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_2'}, 1}.
  {label, 61}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, strong_rand_bytes, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, #{mode => urlsafe, padding => false}}, {x, 1}}.
    {call_ext_last, 2, {extfunc, base64, encode, 2}, 2}.

{function, '__bp_tpl_3-t/0-fun-0-', 0, 69}.
  {label, 68}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_3-t/0-fun-0-'}, 0}.
  {label, 69}.
    {allocate, 13, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {integer, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, strong_rand_bytes, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_binary, {f, 72}, [{x, 0}]}.
    {gc_bif, byte_size, {f, 72}, 1, [{x, 0}], {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {integer, 16}]}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, decode_unsigned, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 96}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 4294967295}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 0}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 80}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {integer, 65535}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 64}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {integer, 4095}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 2}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 48}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {integer, 16383}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 3}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {move, {integer, 281474976710655}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 4}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {y, 5}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 73}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 32768}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bor', 2}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 10, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {put_list, {y, 5}, {x, 0}, {x, 0}}.
    {put_list, {y, 2}, {x, 0}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, [126, 56, 46, 49, 54, 46, 48, 98, 45, 126, 52, 46, 49, 54, 46, 48, 98, 45, 52, 126, 51, 46, 49, 54, 46, 48, 98, 45, 126, 52, 46, 49, 54, 46, 48, 98, 45, 126, 49, 50, 46, 49, 54, 46, 48, 98]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 13}.

{function, '__bp_tpl_3', 0, 65}.
  {label, 64}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_3'}, 0}.
  {label, 65}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_4', 1, 77}.
  {label, 76}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_4'}, 1}.
  {label, 77}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, strong_rand_bytes, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 81}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 82}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [126, 50, 46, 49, 54, 46, 48, 98]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 81}}.
  {label, 82}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 83}, [{x, 0}]}.
    {jump, {f, 80}}.
  {label, 83}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 80}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 7}.

{function, '-bp_at-', 2, 107}.
  {label, 106}.
    {line, [{location, "std@io@random.erl", 9}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_at-'}, 2}.
  {label, 107}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 109}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 108}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 109}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 108}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 108}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 141}.
  {label, 140}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_print'}, 1}.
  {label, 141}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 145}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 145}.
  {label, 144}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_show_top-'}, 1}.
  {label, 145}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 143}}.

{function, '-bp_show_elem-', 1, 147}.
  {label, 146}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_show_elem-'}, 1}.
  {label, 147}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 143}}.

{function, '__bp_show', 2, 143}.
  {label, 142}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_show'}, 2}.
  {label, 143}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 155}, [{x, 0}]}.
    {test, is_eq, {f, 154}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 155}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 156}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 147}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 156}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 158}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 157}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 157}, [{x, 0}]}.
    {test, is_ne_exact, {f, 157}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 157}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 157}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 162}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 163}}.
  {label, 162}.
    {test, is_eq_exact, {f, 159}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 163}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 143}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 157}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 147}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 158}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 160}, [{x, 0}]}.
    {test, is_ne_exact, {f, 160}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 160}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, undefined}]}.
  {label, 159}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 149}, 2}.
  {label, 160}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 161}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 149}.
  {label, 148}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tagged'}, 2}.
  {label, 149}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 164}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 164}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 164}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 165}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 151}, 3}.
  {label, 165}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 151}.
  {label, 150}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_render'}, 1}.
  {label, 151}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 166}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 166}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 167}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 167}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 153}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 153}.
  {label, 152}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_render_pair-'}, 1}.
  {label, 153}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 143}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 169}.
  {label, 168}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_stringify-'}, 1}.
  {label, 169}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 170}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 170}.
    {test, is_integer, {f, 171}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 171}.
    {call, 1, {f, 145}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 182}.
  {label, 181}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 182}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 186}}.
  {label, 186}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 188}}.
  {label, 188}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 189}}.
  {label, 190}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {y, 6}}.
    {jump, {f, 189}}.
  {label, 191}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 189}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 193}}.
  {label, 193}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 196}}.
  {label, 194}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 195}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 196}}.
  {label, 195}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 196}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 198}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 8}.
  {label, 198}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 199}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 199}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 2, 178}.
  {label, 177}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_5'}, 2}.
  {label, 178}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 182}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-hexOf/1-fun-0-', 1, 202}.
  {label, 201}.
    {line, [{location, "std@io@random.erl", 22}]}.
    {func_info, {atom, std@io@random}, {atom, '-hexOf/1-fun-0-'}, 1}.
  {label, 202}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 203}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 203}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 204}}.
  {label, 203}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:368:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 204}.
    {call, 1, {f, 27}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '-bp_join-', 2, 206}.
  {label, 205}.
    {line, [{location, "std@io@random.erl", 22}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_join-'}, 2}.
  {label, 206}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_prim_append', 2, 91}.
  {label, 90}.
    {line, [{location, "std@io@random.erl", 24}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_prim_append'}, 2}.
  {label, 91}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 271}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 271}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
