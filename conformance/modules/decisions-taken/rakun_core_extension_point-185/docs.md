# Decision 185 — When one rakun member has to tell or ask another and an edge between them would be a cycle or drag a member into consume

The example's three modules play the core and two members. [draft/cache.bp](draft/cache.bp) has to tell [draft/client.bp](draft/client.bp) that a tag's data changed, and neither imports the other: an edge between them would drag one member into every program that uses the other. [draft/core.bp](draft/core.bp) defines the extension point instead, a per-tag epoch with `tagEpoch(tag)` and `bumpTag(tag)`, and both members plug into it. `client.get` stores the epochs of a response's tags beside the cached response, and treats a changed epoch as a miss. `cache.revalidateTag` only bumps the epoch.

The first two `get`s print `fetch 1` then `hit 1`. After `revalidateTag("posts")` the stored epoch differs, so the next `get` prints `fetch 2`. That is rakun's `rkTagEpoch` / `rkBumpTag` between `rakun-cache` and `rakun-client`, in one package.

The program prints `fetch 1`, `hit 1` and `fetch 2`.

Cells in this repository that bear on it: `modules/decisions-taken/reported_surface_forms_all_parse-28/cases/module_var`, `modules/module/cases/module_var_self_registration`.

[draft/main.bp](draft/main.bp)
