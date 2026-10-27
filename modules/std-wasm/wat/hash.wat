;; std-wasm's `hash` leaf (decision 992): the SHA-256 of a file's bytes, which `io.fs`'s `File.hash`
;; answers on wasm. It is the digest of FIPS 180-4 over the bytes of a `$str`, any bytes — the text
;; digests of `hash.bp` take a string and read its code points — and the answer is the lowercase hex
;; text, 64 characters. The leaf is the `std:` cell `hash.sha256Hex`, called as `$__std_hash_sha256Hex`.
;; Its work area (the padded message, the round constants, the schedule and the state) is one
;; allocation put back when it returns.

;; The big-endian word at `p`.
(func $hash.be32 (param $p i32) (result i32)
  local.get $p
  i32.load8_u
  i32.const 24
  i32.shl
  local.get $p
  i32.load8_u offset=1
  i32.const 16
  i32.shl
  i32.or
  local.get $p
  i32.load8_u offset=2
  i32.const 8
  i32.shl
  i32.or
  local.get $p
  i32.load8_u offset=3
  i32.or)

;; `v` as four bytes, big-endian, at `p`.
(func $hash.putBe32 (param $p i32) (param $v i32)
  local.get $p
  local.get $v
  i32.const 24
  i32.shr_u
  i32.store8
  local.get $p
  local.get $v
  i32.const 16
  i32.shr_u
  i32.store8 offset=1
  local.get $p
  local.get $v
  i32.const 8
  i32.shr_u
  i32.store8 offset=2
  local.get $p
  local.get $v
  i32.store8 offset=3)

