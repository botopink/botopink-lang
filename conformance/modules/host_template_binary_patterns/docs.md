# host_template_binary_patterns

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> An Erlang template that matches a binary may use any fixed-size byte segment — a literal prefix,
> `Rest/binary`, a sized `/binary`, a literal followed by an integer field, an integer of whole bytes
> read `little` or `signed` — and erlang and beam answer the same.
