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

-record(Invoice, {subtotal, taxRate}).

total() ->
    (Self_subtotal + (Self_subtotal * Self_taxRate)).

validate() ->
    erlang:throw(Error(<<"invalid invoice">>)).
```
