-- One row per provider, procedure code and place of service (same grain as staging).
-- CMS publishes averages; totals here = average x services.
with services as (
    select * from {{ ref('stg_cms__medicare_services') }}
),

sites as (
    select npi, practice_id, location_id
    from {{ ref('int_provider_site') }}
)

select
    -- foreign keys
    s.npi,
    p.practice_id,
    p.location_id,
    s.hcpcs_code,
    s.place_of_service,
    2024                                                     as data_year,

    -- measures
    s.beneficiaries,
    s.services,
    round(s.avg_submitted_charge     * s.services, 2)        as total_submitted_charges,
    round(s.avg_allowed_amount       * s.services, 2)        as total_allowed_amount,
    round(s.avg_medicare_payment     * s.services, 2)        as total_medicare_payment,
    round(s.avg_standardized_payment * s.services, 2)        as total_standardized_payment
from services s
join sites p on p.npi = s.npi