# Clinical SDTM Standardization - Demographics Domain

## Project Overview
This program takes a set of mock raw clinical trial data and transforms it into an SDTM-compliant Demographics domain dataset using SAS.

## Project Structure
1. 01_Specs: Contains the data's mapping spec
2. 02_Raw_Data: Contains the raw_dm (demographics) and raw_ex (exposures) datasets
3. 03_Programs: Contains the main program (sdtm_dm.sas), the raw data generator (raw_data_generator.sas), and the log
4. 04_Output: Contains the standardized DM dataset created by sdtm_dm.sas as an output

## Setup & Usage
1. Clone/download the project
2. Configure your paths for input in raw_data_generator.sas and sdtm_dm.sas
3. Run raw_data_generator.sas
4. Run sdtm_dm.sas

## Data Mapping Specification
[Reference to your Google Sheets mapping spec or include link]

## Key Transformations
- Uses macro to perform date conversion to ISO 8601
- Performs age calculation from birth date and reference start date
- Standardizes treatment arm and gender variables

## Author

Kegan Johnson
