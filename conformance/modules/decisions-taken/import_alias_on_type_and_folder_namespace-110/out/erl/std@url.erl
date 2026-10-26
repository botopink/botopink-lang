-module(std@url).
-export([parse/1, serialize/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__splitOnce'/2, '__bp_priv__parsePort'/1, '__bp_priv__parsePortWalk'/3, '__bp_priv__intToDecimal'/1, '__bp_priv__charToDigit'/1, '__bp_priv__array_slice'/3, '__bp_priv__string_slice'/3]).

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

%%% std/url — pure-botopink URL parsing.

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/url.html

%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/uri_string.html

%%% 

%%% The surface is `parse(s)` → `Url` and `serialize(u)` → `string`. Both

%%% are pure botopink — no host call — so the module works on every

%%% backend including wat. Parsing handles the standard authority shape

%%% 

%%%     scheme://[user[:password]@]host[:port][/path][?query][#fragment]

%%% 

%%% Authentication and port are optional; missing pieces come back as

%%% `""` (string fields) or `0` (port). URI percent-encoding is NOT

%%% applied here — pair this with `querystring` for form values.

%% type Url: scheme, user, password, host, port, path, query, fragment

% Internal: split `s` at the first occurrence of `delim`. Returns

% `#(head, tail)` where `tail` excludes the delimiter. If `delim` is

% not present, `head = s` and `tail = ""`. Implemented via

% `String.split` (which splits on all occurrences) + a rejoin of the

% tail with the delimiter — avoids `String.indexOf` whose Erlang host

% binding (`string:str/2`) is deprecated and reds with `function_clause`

% on binaries in OTP 25+.

splitOnce(S, Delim) ->
    Parts = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(S, Delim),
    case (erlang:length(Parts) < 2) of
        true ->
            {S, <<"">>};
        _ ->
            Head = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Parts, 0) of
                undefined ->
                    <<"">>;
                __bp_nullish ->
                    __bp_nullish
            end,
            Rest = array_slice(Parts, 1, erlang:length(Parts)),
            Tail = iolist_to_binary(lists:join(Delim, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Rest))),
            {Head, Tail}
    end.

% Parse a URL into its component fields. Pure botopink — no host call.

% Defaults: empty strings for absent text fields; 0 for absent port.

parse(Input) ->
    % 1. Split off scheme via `://`.
    SchemeSplit = splitOnce(Input, <<"://">>),
    Scheme = erlang:element(1, SchemeSplit),
    Rest1 = erlang:element(2, SchemeSplit),
    % 2. Split off fragment via `#`.
    FragmentSplit = splitOnce(Rest1, <<"#">>),
    Rest2 = erlang:element(1, FragmentSplit),
    Fragment = erlang:element(2, FragmentSplit),
    % 3. Split off query via `?`.
    QuerySplit = splitOnce(Rest2, <<"?">>),
    Rest3 = erlang:element(1, QuerySplit),
    Query = erlang:element(2, QuerySplit),
    % 4. Split authority from path via the first `/` after the scheme.
    PathSplit = splitOnce(Rest3, <<"/">>),
    Authority = erlang:element(1, PathSplit),
    PathBody = erlang:element(2, PathSplit),
    Path = case (PathBody =:= <<"">>) of
        true ->
            <<"">>;
        false ->
            iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"/">>, PathBody])))
    end,
    % 5. Split userinfo from hostport via `@`.
    UserinfoSplit = splitOnce(Authority, <<"@">>),
    HasUserinfo = (erlang:element(2, UserinfoSplit) =/= <<"">>),
    Userinfo = case HasUserinfo of
        true ->
            erlang:element(1, UserinfoSplit);
        false ->
            <<"">>
    end,
    Hostport = case HasUserinfo of
        true ->
            erlang:element(2, UserinfoSplit);
        false ->
            Authority
    end,
    % 6. Split user:password.
    UserSplit = splitOnce(Userinfo, <<":">>),
    User = erlang:element(1, UserSplit),
    Password = erlang:element(2, UserSplit),
    % 7. Split host:port.
    HostSplit = splitOnce(Hostport, <<":">>),
    Host = erlang:element(1, HostSplit),
    PortStr = erlang:element(2, HostSplit),
    Port = parsePort(PortStr),
    {std@url@@Url, Scheme, User, Password, Host, Port, Path, Query, Fragment}.

% Internal: parse a numeric port from a string. Returns 0 on empty or

% malformed input. Pure botopink — walks each char via a tail-recursive

% helper that uses `String.slice(i, i+1)` to read one char at a time.

% `s.split("")` would give per-char chunks on Node (JS) but on Erlang

% `string:split(S, <<"">>, all)` returns `[S]` (a single chunk), so the

% slice form is the cross-backend portable shape.

