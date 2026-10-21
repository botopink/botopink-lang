# Decision 872 — 799 (4) refuses a bodied `default fn` the type already has; a required member the type has is met by the type's own method and compared with the contract's signature.

A contract's required member that the implemented type already has is met by the type's own method — a primitive's (`string`'s `slice`) or a record's — and that method is compared with the contract's member as any implementor's is (decision 800): a contract's `fn slice(self: Self, start: i32) -> string;` is not met by `string`'s two-parameter `slice`, refused at the block, `implement-signature-differs`. A bodied `default fn` the type already has stays `behavior-member-redeclared` (799 (4)).

[cells/contract_required_member_met_by_type/src/main.bp](cells/contract_required_member_met_by_type/src/main.bp)
[cells/contract_required_member_signature_differs/src/main.bp](cells/contract_required_member_signature_differs/src/main.bp)
[cells/contract_default_fn_type_has_refused/src/main.bp](cells/contract_default_fn_type_has_refused/src/main.bp)
[cells/contract_default_fn_called_on_target/src/main.bp](cells/contract_default_fn_called_on_target/src/main.bp)
[cells/contract_default_fn_called_on_imported_record/src/main.bp](cells/contract_default_fn_called_on_imported_record/src/main.bp)
[cells/contract_default_fn_imported_record_block_not_active/src/main.bp](cells/contract_default_fn_imported_record_block_not_active/src/main.bp)
