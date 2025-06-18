import pandas as pd

# Load datasets
exposure_df = pd.read_csv("exposure.csv")
lights_df = pd.read_csv("lights.csv")

# Melt exposure to long format
exposure_long = exposure_df.melt(id_vars=["adm2_en"], var_name="year_month", value_name="exposure")
exposure_long[['year', 'month']] = exposure_long['year_month'].str.split('-', expand=True).astype(int)
exposure_long = exposure_long.rename(columns={"adm2_en": "province"})

# Aggregate Metro Manila districts
metro_districts = [
    "Metropolitan Manila - 1st District",
    "Metropolitan Manila - 2nd District",
    "Metropolitan Manila - 3rd District",
    "Metropolitan Manila - 4th District"
]
metro_agg = (
    exposure_long[exposure_long["province"].isin(metro_districts)]
    .groupby(["year", "month"])
    .agg({"exposure": "sum"})
    .reset_index()
)
metro_agg["province"] = "Metropolitan Manila"
metro_agg["year_month"] = metro_agg["year"].astype(str) + "-" + metro_agg["month"].apply(lambda x: f"{x:02}")

exposure_cleaned = exposure_long[~exposure_long["province"].isin(metro_districts)]
exposure_cleaned = pd.concat([exposure_cleaned, metro_agg], ignore_index=True)

# Fix province names in lights.csv
lights_df["province"] = lights_df["province"].replace({
    "Shariff Kabunsuan": "Maguindanao",
    "Saranggani": "Sarangani"
})

# Re-aggregate lights
lights_df = (
    lights_df.groupby(["province", "year", "month"], as_index=False)
    .agg({"mean_lights": "sum"})
)

# Normalise province names
def normalize(name):
    return name.strip().lower().replace("-", " ").replace("–", " ")

exposure_cleaned["province_norm"] = exposure_cleaned["province"].apply(normalize)
lights_df["province_norm"] = lights_df["province"].apply(normalize)

# Right join: retain all lights records (some provinces not in exposure but we still want them)
merged_df = pd.merge(
    exposure_cleaned,
    lights_df,
    on=["province_norm", "year", "month"],
    how="right",
    suffixes=('', '_lights')
)

# Fill missing exposure with 0 for provinces only in lights.csv
merged_df["exposure"] = merged_df["exposure"].fillna(0)

# Cleanup and export
merged_df["province"] = merged_df["province"].combine_first(merged_df["province_lights"])
merged_df.drop(columns=["province_norm", "province_lights"], inplace=True, errors='ignore')
merged_df.to_csv("final_merged.csv", index=False)
