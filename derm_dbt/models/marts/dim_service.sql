-- One row per procedure code, with its service line.
-- Rules first, AI second: codes with a known service line are assigned directly,
-- and everything else uses the Cortex classification from int_service_line_ai.
-- Mohs codes need the rule because their CMS descriptions ("removal and microscopic
-- examination of skin cancer") lead the model to label them as biopsy and pathology.
select
    s.hcpcs_code,
    max(s.hcpcs_description)        as hcpcs_description,
    max(s.is_drug::int) = 1         as is_drug,
    case
        when s.hcpcs_code in ('17311', '17312', '17313', '17314', '17315') then 'Skin cancer surgery'
        else max(ai.service_line)
    end                             as service_line,
    case
        when s.hcpcs_code in ('17311', '17312', '17313', '17314', '17315') then 'rule'
        else 'ai'
    end                             as service_line_source
from {{ ref('stg_cms__medicare_services') }} s
left join {{ ref('int_service_line_ai') }} ai on ai.hcpcs_code = s.hcpcs_code
group by s.hcpcs_code
