-module(std@encoding).
-export([base64Decode/1, base64UrlEncode/1, base64UrlDecode/1, hexDecode/1, base64DecodeBytes/1, hexDecodeBytes/1, percentDecode/1, formStringify/1, formParse/1, base64Encode/1, hexEncode/1, base64EncodeBytes/1, hexEncodeBytes/1, percentEncode/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__padToMultipleOfFour'/1, '__bp_priv__formField'/1, '__bp_priv__formDecode'/1, '__bp_priv__base64EncodeBody'/1, '__bp_priv__refused'/1, '__bp_priv__base64DecodeBody'/1, '__bp_priv__hexEncodeBody'/1, '__bp_priv__hexDecodeBody'/1, '__bp_priv__percentEncodeBody'/1, '__bp_priv__percentDecodeBody'/1, '__bp_priv__escapedByte'/2, '__bp_priv__isUnreserved'/1, '__bp_priv__utf8Of'/1, '__bp_priv__utf8Bytes'/1, '__bp_priv__textOfUtf8'/1, '__bp_priv__base64Text'/1, '__bp_priv__base64Value'/1, '__bp_priv__hexDigit'/1, '__bp_priv__upperHexDigit'/1, '__bp_priv__hexValue'/1, '__bp_priv__string_slice'/3, '__bp_priv__array_flatten'/1]).

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

%%% std/encoding — the wire formats: base64, base64url, hex, percent

%%% encoding and the percent-aware form codec, cross-backend.

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/buffer.html (`Buffer.from(s, 'utf8').toString('base64' | 'base64url' | 'hex')`)

%%%              https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent

%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/base64.html

%%%              https://www.erlang.org/doc/apps/stdlib/binary.html (`encode_hex/1`, `decode_hex/1`)

%%%              https://www.erlang.org/doc/apps/stdlib/uri_string.html (`quote/1`, `unquote/1`)

%%%   RFC 4648 (base64, base64url), RFC 3986 §2.1 (percent-encoding)

%%% 

%%% One import for the whole wire-format surface. Every encoder answers a

%%% string; every decoder that can meet malformed input answers

%%% `Result<…, EncodingError>` (decision 486): the host cell writes

%%% `result: true` (decisions 431, 490) and answers `Result<…, HostError>`,

%%% and the public function maps it — nothing here returns a sentinel. The text

%%% codecs read and write the UTF-8 bytes of a `string`: `base64Decode` and

%%% `hexDecode` answer the bytes read back as UTF-8 (a non-UTF-8 payload is

%%% lossy). Bytes cross losslessly through the `Bytes` bridges

%%% (decision 346): `base64EncodeBytes` / `base64DecodeBytes` and

%%% `hexEncodeBytes` / `hexDecodeBytes`.

%%% 

%%% Was also `base64` (decision 106): its `encode`/`decode`/`encodeUrlSafe`/

%%% `decodeUrlSafe` are `base64Encode`/`base64Decode`/`base64UrlEncode`/

%%% `base64UrlDecode` here, and its four tests sit at the foot of this file.

%% import HostError, HostErrorName

% What a decoder refuses (decision 486): the text is not in the codec's form.

%% type EncodingError
%%   NotBase64
%%   NotHex
%%   NotPercentEncoded

% Standard base64 (RFC 4648 §4) of the UTF-8 bytes of `s`, with `=` padding.

%% external fn base64Encode -> erlang template
base64Encode(S) ->
    base64:encode(S).

% The inverse of `base64Encode`. Malformed input is an `Error`: Node's

% `Buffer.from(_, 'base64')` silently drops what it cannot read, so the

% template re-encodes and compares to detect it; Erlang's `base64:decode/1`

% raises, and the template catches.

%% external fn base64DecodeHost -> erlang template

base64Decode(B) ->
    case (fun(__BpA0) -> try (base64:decode(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(B) of
        {ok, V} ->
            {ok, V};
        {error, _} ->
            {error, std@encoding@@EncodingError__v__notbase64}
    end.

% base64url (RFC 4648 §5): the `-_` alphabet, no `=` padding — the form

% JWS/JWT (RFC 7515) and `random.secureToken` use. Pure over `base64Encode`,

% with `replaceAll` (not `replace`, which stops at the first occurrence).

base64UrlEncode(S) ->
    Raw = base64:encode(S),
    NoPlus = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Raw, <<"+">>, <<"-">>),
    NoSlash = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(NoPlus, <<"/">>, <<"_">>),
    (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(NoSlash, <<"=">>, <<"">>).

% The inverse of `base64UrlEncode`: restore the `+/` alphabet, re-pad to a

% multiple of four, decode.

base64UrlDecode(B) ->
    NoDash = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(B, <<"-">>, <<"+">>),
    NoUnder = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(NoDash, <<"_">>, <<"/">>),
    Padded = padToMultipleOfFour(NoUnder),
    base64Decode(Padded).

% Internal: append `=` until the length is a multiple of four. Tail-recursive;

% at most three steps.

padToMultipleOfFour(S) ->
    Remainder = (erlang:length(unicode:characters_to_list(S)) rem 4),
    case (Remainder =:= 0) of
        true ->
            S;
        false ->
            padToMultipleOfFour(iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [S, <<"=">>]))))
    end.

% Lowercase hex of the UTF-8 bytes of `s`: `"hi"` → `6869`.

%% external fn hexEncode -> erlang template
hexEncode(S) ->
    string:lowercase(binary:encode_hex(S)).

% The inverse of `hexEncode`, either case. An odd length or a non-hex digit

% is an `Error` (Node's `Buffer.from(_, 'hex')` truncates silently at the

% first bad digit, so the template validates first; Erlang's

% `binary:decode_hex/1` raises `badarg`, caught).

%% external fn hexDecodeHost -> erlang template

hexDecode(S) ->
    case (fun(__BpA0) -> try (binary:decode_hex(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(S) of
        {ok, V} ->
            {ok, V};
        {error, _} ->
            {error, std@encoding@@EncodingError__v__nothex}
    end.

% ── the `bytes` bridges (decision 346) ───────────────────────────────────────

% The codecs above over `bytes`, lossless: an encoder answers the text of the

% bytes as they are, a decoder the bytes the text spells — with the text

% codecs' rules (the Node cell's base64: trailing `=` optional, no length of

% the form 4k + 1, zero bits after the last whole byte; hex either case, an

% even length) and their `Error` texts. On wasm and at comptime std-wasm

% answers (`encoding.zig`); a decoder's cell answers `?bytes`, absent for text

% that is not one, and the public function makes it the `Error`.

% Standard base64 (RFC 4648 §4) of `b`, with `=` padding.

%% external fn base64EncodeBytes -> erlang template
base64EncodeBytes(B) ->
    base64:encode(B).

% The bytes the base64 text `s` spells; anything `base64Decode` refuses is

% the same `Error`.

base64DecodeBytes(S) ->
    B = (fun(__S) -> __T = string:trim(__S, trailing, [61]), __N = byte_size(__T), case (__N rem 4 =/= 1) andalso lists:all(fun(__C) -> ((__C >= 65) andalso (__C =< 90)) orelse ((__C >= 97) andalso (__C =< 122)) orelse ((__C >= 48) andalso (__C =< 57)) orelse (__C =:= 43) orelse (__C =:= 47) end, binary_to_list(__T)) of false -> undefined; true -> __P = <<__T/binary, (binary:copy(<<61>>, (4 - __N rem 4) rem 4))/binary>>, __B = base64:decode(__P), case base64:encode(__B) =:= __P of true -> __B; false -> undefined end end end)(S),
    case (B =:= undefined) of
        true ->
            {error, std@encoding@@EncodingError__v__notbase64};
        _ ->
            {ok, B}
    end.

%% external fn base64BytesOf -> erlang template

% Lowercase hex of `b`: the bytes `0x68 0x69` are `6869`.

%% external fn hexEncodeBytes -> erlang template
hexEncodeBytes(B) ->
    string:lowercase(binary:encode_hex(B)).

% The bytes the hex text `s` spells, either case; an odd length or a non-hex

% digit is `hexDecode`'s `Error`.

hexDecodeBytes(S) ->
    B = (fun(__H) -> case (byte_size(__H) rem 2 =:= 0) andalso lists:all(fun(__C) -> ((__C >= 48) andalso (__C =< 57)) orelse ((__C >= 65) andalso (__C =< 70)) orelse ((__C >= 97) andalso (__C =< 102)) end, binary_to_list(__H)) of true -> binary:decode_hex(__H); false -> undefined end end)(S),
    case (B =:= undefined) of
        true ->
            {error, std@encoding@@EncodingError__v__nothex};
        _ ->
            {ok, B}
    end.

%% external fn hexBytesOf -> erlang template

% RFC 3986 percent-encoding of a component: every byte of the UTF-8 form

% outside the unreserved set `A-Z a-z 0-9 - . _ ~` becomes `%XX`, uppercase.

% `uri_string:quote/1` is exactly that; `encodeURIComponent` leaves

% `! ' ( ) *` unencoded (RFC 2396's mark set), so the Node template encodes

% those five too — the two targets answer the same bytes for the same input.

%% external fn percentEncode -> erlang template
percentEncode(S) ->
    uri_string:quote(S).

% The inverse of `percentEncode`. A `%` not followed by two hex digits, or a

% sequence that is not UTF-8, is an `Error`. `+` is left as `+` — the form

% codec below is what reads `+` as a space.

%% external fn percentDecodeHost -> erlang template

percentDecode(S) ->
    case (fun(__BpA0) -> try ((fun(__S) -> case unicode:characters_to_binary(uri_string:unquote(__S)) of __V when is_binary(__V) -> __V; _ -> erlang:error(badarg) end end)(__BpA0)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(S) of
        {ok, V} ->
            {ok, V};
        {error, _} ->
            {error, std@encoding@@EncodingError__v__notpercentencoded}
    end.

% `application/x-www-form-urlencoded`, the escaping form: each pair is

% `percentEncode(name)=percentEncode(value)`, joined with `&`.

% `querystring.stringify` writes the same text and refuses a control

% character, which this does not.

formStringify(Pairs) ->
    iolist_to_binary(lists:join(<<"&">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(P) ->
        iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [uri_string:quote(erlang:element(1, P)), <<"=">>, uri_string:quote(erlang:element(2, P))])))
    end, Pairs)))).

% The inverse of `formStringify`, percent-aware: split on `&`, each field on

% its FIRST `=` (a field with no `=` is a name with an empty value), `+` read

% as a space (the form encoding's rule), then percent-decoded. A field that

% does not decode keeps its raw text — a parse over user input must not

% throw, and a malformed pair is still a pair. Empty fields (`a=1&&b=2`)

% are dropped. `querystring.parseForm` is the refusing reader: a malformed

% escape or a control character is its `Error`, not a raw field.

formParse(Q) ->
    Fields = lists:filter(fun(F) ->
        (F =/= <<"">>)
    end, (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Q, <<"&">>)),
    lists:map(fun(F) ->
        formField(F)
    end, Fields).

% Internal: one `name=value` field into its decoded pair.

formField(F) ->
    Eq = (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(F, <<"=">>),
    RawName = case (Eq < 0) of
        true ->
            F;
        false ->
            string_slice(F, 0, Eq)
    end,
    RawValue = case (Eq < 0) of
        true ->
            <<"">>;
        false ->
            string_slice(F, '__bp_int'((Eq + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:224:51">>), erlang:length(unicode:characters_to_list(F)))
    end,
    {formDecode(RawName), formDecode(RawValue)}.

% Internal: `+` to space, then percent-decode, falling back to the raw text.

formDecode(S) ->
    Spaced = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(S, <<"+">>, <<" ">>),
    (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (Spaced) end end)(percentDecode(Spaced)).

% ── the wasm bodies (decision 238) ───────────────────────────────────────────

% wasm has no host to encode with, so each cell above names one of these

% private bodies with `#[compiler.external(.Wasm(fn: …))]`. They run only on wasm and

% answer what the Node cell answers: a string's bytes are its UTF-8, a decoded

% byte string is read back as Node's `toString('utf8')` reads it (WHATWG UTF-8:

% each maximal ill-formed subsequence one U+FFFD), and the text is built from

% code points with `string.fromCodepoint` (decision 262).

base64EncodeBody(S) ->
    base64Text(utf8Of(S)).

% What the wasm bodies refuse with: the `HostError` a host's raise would be.

refused(Message) ->
    {std@failure@@HostError, Message, <<"host">>, std@failure@@HostErrorName__v__error, undefined}.

% The Node cell's rule: strip trailing `=`, decode, and accept only what

% re-encodes to the same text — the `+/` alphabet only, no length of the form

% 4k + 1, zero bits after the last whole byte.

base64DecodeBody(B) ->
    try
        Cs = [<<__C/utf8>> || __C <- unicode:characters_to_list(B, utf8)],
        N = erlang:length(Cs),
        N@3 = (fun __BpLoop(N@1) ->
            case ((N@1 > 0) andalso ((case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, '__bp_int'((N@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:262:30">>)) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end) =:= <<"=">>)) of
                true ->
                    N@2 = '__bp_int'((N@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:263:15">>),
                    __BpLoop(N@2);
                _ -> N@1
            end
        end)(N),
        case ((N@3 rem 4) =:= 1) of
            true ->
                {error, refused(<<"not base64">>)};
            _ ->
                Sextets = [],
                I = 0,
                {Sextets@3, I@3} = (fun __BpLoop({Sextets@1, I@1}) ->
                    case (I@1 < N@3) of
                        true ->
                            V = base64Value(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, I@1) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish@1 ->
                                    __bp_nullish@1
                            end),
                            case (V < 0) of
                                true ->
                                    erlang:throw({'__bp_try', {error, refused(<<"not base64">>)}});
                                _ -> ok
                            end,
                            Sextets@2 = (Sextets@1 ++ [V]),
                            I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:272:15">>),
                            __BpLoop({Sextets@2, I@2});
                        _ -> {Sextets@1, I@1}
                    end
                end)({Sextets, I}),
                Last = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Sextets@3, '__bp_int'((N@3 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:274:29">>)) of
                    undefined ->
                        0;
                    __bp_nullish@2 ->
                        __bp_nullish@2
                end,
                case (((N@3 rem 4) =:= 2) andalso ((Last rem 16) =/= 0)) of
                    true ->
                        {error, refused(<<"not base64">>)};
                    _ ->
                        case (((N@3 rem 4) =:= 3) andalso ((Last rem 4) =/= 0)) of
                            true ->
                                {error, refused(<<"not base64">>)};
                            _ ->
                                Bytes = [],
                                G = 0,
                                {Bytes@7, G@3} = (fun __BpLoop({Bytes@1, G@1}) ->
                                    case (G@1 < N@3) of
                                        true ->
                                            S0 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Sextets@3, G@1) of
                                                undefined ->
                                                    0;
                                                __bp_nullish@3 ->
                                                    __bp_nullish@3
                                            end,
                                            S1 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Sextets@3, '__bp_int'((G@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:281:31">>)) of
                                                undefined ->
                                                    0;
                                                __bp_nullish@4 ->
                                                    __bp_nullish@4
                                            end,
                                            S2 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Sextets@3, '__bp_int'((G@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:282:31">>)) of
                                                undefined ->
                                                    0;
                                                __bp_nullish@5 ->
                                                    __bp_nullish@5
                                            end,
                                            S3 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Sextets@3, '__bp_int'((G@1 + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:283:31">>)) of
                                                undefined ->
                                                    0;
                                                __bp_nullish@6 ->
                                                    __bp_nullish@6
                                            end,
                                            Bytes@2 = (Bytes@1 ++ ['__bp_int'(('__bp_int'((S0 * 4), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:284:23">>) + '__bp_int'((S1 div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:284:32">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:284:27">>)]),
                                            Bytes@4 = case ('__bp_int'((G@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:285:15">>) < N@3) of
                                                true ->
                                                    Bytes@3 = (Bytes@2 ++ ['__bp_int'(('__bp_int'((((S1 rem 16)) * 16), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:285:45">>) + '__bp_int'((S2 div 4), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:285:55">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:285:50">>)]),
                                                    Bytes@3;
                                                _ ->
                                                    Bytes@2
                                            end,
                                            Bytes@6 = case ('__bp_int'((G@1 + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:286:15">>) < N@3) of
                                                true ->
                                                    Bytes@5 = (Bytes@4 ++ ['__bp_int'(('__bp_int'((((S2 rem 4)) * 64), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:286:44">>) + S3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:286:49">>)]),
                                                    Bytes@5;
                                                _ ->
                                                    Bytes@4
                                            end,
                                            G@2 = '__bp_int'((G@1 + 4), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:287:15">>),
                                            __BpLoop({Bytes@6, G@2});
                                        _ -> {Bytes@1, G@1}
                                    end
                                end)({Bytes, G}),
                                {ok, textOfUtf8(Bytes@7)}
                        end
                end
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

hexEncodeBody(S) ->
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(B) ->
        <<(hexDigit('__bp_int'((B div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:293:44">>)))/binary, (hexDigit((B rem 16)))/binary>>
    end, utf8Of(S))))).

hexDecodeBody(S) ->
    try
        Cs = [<<__C/utf8>> || __C <- unicode:characters_to_list(S, utf8)],
        case ((erlang:length(Cs) rem 2) =/= 0) of
            true ->
                {error, refused(<<"not hex">>)};
            _ ->
                Bytes = [],
                I = 0,
                {Bytes@3, I@3} = (fun __BpLoop({Bytes@1, I@1}) ->
                    case (I@1 < erlang:length(Cs)) of
                        true ->
                            Hi = hexValue(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, I@1) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish ->
                                    __bp_nullish
                            end),
                            Lo = hexValue(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:303:35">>)) of
                                undefined ->
                                    <<"">>;
                                __bp_nullish@1 ->
                                    __bp_nullish@1
                            end),
                            case ((Hi < 0) orelse (Lo < 0)) of
                                true ->
                                    erlang:throw({'__bp_try', {error, refused(<<"not hex">>)}});
                                _ -> ok
                            end,
                            Bytes@2 = (Bytes@1 ++ ['__bp_int'(('__bp_int'((Hi * 16), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:305:23">>) + Lo), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:305:28">>)]),
                            I@2 = '__bp_int'((I@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:306:15">>),
                            __BpLoop({Bytes@2, I@2});
                        _ -> {Bytes@1, I@1}
                    end
                end)({Bytes, I}),
                {ok, textOfUtf8(Bytes@3)}
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% `encodeURIComponent` plus the five marks the Node cell escapes too: every

% UTF-8 byte outside `A-Z a-z 0-9 - . _ ~` as `%XX`, uppercase.

percentEncodeBody(S) ->
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(C) ->
        case isUnreserved((fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(C, 0)) of
            true ->
                C;
            false ->
                iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(B) ->
                    <<"%", (upperHexDigit('__bp_int'((B div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:322:54">>)))/binary, (upperHexDigit((B rem 16)))/binary>>
                end, utf8Bytes((fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(C, 0))))))
        end
    end, [<<__C/utf8>> || __C <- unicode:characters_to_list(S, utf8)])))).

% `decodeURIComponent`: a `%` reads two hex digits; a byte below 0x80 is its

% character, a lead byte takes the continuation escapes its length says, and

% the sequence must be well-formed UTF-8 (no overlong form, no surrogate,

% nothing past U+10FFFF) — anything else is the `Error`. Other text passes.

percentDecodeBody(S) ->
    try
        Cs = [<<__C/utf8>> || __C <- unicode:characters_to_list(S, utf8)],
        Out = [],
        I = 0,
        {Out@7, I@7} = (fun __BpLoop({Out@1, I@1}) ->
            case (I@1 < erlang:length(Cs)) of
                true ->
                    C = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, I@1) of
                        undefined ->
                            <<"">>;
                        __bp_nullish ->
                            __bp_nullish
                    end,
                    {Out@6, I@6} = case (C =/= <<"%">>) of
                        true ->
                            Out@2 = (Out@1 ++ [C]),
                            I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:341:19">>),
                            {Out@2, I@2};
                        _ ->
                            B = escapedByte(Cs, I@1),
                            case (B < 0) of
                                true ->
                                    erlang:throw({'__bp_try', {error, refused(<<"not percent-encoded">>)}});
                                _ -> ok
                            end,
                            {Out@5, I@5} = case (B < 128) of
                                true ->
                                    Out@3 = (Out@1 ++ [<<(B)/utf8>>]),
                                    I@3 = '__bp_int'((I@1 + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:347:23">>),
                                    {Out@3, I@3};
                                _ ->
                                    Len = case ((B >= 192) andalso (B < 224)) of
                                        true ->
                                            2;
                                        false ->
                                            case ((B >= 224) andalso (B < 240)) of
                                                true ->
                                                    3;
                                                false ->
                                                    case ((B >= 240) andalso (B < 248)) of
                                                        true ->
                                                            4;
                                                        false ->
                                                            0
                                                    end
                                            end
                                    end,
                                    case (Len =:= 0) of
                                        true ->
                                            erlang:throw({'__bp_try', {error, refused(<<"not percent-encoded">>)}});
                                        _ -> ok
                                    end,
                                    Cp = case (Len =:= 2) of
                                        true ->
                                            '__bp_int'((B - 192), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:359:23">>);
                                        false ->
                                            case (Len =:= 3) of
                                                true ->
                                                    '__bp_int'((B - 224), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:361:23">>);
                                                false ->
                                                    '__bp_int'((B - 240), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:363:23">>)
                                            end
                                    end,
                                    K = 1,
                                    {Cp@3, K@3} = (fun __BpLoop1({Cp@1, K@1}) ->
                                        case (K@1 < Len) of
                                            true ->
                                                Cb = escapedByte(Cs, '__bp_int'((I@1 + '__bp_int'((3 * K@1), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:366:52">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:366:48">>)),
                                                case ((Cb < 128) orelse (Cb >= 192)) of
                                                    true ->
                                                        erlang:throw({'__bp_try', {error, refused(<<"not percent-encoded">>)}});
                                                    _ -> ok
                                                end,
                                                Cp@2 = '__bp_int'(('__bp_int'((Cp@1 * 64), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:369:29">>) + ('__bp_int'((Cb - 128), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:369:40">>))), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:369:34">>),
                                                K@2 = '__bp_int'((K@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:370:27">>),
                                                __BpLoop1({Cp@2, K@2});
                                            _ -> {Cp@1, K@1}
                                        end
                                    end)({Cp, K}),
                                    Least = case (Len =:= 2) of
                                        true ->
                                            128;
                                        false ->
                                            case (Len =:= 3) of
                                                true ->
                                                    2048;
                                                false ->
                                                    65536
                                            end
                                    end,
                                    case (((Cp@3 < Least) orelse (Cp@3 > 1114111)) orelse (((Cp@3 >= 55296) andalso (Cp@3 =< 57343)))) of
                                        true ->
                                            erlang:throw({'__bp_try', {error, refused(<<"not percent-encoded">>)}});
                                        _ -> ok
                                    end,
                                    Out@4 = (Out@1 ++ [<<(Cp@3)/utf8>>]),
                                    I@4 = '__bp_int'((I@1 + '__bp_int'((3 * Len), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:381:27">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:381:23">>),
                                    {Out@4, I@4}
                            end,
                            {Out@5, I@5}
                    end,
                    __BpLoop({Out@6, I@6});
                _ -> {Out@1, I@1}
            end
        end)({Out, I}),
        {ok, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Out@7)))}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The byte `%XX` at index `i` spells, or -1 when `i` holds no `%` followed by

% two hex digits.

escapedByte(Cs, I) ->
    case (case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, I) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end =/= <<"%">>) of
        true ->
            (-1);
        _ ->
            Hi = hexValue(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:392:31">>)) of
                undefined ->
                    <<"">>;
                __bp_nullish@1 ->
                    __bp_nullish@1
            end),
            Lo = hexValue(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:393:31">>)) of
                undefined ->
                    <<"">>;
                __bp_nullish@2 ->
                    __bp_nullish@2
            end),
            case ((Hi < 0) orelse (Lo < 0)) of
                true ->
                    (-1);
                _ ->
                    '__bp_int'(('__bp_int'((Hi * 16), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:395:15">>) + Lo), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:395:20">>)
            end
    end.

isUnreserved(Cp) ->
    (((((((((Cp >= 65) andalso (Cp =< 90))) orelse (((Cp >= 97) andalso (Cp =< 122)))) orelse (((Cp >= 48) andalso (Cp =< 57)))) orelse (Cp =:= 45)) orelse (Cp =:= 46)) orelse (Cp =:= 95)) orelse (Cp =:= 126)).

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
                    ['__bp_int'((192 + '__bp_int'((Cp div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:421:37">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:421:32">>), '__bp_int'((128 + (Cp rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:421:47">>)];
                _ ->
                    case (Cp < 65536) of
                        true ->
                            ['__bp_int'((224 + '__bp_int'((Cp div 4096), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:423:26">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:423:21">>), '__bp_int'((128 + (('__bp_int'((Cp div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:423:44">>)) rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:423:38">>), '__bp_int'((128 + (Cp rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:423:60">>)];
                        _ ->
                            ['__bp_int'((240 + '__bp_int'((Cp div 262144), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:425:18">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:425:13">>), '__bp_int'((128 + (('__bp_int'((Cp div 4096), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:426:19">>)) rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:426:13">>), '__bp_int'((128 + (('__bp_int'((Cp div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:427:19">>)) rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:427:13">>), '__bp_int'((128 + (Cp rem 64)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:428:13">>)]
                    end
            end
    end.

% `bytes` read as UTF-8 the way the WHATWG decoder (and so Node's

% `toString('utf8')`) reads them: a byte that cannot start a sequence, a

% sequence cut short, an overlong or surrogate form, and a sequence past

% U+10FFFF each answer U+FFFD for their maximal ill-formed subsequence.

textOfUtf8(Bytes) ->
    Out = [],
    Need = 0,
    Seen = 0,
    Cp = 0,
    Lower = 128,
    Upper = 191,
    I = 0,
    {Out@13, Need@14, Cp@15, Lower@14, Upper@14, I@6, Seen@8} = (fun __BpLoop({Out@1, Need@1, Cp@1, Lower@1, Upper@1, I@1, Seen@1}) ->
        case (I@1 < erlang:length(Bytes)) of
            true ->
                B = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, I@1) of
                    undefined ->
                        0;
                    __bp_nullish ->
                        __bp_nullish
                end,
                {Out@12, Need@13, Cp@14, Lower@13, Upper@13, I@5, Seen@7} = case (Need@1 =:= 0) of
                    true ->
                        {Out@7, Need@8, Cp@8, Lower@9, Upper@9} = case (B < 128) of
                            true ->
                                Out@2 = (Out@1 ++ [<<(B)/utf8>>]),
                                {Out@2, Need@1, Cp@1, Lower@1, Upper@1};
                            _ ->
                                {Need@7, Cp@7, Lower@8, Upper@8, Out@6} = case ((B >= 194) andalso (B =< 223)) of
                                    true ->
                                        Need@2 = 1,
                                        Cp@2 = '__bp_int'((B - 192), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:450:24">>),
                                        {Need@2, Cp@2, Lower@1, Upper@1, Out@1};
                                    _ ->
                                        {Lower@7, Upper@7, Need@6, Cp@6, Out@5} = case ((B >= 224) andalso (B =< 239)) of
                                            true ->
                                                Lower@3 = case (B =:= 224) of
                                                    true ->
                                                        Lower@2 = 160,
                                                        Lower@2;
                                                    _ ->
                                                        Lower@1
                                                end,
                                                Upper@3 = case (B =:= 237) of
                                                    true ->
                                                        Upper@2 = 159,
                                                        Upper@2;
                                                    _ ->
                                                        Upper@1
                                                end,
                                                Need@3 = 2,
                                                Cp@3 = '__bp_int'((B - 224), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:455:24">>),
                                                {Lower@3, Upper@3, Need@3, Cp@3, Out@1};
                                            _ ->
                                                {Lower@6, Upper@6, Need@5, Cp@5, Out@4} = case ((B >= 240) andalso (B =< 244)) of
                                                    true ->
                                                        Lower@5 = case (B =:= 240) of
                                                            true ->
                                                                Lower@4 = 144,
                                                                Lower@4;
                                                            _ ->
                                                                Lower@1
                                                        end,
                                                        Upper@5 = case (B =:= 244) of
                                                            true ->
                                                                Upper@4 = 143,
                                                                Upper@4;
                                                            _ ->
                                                                Upper@1
                                                        end,
                                                        Need@4 = 3,
                                                        Cp@4 = '__bp_int'((B - 240), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:460:24">>),
                                                        {Lower@5, Upper@5, Need@4, Cp@4, Out@1};
                                                    _ ->
                                                        Out@3 = (Out@1 ++ [<<(65533)/utf8>>]),
                                                        {Lower@1, Upper@1, Need@1, Cp@1, Out@3}
                                                end,
                                                {Lower@6, Upper@6, Need@5, Cp@5, Out@4}
                                        end,
                                        {Need@6, Cp@6, Lower@7, Upper@7, Out@5}
                                end,
                                {Out@6, Need@7, Cp@7, Lower@8, Upper@8}
                        end,
                        I@2 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:462:19">>),
                        {Out@7, Need@8, Cp@8, Lower@9, Upper@9, I@2, Seen@1};
                    _ ->
                        {Need@12, Seen@6, Cp@13, Lower@12, Upper@12, Out@11, I@4} = case ((B < Lower@1) orelse (B > Upper@1)) of
                            true ->
                                Need@9 = 0,
                                Seen@2 = 0,
                                Cp@9 = 0,
                                Lower@10 = 128,
                                Upper@10 = 191,
                                Out@8 = (Out@1 ++ [<<(65533)/utf8>>]),
                                {Need@9, Seen@2, Cp@9, Lower@10, Upper@10, Out@8, I@1};
                            _ ->
                                Lower@11 = 128,
                                Upper@11 = 191,
                                Cp@10 = '__bp_int'(('__bp_int'((Cp@1 * 64), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:473:21">>) + ('__bp_int'((B - 128), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:473:31">>))), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:473:26">>),
                                Seen@3 = '__bp_int'((Seen@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:474:25">>),
                                {Out@10, Need@11, Seen@5, Cp@12} = case (Seen@3 =:= Need@1) of
                                    true ->
                                        Out@9 = (Out@1 ++ [<<(Cp@10)/utf8>>]),
                                        Need@10 = 0,
                                        Seen@4 = 0,
                                        Cp@11 = 0,
                                        {Out@9, Need@10, Seen@4, Cp@11};
                                    _ ->
                                        {Out@1, Need@1, Seen@3, Cp@10}
                                end,
                                I@3 = '__bp_int'((I@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:481:19">>),
                                {Need@11, Seen@5, Cp@12, Lower@11, Upper@11, Out@10, I@3}
                        end,
                        {Out@11, Need@12, Cp@13, Lower@12, Upper@12, I@4, Seen@6}
                end,
                __BpLoop({Out@12, Need@13, Cp@14, Lower@13, Upper@13, I@5, Seen@7});
            _ -> {Out@1, Need@1, Cp@1, Lower@1, Upper@1, I@1, Seen@1}
        end
    end)({Out, Need, Cp, Lower, Upper, I, Seen}),
    Out@15 = case (Need@14 =/= 0) of
        true ->
            Out@14 = (Out@13 ++ [<<(65533)/utf8>>]),
            Out@14;
        _ ->
            Out@13
    end,
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Out@15))).

base64Text(Bytes) ->
    Alphabet = <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/">>,
    Out = [],
    G = 0,
    {Out@6, G@3} = (fun __BpLoop({Out@1, G@1}) ->
        case (G@1 < erlang:length(Bytes)) of
            true ->
                N = '__bp_int'((erlang:length(Bytes) - G@1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/encoding.bp:493:30">>),
                B0 = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, G@1) of
                    undefined ->
                        0;
                    __bp_nullish ->
                        __bp_nullish
                end,
                B1 = case (N > 1) of
                    true ->
                        case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'((G@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:496:24">>)) of
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
                        case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bytes, '__bp_int'((G@1 + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:499:24">>)) of
                            undefined ->
                                0;
                            __bp_nullish@2 ->
                                __bp_nullish@2
                        end;
                    false ->
                        0
                end,
                Out@2 = (Out@1 ++ [case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'((B0 div 4), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:501:33">>)) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@3 ->
                        __bp_nullish@3
                end]),
                Out@3 = (Out@2 ++ [case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'(('__bp_int'((((B0 rem 4)) * 16), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:502:39">>) + '__bp_int'((B1 div 16), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:502:49">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:502:44">>)) of
                    undefined ->
                        <<"">>;
                    __bp_nullish@4 ->
                        __bp_nullish@4
                end]),
                Out@4 = (Out@3 ++ [case (N > 1) of
                    true ->
                        case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, '__bp_int'(('__bp_int'((((B1 rem 16)) * 4), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/encoding.bp:505:39">>) + '__bp_int'((B2 div 64), -2147483648, 2147483647, <<"integer overflow: / on i32 at src/encoding.bp:505:48">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:505:43">>)) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@5 ->
                                __bp_nullish@5
                        end;
                    false ->
                        <<"=">>
                end]),
                Out@5 = (Out@4 ++ [case (N > 2) of
                    true ->
                        case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(Alphabet, (B2 rem 64)) of
                            undefined ->
                                <<"">>;
                            __bp_nullish@6 ->
                                __bp_nullish@6
                        end;
                    false ->
                        <<"=">>
                end]),
                G@2 = '__bp_int'((G@1 + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/encoding.bp:513:15">>),
                __BpLoop({Out@5, G@2});
            _ -> {Out@1, G@1}
        end
    end)({Out, G}),
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Out@6))).

% The value of one character of the `+/` alphabet, or -1.

base64Value(C) ->
    case (C =:= <<"">>) of
        true ->
            (-1);
        _ ->
            (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(<<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/">>, C)
    end.

hexDigit(N) ->
    case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(<<"0123456789abcdef">>, N) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end.

upperHexDigit(N) ->
    case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(<<"0123456789ABCDEF">>, N) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end.

% The value of one hex digit, either case, or -1.

hexValue(C) ->
    case (C =:= <<"">>) of
        true ->
            (-1);
        _ ->
            LowerAt = (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(<<"0123456789abcdef">>, C),
            case (LowerAt >= 0) of
                true ->
                    LowerAt;
                _ ->
                    (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(<<"0123456789ABCDEF">>, C)
            end
    end.

% ── tests ────────────────────────────────────────────────────────────────────











% ── the tests of the retired `base64` module, over the names that replaced it ──





string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
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

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__padToMultipleOfFour'(A0) -> padToMultipleOfFour(A0).

'__bp_priv__formField'(A0) -> formField(A0).

'__bp_priv__formDecode'(A0) -> formDecode(A0).

'__bp_priv__base64EncodeBody'(A0) -> base64EncodeBody(A0).

'__bp_priv__refused'(A0) -> refused(A0).

'__bp_priv__base64DecodeBody'(A0) -> base64DecodeBody(A0).

'__bp_priv__hexEncodeBody'(A0) -> hexEncodeBody(A0).

'__bp_priv__hexDecodeBody'(A0) -> hexDecodeBody(A0).

'__bp_priv__percentEncodeBody'(A0) -> percentEncodeBody(A0).

'__bp_priv__percentDecodeBody'(A0) -> percentDecodeBody(A0).

'__bp_priv__escapedByte'(A0, A1) -> escapedByte(A0, A1).

'__bp_priv__isUnreserved'(A0) -> isUnreserved(A0).

'__bp_priv__utf8Of'(A0) -> utf8Of(A0).

'__bp_priv__utf8Bytes'(A0) -> utf8Bytes(A0).

'__bp_priv__textOfUtf8'(A0) -> textOfUtf8(A0).

'__bp_priv__base64Text'(A0) -> base64Text(A0).

'__bp_priv__base64Value'(A0) -> base64Value(A0).

'__bp_priv__hexDigit'(A0) -> hexDigit(A0).

'__bp_priv__upperHexDigit'(A0) -> upperHexDigit(A0).

'__bp_priv__hexValue'(A0) -> hexValue(A0).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).

'__bp_priv__array_flatten'(A0) -> array_flatten(A0).
