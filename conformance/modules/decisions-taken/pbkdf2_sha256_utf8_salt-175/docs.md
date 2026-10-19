# Decision 175 — † `hash.pbkdf2Sha256(password, salt, iterations, length)` derives over the salt's UTF-8 bytes, the same on node and erla

The example derives three keys with `hash.pbkdf2Sha256`. RFC 6070's inputs, `("password", "salt", 1, 32)`, give `Eg-2z_z4syxD5yJSVsT4N6hlSMkszDVICAWYfLcL4Xs` on every target. The salt `sålt` is derived over its UTF-8 bytes, where `å` is two bytes, and also gives one answer everywhere. The salt `c2FsdA`, which is `salt` in base64, is derived over its six characters and not over the bytes it encodes, so its key differs from the key for `salt` and the comparison prints `false`.

Cells in this repository that also bear on it: `modules/std_hash_on_every_target`.

[draft/main.bp](draft/main.bp)