;; The round constants at `k` and the initial state at `h`.
(func $hash.tables (param $k i32) (param $h i32)
  local.get $k
  i32.const 1116352408
  i32.store offset=0
  local.get $k
  i32.const 1899447441
  i32.store offset=4
  local.get $k
  i32.const -1245643825
  i32.store offset=8
  local.get $k
  i32.const -373957723
  i32.store offset=12
  local.get $k
  i32.const 961987163
  i32.store offset=16
  local.get $k
  i32.const 1508970993
  i32.store offset=20
  local.get $k
  i32.const -1841331548
  i32.store offset=24
  local.get $k
  i32.const -1424204075
  i32.store offset=28
  local.get $k
  i32.const -670586216
  i32.store offset=32
  local.get $k
  i32.const 310598401
  i32.store offset=36
  local.get $k
  i32.const 607225278
  i32.store offset=40
  local.get $k
  i32.const 1426881987
  i32.store offset=44
  local.get $k
  i32.const 1925078388
  i32.store offset=48
  local.get $k
  i32.const -2132889090
  i32.store offset=52
  local.get $k
  i32.const -1680079193
  i32.store offset=56
  local.get $k
  i32.const -1046744716
  i32.store offset=60
  local.get $k
  i32.const -459576895
  i32.store offset=64
  local.get $k
  i32.const -272742522
  i32.store offset=68
  local.get $k
  i32.const 264347078
  i32.store offset=72
  local.get $k
  i32.const 604807628
  i32.store offset=76
  local.get $k
  i32.const 770255983
  i32.store offset=80
  local.get $k
  i32.const 1249150122
  i32.store offset=84
  local.get $k
  i32.const 1555081692
  i32.store offset=88
  local.get $k
  i32.const 1996064986
  i32.store offset=92
  local.get $k
  i32.const -1740746414
  i32.store offset=96
  local.get $k
  i32.const -1473132947
  i32.store offset=100
  local.get $k
  i32.const -1341970488
  i32.store offset=104
  local.get $k
  i32.const -1084653625
  i32.store offset=108
  local.get $k
  i32.const -958395405
  i32.store offset=112
  local.get $k
  i32.const -710438585
  i32.store offset=116
  local.get $k
  i32.const 113926993
  i32.store offset=120
  local.get $k
  i32.const 338241895
  i32.store offset=124
  local.get $k
  i32.const 666307205
  i32.store offset=128
  local.get $k
  i32.const 773529912
  i32.store offset=132
  local.get $k
  i32.const 1294757372
  i32.store offset=136
  local.get $k
  i32.const 1396182291
  i32.store offset=140
  local.get $k
  i32.const 1695183700
  i32.store offset=144
  local.get $k
  i32.const 1986661051
  i32.store offset=148
  local.get $k
  i32.const -2117940946
  i32.store offset=152
  local.get $k
  i32.const -1838011259
  i32.store offset=156
  local.get $k
  i32.const -1564481375
  i32.store offset=160
  local.get $k
  i32.const -1474664885
  i32.store offset=164
  local.get $k
  i32.const -1035236496
  i32.store offset=168
  local.get $k
  i32.const -949202525
  i32.store offset=172
  local.get $k
  i32.const -778901479
  i32.store offset=176
  local.get $k
  i32.const -694614492
  i32.store offset=180
  local.get $k
  i32.const -200395387
  i32.store offset=184
  local.get $k
  i32.const 275423344
  i32.store offset=188
  local.get $k
  i32.const 430227734
  i32.store offset=192
  local.get $k
  i32.const 506948616
  i32.store offset=196
  local.get $k
  i32.const 659060556
  i32.store offset=200
  local.get $k
  i32.const 883997877
  i32.store offset=204
  local.get $k
  i32.const 958139571
  i32.store offset=208
  local.get $k
  i32.const 1322822218
  i32.store offset=212
  local.get $k
  i32.const 1537002063
  i32.store offset=216
  local.get $k
  i32.const 1747873779
  i32.store offset=220
  local.get $k
  i32.const 1955562222
  i32.store offset=224
  local.get $k
  i32.const 2024104815
  i32.store offset=228
  local.get $k
  i32.const -2067236844
  i32.store offset=232
  local.get $k
  i32.const -1933114872
  i32.store offset=236
  local.get $k
  i32.const -1866530822
  i32.store offset=240
  local.get $k
  i32.const -1538233109
  i32.store offset=244
  local.get $k
  i32.const -1090935817
  i32.store offset=248
  local.get $k
  i32.const -965641998
  i32.store offset=252
  local.get $h
  i32.const 1779033703
  i32.store offset=0
  local.get $h
  i32.const -1150833019
  i32.store offset=4
  local.get $h
  i32.const 1013904242
  i32.store offset=8
  local.get $h
  i32.const -1521486534
  i32.store offset=12
  local.get $h
  i32.const 1359893119
  i32.store offset=16
  local.get $h
  i32.const -1694144372
  i32.store offset=20
  local.get $h
  i32.const 528734635
  i32.store offset=24
  local.get $h
  i32.const 1541459225
  i32.store offset=28
)

