----- SOURCE CODE -- main.bp
```botopink
val Maybe = enum {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
        };
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, 'Maybe_check', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Maybe_check'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"nothing">>}, {x, 0}}.
    {jump, {f, 4}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, 'Just'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"just">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
  {label, 4}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
