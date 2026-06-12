----- SOURCE CODE -- http.bp
```botopink
pub record Response {
    body: string,
    fn ok(body: string) -> Response {
        return Response(body: body);
    }
}

pub record App {
    port: i32,
    path: string,
}
```

----- BEAM ASSEMBLY -- http.S
```erlang
{module, http}.
{exports, [{'Response_ok', 1}]}.
{attributes, []}.
{labels, 4}.

{function, 'Response_ok', 1, 3}.
  {label, 2}.
    {line, [{location, "http.erl", 1}]}.
    {func_info, {atom, http}, {atom, 'Response_ok'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {x, 0}, {x, 1}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 2, {list, [{atom, body}, {x, 1}]}}.
    {deallocate, 0}.
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
{labels, 10}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, http, 'Response_ok', 1}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 8}, [{x, 0}]}.
    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, body}, {x, 0}]}}.
  {label, 8}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {integer, 8080}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 3, {list, [{atom, port}, {x, 1}, {atom, path}, {x, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 9}, [{x, 0}]}.
    {get_map_elements, {f, 9}, {x, 0}, {list, [{atom, port}, {x, 0}]}}.
  {label, 9}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
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
```

----- RUN LOG -----
```logs
<<"hi">>
8080
```
