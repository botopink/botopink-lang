----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) {
    loop (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

countUp(X) ->
    lists:foreach(fun(I) ->
        case (I > 100) of
            true ->
                
        end
    end, lists:seq(X, infinity)).
```
