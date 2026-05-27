----- SOURCE CODE -- main.bp
```botopink
record IoError { path: string }
fn step1() -> @Result(i32, IoError) {
    throw IoError(path: "/data");
}
fn step2(x: i32) -> @Result(i32, IoError) {
    throw IoError(path: "/out");
}
fn pipeline() -> @Result(i32, IoError) {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(IoError, {path}).

step1() ->
    erlang:throw(IoError(<<"/data">>)).

step2(X) ->
    erlang:throw(IoError(<<"/out">>)).

pipeline() ->
    A = step1(),
    B = step2(A),
    B.
```

----- RUN LOG -----
```logs
```
