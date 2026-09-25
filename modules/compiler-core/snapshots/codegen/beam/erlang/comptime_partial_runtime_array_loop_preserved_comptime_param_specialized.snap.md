----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    for (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

'COMMANDS'() ->
    [<<"calc">>, <<"noop">>, <<"help">>].

main() ->
    R1 = 'execute_$0'(10),
    R2 = 'execute_$1'(42).

'execute_$0'(Input) ->
    Slug = <<"calc">>,
    Output = 0,
    Output@4 = lists:foldl(fun(Cmd, Output@1) ->
        Output@3 = case (Cmd =:= Slug) of
            true ->
                Output@2 = (Input * 2),
                Output@2;
            _ ->
                Output@1
        end,
        Output@3
    end, Output, 'COMMANDS'()),
    Output@4.

'execute_$1'(Input) ->
    Slug = <<"noop">>,
    Output = 0,
    Output@4 = lists:foldl(fun(Cmd, Output@1) ->
        Output@3 = case (Cmd =:= Slug) of
            true ->
                Output@2 = (Input * 2),
                Output@2;
            _ ->
                Output@1
        end,
        Output@3
    end, Output, 'COMMANDS'()),
    Output@4.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
