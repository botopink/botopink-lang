-module(bp_load_cases_nullish_default_namespace_call@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__find'/1]).

%% import __bp_ns_names__fallback

%%% Decision 330 — the default of `??` may be a call through a module

%%% namespace: a std module's (`path.basename(…)`) or one of the package's

%%% own (`names.fallback()`). It is a call of that module's function, run

%%% only when the left side is absent — never a method call on the namespace.

%% import path


find(Key) ->
    case (Key =:= <<"a">>) of
        true ->
            <<"found">>;
        false ->
            undefined
    end.

main() ->
    '__bp_print'([case find(<<"a">>) of
        undefined ->
            std@path:basename(<<"/srv/data.txt">>);
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case find(<<"b">>) of
        undefined ->
            std@path:basename(<<"/srv/data.txt">>);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([erlang:length(unicode:characters_to_list((case find(<<"b">>) of
        undefined ->
            std@path:dirname(<<"/srv/data.txt">>);
        __bp_nullish@2 ->
            __bp_nullish@2
    end)))]),
    '__bp_print'([case find(<<"a">>) of
        undefined ->
            bp_load_cases_nullish_default_namespace_call@names:fallback();
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    Who = case find(<<"b">>) of
        undefined ->
            bp_load_cases_nullish_default_namespace_call@names:fallback();
        __bp_nullish@4 ->
            __bp_nullish@4
    end,
    '__bp_print'([Who]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/nullish_default_namespace_call|*">>.

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

'__bp_priv__find'(A0) -> find(A0).
