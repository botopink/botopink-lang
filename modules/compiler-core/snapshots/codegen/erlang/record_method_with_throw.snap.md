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
-export([total/1, validate/1]).

total(Self) ->
    (maps:get(subtotal, Self) + (maps:get(subtotal, Self) * maps:get(taxRate, Self))).

validate(Self) ->
    erlang:throw(<<"invalid invoice">>).
```

----- RUN LOG -----
```logs
```
