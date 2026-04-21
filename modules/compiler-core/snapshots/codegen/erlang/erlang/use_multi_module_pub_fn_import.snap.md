----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- ERLANG -- math.erl
```erlang
-module(math).
-export([double/1]).

double(X) ->
    (X * 2).
```

----- SOURCE CODE -- main.bp
```botopink
use {double} from "math";
val result = double(21);
```

----- ERLANG -- main.erl
```erlang
-module(main).

-import(math, [double/0]).

result() ->
    double(21).
```
