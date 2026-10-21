# Decision 142 — `json.decode` converts a numeral exactly, in botopink

The example decodes one numeral per line and prints the `f64` the document holds. The first two numerals sit on the fast path: `0.1` and `123456789012345e-22` have at most fifteen significant digits and a power of ten inside -22…22, so one exact division rounds once and prints `0.1` and `1.23456789012345e-8`. The next four lie past it, and the exact fraction of big integers decides each one. `1e23` prints `1.0e23` and not its neighbour `9.999999999999999e22`. `9007199254740993` sits halfway between two `f64`s and goes to the even one, `9.007199254740992e15`. `2.2250738585072014e-308` is the least normal number and `1.7976931348623157e308` the largest finite one, and both print back unchanged. On the subnormal grid, `5e-324` is the least subnormal (`5.0e-324`), and `2e-324`, below half of it, is `0.0`. `1.8e308` is past the largest finite value, so it is refused with `number overflows f64` and never becomes `Infinity`.

The digits are read and divided by botopink code, in 15-bit limbs whose products stay below 2^31, and the result is assembled without an integer-to-float conversion. That is why every target prints the same nine lines and no host `strtod` is called. The import is `from "json"`: the reader now belongs to the `json` library (396, 500), and std knows nothing of JSON.

Cells in this repository that also bear on it: none. std's `json.bp` keeps its own inline test of the boundaries until it moves to the `json` repository.

[draft/main.bp](draft/main.bp)
