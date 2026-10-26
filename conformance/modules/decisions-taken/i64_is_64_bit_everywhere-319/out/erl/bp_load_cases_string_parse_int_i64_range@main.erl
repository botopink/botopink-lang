-module(bp_load_cases_string_parse_int_i64_range@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__parsed'/1, '__bp_priv__string_parseInt'/1]).

%% behavior string

%%% 02-std-and-packaging/97-std-dedupe step 13, decisions 176 and 319 — `string.parseInt()` reads

%%% every `i64`: −2^63 … 2^63 − 1 is `Ok` on every target, one past either end is `Error` naming the

%%% numeral. The parent bounded it at ±(2^53 − 1), so `"9007199254740992"` was out of range.

parsed(S) ->
    case string_parseInt(S) of
        {ok, N} ->
            erlang:integer_to_binary(N);
        {error, Reason} ->
            Reason
    end.

main() ->
    '__bp_print'([parsed(<<"9007199254740991">>)]),
    '__bp_print'([parsed(<<"9007199254740992">>)]),
    '__bp_print'([parsed(<<"-9007199254740993">>)]),
    '__bp_print'([parsed(<<"9223372036854775807">>)]),
    '__bp_print'([parsed(<<"-9223372036854775808">>)]),
    '__bp_print'([parsed(<<"+0009223372036854775807">>)]),
    '__bp_print'([parsed(<<"9223372036854775808">>)]),
    '__bp_print'([parsed(<<"-9223372036854775809">>)]),
    '__bp_print'([parsed(<<"99999999999999999999999999">>)]),
    N = (fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (0) end end)(string_parseInt(<<"9007199254740993">>)),
    '__bp_print'(['__bp_int'((N + 2), -9223372036854775808, 9223372036854775807, <<"integer overflow: + on i64 at src/main.bp:25:13">>)]),
    '__bp_print'([('__bp_int'((N - 2), -9223372036854775808, 9223372036854775807, <<"integer overflow: - on i64 at src/main.bp:26:13">>) =:= 9007199254740991)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/string_parse_int_i64_range|*">>.

string_parseInt(Self) ->
    Signed = ((string:prefix(Self, <<"-">>) =/= nomatch) orelse (string:prefix(Self, <<"+">>) =/= nomatch)),
    Digits = case Signed of
        true ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, 1);
        false ->
            Self
    end,
    case (fun(__S) -> (__S =/= <<>>) andalso lists:all(fun(__C) -> (__C >= 48) andalso (__C =< 57) end, binary_to_list(__S)) end)(Digits) of
        true ->
            (fun(__S) -> __N = binary_to_integer(__S), case (__N >= -9223372036854775807 - 1) andalso (__N =< 9223372036854775807) of true -> {ok, __N}; false -> {error, <<"parseInt: ", 34, __S/binary, 34, " is out of range">>} end end)(Self);
        false ->
            {error, <<"parseInt: ", 34, (Self)/binary, 34, " is not an integer">>}
    end.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

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

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__parsed'(A0) -> parsed(A0).

'__bp_priv__string_parseInt'(A0) -> string_parseInt(A0).
