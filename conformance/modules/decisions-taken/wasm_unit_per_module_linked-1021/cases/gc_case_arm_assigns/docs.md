# gc_case_arm_assigns

A `case` in statement position whose arrow arms assign a local `var` leaves the arm's value in it for the code after the `case`: `n4` then `negative`; on wasm the GC lowering runs the arm as a statement (decision 1021 (10)); beam dropped the assignment (`case/cases/case_arm_assigns_local`).
