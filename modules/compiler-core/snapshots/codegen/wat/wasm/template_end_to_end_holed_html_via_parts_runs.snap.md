----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
    var acc = "\"\"";
    for (q.parts()) { p ->
        if (p.kind == "Text") {
            acc = acc + " + \"" + p.text + "\"";
        };
        if (p.kind == "Interp") {
            acc = acc + " + " + p.code;
        };
    };
    return q.build(acc);
}
val name = "world";
val page = html """<p>${name}</p>""";
fn main() {
    @print(page);
}
```

----- COMPTIME WAT -- template html
```wat
(func $html/1 (param $a0 i32) (result i32)
  (local $V_Q i32) (local $t1 i32) (local $V_Acc i32) (local $t2 i32) (local $t3 i32) (local $V_Acc@6 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Q
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 2
  call $rt_bin
  local.set $t1
  (block $L4
  (block $L3
  local.get $t1
  local.set $V_Acc
  br $L4
  )
  local.get $t1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t1
  drop
  call $rt_nil
  local.set $t2
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $t2
  call $rt_make_fun
  local.get $V_Acc
  local.get $V_Q
  call $bp_comptime_template:parts/1
  call $rt_pending
  br_if $raise
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $t3
  (block $L6
  (block $L5
  local.get $t3
  local.set $V_Acc@6
  br $L6
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  local.get $V_Q
  local.get $V_Acc@6
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $raise
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

(func $fun1:html/1 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_P i32) (local $V_Acc@1 i32) (local $t1 i32) (local $t2 i32) (local $V_Acc@2 i32) (local $t3 i32) (local $V_Acc@3 i32) (local $t4 i32) (local $t5 i32) (local $V_Acc@4 i32) (local $t6 i32) (local $V_Acc@5 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_P
  local.get $a1
  local.set $V_Acc@1
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $V_Acc@1
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $t2
  (block $L6
  (block $L5
  local.get $t2
  local.set $V_Acc@2
  br $L6
  )
  local.get $t2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t2
  drop
  local.get $V_Acc@2
  br $L3
  )
  (block $L7
  local.get $V_Acc@1
  br $L3
  )
  local.get $t1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t3
  (block $L9
  (block $L8
  local.get $t3
  local.set $V_Acc@3
  br $L9
  )
  local.get $t3
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t3
  drop
  global.get $__lit
  i32.const 32
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 272
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $t4
  (block $L10 (result i32)
  (block $L11
  local.get $t4
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L11
  local.get $V_Acc@3
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 3
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 96
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_P
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.set $t5
  (block $L13
  (block $L12
  local.get $t5
  local.set $V_Acc@4
  br $L13
  )
  local.get $t5
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t5
  drop
  local.get $V_Acc@4
  br $L10
  )
  (block $L14
  local.get $V_Acc@3
  br $L10
  )
  local.get $t4
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $t6
  (block $L16
  (block $L15
  local.get $t6
  local.set $V_Acc@5
  br $L16
  )
  local.get $t6
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $t6
  drop
  local.get $V_Acc@5
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
;;     text => <<"<p>__bp_hole_q_0</p>">>,
;;     parts => [
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"<p>">>,
;;             span => #{start => 0, 'end' => 3, line => 1}
;;         },
;;         #{
;;             kind => <<"Interp">>,
;;             code => <<"__bp_hole_q_0">>,
;;             span => #{start => 3, 'end' => 16, line => 1}
;;         },
;;         #{
;;             kind => <<"Text">>,
;;             text => <<"</p>">>,
;;             span => #{start => 16, 'end' => 20, line => 1}
;;         }
;;     ],
;;     source => #{file => <<"">>, line => 14, col => 17},
;;     context => #{
;;         source => #{file => <<"">>, line => 14, col => 17},
;;         text => <<"<p>__bp_hole_q_0</p>">>,
;;         multiline => true
;;     },
;;     bindings => [
;;         #{name => <<"html">>, kind => 'Fn'},
;;         #{name => <<"name">>, kind => 'Val'},
;;         #{name => <<"page">>, kind => 'Val'},
;;         #{name => <<"main">>, kind => 'Fn'}
;;     ]
;; }
```

----- COMPTIME REPLY -- template html
```json
{
  "kind": "code",
  "source": "\"\" + \"<p>\" + __bp_hole_q_0 + \"</p>\""
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (start $__init_globals)
  (data (i32.const 256) "\05\00\00\00world")
  (data (i32.const 268) "\00\00\00\00")
  (data (i32.const 272) "\03\00\00\00<p>")
  (data (i32.const 280) "\04\00\00\00</p>")
  (global $__heap_ptr (mut i32) (i32.const 288))
  (global $name (mut i32) (i32.const 256))
  (global $page (mut i32) (i32.const 0))
  (func $main
    global.get $page
    call $__print_str
  )
  (func $__init_globals
    i32.const 268
    i32.const 272
    call $__str_concat
    global.get $name
    call $__str_concat
    i32.const 280
    call $__str_concat
    global.set $page
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   32..64 float fraction   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__print_str_raw (param $s i32)
    local.get $s
    i32.const 256
    i32.lt_u
    (if
      (then
        ;; a pointer below the data floor is not a string
        unreachable
      )
    )
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
  )
  (func $__print_str (param $s i32)
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__str_concat (param $a i32) (param $b i32) (result i32)
    (local $base i32) (local $alen i32) (local $blen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $b
    i32.load
    local.set $blen
    global.get $__heap_ptr
    local.set $base
    ;; bump heap by 4 (length prefix) + alen + blen
    global.get $__heap_ptr
    i32.const 4
    local.get $alen
    i32.add
    local.get $blen
    i32.add
    i32.add
    global.set $__heap_ptr
    ;; store combined length prefix
    local.get $base
    local.get $alen
    local.get $blen
    i32.add
    i32.store
    ;; copy a's bytes: base+4 <- a+4
    local.get $base
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $alen
    memory.copy
    ;; copy b's bytes: base+4+alen <- b+4
    local.get $base
    i32.const 4
    i32.add
    local.get $alen
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $blen
    memory.copy
    local.get $base
  )
)
```

----- RUN LOG -----
```logs
<p>world</p>
```
