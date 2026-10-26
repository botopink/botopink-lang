-module(bp_load_cases_decorator_decl_pattern@main).
-export(['_botopink_main'/0, main/1]).
-export([sendReceipt/1, refund/1, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%% type DeclaredMeta: key, value

%% type DeclaredTypedMeta: key, value

%% type Declared: name, module, meta, returnTypeName, value, typedMeta

%%% Decision 280 (2), example 2 — `@Decl<fn(e: E) -> unknown>`: the decorator

%%% takes no argument, and its pattern binds `E` from the annotated

%%% function's parameter. A function of that shape is accepted whatever it

%%% returns; the catalogue (`@TypeInfo.all(with: on)`) lists the listeners.

%% type OrderPlaced: id, total

%% type OrderCancelled: id

sendReceipt(E) ->
    <<"receipt ", ('__bp_text'(erlang:element(2, E)))/binary>>.

refund(E) ->
    '__bp_print'([<<"refund ", ('__bp_text'(erlang:element(2, E)))/binary>>]).

main() ->
    '__bp_print'([iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(D) ->
        erlang:element(2, D)
    end, [{bp_load_cases_decorator_decl_pattern@main@@Declared, <<"sendReceipt">>, <<"bp_load__cases__decorator_decl_pattern/main">>, [], <<"string">>, fun sendReceipt/1, [{bp_load_cases_decorator_decl_pattern@main@@DeclaredTypedMeta, <<"bp_load__cases__decorator_decl_pattern@main@@EventHandler">>, fun() ->
        {bp_load_cases_decorator_decl_pattern@main@@EventHandler, <<"sendReceipt">>}
    end}]}, {bp_load_cases_decorator_decl_pattern@main@@Declared, <<"refund">>, <<"bp_load__cases__decorator_decl_pattern/main">>, [], <<"void">>, fun refund/1, [{bp_load_cases_decorator_decl_pattern@main@@DeclaredTypedMeta, <<"bp_load__cases__decorator_decl_pattern@main@@EventHandler">>, fun() ->
        {bp_load_cases_decorator_decl_pattern@main@@EventHandler, <<"refund">>}
    end}]}]))))]),
    '__bp_print'([sendReceipt({bp_load_cases_decorator_decl_pattern@main@@OrderPlaced, <<"o1">>, 10})]),
    refund({bp_load_cases_decorator_decl_pattern@main@@OrderCancelled, <<"o2">>}).

% What `#[on]` records.

%% type EventHandler: event

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/decorator_decl_pattern|*">>.

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
