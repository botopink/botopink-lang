----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
#[@result]
fn fetchName() -> @Result<string, UserError> {
    throw UserError(msg: "name missing");
}
#[@result]
fn fetchAge() -> @Result<i32, UserError> {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    @print(name, age);
}
fn main() {
    loadUser();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 18}.

{function, fetchName, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, fetchName}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"name missing">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 2, {list, [{atom, msg}, {x, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, fetchAge, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, fetchAge}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"age missing">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 2, {list, [{atom, msg}, {x, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, loadUser, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, loadUser}, 0}.
  {label, 7}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {call, 0, {f, 3}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {literal, <<"anonymous">>}, {x, 0}}.
  {label, 15}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 5}}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {integer, 0}, {x, 0}}.
  {label, 17}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.
```

----- RUN LOG -----
```logs
<<"anonymous">>
```
