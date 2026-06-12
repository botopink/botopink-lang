----- SOURCE CODE -- main.bp
```botopink
val Invoice = record {
    subtotal: f64,
    taxRate: f64,
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw new Error("invalid invoice");
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Invoice: subtotal, taxRate

total(Self) ->
    (maps:get(subtotal, Self) + (maps:get(subtotal, Self) * maps:get(taxRate, Self))).

validate(Self) ->
    erlang:throw(Error(<<"invalid invoice">>)).
```

----- RUN LOG -----
```logs
```
