----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(expr q: string) -> string {
    val hit = compiler.lookup(q, "greeting");
    if (hit) { b ->
        return compiler.build(b.name);
    } else {
        return compiler.fail("greeting not found in caller scope", at: q);
    };
}
val s = refer @`greeting`;
fn main() {
    @print(s);
}
```

----- COMPTIME WAT -- template refer
```wat
(func $refer/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 8
  call $rt_bin
  call $bp_comptime_template:lookup/2
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 31
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
  br $L5
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L3
  )
  local.set $s1
  (block $L8
  (block $L7
  local.get $s1
  local.set $s2
  br $L8
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s2
  local.set $s1
  (block $L9 (result i32)
  (block $L10
  local.get $s1
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L10
  i32.const 1
  call $rt_tuple
  local.set $s2
  local.get $s2
  i32.const 0
  (block $L11 (result i32)
  (block $L12
  local.get $s0
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 34
  call $rt_bin
  call $bp_comptime_template:fail/2
  call $rt_pending
  br_if $L12
  br $L11
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L13 (result i32)
  (block $L14
  local.get $s3
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 72
  call $rt_int
  local.get $s5
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L13
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L11
  )
  call $rt_tset
  drop
  local.get $s2
  local.set $s2
  (block $L15 (result i32)
  (block $L16
  local.get $s2
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L16
  local.get $s2
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  (block $L17 (result i32)
  (block $L18
  local.get $s3
  call $bp_comptime_template:expr/1
  call $rt_pending
  br_if $L18
  br $L17
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L19 (result i32)
  (block $L20
  local.get $s3
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L20
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 25
  call $rt_int
  local.get $s5
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L19
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L17
  )
  br $L15
  )
  local.get $s2
  call $rt_case_clause
  drop
  br $raise
  )
  br $L9
  )
  (block $L21
  local.get $s1
  local.set $s2
  i32.const 2
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  local.get $s0
  call $rt_tset
  drop
  local.get $s3
  i32.const 1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s2
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s3
  local.set $s0
  (block $L22 (result i32)
  (block $L23
  local.get $s0
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L23
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $s0
  i32.const 1
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  (block $L24 (result i32)
  (block $L25
  local.get $s2
  local.get $s3
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $L25
  br $L24
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L26 (result i32)
  (block $L27
  local.get $s2
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L27
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 25
  call $rt_int
  local.get $s4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L26
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L24
  )
  br $L22
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  br $L9
  )
  local.get $s1
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
;;     text => <<"greeting">>,
;;     source => #{file => <<"">>, line => 10, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 10, col => 15},
;;         text => <<"greeting">>,
;;         multiline => false
;;     },
;;     bindings => [
;;         #{
;;             kind => 'Val',
;;             name => <<"greeting">>,
;;             fields => [],
;;             variants => [],
;;             methods => [],
;;             returnType => <<"">>,
;;             annotations => [],
;;             hooks => [],
;;             params => [],
;;             component => undefined,
;;             module => <<"">>,
;;             owner => undefined,
;;             package => <<"">>,
;;             meta => [],
;;             identity => <<"main@@greeting">>,
;;             local => <<"greeting">>
;;         }
;;     ],
;;     words => [<<"greeting">>]
;; }
```

----- COMPTIME REPLY -- template refer
```json
{
  "kind": "code",
  "source": "greeting"
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, greeting/0, s/0]).

greeting() ->
    <<"ola mundo">>.

s() ->
    greeting().

main() ->
    '__bp_print'([s()]).

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
ola mundo
```
