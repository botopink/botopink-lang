# Decision 887 — A member `compiler.addMember` adds is `pub`; a primitive's property is written `pub val length: i32;`; settles 859 / 814 (2) for the two spellings without `pub`.

A member a decorator adds reaches every importer: `Users.spell(…)`, added by `#[spelled]` in `users`, is called
from `main`; `xs.length` reads the property std's prelude writes `pub val length: i32;`
(`added_member_is_pub`, on the four targets).

[cases/added_member_is_pub/src/main.bp](cases/added_member_is_pub/src/main.bp)
