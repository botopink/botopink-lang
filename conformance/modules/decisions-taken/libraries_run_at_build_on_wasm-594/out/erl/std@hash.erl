-module(std@hash).
-export([pbkdf2Sha256/4, cacheKey/1, strongCacheKey/1, etag/1, weakEtag/1, matches/2, fingerprint/2, hmacSha256Base64Url/2, sha1Base64/1, sha256Base64Url/1, equalsConstantTime/2, sha256/1, sha512/1, md5/1, hmacSha256/2, contentHash/1, strongHash/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__panicText'/1, '__bp_priv__frame'/1, '__bp_priv__sha256Body'/1, '__bp_priv__sha256Base64UrlBody'/1, '__bp_priv__strongHashBody'/1, '__bp_priv__sha512Body'/1, '__bp_priv__md5Body'/1, '__bp_priv__sha1Base64Body'/1, '__bp_priv__hmacSha256Body'/2, '__bp_priv__hmacSha256Base64UrlBody'/2, '__bp_priv__equalsConstantTimeBody'/2, '__bp_priv__pbkdf2DeriveBody'/4, '__bp_priv__utf8Of'/1, '__bp_priv__utf8Bytes'/1, '__bp_priv__hexDigit'/1, '__bp_priv__hexOf'/1, '__bp_priv__base64Of'/3, '__bp_priv__base64Group'/4, '__bp_priv__zeroBytes'/1, '__bp_priv__xorByte'/2, '__bp_priv__xorBytes'/2, '__bp_priv__wrap32'/1, '__bp_priv__rotr32'/2, '__bp_priv__mix'/3, '__bp_priv__bits32'/4, '__bp_priv__smallInt'/1, '__bp_priv__upperHalf'/1, '__bp_priv__lowerHalf'/1, '__bp_priv__wordOf'/2, '__bp_priv__wordBE'/2, '__bp_priv__wordLE'/2, '__bp_priv__hexValue'/3, '__bp_priv__halvesOf'/2, '__bp_priv__bytesBE'/1, '__bp_priv__bytesLE'/1, '__bp_priv__padded'/4, '__bp_priv__hmacKeyBlock'/1, '__bp_priv__hmacSha256Bytes'/2, '__bp_priv__padOf'/2, '__bp_priv__hmacWithPads'/3, '__bp_priv__sha256Bytes'/1, '__bp_priv__sha256Block'/4, '__bp_priv__sha1Bytes'/1, '__bp_priv__sha1Block'/3, '__bp_priv__md5Bytes'/1, '__bp_priv__md5Block'/5, '__bp_priv__sha512Bytes'/1, '__bp_priv__sha512Block'/4, '__bp_priv__sha256Initial'/0, '__bp_priv__sha256Constants'/0, '__bp_priv__sha512Initial'/0, '__bp_priv__sha512Constants'/0, '__bp_priv__md5Constants'/0, '__bp_priv__string_slice'/3, '__bp_priv__array_slice'/3, '__bp_priv__array_flatten'/1]).

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

%% import failure

% base64url (no padding) of the raw HMAC-SHA256 of `data` under `key` —

% the JWS HS256 signature (RFC 7515 §3) and a session-cookie MAC.

%% external fn hmacSha256Base64Url -> erlang template
hmacSha256Base64Url(Key, Data) ->
    base64:encode(crypto:mac(hmac, sha256, Key, Data), #{mode => urlsafe, padding => false}).

% Standard base64 (with padding) of the raw SHA-1 of `data` — the

% `Sec-WebSocket-Accept` value of RFC 6455 §1.3. SHA-1 is here for that

% handshake only; it is not a signature primitive.

%% external fn sha1Base64 -> erlang template
sha1Base64(Data) ->
    base64:encode(crypto:hash(sha, Data)).

% base64url (no padding) of the raw SHA-256 of `data` — 43 characters.

%% external fn sha256Base64Url -> erlang template
sha256Base64Url(Data) ->
    base64:encode(crypto:hash(sha256, Data), #{mode => urlsafe, padding => false}).

% `a == b` in time that depends only on the length, not on where the two

% first differ — the compare a signature check must use (`==` on two

% signature strings is a byte-at-a-time timing oracle on both backends).

% Different lengths answer `false` without throwing: `timingSafeEqual` and

% `crypto:hash_equals/2` both raise on a length mismatch, so each template

% checks the byte length first (the length of a MAC is not secret).

%% external fn equalsConstantTime -> erlang template
equalsConstantTime(A, B) ->
    (fun(__A, __B) -> byte_size(__A) =:= byte_size(__B) andalso crypto:hash_equals(__A, __B) end)(A, B).

% ── 1.0.11-beta front 97: PBKDF2 ─────────────────────────────────────────────

% The cell behind `pbkdf2Sha256`: base64url (no padding) of the derived key.

% Node: `crypto.pbkdf2Sync(password, salt, iterations, length, 'sha256')`.

% Erlang: `crypto:pbkdf2_hmac(sha256, Password, Salt, Iterations, Length)`.

%% external fn pbkdf2Derive -> erlang template

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

pbkdf2Sha256(Password, Salt, Iterations, Length) ->
    Refused = ((Iterations < 1) orelse (Length < 1)),
    case Refused of
        true ->
            erlang:error({panic, <<"hash.pbkdf2Sha256: iterations and length must be at least 1">>});
        _ -> ok
    end,
    base64:encode(crypto:pbkdf2_hmac(sha256, Password, Salt, Iterations, Length), #{mode => urlsafe, padding => false}).

% Internal, test scaffolding: the text a body panics with, `""` when it

% answered — `attempt` (decision 431), which a root module may import: it is

% not the harness.

panicText(Body) ->
    case std@failure:attempt(Body) of
        {ok, _} ->
            <<"">>;
        {error, F} ->
            '__bp_field'(F, message)
    end.

% ── tests ────────────────────────────────────────────────────────────────────











% ── hex digests (was `crypto`) ───────────────────────────────────────────────

%% external fn sha256 -> erlang template
sha256(Data) ->
    list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:hash(sha256, Data))]).

%% external fn sha512 -> erlang template
sha512(Data) ->
    list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:hash(sha512, Data))]).

%% external fn md5 -> erlang template
md5(Data) ->
    list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:hash(md5, Data))]).

% HMAC-SHA256. `key` is the secret material; `data` is the message.

% Both lower to the host's keyed-hash primitive — Node's

% `crypto.createHmac('sha256', key).update(data).digest('hex')` and

% Erlang's `crypto:mac(hmac, sha256, key, data)`.

%% external fn hmacSha256 -> erlang template
hmacSha256(Key, Data) ->
    list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:mac(hmac, sha256, Key, Data))]).

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

