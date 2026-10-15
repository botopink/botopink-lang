;; std-wasm's text leaves (front 164 s3): a string's UTF-8 bytes read where
;; no `.bp` form reaches them. Each function is a `std:` cell's
;; (`#[@External.Wasm(std: "text.<function>")]` in `libs/std/src/primitives.bp`)
;; and the program calls it as `$__std_text_<function>`. A string is the
;; codegen's `$str`, `(array (mut i8))` (decision 549: named, never declared).

;; `String.length` — the code points of `s` (decision 240): every byte that is
;; no continuation byte (`10xxxxxx`) starts one. A string is valid UTF-8.
(func $text.length (param $s (ref null $str)) (result i32)
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
      ;; n += (s[i] & 0xC0) != 0x80
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
  local.get $n)

;; `String.charCodeAt(i)` — the code point at code-point index `i`, `-1` for a
;; negative `i` or one past the text. A sequence's width is read from its lead
;; byte and its bits decoded as they stand; a byte past the end reads as 0.
(func $text.charCodeAt (param $s (ref null $str)) (param $i i32) (result i32)
  (local $len i32)
  (local $p i32)
  (local $b i32)
  (local $w i32)
  (local $cp i32)
  (local $k i32)
  local.get $i
  i32.const 0
  i32.lt_s
  (if
    (then
      i32.const -1
      return
    )
  )
  local.get $s
  array.len
  local.set $len
  (block $done
    (loop $next
      local.get $p
      local.get $len
      i32.ge_u
      br_if $done
      local.get $s
      local.get $p
      array.get_u $str
      local.set $b
      ;; w: 4 from 0xF0, 3 from 0xE0, 2 from 0xC0, else 1
      i32.const 4
      i32.const 3
      i32.const 2
      i32.const 1
      local.get $b
      i32.const 0xC0
      i32.ge_u
      select
      local.get $b
      i32.const 0xE0
      i32.ge_u
      select
      local.get $b
      i32.const 0xF0
      i32.ge_u
      select
      local.set $w
      local.get $i
      i32.eqz
      (if
        (then
          ;; the code point starting at p
          local.get $w
          i32.const 1
          i32.eq
          (if
            (then
              local.get $b
              return
            )
          )
          ;; cp = b & ((0x80 >> w) - 1)
          local.get $b
          i32.const 0x80
          local.get $w
          i32.shr_u
          i32.const 1
          i32.sub
          i32.and
          local.set $cp
          i32.const 1
          local.set $k
          (block $decoded
            (loop $more
              local.get $k
              local.get $w
              i32.ge_u
              br_if $decoded
              ;; cp = (cp << 6) | (s[p + k] & 0x3F), 0 past the end
              local.get $cp
              i32.const 6
              i32.shl
              local.get $p
              local.get $k
              i32.add
              local.get $len
              i32.lt_u
              (if (result i32)
                (then
                  local.get $s
                  local.get $p
                  local.get $k
                  i32.add
                  array.get_u $str
                  i32.const 0x3F
                  i32.and
                )
                (else
                  i32.const 0
                )
              )
              i32.or
              local.set $cp
              local.get $k
              i32.const 1
              i32.add
              local.set $k
              br $more
            )
          )
          local.get $cp
          return
        )
      )
      local.get $i
      i32.const 1
      i32.sub
      local.set $i
      local.get $p
      local.get $w
      i32.add
      local.set $p
      br $next
    )
  )
  i32.const -1)
