select
    s.hcpcs_code,
    max(s.hcpcs_description)        as hcpcs_description,
    max(s.is_drug::int) = 1         as is_drug,
    max(ai.service_line)            as service_line
from {{ ref('stg_cms__medicare_services') }} s
left join {{ ref('int_service_line_ai') }} ai on ai.hcpcs_code = s.hcpcs_code
group by s.hcpcs_code