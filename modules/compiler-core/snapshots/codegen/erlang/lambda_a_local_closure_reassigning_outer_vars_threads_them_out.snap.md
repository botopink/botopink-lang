----- SOURCE CODE -- main.bp
```botopink
fn render(words: Array<string>) -> string {
    var out = "";
    var count = 0;
    val emit = { w ->
        out = out + "<" + w + ">";
        count = count + 1;
    };
    emit("start");
    loop (words) { w -> emit(w); };
    return out + " " + count.toString();
}
fn main() {
    @print(render(["a", "b"]));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

render(Words) ->
    Out = <<"">>,
    Count = 0,
    Emit = fun(W, {Out@1, Count@1}) ->
        Out@2 = <<Out@1/binary, "<", ('__bp_text'(W))/binary, ">">>,
        Count@2 = (Count@1 + 1),
        {Out@2, Count@2}
    end,
    {Out@3, Count@3} = Emit(<<"start">>, {Out, Count}),
    {Out@6, Count@6} = lists:foldl(fun(W, {Out@4, Count@4}) ->
        {Out@5, Count@5} = Emit(W, {Out@4, Count@4}),
        {Out@5, Count@5}
    end, {Out@3, Count@3}, Words),
    <<Out@6/binary, " ", ('__bp_text'(erlang:integer_to_binary(Count@6)))/binary>>.

main() ->
    '__bp_print'([render([<<"a">>, <<"b">>])]).

'__bp_text'(Value) when is_binary(Value) -> Value;
'__bp_text'(Value) -> iolist_to_binary(io_lib:format(<<"~p">>, [Value])).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<start><a><b> 3
```
