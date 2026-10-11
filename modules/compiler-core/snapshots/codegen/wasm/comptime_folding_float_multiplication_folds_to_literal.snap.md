----- SOURCE CODE -- main.bp
```botopink
val pi2 = comptime {
    break 3.14 * 2.0;
};
fn main() {
    @print(pi2);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val pi2 = comptime {
          break 3.14 * 2.0;
      } → 6.28
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 2272))
  (global $pi2 f64 (f64.const 6.28))
  (func $main
    global.get $pi2
    call $__print_f64
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
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
  (func $__print_f64 (param $x f64)
    local.get $x
    call $__print_f64_raw
    call $__print_nl
  )
  (func $__print_f64_raw (param $x f64)
    (local $s i32)
    local.get $x
    call $__std_number_floatToString
    local.set $s
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 2272))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 1444
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  (data (i32.const 256) "-Infinity\00nan\00inf\000123456789abcdef\00NaN\00-0.0\00\06\00\00\00\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f0\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\02\13\03\03\03\03\03\03\03\03\03\03\03\03#\03\034\04\04\04D\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\f1\00\00\01\00\00\00\02\00\00\00\03\00\00\00\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\05\00\00\00\00\00\00\00\19\00\00\00\00\00\00\00}\00\00\00\00\00\00\00q\02\00\00\00\00\00\005\0c\00\00\00\00\00\00\t=\00\00\00\00\00\00-1\01\00\00\00\00\00\e1\f5\05\00\00\00\00\00e\cd\1d\00\00\00\00\00\f9\02\95\00\00\00\00\00\dd\0e\e9\02\00\00\00\00QJ\8d\0e\00\00\00\00\95s\c2H\00\00\00\00\e9A\cck\01\00\00\00\8dI\fd\1a\07\00\00\00\c1o\f2\86#\00\00\00\c5.\bc\a2\b1\00\00\00\d9\e9\ac-x\03\00\00=\91`\e4X\11\00\001\d6\e2u\bcV\00\00\f5.nM\ae\b1\01\00\c9\ea&\83gx\08\00\ed\95\c2\8f\05Z*\00\a1\ed\cc\ce\1b\c2\d3\00%\a4\00\n\8b\ca\"\04\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00@\95YiYUUTU\15UUV\04\05\15A\10TU@EQUD@EPDPUUE\00@\00@@\04D\96eUVUE@ETQA\15@U\91UUUU@Q\05\01\00\00TETTEU\05\04\00\10\04\10\14\04@\00\00\00\01@UU\15AT\04\00\00D\00\01\00\00\00\00@A\00\00DPDEPT\00UUTUeQ\00@\00@\01\00\00\01\00\05\01\00\11TQQTUU\05\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00 4Pe\c0_\c9\a6R\bb\13\cb\ae\c4@\c2\18\06\c8\dfq\00\d5\a8|\f5o\0f\daX\fc'\13nGV5}$ e\02\c7\e7h\e4\8c\a4\1d\e9\e6\02h\d7\cd9ayw\fc\c2@[\ef\16y\8c\deC\ff\a7Q\f9\91\f3\b2x\f5\bd\be\11\e8W\e9\d6\e8\be\e8{\b0T\ac\8f\84\8du\1b\ea#\a4\99\e9\f9\d3\8b\b7\a3q@a\da>\15\ce\e3>\cbs\f9H\08\8c\97\b4'\d5\1bp\10\a2\bf\ef\b9\eb\852\15M\b4M\b4\9b\bbo\19\96\b6\07l\f8\e7\ee\ad6\d9\b4\f5\915\ae\13\"\"\18\afNjhM\91\da\aa=O@t\1e\9f\bd\9e\e0\06\a1\c0\98W\c2\a7\fd\a4\0e\90\17\0e}Iqs\e3 \8f\b2 \d8v\05\14;\12\85=t4\81\13C\b0\ad)z_'\f45\1c\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\10\00\00\00\00\00\00\00\00\b94\032\b7\f4\ad\14\10\db\1a\b3\08\92T\0e\r0}\95\14G\ba\1af\08\8fM&\ad\c6m\f5\98\bf\85\e2\b7E\11\ca\96\85=\92\bd\1d\eb\fc\a1\18`\dc\efR\16<\92\ae\"\0b\b8\c1\b4\83\9d-[\05b\da\1c0L~\8fN\8b\b2[\16\f4R\9f\8bV\a5\12\fb\d4\82vC\ed\8a\f0\8f\e7\f91\15e\19\18P\f1\9b\d9J\13\ee\b4(L\f0\a6\86\c1%\1f\03_\c2p\cb\9eI\16\e6B\88\9cD\eb \14\b0e\086\adn\a5\85\85\f0\ca\14\e2\fd\03\1a\0b\89\99y\d5\b1=\t\d8\da\97:5\eb\cf\10\ac6?^s\bb8\cf>gR\faD\af\ba\15")
  ;; __std_f3 — from std_wasm.wasm (sha256 b4b6f06748d6)
  ;; std:number.floatToString — from std_wasm.wasm (sha256 9d7878a94c98)
  ;; __std_f75 — from std_wasm.wasm (sha256 aba5f076b057)
  ;; __std_f93 — from std_wasm.wasm (sha256 a8fb72202472)
  ;; __std_f99 — from std_wasm.wasm (sha256 dabd4cf8aba0)
  ;; __std_f100 — from std_wasm.wasm (sha256 9b6ec601b8aa)
  ;; __std_f101 — from std_wasm.wasm (sha256 965ca1fa4736)
  ;; __std_f102 — from std_wasm.wasm (sha256 a906c53b0497)
  ;; __std_f103 — from std_wasm.wasm (sha256 440c634a9e36)
  ;; __std_f104 — from std_wasm.wasm (sha256 4fb15f2ddd47)
  ;; __std_f109 — from std_wasm.wasm (sha256 4c40dff46753)
  ;; __std_f110 — from std_wasm.wasm (sha256 4d190b081720)
  ;; __std_f111 — from std_wasm.wasm (sha256 94fc71de7e06)
)
```

----- RUN LOG -----
```logs
6.28
```
