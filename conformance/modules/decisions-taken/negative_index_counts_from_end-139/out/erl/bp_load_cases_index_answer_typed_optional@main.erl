-module(bp_load_cases_index_answer_typed_optional@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% C-02 / decision 63 (amended) — `xs[k]` is `xs.at(k)`, so the index has the

%%% method's answer, `?T`, for a primitive element and a user enum's alike, and

%%% a name written `?T` holds it (`reject/index_answer_is_optional` refuses the

%%% `T` spelling). Two wasm defects sat on this path: a `val c: ?Color` read a

%%% box around an all-unit enum's ordinal as the bare ordinal, so `c ==

%%% Color.Green` answered `false`; and every `a ?? b` binds the same

%%% `__bp_nullish`, so a string payload in one `??` made the next `??` over an

%%% `i32` print as a string — a trap on the integer read as a pointer.

%% type Color
%%   Red
%%   Green

main() ->
    Ts = [1, 2],
    X = (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Ts, 0),
    '__bp_print'([X]),
    '__bp_print'([(X =:= 1)]),
    Cs = [bp_load_cases_index_answer_typed_optional@main@@Color__v__red, bp_load_cases_index_answer_typed_optional@main@@Color__v__green],
    C = (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, 1),
    '__bp_print'([(C =:= bp_load_cases_index_answer_typed_optional@main@@Color__v__green)]),
    D = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, 0) of
        undefined ->
            bp_load_cases_index_answer_typed_optional@main@@Color__v__green;
        __bp_nullish ->
            __bp_nullish
    end,
    '__bp_print'([(D =:= bp_load_cases_index_answer_typed_optional@main@@Color__v__red)]),
    '__bp_print'([((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, 5) =:= bp_load_cases_index_answer_typed_optional@main@@Color__v__red)]),
    Ss = [<<"a">>, <<"b">>],
    S = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Ss, (-1)) of
        undefined ->
            <<"none">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end,
    '__bp_print'([S]),
    Y = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Ts, 5) of
        undefined ->
            7;
        __bp_nullish@2 ->
            __bp_nullish@2
    end,
    '__bp_print'([Y]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/index_answer_typed_optional|*">>.

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
