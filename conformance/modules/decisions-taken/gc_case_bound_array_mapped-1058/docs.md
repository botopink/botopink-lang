# Decision 1058 — A comptime body is typed against an opaque `Decl` inside the lowering, with the language surface unchanged; the `.comptime` stage belongs to analysis, always runs and has no switch; a GC gap that gives a wrong answer is guarded into a named gap at once; answers 1035-b Q1 (a), Q2 (b), switch (a), wrong slot (b); amends 1035 (1), (6).

An array bound by a `case` arm's payload pattern (`Obj(fields: fs)` of `fields: F[]`) and then mapped reads each element's field from its own slot, and the mapped array keeps the element type the lambda answers: `fs.map({ f -> f.key }).join(";")` answers `y`, as the same array returned through a function typed `F[]` does, alike on all four targets (decision 1058 (4), 144 B-196).

[cases/gc_case_bound_array_mapped/src/main.bp](cases/gc_case_bound_array_mapped/src/main.bp)
