select
    practice_id,
    max(practice_name)              as practice_name,
    count(distinct npi)             as provider_count,
    count(distinct location_id)     as site_count
from {{ ref('int_provider_site') }}
group by practice_id