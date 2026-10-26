{module, std@hash}.
{exports, [{hmacSha256Base64Url, 2}, {sha1Base64, 1}, {sha256Base64Url, 1}, {equalsConstantTime, 2}, {pbkdf2Sha256, 4}, {sha256, 1}, {sha512, 1}, {md5, 1}, {hmacSha256, 2}, {contentHash, 1}, {strongHash, 1}, {cacheKey, 1}, {strongCacheKey, 1}, {etag, 1}, {weakEtag, 1}, {matches, 2}, {fingerprint, 2}, {'__bp_priv__array_flatten', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__base64Group', 4}, {'__bp_priv__base64Of', 3}, {'__bp_priv__bits32', 4}, {'__bp_priv__bytesBE', 1}, {'__bp_priv__bytesLE', 1}, {'__bp_priv__equalsConstantTimeBody', 2}, {'__bp_priv__frame', 1}, {'__bp_priv__halvesOf', 2}, {'__bp_priv__hexDigit', 1}, {'__bp_priv__hexOf', 1}, {'__bp_priv__hexValue', 3}, {'__bp_priv__hmacKeyBlock', 1}, {'__bp_priv__hmacSha256Base64UrlBody', 2}, {'__bp_priv__hmacSha256Body', 2}, {'__bp_priv__hmacSha256Bytes', 2}, {'__bp_priv__hmacWithPads', 3}, {'__bp_priv__lowerHalf', 1}, {'__bp_priv__md5Block', 5}, {'__bp_priv__md5Body', 1}, {'__bp_priv__md5Bytes', 1}, {'__bp_priv__md5Constants', 0}, {'__bp_priv__mix', 3}, {'__bp_priv__padOf', 2}, {'__bp_priv__padded', 4}, {'__bp_priv__panicText', 1}, {'__bp_priv__pbkdf2DeriveBody', 4}, {'__bp_priv__rotr32', 2}, {'__bp_priv__sha1Base64Body', 1}, {'__bp_priv__sha1Block', 3}, {'__bp_priv__sha1Bytes', 1}, {'__bp_priv__sha256Base64UrlBody', 1}, {'__bp_priv__sha256Block', 4}, {'__bp_priv__sha256Body', 1}, {'__bp_priv__sha256Bytes', 1}, {'__bp_priv__sha256Constants', 0}, {'__bp_priv__sha256Initial', 0}, {'__bp_priv__sha512Block', 4}, {'__bp_priv__sha512Body', 1}, {'__bp_priv__sha512Bytes', 1}, {'__bp_priv__sha512Constants', 0}, {'__bp_priv__sha512Initial', 0}, {'__bp_priv__smallInt', 1}, {'__bp_priv__strongHashBody', 1}, {'__bp_priv__upperHalf', 1}, {'__bp_priv__utf8Bytes', 1}, {'__bp_priv__utf8Of', 1}, {'__bp_priv__wordBE', 2}, {'__bp_priv__wordLE', 2}, {'__bp_priv__wordOf', 2}, {'__bp_priv__wrap32', 1}, {'__bp_priv__xorByte', 2}, {'__bp_priv__xorBytes', 2}, {'__bp_priv__zeroBytes', 1}]}.
{attributes, []}.
{labels, 1075}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@hash.erl", 1}]}.
    {func_info, {atom, std@hash}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 211}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 212}}.
  {label, 211}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 213}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 214}}.
  {label, 213}.
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
    {call, 2, {f, 216}}.
  {label, 214}.
  {label, 212}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@hash.erl", 2}]}.
    {func_info, {atom, std@hash}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 217}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 218}}.
  {label, 217}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 219}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 216}}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 216}}.
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
    {call, 2, {f, 216}}.
  {label, 220}.
  {label, 218}.
    {deallocate, 6}.
    return.
%%% std/hash — every hash std has, pure functions all (decision 106): the hex
%%% digests (`sha256`, `sha512`, `md5`, `hmacSha256` — was `crypto`), the
%%% digests the security fronts need in the shape they are compared in
%%% (base64url of the raw digest, RFC 7515; SHA-1 for the WebSocket accept
%%% key, RFC 6455; a constant-time compare), and the content hashes for cache
%%% keys, ETags and asset fingerprints (was `content_hash`). `crypto`'s
%%% `randomBytes` reads entropy and lives in `io/random.bp`.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/crypto.html
%%%              (`createHash`, `createHmac`, `.digest('base64' | 'base64url')`,
%%%               `timingSafeEqual`, `pbkdf2Sync`)
%%%   Erlang   — https://www.erlang.org/doc/apps/crypto/crypto.html
%%%              (`crypto:hash/2`, `crypto:mac/4`, `crypto:hash_equals/2`,
%%%               `crypto:pbkdf2_hmac/5`)
%%%              https://www.erlang.org/doc/apps/stdlib/base64.html
%%%              (`base64:encode/2` with `#{mode => urlsafe, padding => false}`)
%%%   RFC 4648 §5 (base64url), RFC 4231 (HMAC-SHA256), RFC 6455 §1.3
%%% 
%%% Each cell calls `crypto:hash/2` / `createHash` itself rather than a
%%% sibling function — the duplication is in the template string, not in
%%% behaviour.
%%% 
%%% Text in: every input is the UTF-8 bytes of a `string` (there is no
%%% byte type — `language-gaps.md`), so an HMAC key is text too.
% base64url (no padding) of the raw HMAC-SHA256 of `data` under `key` —
% the JWS HS256 signature (RFC 7515 §3) and a session-cookie MAC.

{function, hmacSha256Base64Url, 2, 129}.
  {label, 128}.
    {line, [{location, "std@hash.erl", 3}]}.
    {func_info, {atom, std@hash}, {atom, hmacSha256Base64Url}, 2}.
  {label, 129}.
    {call_only, 2, {f, 127}}.
% Standard base64 (with padding) of the raw SHA-1 of `data` — the
% `Sec-WebSocket-Accept` value of RFC 6455 §1.3. SHA-1 is here for that
% handshake only; it is not a signature primitive.

{function, sha1Base64, 1, 133}.
  {label, 132}.
    {line, [{location, "std@hash.erl", 4}]}.
    {func_info, {atom, std@hash}, {atom, sha1Base64}, 1}.
  {label, 133}.
    {call_only, 1, {f, 131}}.
% base64url (no padding) of the raw SHA-256 of `data` — 43 characters.

{function, sha256Base64Url, 1, 137}.
  {label, 136}.
    {line, [{location, "std@hash.erl", 5}]}.
    {func_info, {atom, std@hash}, {atom, sha256Base64Url}, 1}.
  {label, 137}.
    {call_only, 1, {f, 135}}.
% `a == b` in time that depends only on the length, not on where the two
% first differ — the compare a signature check must use (`==` on two
% signature strings is a byte-at-a-time timing oracle on both backends).
% Different lengths answer `false` without throwing: `timingSafeEqual` and
% `crypto:hash_equals/2` both raise on a length mismatch, so each template
% checks the byte length first (the length of a MAC is not secret).

{function, equalsConstantTime, 2, 150}.
  {label, 149}.
    {line, [{location, "std@hash.erl", 6}]}.
    {func_info, {atom, std@hash}, {atom, equalsConstantTime}, 2}.
  {label, 150}.
    {call_only, 2, {f, 139}}.
% ── 1.0.11-beta front 97: PBKDF2 ─────────────────────────────────────────────
% The cell behind `pbkdf2Sha256`: base64url (no padding) of the derived key.
% Node: `crypto.pbkdf2Sync(password, salt, iterations, length, 'sha256')`.
% Erlang: `crypto:pbkdf2_hmac(sha256, Password, Salt, Iterations, Length)`.
% PBKDF2-HMAC-SHA256 (RFC 8018 §5.2): `length` BYTES of key derived from
% `password` over `salt` in `iterations` rounds, as unpadded base64url — the
% shape a stored password hash is compared in (`equalsConstantTime`).
% `password` and `salt` are TEXT, their UTF-8 bytes (decision 175; there is no
% byte type): a salt that is itself base64 is derived over its characters,
% not over the bytes it encodes. The same answer on both targets for every
% input — the published vectors are the tests.
% 
% `iterations` and `length` are at least 1; anything else is a programming
% error, a panic with one text on both targets (each host raises its own
% otherwise), never an empty key.

{function, pbkdf2Sha256, 4, 7}.
  {label, 6}.
    {line, [{location, "std@hash.erl", 7}]}.
    {func_info, {atom, std@hash}, {atom, pbkdf2Sha256}, 4}.
  {label, 7}.
    {allocate, 5, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {test, is_lt, {f, 221}, [{y, 2}, {integer, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 222}}.
  {label, 221}.
    {move, {atom, false}, {x, 0}}.
  {label, 222}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 223}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 225}, [{y, 3}, {integer, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 225}.
    {move, {atom, false}, {x, 0}}.
  {label, 226}.
    {jump, {f, 224}}.
  {label, 223}.
    {move, {atom, true}, {x, 0}}.
  {label, 224}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq, {f, 227}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"hash.pbkdf2Sha256: iterations and length must be at least 1">>}, {x, 0}}.
    {call, 1, {f, 229}}.
    {jump, {f, 230}}.
  {label, 227}.
  {label, 230}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 3}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 4, {f, 232}, 5}.
% Internal, test scaffolding: the text a body panics with, `""` when it
% answered — `attempt` (decision 431), which a root module may import: it is
% not the harness.

{function, panicText, 1, 9}.
  {label, 8}.
    {line, [{location, "std@hash.erl", 8}]}.
    {func_info, {atom, std@hash}, {atom, panicText}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {test, is_tagged_tuple, {f, 234}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 233}}.
  {label, 234}.
    {test, is_tagged_tuple, {f, 235}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 237}}.
    {jump, {f, 233}}.
  {label, 235}.
    {case_end, {x, 0}}.
  {label, 233}.
    {deallocate, 2}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% ── hex digests (was `crypto`) ───────────────────────────────────────────────

{function, sha256, 1, 160}.
  {label, 159}.
    {line, [{location, "std@hash.erl", 9}]}.
    {func_info, {atom, std@hash}, {atom, sha256}, 1}.
  {label, 160}.
    {call_only, 1, {f, 152}}.

{function, sha512, 1, 170}.
  {label, 169}.
    {line, [{location, "std@hash.erl", 10}]}.
    {func_info, {atom, std@hash}, {atom, sha512}, 1}.
  {label, 170}.
    {call_only, 1, {f, 162}}.

{function, md5, 1, 180}.
  {label, 179}.
    {line, [{location, "std@hash.erl", 11}]}.
    {func_info, {atom, std@hash}, {atom, md5}, 1}.
  {label, 180}.
    {call_only, 1, {f, 172}}.
% HMAC-SHA256. `key` is the secret material; `data` is the message.
% Both lower to the host's keyed-hash primitive — Node's
% `crypto.createHmac('sha256', key).update(data).digest('hex')` and
% Erlang's `crypto:mac(hmac, sha256, key, data)`.

{function, hmacSha256, 2, 190}.
  {label, 189}.
    {line, [{location, "std@hash.erl", 12}]}.
    {func_info, {atom, std@hash}, {atom, hmacSha256}, 2}.
  {label, 190}.
    {call_only, 2, {f, 182}}.
% ── tests ────────────────────────────────────────────────────────────────────
% ── content hashes (was `content_hash`) ──────────────────────────────────────
% Stable hashes for cache keys, ETags and asset fingerprints (1.0.10-beta
% `01-std` front 03).
% 
% Reference:
%   RFC 9110 § 8.8.3 — https://www.rfc-editor.org/rfc/rfc9110#field.etag
%   Next.js caching  — https://nextjs.org/docs/app/getting-started/caching
%   Erlang           — https://www.erlang.org/doc/apps/crypto/crypto.html#hash/2
% 
% `strongHash` carries its own SHA-256 cell rather than calling `sha256`
% above; the truncation lives in the template.
% 
% TWO hashes, and the choice is not a matter of taste. `contentHash` is a
% djb2 fold rendered as lowercase hex: fast, stable across both targets,
% and TRIVIAL TO COLLIDE ON PURPOSE. Use it when a collision costs a wrong
% cache hit you control — an asset filename, an internal fingerprint.
% `strongHash` is SHA-256 truncated to 32 hex characters. Use it whenever
% the hashed value came from outside: a request header, a client-supplied
% tag, a key that spans a user boundary.
% 
% The `contentHash` templates were lifted from
% `repository/emilia/modules/emilia/src/emilia.bp` (`hashHex`). Every target
% folds the string's CODE POINTS (decision 260, decision 169's unit):
% `contentHash("🎉")` is `djb2([127881])` everywhere — the Node cell walks
% `Array.from(s)`, which iterates by code point, where `hashHex` still folds
% UTF-16 units and so differs from it for a character above U+FFFF.
% Collapsing `emilia.hashHex` onto std is an `emilia`-owned change. On wasm,
% and at comptime on every target, it is std-wasm's (`modules/std-wasm`,
% decision 440): its `std:` cell is the one implementation both read.

{function, contentHash, 1, 206}.
  {label, 205}.
    {line, [{location, "std@hash.erl", 13}]}.
    {func_info, {atom, std@hash}, {atom, contentHash}, 1}.
  {label, 206}.
    {call_only, 1, {f, 192}}.

{function, strongHash, 1, 210}.
  {label, 209}.
    {line, [{location, "std@hash.erl", 14}]}.
    {func_info, {atom, std@hash}, {atom, strongHash}, 1}.
  {label, 210}.
    {call_only, 1, {f, 208}}.
% ── cache keys — framed, never joined ────────────────────────────────────────
% A key over several parts. Each part is length-prefixed, so no two different
% part lists can collide: ["user:1", "profile"] and ["user", "1:profile"] frame
% to `6:user:1|7:profile` and `4:user|9:1:profile` and therefore hash to
% different keys. A cache that collides across a user boundary serves one user
% another user's page, so the framing is the whole reason this function exists
% instead of a `join`.

{function, cacheKey, 1, 11}.
  {label, 10}.
    {line, [{location, "std@hash.erl", 15}]}.
    {func_info, {atom, std@hash}, {atom, cacheKey}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 15}}.
    {call_last, 1, {f, 192}, 1}.
% The same framing over the strong hash, for keys built from input the caller
% did not choose.

{function, strongCacheKey, 1, 13}.
  {label, 12}.
    {line, [{location, "std@hash.erl", 16}]}.
    {func_info, {atom, std@hash}, {atom, strongCacheKey}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 15}}.
    {call_last, 1, {f, 208}, 1}.
% `<length>:<part>` per part, `|` between parts. The one place a multi-part
% key is rendered, so no function in this module joins parts unframed.

{function, frame, 1, 15}.
  {label, 14}.
    {line, [{location, "std@hash.erl", 17}]}.
    {func_info, {atom, std@hash}, {atom, frame}, 1}.
  {label, 15}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 243}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 279}, 3}.
% ── ETags (RFC 9110 § 8.8.3) ─────────────────────────────────────────────────
% A strong ETag, quoted as RFC 9110 requires. The quotes are part of the value:
% a caller who has to remember to add them is a caller who will forget.

