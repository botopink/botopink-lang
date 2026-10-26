# contract_block_method_on_array_wasm

Decisions 799, 872: inside a method of an extension block over `array<string>`, `self.join(…)` and
`self.length.toString()` resolve, and `self.toString()` on a primitive `self` resolves. The program runs on every target.
