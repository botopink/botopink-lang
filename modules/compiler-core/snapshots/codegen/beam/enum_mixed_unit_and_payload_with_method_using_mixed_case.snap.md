----- SOURCE CODE -- main.bp
```botopink
val Maybe = type {
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
{labels, 2}.
```

----- BEAM ASSEMBLY -- main__t__maybe.S
```erlang
{module, main__t__maybe}.
{exports, [{check, 1}]}.
{attributes, []}.
{labels, 7}.

{function, check, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__maybe.erl", 1}]}.
    {func_info, {atom, main__t__maybe}, {atom, check}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {atom, 'Nothing'}]}.
    {move, {literal, <<"nothing">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, 'Just'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"just">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
  {label, 4}.
    {deallocate, 3}.
    return.
```

----- RUN LOG -----
```logs
```
