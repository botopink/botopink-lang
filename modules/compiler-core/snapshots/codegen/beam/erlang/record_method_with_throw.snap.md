----- SOURCE CODE -- main.bp
```botopink
val Invoice = type(
    subtotal: f64,
    taxRate: f64) {
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw "invalid invoice";
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Invoice: subtotal, taxRate
```

----- ERLANG -- test@main@@Invoice.erl
```erlang
-module(test@main@@Invoice).
-export([total/1, validate/1, '__bp_get'/2, '__bp_format'/1]).

total(Self) ->
    (erlang:element(2, Self) + (erlang:element(2, Self) * erlang:element(3, Self))).

validate(Self) ->
    erlang:throw(<<"invalid invoice">>).

'__bp_get'(V, subtotal) -> erlang:element(2, V);
'__bp_get'(V, taxRate) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Invoice", [{"subtotal", erlang:element(2, V)}, {"taxRate", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
