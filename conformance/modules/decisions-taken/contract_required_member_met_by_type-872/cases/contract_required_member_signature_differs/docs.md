# contract_required_member_signature_differs

Decision 872 (2): the member a type supplies to an extension block's contract is compared with the
contract's as any implementor's (decision 800). A one-parameter `slice` is not met by `string`'s
`slice(self: Self, start: i32, end: ?i32 = null)`: refused at the block, `implement-signature-differs`.
