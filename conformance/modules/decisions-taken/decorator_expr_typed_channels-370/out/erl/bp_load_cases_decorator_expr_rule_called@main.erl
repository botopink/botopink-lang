-module(bp_load_cases_decorator_expr_rule_called@main).
-export(['_botopink_main'/0, main/1]).
-export([passwordsMatch/1, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decision 370 (2) — a decorator hands a parameter's `@Expr` on to the

%%% program through a typed member: `decl.addMember(name, fn(…) -> R { … })`

%%% gives the annotated type a function value whose body uses the

%%% parameters, each `@Expr` spliced where it was written. `rule` is

%%% `passwordsMatch`, called by `validate` at run time — never at build.

%% type Violation: field, message

passwordsMatch(A) ->
    (erlang:element(2, A) =:= erlang:element(3, A)).

%% type Signup: password, confirm

main() ->
    Ok = bp_load_cases_decorator_expr_rule_called@main@@Signup:validate({bp_load_cases_decorator_expr_rule_called@main@@Signup, <<"abc">>, <<"abc">>}),
    '__bp_print'([erlang:length(Ok)]),
    Bad = bp_load_cases_decorator_expr_rule_called@main@@Signup:validate({bp_load_cases_decorator_expr_rule_called@main@@Signup, <<"abc">>, <<"abd">>}),
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
    <<"cases/decorator_expr_rule_called|*">>.

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
