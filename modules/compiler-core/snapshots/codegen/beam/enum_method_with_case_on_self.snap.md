----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
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
{labels, 5}.

{function, 'Color_name', 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Color_name'}, 0}.
  {label, 3}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {atom, self}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"red">>}, {x, 0}}.
    {jump, {f, 4}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"green">>}, {x, 0}}.
    {jump, {f, 4}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"blue">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
```

----- RUN LOG -----
```logs
```
