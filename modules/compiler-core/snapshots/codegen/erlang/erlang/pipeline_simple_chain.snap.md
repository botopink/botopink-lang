----- SOURCE CODE -- main.bp
```botopink
fn double(x: i32) -> i32 { return x * 2; }
fn inc(x: i32) -> i32 { return x + 1; }
fn main() {
    val result = 1
        |> double
        |> inc;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

double(X) ->
    (X * 2).

inc(X) ->
    (X + 1).

main() ->
    Result = Inc(Double(1)).
```
