-- One row per provider, procedure code and place of service.
-- Rename, type and trim only. No business logic here.
with source as (
    select * from {{ source('cms', 'medicare_prov_svc') }}
),

renamed as (
    select
        trim(rndrng_npi)                              as npi,
        trim(rndrng_prvdr_ent_cd)                     as entity_type,
        initcap(trim(rndrng_prvdr_city))              as billing_city,
        upper(trim(rndrng_prvdr_state_abrvtn))        as billing_state,
        lpad(trim(rndrng_prvdr_zip5), 5, '0')         as billing_zip,
        trim(rndrng_prvdr_type)                       as provider_type,
        rndrng_prvdr_mdcr_prtcptg_ind = 'Y'           as is_medicare_participating,
        upper(trim(hcpcs_cd))                         as hcpcs_code,
        trim(hcpcs_desc)                              as hcpcs_description,
        hcpcs_drug_ind = 'Y'                          as is_drug,
        trim(place_of_srvc)                           as place_of_service,
        tot_benes::integer                            as beneficiaries,
        tot_srvcs::number(38, 4)                      as services,
        tot_bene_day_srvcs::number(38, 4)             as beneficiary_day_services,
        avg_sbmtd_chrg::number(38, 6)                 as avg_submitted_charge,
        avg_mdcr_alowd_amt::number(38, 6)             as avg_allowed_amount,
        avg_mdcr_pymt_amt::number(38, 6)              as avg_medicare_payment,
        avg_mdcr_stdzd_amt::number(38, 6)             as avg_standardized_payment
    from source
)

select * from renamed