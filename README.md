# shift-left-2-dbt-cicd
# Extreme CI/CD for dbt

> Badly formatted, undocumented, untested or destructive SQL never leaves the laptop — and CI only rebuilds what actually changed.

[![quality](https://github.com/initiative1972/shift-left-2-dbt-cicd/actions/workflows/quality.yml/badge.svg)](../../actions/workflows/quality.yml)
[![slim-ci](https://github.com/initiative1972/shift-left-2-dbt-cicd/actions/workflows/slim-ci.yml/badge.svg)](../../actions/workflows/slim-ci.yml)

Project 2 of a shift-left data-engineering portfolio. Where [[../project-1-webhook-interceptor](https://github.com/initiative1972/shift-left-1-webhook-interceptor)] guards the **ingestion boundary** with a data contract, this project shows the **day-to-day craft**: quality enforced on the developer's machine with pre-commit, and a cost-aware CI pipeline that only builds the models a change actually touches.

It's a complete, runnable **dbt + DuckDB** project — no warehouse account, no credit card.

---

## Why this project exists

Two failure modes dominate real dbt projects:

1. **Quality drift** — models merged with no tests, no descriptions, inconsistent SQL. Six months later nobody can safely change anything.
2. **CI cost blow-out** — every pull request rebuilds the *entire* warehouse, so CI gets slow and expensive, so people start skipping it.

Shift-left fixes both by moving quality earlier and making CI *stateful*:

- **On the laptop:** `pre-commit` runs SQLFluff (formatting) and dbt-checkpoint (every model must be documented and tested) *before the commit is allowed*.
- **In the pipeline:** **Slim CI** uses `state:modified+` and deferral to build and test **only the changed models and their children**, deferring everything else to the production state.
- **For correctness:** **dbt unit tests** validate non-trivial transformation logic against static mock inputs — no warehouse round-trip, no flakiness.

## Architecture

```
┌─ developer machine ────────────────────────────────────────────┐
│  git commit                                                     │
│     └─▶ pre-commit                                              │
│           ├─ SQLFluff ............ lint + autoformat SQL        │
│           └─ dbt-checkpoint ...... every model tested + described
│         ✗ non-compliant  →  commit BLOCKED (never pushed)       │
└────────────────────────────────────────────────────────────────┘
        │  push / open PR
        ▼
┌─ GitHub Actions ───────────────────────────────────────────────┐
│  quality.yml                                                    │
│     ├─ pre-commit (backstop)                                    │
│     └─ dbt unit tests (logic vs mock inputs)                    │
│  slim-ci.yml                                                    │
│     ├─ rebuild production state from `main`                     │
│     └─ dbt build --select state:modified+ --defer --favor-state │
│         → only changed models + children built & tested         │
└────────────────────────────────────────────────────────────────┘
```

## The data model (synthetic finance)

A deliberately small but realistic lineage — **all data is synthetic** (see `seeds/`):

```
raw_accounts ─┐
              ├─▶ stg_accounts ─────┐
raw_transactions ─▶ stg_transactions ─┴─▶ account_balances ─▶ account_interest
```

`account_interest` applies a **tiered interest calculation** (0.50% / 1.50% / 2.75% by balance band) — the kind of material business logic you never want to break silently. It's covered by a dbt unit test.

## Quickstart (runs locally in ~3 minutes, no cloud account)

```bash
# 1. Install dbt-duckdb, pre-commit, SQLFluff
make setup
make install-hooks       # wire pre-commit into git

# 2. Build everything and run all tests (seeds → models → tests → unit tests)
make demo

# 3. Run just the unit tests (transformation logic vs mock inputs)
make unit-test
```

> **No `make` (e.g. Windows)?** Set `DBT_PROFILES_DIR` to this folder and run the
> underlying commands directly: `dbt seed --target dev`, `dbt build --target dev`,
> `dbt build --select test_type:unit --target dev`.

## The two money shots

This repo is built around **two demonstrations of what it prevents** — the most
persuasive thing a portfolio project can show.

### 1. A bad model blocked on the laptop
Add a model with no test and no description → `git commit` is **rejected** by
pre-commit. Full walkthrough: [`scenarios/01-blocked-by-precommit.md`](scenarios/01-blocked-by-precommit.md).

![pre-commit blocking a bad commit](docs/precommit-blocked.png)

### 2. CI builds only what changed
Change one model → Slim CI builds **just that model and its children**, not the
whole project. Full walkthrough: [`scenarios/02-slim-ci-only-changed.md`](scenarios/02-slim-ci-only-changed.md).

![Slim CI selecting only the changed model](docs/slim-ci-log.png)

> *(Add the two captures above once you've run them. The red-commit terminal and
> the "1 of 5 models built" CI log are the whole pitch.)*

## Engineering decisions & trade-offs

- **DuckDB, not a cloud warehouse.** The *patterns* (Slim CI, deferral, unit
  tests) are warehouse-agnostic; DuckDB makes the repo reproducible on any
  machine in minutes. State-based selection and deferral behave the same way.
- **Slim CI via a two-checkout prod rebuild.** `slim-ci.yml` rebuilds production
  state from `main` into a shared DuckDB file, then defers to it. On a real
  warehouse you'd defer to a persistent prod schema and commit the manifest as an
  artefact — I've left `make prod-manifest` and `ci/prod-manifest/` in place for
  that flavour. The *selection logic* (`state:modified+`) is identical either way.
- **Quality enforced twice.** pre-commit on the laptop is the fast feedback loop;
  the same checks run in CI as a backstop for anyone who skips the hook.
- **Unit tests on the risky logic only.** The tiered-interest calc is unit
  tested; trivial passthroughs are covered by schema tests. Test where the risk
  is, not everywhere.

## What's simplified (honest scope)

- Small model set and synthetic seeds — enough to show the lineage and the
  selective build, not a production warehouse.
- The "production" environment is reconstructed from `main` in CI rather than a
  long-lived warehouse; on this toy scale the compute saving is illustrative, but
  the mechanism is exactly what saves real hours on a large project.
- Single `AUD` currency, no incremental models, no snapshots — deliberately out
  of scope to keep the demo readable.

## Regulatory mapping

The change-management discipline here maps to **CPS 230** (controls over changes
to systems supporting critical operations; *evidence of effective
implementation*) and **CPG 235** (data quality across the lifecycle). See
[`docs/regulatory-mapping.md`](docs/regulatory-mapping.md). *Not compliance advice.*

## Reusable lead magnet

`.pre-commit-config.yaml` and `.github/workflows/slim-ci.yml` are designed to be
lifted straight into any dbt project. They're the companion artefacts to the
**Week 10** article in the *Shift Left* series.

## Tech

- **Transformation:** dbt-core 1.9.x
- **Engine:** DuckDB (local, zero-config) via dbt-duckdb
- **Linting/format:** SQLFluff 4.4.0 (dbt templater)
- **Metadata governance:** dbt-checkpoint v2.0.10
- **CI:** GitHub Actions (quality + Slim CI)

## License

MIT — see [LICENSE](LICENSE).
