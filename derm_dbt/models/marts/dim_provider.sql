select
    npi,
    provider_type,
    site_match_method
from {{ ref('int_provider_site') }}