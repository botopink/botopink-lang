----- SOURCE CODE -- main.bp
```botopink
type Vec2(
    x: f64,
    y: f64) {
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
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
-export([dot/2]).

dot(Self, Other) ->
    ((maps:get(x, Self) * maps:get(x, Other)) + (maps:get(y, Self) * maps:get(y, Other))).
```

----- RUN LOG -----
```logs
```
