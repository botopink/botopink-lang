# enum_variant_array_payload_beside_scalar

A payload enum's variants may carry payloads of different shapes — one
variant's field an array, a sibling's a scalar — and each prints by its own
field's shape: `Enum.Variant(field: value, …)`, the array field's elements
comma-joined in `[…]`.
