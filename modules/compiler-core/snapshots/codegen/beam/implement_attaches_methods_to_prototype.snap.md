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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'Person_print', 1}]}.
{attributes, []}.
{labels, 5}.

{function, 'Person_print', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Person_print'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_map, {f, 4}, [{x, 0}]}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, name}, {x, 0}]}}.
  {label, 4}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
