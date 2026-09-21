----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
    }
}
fn red500() -> Token {
    return .Color.Red.500;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, red500, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, red500}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {atom, main__t__token_color_red__v__500}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, main__t__token_color__v__red}, {x, 0}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, main__t__token__v__color}, {x, 0}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- main__t__token_color.S
```erlang
{module, main__t__token_color}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 5}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__token_color.erl", 1}]}.
    {func_info, {atom, main__t__token_color}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, main__t__token_color__v__red}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"_inner">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"__Token__Color.Red">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"__Token__Color">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- main__t__token_color_red.S
```erlang
{module, main__t__token_color_red}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 6}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__token_color_red.erl", 1}]}.
    {func_info, {atom, main__t__token_color_red}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, main__t__token_color_red__v__100}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"__Token__Color__Red.__100">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, main__t__token_color_red__v__500}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"__Token__Color__Red.__500">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"__Token__Color__Red">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- main__t__token.S
```erlang
{module, main__t__token}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 5}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__token.erl", 1}]}.
    {func_info, {atom, main__t__token}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, main__t__token__v__color}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"_inner">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Token.Color">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Token">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
