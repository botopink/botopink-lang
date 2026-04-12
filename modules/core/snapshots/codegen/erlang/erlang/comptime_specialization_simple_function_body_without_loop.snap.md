----- SOURCE CODE -- main.bp
```botopink
fn execute(comptime slug: string, input: i32) -> i32 {
    return input + 0;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
    val r3 = execute("calc", 5);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

main() ->
    R1 = execute_$0(10),
    R2 = execute_$1(42),
    R3 = execute_$0(5).

execute_$0(Input) ->
    (Input + 0).

execute_$1(Input) ->
    (Input + 0).
```
