"""
Extract dermatology providers from two CMS public-use files.

Both source files are too large to load into memory at once (3.3 GB and
900 MB), so each one is read in chunks. Every chunk is filtered to
dermatology and Mohs surgery providers in nine states, and the matches are
written as pipe-delimited extracts for loading into Snowflake
(see Scripts/load_raw.sql).

Inputs (download from data.cms.gov into Data/):
    PHY_R26_P05_V10_D24_Prov_Svc.csv   Medicare Physician & Other Practitioners
                                       by Provider and Service, 2024
    DAC_NationalDownloadableFile.csv   Doctors and Clinicians National
                                       Downloadable File

Outputs (written to Output/, overwritten on each run):
    phys_filtered.txt
    dac_filtered.txt

Run from anywhere:
    python Scripts/Transform.py
"""

from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "Data"
OUTPUT_DIR = ROOT / "Output"

CHUNK_SIZE = 100_000
STATES = ["TN", "KY", "VA", "NC", "GA", "AL", "MS", "AR", "MO"]

# Medicare Physician & Other Practitioners: one row per provider, procedure
# code and place of service.
PHY_FILE = DATA_DIR / "PHY_R26_P05_V10_D24_Prov_Svc.csv"
PHY_COLUMNS = [
    "Rndrng_NPI", "Rndrng_Prvdr_Ent_Cd", "Rndrng_Prvdr_City", "Rndrng_Prvdr_State_Abrvtn",
    "Rndrng_Prvdr_Zip5", "Rndrng_Prvdr_Type", "Rndrng_Prvdr_Mdcr_Prtcptg_Ind",
    "HCPCS_Cd", "HCPCS_Desc", "HCPCS_Drug_Ind", "Place_Of_Srvc",
    "Tot_Benes", "Tot_Srvcs", "Tot_Bene_Day_Srvcs",
    "Avg_Sbmtd_Chrg", "Avg_Mdcr_Alowd_Amt", "Avg_Mdcr_Pymt_Amt", "Avg_Mdcr_Stdzd_Amt",
]
PHY_SPECIALTIES = ["Dermatology", "Micrographic Dermatologic Surgery"]

# Doctors and Clinicians directory: one row per clinician, group and address.
DAC_FILE = DATA_DIR / "DAC_NationalDownloadableFile.csv"
DAC_COLUMNS = [
    "NPI", "Ind_PAC_ID", "pri_spec", "sec_spec_all", "Facility Name", "org_pac_id",
    "num_org_mem", "adr_ln_1", "adr_ln_2", "City/Town", "State", "ZIP Code", "adrs_id",
]
DAC_SPECIALTIES = ["DERMATOLOGY", "MICROGRAPHIC DERMATOLOGIC SURGERY (MDS)"]
# Spaces and slashes in column names would need quoting in Snowflake.
DAC_RENAME = {"Facility Name": "Facility_Name", "City/Town": "City_Town", "ZIP Code": "ZIP_Code"}


def filter_derm_rows(path, columns, specialty_col, specialty_values, state_col, states,
                     output_path, rename=None):
    """Filter one CMS file to the given specialties and states and write it out.

    Exact specialty values are matched with isin() rather than a substring
    search, because "derm" also matches provider and practice names
    (McDermott, Scleroderma programs, and so on).

    Prints row counts per state and per specialty so the load can be
    reconciled against Snowflake. Returns the filtered DataFrame.
    """
    # dtype=str keeps NPIs, ZIP codes and IDs exactly as published (no lost
    # leading zeros or float conversion). keep_default_na=False keeps blanks
    # as "" so values like "NA" are never turned into nulls.
    chunks = pd.read_csv(path, chunksize=CHUNK_SIZE, dtype=str, usecols=columns,
                         keep_default_na=False)

    filtered_chunks = []
    for df in chunks:
        is_specialty = df[specialty_col].isin(specialty_values)
        in_states = df[state_col].isin(states)
        filtered_chunks.append(df[is_specialty & in_states])
    result = pd.concat(filtered_chunks)

    # The output is pipe-delimited, so any pipes inside values would shift columns.
    result = result.replace(r"\|", " / ", regex=True)

    print(f"{output_path.name}: {len(result):,} rows")
    print(result[state_col].value_counts().to_string(), "\n")
    print(result[specialty_col].value_counts().to_string(), "\n")

    if rename:
        result = result.rename(columns=rename)

    result.to_csv(output_path, sep="|", index=False)
    return result


def main():
    OUTPUT_DIR.mkdir(exist_ok=True)

    filter_derm_rows(
        path=PHY_FILE,
        columns=PHY_COLUMNS,
        specialty_col="Rndrng_Prvdr_Type",
        specialty_values=PHY_SPECIALTIES,
        state_col="Rndrng_Prvdr_State_Abrvtn",
        states=STATES,
        output_path=OUTPUT_DIR / "phys_filtered.txt",
    )
    filter_derm_rows(
        path=DAC_FILE,
        columns=DAC_COLUMNS,
        specialty_col="pri_spec",
        specialty_values=DAC_SPECIALTIES,
        state_col="State",
        states=STATES,
        output_path=OUTPUT_DIR / "dac_filtered.txt",
        rename=DAC_RENAME,
    )


if __name__ == "__main__":
    main()
