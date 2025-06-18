clear all
set more off

* Import merged panel data
import delimited using "final_merged.csv", clear
capture drop year_month
gen year_month = ym(year, month)
format year_month %tm
egen prov_id = group(province)
xtset prov_id year_month

* Import poverty data and keep only 2018
import delimited using "poverty.csv", clear
keep if year == 2018
summarize poverty
scalar p_cutoff = r(p50)
gen high_poverty = poverty > p_cutoff
keep province high_poverty
tempfile povertygroup
save `povertygroup', replace

* Re-import merged panel data and merge poverty split
import delimited using "final_merged.csv", clear
capture drop year_month
gen year_month = ym(year, month)
format year_month %tm
egen prov_id = group(province)
merge m:1 province using `povertygroup'
drop if _merge == 2
drop _merge
xtset prov_id year_month

* Create time fixed effects
capture drop time_id
egen time_id = group(year_month)

* Fisher-type unit root tests: TABLE 3
xtunitroot fisher mean_lights, dfuller lags(1)
xtunitroot fisher exposure, dfuller lags(1)

* Collapse to national average for lag selection
* Lag selection: TABLE 4
preserve
collapse (mean) mean_lights exposure, by(year month)
gen year_month = ym(year, month)
format year_month %tm
tsset year_month
varsoc mean_lights exposure
restore