{function, etag, 1, 17}.
  {label, 16}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, etag}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 192}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 275}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, weakEtag, 1, 19}.
  {label, 18}.
    {line, [{location, "std@hash.erl", 19}]}.
    {func_info, {atom, std@hash}, {atom, weakEtag}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 192}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"W/\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 275}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.
% The 304 decision. Handles the three shapes a handler actually receives: an
% exact match, the `*` wildcard, and a comma-separated candidate list. The
% membership test is `indexOf`, not `Array.contains`: `contains` is a
% `default fn`, which a consumer's embedded copy of this module emits
% verbatim on commonJS (`libs/std/AGENTS.md` § Conventions).

{function, matches, 2, 21}.
  {label, 20}.
    {line, [{location, "std@hash.erl", 20}]}.
    {func_info, {atom, std@hash}, {atom, matches}, 2}.
  {label, 21}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {test, is_eq_exact, {f, 280}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 281}}.
  {label, 280}.
    {move, {atom, false}, {x, 0}}.
  {label, 281}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 283}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 300}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 302}}.
    {test, is_ne_exact, {f, 305}, [{x, 0}, {integer, -1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 306}}.
  {label, 305}.
    {move, {atom, false}, {x, 0}}.
  {label, 306}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 302}}.
    {test, is_ne_exact, {f, 307}, [{x, 0}, {integer, -1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 308}}.
  {label, 307}.
    {move, {atom, false}, {x, 0}}.
  {label, 308}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq, {f, 309}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 310}}.
  {label, 309}.
    {move, {y, 8}, {x, 0}}.
  {label, 310}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 311}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 312}}.
  {label, 311}.
    {move, {y, 9}, {x, 0}}.
  {label, 312}.
    {deallocate, 12}.
    return.
% ── fingerprints ─────────────────────────────────────────────────────────────
% `app.js` → `app.<hash>.js`. The extension stays last: a browser and a CDN
% both dispatch on it, and a hash appended after it breaks both. A leading
% dot (`.gitignore`) is not an extension boundary, and a name without an
% extension gains no trailing dot (`LICENSE` → `LICENSE.<hash>`).
% 
% The extension is measured as the last `.`-separated piece. It was written
% that way when Erlang's `lastIndexOf` answered a BYTE offset while
% `length`/`slice` counted characters; the four agree now (decision 169), and
% the piece measure stays because it is the same cut.

{function, fingerprint, 2, 23}.
  {label, 22}.
    {line, [{location, "std@hash.erl", 21}]}.
    {func_info, {atom, std@hash}, {atom, fingerprint}, 2}.
  {label, 23}.
    {allocate, 16, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 192}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 283}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 313}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 313}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 314}}.
  {label, 313}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:390:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 314}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 316}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_ne_exact, {f, 319}, [{y, 4}, {atom, undefined}]}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 245}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 321}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 321}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 322}}.
  {label, 321}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:391:50">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 322}.
    {jump, {f, 320}}.
  {label, 319}.
    {move, {integer, 0}, {x, 0}}.
  {label, 320}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 323}, [{integer, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 245}}.
    {test, is_lt, {f, 325}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 326}}.
  {label, 325}.
    {move, {atom, false}, {x, 0}}.
  {label, 326}.
    {jump, {f, 324}}.
  {label, 323}.
    {move, {atom, false}, {x, 0}}.
  {label, 324}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 245}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {test, is_ge, {f, 327}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 327}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 328}}.
  {label, 327}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:393:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 328}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 329}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 332}}.
    {jump, {f, 330}}.
  {label, 329}.
    {move, {y, 0}, {x, 0}}.
  {label, 330}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 333}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 245}}.
    {move, {y, 7}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 332}}.
    {jump, {f, 334}}.
  {label, 333}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 334}.
    {move, {x, 0}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 275}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 16}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% 
% Every expected hex below is a LITERAL, not a second call: a literal is the
% only form that catches the two targets drifting apart.
% ── the wasm bodies (decision 238) ──────────────────────────────────────────
% wasm has no host to hash with, so each cell above names one of these
% private bodies with `#[compiler.external(.Wasm(fn: …))]`. They run only on wasm —
% commonJS and erlang call their host — and they answer what Node's `crypto`
% answers: SHA-256 and SHA-512 (FIPS 180-4), SHA-1 (RFC 3174), MD5
% (RFC 1321), HMAC (RFC 2104), PBKDF2 (RFC 8018 §5.2), base64 (RFC 4648 §4,
% §5) and the djb2 fold over code points (decision 260). botopink has no bit operation and wasm no `i64` this backend
% lowers, so a 32-bit word is a whole `f64` in [0, 2^32), its bit
% operations exact arithmetic (`wrap32`, `rotr32`, `mix`, `bits32`); a
% 64-bit SHA-512 word is two of them. A word is stored in an
% `array<i32>` as two 16-bit halves, since a float in an array keeps only
% its `f32`; a constant is the hex its standard prints. A byte is an `i32` in 0..255; a string's bytes are its UTF-8.

{function, sha256Body, 1, 25}.
  {label, 24}.
    {line, [{location, "std@hash.erl", 22}]}.
    {func_info, {atom, std@hash}, {atom, sha256Body}, 1}.
  {label, 25}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 101}}.
    {call_last, 1, {f, 51}, 1}.

{function, sha256Base64UrlBody, 1, 27}.
  {label, 26}.
    {line, [{location, "std@hash.erl", 23}]}.
    {func_info, {atom, std@hash}, {atom, sha256Base64UrlBody}, 1}.
  {label, 27}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 101}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call_last, 3, {f, 53}, 1}.

{function, strongHashBody, 1, 29}.
  {label, 28}.
    {line, [{location, "std@hash.erl", 24}]}.
    {func_info, {atom, std@hash}, {atom, strongHashBody}, 1}.
  {label, 29}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 101}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{integer, 16}, {integer, 0}], {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {call_last, 1, {f, 51}, 4}.

{function, sha512Body, 1, 31}.
  {label, 30}.
    {line, [{location, "std@hash.erl", 25}]}.
    {func_info, {atom, std@hash}, {atom, sha512Body}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 113}}.
    {call_last, 1, {f, 51}, 1}.

{function, md5Body, 1, 33}.
  {label, 32}.
    {line, [{location, "std@hash.erl", 26}]}.
    {func_info, {atom, std@hash}, {atom, md5Body}, 1}.
  {label, 33}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 109}}.
    {call_last, 1, {f, 51}, 1}.

{function, sha1Base64Body, 1, 35}.
  {label, 34}.
    {line, [{location, "std@hash.erl", 27}]}.
    {func_info, {atom, std@hash}, {atom, sha1Base64Body}, 1}.
  {label, 35}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 105}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call_last, 3, {f, 53}, 1}.

{function, hmacSha256Body, 2, 37}.
  {label, 36}.
    {line, [{location, "std@hash.erl", 28}]}.
    {func_info, {atom, std@hash}, {atom, hmacSha256Body}, 2}.
  {label, 37}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 93}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 95}}.
    {call_last, 1, {f, 51}, 4}.

{function, hmacSha256Base64UrlBody, 2, 39}.
  {label, 38}.
    {line, [{location, "std@hash.erl", 29}]}.
    {func_info, {atom, std@hash}, {atom, hmacSha256Base64UrlBody}, 2}.
  {label, 39}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 93}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 95}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call_last, 3, {f, 53}, 4}.
% Every byte compared, no early exit; a length mismatch is `false`.

{function, equalsConstantTimeBody, 2, 41}.
  {label, 40}.
    {line, [{location, "std@hash.erl", 30}]}.
    {func_info, {atom, std@hash}, {atom, equalsConstantTimeBody}, 2}.
  {label, 41}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 335}, [{x, 1}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 335}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@hash.erl", 31}]}.
  {label, 336}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 337}, [{y, 5}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 338}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 339}}.
  {label, 338}.
    {move, {integer, 0}, {x, 0}}.
  {label, 339}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 340}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 341}}.
  {label, 340}.
    {move, {integer, 0}, {x, 0}}.
  {label, 341}.
    {gc_bif, '-', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 342}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 342}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 343}}.
  {label, 342}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:570:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 343}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 9}, {y, 9}], {x, 0}}.
    {test, is_ge, {f, 344}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 344}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 345}}.
  {label, 344}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:571:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 345}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 346}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 346}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 347}}.
  {label, 346}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:572:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 347}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 336}}.
  {label, 337}.
    {test, is_eq_exact, {f, 348}, [{y, 4}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 349}}.
  {label, 348}.
    {move, {atom, false}, {x, 0}}.
  {label, 349}.
    {deallocate, 11}.
    return.
% RFC 8018 §5.2 over HMAC-SHA256: block `i` is U1 ^ … ^ Uc, U1 the HMAC of
% the salt and `i` (four bytes, big-endian), each next U the HMAC of the
% last; the key is the blocks' first `length` bytes.

{function, pbkdf2DeriveBody, 4, 43}.
  {label, 42}.
    {line, [{location, "std@hash.erl", 31}]}.
    {func_info, {atom, std@hash}, {atom, pbkdf2DeriveBody}, 4}.
  {label, 43}.
    {allocate, 18, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 45}}.
    {call, 1, {f, 93}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 54}, {x, 1}}.
    {call, 2, {f, 97}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 92}, {x, 1}}.
    {call, 2, {f, 97}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "std@hash.erl", 32}]}.
  {label, 350}.
    {move, {y, 8}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 351}, [{x, 0}, {y, 3}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 9}, {integer, 256}], {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 9}, {integer, 256}], {x, 0}}.
    {test, is_ge, {f, 352}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 352}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 353}}.
  {label, 352}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:596:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 353}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 256}], {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 9}, {integer, 65536}], {x, 0}}.
    {test, is_ge, {f, 354}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 354}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 355}}.
  {label, 354}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:595:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 355}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 256}], {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 9}, {integer, 16777216}], {x, 0}}.
    {test, is_ge, {f, 356}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 356}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 357}}.
  {label, 356}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:594:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 357}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {call, 3, {f, 99}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {line, [{location, "std@hash.erl", 32}]}.
  {label, 358}.
    {test, is_lt, {f, 359}, [{y, 14}, {y, 2}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 12}, {x, 2}}.
    {move, {y, 6}, {x, 1}}.
    {call, 3, {f, 99}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 13}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call, 2, {f, 61}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 14}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 360}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 360}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 361}}.
  {label, 360}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:605:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 361}.
    {move, {x, 0}, {y, 14}}.
    {jump, {f, 358}}.
  {label, 359}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 362}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 362}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 363}}.
  {label, 362}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:608:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 363}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 350}}.
  {label, 351}.
    {test, is_ne_exact, {f, 364}, [{y, 3}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 365}}.
  {label, 364}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 365}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call_last, 3, {f, 53}, 18}.
% ── bytes and text ──

{function, utf8Of, 1, 45}.
  {label, 44}.
    {line, [{location, "std@hash.erl", 32}]}.
    {func_info, {atom, std@hash}, {atom, utf8Of}, 1}.
  {label, 45}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 367}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 377}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 1, {f, 390}, 4}.

{function, utf8Bytes, 1, 47}.
  {label, 46}.
    {line, [{location, "std@hash.erl", 33}]}.
    {func_info, {atom, std@hash}, {atom, utf8Bytes}, 1}.
  {label, 47}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 391}, [{y, 0}, {integer, 128}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 391}.
    {test, is_lt, {f, 392}, [{y, 0}, {integer, 2048}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 393}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 393}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 394}}.
  {label, 393}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:626:47">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 394}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 395}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 395}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 396}}.
  {label, 395}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:626:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 396}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 192}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 397}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 397}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 398}}.
  {label, 397}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:626:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 398}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 392}.
    {test, is_lt, {f, 399}, [{y, 0}, {integer, 65536}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 400}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 400}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 401}}.
  {label, 400}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:628:60">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 401}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 402}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 402}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 403}}.
  {label, 402}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:628:44">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 403}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 404}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 404}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 405}}.
  {label, 404}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:628:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 405}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 4096}], {x, 0}}.
    {test, is_ge, {f, 406}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 406}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 407}}.
  {label, 406}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:628:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 407}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 224}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 408}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 408}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 409}}.
  {label, 408}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:628:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 409}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 399}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 410}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 410}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 411}}.
  {label, 410}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:633:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 411}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 412}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 412}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 413}}.
  {label, 412}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:632:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 413}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 414}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 414}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 415}}.
  {label, 414}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:632:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 415}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 4096}], {x, 0}}.
    {test, is_ge, {f, 416}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 416}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 417}}.
  {label, 416}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:631:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 417}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 418}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 418}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 419}}.
  {label, 418}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:631:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 419}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 262144}], {x, 0}}.
    {test, is_ge, {f, 420}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 420}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 421}}.
  {label, 420}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:630:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 421}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 240}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 422}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 422}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 423}}.
  {label, 422}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:630:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 423}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, hexDigit, 1, 49}.
  {label, 48}.
    {line, [{location, "std@hash.erl", 34}]}.
    {func_info, {atom, std@hash}, {atom, hexDigit}, 1}.
  {label, 49}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0123456789abcdef">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 426}}.
    {test, is_ne_exact, {f, 424}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 448}}.
  {label, 424}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 448}.
    {deallocate, 2}.
    return.

{function, hexOf, 1, 51}.
  {label, 50}.
    {line, [{location, "std@hash.erl", 35}]}.
    {func_info, {atom, std@hash}, {atom, hexOf}, 1}.
  {label, 51}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 450}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 279}, 3}.
% RFC 4648 base64: §5's alphabet when `url`, `=` padding when `pad`.

