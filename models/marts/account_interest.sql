-- Tiered monthly interest on the account closing balance.
-- This is the non-trivial calculation covered by a dbt unit test
-- (see _marts__models.yml :: unit_tests).
--
-- Tiers (annual rate):
--   balance <= 1,000           -> 0.50%
--   1,000 < balance <= 10,000  -> 1.50%
--   balance > 10,000           -> 2.75%
-- Monthly interest = balance * annual_rate / 12, rounded to 2 dp.

with balances as (
    select * from {{ ref('account_balances') }}
),

tiered as (
    select
        account_id,
        closing_balance,
        case
            when closing_balance <= 1000 then 0.0050
            when closing_balance <= 10000 then 0.0150
            else 0.0275
        end as annual_rate
    from balances
)

select
    account_id,
    closing_balance,
    annual_rate,
    round(closing_balance * annual_rate / 12, 2) as monthly_interest
from tiered
