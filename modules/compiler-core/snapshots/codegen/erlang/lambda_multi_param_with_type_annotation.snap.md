----- SOURCE CODE -- main.bp
```botopink
fn main() -> i32 {
    val add: fn(i32,i32)-> i32 = {a, b ->
        return a + b;
    };
    return add(10, 20);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Add = fun(A, B) ->
        '__bp_add'(A, B)
    end,
    Add(10, 20).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
