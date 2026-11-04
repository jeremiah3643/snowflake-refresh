-- Load the filtered CMS extracts from Scripts/Transform.py into DERM.RAW.
--
-- PUT uploads local files, so run this with the Snowflake CLI or SnowSQL,
-- not a Snowsight worksheet:
--     snow sql -f Scripts/load_raw.sql
-- Update the file:// paths in the PUT commands to match your machine.
--
-- Every column lands as VARCHAR. Typing, trimming and renaming happen in the
-- dbt staging models, so a bad value never fails the load.

use database DERM;
create schema if not exists RAW;
use schema RAW;

create file format if not exists PIPE_FORMAT
    field_delimiter = '|'
    skip_header = 1
    field_optionally_enclosed_by = '"'
    null_if = ('');

create stage if not exists CMS_STAGE
    file_format = PIPE_FORMAT;

-- Medicare Physician & Other Practitioners by Provider and Service, 2024
create or replace table MEDICARE_PROV_SVC (
    RNDRNG_NPI                      varchar,
    RNDRNG_PRVDR_ENT_CD             varchar,
    RNDRNG_PRVDR_CITY               varchar,
    RNDRNG_PRVDR_STATE_ABRVTN       varchar,
    RNDRNG_PRVDR_ZIP5               varchar,
    RNDRNG_PRVDR_TYPE               varchar,
    RNDRNG_PRVDR_MDCR_PRTCPTG_IND   varchar,
    HCPCS_CD                        varchar,
    HCPCS_DESC                      varchar,
    HCPCS_DRUG_IND                  varchar,
    PLACE_OF_SRVC                   varchar,
    TOT_BENES                       varchar,
    TOT_SRVCS                       varchar,
    TOT_BENE_DAY_SRVCS              varchar,
    AVG_SBMTD_CHRG                  varchar,
    AVG_MDCR_ALOWD_AMT              varchar,
    AVG_MDCR_PYMT_AMT               varchar,
    AVG_MDCR_STDZD_AMT              varchar
);

-- Doctors and Clinicians National Downloadable File
create or replace table DAC_CLINICIANS (
    NPI             varchar,
    IND_PAC_ID      varchar,
    PRI_SPEC        varchar,
    SEC_SPEC_ALL    varchar,
    FACILITY_NAME   varchar,
    ORG_PAC_ID      varchar,
    NUM_ORG_MEM     varchar,
    ADR_LN_1        varchar,
    ADR_LN_2        varchar,
    CITY_TOWN       varchar,
    STATE           varchar,
    ZIP_CODE        varchar,
    ADRS_ID         varchar
);

put file://C:/Snowflake/Output/phys_filtered.txt @CMS_STAGE auto_compress = false overwrite = true;
put file://C:/Snowflake/Output/dac_filtered.txt  @CMS_STAGE auto_compress = false overwrite = true;

copy into MEDICARE_PROV_SVC from @CMS_STAGE/phys_filtered.txt;
copy into DAC_CLINICIANS    from @CMS_STAGE/dac_filtered.txt;

-- Reconcile: these should match the row counts Transform.py prints
-- (36,942 and 3,518 for the 2024 files).
select 'MEDICARE_PROV_SVC' as table_name, count(*) as row_count from MEDICARE_PROV_SVC
union all
select 'DAC_CLINICIANS', count(*) from DAC_CLINICIANS;
