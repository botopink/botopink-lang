-module(std@querystring).
-export([parse/1, parseForm/1, stringify/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__stripPrefix'/1, '__bp_priv__isHexDigit'/1, '__bp_priv__isControl'/1, '__bp_priv__isControlEscape'/2, '__bp_priv__scan'/2, '__bp_priv__decodeComponent'/2, '__bp_priv__decodeField'/2, '__bp_priv__decodeFields'/4, '__bp_priv__decodeBody'/2, '__bp_priv__hasControlFrom'/2, '__bp_priv__hasControl'/1, '__bp_priv__pairsOf'/1, '__bp_priv__problemOf'/1, '__bp_priv__string_slice'/3]).

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

%%% std/querystring — the query-string codec: RFC 3986 query components and

%%% the `application/x-www-form-urlencoded` flavour.

%%% 

%%% Reference:

%%%   RFC 3986 §2.1 (percent-encoding), §3.4 (query)

%%%   WHATWG URL — application/x-www-form-urlencoded (`+` is a space)

%%%   Node.js  — https://nodejs.org/api/querystring.html

%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/uri_string.html

%%% 

%%% A codec, not a splitter. `parse` / `parseForm` split on `&`, each field

%%% on its FIRST `=` (a field with no `=` is a name with an empty value; an

%%% empty field is dropped), and percent-decode both sides; `parseForm`

%%% also reads `+` as a space, `parse` keeps it as a `+`. `stringify`

%%% percent-encodes every byte outside the RFC 3986 unreserved set, so its

%%% output reads back through either parser.

%%% 

%%% Refused, never kept as written (rakun's 03r-e rule, as a refusal): a `%`

%%% not followed by two hex digits, an escape sequence that is not UTF-8, and

%%% a control character (U+0000–U+001F, U+007F) — raw, or as the escape that

%%% would decode to one. A parser that can produce a newline is how a newline

%%% reaches a header. `stringify` refuses a control character too, so every

%%% text it writes is one `parse` reads back.

%%% 

%%% The percent codec is `encoding`'s (`percentEncode` / `percentDecode`),

%%% imported: the same bytes on commonJS and erlang, and the refusals above

%%% are decided in botopink before either cell runs.

%% import percentEncode, percentDecode, hexDecode

% Strip an optional leading `?` from a URL's query portion. Idempotent.

stripPrefix(Query) ->
    case (string:prefix(Query, <<"?">>) =/= nomatch) of
        true ->
            string_slice(Query, 1, erlang:length(unicode:characters_to_list(Query)));
        _ ->
            Query
    end.

isHexDigit(C) ->
    ((C =/= <<"">>) andalso (string:find(<<"0123456789abcdefABCDEF">>, C) =/= nomatch)).

isControl(C) ->
    Code = (fun(__S, __I) -> case unicode:characters_to_list(__S, utf8) of __L when length(__L) > __I, __I >= 0 -> lists:nth(__I + 1, __L); _ -> -1 end end)(C, 0),
    ((Code >= 0) andalso (((Code < 32) orelse (Code =:= 127)))).

% Whether `%<h1><h2>` decodes to a control character: `%00`–`%1F` or `%7F`.

% A byte below 0x80 is never part of a multi-byte UTF-8 sequence, so the

% escape alone decides it.

isControlEscape(H1, H2) ->
    (((H1 =:= <<"0">>) orelse (H1 =:= <<"1">>)) orelse (((H1 =:= <<"7">>) andalso (((H2 =:= <<"f">>) orelse (H2 =:= <<"F">>)))))).

% The first problem in one raw component from index `i`, or `""` when it may

% be decoded. Walks the string by `at`: a `%` reads its two digits by index,

% which a `split("")` piece list would only re-index.

scan(S, I) ->
    case (I >= erlang:length(unicode:characters_to_list(S))) of
        true ->
            <<"">>;
        _ ->
            C = case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, I) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end,
            case (C =:= <<"%">>) of
                true ->
                    H1 = case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/querystring.bp:59:25">>)) of
                        undefined ->
                            <<"">>;
                        __bp_nullish@1 ->
                            __bp_nullish@1
                    end,
                    H2 = case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, '__bp_int'((I + 2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/querystring.bp:60:25">>)) of
                        undefined ->
                            <<"">>;
                        __bp_nullish@2 ->
                            __bp_nullish@2
                    end,
                    case (((isHexDigit(H1) andalso isHexDigit(H2))) =:= false) of
                        true ->
                            <<"a `%` not followed by two hex digits">>;
                        _ ->
                            case isControlEscape(H1, H2) of
                                true ->
                                    <<"an escape that decodes to a control character">>;
                                _ ->
                                    scan(S, '__bp_int'((I + 3), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/querystring.bp:65:26">>))
                            end
                    end;
                _ ->
                    case isControl(C) of
                        true ->
                            <<"a control character">>;
                        _ ->
                            scan(S, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/querystring.bp:68:22">>))
                    end
            end
    end.

% One raw component decoded, `+` first read as a space when `form`.

decodeComponent(Raw, Form) ->
    Text = case Form of
        true ->
            (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Raw, <<"+">>, <<" ">>);
        false ->
            Raw
    end,
    Problem = scan(Text, 0),
    case (Problem =/= <<"">>) of
        true ->
            {error, <<"querystring.parse: ", Problem/binary>>};
        _ ->
            Decoded = std@encoding:percentDecode(Text),
            case (fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(Decoded) of
                true ->
                    {error, <<"querystring.parse: an escape sequence that is not UTF-8">>};
                _ ->
                    {ok, (fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (<<"">>) end end)(Decoded)}
            end
    end.

% One `name=value` field, split on its FIRST `=`.

decodeField(Field, Form) ->
    Eq = (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(Field, <<"=">>),
    RawName = case (Eq < 0) of
        true ->
            Field;
        false ->
            string_slice(Field, 0, Eq)
    end,
    RawValue = case (Eq < 0) of
        true ->
            <<"">>;
        false ->
            string_slice(Field, '__bp_int'((Eq + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/querystring.bp:89:55">>), erlang:length(unicode:characters_to_list(Field)))
    end,
    case decodeComponent(RawName, Form) of
        {ok, Name} ->
            case decodeComponent(RawValue, Form) of
                {ok, Value} ->
                    {ok, {Name, Value}};
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.

decodeFields(Fields, I, Form, Acc) ->
    case (I >= erlang:length(Fields)) of
        true ->
            {ok, Acc};
        _ ->
            case decodeField(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Fields, I) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end, Form) of
                {ok, Pair} ->
                    decodeFields(Fields, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/querystring.bp:103:39">>), Form, (Acc ++ [Pair]));
                {error, _TryE0} -> {error, _TryE0}
            end
    end.

decodeBody(Body, Form) ->
    Fields = lists:filter(fun(Chunk) ->
        (Chunk =/= <<"">>)
    end, (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(Body, <<"&">>)),
    None = [],
    decodeFields(Fields, 0, Form, None).

% Parse a URL query (RFC 3986) into its ordered `#(name, value)` pairs, a

% leading `?` stripped. Duplicate names are kept in order (Node's

% `querystring.parse` folds them into arrays; the pair list leaves that to

% the caller). `+` is a `+` here — `parseForm` is the flavour that reads it

% as a space. A malformed escape, a non-UTF-8 escape sequence or a control

% character is an `Error`.

parse(Query) ->
    decodeBody(stripPrefix(Query), false).

% Parse an `application/x-www-form-urlencoded` body: `parse`'s rules with

% `+` read as a space before decoding. A form body is not a URL, so a

% leading `?` is data, not stripped.

parseForm(Body) ->
    decodeBody(Body, true).

hasControlFrom(S, I) ->
    case (I >= erlang:length(unicode:characters_to_list(S))) of
        true ->
            false;
        _ ->
            case isControl(case (fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(S, I) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end) of
                true ->
                    true;
                _ ->
                    hasControlFrom(S, '__bp_int'((I + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/querystring.bp:135:32">>))
            end
    end.

hasControl(S) ->
    hasControlFrom(S, 0).

% Serialize ordered `#(name, value)` pairs: each side percent-encoded over

% the RFC 3986 unreserved set (a space is `%20`, a `+` is `%2B`, so the text

% reads back through `parse` and `parseForm` alike), joined with `&`. Empty

% input is `""`; there is no leading `?`. A control character in a name or a

% value is an `Error` — `parse` would refuse the text it became.

stringify(Pairs) ->
    Bad = lists:filter(fun(P) ->
        (hasControl(erlang:element(1, P)) orelse hasControl(erlang:element(2, P)))
    end, Pairs),
    case (erlang:length(Bad) > 0) of
        true ->
            {error, <<"querystring.stringify: a control character">>};
        _ ->
            {ok, iolist_to_binary(lists:join(<<"&">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(P) ->
                iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [std@encoding:percentEncode(erlang:element(1, P)), <<"=">>, std@encoding:percentEncode(erlang:element(2, P))])))
            end, Pairs))))}
    end.

% ── tests ────────────────────────────────────────────────────────────────────

pairsOf(R) ->
    None = [],
    iolist_to_binary(lists:join(<<"|">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(P) ->
        iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [erlang:element(1, P), <<"=>">>, erlang:element(2, P)])))
    end, (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (None) end end)(R))))).

problemOf(R) ->
    Text = case R of
        {ok, _v} ->
            <<"">>;
        {error, E} ->
            E
    end,
    Text.















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

'__bp_priv__stripPrefix'(A0) -> stripPrefix(A0).

'__bp_priv__isHexDigit'(A0) -> isHexDigit(A0).

'__bp_priv__isControl'(A0) -> isControl(A0).

'__bp_priv__isControlEscape'(A0, A1) -> isControlEscape(A0, A1).

'__bp_priv__scan'(A0, A1) -> scan(A0, A1).

'__bp_priv__decodeComponent'(A0, A1) -> decodeComponent(A0, A1).

'__bp_priv__decodeField'(A0, A1) -> decodeField(A0, A1).

'__bp_priv__decodeFields'(A0, A1, A2, A3) -> decodeFields(A0, A1, A2, A3).

'__bp_priv__decodeBody'(A0, A1) -> decodeBody(A0, A1).

'__bp_priv__hasControlFrom'(A0, A1) -> hasControlFrom(A0, A1).

'__bp_priv__hasControl'(A0) -> hasControl(A0).

'__bp_priv__pairsOf'(A0) -> pairsOf(A0).

'__bp_priv__problemOf'(A0) -> problemOf(A0).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
