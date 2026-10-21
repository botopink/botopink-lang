# Decision 886 — A type's own method meets an extension block's contract only when it is `pub` or the block is in the method's module; else `method-not-pub` at the block, naming the type, the method and the module; narrows 872 (2), keeps 859 (2).

A type's own method meets an extension block's contract when it is `pub`, or when the block is written in the method's module. A block in another module whose contract a private method would meet is refused at the block, `method-not-pub`, naming the type, the method and the module.

[cells/contract_member_not_pub_at_block/src/main.bp](cells/contract_member_not_pub_at_block/src/main.bp)
[cells/contract_member_pub_or_same_module/src/main.bp](cells/contract_member_pub_or_same_module/src/main.bp)