{function, base64Of, 3, 53}.
  {label, 52}.
    {line, [{location, "std@hash.erl", 36}]}.
    {func_info, {atom, std@hash}, {atom, base64Of}, 3}.
  {label, 53}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 453}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_">>}, {x, 0}}.
    {jump, {f, 454}}.
  {label, 453}.
    {move, {literal, <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/">>}, {x, 0}}.
  {label, 454}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@hash.erl", 37}]}.
  {label, 455}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 5}], {x, 0}}.
    {test, is_ge, {f, 457}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 457}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 458}}.
  {label, 457}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:653:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 458}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 456}, [{x, 1}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 4, {f, 55}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 275}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 459}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 459}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 460}}.
  {label, 459}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:655:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 460}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 455}}.
  {label, 456}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, base64Group, 4, 55}.
  {label, 54}.
    {line, [{location, "std@hash.erl", 37}]}.
    {func_info, {atom, std@hash}, {atom, base64Group}, 4}.
  {label, 55}.
    {allocate, 20, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{integer, 3}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 461}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 461}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 462}}.
  {label, 461}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:666:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 462}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 463}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 463}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 464}}.
  {label, 463}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:666:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 464}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 466}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 466}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 467}}.
  {label, 466}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:667:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 467}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 465}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 468}}.
  {label, 465}.
    {move, {integer, 0}, {x, 0}}.
  {label, 468}.
    {move, {x, 0}, {y, 6}}.
    {test, is_lt, {f, 469}, [{integer, 1}, {y, 4}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 472}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 472}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 473}}.
  {label, 472}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:669:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 473}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 474}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 474}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 475}}.
  {label, 474}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:669:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 475}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 471}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 476}}.
  {label, 471}.
    {move, {integer, 0}, {x, 0}}.
  {label, 476}.
    {jump, {f, 470}}.
  {label, 469}.
    {move, {integer, 0}, {x, 0}}.
  {label, 470}.
    {move, {x, 0}, {y, 8}}.
    {test, is_lt, {f, 477}, [{integer, 2}, {y, 4}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 480}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 480}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 481}}.
  {label, 480}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:672:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 481}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 482}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 482}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 483}}.
  {label, 482}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:672:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 483}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 479}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 484}}.
  {label, 479}.
    {move, {integer, 0}, {x, 0}}.
  {label, 484}.
    {jump, {f, 478}}.
  {label, 477}.
    {move, {integer, 0}, {x, 0}}.
  {label, 478}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 485}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {jump, {f, 486}}.
  {label, 485}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 486}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 488}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 488}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 489}}.
  {label, 488}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:675:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 489}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 426}}.
    {test, is_ne_exact, {f, 487}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 490}}.
  {label, 487}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 490}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 492}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 492}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 493}}.
  {label, 492}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:676:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 493}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 8}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 494}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 494}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 495}}.
  {label, 494}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:676:45">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 495}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 496}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 496}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 497}}.
  {label, 496}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:676:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 497}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 426}}.
    {test, is_ne_exact, {f, 491}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 498}}.
  {label, 491}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 498}.
    {move, {x, 0}, {y, 15}}.
    {test, is_lt, {f, 499}, [{integer, 1}, {y, 4}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 8}, {integer, 16}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 502}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 502}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 503}}.
  {label, 502}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:678:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 503}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 10}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 504}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 504}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 505}}.
  {label, 504}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:678:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 505}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 506}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 506}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 507}}.
  {label, 506}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:678:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 507}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 426}}.
    {test, is_ne_exact, {f, 501}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {jump, {f, 508}}.
  {label, 501}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 508}.
    {jump, {f, 500}}.
  {label, 499}.
    {move, {y, 11}, {x, 0}}.
  {label, 500}.
    {move, {x, 0}, {y, 17}}.
    {test, is_lt, {f, 509}, [{integer, 2}, {y, 4}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 10}, {integer, 64}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 426}}.
    {test, is_ne_exact, {f, 511}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {jump, {f, 512}}.
  {label, 511}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 512}.
    {jump, {f, 510}}.
  {label, 509}.
    {move, {y, 11}, {x, 0}}.
  {label, 510}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 13}, {x, 0}}.
    {move, {y, 15}, {x, 1}}.
    {call, 2, {f, 514}}.
    {move, {y, 17}, {x, 1}}.
    {call, 2, {f, 514}}.
    {move, {y, 19}, {x, 1}}.
    {call, 2, {f, 514}}.
    {deallocate, 20}.
    return.
% `n` zero bytes, by doubling (`array.repeat` and `array.range` recurse once
% per element).

{function, zeroBytes, 1, 57}.
  {label, 56}.
    {line, [{location, "std@hash.erl", 38}]}.
    {func_info, {atom, std@hash}, {atom, zeroBytes}, 1}.
  {label, 57}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@hash.erl", 39}]}.
  {label, 516}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 517}, [{x, 0}, {y, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 516}}.
  {label, 517}.
    {test, is_ne_exact, {f, 518}, [{y, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 3, {extfunc, lists, sublist, 3}, 3}.
  {label, 518}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 3}.

{function, xorByte, 2, 59}.
  {label, 58}.
    {line, [{location, "std@hash.erl", 39}]}.
    {func_info, {atom, std@hash}, {atom, xorByte}, 2}.
  {label, 59}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@hash.erl", 40}]}.
  {label, 520}.
    {test, is_lt, {f, 521}, [{y, 5}, {integer, 256}]}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'rem', {f, 0}, 2, [{y, 4}, {integer, 2}], {x, 0}}.
    {test, is_ne_exact, {f, 522}, [{x, 1}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 5}], {x, 0}}.
    {test, is_ge, {f, 523}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 523}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 524}}.
  {label, 523}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:702:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 524}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 525}}.
  {label, 522}.
  {label, 525}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 526}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 526}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 527}}.
  {label, 526}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:703:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 527}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 4}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 528}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 528}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 529}}.
  {label, 528}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:704:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 529}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 530}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 530}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 531}}.
  {label, 530}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:705:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 531}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 520}}.
  {label, 521}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, xorBytes, 2, 61}.
  {label, 60}.
    {line, [{location, "std@hash.erl", 40}]}.
    {func_info, {atom, std@hash}, {atom, xorBytes}, 2}.
  {label, 61}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 533}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 539}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 4}.
% ── words ──

{function, wrap32, 1, 63}.
  {label, 62}.
    {line, [{location, "std@hash.erl", 41}]}.
    {func_info, {atom, std@hash}, {atom, wrap32}, 1}.
  {label, 63}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 4294967296.0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {deallocate, 3}.
    return.
% `x` rotated right by n bits, `p` = 2^n.

{function, rotr32, 2, 65}.
  {label, 64}.
    {line, [{location, "std@hash.erl", 42}]}.
    {func_info, {atom, std@hash}, {atom, rotr32}, 2}.
  {label, 65}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 3, {f, 67}, 2}.
% The low 32 bits of (y:x) >> n, `p` = 2^n: x's bits shifted down and y's
% low n bits above them.

{function, mix, 3, 67}.
  {label, 66}.
    {line, [{location, "std@hash.erl", 43}]}.
    {func_info, {atom, std@hash}, {atom, mix}, 3}.
  {label, 67}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne, {f, 540}, [{y, 2}, {integer, 0}]}.
    {jump, {f, 541}}.
  {label, 540}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/hash.bp:728:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 541}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {y, 2}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ne, {f, 542}, [{y, 2}, {integer, 0}]}.
    {jump, {f, 543}}.
  {label, 542}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/hash.bp:729:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 543}.
    {gc_bif, '/', {f, 0}, 0, [{y, 1}, {y, 2}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_ne, {f, 544}, [{y, 2}, {integer, 0}]}.
    {jump, {f, 545}}.
  {label, 544}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/hash.bp:730:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 545}.
    {gc_bif, '/', {f, 0}, 0, [{float, 4294967296.0}, {y, 2}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {deallocate, 7}.
    return.
% One of four bitwise functions of three words, bit by bit: `mode` 0 is
% x ^ y ^ z, 1 chooses y where x is set and z elsewhere, 2 is the
% majority, 3 is MD5's y ^ (x | ~z).

{function, bits32, 4, 69}.
  {label, 68}.
    {line, [{location, "std@hash.erl", 44}]}.
    {func_info, {atom, std@hash}, {atom, bits32}, 4}.
  {label, 69}.
    {allocate, 19, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "std@hash.erl", 45}]}.
  {label, 546}.
    {test, is_lt, {f, 547}, [{y, 9}, {integer, 32}]}.
    {gc_bif, '/', {f, 0}, 0, [{y, 4}, {float, 2.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 5}, {float, 2.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 6}, {float, 2.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 10}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 11}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {gc_bif, '*', {f, 0}, 0, [{float, 2.0}, {y, 12}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 13}, {y, 14}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 15}], {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {test, is_eq_exact, {f, 548}, [{y, 3}, {integer, 0}]}.
    {test, is_eq_exact, {f, 549}, [{y, 16}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 550}}.
  {label, 549}.
    {move, {atom, false}, {x, 0}}.
  {label, 550}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 551}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 553}, [{y, 16}, {float, 3.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 554}}.
  {label, 553}.
    {move, {atom, false}, {x, 0}}.
  {label, 554}.
    {jump, {f, 552}}.
  {label, 551}.
    {move, {atom, true}, {x, 0}}.
  {label, 552}.
    {move, {x, 0}, {y, 17}}.
    {jump, {f, 555}}.
  {label, 548}.
  {label, 555}.
    {test, is_eq_exact, {f, 556}, [{y, 3}, {integer, 1}]}.
    {test, is_eq_exact, {f, 557}, [{y, 13}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 558}}.
  {label, 557}.
    {move, {atom, false}, {x, 0}}.
  {label, 558}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 559}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 561}, [{y, 14}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 562}}.
  {label, 561}.
    {move, {atom, false}, {x, 0}}.
  {label, 562}.
    {jump, {f, 560}}.
  {label, 559}.
    {move, {atom, false}, {x, 0}}.
  {label, 560}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 563}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 565}, [{y, 13}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 566}}.
  {label, 565}.
    {move, {atom, false}, {x, 0}}.
  {label, 566}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 567}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 569}, [{y, 15}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 570}}.
  {label, 569}.
    {move, {atom, false}, {x, 0}}.
  {label, 570}.
    {jump, {f, 568}}.
  {label, 567}.
    {move, {atom, false}, {x, 0}}.
  {label, 568}.
    {jump, {f, 564}}.
  {label, 563}.
    {move, {atom, true}, {x, 0}}.
  {label, 564}.
    {move, {x, 0}, {y, 17}}.
    {jump, {f, 571}}.
  {label, 556}.
  {label, 571}.
    {test, is_eq_exact, {f, 572}, [{y, 3}, {integer, 2}]}.
    {test, is_ge, {f, 573}, [{y, 16}, {float, 2.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 574}}.
  {label, 573}.
    {move, {atom, false}, {x, 0}}.
  {label, 574}.
    {move, {x, 0}, {y, 17}}.
    {jump, {f, 575}}.
  {label, 572}.
  {label, 575}.
    {test, is_eq_exact, {f, 576}, [{y, 3}, {integer, 3}]}.
    {test, is_eq_exact, {f, 578}, [{y, 13}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 579}}.
  {label, 578}.
    {move, {atom, false}, {x, 0}}.
  {label, 579}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 580}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 582}, [{y, 15}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 583}}.
  {label, 582}.
    {move, {atom, false}, {x, 0}}.
  {label, 583}.
    {jump, {f, 581}}.
  {label, 580}.
    {move, {atom, true}, {x, 0}}.
  {label, 581}.
    {test, is_eq, {f, 577}, [{x, 0}, {atom, true}]}.
    {move, {float, 1.0}, {x, 0}}.
    {jump, {f, 584}}.
  {label, 577}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 584}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 14}, {y, 18}], {x, 0}}.
    {test, is_eq_exact, {f, 585}, [{x, 0}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 586}}.
  {label, 585}.
    {move, {atom, false}, {x, 0}}.
  {label, 586}.
    {move, {x, 0}, {y, 17}}.
    {jump, {f, 587}}.
  {label, 576}.
  {label, 587}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq, {f, 588}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {y, 8}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 589}}.
  {label, 588}.
  {label, 589}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 11}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 8}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 590}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 590}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 591}}.
  {label, 590}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:765:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 591}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 546}}.
  {label, 547}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 19}.
    return.
% A whole `v` in 0..65535 as an `i32`.

{function, smallInt, 1, 71}.
  {label, 70}.
    {line, [{location, "std@hash.erl", 45}]}.
    {func_info, {atom, std@hash}, {atom, smallInt}, 1}.
  {label, 71}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 32768}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 32768.0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@hash.erl", 46}]}.
  {label, 592}.
    {test, is_lt, {f, 593}, [{integer, 0}, {y, 3}]}.
    {test, is_ge, {f, 594}, [{y, 2}, {y, 4}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 595}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 595}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 596}}.
  {label, 595}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:778:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 596}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 597}}.
  {label, 594}.
  {label, 597}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 598}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 598}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 599}}.
  {label, 598}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:781:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 599}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 4}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 592}}.
  {label, 593}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, upperHalf, 1, 73}.
  {label, 72}.
    {line, [{location, "std@hash.erl", 46}]}.
    {func_info, {atom, std@hash}, {atom, upperHalf}, 1}.
  {label, 73}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 65536.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {call_last, 1, {f, 71}, 1}.

{function, lowerHalf, 1, 75}.
  {label, 74}.
    {line, [{location, "std@hash.erl", 47}]}.
    {func_info, {atom, std@hash}, {atom, lowerHalf}, 1}.
  {label, 75}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 65536.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 65536.0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {call_last, 1, {f, 71}, 3}.
% Word `i` of a halves array.

{function, wordOf, 2, 77}.
  {label, 76}.
    {line, [{location, "std@hash.erl", 48}]}.
    {func_info, {atom, std@hash}, {atom, wordOf}, 2}.
  {label, 77}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 2}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 601}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 601}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 602}}.
  {label, 601}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:797:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 602}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 600}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 603}}.
  {label, 600}.
    {move, {integer, 0}, {x, 0}}.
  {label, 603}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 65536.0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 2}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 605}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 605}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 606}}.
  {label, 605}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:797:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 606}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 607}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 607}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 608}}.
  {label, 607}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:797:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 608}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 604}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 609}}.
  {label, 604}.
    {move, {integer, 0}, {x, 0}}.
  {label, 609}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {deallocate, 6}.
    return.

{function, wordBE, 2, 79}.
  {label, 78}.
    {line, [{location, "std@hash.erl", 49}]}.
    {func_info, {atom, std@hash}, {atom, wordBE}, 2}.
  {label, 79}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 610}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 611}}.
  {label, 610}.
    {move, {integer, 0}, {x, 0}}.
  {label, 611}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 16777216.0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 613}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 613}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 614}}.
  {label, 613}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:802:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 614}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 612}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 615}}.
  {label, 612}.
    {move, {integer, 0}, {x, 0}}.
  {label, 615}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 65536.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 617}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 617}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 618}}.
  {label, 617}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:803:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 618}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 616}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 619}}.
  {label, 616}.
    {move, {integer, 0}, {x, 0}}.
  {label, 619}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 256.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 621}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 621}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 622}}.
  {label, 621}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:804:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 622}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 620}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 623}}.
  {label, 620}.
    {move, {integer, 0}, {x, 0}}.
  {label, 623}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {deallocate, 12}.
    return.

{function, wordLE, 2, 81}.
  {label, 80}.
    {line, [{location, "std@hash.erl", 50}]}.
    {func_info, {atom, std@hash}, {atom, wordLE}, 2}.
  {label, 81}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 625}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 625}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 626}}.
  {label, 625}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:808:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 626}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 624}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 627}}.
  {label, 624}.
    {move, {integer, 0}, {x, 0}}.
  {label, 627}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 16777216.0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 629}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 629}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 630}}.
  {label, 629}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:809:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 630}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 628}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 631}}.
  {label, 628}.
    {move, {integer, 0}, {x, 0}}.
  {label, 631}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 65536.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 633}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 633}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 634}}.
  {label, 633}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:810:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 634}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 632}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 635}}.
  {label, 632}.
    {move, {integer, 0}, {x, 0}}.
  {label, 635}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 256.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 636}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 637}}.
  {label, 636}.
    {move, {integer, 0}, {x, 0}}.
  {label, 637}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {deallocate, 12}.
    return.
% The `count` hex digits of `w` from `start` as a whole number.

