----- SOURCE CODE -- main.bp
```botopink
val Invoice = record {
    subtotal: f64,
    taxRate: f64,
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw new Error("invalid invoice");
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 9}.

{function, 'Invoice_total', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Invoice_total'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, subtotal}, {x, 0}]}}.
  {label, 6}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 7}, [{x, 0}]}.
    {get_map_elements, {f, 7}, {x, 0}, {list, [{atom, subtotal}, {x, 0}]}}.
  {label, 7}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, taxRate}, {x, 0}]}}.
  {label, 8}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Invoice_validate', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Invoice_validate'}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {move, {literal, <<"invalid invoice">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved local call: Error/1
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
```

----- RUN LOG -----
```logs
```
