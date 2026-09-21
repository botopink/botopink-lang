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

----- BEAM ASSEMBLY -- main__t__parseerror.S
```erlang
{module, main__t__parseerror}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "main__t__parseerror.erl", 1}]}.
    {func_info, {atom, main__t__parseerror}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, msg}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 6}.
  {label, 5}.
    {line, [{location, "main__t__parseerror.erl", 1}]}.
    {func_info, {atom, main__t__parseerror}, {atom, '__bp_format'}, 1}.
  {label, 6}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"msg">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"ParseError">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- main__t__parser.S
```erlang
{module, main__t__parser}.
{exports, [{parse, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 6}.

{function, parse, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__parser.erl", 1}]}.
    {func_info, {atom, main__t__parser}, {atom, parse}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bad input">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, main__t__parseerror}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, '__bp_format', 1, 5}.
  {label, 4}.
    {line, [{location, "main__t__parser.erl", 2}]}.
    {func_info, {atom, main__t__parser}, {atom, '__bp_format'}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Parser">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