{function, hexValue, 3, 83}.
  {label, 82}.
    {line, [{location, "std@hash.erl", 51}]}.
    {func_info, {atom, std@hash}, {atom, hexValue}, 3}.
  {label, 83}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {float, 0.0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@hash.erl", 52}]}.
  {label, 638}.
    {test, is_lt, {f, 639}, [{y, 4}, {y, 2}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 640}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 640}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 641}}.
  {label, 640}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:819:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 641}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 379}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_lt, {f, 642}, [{y, 5}, {integer, 58}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 5}, {integer, 48}], {x, 0}}.
    {test, is_ge, {f, 644}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 644}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 645}}.
  {label, 644}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:820:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 645}.
    {jump, {f, 643}}.
  {label, 642}.
    {gc_bif, '-', {f, 0}, 0, [{y, 5}, {integer, 87}], {x, 0}}.
    {test, is_ge, {f, 646}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 646}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 647}}.
  {label, 646}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:820:47">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 647}.
  {label, 643}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {float, 16.0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 6}, {float, 1.0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 648}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 648}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 649}}.
  {label, 648}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:822:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 649}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 638}}.
  {label, 639}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.
% Space-separated hex words of `digits` (8 or 16) digits as 16-bit halves.

{function, halvesOf, 2, 85}.
  {label, 84}.
    {line, [{location, "std@hash.erl", 52}]}.
    {func_info, {atom, std@hash}, {atom, halvesOf}, 2}.
  {label, 85}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@hash.erl", 53}]}.
  {label, 650}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 651}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 3}, {x, 1}}.
    {call, 3, {f, 83}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 8}], {x, 0}}.
    {test, is_ge, {f, 653}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 653}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 654}}.
  {label, 653}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:834:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 654}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 655}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 655}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 656}}.
  {label, 655}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:834:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 656}.
    {test, is_ne_exact, {f, 657}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 658}}.
  {label, 657}.
    {move, {literal, {panic, <<"integer division by zero: % on i32 at src/hash.bp:834:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 658}.
    {gc_bif, 'rem', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 652}, [{x, 0}, {y, 1}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 9}], {x, 0}}.
    {test, is_ge, {f, 660}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 660}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 661}}.
  {label, 660}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:834:56">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 661}.
    {jump, {f, 659}}.
  {label, 652}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 8}], {x, 0}}.
    {test, is_ge, {f, 662}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 662}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 663}}.
  {label, 662}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:834:68">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 663}.
  {label, 659}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 650}}.
  {label, 651}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 10}.
    return.
% Halves to bytes, each word big-endian.

{function, bytesBE, 1, 87}.
  {label, 86}.
    {line, [{location, "std@hash.erl", 53}]}.
    {func_info, {atom, std@hash}, {atom, bytesBE}, 1}.
  {label, 87}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 665}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 1, {f, 390}, 2}.
% Halves to bytes, each word little-endian (MD5).

{function, bytesLE, 1, 89}.
  {label, 88}.
    {line, [{location, "std@hash.erl", 54}]}.
    {func_info, {atom, std@hash}, {atom, bytesLE}, 1}.
  {label, 89}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@hash.erl", 55}]}.
  {label, 668}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 669}, [{y, 2}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 670}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 671}}.
  {label, 670}.
    {move, {integer, 0}, {x, 0}}.
  {label, 671}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 673}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 673}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 674}}.
  {label, 673}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:851:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 674}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 672}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 675}}.
  {label, 672}.
    {move, {integer, 0}, {x, 0}}.
  {label, 675}.
    {move, {x, 0}, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 4}, {integer, 256}], {x, 0}}.
    {test, is_ge, {f, 676}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 676}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 677}}.
  {label, 676}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:852:72">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 677}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 4}, {integer, 256}], {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 6}, {integer, 256}], {x, 0}}.
    {test, is_ge, {f, 678}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 678}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 679}}.
  {label, 678}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:852:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 679}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 6}, {integer, 256}], {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 680}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 680}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 681}}.
  {label, 680}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:853:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 681}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 668}}.
  {label, 669}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
% The message, `0x80`, zeros, and its length in bits in the last
% `lengthBytes` bytes of a `block`-byte block.

{function, padded, 4, 91}.
  {label, 90}.
    {line, [{location, "std@hash.erl", 55}]}.
    {func_info, {atom, std@hash}, {atom, padded}, 4}.
  {label, 91}.
    {allocate, 20, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 8}], {x, 0}}.
    {test, is_ge, {f, 682}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 682}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 683}}.
  {label, 682}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:866:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 683}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 684}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 684}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 685}}.
  {label, 684}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:867:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 685}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 686}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 686}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 687}}.
  {label, 686}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:867:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 687}.
    {test, is_ne_exact, {f, 688}, [{y, 1}, {integer, 0}]}.
    {jump, {f, 689}}.
  {label, 688}.
    {move, {literal, {panic, <<"integer division by zero: % on i32 at src/hash.bp:867:57">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 689}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 690}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 690}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 691}}.
  {label, 690}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:867:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 691}.
    {test, is_ne_exact, {f, 692}, [{y, 1}, {integer, 0}]}.
    {jump, {f, 693}}.
  {label, 692}.
    {move, {literal, {panic, <<"integer division by zero: % on i32 at src/hash.bp:867:66">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 693}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 4}, {integer, 256}], {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 4}, {integer, 256}], {x, 0}}.
    {test, is_ge, {f, 694}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 694}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 695}}.
  {label, 694}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:871:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 695}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 256}], {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 4}, {integer, 65536}], {x, 0}}.
    {test, is_ge, {f, 696}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 696}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 697}}.
  {label, 696}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:870:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 697}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 256}], {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 4}, {integer, 16777216}], {x, 0}}.
    {test, is_ge, {f, 698}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 698}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 699}}.
  {label, 698}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:869:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 699}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 700}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 702}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 702}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 703}}.
  {label, 702}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:875:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 703}.
    {call, 1, {f, 57}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {jump, {f, 701}}.
  {label, 700}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 704}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 704}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 705}}.
  {label, 704}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:877:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 705}.
    {call, 1, {f, 57}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
  {label, 701}.
    {move, {x, 0}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {integer, 128}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 20}.
% ── HMAC ──
% The key as HMAC's 64-byte block: hashed when longer, zero-padded.

{function, hmacKeyBlock, 1, 93}.
  {label, 92}.
    {line, [{location, "std@hash.erl", 56}]}.
    {func_info, {atom, std@hash}, {atom, hmacKeyBlock}, 1}.
  {label, 93}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 706}, [{integer, 64}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 101}}.
    {jump, {f, 707}}.
  {label, 706}.
    {move, {y, 0}, {x, 0}}.
  {label, 707}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 64}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 708}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 708}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 709}}.
  {label, 708}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/hash.bp:886:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 709}.
    {call, 1, {f, 57}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 4}.

{function, hmacSha256Bytes, 2, 95}.
  {label, 94}.
    {line, [{location, "std@hash.erl", 57}]}.
    {func_info, {atom, std@hash}, {atom, hmacSha256Bytes}, 2}.
  {label, 95}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 54}, {x, 1}}.
    {call, 2, {f, 97}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 92}, {x, 1}}.
    {call, 2, {f, 97}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 3, {f, 99}, 5}.
% The key block with every byte xored with `pad` (0x36 inner, 0x5c outer).

{function, padOf, 2, 97}.
  {label, 96}.
    {line, [{location, "std@hash.erl", 58}]}.
    {func_info, {atom, std@hash}, {atom, padOf}, 2}.
  {label, 97}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 711}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 2}.

{function, hmacWithPads, 3, 99}.
  {label, 98}.
    {line, [{location, "std@hash.erl", 59}]}.
    {func_info, {atom, std@hash}, {atom, hmacWithPads}, 3}.
  {label, 99}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {call, 1, {f, 101}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {call_last, 1, {f, 101}, 5}.
% ── SHA-256 ──

{function, sha256Bytes, 1, 101}.
  {label, 100}.
    {line, [{location, "std@hash.erl", 60}]}.
    {func_info, {atom, std@hash}, {atom, sha256Bytes}, 1}.
  {label, 101}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {integer, 64}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 91}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 119}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 117}}.
    {move, {integer, 8}, {x, 1}}.
    {call, 2, {f, 85}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@hash.erl", 61}]}.
  {label, 712}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 713}, [{y, 4}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 4, {f, 103}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 714}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 714}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 715}}.
  {label, 714}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:915:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 715}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 712}}.
  {label, 713}.
    {move, {y, 3}, {x, 0}}.
    {call_last, 1, {f, 87}, 5}.

{function, sha256Block, 4, 103}.
  {label, 102}.
    {line, [{location, "std@hash.erl", 61}]}.
    {func_info, {atom, std@hash}, {atom, sha256Block}, 4}.
  {label, 103}.
    {allocate, 67, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}, {y, 49}, {y, 50}, {y, 51}, {y, 52}, {y, 53}, {y, 54}, {y, 55}, {y, 56}, {y, 57}, {y, 58}, {y, 59}, {y, 60}, {y, 61}, {y, 62}, {y, 63}, {y, 64}, {y, 65}, {y, 66}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 7}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 716}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 716}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 717}}.
  {label, 716}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:930:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 717}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 8}], {x, 0}}.
    {test, is_ge, {f, 718}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 718}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 719}}.
  {label, 718}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:931:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 719}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 14}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 12}], {x, 0}}.
    {test, is_ge, {f, 720}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 720}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 721}}.
  {label, 720}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:932:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 721}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 722}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 722}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 723}}.
  {label, 722}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:933:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 723}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 16}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 20}], {x, 0}}.
    {test, is_ge, {f, 724}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 724}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 725}}.
  {label, 724}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:934:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 725}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 24}], {x, 0}}.
    {test, is_ge, {f, 726}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 726}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 727}}.
  {label, 726}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:935:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 727}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 28}], {x, 0}}.
    {test, is_ge, {f, 728}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 728}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 729}}.
  {label, 728}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:936:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 729}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 19}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 32}], {x, 0}}.
    {test, is_ge, {f, 730}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 730}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 731}}.
  {label, 730}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:937:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 731}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 36}], {x, 0}}.
    {test, is_ge, {f, 732}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 732}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 733}}.
  {label, 732}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:938:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 733}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 21}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 40}], {x, 0}}.
    {test, is_ge, {f, 734}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 734}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 735}}.
  {label, 734}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:939:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 735}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 22}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 44}], {x, 0}}.
    {test, is_ge, {f, 736}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 736}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 737}}.
  {label, 736}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:940:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 737}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 23}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 48}], {x, 0}}.
    {test, is_ge, {f, 738}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 738}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 739}}.
  {label, 738}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:941:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 739}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 24}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 52}], {x, 0}}.
    {test, is_ge, {f, 740}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 740}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 741}}.
  {label, 740}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:942:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 741}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 25}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 56}], {x, 0}}.
    {test, is_ge, {f, 742}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 742}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 743}}.
  {label, 742}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:943:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 743}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 26}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 60}], {x, 0}}.
    {test, is_ge, {f, 744}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 744}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 745}}.
  {label, 744}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:944:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 745}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 27}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {line, [{location, "std@hash.erl", 62}]}.
  {label, 746}.
    {test, is_lt, {f, 747}, [{y, 28}, {integer, 64}]}.
    {move, {y, 8}, {x, 0}}.
    {move, {float, 64.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 29}}.
    {move, {y, 8}, {x, 0}}.
    {move, {float, 2048.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 30}}.
    {move, {y, 8}, {x, 0}}.
    {move, {float, 33554432.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {y, 30}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 29}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 31}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {y, 31}], {x, 0}}.
    {move, {x, 0}, {y, 32}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 1}, {x, 3}}.
    {move, {y, 10}, {x, 2}}.
    {move, {y, 9}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 32}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 33}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 9}, {y, 28}], {x, 0}}.
    {test, is_ge, {f, 748}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 748}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 749}}.
  {label, 748}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:953:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 749}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 3, {f, 83}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 33}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 12}], {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 4}, {x, 0}}.
    {move, {float, 4.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 35}}.
    {move, {y, 4}, {x, 0}}.
    {move, {float, 8192.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 36}}.
    {move, {y, 4}, {x, 0}}.
    {move, {float, 4194304.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {y, 36}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 35}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 37}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 2}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 37}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 38}}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {y, 34}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 34}, {y, 38}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 13}, {x, 0}}.
    {move, {float, 128.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 39}}.
    {move, {y, 13}, {x, 0}}.
    {move, {float, 262144.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 40}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 13}, {float, 8.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {y, 40}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 39}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 41}}.
    {move, {y, 26}, {x, 0}}.
    {move, {float, 131072.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 42}}.
    {move, {y, 26}, {x, 0}}.
    {move, {float, 524288.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 43}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 26}, {float, 1024.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {y, 43}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 42}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 44}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 44}, {y, 21}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 41}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 12}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 45}}.
    {move, {y, 13}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 14}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 15}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 16}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 17}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 18}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 19}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 20}, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 21}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 22}, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 23}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 24}, {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 25}, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 26}, {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 27}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 45}, {x, 0}}.
    {move, {x, 0}, {y, 27}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 28}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 750}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 750}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 751}}.
  {label, 750}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:998:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 751}.
    {move, {x, 0}, {y, 28}}.
    {jump, {f, 746}}.
  {label, 747}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 46}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 47}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 48}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 49}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 8}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 50}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 9}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 51}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 10}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 52}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 7}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 11}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 53}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 53}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 53}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 52}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 52}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 51}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 51}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 50}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 50}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 49}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 49}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 48}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 48}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 47}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 47}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 46}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 46}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 54}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 67}.
    return.
% ── SHA-1 ──

{function, sha1Bytes, 1, 105}.
  {label, 104}.
    {line, [{location, "std@hash.erl", 62}]}.
    {func_info, {atom, std@hash}, {atom, sha1Bytes}, 1}.
  {label, 105}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {integer, 64}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 91}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"67452301 efcdab89 98badcfe 10325476 c3d2e1f0">>}, {x, 0}}.
    {move, {integer, 8}, {x, 1}}.
    {call, 2, {f, 85}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@hash.erl", 63}]}.
  {label, 752}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 753}, [{y, 3}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 107}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 754}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 754}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 755}}.
  {label, 754}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1036:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 755}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 752}}.
  {label, 753}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 1, {f, 87}, 4}.

