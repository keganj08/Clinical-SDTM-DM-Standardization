/******************************************************************************
* Program: sdtm_dm.sas
* Purpose: Create SDTM Demographics (DM) domain from mock raw clinical trial data
* 
* Description:
*   This program reads raw demographics (raw_dm) and exposure (raw_ex) data,
*   applies SDTM standardization rules, and outputs a compliant DM dataset.
*   Key transformations include:
*   - ISO 8601 date conversion via macro
*   - Treatment arm mapping and standardization
*   - Age calculation from birth date and reference start date
*   - Gender standardization to controlled terminology
*
* Input Datasets:
*   - raw.raw_dm: Raw demographics (subjid, gender, brthdt)
*   - raw.raw_ex: Raw exposure records (subjid, exstdtc, trt)
*
* Output Dataset:
*   - sdtm.dm: SDTM-compliant Demographics domain
*
* Instructions:
*   1. Ensure raw datasets exist in 02_Raw_Data folder
*   2. Update the root path below to match your project location
*   3. Run this entire program
*   4. Review log for warnings/errors
*   5. Verify output in 04_SDTM folder
*
*
* Notes:
*   - RACE set to "UNKNOWN" (not collected in study)
*   - ACTARM equals ARM (no unplanned treatment assignments)
*   - Log automatically saved to 03_Programs/Logs/
*
* Author: Kegan Johnson
******************************************************************************/

/* MACROS */

/* Tries to convert dates to ISO 8601 */
%macro dt_to_iso(in_var, out_var);
	&out_var = "";
	if missing(&in_var) then &out_var = "";
	else do;
		_temp_date = input(&in_var, anydtdte32.);
		if _temp_date ^= . then &out_var = put(_temp_date, is8601da.);
		else do;
			&out_var = "";
		end;
	end;
%mend dt_to_iso;
	

/* USER SETUP: Before running, change this path to your local project folder. */
%let root = /home/u63530371/Clinical_SDTM_Project_DM;

libname raw "&root/02_Raw_Data";
libname prgrms "&root/03_Programs";
libname sdtm "&root/04_Output";

/* Redirect log to file */
proc printto log="&root/03_Programs/Logs/dm_program_log.txt" new;
run;

/* CREATE SORTED HELPER DATASETS */
proc sort data=raw.raw_dm out=work.dm_sorted;
	by SUBJID; /* Sort by subjects to match ex_sorted */
run;

proc sort data=raw.raw_ex out=ex_sorted;
	by SUBJID exstdtc; /* Sort by subjects, then ascending: Earliest date first */
run;

/* Get earliest date */
data ex_first;
	set ex_sorted;
	by SUBJID;
	if first.SUBJID; /* Select only the observation with the earliest date for this subject */
	keep SUBJID exstdtc trt;
run;

/* Get latest date */
data ex_last;
	set ex_sorted;
	by SUBJID;
	if last.SUBJID; /* Select only the observation with the latest date for this subject */
	keep SUBJID exstdtc trt;
run;

/* MAIN ENGINE */
data sdtm.dm;
	
	/* SET UP ATTRIBUTES ACCORDING TO THE SDTM */
	length
		/* Identifiers */
	    STUDYID  $8		/* Lenghts set to lengths of longest data values */
	    DOMAIN   $2
	    USUBJID  $40
	    SUBJID   $10
	    SITEID   $3
	    
	    /* Timing */
	    RFSTDTC  $19	/* Numeric */
	    RFENDTC  $19
	    RFXSTDTC $19
	    RFXENDTC $19
	    RFICDTC  $19
	    RFPENDTC $19
	    DTHDTC   $19
	    DTHFL    $1
	    BRTHDTC  $19
	    
	    /* Demographics */
	    AGE		  8    	/* Numeric */
	    AGEU     $10
	    SEX      $1
	    RACE     $60
	    
	    /* Treatment / Arms */
	    ARMCD    $20
	    ARM      $60
	    ACTARMCD $20
	    ACTARM   $60
	    ARMNRS   $20
	    ACTARMUD $20
	    COUNTRY  $3;
	
	/* Merge raw_dm and raw_es */
	merge work.dm_sorted (in=a)
		work.ex_first (in=b rename=(exstdtc = raw_start trt=trt_first))
		work.ex_last  (in=c rename=(exstdtc = raw_end trt=trt_last)); /* Perform two merges in succession, keeping date and treatment from both ex_first and ex_last */
	by SUBJID;
	if a; /* Keep a */
	
	/* Logic */
	STUDYID = "DEMO-001";
	DOMAIN = "DM";
	SITEID = "001";
	USUBJID = CATX("-", STUDYID, SITEID, SUBJID); /* CATX is ideal for concatenation within one observation */
	
	/* Timing logic */
	%dt_to_iso(raw_start, 	RFSTDTC);
	%dt_to_iso(raw_end, 	RFENDTC);
	%dt_to_iso(raw_start, 	RFXSTDTC);
	%dt_to_iso(raw_end, 	RFXENDTC);
	%dt_to_iso(brthdt, 		BRTHDTC);
	
	/* Variables that are expected but not available; Recorded as missing */
	RFICDTC = "";
	RFPENDTC = ""; 
	DTHDTC = ""; 
	DTHFL = ""; 
	RACE = "UNKNOWN";

	if not missing(brthdt) and not missing(raw_start) then do;
		_dt1 = input(brthdt, anydtdte32.);
		_dt2 = input(raw_start, anydtdte32.);
		AGE = floor(yrdif(_dt1, _dt2, 'AGE')); /* Calculate time between subject birth and reference start. More robust for age than intick() */
		if AGE < 0 or AGE > 125 then put "WARNING: Suspect AGE calculated: " AGE= USUBJID=;
		AGEU = "YEARS";
	end;
	
	_temp_sex = upcase(strip(gender));
	select (_temp_sex);
		when("M", "MALE") do;
			SEX = "M";
		end;
		when ("F", "FEMALE") do;
			SEX = "F";
		end;
		otherwise do;
			SEX = "U";
		end;
	end;

	_temp_arm = upcase(strip(trt_first));
	select (_temp_arm);
		when("PLACEBO") do;
			ARMCD 	= "PLACEBO";
			ARM 	= "Placebo";
			ARMNRS 	= "";
		end;
		when ("DRUG_A") do;
			ARMCD 	= "TRTA";
			ARM 	= "Drug A";
			ARMNRS 	= "";
		end;
		when ("DRUG_B") do;
			ARMCD 	= "TRTB";
			ARM 	= "Drug B";
			ARMNRS 	= "";
		end;
		when ("") do;
			ARMCD 	= "";
			ARM 	= "";
			ARMNRS	= "NOT ASSIGNED";
		end;
		otherwise do;
			ARMCD 	= "";
			ARM 	= "";
			ARMNRS	= "NOT ASSIGNED";
			put "WARNING: Unexpected treatment found: " _temp_arm= " for " USUBJID=;
		end;
	end;
	
	ACTARMCD 	= ARMCD; /* This is true in this data set with only one treatment variable */
	ACTARM		= ARM;
	ACTARMUD	= "";
	
	COUNTRY = "USA";

	drop _temp_date _dt1 _dt2 _temp_arm _temp_sex;

	keep STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC DTHDTC DTHFL 
			SITEID BRTHDTC AGE AGEU SEX RACE ARMCD ARM ACTARMCD ACTARM ARMNRS ACTARMUD COUNTRY;
run;

proc printto;
run;
