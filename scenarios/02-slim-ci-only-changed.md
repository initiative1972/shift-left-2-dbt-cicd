# Scenario 2 — CI rebuilds only what changed

**Claim being demonstrated:** *"CI only rebuilds the models that actually changed, plus their children — not the whole project. That is real cloud-compute cost saved."*

## The mechanism

`dbt build --select state:modified+` compares the PR's dbt graph against a
**production manifest** and selects only:

- models whose code (or config) changed, **and**
- everything downstream of them (the `+` suffix).

`--defer --favor-state` then points any *unchanged upstream* models at the
existing production relations instead of rebuilding them. On a real warehouse,
that is where the money is saved.

## Steps to reproduce (locally)

1. Build the production baseline and snapshot its manifest:
   ```bash
   make demo            # builds everything once (this is "production")
   make prod-manifest   # copies target/manifest.json -> ci/prod-manifest/
   ```

2. Change exactly one downstream model — e.g. tweak a comment or the rounding in
   `models/marts/account_interest.sql`.

3. Ask dbt what a Slim build would select:
   ```bash
   dbt ls --select state:modified+ --state ci/prod-manifest --resource-type model
   ```

## Expected result (the money shot)

Only the changed model (and its children) is selected:

```
dbt_cicd.marts.account_interest
```

**Not** `stg_accounts`, `stg_transactions`, or `account_balances` — those are
unchanged and are deferred to production. Contrast with a naive CI that runs
`dbt build` and rebuilds **all** models every time.

> 📸 **Capture the Slim CI log for the README** — specifically the "models
> selected" list and the build summary (`PASS=1` vs a full-build `PASS=N`).

## Put a number on it (stretch)

Add a row to the README table every time you run it:

| Change | Full build (models) | Slim CI (models) | Saving |
|---|---|---|---|
| Edit `account_interest` | 5 | 1 | 80% |
| Edit `stg_transactions` | 5 | 3 (+ children) | 40% |

On this toy project the absolute numbers are small; the **pattern** is exactly
what saves hours and dollars on a 500-model warehouse project.
