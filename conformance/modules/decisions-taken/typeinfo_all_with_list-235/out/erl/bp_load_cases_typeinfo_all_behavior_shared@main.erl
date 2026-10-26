-module(bp_load_cases_typeinfo_all_behavior_shared@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__declared__metaAll__BeanRole'/2]).

%% type DeclaredMeta: key, value

%% type DeclaredTypedMeta: key, value

%% type Declared: name, module, meta, returnTypeName, value, typedMeta

%%% Decision 564 — a query over several decorators answers the behavior they

%%% share: `#[service]` and `#[repository]` both name `Bean`, so

%%% `@TypeInfo.all(with: [service, repository])` answers

%%% `Declared<Bean>[]`, in the one order (decision 235).

%% behavior Bean

%% type Mailer: host

%% type Orders: table

main() ->
    All = [{bp_load_cases_typeinfo_all_behavior_shared@main@@Declared, <<"Mailer">>, <<"bp_load__cases__typeinfo_all_behavior_shared/main">>, [], <<"">>, undefined, [{bp_load_cases_typeinfo_all_behavior_shared@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_behavior_shared@main@@BeanRole">>, fun() ->
        {bp_load_cases_typeinfo_all_behavior_shared@main@@BeanRole, <<"service">>}
    end}]}, {bp_load_cases_typeinfo_all_behavior_shared@main@@Declared, <<"Orders">>, <<"bp_load__cases__typeinfo_all_behavior_shared/main">>, [], <<"">>, undefined, [{bp_load_cases_typeinfo_all_behavior_shared@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_behavior_shared@main@@BeanRole">>, fun() ->
        {bp_load_cases_typeinfo_all_behavior_shared@main@@BeanRole, <<"repository">>}
    end}]}],
    lists:foreach(fun(D) ->
        '__bp_print'([<<('__bp_text'(erlang:element(2, D)))/binary, " ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(M) ->
            erlang:element(2, M)
        end, declared__metaAll__BeanRole(erlang:element(7, D), <<"bp_load__cases__typeinfo_all_behavior_shared@main@@BeanRole">>)))))))/binary>>])
    end, All).

% What `#[service]` and `#[repository]` record: the bean's role.

%% type BeanRole: role

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/typeinfo_all_behavior_shared|*">>.

declared__metaAll__BeanRole(Slots, Key) ->
    Out = [],
    Out@5 = lists:foldl(fun(S, Out@1) ->
        Out@4 = case (erlang:element(2, S) =:= Key) of
            true ->
                F = erlang:element(3, S),
                Out@3 = case erlang:is_function(F, 0) of
                    true ->
                        Out@2 = (Out@1 ++ [F()]),
                        Out@2;
                    _ ->
                        Out@1
                end,
                Out@3;
            _ ->
                Out@1
        end,
        Out@4
    end, Out, Slots),
    Out@5.

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

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__declared__metaAll__BeanRole'(A0, A1) -> declared__metaAll__BeanRole(A0, A1).
