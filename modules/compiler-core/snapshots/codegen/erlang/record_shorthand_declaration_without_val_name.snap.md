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
-export([dot/2, '__bp_get'/2, '__bp_format'/1]).

dot(Self, Other) ->
    ((element(2, Self) * element(2, Other)) + (element(3, Self) * element(3, Other))).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V).

'__bp_format'(V) -> {record, "Vec2", [{"x", element(2, V)}, {"y", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
