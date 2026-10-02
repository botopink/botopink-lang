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
-module(test@main).

%% type Vec2: x, y
```

----- ERLANG -- test@main@@Vec2.erl
```erlang
-module(test@main@@Vec2).
-export([dot/2, '__bp_get'/2, '__bp_format'/1]).

dot(Self, Other) ->
    ((erlang:element(2, Self) * erlang:element(2, Other)) + (erlang:element(3, Self) * erlang:element(3, Other))).

'__bp_get'(V, x) -> erlang:element(2, V);
'__bp_get'(V, y) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Vec2", [{"x", erlang:element(2, V)}, {"y", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
