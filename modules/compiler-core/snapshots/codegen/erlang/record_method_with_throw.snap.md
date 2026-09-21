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
-module(main).

%% type Invoice: subtotal, taxRate
```

----- ERLANG -- main__t__invoice.erl
```erlang
-module(main__t__invoice).
-export([total/1, validate/1, '__bp_get'/2, '__bp_format'/1]).

total(Self) ->
    (element(2, Self) + (element(2, Self) * element(3, Self))).

validate(Self) ->
    erlang:throw(<<"invalid invoice">>).

'__bp_get'(V, subtotal) -> element(2, V);
'__bp_get'(V, taxRate) -> element(3, V).

'__bp_format'(V) -> {record, "Invoice", [{"subtotal", element(2, V)}, {"taxRate", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
