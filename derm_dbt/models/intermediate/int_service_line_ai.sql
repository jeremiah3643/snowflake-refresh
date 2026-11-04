-- Classifies each distinct procedure code into a service line with Cortex.
-- Incremental: only codes not already classified get sent to the model,
-- so rebuilds cost nothing unless new codes appear.
{{ config(materialized='incremental', unique_key='hcpcs_code') }}

with codes as (
    select hcpcs_code, max(hcpcs_description) as hcpcs_description
    from {{ ref('stg_cms__medicare_services') }}
    group by hcpcs_code
)

select
    hcpcs_code,
    hcpcs_description,
    AI_CLASSIFY(
        hcpcs_description,
        [
          {'label': 'Skin cancer surgery',  'description': 'Excision of malignant lesions, Mohs surgery, and the wound repairs, closures, flaps or grafts that follow'},
          {'label': 'Biopsy and pathology', 'description': 'Skin biopsies of any type, and lab or pathology examination of tissue'},
          {'label': 'Lesion destruction',   'description': 'Destroying lesions by freezing, burning, laser or chemicals'},
          {'label': 'Office visits',        'description': 'Evaluation and management visits only: new or established patient office visits'},
          {'label': 'Drugs and injections', 'description': 'Injected or supplied drugs, usually J codes'},
          {'label': 'Other',                'description': 'Radiation, imaging, or anything else'}
        ],
        {'task_description': 'Classify a Medicare procedure description from a dermatology practice into its service line'}
    ):labels[0]::string          as service_line,
    current_timestamp()          as classified_at
from codes

{% if is_incremental() %}
where hcpcs_code not in (select hcpcs_code from {{ this }})
{% endif %}