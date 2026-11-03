# ten_million_allocations

Ten million short-lived strings — the number's text and three concatenations per iteration, two and a half million
iterations — of which only the lengths are kept, printing `48888890` on every target. On wasm the collector frees each
iteration's strings, so the loop's memory does not grow with its length.
