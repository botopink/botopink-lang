----- SOURCE CODE -- main.bp
```botopink
record ParseError { msg: string }
val Parser = struct {
    fn parse(self: Self) -> @Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = p.parse() catch 0;
    return result;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record ParseError: msg

%% struct Parser: 

parse(Self) ->
    erlang:throw(#{msg => <<"bad input">>}).

run(P) ->
    Result = case parse(P) of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    Result.
```

----- RUN LOG -----
```logs
```
