# derm_dbt

dbt project that turns the raw CMS extracts in `DERM.RAW` into a tested star schema in `DERM.MARTS`.
See the [project README](../README.md) for the full pipeline and design notes.

## Layers

| Layer | Schema | Materialized | Models |
|---|---|---|---|
| Sources | `RAW` | tables (loaded by `Scripts/load_raw.sql`) | `medicare_prov_svc`, `dac_clinicians` |
| Staging | `STAGING` | views | `stg_cms__medicare_services`, `stg_cms__dac_clinicians` |
| Intermediate | `STAGING` | views / incremental | `int_provider_site`, `int_service_line_ai` |
| Marts | `MARTS` | tables | `fct_services`, `dim_provider`, `dim_practice`, `dim_location`, `dim_service` |

Seed: `state_regions` maps each state to a region.

`macros/generate_schema_name.sql` overrides dbt's default so models land in `STAGING` and `MARTS`
exactly, not `<target_schema>_STAGING`.

## Running

From this folder, with a `derm_dbt` profile in `~/.dbt/profiles.yml`:

```bash
dbt debug       # check the connection
dbt build       # seed, run and test everything in dependency order
dbt docs generate && dbt docs serve   # browse lineage and column docs
```
