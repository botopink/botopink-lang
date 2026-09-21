----- SOURCE CODE -- main.bp
```botopink
val Vec2 = type(
    x: f64,
    y: f64) {
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Vec2: x, y
```

----- ERLANG -- main__t__vec2.erl
```erlang
-module(main__t__vec2).
-export([lengthSq/1, scale/2]).

lengthSq(Self) ->
    ((maps:get(x, Self) * maps:get(x, Self)) + (maps:get(y, Self) * maps:get(y, Self))).

scale(Self, Factor) ->
    (maps:get(x, Self) * Factor).
```

----- RUN LOG -----
```logs
```
