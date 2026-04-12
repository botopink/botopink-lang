----- SOURCE CODE -- main.bp
```botopink
interface Printable {
    fn print(self: Self),
}
record Person { name: string }
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) {
        return self.name;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% interface Printable

-record(Person, {name}).

%% implement Printable for Person

print() ->
    Self_name.
```
