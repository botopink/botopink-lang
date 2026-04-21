----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
fn fetch() -> #(i32, i32) {
    return #(1, 2);
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Error, {msg}).

fetch() ->
    {1, 2}.

f() ->
    {A, B} = try
        fetch()
catch
        _Err ->
            erlang:throw(Error(<<"failed">>))
end.
```
