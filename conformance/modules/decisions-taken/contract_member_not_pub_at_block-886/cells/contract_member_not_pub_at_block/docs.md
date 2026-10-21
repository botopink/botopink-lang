# contract_member_not_pub_at_block

Decision 886 (1): `Box.label` is written without `pub` in `box.bp`; `BoxShout implement Shout for Box {}`
in `main.bp` would meet `Shout`'s `label` with it. Refused at the block, `method-not-pub`, naming `Box`,
`label` and `box`.
