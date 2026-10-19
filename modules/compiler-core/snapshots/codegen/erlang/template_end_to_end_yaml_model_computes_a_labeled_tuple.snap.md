----- SOURCE CODE -- main.bp
```botopink
pub fn conf(syntax q: string) -> anyvalue {
    val t = compiler.text(q);
    val port = 8000 + t.length;
    val debug = true;
    return #(port, debug);
}
val cfg = conf @`yaml`;
fn main() {
    print(cfg.port + 1);
}
import {compiler} from "std";

import {io.terminal.print} from "std";
```

----- COMPTIME WAT -- template conf
```wat
(func $conf/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  call $bp_comptime_template:text/1
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s1
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $s0
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $s1
  local.set $s2
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 2
  call $rt_int
  i64.const 27
  call $rt_int
  local.get $s2
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s2
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $s0
  local.get $s1
  call $rt_raise
  drop
  br $raise
  )
  br $L3
  )
  local.set $s0
  (block $L8
  (block $L7
  local.get $s0
  local.set $s1
  br $L8
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  i64.const 8000
  call $rt_int
  local.get $s1
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 6
  call $rt_atom
  call $bp_comptime_template:__bp_len/2
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L10
  (block $L9
  local.get $s0
  local.set $s1
  br $L10
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 4
  call $rt_atom
  local.set $s0
  (block $L12
  (block $L11
  local.get $s0
  local.set $s2
  br $L12
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  i32.const 1
  call $rt_tuple
  local.set $s0
  local.get $s0
  i32.const 0
  i32.const 2
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  local.get $s1
  call $rt_tset
  drop
  local.get $s3
  i32.const 1
  local.get $s2
  call $rt_tset
  drop
  local.get $s3
  call $rt_tset
  drop
  local.get $s0
  local.set $s0
  (block $L13 (result i32)
  (block $L14
  local.get $s0
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L14
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s1
  local.get $s1
  local.set $s1
  (block $L15 (result i32)
  (block $L16
  local.get $s1
  call $bp_comptime_template:expr/1
  call $rt_pending
  br_if $L16
  br $L15
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L17 (result i32)
  (block $L18
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L18
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 12
  call $rt_int
  local.get $s3
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L17
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L15
  )
  br $L13
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     '__bp_capture' => <<"q">>,
;;     text => <<"yaml">>,
;;     source => #{file => <<"main.bp">>, line => 7, col => 16},
;;     context => #{
;;         source => #{file => <<"main.bp">>, line => 7, col => 16},
;;         text => <<"yaml">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"yaml">>],
;;     name => <<"yaml">>
;; }
```

----- COMPTIME REPLY -- template conf
```json
{
  "kind": "value",
  "value": {
    "$tuple": [
      8004,
      true
    ]
  }
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, cfg/0]).

cfg() ->
    {8004, true}.

main() ->
    '__bp_print'(['__bp_int'((erlang:element(1, cfg()) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:9:20">>)]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
8005
```
