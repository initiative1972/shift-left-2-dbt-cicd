# Regulatory mapping — change management & data integrity

> General information only. **Not compliance or legal advice.** Verify all
> regulatory facts against [apra.gov.au](https://www.apra.gov.au). Personal
> portfolio project, public sources only, synthetic data only.

This project is primarily a **data-engineering craft** demonstration, but the
discipline it enforces maps cleanly to prudential expectations around change
management and data integrity.

## Status of the standards (verified)

- **CPS 230 Operational Risk Management** — **fully in force** (commenced
  1 July 2025; transition ended 1 July 2026). Supervisory emphasis is on
  *evidence of effective implementation* of controls.
- **CPG 235 Managing Data Risk** — guidance on data quality controls across the
  data lifecycle.

## How this project evidences the expectations

| Expectation (paraphrased) | How this project evidences it |
|---|---|
| Controls over **changes** to systems that support critical operations (CPS 230) | No model change merges without passing automated review: lint, metadata governance, unit tests, and a selective build — all in version-controlled CI. |
| **Data quality managed across the lifecycle** (CPG 235) | Quality moves left: tests and documentation are required *before commit*, not reconciled afterwards. Every model is tested and described. |
| **Evidence of effective implementation**, not assertion (CPS 230) | Every PR produces a durable, timestamped CI record (which checks ran, what passed). The green badge and run history *are* the evidence. |
| **Logic correctness** of material calculations | The tiered-interest calculation is covered by a dbt unit test against fixed mock inputs — a regression can't silently ship. |

## What this does *not* claim

This is a small, synthetic demonstration of engineering controls — not a
compliance programme and not advice. It shows one concrete way "shift-left"
practice produces the change-management and data-integrity *evidence* APRA's
framework expects.
