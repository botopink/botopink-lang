----- SOURCE CODE -- main.bp
```botopink
record ParseError { msg: string }
val Parser = struct {
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
{labels, 8}.

{function, 'Parser_parse', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Parser_parse'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {literal, <<"bad input">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 2, {list, [{atom, msg}, {x, 1}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, run, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, run}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved method call: parse/1
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {integer, 0}, {x, 0}}.
  {label, 7}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
