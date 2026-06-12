----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
*fn fetchName() -> @Result<string, UserError> {
    throw UserError(msg: "name missing");
}
*fn fetchAge() -> @Result<i32, UserError> {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    @print(name, age);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record UserError: msg

fetchName() ->
    {error, #{msg => <<"name missing">>}}.

fetchAge() ->
    {error, #{msg => <<"age missing">>}}.

loadUser() ->
    Name = case fetchName() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            <<"anonymous">>
    end,
    Age = case fetchAge() of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            0
    end,
    io:format("~p~n", [Name, Age]).
```

----- RUN LOG -----
```logs
```
