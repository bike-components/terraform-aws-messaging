# CLAUDE.md

Guidance for Claude Code (and anyone else) working in this repo.

## What this repo is

`terraform-aws-messaging` is a Terraform module: SNS + SQS pub/sub,
composed from single-resource nested submodules (`modules/sns`,
`modules/sqs`, `modules/s3`). The root module creates an optional topic,
N queues (each optionally with its own DLQ and S3 large-payload offload),
the IAM plumbing for producers/consumers, and the policies that let
everything talk to each other. It is a small, solo-maintained portfolio
module — not a monorepo, no build system, no application code.

Start here, in this order:
1. **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)** — module graph,
   data flow, settings-resolution pattern, IAM model. Read this before
   making any structural change.
2. **[`docs/decisions/`](docs/decisions/)** — why the non-obvious
   tradeoffs were made the way they were (nested submodule split,
   per-queue IAM roles, bundling the S3 offload bucket, the account-root
   trust-policy fallback).
3. **`README.md`** — the consumer-facing usage doc (what someone
   pinning this module via `source = "git::..."` would read).

## Repo layout

```
main.tf, locals.tf, variables.tf, outputs.tf, iam.tf, s3_offload.tf   root module
modules/sns/, modules/sqs/, modules/s3/                                nested submodules (single resource each)
examples/basic/, examples/complete/, examples/direct-attachment/       runnable examples — also the integration-test fixtures
docs/ARCHITECTURE.md, docs/decisions/                                  architecture + decision log (see above)
```

## Conventions to follow

- **Settings resolution happens once, in `locals.tf`.** Every
  queue-level field that can fall back to `default_queue_settings` is
  resolved via `coalesce()` in `locals.queues`, and everything downstream
  (`main.tf`, `iam.tf`) reads from `local.queues`, never `var.queues`
  directly. If you add a new per-queue setting with a module-wide
  default, add the `coalesce()` line in `locals.tf` and nowhere else.
- **`optional()` typing throughout.** The `queues` and
  `default_queue_settings` object types use `optional(type, default)`
  consistently — match that style for any new nested object field.
- **Naming**: `name_prefix` prefixes every resource
  (`<prefix>-<key>`) unless a resource sets its own `name_override` /
  is created with an explicit `name`. Don't hardcode prefixes elsewhere.
- **IAM is opt-in per resource, not blanket.** There is no
  module-wide transmitter/receiver role — see
  [ADR 0002](docs/decisions/0002-per-queue-iam-roles.md). New IAM
  surface area should follow the same shape: a flag that defaults to
  `false`, a standalone reusable `aws_iam_policy`, and an optional role
  on top of it.
- **A role with no principal ARNs supplied trusts the account root**,
  not an open door — see
  [ADR 0004](docs/decisions/0004-trust-policy-fallback-to-account-root.md).
  Don't "fix" this by requiring principal ARNs up front; that reintroduces
  the sequencing problem the fallback exists to solve.

## Decision log — when to write an ADR

Write an ADR (`docs/decisions/NNNN-title.md`, copy
[`TEMPLATE.md`](docs/decisions/TEMPLATE.md)) whenever a change involves a
real fork in the road — a choice between two or more reasonable designs,
where the reasoning won't be obvious from the diff alone. Examples that
would warrant one: changing how IAM roles are scoped, deciding whether a
new AWS primitive gets its own nested submodule vs. inlined resources,
changing a default that affects blast radius (e.g. the account-root trust
fallback), or reversing an existing ADR's decision.

Don't write one for: bug fixes, variable additions that follow an
existing pattern (e.g. a new field in `default_queue_settings`), or
formatting/refactoring with no behavior change.

If the tradeoff is debatable rather than clear-cut, propose the ADR
(`Status: proposed`) and ask before marking it `accepted` — this is a
one-maintainer repo, but a wrong architectural default is expensive to
walk back once something depends on it.