{function, sha1Block, 3, 107}.
  {label, 106}.
    {line, [{location, "std@hash.erl", 63}]}.
    {func_info, {atom, std@hash}, {atom, sha1Block}, 3}.
  {label, 107}.
    {allocate, 35, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 756}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 756}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 757}}.
  {label, 756}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1048:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 757}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 9}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 8}], {x, 0}}.
    {test, is_ge, {f, 758}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 758}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 759}}.
  {label, 758}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1049:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 759}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 12}], {x, 0}}.
    {test, is_ge, {f, 760}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 760}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 761}}.
  {label, 760}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1050:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 761}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 762}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 762}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 763}}.
  {label, 762}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1051:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 763}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 20}], {x, 0}}.
    {test, is_ge, {f, 764}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 764}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 765}}.
  {label, 764}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1052:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 765}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 24}], {x, 0}}.
    {test, is_ge, {f, 766}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 766}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 767}}.
  {label, 766}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1053:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 767}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 14}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 28}], {x, 0}}.
    {test, is_ge, {f, 768}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 768}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 769}}.
  {label, 768}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1054:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 769}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 32}], {x, 0}}.
    {test, is_ge, {f, 770}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 770}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 771}}.
  {label, 770}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1055:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 771}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 16}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 36}], {x, 0}}.
    {test, is_ge, {f, 772}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 772}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 773}}.
  {label, 772}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1056:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 773}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 40}], {x, 0}}.
    {test, is_ge, {f, 774}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 774}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 775}}.
  {label, 774}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1057:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 775}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 44}], {x, 0}}.
    {test, is_ge, {f, 776}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 776}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 777}}.
  {label, 776}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1058:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 777}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 19}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 48}], {x, 0}}.
    {test, is_ge, {f, 778}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 778}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 779}}.
  {label, 778}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1059:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 779}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 52}], {x, 0}}.
    {test, is_ge, {f, 780}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 780}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 781}}.
  {label, 780}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1060:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 781}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 21}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 56}], {x, 0}}.
    {test, is_ge, {f, 782}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 782}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 783}}.
  {label, 782}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1061:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 783}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 22}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 60}], {x, 0}}.
    {test, is_ge, {f, 784}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 784}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 785}}.
  {label, 784}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1062:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 785}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 23}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {line, [{location, "std@hash.erl", 64}]}.
  {label, 786}.
    {test, is_lt, {f, 787}, [{y, 24}, {integer, 80}]}.
    {test, is_lt, {f, 788}, [{y, 24}, {integer, 20}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 1}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 1518500249.0}], {x, 0}}.
    {jump, {f, 789}}.
  {label, 788}.
    {test, is_lt, {f, 790}, [{y, 24}, {integer, 40}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 1859775393.0}], {x, 0}}.
    {jump, {f, 791}}.
  {label, 790}.
    {test, is_lt, {f, 792}, [{y, 24}, {integer, 60}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 2}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 2400959708.0}], {x, 0}}.
    {jump, {f, 793}}.
  {label, 792}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {float, 3395469782.0}], {x, 0}}.
  {label, 793}.
  {label, 791}.
  {label, 789}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 3}, {x, 0}}.
    {move, {float, 134217728.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 25}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 8}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {float, 4.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 26}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 21}, {x, 0}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {y, 10}, {x, 2}}.
    {move, {y, 16}, {x, 1}}.
    {call, 4, {f, 69}}.
    {move, {y, 8}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {float, 0.0}, {x, 2}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {move, {float, 2147483648.0}, {x, 1}}.
    {call, 2, {f, 65}}.
    {move, {x, 0}, {y, 28}}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 11}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 13}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 14}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 15}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 16}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 17}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 18}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 19}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 20}, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 21}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 22}, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 23}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 28}, {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 24}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 794}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 794}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 795}}.
  {label, 794}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1097:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 795}.
    {move, {x, 0}, {y, 24}}.
    {jump, {f, 786}}.
  {label, 787}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 29}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 30}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 32}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 33}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 33}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 33}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 32}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 32}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 31}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 31}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 30}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 30}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 29}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 29}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 34}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 35}.
    return.
% ── MD5 ──

{function, md5Bytes, 1, 109}.
  {label, 108}.
    {line, [{location, "std@hash.erl", 64}]}.
    {func_info, {atom, std@hash}, {atom, md5Bytes}, 1}.
  {label, 109}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, false}, {x, 0}}.
    {move, {integer, 64}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 91}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 125}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 2048}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 131072}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 4194304}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 67108864}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 512}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 65536}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 2097152}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 268435456}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 4096}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 262144}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 8388608}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 134217728}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1024}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 32768}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1048576}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 33554432}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"67452301 efcdab89 98badcfe 10325476">>}, {x, 0}}.
    {move, {integer, 8}, {x, 1}}.
    {call, 2, {f, 85}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {line, [{location, "std@hash.erl", 65}]}.
  {label, 796}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 797}, [{y, 6}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 4}, {x, 4}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 5, {f, 111}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 798}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 798}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 799}}.
  {label, 798}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1146:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 799}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 796}}.
  {label, 797}.
    {move, {y, 5}, {x, 0}}.
    {call_last, 1, {f, 89}, 7}.

{function, md5Block, 5, 111}.
  {label, 110}.
    {line, [{location, "std@hash.erl", 65}]}.
    {func_info, {atom, std@hash}, {atom, md5Block}, 5}.
  {label, 111}.
    {allocate, 27, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "std@hash.erl", 66}]}.
  {label, 800}.
    {test, is_lt, {f, 801}, [{y, 9}, {integer, 64}]}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 9}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 802}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 802}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 803}}.
  {label, 802}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:1164:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 803}.
    {move, {x, 0}, {y, 10}}.
    {test, is_eq_exact, {f, 804}, [{y, 10}, {integer, 0}]}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 1}, {x, 3}}.
    {move, {y, 8}, {x, 2}}.
    {move, {y, 7}, {x, 1}}.
    {call, 4, {f, 69}}.
    {jump, {f, 805}}.
  {label, 804}.
    {test, is_eq_exact, {f, 806}, [{y, 10}, {integer, 1}]}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 1}, {x, 3}}.
    {move, {y, 7}, {x, 2}}.
    {move, {y, 6}, {x, 1}}.
    {call, 4, {f, 69}}.
    {jump, {f, 807}}.
  {label, 806}.
    {test, is_eq_exact, {f, 808}, [{y, 10}, {integer, 2}]}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {y, 8}, {x, 2}}.
    {move, {y, 7}, {x, 1}}.
    {call, 4, {f, 69}}.
    {jump, {f, 809}}.
  {label, 808}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 3}, {x, 3}}.
    {move, {y, 8}, {x, 2}}.
    {move, {y, 7}, {x, 1}}.
    {call, 4, {f, 69}}.
  {label, 809}.
  {label, 807}.
  {label, 805}.
    {move, {x, 0}, {y, 11}}.
    {test, is_eq_exact, {f, 810}, [{y, 10}, {integer, 0}]}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 811}}.
  {label, 810}.
    {test, is_eq_exact, {f, 812}, [{y, 10}, {integer, 1}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 5}, {y, 9}], {x, 0}}.
    {test, is_ge, {f, 814}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 814}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 815}}.
  {label, 814}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1176:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 815}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 816}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 816}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 817}}.
  {label, 816}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1176:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 817}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {jump, {f, 813}}.
  {label, 812}.
    {test, is_eq_exact, {f, 818}, [{y, 10}, {integer, 2}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 9}], {x, 0}}.
    {test, is_ge, {f, 820}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 820}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 821}}.
  {label, 820}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1178:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 821}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 5}], {x, 0}}.
    {test, is_ge, {f, 822}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 822}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 823}}.
  {label, 822}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1178:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 823}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {jump, {f, 819}}.
  {label, 818}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 7}, {y, 9}], {x, 0}}.
    {test, is_ge, {f, 824}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 824}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 825}}.
  {label, 824}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1180:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 825}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
  {label, 819}.
  {label, 813}.
  {label, 811}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 9}, {y, 9}], {x, 0}}.
    {test, is_ge, {f, 826}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 826}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 827}}.
  {label, 826}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1181:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 827}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 3, {f, 83}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 13}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 4}, {y, 12}], {x, 0}}.
    {test, is_ge, {f, 828}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 828}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 829}}.
  {label, 828}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1181:75">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 829}.
    {gc_bif, '+', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 830}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 830}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 831}}.
  {label, 830}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1181:71">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 831}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 81}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 14}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 10}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 833}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 833}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 834}}.
  {label, 833}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1182:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 834}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'rem', {f, 0}, 2, [{y, 9}, {integer, 4}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 835}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 835}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 836}}.
  {label, 835}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1182:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 836}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 316}}.
    {test, is_ne_exact, {f, 832}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {jump, {f, 837}}.
  {label, 832}.
    {move, {integer, 1}, {x, 0}}.
  {label, 837}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {call, 2, {f, 65}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 838}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 838}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 839}}.
  {label, 838}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1187:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 839}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 800}}.
  {label, 801}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 8}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 21}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 21}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 21}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 20}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 20}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 19}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 19}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 18}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 18}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 27}.
    return.
% ── SHA-512 ──

{function, sha512Bytes, 1, 113}.
  {label, 112}.
    {line, [{location, "std@hash.erl", 66}]}.
    {func_info, {atom, std@hash}, {atom, sha512Bytes}, 1}.
  {label, 113}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {integer, 128}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {integer, 16}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 91}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 123}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 121}}.
    {move, {integer, 16}, {x, 1}}.
    {call, 2, {f, 85}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@hash.erl", 67}]}.
  {label, 840}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 841}, [{y, 4}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 4, {f, 115}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 128}], {x, 0}}.
    {test, is_ge, {f, 842}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 842}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 843}}.
  {label, 842}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1214:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 843}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 840}}.
  {label, 841}.
    {move, {y, 3}, {x, 0}}.
    {call_last, 1, {f, 87}, 5}.

