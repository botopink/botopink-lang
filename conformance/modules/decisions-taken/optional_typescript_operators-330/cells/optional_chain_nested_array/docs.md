# optional_chain_nested_array

Decision 330: at the first absent link of a `?.` chain the whole chain is absent. A chain through an optional record's
optional array, `f?.fields?.[0]?.name`, answers the element's field when every link is present (`email`, also when the
chain is split over `val first = f?.fields?.[0]` and `val fields = f?.fields`) and `none` when `f` is absent or `fields` is.
