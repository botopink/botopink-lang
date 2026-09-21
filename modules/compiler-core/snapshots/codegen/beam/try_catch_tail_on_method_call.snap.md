----- SOURCE CODE -- main.bp
```botopink
type ParseError(msg: string)
val Parser = type {
    fn parse(self: Self) -> @Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = p.parse() catch 0;
    return result;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 7}.

{function, run, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, run}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {'try', {y, 1}, {f, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, main__t__parser, parse, 1}}.
    {try_end, {y, 1}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 6}}.
  {label, 4}.
    {try_case, {y, 1}}.
  {label, 5}.
    {move, {integer, 0}, {x, 0}}.
  {label, 6}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
```

----- BEAM ASSEMBLY -- main__t__parser.S
```erlang
{module, main__t__parser}.
{exports, [{parse, 1}]}.
{attributes, []}.
{labels, 4}.

{function, parse, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__parser.erl", 1}]}.
    {func_info, {atom, main__t__parser}, {atom, parse}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bad input">>}, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, msg}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
```

----- RUN LOG -----
```logs
```