{function, sha512Block, 4, 115}.
  {label, 114}.
    {line, [{location, "std@hash.erl", 67}]}.
    {func_info, {atom, std@hash}, {atom, sha512Block}, 4}.
  {label, 115}.
    {allocate, 163, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}, {y, 49}, {y, 50}, {y, 51}, {y, 52}, {y, 53}, {y, 54}, {y, 55}, {y, 56}, {y, 57}, {y, 58}, {y, 59}, {y, 60}, {y, 61}, {y, 62}, {y, 63}, {y, 64}, {y, 65}, {y, 66}, {y, 67}, {y, 68}, {y, 69}, {y, 70}, {y, 71}, {y, 72}, {y, 73}, {y, 74}, {y, 75}, {y, 76}, {y, 77}, {y, 78}, {y, 79}, {y, 80}, {y, 81}, {y, 82}, {y, 83}, {y, 84}, {y, 85}, {y, 86}, {y, 87}, {y, 88}, {y, 89}, {y, 90}, {y, 91}, {y, 92}, {y, 93}, {y, 94}, {y, 95}, {y, 96}, {y, 97}, {y, 98}, {y, 99}, {y, 100}, {y, 101}, {y, 102}, {y, 103}, {y, 104}, {y, 105}, {y, 106}, {y, 107}, {y, 108}, {y, 109}, {y, 110}, {y, 111}, {y, 112}, {y, 113}, {y, 114}, {y, 115}, {y, 116}, {y, 117}, {y, 118}, {y, 119}, {y, 120}, {y, 121}, {y, 122}, {y, 123}, {y, 124}, {y, 125}, {y, 126}, {y, 127}, {y, 128}, {y, 129}, {y, 130}, {y, 131}, {y, 132}, {y, 133}, {y, 134}, {y, 135}, {y, 136}, {y, 137}, {y, 138}, {y, 139}, {y, 140}, {y, 141}, {y, 142}, {y, 143}, {y, 144}, {y, 145}, {y, 146}, {y, 147}, {y, 148}, {y, 149}, {y, 150}, {y, 151}, {y, 152}, {y, 153}, {y, 154}, {y, 155}, {y, 156}, {y, 157}, {y, 158}, {y, 159}, {y, 160}, {y, 161}, {y, 162}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 7}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 8}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 10}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 11}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 12}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 13}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 14}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 15}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 19}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 0}], {x, 0}}.
    {test, is_ge, {f, 844}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 844}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 845}}.
  {label, 844}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1236:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 845}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 846}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 846}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 847}}.
  {label, 846}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1237:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 847}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 21}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 8}], {x, 0}}.
    {test, is_ge, {f, 848}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 848}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 849}}.
  {label, 848}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1238:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 849}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 22}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 12}], {x, 0}}.
    {test, is_ge, {f, 850}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 850}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 851}}.
  {label, 850}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1239:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 851}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 23}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 852}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 852}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 853}}.
  {label, 852}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1240:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 853}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 24}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 20}], {x, 0}}.
    {test, is_ge, {f, 854}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 854}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 855}}.
  {label, 854}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1241:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 855}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 25}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 24}], {x, 0}}.
    {test, is_ge, {f, 856}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 856}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 857}}.
  {label, 856}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1242:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 857}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 26}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 28}], {x, 0}}.
    {test, is_ge, {f, 858}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 858}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 859}}.
  {label, 858}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1243:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 859}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 27}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 32}], {x, 0}}.
    {test, is_ge, {f, 860}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 860}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 861}}.
  {label, 860}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1244:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 861}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 28}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 36}], {x, 0}}.
    {test, is_ge, {f, 862}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 862}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 863}}.
  {label, 862}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1245:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 863}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 29}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 40}], {x, 0}}.
    {test, is_ge, {f, 864}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 864}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 865}}.
  {label, 864}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1246:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 865}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 30}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 44}], {x, 0}}.
    {test, is_ge, {f, 866}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 866}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 867}}.
  {label, 866}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1247:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 867}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 31}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 48}], {x, 0}}.
    {test, is_ge, {f, 868}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 868}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 869}}.
  {label, 868}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1248:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 869}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 32}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 52}], {x, 0}}.
    {test, is_ge, {f, 870}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 870}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 871}}.
  {label, 870}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1249:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 871}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 33}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 56}], {x, 0}}.
    {test, is_ge, {f, 872}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 872}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 873}}.
  {label, 872}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1250:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 873}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 34}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 60}], {x, 0}}.
    {test, is_ge, {f, 874}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 874}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 875}}.
  {label, 874}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1251:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 875}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 35}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 876}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 876}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 877}}.
  {label, 876}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1252:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 877}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 36}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 68}], {x, 0}}.
    {test, is_ge, {f, 878}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 878}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 879}}.
  {label, 878}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1253:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 879}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 37}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 72}], {x, 0}}.
    {test, is_ge, {f, 880}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 880}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 881}}.
  {label, 880}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1254:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 881}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 38}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 76}], {x, 0}}.
    {test, is_ge, {f, 882}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 882}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 883}}.
  {label, 882}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1255:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 883}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 39}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 80}], {x, 0}}.
    {test, is_ge, {f, 884}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 884}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 885}}.
  {label, 884}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1256:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 885}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 40}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 84}], {x, 0}}.
    {test, is_ge, {f, 886}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 886}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 887}}.
  {label, 886}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1257:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 887}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 41}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 88}], {x, 0}}.
    {test, is_ge, {f, 888}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 888}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 889}}.
  {label, 888}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1258:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 889}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 42}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 92}], {x, 0}}.
    {test, is_ge, {f, 890}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 890}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 891}}.
  {label, 890}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1259:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 891}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 43}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 96}], {x, 0}}.
    {test, is_ge, {f, 892}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 892}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 893}}.
  {label, 892}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1260:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 893}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 44}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 100}], {x, 0}}.
    {test, is_ge, {f, 894}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 894}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 895}}.
  {label, 894}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1261:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 895}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 45}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 104}], {x, 0}}.
    {test, is_ge, {f, 896}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 896}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 897}}.
  {label, 896}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1262:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 897}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 46}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 108}], {x, 0}}.
    {test, is_ge, {f, 898}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 898}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 899}}.
  {label, 898}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1263:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 899}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 47}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 112}], {x, 0}}.
    {test, is_ge, {f, 900}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 900}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 901}}.
  {label, 900}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1264:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 901}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 48}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 116}], {x, 0}}.
    {test, is_ge, {f, 902}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 902}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 903}}.
  {label, 902}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1265:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 903}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 49}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 120}], {x, 0}}.
    {test, is_ge, {f, 904}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 904}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 905}}.
  {label, 904}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1266:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 905}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 50}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 124}], {x, 0}}.
    {test, is_ge, {f, 906}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 906}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 907}}.
  {label, 906}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1267:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 907}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 79}}.
    {move, {x, 0}, {y, 51}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 52}}.
    {line, [{location, "std@hash.erl", 68}]}.
  {label, 908}.
    {test, is_lt, {f, 909}, [{y, 52}, {integer, 80}]}.
    {move, {y, 12}, {x, 0}}.
    {move, {float, 16384.0}, {x, 2}}.
    {move, {y, 13}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 53}}.
    {move, {y, 12}, {x, 0}}.
    {move, {float, 262144.0}, {x, 2}}.
    {move, {y, 13}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 54}}.
    {move, {y, 13}, {x, 0}}.
    {move, {float, 512.0}, {x, 2}}.
    {move, {y, 12}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {y, 54}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 53}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 55}}.
    {move, {y, 13}, {x, 0}}.
    {move, {float, 16384.0}, {x, 2}}.
    {move, {y, 12}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 56}}.
    {move, {y, 13}, {x, 0}}.
    {move, {float, 262144.0}, {x, 2}}.
    {move, {y, 12}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 57}}.
    {move, {y, 12}, {x, 0}}.
    {move, {float, 512.0}, {x, 2}}.
    {move, {y, 13}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {y, 57}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 56}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 58}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 19}, {y, 58}], {x, 0}}.
    {move, {x, 0}, {y, 59}}.
    {move, {y, 13}, {x, 0}}.
    {move, {integer, 1}, {x, 3}}.
    {move, {y, 17}, {x, 2}}.
    {move, {y, 15}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 59}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 60}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 17}, {y, 52}], {x, 0}}.
    {test, is_ge, {f, 910}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 910}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 911}}.
  {label, 910}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1285:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 911}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 8}], {x, 0}}.
    {test, is_ge, {f, 912}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 912}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 913}}.
  {label, 912}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1285:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 913}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 3, {f, 83}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 60}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {y, 61}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 18}, {y, 55}], {x, 0}}.
    {move, {x, 0}, {y, 62}}.
    {move, {y, 12}, {x, 0}}.
    {move, {integer, 1}, {x, 3}}.
    {move, {y, 16}, {x, 2}}.
    {move, {y, 14}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 62}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 63}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 17}, {y, 52}], {x, 0}}.
    {test, is_ge, {f, 914}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 914}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 915}}.
  {label, 914}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/hash.bp:1291:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 915}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 8}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 3, {f, 83}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 63}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 20}], {x, 0}}.
    {move, {x, 0}, {y, 64}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 61}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 64}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 65}}.
    {move, {y, 61}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 66}}.
    {move, {y, 4}, {x, 0}}.
    {move, {float, 268435456.0}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 67}}.
    {move, {y, 5}, {x, 0}}.
    {move, {float, 4.0}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 68}}.
    {move, {y, 5}, {x, 0}}.
    {move, {float, 128.0}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {y, 68}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 67}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 69}}.
    {move, {y, 5}, {x, 0}}.
    {move, {float, 268435456.0}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 70}}.
    {move, {y, 4}, {x, 0}}.
    {move, {float, 4.0}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 71}}.
    {move, {y, 4}, {x, 0}}.
    {move, {float, 128.0}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {y, 71}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 70}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 72}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 2}, {x, 3}}.
    {move, {y, 9}, {x, 2}}.
    {move, {y, 7}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 72}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 73}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 2}, {x, 3}}.
    {move, {y, 8}, {x, 2}}.
    {move, {y, 6}, {x, 1}}.
    {call, 4, {f, 69}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 69}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 74}}.
    {move, {y, 16}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 17}, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 14}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 15}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {y, 66}], {x, 0}}.
    {move, {x, 0}, {y, 75}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 10}, {y, 65}], {x, 0}}.
    {move, {x, 0}, {y, 76}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 75}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 76}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 75}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 66}, {y, 73}], {x, 0}}.
    {move, {x, 0}, {y, 77}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 65}, {y, 74}], {x, 0}}.
    {move, {x, 0}, {y, 78}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 77}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 78}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 77}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 22}, {x, 0}}.
    {move, {float, 2.0}, {x, 2}}.
    {move, {y, 23}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 79}}.
    {move, {y, 22}, {x, 0}}.
    {move, {float, 256.0}, {x, 2}}.
    {move, {y, 23}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 80}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 22}, {float, 128.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {y, 80}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 79}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 81}}.
    {move, {y, 23}, {x, 0}}.
    {move, {float, 2.0}, {x, 2}}.
    {move, {y, 22}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 82}}.
    {move, {y, 23}, {x, 0}}.
    {move, {float, 256.0}, {x, 2}}.
    {move, {y, 22}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 83}}.
    {move, {y, 23}, {x, 0}}.
    {move, {float, 128.0}, {x, 2}}.
    {move, {y, 22}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {y, 83}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 82}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 84}}.
    {move, {y, 48}, {x, 0}}.
    {move, {float, 524288.0}, {x, 2}}.
    {move, {y, 49}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 85}}.
    {move, {y, 49}, {x, 0}}.
    {move, {float, 536870912.0}, {x, 2}}.
    {move, {y, 48}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 86}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 48}, {float, 64.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {move, {y, 86}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 85}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 87}}.
    {move, {y, 49}, {x, 0}}.
    {move, {float, 524288.0}, {x, 2}}.
    {move, {y, 48}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 88}}.
    {move, {y, 48}, {x, 0}}.
    {move, {float, 536870912.0}, {x, 2}}.
    {move, {y, 49}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 89}}.
    {move, {y, 49}, {x, 0}}.
    {move, {float, 64.0}, {x, 2}}.
    {move, {y, 48}, {x, 1}}.
    {call, 3, {f, 67}}.
    {move, {y, 89}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 88}, {x, 0}}.
    {call, 4, {f, 69}}.
    {move, {x, 0}, {y, 90}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 90}, {y, 39}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 84}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 21}], {x, 0}}.
    {move, {x, 0}, {y, 91}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 87}, {y, 38}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 81}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 20}], {x, 0}}.
    {move, {x, 0}, {y, 92}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 91}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 92}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 93}}.
    {move, {y, 22}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 23}, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 24}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 25}, {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 26}, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 27}, {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 28}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 29}, {x, 0}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 30}, {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {move, {y, 31}, {x, 0}}.
    {move, {x, 0}, {y, 29}}.
    {move, {y, 32}, {x, 0}}.
    {move, {x, 0}, {y, 30}}.
    {move, {y, 33}, {x, 0}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 34}, {x, 0}}.
    {move, {x, 0}, {y, 32}}.
    {move, {y, 35}, {x, 0}}.
    {move, {x, 0}, {y, 33}}.
    {move, {y, 36}, {x, 0}}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 37}, {x, 0}}.
    {move, {x, 0}, {y, 35}}.
    {move, {y, 38}, {x, 0}}.
    {move, {x, 0}, {y, 36}}.
    {move, {y, 39}, {x, 0}}.
    {move, {x, 0}, {y, 37}}.
    {move, {y, 40}, {x, 0}}.
    {move, {x, 0}, {y, 38}}.
    {move, {y, 41}, {x, 0}}.
    {move, {x, 0}, {y, 39}}.
    {move, {y, 42}, {x, 0}}.
    {move, {x, 0}, {y, 40}}.
    {move, {y, 43}, {x, 0}}.
    {move, {x, 0}, {y, 41}}.
    {move, {y, 44}, {x, 0}}.
    {move, {x, 0}, {y, 42}}.
    {move, {y, 45}, {x, 0}}.
    {move, {x, 0}, {y, 43}}.
    {move, {y, 46}, {x, 0}}.
    {move, {x, 0}, {y, 44}}.
    {move, {y, 47}, {x, 0}}.
    {move, {x, 0}, {y, 45}}.
    {move, {y, 48}, {x, 0}}.
    {move, {x, 0}, {y, 46}}.
    {move, {y, 49}, {x, 0}}.
    {move, {x, 0}, {y, 47}}.
    {move, {y, 50}, {x, 0}}.
    {move, {x, 0}, {y, 48}}.
    {move, {y, 51}, {x, 0}}.
    {move, {x, 0}, {y, 49}}.
    {move, {y, 93}, {x, 0}}.
    {move, {x, 0}, {y, 50}}.
    {move, {y, 91}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 51}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 52}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 916}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 916}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 917}}.
  {label, 916}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/hash.bp:1386:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 917}.
    {move, {x, 0}, {y, 52}}.
    {jump, {f, 908}}.
  {label, 909}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {move, {x, 0}, {y, 94}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 95}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 94}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 95}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 96}}.
    {move, {y, 94}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 97}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 7}], {x, 0}}.
    {move, {x, 0}, {y, 98}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {move, {x, 0}, {y, 99}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 98}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 99}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 100}}.
    {move, {y, 98}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 101}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 9}], {x, 0}}.
    {move, {x, 0}, {y, 102}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 8}], {x, 0}}.
    {move, {x, 0}, {y, 103}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 102}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 103}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 104}}.
    {move, {y, 102}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 105}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 7}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 11}], {x, 0}}.
    {move, {x, 0}, {y, 106}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 10}], {x, 0}}.
    {move, {x, 0}, {y, 107}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 106}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 107}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 108}}.
    {move, {y, 106}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 109}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 13}], {x, 0}}.
    {move, {x, 0}, {y, 110}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 8}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 12}], {x, 0}}.
    {move, {x, 0}, {y, 111}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 110}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 111}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 112}}.
    {move, {y, 110}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 113}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 11}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 15}], {x, 0}}.
    {move, {x, 0}, {y, 114}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 10}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 14}], {x, 0}}.
    {move, {x, 0}, {y, 115}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 114}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 115}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 116}}.
    {move, {y, 114}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 117}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 13}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 17}], {x, 0}}.
    {move, {x, 0}, {y, 118}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 12}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 16}], {x, 0}}.
    {move, {x, 0}, {y, 119}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 118}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 119}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 120}}.
    {move, {y, 118}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 121}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 15}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 19}], {x, 0}}.
    {move, {x, 0}, {y, 122}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 14}, {x, 1}}.
    {call, 2, {f, 77}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 18}], {x, 0}}.
    {move, {x, 0}, {y, 123}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 122}, {float, 4294967296.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 123}, {x, 0}], {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 124}}.
    {move, {y, 122}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 125}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 125}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 125}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 124}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 124}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 121}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 121}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 120}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 120}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 117}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 117}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 116}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 116}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 113}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 113}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 112}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 112}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 109}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 109}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 108}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 108}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 105}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 105}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 104}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 104}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 101}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 101}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 100}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 100}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 97}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 97}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 96}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 126}}.
    {move, {y, 96}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {y, 126}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 163}.
    return.
% ── constants, as the hex the standards print ──
% One literal each, read in place (`hexValue` at `9 · i`, or `17 · i` for a
% 64-bit word), so a digest allocates none of its tables.
% FIPS 180-4 §5.3.3: the square roots of the first 8 primes.

{function, sha256Initial, 0, 117}.
  {label, 116}.
    {line, [{location, "std@hash.erl", 68}]}.
    {func_info, {atom, std@hash}, {atom, sha256Initial}, 0}.
  {label, 117}.
    {allocate, 0, 0}.
    {move, {literal, <<"6a09e667 bb67ae85 3c6ef372 a54ff53a 510e527f 9b05688c 1f83d9ab 5be0cd19">>}, {x, 0}}.
    {deallocate, 0}.
    return.
% FIPS 180-4 §4.2.2: the cube roots of the first 64 primes.

{function, sha256Constants, 0, 119}.
  {label, 118}.
    {line, [{location, "std@hash.erl", 69}]}.
    {func_info, {atom, std@hash}, {atom, sha256Constants}, 0}.
  {label, 119}.
    {allocate, 0, 0}.
    {move, {literal, <<"428a2f98 71374491 b5c0fbcf e9b5dba5 3956c25b 59f111f1 923f82a4 ab1c5ed5 d807aa98 12835b01 243185be 550c7dc3 72be5d74 80deb1fe 9bdc06a7 c19bf174 e49b69c1 efbe4786 0fc19dc6 240ca1cc 2de92c6f 4a7484aa 5cb0a9dc 76f988da 983e5152 a831c66d b00327c8 bf597fc7 c6e00bf3 d5a79147 06ca6351 14292967 27b70a85 2e1b2138 4d2c6dfc 53380d13 650a7354 766a0abb 81c2c92e 92722c85 a2bfe8a1 a81a664b c24b8b70 c76c51a3 d192e819 d6990624 f40e3585 106aa070 19a4c116 1e376c08 2748774c 34b0bcb5 391c0cb3 4ed8aa4a 5b9cca4f 682e6ff3 748f82ee 78a5636f 84c87814 8cc70208 90befffa a4506ceb bef9a3f7 c67178f2">>}, {x, 0}}.
    {deallocate, 0}.
    return.
% FIPS 180-4 §5.3.5: the square roots of the first 8 primes, 64 bits.

{function, sha512Initial, 0, 121}.
  {label, 120}.
    {line, [{location, "std@hash.erl", 70}]}.
    {func_info, {atom, std@hash}, {atom, sha512Initial}, 0}.
  {label, 121}.
    {allocate, 0, 0}.
    {move, {literal, <<"6a09e667f3bcc908 bb67ae8584caa73b 3c6ef372fe94f82b a54ff53a5f1d36f1 510e527fade682d1 9b05688c2b3e6c1f 1f83d9abfb41bd6b 5be0cd19137e2179">>}, {x, 0}}.
    {deallocate, 0}.
    return.
% FIPS 180-4 §4.2.3: the cube roots of the first 80 primes, 64 bits.

