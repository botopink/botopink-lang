# contract_member_pub_or_same_module

Decision 886 (1): a `pub` method meets an extension block's contract from another module (`Box.label`,
the block in `main.bp`), and a private one meets it from a block in its own module (`Crate.label`, the
block in `box.bp`). The program runs.
