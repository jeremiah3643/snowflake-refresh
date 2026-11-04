select
    hcpcs_code,
    max(hcpcs_description)  as hcpcs_description,
    max(is_drug::int) = 1   as is_drug
from {{ ref('stg_cms__medicare_services') }}
group by hcpcs_code