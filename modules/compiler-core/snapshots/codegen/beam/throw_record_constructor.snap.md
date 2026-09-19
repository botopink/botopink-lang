----- SOURCE CODE -- main.bp
```botopink
type AppError(code: i32, msg: string)
fn validate(x: i32) {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 6}.

{function, validate, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, validate}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 4}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, code}, {integer, 400}, {atom, msg}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 5}}.
  {label, 4}.
  {label, 5}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