{function, sha512Constants, 0, 123}.
  {label, 122}.
    {line, [{location, "std@hash.erl", 71}]}.
    {func_info, {atom, std@hash}, {atom, sha512Constants}, 0}.
  {label, 123}.
    {allocate, 0, 0}.
    {move, {literal, <<"428a2f98d728ae22 7137449123ef65cd b5c0fbcfec4d3b2f e9b5dba58189dbbc 3956c25bf348b538 59f111f1b605d019 923f82a4af194f9b ab1c5ed5da6d8118 d807aa98a3030242 12835b0145706fbe 243185be4ee4b28c 550c7dc3d5ffb4e2 72be5d74f27b896f 80deb1fe3b1696b1 9bdc06a725c71235 c19bf174cf692694 e49b69c19ef14ad2 efbe4786384f25e3 0fc19dc68b8cd5b5 240ca1cc77ac9c65 2de92c6f592b0275 4a7484aa6ea6e483 5cb0a9dcbd41fbd4 76f988da831153b5 983e5152ee66dfab a831c66d2db43210 b00327c898fb213f bf597fc7beef0ee4 c6e00bf33da88fc2 d5a79147930aa725 06ca6351e003826f 142929670a0e6e70 27b70a8546d22ffc 2e1b21385c26c926 4d2c6dfc5ac42aed 53380d139d95b3df 650a73548baf63de 766a0abb3c77b2a8 81c2c92e47edaee6 92722c851482353b a2bfe8a14cf10364 a81a664bbc423001 c24b8b70d0f89791 c76c51a30654be30 d192e819d6ef5218 d69906245565a910 f40e35855771202a 106aa07032bbd1b8 19a4c116b8d2d0c8 1e376c085141ab53 2748774cdf8eeb99 34b0bcb5e19b48a8 391c0cb3c5c95a63 4ed8aa4ae3418acb 5b9cca4f7763e373 682e6ff3d6b2b8a3 748f82ee5defb2fc 78a5636f43172f60 84c87814a1f0ab72 8cc702081a6439ec 90befffa23631e28 a4506cebde82bde9 bef9a3f7b2c67915 c67178f2e372532b ca273eceea26619c d186b8c721c0c207 eada7dd6cde0eb1e f57d4f7fee6ed178 06f067aa72176fba 0a637dc5a2c898a6 113f9804bef90dae 1b710b35131c471b 28db77f523047d84 32caab7b40c72493 3c9ebe0a15c9bebc 431d67c49c100d4c 4cc5d4becb3e42b6 597f299cfc657e2a 5fcb6fab3ad6faec 6c44198c4a475817">>}, {x, 0}}.
    {deallocate, 0}.
    return.
% RFC 1321 §3.4: floor(2^32 · |sin(i + 1)|).

{function, md5Constants, 0, 125}.
  {label, 124}.
    {line, [{location, "std@hash.erl", 72}]}.
    {func_info, {atom, std@hash}, {atom, md5Constants}, 0}.
  {label, 125}.
    {allocate, 0, 0}.
    {move, {literal, <<"d76aa478 e8c7b756 242070db c1bdceee f57c0faf 4787c62a a8304613 fd469501 698098d8 8b44f7af ffff5bb1 895cd7be 6b901122 fd987193 a679438e 49b40821 f61e2562 c040b340 265e5a51 e9b6c7aa d62f105d 02441453 d8a1e681 e7d3fbc8 21e1cde6 c33707d6 f4d50d87 455a14ed a9e3e905 fcefa3f8 676f02d9 8d2a4c8a fffa3942 8771f681 6d9d6122 fde5380c a4beea44 4bdecfa9 f6bb4b60 bebfbc70 289b7ec6 eaa127fa d4ef3085 04881d05 d9d4d039 e6db99e5 1fa27cf8 c4ac5665 f4292244 432aff97 ab9423a7 fc93a039 655b59c3 8f0ccc92 ffeff47d 85845dd1 6fa87e4f fe2ce6e0 a3014314 4e0811a1 f7537e82 bd3af235 2ad7d2bb eb86d391">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'string_slice', 3, 332}.
  {label, 331}.
    {line, [{location, "std@hash.erl", 73}]}.
    {func_info, {atom, std@hash}, {atom, 'string_slice'}, 3}.
  {label, 332}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 918}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 920}, 3}.
  {label, 918}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 942}, 3}.

{function, 'array_flatten', 1, 390}.
  {label, 389}.
    {line, [{location, "std@hash.erl", 74}]}.
    {func_info, {atom, std@hash}, {atom, 'array_flatten'}, 1}.
  {label, 390}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 959}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__array_flatten', 1, 962}.
  {label, 961}.
    {line, [{location, "std@hash.erl", 76}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__array_flatten'}, 1}.
  {label, 962}.
    {call_only, 1, {f, 390}}.

{function, '__bp_priv__array_range', 2, 964}.
  {label, 963}.
    {line, [{location, "std@hash.erl", 77}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 964}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 966}.
  {label, 965}.
    {line, [{location, "std@hash.erl", 78}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 966}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 968}.
  {label, 967}.
    {line, [{location, "std@hash.erl", 79}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 968}.
    {call_only, 3, {f, 332}}.

{function, '__bp_priv__base64Group', 4, 970}.
  {label, 969}.
    {line, [{location, "std@hash.erl", 80}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__base64Group'}, 4}.
  {label, 970}.
    {call_only, 4, {f, 55}}.

{function, '__bp_priv__base64Of', 3, 972}.
  {label, 971}.
    {line, [{location, "std@hash.erl", 81}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__base64Of'}, 3}.
  {label, 972}.
    {call_only, 3, {f, 53}}.

{function, '__bp_priv__bits32', 4, 974}.
  {label, 973}.
    {line, [{location, "std@hash.erl", 82}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__bits32'}, 4}.
  {label, 974}.
    {call_only, 4, {f, 69}}.

{function, '__bp_priv__bytesBE', 1, 976}.
  {label, 975}.
    {line, [{location, "std@hash.erl", 83}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__bytesBE'}, 1}.
  {label, 976}.
    {call_only, 1, {f, 87}}.

{function, '__bp_priv__bytesLE', 1, 978}.
  {label, 977}.
    {line, [{location, "std@hash.erl", 84}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__bytesLE'}, 1}.
  {label, 978}.
    {call_only, 1, {f, 89}}.

{function, '__bp_priv__equalsConstantTimeBody', 2, 980}.
  {label, 979}.
    {line, [{location, "std@hash.erl", 85}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__equalsConstantTimeBody'}, 2}.
  {label, 980}.
    {call_only, 2, {f, 41}}.

{function, '__bp_priv__frame', 1, 982}.
  {label, 981}.
    {line, [{location, "std@hash.erl", 86}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__frame'}, 1}.
  {label, 982}.
    {call_only, 1, {f, 15}}.

{function, '__bp_priv__halvesOf', 2, 984}.
  {label, 983}.
    {line, [{location, "std@hash.erl", 87}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__halvesOf'}, 2}.
  {label, 984}.
    {call_only, 2, {f, 85}}.

{function, '__bp_priv__hexDigit', 1, 986}.
  {label, 985}.
    {line, [{location, "std@hash.erl", 88}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hexDigit'}, 1}.
  {label, 986}.
    {call_only, 1, {f, 49}}.

{function, '__bp_priv__hexOf', 1, 988}.
  {label, 987}.
    {line, [{location, "std@hash.erl", 89}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hexOf'}, 1}.
  {label, 988}.
    {call_only, 1, {f, 51}}.

{function, '__bp_priv__hexValue', 3, 990}.
  {label, 989}.
    {line, [{location, "std@hash.erl", 90}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hexValue'}, 3}.
  {label, 990}.
    {call_only, 3, {f, 83}}.

{function, '__bp_priv__hmacKeyBlock', 1, 992}.
  {label, 991}.
    {line, [{location, "std@hash.erl", 91}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hmacKeyBlock'}, 1}.
  {label, 992}.
    {call_only, 1, {f, 93}}.

{function, '__bp_priv__hmacSha256Base64UrlBody', 2, 994}.
  {label, 993}.
    {line, [{location, "std@hash.erl", 92}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hmacSha256Base64UrlBody'}, 2}.
  {label, 994}.
    {call_only, 2, {f, 39}}.

{function, '__bp_priv__hmacSha256Body', 2, 996}.
  {label, 995}.
    {line, [{location, "std@hash.erl", 93}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hmacSha256Body'}, 2}.
  {label, 996}.
    {call_only, 2, {f, 37}}.

{function, '__bp_priv__hmacSha256Bytes', 2, 998}.
  {label, 997}.
    {line, [{location, "std@hash.erl", 94}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hmacSha256Bytes'}, 2}.
  {label, 998}.
    {call_only, 2, {f, 95}}.

{function, '__bp_priv__hmacWithPads', 3, 1000}.
  {label, 999}.
    {line, [{location, "std@hash.erl", 95}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__hmacWithPads'}, 3}.
  {label, 1000}.
    {call_only, 3, {f, 99}}.

{function, '__bp_priv__lowerHalf', 1, 1002}.
  {label, 1001}.
    {line, [{location, "std@hash.erl", 96}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__lowerHalf'}, 1}.
  {label, 1002}.
    {call_only, 1, {f, 75}}.

{function, '__bp_priv__md5Block', 5, 1004}.
  {label, 1003}.
    {line, [{location, "std@hash.erl", 97}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__md5Block'}, 5}.
  {label, 1004}.
    {call_only, 5, {f, 111}}.

{function, '__bp_priv__md5Body', 1, 1006}.
  {label, 1005}.
    {line, [{location, "std@hash.erl", 98}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__md5Body'}, 1}.
  {label, 1006}.
    {call_only, 1, {f, 33}}.

{function, '__bp_priv__md5Bytes', 1, 1008}.
  {label, 1007}.
    {line, [{location, "std@hash.erl", 99}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__md5Bytes'}, 1}.
  {label, 1008}.
    {call_only, 1, {f, 109}}.

{function, '__bp_priv__md5Constants', 0, 1010}.
  {label, 1009}.
    {line, [{location, "std@hash.erl", 100}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__md5Constants'}, 0}.
  {label, 1010}.
    {call_only, 0, {f, 125}}.

{function, '__bp_priv__mix', 3, 1012}.
  {label, 1011}.
    {line, [{location, "std@hash.erl", 101}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__mix'}, 3}.
  {label, 1012}.
    {call_only, 3, {f, 67}}.

{function, '__bp_priv__padOf', 2, 1014}.
  {label, 1013}.
    {line, [{location, "std@hash.erl", 102}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__padOf'}, 2}.
  {label, 1014}.
    {call_only, 2, {f, 97}}.

{function, '__bp_priv__padded', 4, 1016}.
  {label, 1015}.
    {line, [{location, "std@hash.erl", 103}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__padded'}, 4}.
  {label, 1016}.
    {call_only, 4, {f, 91}}.

{function, '__bp_priv__panicText', 1, 1018}.
  {label, 1017}.
    {line, [{location, "std@hash.erl", 104}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__panicText'}, 1}.
  {label, 1018}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__pbkdf2DeriveBody', 4, 1020}.
  {label, 1019}.
    {line, [{location, "std@hash.erl", 105}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__pbkdf2DeriveBody'}, 4}.
  {label, 1020}.
    {call_only, 4, {f, 43}}.

{function, '__bp_priv__rotr32', 2, 1022}.
  {label, 1021}.
    {line, [{location, "std@hash.erl", 106}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__rotr32'}, 2}.
  {label, 1022}.
    {call_only, 2, {f, 65}}.

{function, '__bp_priv__sha1Base64Body', 1, 1024}.
  {label, 1023}.
    {line, [{location, "std@hash.erl", 107}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha1Base64Body'}, 1}.
  {label, 1024}.
    {call_only, 1, {f, 35}}.

{function, '__bp_priv__sha1Block', 3, 1026}.
  {label, 1025}.
    {line, [{location, "std@hash.erl", 108}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha1Block'}, 3}.
  {label, 1026}.
    {call_only, 3, {f, 107}}.

{function, '__bp_priv__sha1Bytes', 1, 1028}.
  {label, 1027}.
    {line, [{location, "std@hash.erl", 109}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha1Bytes'}, 1}.
  {label, 1028}.
    {call_only, 1, {f, 105}}.

{function, '__bp_priv__sha256Base64UrlBody', 1, 1030}.
  {label, 1029}.
    {line, [{location, "std@hash.erl", 110}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha256Base64UrlBody'}, 1}.
  {label, 1030}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__sha256Block', 4, 1032}.
  {label, 1031}.
    {line, [{location, "std@hash.erl", 111}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha256Block'}, 4}.
  {label, 1032}.
    {call_only, 4, {f, 103}}.

{function, '__bp_priv__sha256Body', 1, 1034}.
  {label, 1033}.
    {line, [{location, "std@hash.erl", 112}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha256Body'}, 1}.
  {label, 1034}.
    {call_only, 1, {f, 25}}.

{function, '__bp_priv__sha256Bytes', 1, 1036}.
  {label, 1035}.
    {line, [{location, "std@hash.erl", 113}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha256Bytes'}, 1}.
  {label, 1036}.
    {call_only, 1, {f, 101}}.

{function, '__bp_priv__sha256Constants', 0, 1038}.
  {label, 1037}.
    {line, [{location, "std@hash.erl", 114}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha256Constants'}, 0}.
  {label, 1038}.
    {call_only, 0, {f, 119}}.

{function, '__bp_priv__sha256Initial', 0, 1040}.
  {label, 1039}.
    {line, [{location, "std@hash.erl", 115}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha256Initial'}, 0}.
  {label, 1040}.
    {call_only, 0, {f, 117}}.

{function, '__bp_priv__sha512Block', 4, 1042}.
  {label, 1041}.
    {line, [{location, "std@hash.erl", 116}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha512Block'}, 4}.
  {label, 1042}.
    {call_only, 4, {f, 115}}.

{function, '__bp_priv__sha512Body', 1, 1044}.
  {label, 1043}.
    {line, [{location, "std@hash.erl", 117}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha512Body'}, 1}.
  {label, 1044}.
    {call_only, 1, {f, 31}}.

{function, '__bp_priv__sha512Bytes', 1, 1046}.
  {label, 1045}.
    {line, [{location, "std@hash.erl", 118}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha512Bytes'}, 1}.
  {label, 1046}.
    {call_only, 1, {f, 113}}.

{function, '__bp_priv__sha512Constants', 0, 1048}.
  {label, 1047}.
    {line, [{location, "std@hash.erl", 119}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha512Constants'}, 0}.
  {label, 1048}.
    {call_only, 0, {f, 123}}.

{function, '__bp_priv__sha512Initial', 0, 1050}.
  {label, 1049}.
    {line, [{location, "std@hash.erl", 120}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__sha512Initial'}, 0}.
  {label, 1050}.
    {call_only, 0, {f, 121}}.

{function, '__bp_priv__smallInt', 1, 1052}.
  {label, 1051}.
    {line, [{location, "std@hash.erl", 121}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__smallInt'}, 1}.
  {label, 1052}.
    {call_only, 1, {f, 71}}.

{function, '__bp_priv__strongHashBody', 1, 1054}.
  {label, 1053}.
    {line, [{location, "std@hash.erl", 122}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__strongHashBody'}, 1}.
  {label, 1054}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv__upperHalf', 1, 1056}.
  {label, 1055}.
    {line, [{location, "std@hash.erl", 123}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__upperHalf'}, 1}.
  {label, 1056}.
    {call_only, 1, {f, 73}}.

{function, '__bp_priv__utf8Bytes', 1, 1058}.
  {label, 1057}.
    {line, [{location, "std@hash.erl", 124}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__utf8Bytes'}, 1}.
  {label, 1058}.
    {call_only, 1, {f, 47}}.

{function, '__bp_priv__utf8Of', 1, 1060}.
  {label, 1059}.
    {line, [{location, "std@hash.erl", 125}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__utf8Of'}, 1}.
  {label, 1060}.
    {call_only, 1, {f, 45}}.

{function, '__bp_priv__wordBE', 2, 1062}.
  {label, 1061}.
    {line, [{location, "std@hash.erl", 126}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__wordBE'}, 2}.
  {label, 1062}.
    {call_only, 2, {f, 79}}.

{function, '__bp_priv__wordLE', 2, 1064}.
  {label, 1063}.
    {line, [{location, "std@hash.erl", 127}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__wordLE'}, 2}.
  {label, 1064}.
    {call_only, 2, {f, 81}}.

{function, '__bp_priv__wordOf', 2, 1066}.
  {label, 1065}.
    {line, [{location, "std@hash.erl", 128}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__wordOf'}, 2}.
  {label, 1066}.
    {call_only, 2, {f, 77}}.

{function, '__bp_priv__wrap32', 1, 1068}.
  {label, 1067}.
    {line, [{location, "std@hash.erl", 129}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__wrap32'}, 1}.
  {label, 1068}.
    {call_only, 1, {f, 63}}.

{function, '__bp_priv__xorByte', 2, 1070}.
  {label, 1069}.
    {line, [{location, "std@hash.erl", 130}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__xorByte'}, 2}.
  {label, 1070}.
    {call_only, 2, {f, 59}}.

{function, '__bp_priv__xorBytes', 2, 1072}.
  {label, 1071}.
    {line, [{location, "std@hash.erl", 131}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__xorBytes'}, 2}.
  {label, 1072}.
    {call_only, 2, {f, 61}}.

{function, '__bp_priv__zeroBytes', 1, 1074}.
  {label, 1073}.
    {line, [{location, "std@hash.erl", 132}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_priv__zeroBytes'}, 1}.
  {label, 1074}.
    {call_only, 1, {f, 57}}.

{function, '__bp_tpl_0', 2, 127}.
  {label, 126}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_0'}, 2}.
  {label, 127}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, hmac}, {x, 0}}.
    {move, {atom, sha256}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {move, {y, 1}, {x, 3}}.
    {call_ext, 4, {extfunc, crypto, mac, 4}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, #{mode => urlsafe, padding => false}}, {x, 1}}.
    {call_ext_last, 2, {extfunc, base64, encode, 2}, 3}.

{function, '__bp_tpl_1', 1, 131}.
  {label, 130}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_1'}, 1}.
  {label, 131}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, sha}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, base64, encode, 1}, 2}.

{function, '__bp_tpl_2', 1, 135}.
  {label, 134}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_2'}, 1}.
  {label, 135}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, sha256}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, #{mode => urlsafe, padding => false}}, {x, 1}}.
    {call_ext_last, 2, {extfunc, base64, encode, 2}, 2}.

{function, '__bp_tpl_3-t/2-fun-0-', 2, 143}.
  {label, 142}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_3-t/2-fun-0-'}, 2}.
  {label, 143}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 146}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash_equals, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 148}}.
  {label, 146}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 147}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 148}}.
  {label, 147}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 148}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_3', 2, 139}.
  {label, 138}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_3'}, 2}.
  {label, 139}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 143}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_4', 1, 152}.
  {label, 151}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_4'}, 1}.
  {label, 152}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {atom, sha256}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 156}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 157}, [{x, 0}]}.
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
    {jump, {f, 156}}.
  {label, 157}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 158}, [{x, 0}]}.
    {jump, {f, 155}}.
  {label, 158}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 155}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 7}.

{function, '__bp_tpl_5', 1, 162}.
  {label, 161}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_5'}, 1}.
  {label, 162}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {atom, sha512}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 166}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 167}, [{x, 0}]}.
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
    {jump, {f, 166}}.
  {label, 167}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 168}, [{x, 0}]}.
    {jump, {f, 165}}.
  {label, 168}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 165}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 7}.

{function, '__bp_tpl_6', 1, 172}.
  {label, 171}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_6'}, 1}.
  {label, 172}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {atom, md5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 176}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 177}, [{x, 0}]}.
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
    {jump, {f, 176}}.
  {label, 177}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 178}, [{x, 0}]}.
    {jump, {f, 175}}.
  {label, 178}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 175}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 7}.

{function, '__bp_tpl_7', 2, 182}.
  {label, 181}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_7'}, 2}.
  {label, 182}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, nil, {y, 3}}.
    {move, {atom, hmac}, {x, 0}}.
    {move, {atom, sha256}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 3}}.
    {call_ext, 4, {extfunc, crypto, mac, 4}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 4}}.
  {label, 186}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 187}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 4}}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, [126, 50, 46, 49, 54, 46, 48, 98]}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 186}}.
  {label, 187}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 188}, [{x, 0}]}.
    {jump, {f, 185}}.
  {label, 188}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 185}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 8}.

{function, '__bp_tpl_8--t/1-fun-0--fun-1-', 2, 200}.
  {label, 199}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_8--t/1-fun-0--fun-1-'}, 2}.
  {label, 200}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 33}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '*', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 4294967295}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_8-t/1-fun-0-', 1, 196}.
  {label, 195}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_8-t/1-fun-0-'}, 1}.
  {label, 196}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 200}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 5381}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 204}}.
  {label, 204}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 16}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, integer_to_list, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 4}.

{function, '__bp_tpl_8', 1, 192}.
  {label, 191}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_8'}, 1}.
  {label, 192}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 196}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_9', 1, 208}.
  {label, 207}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_9'}, 1}.
  {label, 208}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, sha256}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, encode_hex, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {integer, 32}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 2}.

{function, '__bp_tpl_10', 1, 229}.
  {label, 228}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_10'}, 1}.
  {label, 229}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_11', 4, 232}.
  {label, 231}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_11'}, 4}.
  {label, 232}.
    {allocate, 5, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {atom, sha256}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 3}, {x, 4}}.
    {call_ext, 5, {extfunc, crypto, pbkdf2_hmac, 5}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {literal, #{mode => urlsafe, padding => false}}, {x, 1}}.
    {call_ext_last, 2, {extfunc, base64, encode, 2}, 5}.

{function, '-bp_field-', 2, 237}.
  {label, 236}.
    {line, [{location, "std@hash.erl", 9}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_field-'}, 2}.
  {label, 237}.
    {test, is_map, {f, 238}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 238}.
    {test, is_tuple, {f, 239}, [{x, 0}]}.
    {bif, element, {f, 241}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 241}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 239}.
    {test, is_eq_exact, {f, 241}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 240}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 240}.
    {test, is_binary, {f, 241}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 241}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_tpl_12', 1, 245}.
  {label, 244}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_12'}, 1}.
  {label, 245}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_print', 1, 247}.
  {label, 246}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_print'}, 1}.
  {label, 247}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 251}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 251}.
  {label, 250}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_show_top-'}, 1}.
  {label, 251}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 249}}.

{function, '-bp_show_elem-', 1, 253}.
  {label, 252}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_show_elem-'}, 1}.
  {label, 253}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 249}}.

{function, '__bp_show', 2, 249}.
  {label, 248}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_show'}, 2}.
  {label, 249}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 261}, [{x, 0}]}.
    {test, is_eq, {f, 260}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 260}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 261}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 262}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 253}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 262}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 264}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 263}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 263}, [{x, 0}]}.
    {test, is_ne_exact, {f, 263}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 263}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 263}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 268}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 269}}.
  {label, 268}.
    {test, is_eq_exact, {f, 265}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 269}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 249}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 263}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 253}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 264}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 266}, [{x, 0}]}.
    {test, is_ne_exact, {f, 266}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 266}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 267}, [{x, 0}, {atom, undefined}]}.
  {label, 265}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 255}, 2}.
  {label, 266}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 267}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 255}.
  {label, 254}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_tagged'}, 2}.
  {label, 255}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 270}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 270}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 270}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 271}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 257}, 3}.
  {label, 271}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 257}.
  {label, 256}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_render'}, 1}.
  {label, 257}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 272}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 272}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 273}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 273}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 259}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 259}.
  {label, 258}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_render_pair-'}, 1}.
  {label, 259}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 249}}.
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

{function, '-bp_stringify-', 1, 275}.
  {label, 274}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_stringify-'}, 1}.
  {label, 275}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 276}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 276}.
    {test, is_integer, {f, 277}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 277}.
    {call, 1, {f, 251}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-frame/1-fun-0-', 1, 243}.
  {label, 242}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '-frame/1-fun-0-'}, 1}.
  {label, 243}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 245}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 275}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, '-bp_join-', 2, 279}.
  {label, 278}.
    {line, [{location, "std@hash.erl", 18}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_join-'}, 2}.
  {label, 279}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 275}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_13-t/2-fun-0-', 2, 287}.
  {label, 286}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_13-t/2-fun-0-'}, 2}.
  {label, 287}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 289}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 291}, [{x, 0}]}.
    {jump, {f, 292}}.
  {label, 291}.
    {test, is_tuple, {f, 293}, [{x, 0}]}.
    {test, test_arity, {f, 293}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 292}}.
  {label, 293}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 292}.
    {move, {x, 0}, {y, 4}}.
  {label, 294}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 295}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 297}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 297}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 298}}.
  {label, 297}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 298}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 294}}.
  {label, 295}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 296}, [{x, 0}]}.
    {jump, {f, 290}}.
  {label, 296}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 290}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 289}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_13', 2, 283}.
  {label, 282}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_13'}, 2}.
  {label, 283}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 287}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-matches/2-fun-1-', 1, 300}.
  {label, 299}.
    {line, [{location, "std@hash.erl", 21}]}.
    {func_info, {atom, std@hash}, {atom, '-matches/2-fun-1-'}, 1}.
  {label, 300}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, trim, 1}}.
    {deallocate, 1}.
    return.

