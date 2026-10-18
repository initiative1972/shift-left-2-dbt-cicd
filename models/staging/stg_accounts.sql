with source as (
    select * from {{ ref('raw_accounts') }}
)

select
    account_id,
    account_name,
    account_type,
    cast(opened_date as date) as opened_date
from source
