# string_lower_final_sigma

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **Case mapping covers all of Unicode** (decision 443) on the four targets —
> `"straße".toUpper()` is `"STRASSE"`, `"É".toLower()` is `"é"`. Every target
> answers OTP's where a JS engine's differs (decision 521): no final sigma
> (`"ΟΔΟΣ".toLower()` is `"οδοσ"`, where a JS engine answers `"οδος"`).
