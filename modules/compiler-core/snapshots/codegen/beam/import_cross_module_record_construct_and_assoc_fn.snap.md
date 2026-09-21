----- SOURCE CODE -- http.bp
```botopink
pub type Response(
    body: string) {
    fn ok(body: string) -> Response {
        return Response(body: body);
    }
}

pub type App(
    port: i32,
    path: string,
)
```

----- BEAM ASSEMBLY -- http.S
```erlang
{module, http}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- http__t__response.S
```erlang
{module, http__t__response}.
{exports, [{ok, 1}]}.
{attributes, []}.
{labels, 4}.

{function, ok, 1, 3}.
  {label, 2}.
    {line, [{location, "http__t__response.erl", 1}]}.
    {func_info, {atom, http__t__response}, {atom, ok}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, body}, {y, 0}]}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Response, App} from "http";

fn main() {
    val r = Response.ok("hi");
    @print(r.body);
    val a = App(8080, "/");
    @print(a.port);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 23}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {call_ext, 1, {extfunc, http__t__response, ok, 1}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, body}, {x, 0}]}}.
  {label, 8}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 10}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, port}, {integer, 8080}, {atom, path}, {x, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 22}, [{x, 0}]}.
    {get_map_elements, {f, 22}, {x, 0}, {list, [{atom, port}, {x, 0}]}}.
  {label, 22}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 10}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, '__bp_print', 1, 10}.
  {label, 9}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 10}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 14}.
  {label, 13}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-bp_show_top-'}, 1}.
  {label, 14}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 12}}.

{function, '-bp_show_elem-', 1, 16}.
  {label, 15}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 16}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 12}}.

{function, '__bp_show', 2, 12}.
  {label, 11}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_show'}, 2}.
  {label, 12}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 18}, [{x, 0}]}.
    {test, is_eq, {f, 17}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 17}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 18}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 19}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 16}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 19}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 21}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 20}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 20}, [{x, 0}]}.
    {test, is_ne_exact, {f, 20}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 20}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 20}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 16}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
```

----- RUN LOG -----
```logs
hi
8080
```