parsePort(S) ->
    case (S =:= <<"">>) of
        true ->
            0;
        _ ->
            parsePortWalk(S, 0, 0)
    end.

parsePortWalk(S, Idx, Acc) ->
    case (Idx >= erlang:length(unicode:characters_to_list(S))) of
        true ->
            Acc;
        _ ->
            Ch = string_slice(S, Idx, '__bp_int'((Idx + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/url.bp:103:31">>)),
            Digit = charToDigit(Ch),
            NextAcc = case (Digit < 0) of
                true ->
                    Acc;
                false ->
                    '__bp_int'(('__bp_int'((Acc * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/url.bp:105:47">>) + Digit), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/url.bp:105:52">>)
            end,
            parsePortWalk(S, '__bp_int'((Idx + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/url.bp:106:33">>), NextAcc)
    end.

% Internal: render an i32 as a decimal string by piggy-backing on

% `array<i32>.join("")` — both backends stringify numeric elements

% for `join`: Node's `Array.prototype.join` calls `String(n)` per

% element and Erlang's `lists:join` + iolist-to-binary path maps

% `is_integer(__E) -> integer_to_binary(__E)`. The single-element

% array `[n].join("")` is therefore equivalent to a host

% `int_to_string(n)` on every backend, with no hand-rolled walk

% that would have to dodge i32 division being float on Node.

intToDecimal(N) ->
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [N]))).

charToDigit(Ch) ->
    case (Ch =:= <<"0">>) of
        true ->
            0;
        _ ->
            case (Ch =:= <<"1">>) of
                true ->
                    1;
                _ ->
                    case (Ch =:= <<"2">>) of
                        true ->
                            2;
                        _ ->
                            case (Ch =:= <<"3">>) of
                                true ->
                                    3;
                                _ ->
                                    case (Ch =:= <<"4">>) of
                                        true ->
                                            4;
                                        _ ->
                                            case (Ch =:= <<"5">>) of
                                                true ->
                                                    5;
                                                _ ->
                                                    case (Ch =:= <<"6">>) of
                                                        true ->
                                                            6;
                                                        _ ->
                                                            case (Ch =:= <<"7">>) of
                                                                true ->
                                                                    7;
                                                                _ ->
                                                                    case (Ch =:= <<"8">>) of
                                                                        true ->
                                                                            8;
                                                                        _ ->
                                                                            case (Ch =:= <<"9">>) of
                                                                                true ->
                                                                                    9;
                                                                                _ ->
                                                                                    '__bp_int'((0 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/url.bp:132:14">>)
                                                                            end
                                                                    end
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

% Serialize a `Url` back to the standard

% `scheme://[user[:password]@]host[:port][/path][?query][#fragment]`

% shape. Inverse of `parse` on every valid URL the parser produces.

% String concat uses the cross-backend `[a, b].join("")` workaround

% (raw `+` on strings is numeric on Erlang — badarith on binaries).

serialize(U) ->
    Userinfo = case (erlang:element(3, U) =:= <<"">>) of
        true ->
            <<"">>;
        false ->
            case (erlang:element(4, U) =:= <<"">>) of
                true ->
                    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [erlang:element(3, U), <<"@">>])));
                false ->
                    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [erlang:element(3, U), <<":">>, erlang:element(4, U), <<"@">>])))
            end
    end,
    % `intToDecimal(u.port)` rather than `u.port.toString()`: the
    % `Integer.toString()` Erlang lowering emits a bare `toString/1`
    % undefined call when the receiver is a record-field access of
    % i32, and a pure-botopink walk avoids that bridge gap.
    Hostport = case (erlang:element(6, U) =:= 0) of
        true ->
            erlang:element(5, U);
        false ->
            iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [erlang:element(5, U), <<":">>, intToDecimal(erlang:element(6, U))])))
    end,
    QuerySuffix = case (erlang:element(8, U) =:= <<"">>) of
        true ->
            <<"">>;
        false ->
            iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"?">>, erlang:element(8, U)])))
    end,
    FragmentSuffix = case (erlang:element(9, U) =:= <<"">>) of
        true ->
            <<"">>;
        false ->
            iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"#">>, erlang:element(9, U)])))
    end,
    iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [erlang:element(2, U), <<"://">>, Userinfo, Hostport, erlang:element(7, U), QuerySuffix, FragmentSuffix]))).

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

'__bp_priv__splitOnce'(A0, A1) -> splitOnce(A0, A1).

'__bp_priv__parsePort'(A0) -> parsePort(A0).

'__bp_priv__parsePortWalk'(A0, A1, A2) -> parsePortWalk(A0, A1, A2).

'__bp_priv__intToDecimal'(A0) -> intToDecimal(A0).

'__bp_priv__charToDigit'(A0) -> charToDigit(A0).

'__bp_priv__array_slice'(A0, A1, A2) -> array_slice(A0, A1, A2).

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
