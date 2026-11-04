with sites as (
    select
        location_id,
        max(address_line_1)  as address_line_1,
        max(site_city)       as city,
        max(site_state)      as state,
        max(site_zip)        as zip
    from {{ ref('int_provider_site') }}
    group by location_id
)

select
    s.*,
    r.state_name,
    r.region
from sites s
left join {{ ref('state_regions') }} r on r.state = s.state