{function, '-bp_indexOf-', 3, 302}.
  {label, 301}.
    {line, [{location, "std@hash.erl", 21}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_indexOf-'}, 3}.
  {label, 302}.
    {test, is_nonempty_list, {f, 303}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 304}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 304}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 302}}.
  {label, 303}.
    {move, {integer, -1}, {x, 0}}.
    return.

{function, '-bp_at-', 2, 316}.
  {label, 315}.
    {line, [{location, "std@hash.erl", 22}]}.
    {func_info, {atom, std@hash}, {atom, '-bp_at-'}, 2}.
  {label, 316}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 318}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 317}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 318}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 317}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 317}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_14', 1, 367}.
  {label, 366}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_14'}, 1}.
  {label, 367}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 371}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 372}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 374}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 374}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 375}}.
  {label, 374}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 375}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 371}}.
  {label, 372}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 373}, [{x, 0}]}.
    {jump, {f, 370}}.
  {label, 373}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 370}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_15-t/2-fun-0-', 2, 383}.
  {label, 382}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_15-t/2-fun-0-'}, 2}.
  {label, 383}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 387}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_lt, {f, 387}, [{x, 0}, {x, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 387}, [{x, 0}, {x, 1}]}.
    {jump, {f, 388}}.
  {label, 388}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 387}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_15', 2, 379}.
  {label, 378}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_15'}, 2}.
  {label, 379}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 383}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-utf8Of/1-fun-2-', 1, 377}.
  {label, 376}.
    {line, [{location, "std@hash.erl", 33}]}.
    {func_info, {atom, std@hash}, {atom, '-utf8Of/1-fun-2-'}, 1}.
  {label, 377}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 379}}.
    {call, 1, {f, 47}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_16-t/2-fun-0-', 2, 430}.
  {label, 429}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_16-t/2-fun-0-'}, 2}.
  {label, 430}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 434}}.
  {label, 434}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 436}}.
  {label, 436}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 438}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 437}}.
  {label, 438}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 439}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {y, 6}}.
    {jump, {f, 437}}.
  {label, 439}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 437}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 441}}.
  {label, 441}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 442}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 444}}.
  {label, 442}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 443}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 444}}.
  {label, 443}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 444}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 446}, [{x, 0}, {atom, true}]}.
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
  {label, 446}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 447}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 447}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_16', 2, 426}.
  {label, 425}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_16'}, 2}.
  {label, 426}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 430}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-hexOf/1-fun-3-', 1, 450}.
  {label, 449}.
    {line, [{location, "std@hash.erl", 36}]}.
    {func_info, {atom, std@hash}, {atom, '-hexOf/1-fun-3-'}, 1}.
  {label, 450}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {call, 1, {f, 49}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 451}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 451}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 452}}.
  {label, 451}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:642:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 452}.
    {call, 1, {f, 49}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 275}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '__bp_add', 2, 514}.
  {label, 513}.
    {line, [{location, "std@hash.erl", 38}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_add'}, 2}.
  {label, 514}.
    {test, is_binary, {f, 515}, [{x, 0}]}.
    {test, is_binary, {f, 515}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 515}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '__bp_tpl_17-t/2-fun-0-', 2, 537}.
  {label, 536}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_17-t/2-fun-0-'}, 2}.
  {label, 537}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_17', 2, 533}.
  {label, 532}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_17'}, 2}.
  {label, 533}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 537}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, sublist, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, sublist, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, zipwith, 3}, 5}.

{function, '-xorBytes/2-fun-4-', 1, 539}.
  {label, 538}.
    {line, [{location, "std@hash.erl", 41}]}.
    {func_info, {atom, std@hash}, {atom, '-xorBytes/2-fun-4-'}, 1}.
  {label, 539}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 59}}.
    {deallocate, 3}.
    return.

{function, '-bytesBE/1-fun-5-', 1, 665}.
  {label, 664}.
    {line, [{location, "std@hash.erl", 54}]}.
    {func_info, {atom, std@hash}, {atom, '-bytesBE/1-fun-5-'}, 1}.
  {label, 665}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 256}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 256}], {x, 0}}.
    {test, is_ge, {f, 666}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 666}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 667}}.
  {label, 666}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/hash.bp:841:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 667}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-padOf/2-fun-6-', 2, 711}.
  {label, 710}.
    {line, [{location, "std@hash.erl", 59}]}.
    {func_info, {atom, std@hash}, {atom, '-padOf/2-fun-6-'}, 2}.
  {label, 711}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 59}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_18-t/3-fun-0-', 3, 924}.
  {label, 923}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_18-t/3-fun-0-'}, 3}.
  {label, 924}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 928}}.
  {label, 928}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 930}}.
  {label, 930}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 932}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 931}}.
  {label, 932}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 933}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 931}}.
  {label, 933}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 931}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 935}}.
  {label, 935}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 937}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 936}}.
  {label, 937}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 938}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 936}}.
  {label, 938}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 936}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 940}}.
  {label, 940}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_18', 3, 920}.
  {label, 919}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_18'}, 3}.
  {label, 920}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 924}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_19-t/2-fun-0-', 2, 946}.
  {label, 945}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_19-t/2-fun-0-'}, 2}.
  {label, 946}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 950}}.
  {label, 950}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 952}}.
  {label, 952}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 954}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 953}}.
  {label, 954}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 955}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 953}}.
  {label, 955}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 953}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 957}}.
  {label, 957}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_19', 2, 942}.
  {label, 941}.
    {func_info, {atom, std@hash}, {atom, '__bp_tpl_19'}, 2}.
  {label, 942}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 946}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-flatten/1-fun-7-', 2, 959}.
  {label, 958}.
    {line, [{location, "std@hash.erl", 75}]}.
    {func_info, {atom, std@hash}, {atom, '-flatten/1-fun-7-'}, 2}.
  {label, 959}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 216}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 216}.
  {label, 215}.
    {line, [{location, "std@hash.erl", 75}]}.
    {func_info, {atom, std@hash}, {atom, '__bp_prim_append'}, 2}.
  {label, 216}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 960}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 960}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
