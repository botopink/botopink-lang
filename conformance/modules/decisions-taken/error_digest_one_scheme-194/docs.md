# Decision 194 — One error-digest scheme with one implementation: the first 16 hex of `strongHash` over `module|errorClass|message|top

The example hits one fault twice. In the second hit the line numbers differ (`order.bp:12` against `order.bp:15`) and there is a fourth frame, `server.bp:40`. `topFramesOf` prints what the scheme keeps of those frames: the first three, with their line numbers stripped (`order.bp render.bp page.bp`). Both calls therefore hash the same text. The second line prints `16 true false`: the digest is sixteen hex characters, the two hits share it, and a fault of another class (`badmatch`) gets another one. The digest names the fault, not one occurrence of it.

The last line is the one call that logs the fault and answers its digest at once. `Logger.logError` writes the error record and returns the same digest `errorDigest` computed, so `shown == first` prints `true`, and a fallback page shows the digest the log line carries. The program computes the digest nowhere else. `log`'s function is the one implementation.

Cells in this repository that also bear on it: none. The digest lives in the `log` library, and its known-answer fixture is `log`'s.

[draft/main.bp](draft/main.bp)
