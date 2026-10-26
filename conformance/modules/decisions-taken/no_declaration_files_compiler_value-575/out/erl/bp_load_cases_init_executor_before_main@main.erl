-module(bp_load_cases_init_executor_before_main@main).
-export(['_botopink_main'/0, main/1]).
-export(['_botopink_init'/0, hello/0, greet/0, home/0, '__bp_executor_0'/0, '__bp_executor_1'/0, '__bp_executor_2'/0, '__bp_executor_3'/0, '__bp_executor_4'/0, '__bp_executor_5'/0, '__bp_executor_6'/0, '__bp_executor_7'/0, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_init_0'/0, '__bp_init_1'/0, '__bp_init_2'/0, '__bp_init_3'/0, '__bp_init_4'/0, '__bp_init_5'/0, banner/0, '__bp_init_6'/0, '__bp_init_7'/0]).

%%% Decision 575 (3) — `compiler.init(executor)`: run-time code a decorator

%%% compiles beside the annotated declaration, run once before `main` in the

%%% program's init list — declarations in source order, the calls of one body

%%% in order, any number per declaration. The executor is a tree (575 (4)):

%%% the `comptime` parameter `label` and the body's `val name` are spliced as

%%% literals. An executor may be named instead of written at the call: a

%%% function of the decorator's module (`hello`), or a `syntax` parameter

%%% (`run`), spliced as the annotation wrote it.

hello() ->
    '__bp_print'([<<"hello">>]).

greet() ->
    '__bp_print'([<<"greet">>]).

home() ->
    <<"home">>.

'__bp_executor_0'() ->
    '__bp_print'([<<('__bp_text'((<<"page">>)))/binary, " ", ('__bp_text'((<<"home">>)))/binary>>]).

'__bp_init_0'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_0'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_0'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_0'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_1'() ->
    '__bp_print'([<<"again ", ('__bp_text'((<<"home">>)))/binary>>]).

'__bp_init_1'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_1'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_1'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_1'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

%% type Shell: title

'__bp_executor_2'() ->
    '__bp_print'([<<('__bp_text'((<<"layout">>)))/binary, " ", ('__bp_text'((<<"Shell">>)))/binary>>]).

'__bp_init_2'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_2'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_2'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_2'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_3'() ->
    '__bp_print'([<<"again ", ('__bp_text'((<<"Shell">>)))/binary>>]).

'__bp_init_3'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_3'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_3'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_3'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_4'() ->
    '__bp_print'([<<('__bp_text'((<<"view">>)))/binary, " ", ('__bp_text'((<<"Shell">>)))/binary>>]).

'__bp_init_4'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_4'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_4'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_4'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_5'() ->
    '__bp_print'([<<"again ", ('__bp_text'((<<"Shell">>)))/binary>>]).

'__bp_init_5'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_5'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_5'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_5'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

banner() ->
    <<"banner">>.

'__bp_executor_6'() ->
    hello().

'__bp_init_6'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_6'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_6'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_6'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'__bp_executor_7'() ->
    greet().

'__bp_init_7'() ->
    case persistent_term:get({bp_load_cases_init_executor_before_main@main, '__bp_init_7'}, '__bp_unset') of
        '__bp_unset' -> __BpV = '__bp_executor_7'(), persistent_term:put({bp_load_cases_init_executor_before_main@main, '__bp_init_7'}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

main() ->
    '__bp_print'([<<"main">>]),
    '__bp_print'([home()]),
    '__bp_print'([erlang:element(2, {bp_load_cases_init_executor_before_main@main@@Shell, <<"t">>})]),
    '__bp_print'([banner()]).

'__bp_loaded_main'() ->
    '_botopink_init'(),
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/init_executor_before_main|*">>.

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
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_0'}),
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_1'}),
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_2'}),
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_3'}),
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_4'}),
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_5'}),
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_6'}),
    persistent_term:erase({bp_load_cases_init_executor_before_main@main, '__bp_init_7'}),
    '__bp_init_0'(),
    '__bp_init_1'(),
    '__bp_init_2'(),
    '__bp_init_3'(),
    '__bp_init_4'(),
    '__bp_init_5'(),
    '__bp_init_6'(),
    '__bp_init_7'(),
    ok.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '_botopink_init'(),
    main().

main(_Args) ->
    '_botopink_main'().
