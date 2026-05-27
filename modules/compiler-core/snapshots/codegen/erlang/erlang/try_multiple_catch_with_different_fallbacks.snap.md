----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
fn fetchName() -> @Result(string, UserError) {
    throw UserError(msg: "name missing");
}
fn fetchAge() -> @Result(i32, UserError) {
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

-record(UserError, {msg}).

fetchName() ->
    erlang:throw(UserError(<<"name missing">>)).

fetchAge() ->
    erlang:throw(UserError(<<"age missing">>)).

loadUser() ->
    Name = try
        fetchName()
catch
        _Err ->
            <<"anonymous">>(_Err)
end,
    Age = try
        fetchAge()
catch
        _Err ->
            0(_Err)
end,
    io:format("~p~n", [Name, Age]).
```

----- RUN LOG -----
```logs
```
