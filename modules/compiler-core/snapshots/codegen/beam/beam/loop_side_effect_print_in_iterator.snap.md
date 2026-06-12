----- SOURCE CODE -- main.bp
```botopink
val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
loop (messages, 0..) { msg, i ->
    @print(msg);
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, messages, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, messages}, 0}.
  {label, 3}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"Aviso 500">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"Sucesso 200">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"Erro 404">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
