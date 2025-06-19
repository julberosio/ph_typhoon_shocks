
# Replication Package for: Estimating Provincial Economic Impacts of Typhoons in the Philippines with Satellite Data and Local Projections
## June 2025

This replication package accompanies Gubbiotti, Osio and Tapia. (2025). "Estimating Provincial Economic Impacts of Typhoons in the Philippines with Satellite Data and Local Projections." Term paper, Barcelona School of Economics.

## Authors

- Alessandro Gubbiotti
- Julber Osio
- Juan Manuel Tapia

## Abstract in English

This paper examines the dynamic effects of typhoon shocks on local economic activity in the Philippines and investigates whether recovery trajectories differ by poverty incidence. Using a physically-simulated wind exposure index and monthly nighttime lights data from 2012 to 2024, we estimate impulse response functions via local projections. We find that poorer provinces experience sharper initial declines but exhibit faster short-run rebounds, followed by significantly weaker medium-run recoveries. These patterns are robust across alternative poverty thresholds. Our findings highlight the unequal temporal burden of climate shocks and underscore the need for sustained support to the poorest regions.

JEL classification: Q54, R11, C23
Keywords: typhoon shock, subnational economic activity, local projections

## Abstract in Filipino

Sinusuri ng pag-aaral na ito ang dinamikong epekto ng mga bagyo sa lokal na gawaing pang-ekonomiya sa Pilipinas, at kung paanong nagkakaiba ang pagbangon ng ekonomiya ayon sa antas ng kahirapan. Gamit ang isang physically-simulated wind exposure index at buwanang datos ng liwanag sa gabi mula 2012 hanggang 2024, tinuos namin ang mga impulse response function sa pamamagitan ng local projections. Lumalabas na mas matindi ang pagbagsak sa mga lalawigang mahihirap, bagaman mas mabilis ang panandaliang pag-angat na sinusundan ng mas mahinang pagbangon sa kalaunan. Ipinapakita ng mga resulta ang hindi pantay na epekto ng bagyo sa pagbangon ng ekonomiya.

Klasipikasyon ng JEL: Q54, R11, C23
Mga susing salita: typhoon shock, panlalawigang gawaing pang-ekonomiya, local projections

# Data availability and provenance statements
### Statement about rights

The author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.

### Summary of availability

All data are publicly available.

### Details on each data source

- Philippine province (administrative level 02) shapefiles are sourced from the National Mapping and Resource Information Authority (NAMRIA) and Philippines Statistics Authority (PSA), and are available for download through the Humanitarian Data Exchange https://data.humdata.org/dataset/cod-ab-phl under a Creative Commons Attribution for Intergovernmental Organisations (CC BY-IGO) licence.
- Philippine Area of Responsibility (PAR) shapefile is sourced from the Philippine Atmospheric, Geophysical and Astronomical Services Administration (PAGASA), and is available for download through the Humanitarian Data Exchange https://data.humdata.org/dataset/philippine-area-of-responsibility-par-polygon under a Creative Commons Attribution for Intergovernmental Organisations (CC BY-IGO) licence.
- The typhoon track data are sourced from the International Best Track Archive for Climate Stewardship (IBTrACS), maintained by NOAA’s National Centers for Environmental Information. The data are available at: https://www.ncei.noaa.gov/products/international-best-track-archive and are distributed under a World Data Center open data policy.
- The nighttime lights data are derived from the VIIRS Day/Night Band (DNB) monthly cloud-free composites (VCM-CFG), accessed via Google Earth Engine from NOAA’s Earth Observation Group. The dataset is available at: https://eogdata.mines.edu/download_dnb_composites.html and is released under a U.S. Government Public Domain licence.
- Poverty incidence estimates at the provincial level are sourced from the Philippine Statistics Authority’s OpenStat portal. The data are publicly available at: https://openstat.psa.gov.ph/ and are provided under the Philippines' Open Data Licence.

# Description of programmes/code

- The JavaScript code `code_data/00_province_lights.js` will extract raster data from VIIRS and aggregate mean nighttime light pixel values for each Philippine province per month. The output file is `lights.csv`.
- The typhoon exposure index `exposure.csv` is created in QGIS. Please refer to `shapefiles/` for the shapefiles and `logs/` for the QGIS logs.
- The Python code `code_data/01_merge_data.py` will clean, harmonise, and merge typhoon exposure `exposure.csv` and mean nighttime light `lights.csv` per Philippine province. The output file is `final_merged.csv`.
- The Stata code `code_data/02_diagnostics.do` will run stationarity and lag selection tests on `final_merged.csv`.
- The Matlab code `code_data/03_loc_proj.m` will run the main local projections model with bootstrapping using `final_merged.csv`, and will create the output `figures/baseline_gap_.pdf`.
- The Matlab code `code_data/03_loc_proj.m` will run the robustness check model with bootstrapping using `final_merged.csv`, and will create the outputs `figures/robust_low.pdf`, `figures/robust_high.pdf`, and `figures/robust_gap.pdf`.

# List of tables and figures

The provided code reproduces all tables and figures in the paper, except for maps.

| Figure/Table #    | Program                  | Line Number | Output file                      |
|-------------------|--------------------------|-------------|----------------------------------|
| Figure 1           | code_data/03_loc_proj.m    |    123         | figures/baseline_gap_.pdf                 |
| Figure 2           | code_data/04_loc_proj_robust.m | 122          | figures/robust_low.pdf                     |
| Figure 3           | code_data/04_loc_proj_robust.m| 141        | figures/robust_high.pdf                      |
| Figure 4          | code_data/04_loc_proj_robust.m           |    160         | figures/robust_gap.pdf                                 |
| Table 1          | code_data/03_loc_proj.m      |     188        |                     |
| Table 2          | code_data/04_loc_proj_robust.m      |     179        |            |
| Table 3 | code_data/02_diagnostics.do | 37 ||
| Table 4 | code_data/02_diagnostics.do | 42 ||

### Replicating maps in QGIS

Follow the instructions to replicate each map in QGIS.

| Figure # | Shapefiles | Instructions |
|-------------------|--------------------------|----------------------------------|
| Figure 5 | shapefiles/par.shp shapefiles/typhoons_par.shp | |
| Figure 6 | shapefiles/ph_provinces_data.shp shapefiles/typhoons_par.shp shapefiles/typhoon_buffer.shp | Symbology: Graduated final_merged_wide_exposure_2012_12. Filter "NAME" LIKE 'BOPHA' AND "SEASON" = 2012 |
| Figure 7 | shapefiles/ph_provinces_data.shp | Symbology: Graduated final_merged_wide_mean_lights_2018_01 |
| Figure 8 | shapefiles/ph_provinces_data.shp | Symbology: Graduated poverty_wide_poverty_2018 |

# References

- Elvidge, C. D. et al. (2017). “VIIRS night-time lights”. In: *International Journal of Remote Sensing* 38.21, pp. 5860–5879.
- Gahtan, J. et al. (2024). *International Best Track Archive for Climate Stewardship (IBTrACS) Project, Version 4r01.* NOAA National Centers for Environmental Information.
- Knapp, K. R. et al. (2010). “The International Best Track Archive for Climate Stewardship (IBTrACS): Unifying tropical cyclone best track data”. In: *Bulletin of the American Meteorological Society* 91.3, pp. 363–376.

### Licence for Code

The code is licensed under a MIT licence. See [LICENSE.txt](LICENSE.txt) for details.
