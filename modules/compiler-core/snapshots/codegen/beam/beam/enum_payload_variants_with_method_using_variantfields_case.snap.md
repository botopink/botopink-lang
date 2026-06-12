----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            _ -> 0.0;
        };
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, 'Shape_area', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Shape_area'}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, 'Circle'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 0}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {float, 3.14}], {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, 'Square'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 1}, {y, 1}], {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 3, {atom, 'Triangle'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 2}, {y, 3}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {float, 0.5}], {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 4}.
    return.
```

----- RUN LOG -----
```logs
```
