with accounts as (
    select * from {{ ref('stg_accounts') }}
),

transactions as (
    select * from {{ ref('stg_transactions') }}
),

balances as (
    select
        account_id,
        sum(amount) as closing_balance
    from transactions
    group by account_id
)

select
    a.account_id,
    a.account_name,
    a.account_type,
    coalesce(b.closing_balance, 0) as closing_balance
from accounts as a
left join balances as b on a.account_id = b.account_id
