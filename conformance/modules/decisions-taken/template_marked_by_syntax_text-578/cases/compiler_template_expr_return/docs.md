> Decisions 577, 578 — a template is a function whose first parameter is
> its text, `syntax q: string`, called `` name @`…` ``: the text arrives raw
> (no escape but `` \` ``, no hole) and `compiler.text(q)` reads it. The
> call becomes the template's return: a value computed at build is spliced
> as a literal (`shout`), and `compiler.build(source)` answers the code
> built from text, typed where the call stands (`-> anyvalue`, `twice`).
