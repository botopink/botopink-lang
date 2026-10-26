-module(bp_load_cases_member_reads_own_meta@main).
-export(['_botopink_main'/0, main/1]).
-export([passwordsMatch/1, handleFree/1, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 395 — a typed member reads its own type's typed meta through

%%% the decorator's type parameter. In `#[validated]`'s body

%%% `compiler.typeInfo(T).metaAll(Check)` is typed `Check<T>[]` and the member is

%%% checked against it; rendered into `Conta`, the read is answered with the

%%% two `#[check]`s and the member checked again. The list is a constant of

%%% build (`comptime`); the loop and the rules run at run time.

%% type Violation: field, message

%% type Check: message, rule

passwordsMatch(C) ->
    (erlang:element(3, C) =:= erlang:element(4, C)).

handleFree(C) ->
    (erlang:element(2, C) =/= <<"admin">>).

%% type Conta: handle, password, confirm

main() ->
    '__bp_print'([erlang:length(bp_load_cases_member_reads_own_meta@main@@Conta:validate({bp_load_cases_member_reads_own_meta@main@@Conta, <<"ana">>, <<"abc">>, <<"abc">>}))]),
    Bad = bp_load_cases_member_reads_own_meta@main@@Conta:validate({bp_load_cases_member_reads_own_meta@main@@Conta, <<"admin">>, <<"abc">>, <<"abd">>}),
    '__bp_print'([erlang:length(Bad)]),
    lists:foreach(fun(V) ->
        '__bp_print'([<<('__bp_text'(erlang:element(2, V)))/binary, ": ", ('__bp_text'(erlang:element(3, V)))/binary>>])
    end, Bad).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/member_reads_own_meta|*">>.

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
