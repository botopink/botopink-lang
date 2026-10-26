-module(bp_load_cases_typeinfo_all_list@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, declared__metaAll__Service/2, declared__metaAll__Store/2, declared__metaAll__Audited/2]).

%% type DeclaredMeta: key, value

%% type DeclaredTypedMeta: key, value

%% type Declared: name, module, meta, returnTypeName, value, typedMeta

%%% Decision 235 — `@TypeInfo.all(with: [a, b])` answers every declaration

%%% carrying any decorator of the list, in the one order (module path, then

%%% declaration order), a declaration carrying two of them once, with the

%%% meta every listed decorator set. Each `value` is `unknown` (decision 254);

%%% calling it through `is fn() -> T` is front 130's. A type's entry has no

%%% return type: `returnTypeName` is `""` (decision 256).

%% type Mailer: host

%% type Orders: table

%% type Billing: rate

main() ->
    lists:foreach(fun(D) ->
        Meta = [],
        Meta@3 = lists:foldl(fun(M, Meta@1) ->
            Meta@2 = (Meta@1 ++ [<<"role=", ('__bp_text'(erlang:element(2, M)))/binary>>]),
            Meta@2
        end, Meta, declared__metaAll__Service(erlang:element(7, D), <<"bp_load__cases__typeinfo_all_list@main@@Service">>)),
        Meta@6 = lists:foldl(fun(M, Meta@4) ->
            Meta@5 = (Meta@4 ++ [<<"store=", ('__bp_text'(erlang:element(2, M)))/binary>>]),
            Meta@5
        end, Meta@3, declared__metaAll__Store(erlang:element(7, D), <<"bp_load__cases__typeinfo_all_list@main@@Store">>)),
        '__bp_print'([<<('__bp_text'(erlang:element(2, D)))/binary, " ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Meta@6)))))/binary>>])
    end, [{bp_load_cases_typeinfo_all_list@main@@Declared, <<"Mailer">>, <<"bp_load__cases__typeinfo_all_list/main">>, [], <<"">>, fun() ->
        bp_load_cases_typeinfo_all_list@main@@Mailer:make()
    end, [{bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_list@main@@Service">>, fun() ->
        {bp_load_cases_typeinfo_all_list@main@@Service, <<"service">>}
    end}]}, {bp_load_cases_typeinfo_all_list@main@@Declared, <<"Orders">>, <<"bp_load__cases__typeinfo_all_list/main">>, [], <<"">>, fun() ->
        bp_load_cases_typeinfo_all_list@main@@Orders:make()
    end, [{bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_list@main@@Store">>, fun() ->
        {bp_load_cases_typeinfo_all_list@main@@Store, <<"sql">>}
    end}]}, {bp_load_cases_typeinfo_all_list@main@@Declared, <<"Billing">>, <<"bp_load__cases__typeinfo_all_list/main">>, [], <<"">>, fun() ->
        bp_load_cases_typeinfo_all_list@main@@Billing:make()
    end, [{bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_list@main@@Service">>, fun() ->
        {bp_load_cases_typeinfo_all_list@main@@Service, <<"service">>}
    end}, {bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_list@main@@Audited">>, fun() ->
        {bp_load_cases_typeinfo_all_list@main@@Audited, <<"yes">>}
    end}]}]),
    lists:foreach(fun(D) ->
        '__bp_print'([<<('__bp_text'(erlang:element(2, D)))/binary, " ", ('__bp_text'(erlang:integer_to_binary(('__bp_int'((erlang:length(declared__metaAll__Service(erlang:element(7, D), <<"bp_load__cases__typeinfo_all_list@main@@Service">>)) + erlang:length(declared__metaAll__Audited(erlang:element(7, D), <<"bp_load__cases__typeinfo_all_list@main@@Audited">>))), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:54:21">>)))))/binary, " [", ('__bp_text'(erlang:element(5, D)))/binary, "]">>])
    end, [{bp_load_cases_typeinfo_all_list@main@@Declared, <<"Mailer">>, <<"bp_load__cases__typeinfo_all_list/main">>, [], <<"">>, fun() ->
        bp_load_cases_typeinfo_all_list@main@@Mailer:make()
    end, [{bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_list@main@@Service">>, fun() ->
        {bp_load_cases_typeinfo_all_list@main@@Service, <<"service">>}
    end}]}, {bp_load_cases_typeinfo_all_list@main@@Declared, <<"Billing">>, <<"bp_load__cases__typeinfo_all_list/main">>, [], <<"">>, fun() ->
        bp_load_cases_typeinfo_all_list@main@@Billing:make()
    end, [{bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_list@main@@Service">>, fun() ->
        {bp_load_cases_typeinfo_all_list@main@@Service, <<"service">>}
    end}, {bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta, <<"bp_load__cases__typeinfo_all_list@main@@Audited">>, fun() ->
        {bp_load_cases_typeinfo_all_list@main@@Audited, <<"yes">>}
    end}]}]).

% What `#[service]` records.

%% type Service: role

% What `#[repository]` records.

%% type Store: store

% What `#[audited]` records.

%% type Audited: audit

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/typeinfo_all_list|*">>.

declared__metaAll__Service(Slots, Key) ->
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

declared__metaAll__Store(Slots, Key) ->
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

declared__metaAll__Audited(Slots, Key) ->
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

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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
