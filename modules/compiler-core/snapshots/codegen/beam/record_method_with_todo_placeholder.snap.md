----- SOURCE CODE -- main.bp
```botopink
type Unimplemented(id: i32) {
    fn process(self: Self) -> string {
        return @todo();
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

----- BEAM ASSEMBLY -- main__t__unimplemented.S
```erlang
{module, main__t__unimplemented}.
{exports, [{process, 1}]}.
{attributes, []}.
{labels, 4}.

{function, process, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__unimplemented.erl", 1}]}.
    {func_info, {atom, main__t__unimplemented}, {atom, process}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, undef}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, error, 1}}.
```

----- RUN LOG -----
```logs
```
