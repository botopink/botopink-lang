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
{exports, [{total, 1}, {validate, 1}]}.
{attributes, []}.
{labels, 9}.

{function, total, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__invoice.erl", 1}]}.
    {func_info, {atom, main__t__invoice}, {atom, total}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, subtotal}, {x, 0}]}}.
  {label, 6}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 7}, [{x, 0}]}.
    {get_map_elements, {f, 7}, {x, 0}, {list, [{atom, subtotal}, {x, 0}]}}.
  {label, 7}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, taxRate}, {x, 0}]}}.
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
```

----- RUN LOG -----
```logs
```
