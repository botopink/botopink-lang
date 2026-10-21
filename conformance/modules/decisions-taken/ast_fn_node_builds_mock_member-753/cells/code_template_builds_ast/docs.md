> Decisions 625 (4), 637 — `code` is std's template over the typed AST,
> imported where used (`import {code} from "std"`): a template answers the
> code it writes with `${…}` holes, each hole read by its arrival — a value
> known at build spliced as its literal (`Lit`), a `syntax` value as it was
> written (`Syntax`), the caller's holes (`compiler.holes(t)`) among them.
