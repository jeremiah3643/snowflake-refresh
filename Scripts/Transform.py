import pandas as pd

PHYDATA = "..\\Data\\PHY_R26_P05_V10_D24_Prov_Svc.csv"
DACDATA = "..\\Data\\DAC_NationalDownloadableFile.csv"

##PHYDATA = "..\\Data\\PHY_sample.csv"
##DACDATA = "..\\Data\\DAC_sample.csv"

phy_columns = ["Rndrng_NPI", "Rndrng_Prvdr_Ent_Cd", "Rndrng_Prvdr_City", "Rndrng_Prvdr_State_Abrvtn",
               "Rndrng_Prvdr_Zip5", "Rndrng_Prvdr_Type", "Rndrng_Prvdr_Mdcr_Prtcptg_Ind",
               "HCPCS_Cd", "HCPCS_Desc", "HCPCS_Drug_Ind", "Place_Of_Srvc",
               "Tot_Benes", "Tot_Srvcs", "Tot_Bene_Day_Srvcs",
               "Avg_Sbmtd_Chrg", "Avg_Mdcr_Alowd_Amt", "Avg_Mdcr_Pymt_Amt", "Avg_Mdcr_Stdzd_Amt"]
dac_columns = ["NPI", "Ind_PAC_ID", "pri_spec", "sec_spec_all", "Facility Name", "org_pac_id", "num_org_mem", "adr_ln_1", "adr_ln_2", "City/Town", "State", "ZIP Code", "adrs_id"]

phy = "Rndrng_Prvdr_Type"
dac = "pri_spec"
phy_state = "Rndrng_Prvdr_State_Abrvtn"
dac_state = "State"
states = ["TN", "KY", "VA", "NC", "GA", "AL", "MS", "AR", "MO"]
output = "..\\Output\\"

dac_rename = {"Facility Name": "Facility_Name", "City/Town": "City_Town", "ZIP Code": "ZIP_Code"}

phy_spec = ["Dermatology", "Micrographic Dermatologic Surgery"]
dac_spec = ["DERMATOLOGY", "MICROGRAPHIC DERMATOLOGIC SURGERY (MDS)"]

def filter_derm_rows(path, columns, search_col, spec_values, state_col, states, outputfilename, rename=None):
    # Read the file 100k rows at a time so the whole file never sits in memory
    # keep_default_na=False keeps blanks as "" instead of NaN
    chunks = pd.read_csv(path, chunksize=100_000, dtype=str, usecols=columns, keep_default_na=False)
    filtered_chunks = []
    for df in chunks:
        is_derm = df[search_col].isin(spec_values)
        in_states = df[state_col].isin(states)
        filtered_chunks.append(df[is_derm & in_states])

    # Combine the matches; swap any pipes in the data so they don't break the delimiter
    result = pd.concat(filtered_chunks)
    result = result.replace(r'\|', ' / ', regex=True)

    # Per-state row counts to check against Snowflake after loading
    print(outputfilename, "rows per state:")
    print(result[state_col].value_counts())
    print(outputfilename, "rows per specialty:")
    print(result[search_col].value_counts())

    if rename:
        result = result.rename(columns=rename)

    # Write once, pipe-delimited (overwrites the file each run)
    result.to_csv(output + outputfilename + "_filtered.txt", sep='|', index=False)
    return result


filter_derm_rows(PHYDATA, phy_columns, phy, phy_spec, phy_state, states, "phys")
filter_derm_rows(DACDATA, dac_columns, dac, dac_spec, dac_state, states, "dac", rename=dac_rename)
