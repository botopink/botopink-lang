----- SOURCE CODE -- main.bp
```botopink
record Person { name: string }
fn firstName(p: Person) -> ?string { @todo(); }
fn shout(s: string) -> ?string { @todo(); }
fn greet(p: Person) -> string {
    return firstName(p)
        .map({ n -> "Hello " + n })
        .flatMap({ n -> shout(n) })
        .unwrapOr("Hello stranger");
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 18}.

{function, firstName, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, firstName}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {atom, undef}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, shout, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, shout}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {move, {atom, undef}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, greet, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, greet}, 1}.
  {label, 7}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 12}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 3}, {x, 0}}.
    {call_fun, 1}.
  {label, 13}.
    {test, is_eq, {f, 10}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {x, 0}, {x, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 3}, {x, 0}}.
    {call_fun, 1}.
  {label, 11}.
    {test, is_eq, {f, 8}, [{x, 0}, {atom, undefined}]}.
    {move, {literal, <<"Hello stranger">>}, {x, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
  {label, 9}.
    {deallocate, 0}.
    return.

{function, '-greet/1-fun-0-', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-greet/1-fun-0-'}, 1}.
  {label, 15}.
    {allocate, 0, 1}.
    {move, {literal, <<"Hello ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-greet/1-fun-1-', 1, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-greet/1-fun-1-'}, 1}.
  {label, 17}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
