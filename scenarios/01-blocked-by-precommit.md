# Scenario 1 — a non-compliant model never leaves the laptop

**Claim being demonstrated:** *"Badly formatted, undocumented or untested SQL is blocked on my machine, before it is ever committed."*

## Steps to reproduce

1. Make sure the hooks are installed:
   ```bash
   make setup
   make install-hooks
   ```

2. Add a new model that breaks the rules — no description, no test:
   ```bash
   cat > models/marts/account_summary.sql <<'SQL'
   SELECT account_id, closing_balance FROM {{ ref('account_balances') }}
   SQL
   ```
   Note the uppercase keywords (SQLFluff will object) and the fact that it has
   **no entry** in `_marts__models.yml` (so no description and no test).

3. Try to commit it:
   ```bash
   git add models/marts/account_summary.sql
   git commit -m "add account summary"
   ```

## Expected result (the money shot)

The commit is **rejected**. You should see failures like:

```
sqlfluff-lint..............................................................Failed
- hook id: sqlfluff-lint
  L:   1 | P:   1 | CP01 | Keywords must be lowercase.
  ...
check-model-has-tests......................................................Failed
- hook id: check-model-has-tests
  account_summary: has 0 tests, expected at least 1
check-model-has-description................................................Failed
- hook id: check-model-has-description
  account_summary: does not have a description
check-model-columns-have-desc..............................................Failed
```

> 📸 **Capture this terminal output for the README.** The rejected commit is the
> proof: the quality gate runs on *your* machine, not after the fact.

## Making it pass (show the fix)

1. Format it: `make fmt` (SQLFluff lowercases keywords and tidies layout).
2. Document and test it — add to `models/marts/_marts__models.yml`:
   ```yaml
     - name: account_summary
       description: Minimal per-account balance summary.
       columns:
         - name: account_id
           description: Primary key.
           data_tests: [unique, not_null]
         - name: closing_balance
           description: Account closing balance in AUD.
           data_tests: [not_null]
   ```
3. Commit again — the hooks now pass, and the model is documented and tested
   **before** it ever reaches the repository.
