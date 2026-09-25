----- SOURCE CODE -- main.bp
```botopink
type ParseError(msg: string)
val Parser = type {
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
-module(test@main).

%% type ParseError: msg

%% type Parser: 

run(P) ->
    Result = case try
        test@main@@Parser:parse(P)
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    Result.
```

----- ERLANG -- test@main@@ParseError.erl
```erlang
-module(test@main@@ParseError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, msg) -> element(2, V).

'__bp_format'(V) -> {record, "ParseError", [{"msg", element(2, V)}]}.
```

----- ERLANG -- test@main@@Parser.erl
```erlang
-module(test@main@@Parser).
-export([parse/1, '__bp_format'/1]).

parse(Self) ->
    erlang:throw({test@main@@ParseError, <<"bad input">>}).

'__bp_format'(_) -> {record, "Parser", []}.
```

----- RUN LOG -----
```logs
```
