----- SOURCE CODE -- main.bp
```botopink
fn two() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
fn stepText(s: YieldStep<i32>) -> string {
    val t = case s {
        Yield(v) -> "yield " + v.toString();
        Done -> "done";
    };
    return t;
}
pub fn main() {
    val it = two();
    @print(stepText(it.next()));
    @print(stepText(it.next()));
    @print(stepText(it.next()));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

%% type YieldStep
%%   Yield(value)
%%   Done

%% @Iterator — eager lowering
two() ->
    [1, 2].

stepText(S) ->
    T = case S of
        {test@main@@YieldStep__v__yield, V} ->
            <<"yield ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>;
        test@main@@YieldStep__v__done ->
            <<"done">>
    end,
    T.

main() ->
    It = two(),
    {BpStep1, It@1} = case It of [BpStepHead1 | BpStepRest1] -> {{test@main@@YieldStep__v__yield, BpStepHead1}, BpStepRest1}; BpStepRest1 -> {test@main@@YieldStep__v__done, BpStepRest1} end,
    '__bp_print'([stepText(BpStep1)]),
    {BpStep2, It@2} = case It@1 of [BpStepHead2 | BpStepRest2] -> {{test@main@@YieldStep__v__yield, BpStepHead2}, BpStepRest2}; BpStepRest2 -> {test@main@@YieldStep__v__done, BpStepRest2} end,
    '__bp_print'([stepText(BpStep2)]),
    {BpStep3, It@3} = case It@2 of [BpStepHead3 | BpStepRest3] -> {{test@main@@YieldStep__v__yield, BpStepHead3}, BpStepRest3}; BpStepRest3 -> {test@main@@YieldStep__v__done, BpStepRest3} end,
    '__bp_print'([stepText(BpStep3)]).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- test@main@@YieldStep.erl
```erlang
-module(test@main@@YieldStep).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@YieldStep__v__yield, F0}) -> {variant, "YieldStep.Yield", [{"value", F0}]};
'__bp_format'(test@main@@YieldStep__v__done) -> {variant, "YieldStep.Done", []}.
```

----- RUN LOG -----
```logs
yield 1
yield 2
done
```
