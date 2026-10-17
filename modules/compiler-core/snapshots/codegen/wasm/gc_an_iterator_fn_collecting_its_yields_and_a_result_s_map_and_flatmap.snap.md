----- SOURCE CODE -- main.bp
```botopink
fn evens(n: i32) -> @Iterator<i32> {
    var i = 0;
    while (i < n) {
        if (i % 2 == 0) yield i;
        i = i + 1;
    }
}

fn parse(s: string) -> @Result<i32, string> {
    if (s == "") throw "empty";
    return s.length();
}

pub fn main() {
    for (evens(7)) { v -> @print(v); }
    @print(parse("abc").map({ n -> n * 10 }).unwrapOr(-1));
    @print(parse("").map({ n -> n * 10 }).unwrapOr(-1));
    @print(parse("ab").flatMap({ n -> parse("xyz") }).unwrapOr(-1));
    @print(parse("ab").flatMap({ n -> parse("") }).isError());
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $box_i32 (struct (field $v i32)))
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut i32)) (field $s1 (mut i32)) (field $s2 (mut i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; @Iterator — a generator state machine (decision 105)
  (func $evens (param $n i32) (result (ref null $gen))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $n
    struct.set $frame0 $s0
    i32.const 0 ;; live
    i32.const 4 ;; evens__body
    local.get $__fr
    ref.null any
    ref.null $gen
    ref.null any ;; the environment
    i32.const 0
    struct.new $gen ;; runs nothing until its first next
  )
  (func $evens__body (param $__gen (ref null $gen)) (result i32)
    (local $n i32)
    (local $i i32)
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    (local $__cnd0 i32)
    local.get $__gen
    struct.get $gen $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $s0
    local.set $n
    local.get $__frame
    struct.get $frame0 $s1
    local.set $i
    local.get $__frame
    struct.get $frame0 $s2
    local.set $__cnd0
    local.get $__frame
    struct.get $frame0 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    i32.const 0
    local.set $i
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__break
      (loop $__continue
    local.get $__seek
    (if (result i32)
      (then
    i32.const 1 ;; re-entering: inside an iteration
      )
      (else
    local.get $i
    local.get $n
    i32.lt_s
      )
    )
        i32.eqz
        br_if $__break
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $i
    i32.const 2
    global.get $__s0
    call $__i32_nz
    i32.rem_s
    i32.const 0
    i32.eq
    local.tee $__cnd0
      )
    )
    (if (result (ref null $gen))
      (then
    (block $__yd1
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 1
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
      )
    )
    br $__yd1 ;; resumed after this yield, or seeking past it
      )
    )
    local.get $__gen
    local.get $i
    struct.new $box_i32
    struct.set $gen $value ;; the yitem
    local.get $__frame
    local.get $n
    struct.set $frame0 $s0
    local.get $__frame
    local.get $i
    struct.set $frame0 $s1
    local.get $__frame
    local.get $__cnd0
    struct.set $frame0 $s2
    local.get $__frame
    i32.const 1
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    return ;; an yitem
    )
    ref.null $gen
      )
      (else
        ref.null $gen
      )
    )
    drop
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $i
    i32.const 1
    global.get $__s1
    call $__i32_add_chk
    local.set $i
      )
    )
        br $__continue
      )
    )
    i32.const 0
    drop
      )
    )
    i32.const 0 ;; the sequence ended
  )
  (func $parse (param $s (ref null $str)) (result (ref null $result))
    local.get $s
    global.get $__s2
    call $__str_eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s3
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    local.get $s
    call $__std_text_length
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $main (export "main")
    (local $v i32)
    (local $__gfor0 (ref null $gen))
    (local $__gc0 (ref null $result))
    (local $__gc1 (ref null $result))
    (local $n i32)
    (local $__gc2 (ref null $result))
    (local $__gc3 (ref null $result))
    (local $__gc4 (ref null $result))
    (local $__gc5 (ref null $result))
    (local $__gc6 (ref null $result))
    i32.const 7
    call $evens
    local.set $__gfor0
    (block $__break
      (loop $__continue
    local.get $__gfor0
    call $__gen_next ;; the next yitem
    i32.eqz
    br_if $__break
    local.get $__gfor0
    struct.get $gen $value
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $v
    local.get $v
    call $__print_i32
    br $__continue
      )
    )
    i32.const 0
    drop
    global.get $__s4
    call $parse
    local.set $__gc1
    local.get $__gc1
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__gc1
      )
      (else
    local.get $__gc1
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    i32.const 10
    global.get $__s5
    call $__i32_mul_chk
    struct.new $box_i32
    struct.new $result
      )
    )
    local.tee $__gc0
    struct.get $result $tag
    (if (result i32)
      (then
    i32.const 0
    i32.const 1
    global.get $__s6
    call $__i32_sub_chk
      )
      (else
    local.get $__gc0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
      )
    )
    call $__print_i32
    global.get $__s2
    call $parse
    local.set $__gc3
    local.get $__gc3
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__gc3
      )
      (else
    local.get $__gc3
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    i32.const 0
    local.get $n
    i32.const 10
    global.get $__s7
    call $__i32_mul_chk
    struct.new $box_i32
    struct.new $result
      )
    )
    local.tee $__gc2
    struct.get $result $tag
    (if (result i32)
      (then
    i32.const 0
    i32.const 1
    global.get $__s8
    call $__i32_sub_chk
      )
      (else
    local.get $__gc2
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
      )
    )
    call $__print_i32
    global.get $__s9
    call $parse
    local.set $__gc5
    local.get $__gc5
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__gc5
      )
      (else
    local.get $__gc5
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    global.get $__s10
    call $parse
      )
    )
    local.tee $__gc4
    struct.get $result $tag
    (if (result i32)
      (then
    i32.const 0
    i32.const 1
    global.get $__s11
    call $__i32_sub_chk
      )
      (else
    local.get $__gc4
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
      )
    )
    call $__print_i32
    global.get $__s9
    call $parse
    local.set $__gc6
    local.get $__gc6
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__gc6
      )
      (else
    local.get $__gc6
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $n
    global.get $__s2
    call $parse
      )
    )
    struct.get $result $tag
    i32.const 0
    i32.ne
    call $__print_bool
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__gen_next (param $g (ref null $gen)) (result i32)
    (local $r i32)
    local.get $g
    struct.get $gen $state
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    call $__gen_resume
    local.tee $r
    i32.eqz
    (if
      (then
    local.get $g
    i32.const 1
    struct.set $gen $state ;; ended
    local.get $g
    ref.null struct
    struct.set $gen $frame ;; its frame dropped
      )
    )
    local.get $r
  )
  (func $__gen_resume (param $g (ref null $gen)) (result i32)
    (local $k i32)
    local.get $g
    struct.get $gen $kind
    local.set $k
    local.get $k
    i32.const 0
    i32.eq
    (if
      (then
    local.get $g
    struct.get $gen $left
    i32.const 0
    i32.le_s
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $left
    i32.const 1
    i32.sub
    struct.set $gen $left
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $src
    struct.get $gen $value
    struct.set $gen $value
    i32.const 1
    return
      )
    )
    local.get $k
    i32.const 1
    i32.eq
    (if
      (then
    (block $__break
      (loop $__continue
    local.get $g
    struct.get $gen $left
    i32.const 0
    i32.le_s
    br_if $__break
    local.get $g
    local.get $g
    struct.get $gen $left
    i32.const 1
    i32.sub
    struct.set $gen $left
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    br $__continue
      )
    )
    local.get $g
    struct.get $gen $src
    call $__gen_next
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $g
    local.get $g
    struct.get $gen $src
    struct.get $gen $value
    struct.set $gen $value
    i32.const 1
    return
      )
    )
    local.get $k
    i32.const 4
    i32.eq
    (if
      (then
    local.get $g
    call $evens__body
    return
      )
    )
    unreachable
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
  (func $__print_bool (param $b i32)
    local.get $b
    call $__print_bool_raw
    call $__print_nl
  )
  (func $__print_bool_raw (param $b i32)
    local.get $b
    (if
      (then
        ;; "true" as a little-endian i32
        i32.const 16
        i32.const 1702195828
        i32.store
        i32.const 16
        i32.const 4
        call $__write_bytes
      )
      (else
        ;; "fals" + 'e'
        i32.const 16
        i32.const 1936482662
        i32.store
        i32.const 16
        i32.const 101
        i32.store8 offset=4
        i32.const 16
        i32.const 5
        call $__write_bytes
      )
    )
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
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
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__i32_divs (param $a i32) (param $b i32) (param $site (ref null $str)) (param $osite (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i32.const -2147483648
    i32.eq
    local.get $b
    i32.const -1
    i32.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i32.div_s
  )
  (func $__i64_divs (param $a i64) (param $b i64) (param $site (ref null $str)) (param $osite (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    i64.const -9223372036854775808
    i64.eq
    local.get $b
    i64.const -1
    i64.eq
    i32.and
    (if
      (then
        local.get $osite
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.div_s
  )
  (func $__i32_nz (param $b i32) (param $site (ref null $str)) (result i32)
    local.get $b
    i32.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  (func $__i64_nz (param $b i64) (param $site (ref null $str)) (result i64)
    local.get $b
    i64.eqz
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $b
  )
  ;; std-wasm's .wat leaves (front 164 s3)
  (func $__std_text_length (param $s (ref null $str)) (result i32)
    (local $i i32)
    (local $len i32)
    (local $n i32)
    local.get $s
    array.len
    local.set $len
    (block $done
      (loop $next
        local.get $i
        local.get $len
        i32.ge_u
        br_if $done
        local.get $s
        local.get $i
        array.get_u $str
        i32.const 0xC0
        i32.and
        i32.const 0x80
        i32.ne
        local.get $n
        i32.add
        local.set $n
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $next
      )
    )
    local.get $n
  )
  (data $__d0 "integer division by zero: % on i32 at main.bp:4:15")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "integer overflow: + on i32 at main.bp:5:15")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "empty")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "abc")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "integer overflow: * on i32 at main.bp:16:38")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "integer overflow: - on i32 at main.bp:16:55")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer overflow: * on i32 at main.bp:17:35")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "integer overflow: - on i32 at main.bp:17:52")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "ab")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "xyz")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "integer overflow: - on i32 at main.bp:18:64")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 50
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 42
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 0
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 5
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 3
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 43
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 43
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 43
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 43
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 2
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 3
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 43
    array.new_data $str $__d11
    global.set $__s11
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
0
2
4
6
30
-1
3
true
```
