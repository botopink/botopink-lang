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

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```
