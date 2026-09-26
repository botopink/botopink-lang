----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- ERLANG -- math.erl
```erlang
-module(test@math).
-export([double/1]).

double(X) ->
    (X * 2).
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {double} from "math";
val result = double(21);
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_init'/0]).

%% import double

result() ->
    case persistent_term:get({test@main, result}, '__bp_unset') of
        '__bp_unset' -> __BpV = test@math:double(21), persistent_term:put({test@main, result}, __BpV), __BpV;
        __BpCached -> __BpCached
    end.

'_botopink_init'() ->
    result(),
    ok.
```

----- RUN LOG -----
```logs
```
