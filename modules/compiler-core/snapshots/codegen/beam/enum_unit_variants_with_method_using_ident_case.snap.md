----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = enum {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 5}.

{function, 'HttpMethod_name', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'HttpMethod_name'}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"GET">>}, {x, 0}}.
    {jump, {f, 4}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"POST">>}, {x, 0}}.
    {jump, {f, 4}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"PUT">>}, {x, 0}}.
    {jump, {f, 4}}.
    {move, {literal, <<"DELETE">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
```

----- RUN LOG -----
```logs
```
