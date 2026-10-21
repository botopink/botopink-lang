# Decision 512 — A workspace declares what its members share; a member declares only its own.

The example is a member of a workspace. It imports `greet.hello` from `greeter`, a dependency the workspace's manifest declares and the member inherits without declaring it again; redeclaring it in the member would be refused. The member's manifest writes only its `name`, which is its directory's and unique in the workspace. Its `src`, `entry`, `version` and `targets` are the workspace's. A draft carries no manifest and no dependency, so the example waits for the promoted cell, a member of `conformance/modules/`.

Cells in this repository that also bear on it: every cell of `conformance/modules/`, a member of the workspace `modules/botopink.json`.

[draft/main.bp](draft/main.bp)
