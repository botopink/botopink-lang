# string_lower_final_sigma

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **Case mapping covers all of Unicode** (decision 443) on the four targets —
> `"straße".toUpper()` is `"STRASSE"`, `"É".toLower()` is `"é"`. A wasm program
> answers OTP's where a JS engine's differs: no final sigma (`"ΟΔΟΣ".toLower()`
> is `"οδοσ"` on wasm, erlang and beam, `"οδος"` on commonJS).
