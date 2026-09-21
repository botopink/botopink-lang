----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Green,
    Blue,
    fn name() -> string {
        case (self) {
            Red -> "red";
            Green -> "green";
            Blue -> "blue";
        };
    }
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- main__t__color.S
```erlang
{module, main__t__color}.
{exports, [{name, 1}]}.
{attributes, []}.
{labels, 8}.

{function, name, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__color.erl", 1}]}.
    {func_info, {atom, main__t__color}, {atom, name}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {atom, 'Red'}]}.
    {move, {literal, <<"red">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_eq, {f, 6}, [{x, 0}, {atom, 'Green'}]}.
    {move, {literal, <<"green">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_eq, {f, 7}, [{x, 0}, {atom, 'Blue'}]}.
    {move, {literal, <<"blue">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
```

----- RUN LOG -----
```logs
```