;; One 64-byte block at `p` into the state at `h`; `w` is the 64-word schedule, `k` the constants.
(func $hash.block (param $h i32) (param $w i32) (param $k i32) (param $p i32)
  (local $t i32)
  (local $x i32)
  (local $a i32)
  (local $b i32)
  (local $c i32)
  (local $d i32)
  (local $e i32)
  (local $f i32)
  (local $g i32)
  (local $hh i32)
  (local $t1 i32)
  (local $t2 i32)
  (block $loaded
    (loop $load
      local.get $t
      i32.const 16
      i32.ge_u
      br_if $loaded
      local.get $w
      local.get $t
      i32.const 2
      i32.shl
      i32.add
      local.get $p
      local.get $t
      i32.const 2
      i32.shl
      i32.add
      call $hash.be32
      i32.store
      local.get $t
      i32.const 1
      i32.add
      local.set $t
      br $load))
  (block $extended
    (loop $extend
      local.get $t
      i32.const 64
      i32.ge_u
      br_if $extended
      local.get $w
      local.get $t
      i32.const 2
      i32.sub
      i32.const 2
      i32.shl
      i32.add
      i32.load
      local.set $x
      local.get $x
      i32.const 17
      i32.rotr
      local.get $x
      i32.const 19
      i32.rotr
      i32.xor
      local.get $x
      i32.const 10
      i32.shr_u
      i32.xor
      local.get $w
      local.get $t
      i32.const 7
      i32.sub
      i32.const 2
      i32.shl
      i32.add
      i32.load
      i32.add
      local.get $w
      local.get $t
      i32.const 15
      i32.sub
      i32.const 2
      i32.shl
      i32.add
      i32.load
      local.set $x
      local.get $x
      i32.const 7
      i32.rotr
      local.get $x
      i32.const 18
      i32.rotr
      i32.xor
      local.get $x
      i32.const 3
      i32.shr_u
      i32.xor
      i32.add
      local.get $w
      local.get $t
      i32.const 16
      i32.sub
      i32.const 2
      i32.shl
      i32.add
      i32.load
      i32.add
      local.set $x
      local.get $w
      local.get $t
      i32.const 2
      i32.shl
      i32.add
      local.get $x
      i32.store
      local.get $t
      i32.const 1
      i32.add
      local.set $t
      br $extend))
  local.get $h
  i32.load
  local.set $a
  local.get $h
  i32.load offset=4
  local.set $b
  local.get $h
  i32.load offset=8
  local.set $c
  local.get $h
  i32.load offset=12
  local.set $d
  local.get $h
  i32.load offset=16
  local.set $e
  local.get $h
  i32.load offset=20
  local.set $f
  local.get $h
  i32.load offset=24
  local.set $g
  local.get $h
  i32.load offset=28
  local.set $hh
  i32.const 0
  local.set $t
  (block $rounded
    (loop $round
      local.get $t
      i32.const 64
      i32.ge_u
      br_if $rounded
      ;; t1 = h + S1(e) + Ch(e, f, g) + K[t] + W[t]
      local.get $hh
      local.get $e
      i32.const 6
      i32.rotr
      local.get $e
      i32.const 11
      i32.rotr
      i32.xor
      local.get $e
      i32.const 25
      i32.rotr
      i32.xor
      i32.add
      local.get $e
      local.get $f
      i32.and
      local.get $e
      i32.const -1
      i32.xor
      local.get $g
      i32.and
      i32.xor
      i32.add
      local.get $k
      local.get $t
      i32.const 2
      i32.shl
      i32.add
      i32.load
      i32.add
      local.get $w
      local.get $t
      i32.const 2
      i32.shl
      i32.add
      i32.load
      i32.add
      local.set $t1
      ;; t2 = S0(a) + Maj(a, b, c)
      local.get $a
      i32.const 2
      i32.rotr
      local.get $a
      i32.const 13
      i32.rotr
      i32.xor
      local.get $a
      i32.const 22
      i32.rotr
      i32.xor
      local.get $a
      local.get $b
      i32.and
      local.get $a
      local.get $c
      i32.and
      i32.xor
      local.get $b
      local.get $c
      i32.and
      i32.xor
      i32.add
      local.set $t2
      local.get $g
      local.set $hh
      local.get $f
      local.set $g
      local.get $e
      local.set $f
      local.get $d
      local.get $t1
      i32.add
      local.set $e
      local.get $c
      local.set $d
      local.get $b
      local.set $c
      local.get $a
      local.set $b
      local.get $t1
      local.get $t2
      i32.add
      local.set $a
      local.get $t
      i32.const 1
      i32.add
      local.set $t
      br $round))
  local.get $h
  local.get $h
  i32.load
  local.get $a
  i32.add
  i32.store
  local.get $h
  local.get $h
  i32.load offset=4
  local.get $b
  i32.add
  i32.store offset=4
  local.get $h
  local.get $h
  i32.load offset=8
  local.get $c
  i32.add
  i32.store offset=8
  local.get $h
  local.get $h
  i32.load offset=12
  local.get $d
  i32.add
  i32.store offset=12
  local.get $h
  local.get $h
  i32.load offset=16
  local.get $e
  i32.add
  i32.store offset=16
  local.get $h
  local.get $h
  i32.load offset=20
  local.get $f
  i32.add
  i32.store offset=20
  local.get $h
  local.get $h
  i32.load offset=24
  local.get $g
  i32.add
  i32.store offset=24
  local.get $h
  local.get $h
  i32.load offset=28
  local.get $hh
  i32.add
  i32.store offset=28)

