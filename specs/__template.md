# [SPEC NAME]

**Version:** 1.0.0-beta                                                   <!-- canonical format; filename uses underscores: 1_0_0_beta.[name].md -->
**Status:** planning
**Created:** [DATE]
**Author:** [AUTHOR]

---

## Status

> The overall status tracks the spec lifecycle independently of individual steps:
> - **planning** — spec is being drafted, scope still under definition
> - **awaiting execution** — spec is ready, waiting to be picked up
> - **completed** — all steps are `completed`
> - **cancelled** — spec discarded (explicit cancel decision)

**Current:** planning

| Step   | Title              | Status    | Assignee |
|--------|--------------------|-----------|----------|
| Step 1 | [Step title]       | pending   | [NAME]   |
| Step 2 | [Step title]       | pending   | [NAME]   |

## Objective

[Describe the main goal of the spec in 2-4 lines. What is to be achieved? What problem does it solve?]

## Prerequisites

- [List dependencies, related specs, or conditions required before starting]
- [E.g.: Spec `1_0_0_beta.foo.md` completed]
- [E.g.: Tool X installed]

## Steps

Each step must be atomic and verifiable. Use the following statuses:

- **pending** — not started yet
- **open** — in progress
- **completed** — finished successfully
- **cancelled** — discarded (include the reason)

### Step 1 — [Step title]

**Status:** pending
**Assignee:** [NAME]

**Description:**
[What needs to be done in this step. Be specific: files to change, functions to create, commands to run.]

**Acceptance criteria:**
- [Objective condition to consider the step done]
- [E.g.: Tests pass with `zig build test`]
- [E.g.: File X exists with function Y]

### Step 2 — [Step title]

**Status:** pending
**Assignee:** [NAME]

**Description:**
[What needs to be done.]

**Acceptance criteria:**
- [Objective condition]

---

## Workflow

1. **Planning phase** — draft the spec steps and acceptance criteria. Status: `planning`.
2. **Ready** — change status to `awaiting execution`.
3. **Start execution** — the agent must ask for confirmation before proceeding. If confirmed, create a git worktree under `.spec/` and a branch named `spec/<filename>` (filename without `.md` extension). E.g.:
   ```
   git worktree add .spec/1_0_0_beta.foo -b spec/1_0_0_beta.foo feat
   ```
4. **Work through steps** — update each step's status as you go (`pending` → `open` → `completed`).
5. **Finish execution** — once all steps are `completed`:
   - Update the spec status to `completed`.
   - Merge the worktree branch into the remote version branch. If this is the **first spec** of the version, create the version branch from `feat`:
     ```
     # First spec: push directly to create the version branch
     git push origin spec/<filename>:refs/heads/spec/<version>
     ```
     Subsequent specs merge into the existing version branch:
     ```
     git fetch origin spec/<version>   # e.g. spec/1.0.0-beta
     git worktree add .spec/_integrate-<name> -b integrate/<name> origin/spec/<version>
     # in the integration worktree: git merge --no-ff spec/<filename>
     git push origin integrate/<name>:spec/<version>
     ```
   - Remove the worktree and delete the remote feature branch:
     ```
     git worktree remove .spec/<name> && git worktree remove .spec/_integrate-<name>
     git push origin --delete spec/<filename>
     git branch -d spec/<filename> integrate/<name>
     git worktree prune
     ```
6. **Version completion** — when all specs under a version are done, integrate into `feat` with clean history:
   ```
   git fetch origin spec/<version>
   git checkout -b spec/<version> origin/spec/<version>
   git rebase -i feat
   ```
   Reorganize commits via interactive rebase so each spec maps to a single clear, well-described commit. Keep all changes intact — only restructure history. Then verify everything passes:
   ```
   zig build test
   zig build test-libs   # if runtimes available
   ```
   Once verified, merge into `feat` and clean up:
   ```
   git checkout feat
   git merge --no-ff spec/<version>
   git push origin feat
   git branch -d spec/<version>
   git push origin --delete spec/<version>
   ```

---

## Notes

- [Additional notes, design decisions, relevant links]
- [Identified risks, considered alternatives]

## Changelog

| Date       | Change                             | Author |
|------------|------------------------------------|--------|
| [DATE]     | Spec created                       | [NAME] |
