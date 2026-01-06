/******************************************************************************
* Program: generate_raw_data.sas
* Purpose: Generate simulated raw data for SDTM DM domain project
* Note: This creates test data only - not real clinical trial data
* 
* Instructions:
* 1. Update the root path below to match your project location
* 2. Run this entire program to create raw_dm and raw_ex datasets
* 3. Verify datasets were created in 02_Raw_Data folder
*
* Author: Kegan Johnson
******************************************************************************/

/* USER SETUP: Before running, hange this path to your local project folder */
%let root = /home/u63530371/Clinical_SDTM_Project_DM;

/* Define library pointing to raw data folder */
libname source "&root/02_Raw_Data";

/* 1. Raw Demographics */
data source.raw_dm;
   length subjid $10 gender $10 brthdt $20;
   input subjid $ gender $ brthdt $;
   datalines;
   101 Male 1990-05-15
   102 female 10JAN1985
   103 M 03/22/1972
   104 . 1995-12-01
   ;
run;

/* 2. Raw Exposure */
data source.raw_ex;
   length subjid $10 exstdtc $20 trt $10;
   input subjid $ exstdtc $ trt $;
   datalines;
   101 2023-01-01 Placebo
   101 2023-01-15 Placebo
   102 2023-02-01 Drug_A
   103 2023-03-10 Drug_B
   104 2023-04-01 Placebo
   ;
run;