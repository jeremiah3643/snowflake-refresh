-- One row per billing provider, with the practice site chosen for them.
-- Rule, in order:
--   1. billing_zip_match:   a directory site at the provider's billing ZIP
--   2. best_available_site: no ZIP match; prefer a group, then the larger group, then lowest address_id
--   3. not_in_directory:    provider missing from the directory; fall back to billing address
-- Simplification: 113 clinicians belong to more than one group; each is assigned one.
with billing as (
    select distinct npi, provider_type, billing_city, billing_state, billing_zip
    from {{ ref('stg_cms__medicare_services') }}
),

candidates as (
    select
        s.*,
        s.practice_zip = b.billing_zip as is_zip_match
    from {{ ref('stg_cms__dac_clinicians') }} s
    join billing b on b.npi = s.npi
),

ranked as (
    select
        *,
        row_number() over (
            partition by npi
            order by
                is_zip_match desc,
                (group_pac_id is not null) desc,
                group_member_count desc nulls last,
                address_id
        ) as site_rank
    from candidates
),

chosen as (
    select * from ranked where site_rank = 1
)

select
    b.npi,
    b.provider_type,
    case
        when c.npi is null then 'not_in_directory'
        when c.is_zip_match then 'billing_zip_match'
        else 'best_available_site'
    end                                                   as site_match_method,
    case
        when c.npi is null then 'NOT_IN_DIRECTORY'
        when c.group_pac_id is null then 'INDEPENDENT'
        else c.group_pac_id
    end                                                   as practice_id,
    case
        when c.npi is null then 'Not in CMS directory'
        when c.group_pac_id is null then 'Independent'
        else c.practice_name
    end                                                   as practice_name,
    c.group_member_count,
    coalesce(c.address_id, 'ZIP-' || b.billing_zip)       as location_id,
    c.address_line_1,
    coalesce(c.practice_city,  b.billing_city)            as site_city,
    coalesce(c.practice_state, b.billing_state)           as site_state,
    coalesce(c.practice_zip,   b.billing_zip)             as site_zip
from billing b
left join chosen c on c.npi = b.npi