A `PostToolUse` hook (`.claude/settings.json`) fires after any edit to a
root-level or `modules/**/*.tf` file and reminds you to consider both the
architecture doc and the decision log — treat that reminder as a
checklist, not busywork; most edits need neither.

## Architecture doc upkeep

`docs/ARCHITECTURE.md` should stay accurate to the current `.tf` files.
Update it in the same change when you: add/remove a resource or nested
module, add a variable that changes control flow (a new `count`/`for_each`
gate, a new conditional IAM statement), or change the IAM model. Cosmetic
changes (formatting, comments, variable descriptions) don't need it.

Mechanical variable/output tables are generated, not hand-written — see
[`docs/ARCHITECTURE.md`'s "Generated reference docs" section](docs/ARCHITECTURE.md#generated-reference-docs)
for the `terraform-docs` command. Regenerate after changing any
`variable`/`output` block in the root module or any `modules/*`
submodule; don't hand-edit content between the `<!-- BEGIN_TF_DOCS -->`
/ `<!-- END_TF_DOCS -->` markers.

## Development workflow

```bash
terraform fmt -recursive -check   # verify formatting (pre-approved, no prompt)
terraform init -backend=false     # local-only init, no state backend (pre-approved)
terraform validate                # per directory: root, modules/*, examples/* (pre-approved)

# regenerate reference tables (pre-approved) — run from repo root, one shared .terraform-docs.yml:
for d in . modules/sns modules/sqs modules/s3; do
  terraform-docs markdown table --config .terraform-docs.yml --output-file README.md --output-mode inject "$d"
done
```

`terraform plan`/`apply`/`destroy` touch real AWS credentials and
(for apply/destroy) real infrastructure — these are **not** pre-approved
and should not be run without the user's explicit go-ahead each time, even
though `plan` itself is read-only. There's no CI in this repo yet, so
`fmt -check` + `validate` across root and every module/example directory
is the whole safety net before a PR — run all of them, not just root.

The three directories under `examples/` are the closest thing to an
integration-test suite this module has (each exercises a different IAM
pattern: role-assumption vs. direct-attachment vs. the full README usage
example). When changing root module behavior, check whether an example
needs updating to match, and prefer extending an existing example over
adding a fourth unless the new pattern is genuinely different.

## Reducing cost and staying efficient

This is a small repo (~20 `.tf` files, no generated code, no
dependencies to index) — most tasks don't need heavy tooling:

- **Default to direct Read/Grep/Glob over spawning subagents.** A
  single-file or single-module change doesn't need the `Explore` agent or
  a `fork`; reach for those for genuinely repo-wide questions ("where
  else does this pattern appear across root + all three submodules"),
  not for "what does `locals.tf` do."
- **Never read `.terraform/` provider binaries, `.terraform.lock.hcl`,
  or `*.tfstate*` files.** The provider binaries are large binary blobs
  that burn context for zero benefit; state files can contain resource
  attribute values (some sensitive) and are also gitignored for a
  reason — don't pull them into context even to "just check" something,
  read the `.tf` source instead. If you ever need to debug real deployed
  state, ask the user to run `terraform show`/`terraform state` and paste
  the relevant part.
- **Scope searches to the source, not the noise.** When grepping across
  the repo, exclude `.terraform/`, `examples/*/.terraform/`, and
  `*.tfstate*` — a plain repo-wide grep without excludes will match
  inside the committed lockfile and (locally, if present) provider
  binaries and state, none of which are useful signal.
- **The permission allowlist in `.claude/settings.json`** pre-approves
  `terraform fmt -check`, `terraform validate`, `terraform init
  -backend=false`, `terraform-docs`, and read-only `git` commands
  (`status`/`diff`/`log`/`show`) so routine verification doesn't
  interrupt you with prompts. `terraform plan`/`apply`/`destroy` and any
  state-mutating or history-rewriting git command are deliberately left
  out — those should still prompt every time.
