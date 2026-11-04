-- Fails (returns a row) if the fact lost rows or dollars versus staging.
with fct as (
    select count(*) as row_count, sum(total_medicare_payment) as payment
    from {{ ref('fct_services') }}
),
stg as (
    select count(*) as row_count, sum(round(avg_medicare_payment * services, 2)) as payment
    from {{ ref('stg_cms__medicare_services') }}
)
select fct.*, stg.row_count as stg_rows, stg.payment as stg_payment
from fct cross join stg
where fct.row_count != stg.row_count
   or abs(fct.payment - stg.payment) > 0.01