;; `hash.sha256Hex` — the SHA-256 of the bytes, as 64 lowercase hex characters.
(func $hash.sha256Hex (param $data (ref null $str)) (result (ref null $str))
  (local $mark i32)
  (local $n i32)
  (local $total i32)
  (local $base i32)
  (local $k i32)
  (local $w i32)
  (local $h i32)
  (local $i i32)
  (local $word i32)
  (local $nib i32)
  (local $out (ref null $str))
  global.get $__heap_ptr
  local.set $mark
  local.get $data
  array.len
  local.set $n
  ;; the message, a 1 bit, zeros, and its length in bits as 64 bits: a multiple of 64 bytes
  local.get $n
  i32.const 72
  i32.add
  i32.const -64
  i32.and
  local.set $total
  local.get $total
  i32.const 544
  i32.add
  call $__alloc
  local.set $base
  local.get $base
  local.get $total
  i32.add
  local.set $k
  local.get $k
  i32.const 256
  i32.add
  local.set $w
  local.get $w
  i32.const 256
  i32.add
  local.set $h
  (block $copied
    (loop $copy
      local.get $i
      local.get $n
      i32.ge_u
      br_if $copied
      local.get $base
      local.get $i
      i32.add
      local.get $data
      local.get $i
      array.get_u $str
      i32.store8
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br $copy))
  local.get $base
  local.get $n
  i32.add
  i32.const 0
  local.get $total
  local.get $n
  i32.sub
  memory.fill
  local.get $base
  local.get $n
  i32.add
  i32.const 128
  i32.store8
  local.get $base
  local.get $total
  i32.add
  i32.const -8
  i32.add
  local.get $n
  i32.const 29
  i32.shr_u
  call $hash.putBe32
  local.get $base
  local.get $total
  i32.add
  i32.const -4
  i32.add
  local.get $n
  i32.const 3
  i32.shl
  call $hash.putBe32
  local.get $k
  local.get $h
  call $hash.tables
  i32.const 0
  local.set $i
  (block $done
    (loop $blocks
      local.get $i
      local.get $total
      i32.ge_u
      br_if $done
      local.get $h
      local.get $w
      local.get $k
      local.get $base
      local.get $i
      i32.add
      call $hash.block
      local.get $i
      i32.const 64
      i32.add
      local.set $i
      br $blocks))
  ;; the state as hex
  i32.const 64
  array.new_default $str
  local.set $out
  i32.const 0
  local.set $i
  (block $hexed
    (loop $hex
      local.get $i
      i32.const 64
      i32.ge_u
      br_if $hexed
      local.get $h
      local.get $i
      i32.const 3
      i32.shr_u
      i32.const 2
      i32.shl
      i32.add
      i32.load
      local.set $word
      local.get $word
      i32.const 28
      local.get $i
      i32.const 7
      i32.and
      i32.const 2
      i32.shl
      i32.sub
      i32.shr_u
      i32.const 15
      i32.and
      local.set $nib
      local.get $out
      local.get $i
      local.get $nib
      i32.const 48
      i32.add
      local.get $nib
      i32.const 87
      i32.add
      local.get $nib
      i32.const 10
      i32.lt_u
      select
      array.set $str
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br $hex))
  local.get $mark
  global.set $__heap_ptr
  local.get $out)
