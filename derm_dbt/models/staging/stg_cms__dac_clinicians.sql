-- One row per clinician, enrollment, group and address. Not deduplicated:
-- choosing each clinician's practice site happens in int_provider_site.
with source as (
    select * from {{ source('cms', 'dac_clinicians') }}
),

renamed as (
    select
        trim(npi)                                     as npi,
        trim(ind_pac_id)                              as individual_pac_id,
        trim(pri_spec)                                as primary_specialty,
        trim(sec_spec_all)                            as secondary_specialties,
        trim(facility_name)                           as practice_name,
        nullif(trim(org_pac_id), '')                  as group_pac_id,
        num_org_mem::integer                          as group_member_count,
        trim(adr_ln_1)                                as address_line_1,
        nullif(trim(adr_ln_2), '')                    as address_line_2,
        initcap(trim(city_town))                      as practice_city,
        upper(trim(state))                            as practice_state,
        lpad(left(trim(zip_code), 5), 5, '0')         as practice_zip,
        trim(zip_code)                                as practice_zip_full,
        trim(adrs_id)                                 as address_id
    from source
)

select * from renamed