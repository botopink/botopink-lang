-module(bp_load_cases_comptime_optional_fn_tested_against_null@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, positive/1, nonZero/1, '__bp_executor_0'/0, '__bp_executor_1'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_init_0'/0, '__bp_init_1'/0]).

%%% Decision 735 — an optional function-typed `comptime` argument is tested

%%% against `null` as any `?T` is: `if (rule == null) { … }`, the function

%%% type no exception. A decorator tells `#[check("…")]` on a rule function

%%% from `#[check("…", rule)]` on a type by it; an ordinary function's

%%% `comptime` parameter is tested the same way.

positive(V) ->
    (V > 0).

nonZero(V) ->
    (V =/= 0).

'__bp_executor_0'() ->
    '__bp_print'([<<('__bp_text'((<<"nonZero">>)))/binary, ": ", ('__bp_text'((<<"not zero">>)))/binary, ", by itself">>]).

'__bp_init_0'() ->
    case persistent_term:get({bp_load_cases_comptime_optional_fn_tested_against_null@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({bp_load_cases_comptime_optional_fn_tested_against_null@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

%% type Amount: v

'__bp_executor_1'() ->
    '__bp_print'([<<('__bp_text'((<<"Amount">>)))/binary, ": ", ('__bp_text'((<<"positive">>)))/binary, ", by a rule">>]).

'__bp_init_1'() ->
    case persistent_term:get({bp_load_cases_comptime_optional_fn_tested_against_null@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({bp_load_cases_comptime_optional_fn_tested_against_null@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

main() ->
    '__bp_print'([<<"no rule">>]),
    '__bp_print'([<<"a rule">>]).

'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/comptime_optional_fn_tested_against_null|*">>.

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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

'_botopink_init'() ->
    persistent_term:erase({bp_load_cases_comptime_optional_fn_tested_against_null@main, '__bp_init_0'}),
    persistent_term:erase({bp_load_cases_comptime_optional_fn_tested_against_null@main, '__bp_init_1'}),
    '__bp_init_0'(),
    '__bp_init_1'(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().
