----- SOURCE CODE -- main.bp
```botopink
val Invoice = type(
    subtotal: f64,
    taxRate: f64) {
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw "invalid invoice";
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

----- BEAM ASSEMBLY -- main__t__invoice.S
```erlang
{module, main__t__invoice}.
{exports, [{total, 1}, {validate, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 15}.

{function, total, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__invoice.erl", 1}]}.
    {func_info, {atom, main__t__invoice}, {atom, total}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 3, {atom, main__t__invoice}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 6}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 3, {atom, main__t__invoice}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 7}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 3, {atom, main__t__invoice}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 8}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, validate, 1, 5}.
  {label, 4}.
    {line, [{location, "main__t__invoice.erl", 2}]}.
    {func_info, {atom, main__t__invoice}, {atom, validate}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"invalid invoice">>}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.

{function, '__bp_get', 2, 10}.
  {label, 9}.
    {line, [{location, "main__t__invoice.erl", 3}]}.
    {func_info, {atom, main__t__invoice}, {atom, '__bp_get'}, 2}.
  {label, 10}.
    {test, is_eq_exact, {f, 11}, [{x, 1}, {atom, subtotal}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 11}.
    {test, is_eq_exact, {f, 12}, [{x, 1}, {atom, taxRate}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 12}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 14}.
  {label, 13}.
    {line, [{location, "main__t__invoice.erl", 3}]}.
    {func_info, {atom, main__t__invoice}, {atom, '__bp_format'}, 1}.
  {label, 14}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"taxRate">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"subtotal">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Invoice">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
