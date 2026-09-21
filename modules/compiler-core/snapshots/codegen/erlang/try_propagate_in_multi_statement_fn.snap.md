----- SOURCE CODE -- main.bp
```botopink
type IoError(path: string)
#[@result]
fn step1() -> @Result<i32, IoError> {
    throw IoError(path: "/data");
}
#[@result]
fn step2(x: i32) -> @Result<i32, IoError> {
    throw IoError(path: "/out");
}
#[@result]
fn pipeline() -> @Result<i32, IoError> {
    val a = try step1();
    val b = try step2(a);
    return b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type IoError: path

step1() ->
    {error, {main__t__ioerror, <<"/data">>}}.

step2(X) ->
    {error, {main__t__ioerror, <<"/out">>}}.

pipeline() ->
    case step1() of
        {ok, A} ->
            case step2(A) of
                {ok, B} ->
                    {ok, B};
                {error, _TryE1} -> {error, _TryE1}
            end;
        {error, _TryE0} -> {error, _TryE0}
    end.
```

----- ERLANG -- main__t__ioerror.erl
```erlang
-module(main__t__ioerror).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, path) -> element(2, V).

'__bp_format'(V) -> {record, "IoError", [{"path", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
