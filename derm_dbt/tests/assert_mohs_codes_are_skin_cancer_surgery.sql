-- Fails (returns rows) if any Mohs surgery code is not in the skin cancer surgery service line.
select hcpcs_code, service_line
from {{ ref('dim_service') }}
where hcpcs_code in ('17311', '17312', '17313', '17314', '17315')
  and service_line is distinct from 'Skin cancer surgery'
