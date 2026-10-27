----- SOURCE CODE -- main.bp
```botopink
type ParseError(msg: string)
val Parser = type() {
    fn parse(self: Self) -> Result<i32, ParseError> {
        throw ParseError(msg: "bad input");
    }
}
fn run(p: Parser) -> i32 {
    val result = try p.parse() catch 0;
    return result;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
  )
  (rec
    (type $rec_ParseError (struct (field $f0 (mut (ref null $str)))))
    (type $brand_rec_ParseError (struct (field f64) (field i32) (field f32) (field f32) (field f32) (field i64) (field f32) (field f64) (field f64) (field i64) (field f32) (field i32) (field i32) (field f32) (field i64) (field f64) (field i64) (field f64) (field f64) (field f32) (field f32) (field i32) (field f32) (field i64) (field f64) (field f32) (field i32) (field f64) (field f32) (field f64) (field f32) (field i64)))
  )
  (rec
    (type $rec_Parser (struct))
    (type $brand_rec_Parser (struct (field f32) (field f64) (field f32) (field f64) (field i32) (field f32) (field f64) (field f32) (field f64) (field i64) (field i32) (field f32) (field i64) (field f32) (field i64) (field f32) (field f64) (field i32) (field i32) (field f64) (field f32) (field f32) (field f32) (field f64) (field f32) (field i32) (field i64) (field f64) (field i32) (field i32) (field i64) (field i32)))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $Parser_parse (param $self (ref null $rec_Parser)) (result (ref null $result))
    (local $__mem0 i32)
    i32.const 1
    global.get $__s0
    struct.new $rec_ParseError
    struct.new $result
    return
  )
  (func $run (param $p (ref null $rec_Parser)) (result i32)
    (local $_try0 i32)
    (local $result i32)
    (local $__gc0 (ref null $result))
    local.get $p
    call $Parser_parse
    local.set $__gc0
    local.get $__gc0
    struct.get $result $tag ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $__gc0
    struct.get $result $payload ;; Ok payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
      )
    )
    local.set $result
    local.get $result
    return
  )
  (data $__d0 "bad input")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 9
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
