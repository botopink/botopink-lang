# component_compose_signature_differs

Decisions 804 (1), 800: a `compose` written with another signature than `fn compose(self: Self) -> Component<R>` is refused at the member, `implement-signature-differs`, naming both signatures.
