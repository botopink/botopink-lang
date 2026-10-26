# Decision 259 — wasm's `std/math` agrees with commonJS bit for bit, `pow` included: std ports glibc's `pow` (the algorithm since glibc 2

Every line compares a `math.pow` result with the exact `f64` that commonJS answers on Linux. Every target runs std's
port of glibc's `pow` instead of the platform's libm, so each comparison is `true` on all four. The first line is the
case that told wasm apart: `158.42161580281933` raised to `2.853827476501465` is `1896229.4525711867`, bit for bit.
The second line takes another fractional exponent. The third meets `sqrt`, an operation IEEE 754 makes exact, which
stays a host call (`f64.sqrt` on wasm) and agrees with `pow(2.0, 0.5)`. The last two are a negative base with an
integral exponent, `-512.0`, and `0⁰`, which is `1.0`.

Cells in this repository that also bear on it: `modules/decisions-taken/math_same_bits_every_target-263/cases/std_math_on_every_target`.

[draft/main.bp](draft/main.bp)
