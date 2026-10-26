-module(bp_load_cases_typeinfo_all_decorator_argument@main).
-export(['_botopink_main'/0, main/1]).
-export([home/0, sweep/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%% type DeclaredMeta: key, value

%% type DeclaredTypedMeta: key, value

%% type Declared: name, module, meta, returnTypeName, value, typedMeta

%%% Decision 268 — `@TypeInfo.all` declares `with: Decorator | Decorator[]`,

%%% and a decorator's name has type `Decorator`: a decorator with further

%%% arguments, a single decorator and a list of them are all accepted.

home() ->
    <<"home">>.

sweep() ->
    <<"sweep">>.

main() ->
    '__bp_print'([erlang:length([{bp_load_cases_typeinfo_all_decorator_argument@main@@Declared, <<"home">>, <<"bp_load__cases__typeinfo_all_decorator_argument/main">>, [], <<"string">>, fun home/0, [{bp_load_cases_typeinfo_all_decorator_argument@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_decorator_argument@main@@Route">>, fun() ->
        {bp_load_cases_typeinfo_all_decorator_argument@main@@Route, <<"/home">>}
    end}]}])]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)([{bp_load_cases_typeinfo_all_decorator_argument@main@@Declared, <<"sweep">>, <<"bp_load__cases__typeinfo_all_decorator_argument/main">>, [], <<"string">>, fun sweep/0, [{bp_load_cases_typeinfo_all_decorator_argument@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_decorator_argument@main@@Job">>, fun() ->
        {bp_load_cases_typeinfo_all_decorator_argument@main@@Job, <<"job">>}
    end}]}], 0)) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(D) ->
        erlang:element(2, D)
    end, [{bp_load_cases_typeinfo_all_decorator_argument@main@@Declared, <<"home">>, <<"bp_load__cases__typeinfo_all_decorator_argument/main">>, [], <<"string">>, fun home/0, [{bp_load_cases_typeinfo_all_decorator_argument@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_decorator_argument@main@@Route">>, fun() ->
        {bp_load_cases_typeinfo_all_decorator_argument@main@@Route, <<"/home">>}
    end}]}, {bp_load_cases_typeinfo_all_decorator_argument@main@@Declared, <<"sweep">>, <<"bp_load__cases__typeinfo_all_decorator_argument/main">>, [], <<"string">>, fun sweep/0, [{bp_load_cases_typeinfo_all_decorator_argument@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_decorator_argument@main@@Job">>, fun() ->
        {bp_load_cases_typeinfo_all_decorator_argument@main@@Job, <<"job">>}
    end}]}]))))]).

% What `#[route]` records.

%% type Route: path

% What `#[job]` records.

%% type Job: kind

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/typeinfo_all_decorator_argument|*">>.

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
