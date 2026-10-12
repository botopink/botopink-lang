# decimal_div_rounding_necessary_aborts

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> **Exact decimals.** std's `decimal` is Java's `BigDecimal` (decision 332): a
> `Decimal` is an unscaled `bigint` and a `scale`, the value `unscaled × 10^-scale`
> (`Decimal(unscaled: 150n, scale: 2)` is `1.50`). `add`, `sub` and `mul` are
> exact — the sum's scale is the larger of the two, the product's their sum;
> `div(other, scale, rounding)` answers at the scale it is given, rounded by a
> `Rounding` — `Up`, `Down`, `Ceiling`, `Floor`, `HalfUp`, `HalfDown`, `HalfEven`,
> Java's `RoundingMode` — and has no form without them; `Unnecessary` asserts the
> quotient is exact, and an inexact one aborts (`Decimal.div: rounding
> necessary`), as a zero divisor does (`Decimal.div: division by zero`).
> `compare(other)` is `-1`, `0` or `1` by numeric value, whatever the scales
> (`1.0` against `1.00` is `0`); `toString()` writes the plain text with the scale
> kept (`"1.00"`, `"100"` for a negative scale, never an exponent); and
> `Decimal.parse(text)` reads a numeral — an optional sign, digits, an optional
> `.` with digits, an optional exponent — into its scale (`"1.50"` is scale 2,
> `"1E+2"` scale −2), anything else an `Error` naming the text. Pure botopink over
> `bigint`: one answer on the four targets.
