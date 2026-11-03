# request_loop

A server's request loop: a hundred thousand request lines, each parsed (`split`, a record) and answered (`join`,
`toUpper`, concatenation, the length's text), only the sum of the responses' lengths kept, printing `3488890` on
every target. On wasm a request's values are collected once it is answered.