%% external fn contentHash -> erlang template
contentHash(Value) ->
    (fun(__S) -> __H = lists:foldl(fun(__C, __A) -> (__A * 33 + __C) band 16#FFFFFFFF end, 5381, unicode:characters_to_list(__S)), list_to_binary(string:lowercase(integer_to_list(__H, 16))) end)(Value).

%% external fn strongHash -> erlang template
strongHash(Value) ->
    binary:part(string:lowercase(binary:encode_hex(crypto:hash(sha256, Value))), 0, 32).

% ── cache keys — framed, never joined ────────────────────────────────────────

% A key over several parts. Each part is length-prefixed, so no two different

% part lists can collide: ["user:1", "profile"] and ["user", "1:profile"] frame

% to `6:user:1|7:profile` and `4:user|9:1:profile` and therefore hash to

% different keys. A cache that collides across a user boundary serves one user

% another user's page, so the framing is the whole reason this function exists

% instead of a `join`.

cacheKey(Parts) ->
    (fun(__S) -> __H = lists:foldl(fun(__C, __A) -> (__A * 33 + __C) band 16#FFFFFFFF end, 5381, unicode:characters_to_list(__S)), list_to_binary(string:lowercase(integer_to_list(__H, 16))) end)(frame(Parts)).

% The same framing over the strong hash, for keys built from input the caller

% did not choose.

strongCacheKey(Parts) ->
    binary:part(string:lowercase(binary:encode_hex(crypto:hash(sha256, frame(Parts)))), 0, 32).

% `<length>:<part>` per part, `|` between parts. The one place a multi-part

% key is rendered, so no function in this module joins parts unframed.

frame(Parts) ->
    iolist_to_binary(lists:join(<<"|">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(P) ->
        <<('__bp_text'(erlang:integer_to_binary(erlang:length(unicode:characters_to_list(P)))))/binary, ":", ('__bp_text'(P))/binary>>
    end, Parts)))).

% ── ETags (RFC 9110 § 8.8.3) ─────────────────────────────────────────────────

% A strong ETag, quoted as RFC 9110 requires. The quotes are part of the value:

% a caller who has to remember to add them is a caller who will forget.

etag(Body) ->
    <<"\"", ((fun(__S) -> __H = lists:foldl(fun(__C, __A) -> (__A * 33 + __C) band 16#FFFFFFFF end, 5381, unicode:characters_to_list(__S)), list_to_binary(string:lowercase(integer_to_list(__H, 16))) end)(Body))/binary, "\"">>.

weakEtag(Body) ->
    <<"W/\"", ((fun(__S) -> __H = lists:foldl(fun(__C, __A) -> (__A * 33 + __C) band 16#FFFFFFFF end, 5381, unicode:characters_to_list(__S)), list_to_binary(string:lowercase(integer_to_list(__H, 16))) end)(Body))/binary, "\"">>.

% The 304 decision. Handles the three shapes a handler actually receives: an

% exact match, the `*` wildcard, and a comma-separated candidate list. The

% membership test is `indexOf`, not `Array.contains`: `contains` is a

% `default fn`, which a consumer's embedded copy of this module emits

% verbatim on commonJS (`libs/std/AGENTS.md` § Conventions).

matches(Body, IfNoneMatch) ->
    Header = string:trim(IfNoneMatch),
    Wildcard = (Header =:= <<"*">>),
    Current = etag(Body),
    Weak = weakEtag(Body),
    Candidates = lists:map(fun(C) ->
        string:trim(C)
    end, (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Header, <<",">>)),
    Exact = ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Candidates, Current) =/= (-1)),
    Loose = ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Candidates, Weak) =/= (-1)),
    Hit = case Exact of
        true ->
            true;
        false ->
            Loose
    end,
    case Wildcard of
        true ->
            true;
        false ->
            Hit
    end.

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

fingerprint(FileName, Contents) ->
    Hash = (fun(__S) -> __H = lists:foldl(fun(__C, __A) -> (__A * 33 + __C) band 16#FFFFFFFF end, 5381, unicode:characters_to_list(__S)), list_to_binary(string:lowercase(integer_to_list(__H, 16))) end)(Contents),
    Pieces = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(FileName, <<".">>),
    Tail = (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Pieces, '__bp_int'((erlang:length(Pieces) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:390:40">>)),
    ExtLen = case (Tail =/= undefined) of
        true ->
            '__bp_int'((erlang:length(unicode:characters_to_list(Tail)) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:391:50">>);
        false ->
            0
    end,
    HasExt = case (erlang:length(Pieces) > 1) of
        true ->
            (ExtLen < erlang:length(unicode:characters_to_list(FileName)));
        false ->
            false
    end,
    Cut = '__bp_int'((erlang:length(unicode:characters_to_list(FileName)) - ExtLen), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:393:33">>),
    Stem = case HasExt of
        true ->
            string_slice(FileName, 0, Cut);
        false ->
            FileName
    end,
    Ext = case HasExt of
        true ->
            string_slice(FileName, Cut, erlang:length(unicode:characters_to_list(FileName)));
        false ->
            <<"">>
    end,
    <<('__bp_text'(Stem))/binary, ".", Hash/binary, ('__bp_text'(Ext))/binary>>.

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

sha256Body(Data) ->
    hexOf(sha256Bytes(utf8Of(Data))).

sha256Base64UrlBody(Data) ->
    base64Of(sha256Bytes(utf8Of(Data)), true, false).

strongHashBody(Value) ->
    hexOf(array_slice(sha256Bytes(utf8Of(Value)), 0, 16)).

sha512Body(Data) ->
    hexOf(sha512Bytes(utf8Of(Data))).

md5Body(Data) ->
    hexOf(md5Bytes(utf8Of(Data))).

sha1Base64Body(Data) ->
    base64Of(sha1Bytes(utf8Of(Data)), false, true).

hmacSha256Body(Key, Data) ->
    hexOf(hmacSha256Bytes(hmacKeyBlock(utf8Of(Key)), utf8Of(Data))).

hmacSha256Base64UrlBody(Key, Data) ->
    base64Of(hmacSha256Bytes(hmacKeyBlock(utf8Of(Key)), utf8Of(Data)), true, false).

% Every byte compared, no early exit; a length mismatch is `false`.

equalsConstantTimeBody(A, B) ->
    X = utf8Of(A),
    Y = utf8Of(B),
    case (erlang:length(X) =/= erlang:length(Y)) of
        true ->
            false;
        _ ->
            Diff = 0.0,
            I = 0,
            {Diff@3, I@3} = (fun __BpLoop({Diff@1, I@1}) ->
                case (I@1 < erlang:length(X)) of
                    true ->
                        D = '__bp_int'((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(X, I@1) of
                            undefined ->
                                0;
                            __bp_nullish@1 ->
                                __bp_nullish@1
                        end - (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Y, I@1) of
                            undefined ->
                                0;
                            __bp_nullish ->
                                __bp_nullish
                        end)), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:570:30">>),
                        Diff@2 = (Diff@1 + ('__bp_int'((D * D), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:571:25">>) * 1.0)),
                        I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:572:15">>),
                        __BpLoop({Diff@2, I@2});
                    _ -> {Diff@1, I@1}
                end
            end)({Diff, I}),
            (Diff@3 =:= 0.0)
    end.

% RFC 8018 §5.2 over HMAC-SHA256: block `i` is U1 ^ … ^ Uc, U1 the HMAC of

% the salt and `i` (four bytes, big-endian), each next U the HMAC of the

% last; the key is the blocks' first `length` bytes.

pbkdf2DeriveBody(Password, Salt, Iterations, Length) ->
    Key = hmacKeyBlock(utf8Of(Password)),
    Inner = padOf(Key, 54),
    Outer = padOf(Key, 92),
    S = utf8Of(Salt),
    Out = [],
    Block = 1,
    {Out@3, Block@3} = (fun __BpLoop({Out@1, Block@1}) ->
        case (erlang:length(Out@1) < Length) of
            true ->
                Index = ['__bp_int'((Block@1 div 16777216), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:594:19">>), (('__bp_int'((Block@1 div 65536), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:595:20">>)) rem 256), (('__bp_int'((Block@1 div 256), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:596:20">>)) rem 256), (Block@1 rem 256)],
                U = hmacWithPads(Inner, Outer, (S ++ Index)),
                T = U,
                J = 1,
                {U@3, T@3, J@3} = (fun __BpLoop1({U@1, T@1, J@1}) ->
                    case (J@1 < Iterations) of
                        true ->
                            U@2 = hmacWithPads(Inner, Outer, U@1),
                            T@2 = xorBytes(T@1, U@2),
                            J@2 = '__bp_int'((J@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:605:19">>),
                            __BpLoop1({U@2, T@2, J@2});
                        _ -> {U@1, T@1, J@1}
                    end
                end)({U, T, J}),
                Out@2 = (Out@1 ++ T@3),
                Block@2 = '__bp_int'((Block@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:608:23">>),
                __BpLoop({Out@2, Block@2});
            _ -> {Out@1, Block@1}
        end
    end)({Out, Block}),
    base64Of(array_slice(Out@3, 0, Length), true, false).

% ── bytes and text ──

utf8Of(S) ->
    Parts = lists:map(fun(C) ->
        utf8Bytes((fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(C, 0))
    end, [<<__C/utf8>> || __C <- unicode:characters_to_list(S, utf8)]),
    array_flatten(Parts).

utf8Bytes(Cp) ->
    case (Cp < 128) of
        true ->
            [Cp];
        _ ->
            case (Cp < 2048) of
                true ->
                    ['__bp_int'((192 + '__bp_int'((Cp div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:626:37">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:626:32">>), '__bp_int'((128 + (Cp rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:626:47">>)];
                _ ->
                    case (Cp < 65536) of
                        true ->
                            ['__bp_int'((224 + '__bp_int'((Cp div 4096), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:628:26">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:628:21">>), '__bp_int'((128 + (('__bp_int'((Cp div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:628:44">>)) rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:628:38">>), '__bp_int'((128 + (Cp rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:628:60">>)];
                        _ ->
                            ['__bp_int'((240 + '__bp_int'((Cp div 262144), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:630:18">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:630:13">>), '__bp_int'((128 + (('__bp_int'((Cp div 4096), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:631:19">>)) rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:631:13">>), '__bp_int'((128 + (('__bp_int'((Cp div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:632:19">>)) rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:632:13">>), '__bp_int'((128 + (Cp rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:633:13">>)]
                    end
            end
    end.

hexDigit(N) ->
    case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(<<"0123456789abcdef">>, N) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end.

hexOf(Bytes) ->
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(B) ->
        <<(hexDigit('__bp_int'((B div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:642:40">>)))/binary, (hexDigit((B rem 16)))/binary>>
    end, Bytes)))).

% RFC 4648 base64: §5's alphabet when `url`, `=` padding when `pad`.

base64Of(Bytes, Url, Pad) ->
    Alphabet = case Url of
        true ->
            <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_">>;
        false ->
            <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/">>
    end,
    Out = <<"">>,
    G = 0,
    {Out@3, G@3} = (fun __BpLoop({Out@1, G@1}) ->
        case ('__bp_int'((3 * G@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:653:14">>) < erlang:length(Bytes)) of
            true ->
                Out@2 = <<Out@1/binary, (base64Group(Bytes, G@1, Alphabet, Pad))/binary>>,
                G@2 = '__bp_int'((G@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:655:15">>),
                __BpLoop({Out@2, G@2});
            _ -> {Out@1, G@1}
        end
    end)({Out, G}),
    Out@3.

base64Group(Bytes, G, Alphabet, Pad) ->
    N = '__bp_int'((erlang:length(Bytes) - '__bp_int'((3 * G), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:666:30">>)), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:666:26">>),
    B0 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'((3 * G), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:667:25">>)) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end,
    B1 = case (N > 1) of
        true ->
            case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'(('__bp_int'((3 * G), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:669:20">>) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:669:24">>)) of
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
            case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'(('__bp_int'((3 * G), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:672:20">>) + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:672:24">>)) of
                undefined ->
                    0;
                __bp_nullish@2 ->
                    __bp_nullish@2
            end;
        false ->
            0
    end,
    Fill = case Pad of
        true ->
            <<"=">>;
        false ->
            <<"">>
    end,
    C0 = case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'((B0 div 4), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:675:29">>)) of
        undefined ->
            <<"">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end,
    C1 = case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'(('__bp_int'((((B0 rem 4)) * 16), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:676:35">>) + '__bp_int'((B1 div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:676:45">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:676:40">>)) of
        undefined ->
            <<"">>;
        __bp_nullish@4 ->
            __bp_nullish@4
    end,
    C2 = case (N > 1) of
        true ->
            case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'(('__bp_int'((((B1 rem 16)) * 4), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:678:31">>) + '__bp_int'((B2 div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:678:40">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:678:35">>)) of
                undefined ->
                    <<"">>;
                __bp_nullish@5 ->
                    __bp_nullish@5
            end;
        false ->
            Fill
    end,
    C3 = case (N > 2) of
        true ->
            case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, (B2 rem 64)) of
                undefined ->
                    <<"">>;
                __bp_nullish@6 ->
                    __bp_nullish@6
            end;
        false ->
            Fill
    end,
    '__bp_add'('__bp_add'('__bp_add'(C0, C1), C2), C3).

% `n` zero bytes, by doubling (`array.repeat` and `array.range` recurse once

% per element).

zeroBytes(N) ->
    Zeros = [0],
    Zeros@3 = (fun __BpLoop(Zeros@1) ->
        case (erlang:length(Zeros@1) < N) of
            true ->
                Zeros@2 = (Zeros@1 ++ Zeros@1),
                __BpLoop(Zeros@2);
            _ -> Zeros@1
        end
    end)(Zeros),
    array_slice(Zeros@3, 0, N).

xorByte(A, B) ->
    R = 0,
    X = A,
    Y = B,
    Bit = 1,
    {R@4, X@3, Y@3, Bit@3} = (fun __BpLoop({R@1, X@1, Y@1, Bit@1}) ->
        case (Bit@1 < 256) of
            true ->
                R@3 = case ((X@1 rem 2) =/= (Y@1 rem 2)) of
                    true ->
                        R@2 = '__bp_int'((R@1 + Bit@1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:702:35">>),
                        R@2;
                    _ ->
                        R@1
                end,
                X@2 = '__bp_int'((X@1 div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:703:15">>),
                Y@2 = '__bp_int'((Y@1 div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:704:15">>),
                Bit@2 = '__bp_int'((Bit@1 * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:705:19">>),
                __BpLoop({R@3, X@2, Y@2, Bit@2});
            _ -> {R@1, X@1, Y@1, Bit@1}
        end
    end)({R, X, Y, Bit}),
    R@4.

xorBytes(A, B) ->
    lists:map(fun(P) ->
        xorByte(erlang:element(1, P), erlang:element(2, P))
    end, lists:zipwith(fun(__X, __Y) -> {__X, __Y} end, lists:sublist(A, length(B)), lists:sublist(B, length(A)))).

% ── words ──

wrap32(X) ->
    (X - (math:floor(((X / 4294967296.0))) * 4294967296.0)).

% `x` rotated right by n bits, `p` = 2^n.

rotr32(X, P) ->
    mix(X, X, P).

% The low 32 bits of (y:x) >> n, `p` = 2^n: x's bits shifted down and y's

% low n bits above them.

mix(X, Y, P) ->
    Down = math:floor(((X / '__bp_nz'(P, <<"division by zero: / on f64 at src/hash.bp:728:19">>)))),
    Low = (Y - (math:floor(((Y / '__bp_nz'(P, <<"division by zero: / on f64 at src/hash.bp:729:22">>)))) * P)),
    (Down + (Low * ((4294967296.0 / '__bp_nz'(P, <<"division by zero: / on f64 at src/hash.bp:730:39">>))))).

% One of four bitwise functions of three words, bit by bit: `mode` 0 is

% x ^ y ^ z, 1 chooses y where x is set and z elsewhere, 2 is the

% majority, 3 is MD5's y ^ (x | ~z).

bits32(X, Y, Z, Mode) ->
    A = X,
    B = Y,
    C = Z,
    R = 0.0,
    Weight = 1.0,
    I = 0,
    {R@4, A@3, B@3, C@3, Weight@3, I@3} = (fun __BpLoop({R@1, A@1, B@1, C@1, Weight@1, I@1}) ->
        case (I@1 < 32) of
            true ->
                Ha = math:floor(((A@1 / 2.0))),
                Hb = math:floor(((B@1 / 2.0))),
                Hc = math:floor(((C@1 / 2.0))),
                Ba = (A@1 - (2.0 * Ha)),
                Bb = (B@1 - (2.0 * Hb)),
                Bc = (C@1 - (2.0 * Hc)),
                Sum = ((Ba + Bb) + Bc),
                On = false,
                On@2 = case (Mode =:= 0) of
                    true ->
                        On@1 = ((Sum =:= 1.0) orelse (Sum =:= 3.0)),
                        On@1;
                    _ ->
                        On
                end,
                On@4 = case (Mode =:= 1) of
                    true ->
                        On@3 = ((((Ba =:= 1.0) andalso (Bb =:= 1.0))) orelse (((Ba =:= 0.0) andalso (Bc =:= 1.0)))),
                        On@3;
                    _ ->
                        On@2
                end,
                On@6 = case (Mode =:= 2) of
                    true ->
                        On@5 = (Sum >= 2.0),
                        On@5;
                    _ ->
                        On@4
                end,
                On@8 = case (Mode =:= 3) of
                    true ->
                        Either = case ((Ba =:= 1.0) orelse (Bc =:= 0.0)) of
                            true ->
                                1.0;
                            false ->
                                0.0
                        end,
                        On@7 = ((Bb + Either) =:= 1.0),
                        On@7;
                    _ ->
                        On@6
                end,
                R@3 = case On@8 of
                    true ->
                        R@2 = (R@1 + Weight@1),
                        R@2;
                    _ ->
                        R@1
                end,
                A@2 = Ha,
                B@2 = Hb,
                C@2 = Hc,
                Weight@2 = (Weight@1 * 2.0),
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:765:15">>),
                __BpLoop({R@3, A@2, B@2, C@2, Weight@2, I@2});
            _ -> {R@1, A@1, B@1, C@1, Weight@1, I@1}
        end
    end)({R, A, B, C, Weight, I}),
    R@4.

% A whole `v` in 0..65535 as an `i32`.

smallInt(V) ->
    R = 0,
    Rest = V,
    Bit = 32768,
    Weight = 32768.0,
    {R@4, Rest@4, Bit@3, Weight@3} = (fun __BpLoop({R@1, Rest@1, Bit@1, Weight@1}) ->
        case (Bit@1 > 0) of
            true ->
                {R@3, Rest@3} = case (Rest@1 >= Weight@1) of
                    true ->
                        R@2 = '__bp_int'((R@1 + Bit@1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:778:19">>),
                        Rest@2 = (Rest@1 - Weight@1),
                        {R@2, Rest@2};
                    _ ->
                        {R@1, Rest@1}
                end,
                Bit@2 = '__bp_int'((Bit@1 div 2), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:781:19">>),
                Weight@2 = (Weight@1 / 2.0),
                __BpLoop({R@3, Rest@3, Bit@2, Weight@2});
            _ -> {R@1, Rest@1, Bit@1, Weight@1}
        end
    end)({R, Rest, Bit, Weight}),
    R@4.

upperHalf(W) ->
    smallInt(math:floor(((W / 65536.0)))).

lowerHalf(W) ->
    smallInt((W - (math:floor(((W / 65536.0))) * 65536.0))).

% Word `i` of a halves array.

wordOf(H, I) ->
    ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(H, '__bp_int'((2 * I), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:797:19">>)) of
        undefined ->
            0;
        __bp_nullish@1 ->
            __bp_nullish@1
    end * 65536.0) + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(H, '__bp_int'(('__bp_int'((2 * I), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:797:48">>) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:797:52">>)) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end * 1.0)).

wordBE(M, I) ->
    ((((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, I) of
        undefined ->
            0;
        __bp_nullish@3 ->
            __bp_nullish@3
    end * 16777216.0) + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:802:18">>)) of
        undefined ->
            0;
        __bp_nullish@2 ->
            __bp_nullish@2
    end * 65536.0)) + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:803:18">>)) of
        undefined ->
            0;
        __bp_nullish@1 ->
            __bp_nullish@1
    end * 256.0)) + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, '__bp_int'((I + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:804:18">>)) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end * 1.0)).

wordLE(M, I) ->
    ((((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, '__bp_int'((I + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:808:19">>)) of
        undefined ->
            0;
        __bp_nullish@3 ->
            __bp_nullish@3
    end * 16777216.0) + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:809:18">>)) of
        undefined ->
            0;
        __bp_nullish@2 ->
            __bp_nullish@2
    end * 65536.0)) + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:810:18">>)) of
        undefined ->
            0;
        __bp_nullish@1 ->
            __bp_nullish@1
    end * 256.0)) + (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(M, I) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end * 1.0)).

% The `count` hex digits of `w` from `start` as a whole number.

hexValue(W, Start, Count) ->
    V = 0.0,
    I = 0,
    {V@3, I@3} = (fun __BpLoop({V@1, I@1}) ->
        case (I@1 < Count) of
            true ->
                C = (fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(W, '__bp_int'((Start + I@1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:819:36">>)),
                Digit = case (C < 58) of
                    true ->
                        '__bp_int'((C - 48), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:820:35">>);
                    false ->
                        '__bp_int'((C - 87), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:820:47">>)
                end,
                V@2 = ((V@1 * 16.0) + (Digit * 1.0)),
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:822:15">>),
                __BpLoop({V@2, I@2});
            _ -> {V@1, I@1}
        end
    end)({V, I}),
    V@3.

% Space-separated hex words of `digits` (8 or 16) digits as 16-bit halves.

halvesOf(Text, Digits) ->
    Out = [],
    At = 0,
    {Out@3, At@3} = (fun __BpLoop({Out@1, At@1}) ->
        case (At@1 < erlang:length(unicode:characters_to_list(Text))) of
            true ->
                V = hexValue(Text, At@1, 8),
                Out@2 = (Out@1 ++ [upperHalf(V), lowerHalf(V)]),
                At@2 = case ((('__bp_int'((At@1 + 8), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:834:22">>)) rem '__bp_nz'(('__bp_int'((Digits + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:834:37">>)), <<"integer division by zero: % on i32 at src/hash.bp:834:27">>)) =:= Digits) of
                    true ->
                        '__bp_int'((At@1 + 9), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:834:56">>);
                    false ->
                        '__bp_int'((At@1 + 8), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:834:68">>)
                end,
                __BpLoop({Out@2, At@2});
            _ -> {Out@1, At@1}
        end
    end)({Out, At}),
    Out@3.

% Halves to bytes, each word big-endian.

bytesBE(H) ->
    Parts = lists:map(fun(X) ->
        ['__bp_int'((X div 256), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:841:52">>), (X rem 256)]
    end, H),
    array_flatten(Parts).

% Halves to bytes, each word little-endian (MD5).

bytesLE(H) ->
    Out = [],
    I = 0,
    {Out@3, I@3} = (fun __BpLoop({Out@1, I@1}) ->
        case (I@1 < erlang:length(H)) of
            true ->
                Upper = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(H, I@1) of
                    undefined ->
                        0;
                    __bp_nullish ->
                        __bp_nullish
                end,
                Lower = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(H, '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:851:28">>)) of
                    undefined ->
                        0;
                    __bp_nullish@1 ->
                        __bp_nullish@1
                end,
                Out@2 = (Out@1 ++ [(Lower rem 256), '__bp_int'((Lower div 256), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:852:46">>), (Upper rem 256), '__bp_int'((Upper div 256), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:852:72">>)]),
                I@2 = '__bp_int'((I@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:853:15">>),
                __BpLoop({Out@2, I@2});
            _ -> {Out@1, I@1}
        end
    end)({Out, I}),
    Out@3.

% The message, `0x80`, zeros, and its length in bits in the last

% `lengthBytes` bytes of a `block`-byte block.

padded(Msg, Block, LengthBytes, BigEndian) ->
    Bits = '__bp_int'((erlang:length(Msg) * 8), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:866:27">>),
    Zeros = (('__bp_int'((Block - (('__bp_int'(('__bp_int'((erlang:length(Msg) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:867:38">>) + LengthBytes), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:867:42">>)) rem '__bp_nz'(Block, <<"integer division by zero: % on i32 at src/hash.bp:867:57">>))), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:867:24">>)) rem '__bp_nz'(Block, <<"integer division by zero: % on i32 at src/hash.bp:867:66">>)),
    Be = ['__bp_int'((Bits div 16777216), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:869:14">>), (('__bp_int'((Bits div 65536), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:870:15">>)) rem 256), (('__bp_int'((Bits div 256), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:871:15">>)) rem 256), (Bits rem 256)],
    Size = case BigEndian of
        true ->
            (zeroBytes('__bp_int'((LengthBytes - 4), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:875:31">>)) ++ Be);
        false ->
            (lists:reverse(Be) ++ zeroBytes('__bp_int'((LengthBytes - 4), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:877:51">>)))
    end,
    (Msg ++ (([128] ++ zeroBytes(Zeros)) ++ Size)).

% ── HMAC ──

% The key as HMAC's 64-byte block: hashed when longer, zero-padded.

hmacKeyBlock(Key) ->
    Short = case (erlang:length(Key) > 64) of
        true ->
            sha256Bytes(Key);
        false ->
            Key
    end,
    (Short ++ zeroBytes('__bp_int'((64 - erlang:length(Short)), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/hash.bp:886:38">>))).

hmacSha256Bytes(Block, Msg) ->
    hmacWithPads(padOf(Block, 54), padOf(Block, 92), Msg).

% The key block with every byte xored with `pad` (0x36 inner, 0x5c outer).

padOf(Block, Pad) ->
    lists:map(fun(B) ->
        xorByte(B, Pad)
    end, Block).

hmacWithPads(Inner, Outer, Msg) ->
    sha256Bytes((Outer ++ sha256Bytes((Inner ++ Msg)))).

% ── SHA-256 ──

sha256Bytes(Msg) ->
    M = padded(Msg, 64, 8, true),
    K = sha256Constants(),
    H = halvesOf(sha256Initial(), 8),
    At = 0,
    {H@3, At@3} = (fun __BpLoop({H@1, At@1}) ->
        case (At@1 < erlang:length(M)) of
            true ->
                H@2 = sha256Block(H@1, M, At@1, K),
                At@2 = '__bp_int'((At@1 + 64), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:915:17">>),
                __BpLoop({H@2, At@2});
            _ -> {H@1, At@1}
        end
    end)({H, At}),
    bytesBE(H@3).

sha256Block(H, M, At, K) ->
    A = wordOf(H, 0),
    B = wordOf(H, 1),
    C = wordOf(H, 2),
    D = wordOf(H, 3),
    E = wordOf(H, 4),
    F = wordOf(H, 5),
    G = wordOf(H, 6),
    Hh = wordOf(H, 7),
    W0 = wordBE(M, At),
    W1 = wordBE(M, '__bp_int'((At + 4), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:930:27">>)),
    W2 = wordBE(M, '__bp_int'((At + 8), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:931:27">>)),
    W3 = wordBE(M, '__bp_int'((At + 12), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:932:27">>)),
    W4 = wordBE(M, '__bp_int'((At + 16), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:933:27">>)),
    W5 = wordBE(M, '__bp_int'((At + 20), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:934:27">>)),
    W6 = wordBE(M, '__bp_int'((At + 24), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:935:27">>)),
    W7 = wordBE(M, '__bp_int'((At + 28), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:936:27">>)),
    W8 = wordBE(M, '__bp_int'((At + 32), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:937:27">>)),
    W9 = wordBE(M, '__bp_int'((At + 36), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:938:27">>)),
    W10 = wordBE(M, '__bp_int'((At + 40), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:939:28">>)),
    W11 = wordBE(M, '__bp_int'((At + 44), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:940:28">>)),
    W12 = wordBE(M, '__bp_int'((At + 48), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:941:28">>)),
    W13 = wordBE(M, '__bp_int'((At + 52), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:942:28">>)),
    W14 = wordBE(M, '__bp_int'((At + 56), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:943:28">>)),
    W15 = wordBE(M, '__bp_int'((At + 60), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:944:28">>)),
    T = 0,
    {Hh@3, G@3, F@3, E@3, D@3, C@3, B@3, A@3, W0@3, W1@3, W2@3, W3@3, W4@3, W5@3, W6@3, W7@3, W8@3, W9@3, W10@3, W11@3, W12@3, W13@3, W14@3, W15@3, T@3} = (fun __BpLoop({Hh@1, G@1, F@1, E@1, D@1, C@1, B@1, A@1, W0@1, W1@1, W2@1, W3@1, W4@1, W5@1, W6@1, W7@1, W8@1, W9@1, W10@1, W11@1, W12@1, W13@1, W14@1, W15@1, T@1}) ->
        case (T@1 < 64) of
            true ->
                S1 = bits32(rotr32(E@1, 64.0), rotr32(E@1, 2048.0), rotr32(E@1, 33554432.0), 0),
                T1 = ((((Hh@1 + S1) + bits32(E@1, F@1, G@1, 1)) + hexValue(K, '__bp_int'((9 * T@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:953:63">>), 8)) + W0@1),
                S0 = bits32(rotr32(A@1, 4.0), rotr32(A@1, 8192.0), rotr32(A@1, 4194304.0), 0),
                T2 = (S0 + bits32(A@1, B@1, C@1, 2)),
                Hh@2 = G@1,
                G@2 = F@1,
                F@2 = E@1,
                E@2 = wrap32((D@1 + T1)),
                D@2 = C@1,
                C@2 = B@1,
                B@2 = A@1,
                A@2 = wrap32((T1 + T2)),
                G0 = bits32(rotr32(W1@1, 128.0), rotr32(W1@1, 262144.0), math:floor(((W1@1 / 8.0))), 0),
                G1 = bits32(rotr32(W14@1, 131072.0), rotr32(W14@1, 524288.0), math:floor(((W14@1 / 1024.0))), 0),
                Next = wrap32((((G1 + W9@1) + G0) + W0@1)),
                W0@2 = W1@1,
                W1@2 = W2@1,
                W2@2 = W3@1,
                W3@2 = W4@1,
                W4@2 = W5@1,
                W5@2 = W6@1,
                W6@2 = W7@1,
                W7@2 = W8@1,
                W8@2 = W9@1,
                W9@2 = W10@1,
                W10@2 = W11@1,
                W11@2 = W12@1,
                W12@2 = W13@1,
                W13@2 = W14@1,
                W14@2 = W15@1,
                W15@2 = Next,
                T@2 = '__bp_int'((T@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:998:15">>),
                __BpLoop({Hh@2, G@2, F@2, E@2, D@2, C@2, B@2, A@2, W0@2, W1@2, W2@2, W3@2, W4@2, W5@2, W6@2, W7@2, W8@2, W9@2, W10@2, W11@2, W12@2, W13@2, W14@2, W15@2, T@2});
            _ -> {Hh@1, G@1, F@1, E@1, D@1, C@1, B@1, A@1, W0@1, W1@1, W2@1, W3@1, W4@1, W5@1, W6@1, W7@1, W8@1, W9@1, W10@1, W11@1, W12@1, W13@1, W14@1, W15@1, T@1}
        end
    end)({Hh, G, F, E, D, C, B, A, W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15, T}),
    N0 = wrap32((wordOf(H, 0) + A@3)),
    N1 = wrap32((wordOf(H, 1) + B@3)),
    N2 = wrap32((wordOf(H, 2) + C@3)),
    N3 = wrap32((wordOf(H, 3) + D@3)),
    N4 = wrap32((wordOf(H, 4) + E@3)),
    N5 = wrap32((wordOf(H, 5) + F@3)),
    N6 = wrap32((wordOf(H, 6) + G@3)),
    N7 = wrap32((wordOf(H, 7) + Hh@3)),
    [upperHalf(N0), lowerHalf(N0), upperHalf(N1), lowerHalf(N1), upperHalf(N2), lowerHalf(N2), upperHalf(N3), lowerHalf(N3), upperHalf(N4), lowerHalf(N4), upperHalf(N5), lowerHalf(N5), upperHalf(N6), lowerHalf(N6), upperHalf(N7), lowerHalf(N7)].

% ── SHA-1 ──

sha1Bytes(Msg) ->
    M = padded(Msg, 64, 8, true),
    H = halvesOf(<<"67452301 efcdab89 98badcfe 10325476 c3d2e1f0">>, 8),
    At = 0,
    {H@3, At@3} = (fun __BpLoop({H@1, At@1}) ->
        case (At@1 < erlang:length(M)) of
            true ->
                H@2 = sha1Block(H@1, M, At@1),
                At@2 = '__bp_int'((At@1 + 64), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1036:17">>),
                __BpLoop({H@2, At@2});
            _ -> {H@1, At@1}
        end
    end)({H, At}),
    bytesBE(H@3).

sha1Block(H, M, At) ->
    A = wordOf(H, 0),
    B = wordOf(H, 1),
    C = wordOf(H, 2),
    D = wordOf(H, 3),
    E = wordOf(H, 4),
    W0 = wordBE(M, At),
    W1 = wordBE(M, '__bp_int'((At + 4), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1048:27">>)),
    W2 = wordBE(M, '__bp_int'((At + 8), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1049:27">>)),
    W3 = wordBE(M, '__bp_int'((At + 12), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1050:27">>)),
    W4 = wordBE(M, '__bp_int'((At + 16), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1051:27">>)),
    W5 = wordBE(M, '__bp_int'((At + 20), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1052:27">>)),
    W6 = wordBE(M, '__bp_int'((At + 24), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1053:27">>)),
    W7 = wordBE(M, '__bp_int'((At + 28), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1054:27">>)),
    W8 = wordBE(M, '__bp_int'((At + 32), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1055:27">>)),
    W9 = wordBE(M, '__bp_int'((At + 36), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1056:27">>)),
    W10 = wordBE(M, '__bp_int'((At + 40), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1057:28">>)),
    W11 = wordBE(M, '__bp_int'((At + 44), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1058:28">>)),
    W12 = wordBE(M, '__bp_int'((At + 48), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1059:28">>)),
    W13 = wordBE(M, '__bp_int'((At + 52), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1060:28">>)),
    W14 = wordBE(M, '__bp_int'((At + 56), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1061:28">>)),
    W15 = wordBE(M, '__bp_int'((At + 60), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1062:28">>)),
    T = 0,
    {E@3, D@3, C@3, B@3, A@3, W0@3, W1@3, W2@3, W3@3, W4@3, W5@3, W6@3, W7@3, W8@3, W9@3, W10@3, W11@3, W12@3, W13@3, W14@3, W15@3, T@3} = (fun __BpLoop({E@1, D@1, C@1, B@1, A@1, W0@1, W1@1, W2@1, W3@1, W4@1, W5@1, W6@1, W7@1, W8@1, W9@1, W10@1, W11@1, W12@1, W13@1, W14@1, W15@1, T@1}) ->
        case (T@1 < 80) of
            true ->
                F = case (T@1 < 20) of
                    true ->
                        (bits32(B@1, C@1, D@1, 1) + 1518500249.0);
                    false ->
                        case (T@1 < 40) of
                            true ->
                                (bits32(B@1, C@1, D@1, 0) + 1859775393.0);
                            false ->
                                case (T@1 < 60) of
                                    true ->
                                        (bits32(B@1, C@1, D@1, 2) + 2400959708.0);
                                    false ->
                                        (bits32(B@1, C@1, D@1, 0) + 3395469782.0)
                                end
                        end
                end,
                Temp = wrap32((((rotr32(A@1, 134217728.0) + F) + E@1) + W0@1)),
                E@2 = D@1,
                D@2 = C@1,
                C@2 = rotr32(B@1, 4.0),
                B@2 = A@1,
                A@2 = Temp,
                Mixed = bits32(bits32(W13@1, W8@1, W2@1, 0), W0@1, 0.0, 0),
                Next = rotr32(Mixed, 2147483648.0),
                W0@2 = W1@1,
                W1@2 = W2@1,
                W2@2 = W3@1,
                W3@2 = W4@1,
                W4@2 = W5@1,
                W5@2 = W6@1,
                W6@2 = W7@1,
                W7@2 = W8@1,
                W8@2 = W9@1,
                W9@2 = W10@1,
                W10@2 = W11@1,
                W11@2 = W12@1,
                W12@2 = W13@1,
                W13@2 = W14@1,
                W14@2 = W15@1,
                W15@2 = Next,
                T@2 = '__bp_int'((T@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1097:15">>),
                __BpLoop({E@2, D@2, C@2, B@2, A@2, W0@2, W1@2, W2@2, W3@2, W4@2, W5@2, W6@2, W7@2, W8@2, W9@2, W10@2, W11@2, W12@2, W13@2, W14@2, W15@2, T@2});
            _ -> {E@1, D@1, C@1, B@1, A@1, W0@1, W1@1, W2@1, W3@1, W4@1, W5@1, W6@1, W7@1, W8@1, W9@1, W10@1, W11@1, W12@1, W13@1, W14@1, W15@1, T@1}
        end
    end)({E, D, C, B, A, W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15, T}),
    N0 = wrap32((wordOf(H, 0) + A@3)),
    N1 = wrap32((wordOf(H, 1) + B@3)),
    N2 = wrap32((wordOf(H, 2) + C@3)),
    N3 = wrap32((wordOf(H, 3) + D@3)),
    N4 = wrap32((wordOf(H, 4) + E@3)),
    [upperHalf(N0), lowerHalf(N0), upperHalf(N1), lowerHalf(N1), upperHalf(N2), lowerHalf(N2), upperHalf(N3), lowerHalf(N3), upperHalf(N4), lowerHalf(N4)].

% ── MD5 ──

md5Bytes(Msg) ->
    M = padded(Msg, 64, 8, false),
    K = md5Constants(),
    % 2^(32 − s) for each round's four left-rotation amounts s.
    Shifts = [33554432, 1048576, 32768, 1024, 134217728, 8388608, 262144, 4096, 268435456, 2097152, 65536, 512, 67108864, 4194304, 131072, 2048],
    H = halvesOf(<<"67452301 efcdab89 98badcfe 10325476">>, 8),
    At = 0,
    {H@3, At@3} = (fun __BpLoop({H@1, At@1}) ->
        case (At@1 < erlang:length(M)) of
            true ->
                H@2 = md5Block(H@1, M, At@1, K, Shifts),
                At@2 = '__bp_int'((At@1 + 64), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1146:17">>),
                __BpLoop({H@2, At@2});
            _ -> {H@1, At@1}
        end
    end)({H, At}),
    bytesLE(H@3).

md5Block(H, M, At, K, Shifts) ->
    A = wordOf(H, 0),
    B = wordOf(H, 1),
    C = wordOf(H, 2),
    D = wordOf(H, 3),
    I = 0,
    {A@3, D@3, C@3, B@3, I@3} = (fun __BpLoop({A@1, D@1, C@1, B@1, I@1}) ->
        case (I@1 < 64) of
            true ->
                Round = '__bp_int'((I@1 div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/hash.bp:1164:23">>),
                F = case (Round =:= 0) of
                    true ->
                        bits32(B@1, C@1, D@1, 1);
                    false ->
                        case (Round =:= 1) of
                            true ->
                                bits32(D@1, B@1, C@1, 1);
                            false ->
                                case (Round =:= 2) of
                                    true ->
                                        bits32(B@1, C@1, D@1, 0);
                                    false ->
                                        bits32(B@1, C@1, D@1, 3)
                                end
                        end
                end,
                G = case (Round =:= 0) of
                    true ->
                        I@1;
                    false ->
                        case (Round =:= 1) of
                            true ->
                                (('__bp_int'(('__bp_int'((5 * I@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1176:16">>) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1176:20">>)) rem 16);
                            false ->
                                case (Round =:= 2) of
                                    true ->
                                        (('__bp_int'(('__bp_int'((3 * I@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1178:16">>) + 5), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1178:20">>)) rem 16);
                                    false ->
                                        (('__bp_int'((7 * I@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1180:16">>)) rem 16)
                                end
                        end
                end,
                Sum = wrap32((((F + A@1) + hexValue(K, '__bp_int'((9 * I@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1181:48">>), 8)) + wordLE(M, '__bp_int'((At + '__bp_int'((4 * G), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1181:75">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1181:71">>)))),
                P = (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Shifts, '__bp_int'(('__bp_int'((Round * 4), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1182:33">>) + (I@1 rem 4)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1182:37">>)) of
                    undefined ->
                        1;
                    __bp_nullish ->
                        __bp_nullish
                end * 1.0),
                A@2 = D@1,
                D@2 = C@1,
                C@2 = B@1,
                B@2 = wrap32((B@1 + rotr32(Sum, P))),
                I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1187:15">>),
                __BpLoop({A@2, D@2, C@2, B@2, I@2});
            _ -> {A@1, D@1, C@1, B@1, I@1}
        end
    end)({A, D, C, B, I}),
    N0 = wrap32((wordOf(H, 0) + A@3)),
    N1 = wrap32((wordOf(H, 1) + B@3)),
    N2 = wrap32((wordOf(H, 2) + C@3)),
    N3 = wrap32((wordOf(H, 3) + D@3)),
    [upperHalf(N0), lowerHalf(N0), upperHalf(N1), lowerHalf(N1), upperHalf(N2), lowerHalf(N2), upperHalf(N3), lowerHalf(N3)].

% ── SHA-512 ──

sha512Bytes(Msg) ->
    M = padded(Msg, 128, 16, true),
    K = sha512Constants(),
    H = halvesOf(sha512Initial(), 16),
    At = 0,
    {H@3, At@3} = (fun __BpLoop({H@1, At@1}) ->
        case (At@1 < erlang:length(M)) of
            true ->
                H@2 = sha512Block(H@1, M, At@1, K),
                At@2 = '__bp_int'((At@1 + 128), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1214:17">>),
                __BpLoop({H@2, At@2});
            _ -> {H@1, At@1}
        end
    end)({H, At}),
    bytesBE(H@3).

sha512Block(H, M, At, K) ->
    Ah = wordOf(H, 0),
    Al = wordOf(H, 1),
    Bh = wordOf(H, 2),
    Bl = wordOf(H, 3),
    Ch = wordOf(H, 4),
    Cl = wordOf(H, 5),
    Dh = wordOf(H, 6),
    Dl = wordOf(H, 7),
    Eh = wordOf(H, 8),
    El = wordOf(H, 9),
    Fh = wordOf(H, 10),
    Fl = wordOf(H, 11),
    Gh = wordOf(H, 12),
    Gl = wordOf(H, 13),
    Hh = wordOf(H, 14),
    Hl = wordOf(H, 15),
    W0h = wordBE(M, '__bp_int'((At + 0), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1236:28">>)),
    W0l = wordBE(M, '__bp_int'((At + 4), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1237:28">>)),
    W1h = wordBE(M, '__bp_int'((At + 8), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1238:28">>)),
    W1l = wordBE(M, '__bp_int'((At + 12), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1239:28">>)),
    W2h = wordBE(M, '__bp_int'((At + 16), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1240:28">>)),
    W2l = wordBE(M, '__bp_int'((At + 20), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1241:28">>)),
    W3h = wordBE(M, '__bp_int'((At + 24), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1242:28">>)),
    W3l = wordBE(M, '__bp_int'((At + 28), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1243:28">>)),
    W4h = wordBE(M, '__bp_int'((At + 32), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1244:28">>)),
    W4l = wordBE(M, '__bp_int'((At + 36), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1245:28">>)),
    W5h = wordBE(M, '__bp_int'((At + 40), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1246:28">>)),
    W5l = wordBE(M, '__bp_int'((At + 44), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1247:28">>)),
    W6h = wordBE(M, '__bp_int'((At + 48), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1248:28">>)),
    W6l = wordBE(M, '__bp_int'((At + 52), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1249:28">>)),
    W7h = wordBE(M, '__bp_int'((At + 56), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1250:28">>)),
    W7l = wordBE(M, '__bp_int'((At + 60), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1251:28">>)),
    W8h = wordBE(M, '__bp_int'((At + 64), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1252:28">>)),
    W8l = wordBE(M, '__bp_int'((At + 68), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1253:28">>)),
    W9h = wordBE(M, '__bp_int'((At + 72), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1254:28">>)),
    W9l = wordBE(M, '__bp_int'((At + 76), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1255:28">>)),
    W10h = wordBE(M, '__bp_int'((At + 80), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1256:29">>)),
    W10l = wordBE(M, '__bp_int'((At + 84), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1257:29">>)),
    W11h = wordBE(M, '__bp_int'((At + 88), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1258:29">>)),
    W11l = wordBE(M, '__bp_int'((At + 92), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1259:29">>)),
    W12h = wordBE(M, '__bp_int'((At + 96), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1260:29">>)),
    W12l = wordBE(M, '__bp_int'((At + 100), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1261:29">>)),
    W13h = wordBE(M, '__bp_int'((At + 104), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1262:29">>)),
    W13l = wordBE(M, '__bp_int'((At + 108), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1263:29">>)),
    W14h = wordBE(M, '__bp_int'((At + 112), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1264:29">>)),
    W14l = wordBE(M, '__bp_int'((At + 116), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1265:29">>)),
    W15h = wordBE(M, '__bp_int'((At + 120), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1266:29">>)),
    W15l = wordBE(M, '__bp_int'((At + 124), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1267:29">>)),
    T = 0,
    {Hh@3, Hl@3, Gh@3, Gl@3, Fh@3, Fl@3, Eh@3, El@3, Dh@3, Dl@3, Ch@3, Cl@3, Bh@3, Bl@3, Ah@3, Al@3, W0h@3, W0l@3, W1h@3, W1l@3, W2h@3, W2l@3, W3h@3, W3l@3, W4h@3, W4l@3, W5h@3, W5l@3, W6h@3, W6l@3, W7h@3, W7l@3, W8h@3, W8l@3, W9h@3, W9l@3, W10h@3, W10l@3, W11h@3, W11l@3, W12h@3, W12l@3, W13h@3, W13l@3, W14h@3, W14l@3, W15h@3, W15l@3, T@3} = (fun __BpLoop({Hh@1, Hl@1, Gh@1, Gl@1, Fh@1, Fl@1, Eh@1, El@1, Dh@1, Dl@1, Ch@1, Cl@1, Bh@1, Bl@1, Ah@1, Al@1, W0h@1, W0l@1, W1h@1, W1l@1, W2h@1, W2l@1, W3h@1, W3l@1, W4h@1, W4l@1, W5h@1, W5l@1, W6h@1, W6l@1, W7h@1, W7l@1, W8h@1, W8l@1, W9h@1, W9l@1, W10h@1, W10l@1, W11h@1, W11l@1, W12h@1, W12l@1, W13h@1, W13l@1, W14h@1, W14l@1, W15h@1, W15l@1, T@1}) ->
        case (T@1 < 80) of
            true ->
                S1h = bits32(mix(Eh@1, El@1, 16384.0), mix(Eh@1, El@1, 262144.0), mix(El@1, Eh@1, 512.0), 0),
                S1l = bits32(mix(El@1, Eh@1, 16384.0), mix(El@1, Eh@1, 262144.0), mix(Eh@1, El@1, 512.0), 0),
                T1l = ((((Hl@1 + S1l) + bits32(El@1, Fl@1, Gl@1, 1)) + hexValue(K, '__bp_int'(('__bp_int'((17 * T@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1285:30">>) + 8), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1285:34">>), 8)) + W0l@1),
                T1h = wrap32((((((Hh@1 + S1h) + bits32(Eh@1, Fh@1, Gh@1, 1)) + hexValue(K, '__bp_int'((17 * T@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/hash.bp:1291:34">>), 8)) + W0h@1) + math:floor(((T1l / 4294967296.0))))),
                T1lw = wrap32(T1l),
                S0h = bits32(mix(Ah@1, Al@1, 268435456.0), mix(Al@1, Ah@1, 4.0), mix(Al@1, Ah@1, 128.0), 0),
                S0l = bits32(mix(Al@1, Ah@1, 268435456.0), mix(Ah@1, Al@1, 4.0), mix(Ah@1, Al@1, 128.0), 0),
                T2l = (S0l + bits32(Al@1, Bl@1, Cl@1, 2)),
                T2h = (S0h + bits32(Ah@1, Bh@1, Ch@1, 2)),
                Hh@2 = Gh@1,
                Hl@2 = Gl@1,
                Gh@2 = Fh@1,
                Gl@2 = Fl@1,
                Fh@2 = Eh@1,
                Fl@2 = El@1,
                El2 = (Dl@1 + T1lw),
                Eh@2 = wrap32(((Dh@1 + T1h) + math:floor(((El2 / 4294967296.0))))),
                El@2 = wrap32(El2),
                Dh@2 = Ch@1,
                Dl@2 = Cl@1,
                Ch@2 = Bh@1,
                Cl@2 = Bl@1,
                Bh@2 = Ah@1,
                Bl@2 = Al@1,
                Al2 = (T1lw + T2l),
                Ah@2 = wrap32(((T1h + T2h) + math:floor(((Al2 / 4294967296.0))))),
                Al@2 = wrap32(Al2),
                G0h = bits32(mix(W1h@1, W1l@1, 2.0), mix(W1h@1, W1l@1, 256.0), math:floor(((W1h@1 / 128.0))), 0),
                G0l = bits32(mix(W1l@1, W1h@1, 2.0), mix(W1l@1, W1h@1, 256.0), mix(W1l@1, W1h@1, 128.0), 0),
                G1h = bits32(mix(W14h@1, W14l@1, 524288.0), mix(W14l@1, W14h@1, 536870912.0), math:floor(((W14h@1 / 64.0))), 0),
                G1l = bits32(mix(W14l@1, W14h@1, 524288.0), mix(W14h@1, W14l@1, 536870912.0), mix(W14l@1, W14h@1, 64.0), 0),
                Nl = (((G1l + W9l@1) + G0l) + W0l@1),
                Nh = wrap32(((((G1h + W9h@1) + G0h) + W0h@1) + math:floor(((Nl / 4294967296.0))))),
                W0h@2 = W1h@1,
                W0l@2 = W1l@1,
                W1h@2 = W2h@1,
                W1l@2 = W2l@1,
                W2h@2 = W3h@1,
                W2l@2 = W3l@1,
                W3h@2 = W4h@1,
                W3l@2 = W4l@1,
                W4h@2 = W5h@1,
                W4l@2 = W5l@1,
                W5h@2 = W6h@1,
                W5l@2 = W6l@1,
                W6h@2 = W7h@1,
                W6l@2 = W7l@1,
                W7h@2 = W8h@1,
                W7l@2 = W8l@1,
                W8h@2 = W9h@1,
                W8l@2 = W9l@1,
                W9h@2 = W10h@1,
                W9l@2 = W10l@1,
                W10h@2 = W11h@1,
                W10l@2 = W11l@1,
                W11h@2 = W12h@1,
                W11l@2 = W12l@1,
                W12h@2 = W13h@1,
                W12l@2 = W13l@1,
                W13h@2 = W14h@1,
                W13l@2 = W14l@1,
                W14h@2 = W15h@1,
                W14l@2 = W15l@1,
                W15h@2 = Nh,
                W15l@2 = wrap32(Nl),
                T@2 = '__bp_int'((T@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/hash.bp:1386:15">>),
                __BpLoop({Hh@2, Hl@2, Gh@2, Gl@2, Fh@2, Fl@2, Eh@2, El@2, Dh@2, Dl@2, Ch@2, Cl@2, Bh@2, Bl@2, Ah@2, Al@2, W0h@2, W0l@2, W1h@2, W1l@2, W2h@2, W2l@2, W3h@2, W3l@2, W4h@2, W4l@2, W5h@2, W5l@2, W6h@2, W6l@2, W7h@2, W7l@2, W8h@2, W8l@2, W9h@2, W9l@2, W10h@2, W10l@2, W11h@2, W11l@2, W12h@2, W12l@2, W13h@2, W13l@2, W14h@2, W14l@2, W15h@2, W15l@2, T@2});
            _ -> {Hh@1, Hl@1, Gh@1, Gl@1, Fh@1, Fl@1, Eh@1, El@1, Dh@1, Dl@1, Ch@1, Cl@1, Bh@1, Bl@1, Ah@1, Al@1, W0h@1, W0l@1, W1h@1, W1l@1, W2h@1, W2l@1, W3h@1, W3l@1, W4h@1, W4l@1, W5h@1, W5l@1, W6h@1, W6l@1, W7h@1, W7l@1, W8h@1, W8l@1, W9h@1, W9l@1, W10h@1, W10l@1, W11h@1, W11l@1, W12h@1, W12l@1, W13h@1, W13l@1, W14h@1, W14l@1, W15h@1, W15l@1, T@1}
        end
    end)({Hh, Hl, Gh, Gl, Fh, Fl, Eh, El, Dh, Dl, Ch, Cl, Bh, Bl, Ah, Al, W0h, W0l, W1h, W1l, W2h, W2l, W3h, W3l, W4h, W4l, W5h, W5l, W6h, W6l, W7h, W7l, W8h, W8l, W9h, W9l, W10h, W10l, W11h, W11l, W12h, W12l, W13h, W13l, W14h, W14l, W15h, W15l, T}),
    N0l = (wordOf(H, 1) + Al@3),
    N0h = wrap32(((wordOf(H, 0) + Ah@3) + math:floor(((N0l / 4294967296.0))))),
    N0lw = wrap32(N0l),
    N1l = (wordOf(H, 3) + Bl@3),
    N1h = wrap32(((wordOf(H, 2) + Bh@3) + math:floor(((N1l / 4294967296.0))))),
    N1lw = wrap32(N1l),
    N2l = (wordOf(H, 5) + Cl@3),
    N2h = wrap32(((wordOf(H, 4) + Ch@3) + math:floor(((N2l / 4294967296.0))))),
    N2lw = wrap32(N2l),
    N3l = (wordOf(H, 7) + Dl@3),
    N3h = wrap32(((wordOf(H, 6) + Dh@3) + math:floor(((N3l / 4294967296.0))))),
    N3lw = wrap32(N3l),
    N4l = (wordOf(H, 9) + El@3),
    N4h = wrap32(((wordOf(H, 8) + Eh@3) + math:floor(((N4l / 4294967296.0))))),
    N4lw = wrap32(N4l),
    N5l = (wordOf(H, 11) + Fl@3),
    N5h = wrap32(((wordOf(H, 10) + Fh@3) + math:floor(((N5l / 4294967296.0))))),
    N5lw = wrap32(N5l),
    N6l = (wordOf(H, 13) + Gl@3),
    N6h = wrap32(((wordOf(H, 12) + Gh@3) + math:floor(((N6l / 4294967296.0))))),
    N6lw = wrap32(N6l),
    N7l = (wordOf(H, 15) + Hl@3),
    N7h = wrap32(((wordOf(H, 14) + Hh@3) + math:floor(((N7l / 4294967296.0))))),
    N7lw = wrap32(N7l),
    [upperHalf(N0h), lowerHalf(N0h), upperHalf(N0lw), lowerHalf(N0lw), upperHalf(N1h), lowerHalf(N1h), upperHalf(N1lw), lowerHalf(N1lw), upperHalf(N2h), lowerHalf(N2h), upperHalf(N2lw), lowerHalf(N2lw), upperHalf(N3h), lowerHalf(N3h), upperHalf(N3lw), lowerHalf(N3lw), upperHalf(N4h), lowerHalf(N4h), upperHalf(N4lw), lowerHalf(N4lw), upperHalf(N5h), lowerHalf(N5h), upperHalf(N5lw), lowerHalf(N5lw), upperHalf(N6h), lowerHalf(N6h), upperHalf(N6lw), lowerHalf(N6lw), upperHalf(N7h), lowerHalf(N7h), upperHalf(N7lw), lowerHalf(N7lw)].

% ── constants, as the hex the standards print ──

% One literal each, read in place (`hexValue` at `9 · i`, or `17 · i` for a

% 64-bit word), so a digest allocates none of its tables.

% FIPS 180-4 §5.3.3: the square roots of the first 8 primes.

sha256Initial() ->
    <<"6a09e667 bb67ae85 3c6ef372 a54ff53a 510e527f 9b05688c 1f83d9ab 5be0cd19">>.

% FIPS 180-4 §4.2.2: the cube roots of the first 64 primes.

sha256Constants() ->
    <<"428a2f98 71374491 b5c0fbcf e9b5dba5 3956c25b 59f111f1 923f82a4 ab1c5ed5 d807aa98 12835b01 243185be 550c7dc3 72be5d74 80deb1fe 9bdc06a7 c19bf174 e49b69c1 efbe4786 0fc19dc6 240ca1cc 2de92c6f 4a7484aa 5cb0a9dc 76f988da 983e5152 a831c66d b00327c8 bf597fc7 c6e00bf3 d5a79147 06ca6351 14292967 27b70a85 2e1b2138 4d2c6dfc 53380d13 650a7354 766a0abb 81c2c92e 92722c85 a2bfe8a1 a81a664b c24b8b70 c76c51a3 d192e819 d6990624 f40e3585 106aa070 19a4c116 1e376c08 2748774c 34b0bcb5 391c0cb3 4ed8aa4a 5b9cca4f 682e6ff3 748f82ee 78a5636f 84c87814 8cc70208 90befffa a4506ceb bef9a3f7 c67178f2">>.

% FIPS 180-4 §5.3.5: the square roots of the first 8 primes, 64 bits.

sha512Initial() ->
    <<"6a09e667f3bcc908 bb67ae8584caa73b 3c6ef372fe94f82b a54ff53a5f1d36f1 510e527fade682d1 9b05688c2b3e6c1f 1f83d9abfb41bd6b 5be0cd19137e2179">>.

% FIPS 180-4 §4.2.3: the cube roots of the first 80 primes, 64 bits.

sha512Constants() ->
    <<"428a2f98d728ae22 7137449123ef65cd b5c0fbcfec4d3b2f e9b5dba58189dbbc 3956c25bf348b538 59f111f1b605d019 923f82a4af194f9b ab1c5ed5da6d8118 d807aa98a3030242 12835b0145706fbe 243185be4ee4b28c 550c7dc3d5ffb4e2 72be5d74f27b896f 80deb1fe3b1696b1 9bdc06a725c71235 c19bf174cf692694 e49b69c19ef14ad2 efbe4786384f25e3 0fc19dc68b8cd5b5 240ca1cc77ac9c65 2de92c6f592b0275 4a7484aa6ea6e483 5cb0a9dcbd41fbd4 76f988da831153b5 983e5152ee66dfab a831c66d2db43210 b00327c898fb213f bf597fc7beef0ee4 c6e00bf33da88fc2 d5a79147930aa725 06ca6351e003826f 142929670a0e6e70 27b70a8546d22ffc 2e1b21385c26c926 4d2c6dfc5ac42aed 53380d139d95b3df 650a73548baf63de 766a0abb3c77b2a8 81c2c92e47edaee6 92722c851482353b a2bfe8a14cf10364 a81a664bbc423001 c24b8b70d0f89791 c76c51a30654be30 d192e819d6ef5218 d69906245565a910 f40e35855771202a 106aa07032bbd1b8 19a4c116b8d2d0c8 1e376c085141ab53 2748774cdf8eeb99 34b0bcb5e19b48a8 391c0cb3c5c95a63 4ed8aa4ae3418acb 5b9cca4f7763e373 682e6ff3d6b2b8a3 748f82ee5defb2fc 78a5636f43172f60 84c87814a1f0ab72 8cc702081a6439ec 90befffa23631e28 a4506cebde82bde9 bef9a3f7b2c67915 c67178f2e372532b ca273eceea26619c d186b8c721c0c207 eada7dd6cde0eb1e f57d4f7fee6ed178 06f067aa72176fba 0a637dc5a2c898a6 113f9804bef90dae 1b710b35131c471b 28db77f523047d84 32caab7b40c72493 3c9ebe0a15c9bebc 431d67c49c100d4c 4cc5d4becb3e42b6 597f299cfc657e2a 5fcb6fab3ad6faec 6c44198c4a475817">>.

% RFC 1321 §3.4: floor(2^32 · |sin(i + 1)|).

md5Constants() ->
    <<"d76aa478 e8c7b756 242070db c1bdceee f57c0faf 4787c62a a8304613 fd469501 698098d8 8b44f7af ffff5bb1 895cd7be 6b901122 fd987193 a679438e 49b40821 f61e2562 c040b340 265e5a51 e9b6c7aa d62f105d 02441453 d8a1e681 e7d3fbc8 21e1cde6 c33707d6 f4d50d87 455a14ed a9e3e905 fcefa3f8 676f02d9 8d2a4c8a fffa3942 8771f681 6d9d6122 fde5380c a4beea44 4bdecfa9 f6bb4b60 bebfbc70 289b7ec6 eaa127fa d4ef3085 04881d05 d9d4d039 e6db99e5 1fa27cf8 c4ac5665 f4292244 432aff97 ab9423a7 fc93a039 655b59c3 8f0ccc92 ffeff47d 85845dd1 6fa87e4f fe2ce6e0 a3014314 4e0811a1 f7537e82 bd3af235 2ad7d2bb eb86d391">>.

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

array_flatten(Self) ->
    Out = lists:foldl(fun(Inner, Out) ->
        '__bp_prim_append'(Out, Inner)
    end, [], Self),
    Out.

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

-compile({inline,['__bp_nz'/2]}).
'__bp_nz'(B, What) when B == 0 -> erlang:error({panic, What});
'__bp_nz'(B, _) -> B.

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

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

'__bp_priv__panicText'(A0) -> panicText(A0).

'__bp_priv__frame'(A0) -> frame(A0).

'__bp_priv__sha256Body'(A0) -> sha256Body(A0).

'__bp_priv__sha256Base64UrlBody'(A0) -> sha256Base64UrlBody(A0).

'__bp_priv__strongHashBody'(A0) -> strongHashBody(A0).

'__bp_priv__sha512Body'(A0) -> sha512Body(A0).

'__bp_priv__md5Body'(A0) -> md5Body(A0).

'__bp_priv__sha1Base64Body'(A0) -> sha1Base64Body(A0).

'__bp_priv__hmacSha256Body'(A0, A1) -> hmacSha256Body(A0, A1).

'__bp_priv__hmacSha256Base64UrlBody'(A0, A1) -> hmacSha256Base64UrlBody(A0, A1).

'__bp_priv__equalsConstantTimeBody'(A0, A1) -> equalsConstantTimeBody(A0, A1).

'__bp_priv__pbkdf2DeriveBody'(A0, A1, A2, A3) -> pbkdf2DeriveBody(A0, A1, A2, A3).

'__bp_priv__utf8Of'(A0) -> utf8Of(A0).

'__bp_priv__utf8Bytes'(A0) -> utf8Bytes(A0).

'__bp_priv__hexDigit'(A0) -> hexDigit(A0).

'__bp_priv__hexOf'(A0) -> hexOf(A0).

'__bp_priv__base64Of'(A0, A1, A2) -> base64Of(A0, A1, A2).

'__bp_priv__base64Group'(A0, A1, A2, A3) -> base64Group(A0, A1, A2, A3).

'__bp_priv__zeroBytes'(A0) -> zeroBytes(A0).

'__bp_priv__xorByte'(A0, A1) -> xorByte(A0, A1).

'__bp_priv__xorBytes'(A0, A1) -> xorBytes(A0, A1).

'__bp_priv__wrap32'(A0) -> wrap32(A0).

'__bp_priv__rotr32'(A0, A1) -> rotr32(A0, A1).

'__bp_priv__mix'(A0, A1, A2) -> mix(A0, A1, A2).

'__bp_priv__bits32'(A0, A1, A2, A3) -> bits32(A0, A1, A2, A3).

'__bp_priv__smallInt'(A0) -> smallInt(A0).

'__bp_priv__upperHalf'(A0) -> upperHalf(A0).

'__bp_priv__lowerHalf'(A0) -> lowerHalf(A0).

'__bp_priv__wordOf'(A0, A1) -> wordOf(A0, A1).

'__bp_priv__wordBE'(A0, A1) -> wordBE(A0, A1).

'__bp_priv__wordLE'(A0, A1) -> wordLE(A0, A1).

'__bp_priv__hexValue'(A0, A1, A2) -> hexValue(A0, A1, A2).

'__bp_priv__halvesOf'(A0, A1) -> halvesOf(A0, A1).

'__bp_priv__bytesBE'(A0) -> bytesBE(A0).

'__bp_priv__bytesLE'(A0) -> bytesLE(A0).

'__bp_priv__padded'(A0, A1, A2, A3) -> padded(A0, A1, A2, A3).

'__bp_priv__hmacKeyBlock'(A0) -> hmacKeyBlock(A0).

'__bp_priv__hmacSha256Bytes'(A0, A1) -> hmacSha256Bytes(A0, A1).

'__bp_priv__padOf'(A0, A1) -> padOf(A0, A1).

'__bp_priv__hmacWithPads'(A0, A1, A2) -> hmacWithPads(A0, A1, A2).

'__bp_priv__sha256Bytes'(A0) -> sha256Bytes(A0).

'__bp_priv__sha256Block'(A0, A1, A2, A3) -> sha256Block(A0, A1, A2, A3).

'__bp_priv__sha1Bytes'(A0) -> sha1Bytes(A0).

'__bp_priv__sha1Block'(A0, A1, A2) -> sha1Block(A0, A1, A2).

'__bp_priv__md5Bytes'(A0) -> md5Bytes(A0).

'__bp_priv__md5Block'(A0, A1, A2, A3, A4) -> md5Block(A0, A1, A2, A3, A4).

'__bp_priv__sha512Bytes'(A0) -> sha512Bytes(A0).

'__bp_priv__sha512Block'(A0, A1, A2, A3) -> sha512Block(A0, A1, A2, A3).

'__bp_priv__sha256Initial'() -> sha256Initial().

'__bp_priv__sha256Constants'() -> sha256Constants().

'__bp_priv__sha512Initial'() -> sha512Initial().

'__bp_priv__sha512Constants'() -> sha512Constants().

'__bp_priv__md5Constants'() -> md5Constants().

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).

'__bp_priv__array_flatten'(A0) -> array_flatten(A0).
