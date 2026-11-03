# component_through_behavior_dispatch

Decision 809 (1), (4) — a component a type's own method answers resolves exactly as the same body called as a plain function does: `wrap(t)` and `t.toStyled()` call the same body, one directly, one dispatched through `Styleable`'s `toStyled`, and both answer the same `Styled`, its fields included (B-211: an unmarked method answering `Component<R>` used to keep the scope-wrapped lambda the lowering gives a `component fn`, without the checker's matching resolve, so the field read past it).
