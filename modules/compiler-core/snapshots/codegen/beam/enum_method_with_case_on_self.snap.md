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
{exports, [{name, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 13}.

{function, name, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__color.erl", 1}]}.
    {func_info, {atom, main__t__color}, {atom, name}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {atom, main__t__color__v__red}]}.
    {move, {literal, <<"red">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_eq, {f, 6}, [{x, 0}, {atom, main__t__color__v__green}]}.
    {move, {literal, <<"green">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_eq, {f, 7}, [{x, 0}, {atom, main__t__color__v__blue}]}.
    {move, {literal, <<"blue">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "main__t__color.erl", 2}]}.
    {func_info, {atom, main__t__color}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 0}, {atom, main__t__color__v__red}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Color.Red">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 10}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 11}, [{x, 0}, {atom, main__t__color__v__green}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Color.Green">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 11}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 12}, [{x, 0}, {atom, main__t__color__v__blue}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Color.Blue">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 12}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Color">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
