----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = type {
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
{labels, 8}.

{function, 'HttpMethod_name', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'HttpMethod_name'}, 1}.
  {label, 3}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {atom, 'Get'}]}.
    {move, {literal, <<"GET">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_eq, {f, 6}, [{x, 0}, {atom, 'Post'}]}.
    {move, {literal, <<"POST">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_eq, {f, 7}, [{x, 0}, {atom, 'Put'}]}.
    {move, {literal, <<"PUT">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
    {move, {literal, <<"DELETE">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.
```

----- RUN LOG -----
```logs
```
