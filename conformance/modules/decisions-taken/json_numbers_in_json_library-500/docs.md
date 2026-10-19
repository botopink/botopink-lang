# Decision 500 — `json` leaves std first (142 s1); `Json`'s numbers land in the json repository, `Decimal` stays in std.

The decision splits one change in two: `Json`'s numbers (`Int`, `BigInt`, `Dec` in place of `Num`) belong to the `json` library, which left std whole, and the exact decimal they decode into stays in std. This program is std's half. It imports `Decimal` from std's `decimal` module, parses three prices, and prints `1.50` — the scale as written, kept —, the sum `4.00`, and `0` for the sum comparing equal to `4.00`. It imports nothing JSON from std, because std has no JSON: `import {json} from "std"` is an unknown module, and a program decoding JSON numbers imports `Json`, `decode` and `encode` from `"json"`, where `Dec(value: Decimal)` carries this very type.

[draft/main.bp](draft/main.bp)
