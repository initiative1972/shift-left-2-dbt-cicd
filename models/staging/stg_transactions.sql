with source as (
    select * from {{ ref('raw_transactions') }}
)

select
    transaction_id,
    account_id,
    cast(amount as decimal(18, 2)) as amount,
    currency,
    cast(txn_date as date) as txn_date
from source
