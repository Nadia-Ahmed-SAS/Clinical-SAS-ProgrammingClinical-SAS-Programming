
/*************************************************************************
* PROJECT:END-to-END Clinical Data Standardization and Reporting Pipeline(SDTM/ADaM)
* PROTOCOL: BEL-2026-041 (Human Medicine)
* PROGRAM NAME: 01_Standardization_Setup.sas
* AUTHOR: NADIA AHMED ALHASAN
* DATE: 2026
* DESCRIPTION: Global setup and raw data ingestion.
* Compliance with CDISC SDTM IG v3.4.
*************************************************************************
/* 1. INITIALIZATION: Set Environment Paths Control */
%let root = /home/u64371687/nadia_clinical_project;

/* Defining Library Architecture based on Study Folder Structure */
libname Raw "&root/Raw_data"; /* Source Data */
libname SDTM "&root/SDTM_data"; /* Tabulation Data */
libname QUERY "&root/QUERY"; /* Data Quality Checks */
libname ADam "&root/ADam"; /* Analysis Data */

/*=======================================================

 Global Macro for Today's Date - Used for Integrity Checks
 ========================================================*/
%let run_date = %sysfunc(today());

/* Output Destinations */
ods pdf file="&root/Output/Final_Clinical_Report.pdf" style=Pearl;
ods excel file="&root/Output/Clinical_Data_Export.xlsx";

/*================================================
 RAW DATA INGESTION:demographics  (dm)
=================================================*/

data Raw.dm_raw;

    attrib
   
        USUBJID length=$10 label="Unique Subject Identifier"
        RFSTDTC length=$10 label="Subject Reference Start Date"
        SEX length=$1 label="Sex"
        AGE  label="Age";
    input USUBJID  RFSTDTC  SEX  AGE;
    datalines;
001 2026-01-10 m 45
002 2026-02-01 f 32
003 2026-01-01 . 50
004 2026-02-01 m 28
005 2026-01-01 m 60
006 2026-02-21 f 110
;
run;
proc export data=Raw.dm_raw outfile="&root/Raw_data/dm_raw.csv"
dbms=csv
replace;
run;
proc import datafile="&root/Raw_data/dm_raw.csv" out=Raw.dm_raw dbms=csv replace;
     getnames=yes; guessingrows=max;
run;


/*===========================================================
 DICTIONARY MAPPING: MedDRA v26.0 (Standard Coding)
 =========================================================*/
proc format;
    /* Mapping Reported Terms to MedDRA Preferred Terms (PT) */
    value $ae_pt
        "Diarrhea", "Loose_Stool" = "Diarrhoea"
        "Stomach_Pain" = "Abdominal Pain"
        "Pregnancy" = "Pregnancy"
        "Fever" = "Pyrexia";

    /* Mapping to System Organ Class (SOC) */
    value $ae_soc
        "Diarrhea", "Loose_Stool", "Stomach_Pain" = "Gastrointestinal disorders"
        "Pregnancy" = "Pregnancy, puerperium and perinatal conditions"
        "Fever" = "General disorders and administration site conditions";

    /* Mapping to MedDRA Lowest Level Term (LLT) Codes */
    value $ae_llt
        "Diarrhea", "Loose_Stool" = "10012735"
        "Stomach_Pain" = "10000081"
        "Pregnancy" = "10036585"
        "Fever" = "10016558";
run;

/*===============================================
4. RAW DATA INGESTION: Adverse Events (AE)
=================================================*/
data Raw.ae_raw;
    attrib
        USUBJID length=$10 label="Unique Subject Identifier"
        AETERM length=$40 label="Reported Term for Adverse Event"
        AESTDTC length=$10 label="Start Date of Adverse Event"
        AESEV length=$10 label="Severity/Intensity"
        AESER length=$1 label="Serious Event (Y/N)";
    input USUBJID  AETERM  AESTDTC  AESEV  AESER ;
    datalines;
001 Diarrhea 2026-01-05 SEVERE N
001 Fever    2026-01-20 MILD  N
002 Loose_Stool 2026-02-30 MILD Y
003 Stomach_Pain 2026-13-12 MODERATE N
004 Pregnancy 2026-06-15 MILD N
005 Fever . SEVERE Y
006 Stomach_Pain 2026-02-03 MODERATE N
;
run;
proc export data=Raw.ae_raw outfile="&root/Raw_data/ae_raw.csv"
dbms=csv
replace;
run;

proc import datafile="&root/Raw_data/ae_raw.csv" out=Raw.ae_raw dbms=csv replace;
     getnames=yes; guessingrows=max;
run;
/*=============================================
5. RAW DATA INGESTION: Vital Signs (VS)
===============================================*/
data Raw.vs_raw;
    attrib
        USUBJID length=$10 label="Unique Subject Identifier"
        VSTEST length=$20 label="Vital Signs Test Name"
        VSORRES length=8 label="Result as Collected"
        VSORRESU length=$10 label="Original Units"
        VSDTC length=$10 label="Date of Measurement"; /* Added $ here because VSDTC is a charcter format*/
    input USUBJID VSTEST VSORRES VSORRESU VSDTC ; /* setting character date */
    datalines;
001 Temp 37.5 C 2026-01-10
001 Weight 70.0 kg 2026-01-10
002 Temp 102.2 F 2026-02-05
002 Weight 154.3 lb 2026-02-05
003 Temp 45.0 C 2026-01-01
005 Weight 110.0 kg 2026-01-15
006 Temp 37.1 C 2026-02-02
;
run;
proc export data=Raw.vs_raw outfile="&root/Raw_data/vs_raw.csv"
dbms=csv
replace;
run;

proc import datafile="&root/Raw_data/vs_raw.csv" out=Raw.vs_raw dbms=csv replace;
     getnames=yes; guessingrows=max;
run;
/*===========================================
6. RAW DATA INGESTION: Laboratory (LB)
=============================================*/
data Raw.lb_raw;
    attrib
        USUBJID length=$10 label="Unique Subject Identifier"
        LBTEST length=$20 label="Lab Test Name"
        LBORRES length=8 label="Numeric Result"
        LBORRESU length=$10 label="Original Units"
        LBNRLO length=8 label="Reference Low"
        LBNRHI length=8 label="Reference High"
        LBDT  length=8 label="Collection Date" format=yymmdd10.;
        /*Reading dates in ISO 8601 format(YYYY-MM_DD)*/
       
    input USUBJID  LBTEST  LBORRES LBORRESU  LBNRLO  LBNRHI LBDT:yymmdd10.;
    datalines;
001 Glucose   300     mg/dL      70   100  2026-02-01
001 ALT        150     U/L      7    55   2026-02-05
002 ALT         40    U/L      7    55    2026-02-05
002 Bilirbin    1.5   mg/dl   0.1   1.2  2026-02-06
003 Cholesterol 280  mg/dL    120   200   2026-02-10
004 Glucose     75    mg/dl    70   100    2026-02-13
005 ALT         7.4   U/L      7    55     2026-02-15
006 Cholesterol  125    mg/dl   120  200   2026-02-02
;
run;
proc export data=Raw.lb_raw outfile="&root/Raw_data/lb_raw.csv"
dbms=csv
replace;
run;

proc import datafile="&root/Raw_data/lb_raw.csv" out=Raw.lb_raw dbms=csv replace;
     getnames=yes; guessingrows=max;
run;
/*******************************************************/
/* 7_RAW DATA INGESTION: EXPOSURE (EX) */
/***********************************************/

data Raw.ex_raw;

    attrib
        USUBJID length=$10 label="Unique Subject Identifier"
        EXTRT length=$20 label="Name of Treatment"
        EXDOSE length=8 label="Dose Amount"
        EXDOSU length=$10 label="Dose Units"
        EXSTDTC length=$10 label="Start Date of Treatment"
        EXENDTC length=$10 label="End Date of Treatment" format=yymmdd10.;
       input
  USUBJID EXTRT  EXDOSE EXDOSU  EXSTDTC  EXENDTC ;
 
  datalines;
   
001 Drug_A 50 mg 2026-01-10 2026-01-20
002 Drug_A 100 mg 2026-02-01 2026-02-15
003 Placebo 0 mg 2026-03-01 2026-03-14
004 Drug_B 25 mg 2026-06-01 2026-06-15
005 Drug_A 50 mg 2026-01-16 2026-01-30
006 Placebo 0 mg 2026-03-01 2026-03-14
;
run;
proc export data=Raw.ex_raw outfile="&root/Raw_data/ex_raw.csv"
dbms=csv
replace;
run;

proc import datafile="&root/Raw_data/ex_raw.csv" out=Raw.ex_raw dbms=csv replace;
     getnames=yes; guessingrows=max;
run;
/*=======================================
 8. RAW DATA INGESTION: Disposition (DS)
==========================================*/
data Raw.ds_raw;
    attrib
        USUBJID length=$10 label="Unique Subject Identifier"
        DSDECOD length=$40 label="Standardized Disposition Term"
        DSSTDTC length=$10 label="Date of Disposition Event";
    input USUBJID DSDECOD $ DSSTDTC $;
    datalines;
001 COMPLETED 2026-01-20
002 COMPLETED 2026-02-15
003 COMPLETED 2026-03-14
004 ADVERSE_EVENT 2026-06-10
005 COMPLETED 2026-01-30
006 WITHDRAWAL_BY_SUBJECT 2026-03-05
;
run;

proc export data=Raw.ds_raw outfile="&root/Raw_data/ds_raw.csv"
dbms=csv
replace;
run;


proc import datafile="&root/Raw_data/ds_raw.csv" out=Raw.ds_raw dbms=csv replace;
     getnames=yes; guessingrows=max;
run;


/*======================================================================================================
 9.standardizing USUBJID to a  3-digit character format(z3.) across all raw domainsfor seamless merging
=====================================================================================================*/

data Raw.dm_raw (drop=temp_id);
    set Raw.dm_raw (rename=(USUBJID=temp_id));
 
    USUBJID = put(temp_id, z3.);
run;

data Raw.ds_raw (drop=temp_id);
    set Raw.ds_raw (rename=(USUBJID=temp_id));
 
    USUBJID = put(temp_id, z3.);
run;
data Raw.ae_raw (drop=temp_id); set Raw.ae_raw (rename=(USUBJID=temp_id)); USUBJID = put(temp_id, z3.); run;
data Raw.vs_raw (drop=temp_id); set Raw.vs_raw (rename=(USUBJID=temp_id)); USUBJID = put(temp_id, z3.); run;
data Raw.lb_raw (drop=temp_id); set Raw.lb_raw (rename=(USUBJID=temp_id)); USUBJID = put(temp_id, z3.); run;
data Raw.ex_raw (drop=temp_id); set Raw.ex_raw (rename=(USUBJID=temp_id)); USUBJID = put(temp_id, z3.); run;

/*=================================================================================

   10.quality control (QC) section:verifying raw data ingestion and id standardization integrity
 ==============================================================================================*

/* Printing all rows for small datasets to ensure full audit */

/* Title 1 stays constant for all following reports */
title1 "Project: BEL-2026-041 - Human Clinical Trial";

/* Table 1 */
title2 "Raw Data Audit: Demographics (dm_raw)";

proc print data=Raw.dm_raw noobs;
run;

/* Table 2 - This replaces the previous title2 but keeps title1 */

title2 "Raw Data Audit: Adverse Events (ae_raw)";

proc print data=Raw.ae_raw noobs;
run;

/* Table 3 */
title2 "Raw Data Audit: Vital Signs (vs_raw)";
proc print data=Raw.vs_raw noobs;
run;

/* Table 4 */
title2 "Raw Data Audit: Laboratory (lb_raw)";
proc print data=Raw.lb_raw noobs;
run;

/* Table 5 */
title2 "Raw Data Audit: Disposition (ds_raw)";
proc print data=Raw.ds_raw noobs;
run;

/* Table  6*/
title2 "Raw Data Audit: Exposure (ex_raw)";
proc print data=Raw.ex_raw noobs;
run;
/* Clear all titles at the end */
title;

/*=====================================
global macro for protocol
=======================================*/


%let studyid= BEL-2026-041;

/*=============================================
11-SDTM mapping:standardizing demographic(DM)
domain based on CDISC implementation Guide
============================================*/

data SDTM.dm_final;
    set Raw.dm_raw;
 
 
 /*new administtrative columns*/

attrib STUDYID length=$20 label="study identifier"

        DOMAIN   length=$2   label="Domain Abbreviation";
       
        STUDYID ="&studyid";
        Domain   ="DM";

    /* A. Variable Standardization: Convert SEX to Uppercase and handle Missing */
    if missing(SEX) then SEX = 'U'; /* 'U' for Unknown as per CDISC */
    else SEX = upcase(SEX);
   
    /* B. Controlled Terminology: Age Units must be consistent */
    attrib AGEU length=$20 label="Age Units";
    AGEU = "YEARS";
   
    /* C. Regional Requirement: Country Code (ISO 3166) */
    attrib COUNTRY length=$3 label="Country";
    COUNTRY = "BEL"; /* Study conducted in Belgium */

    /* D. Final Metadata: Applying Standard Labels */
    label
        USUBJID = "Unique Subject Identifier"
        RFSTDTC = "Subject Reference Start Date"
        SEX = "Sex of Subject"
        AGE = "Age of Subject"
        AGEU = "Age Units"
        COUNTRY = "Country Code";
run;

/*=========================================
12-Merging DM and  AE domains to bring in
(RFSTDTC)for study day calculation (AESDY)
==========================================*/

proc sql;
    create table work.ae_joined as
    select
        d.RFSTDTC,
        a.USUBJID, a.AETERM, a.AESTDTC, a.AESEV, a.AESER
    from SDTM.dm_final d
    left join Raw.ae_raw a on d.USUBJID = a.USUBJID
    where a.AETERM ne ""; /* Exclude subjects with no AEs */
quit;



/*==============================================
 13-SDTM AE mapping :implementing MedDRA coding
calculating study day(AESDY) using clinical logic
SDTM AE mapping(Modified with SEQ)
=======================================*/

proc sort data=work.ae_joined out=ae_sorted;
by USUBJID AESTDTC;
run;


data SDTM.ae_final;
    set ae_sorted;
    by USUBJID;
   
attrib STUDYID length=$20 label="study identifier"

        DOMAIN   length=$2   label="Domain Abbreviation"
             AESEQ   length=8
             label="Sequence Number";
             
        STUDYID ="&studyid";
        Domain   ="AE";
        if first.USUBJID then AESEQ =1;
        else AESEQ+1;
        retain AESEQ;
   
    /* A. MedDRA Coding using Pre-defined Formats */
    attrib
        AEPT length=$40 label="Preferred Term"
        AESOC length=$40 label="System Organ Class"
        AELLTCD length=8 label="Low Level Term Code";
       
    AEPT = put(AETERM, $ae_pt.);
    AESOC = put(AETERM, $ae_soc.);
    AELLTCD = input(put(AETERM, $ae_llt.), 8.);

/*b.Numeric date conversion and handling mixed data types*/
/*checks if variable is character'c' or Numeric 'N' to prevent log errors*/
 
    if vtype(AESTDTC) = 'C' then _dt_ae = input(strip(AESTDTC), ?? anydtdte10.);
    else _dt_ae = AESTDTC;

    if vtype(RFSTDTC) = 'C' then _dt_rf = input(strip(RFSTDTC), ?? anydtdte10.);
    else _dt_rf = RFSTDTC;

    /* apply iso 8601 format for display purposes*/
    format _dt_ae _dt_rf is8601da.;

    attrib AESDY length=8 label="Analysis Study Day";
   
    /* study day calculation (standard CDISC clincal Logic) */
    if _dt_ae ne . and _dt_rf ne . then do;
    /*if AE occure  on or after study start date*/
        if _dt_ae >= _dt_rf then AESDY = (_dt_ae - _dt_rf) + 1;
       
        /*CDISC LOGIC:study day=(date of event-referce start date)+1 if
        event is on or after start date*/
       
        /*if occure before study start date*/
        else AESDY = (_dt_ae - _dt_rf);
    end;
    /*d.final cleanup*/
    drop _dt_ae _dt_rf;
run;

/*==================================================
 14. SDTM MAPPING: Vital Signs (VS Domain)

 Sorting  vital signs data by subject and test to ensure correct squence for
 VISIT/VSSEQ
 =========================================================*/


proc sort data=Raw.vs_raw out=vs_sorted;
    by USUBJID VSTEST;
run;


data SDTM.vs_final;
    set vs_sorted;
    by USUBJID;

    attrib STUDYID length=$20 label="Study Identifier"
           DOMAIN length=$2 label="Domain Abbreviation"
           VSSEQ length=8 label="Sequence Number"
           VSTESTCD length=$8 label="Vital Signs Test Short Code"
           VSSTRESN length=8 label="Numeric Result (Std Units)"
           VSSTRESU length=$10 label="Standard Units"
           VSDTC label="Date/Time of Measurements"; /*  add date for SDTM */

    STUDYID = "&studyid";
    DOMAIN = "VS";

    /* setting the short code for the scan */
   
    if VSTEST = 'Temp' then VSTESTCD = 'TEMP';
    else if VSTEST = 'Weight' then VSTESTCD = 'WEIGHT';
    else VSTESTCD = substr(upcase(strip(VSTEST)),1,8);

    /* converting standard units*/
    if VSTEST = 'Temp' then do;
        if VSORRESU = 'F' then VSSTRESN = (VSORRES - 32) * 5/9;
        else VSSTRESN = VSORRES;
        VSSTRESU = 'C';
    end;
    else if VSTEST = 'Weight' then do;
        if VSORRESU = 'lb' then VSSTRESN = VSORRES * 0.4535;
        else VSSTRESN = VSORRES;
        VSSTRESU = 'kg';
    end;
    else VSSTRESN = VSORRES;

    /* sequence numbering*/
    retain VSSEQ;
    if first.USUBJID then VSSEQ = 1;
    else VSSEQ + 1;
run;


/* ========================================================================
   15. SDTM MAPPING: Laboratory Results (LB Domain)
 

 Step 1: Sorting raw data to ensure chronological order by subject and test
============================================================================*/


proc sort data=Raw.lb_raw out=lb_sorted;
    by USUBJID LBTEST LBDT;
run;

data SDTM.lb_final;
    set lb_sorted;
    by USUBJID;
   

    /* 1. identify the  new variable with fixed lenghts before conditions*/
   
    length LBSTRESU $12 LBTESTCD $8 LBNRIND $10;
    attrib LBSTRESN length=8 label="Numeric Result (Std Units)";
  /* Step 2: Define Administrative Variables and Metadata Attributes */
    attrib STUDYID length=$20 label="Study Identifier"
           DOMAIN length=$2 label="Domain Abbreviation"
           LBSEQ length=8 label="Sequence Number";
   
    STUDYID = "&studyid";
    DOMAIN = "LB";
    /* 2.  the logic of transformation using new variable names */
    if upcase(strip(LBTEST)) = 'GLUCOSE' then do;
        LBSTRESN = LBORRES * 0.0555;
        LBSTRESU = 'mmol/L';
        LBTESTCD = 'GLUC';
    end;
   
    else if upcase(strip(LBTEST)) = 'BILIRBIN' then do;
        LBSTRESN = LBORRES * 17.1;
        LBSTRESU = 'umol/L';
        LBTESTCD = 'BILI';
    end;

    else if upcase(strip(LBTEST)) = 'CHOLESTEROL' then do;
        LBSTRESN = LBORRES * 0.0259;
        LBSTRESU = 'mmol/L';
        LBTESTCD = 'CHOL';
    end;

    else if upcase(strip(LBTEST)) = 'ALT' then do;
        LBSTRESN = LBORRES;
        LBSTRESU = 'U/L';
        LBTESTCD = 'ALT';
    end;

    /* 3. calculating the normal range index */
    if LBSTRESN > LBNRHI then LBNRIND = 'HIGH';
    else if . < LBSTRESN < LBNRLO then LBNRIND = 'LOW';
    else if LBSTRESN ne . then LBNRIND = 'NORMAL';

    /* 4. Sequence Number */
    retain LBSEQ;
    if first.USUBJID then LBSEQ = 1;
    else LBSEQ + 1;
run;



/*==================================================
 16. SDTM MAPPING: Exposure (EX Domain) - FIXED
 =========================================================*/

proc sort data=Raw.ex_raw out=ex_sorted;
    by USUBJID EXSTDTC;
run;

data SDTM.ex_final;
    /*1. ideintfy the length for Exposure _final*/
    length STUDYID $20 DOMAIN $2 EXTRT $40 EXDOSU $20 EXSTDTC EXENDTC $19;
   
    attrib STUDYID label="Study Identifier"
           DOMAIN label="Domain Abbreviation"
           EXSEQ length=8 label="Sequence Number"
           EXTRT label="Name of Actual Treatment"
           EXDOSE length=8 label="Dose per Administration"
           EXDOSU label="Dose Units"
           EXSTDTC label="Start Date/Time of Treatment"
           EXENDTC label="End Date/Time of Treatment";

    /* 2.Read the data with the old date name changed to avoid type conflicts.*/
   
    set ex_sorted (rename=(EXSTDTC=raw_stdtc EXENDTC=raw_endtc));
    by USUBJID;

    STUDYID = "&studyid";
    DOMAIN = "EX";

    /* 3. converting the date from the old format to the new  character*/
    if vtype(raw_stdtc) = 'N' then EXSTDTC = put(raw_stdtc, yymmdd10.);
    else EXSTDTC = raw_stdtc;

    if vtype(raw_endtc) = 'N' then EXENDTC = put(raw_endtc, yymmdd10.);
    else EXENDTC = raw_endtc;

    /* cleaing and numbering*/
    EXTRT = upcase(strip(EXTRT));
    EXDOSU = upcase(strip(EXDOSU));

    retain EXSEQ;
    if first.USUBJID then EXSEQ = 1;
    else EXSEQ + 1;

    drop raw_stdtc raw_endtc; /* delet temporary variables */
run;


/*==================================================
 17. SDTM MAPPING: Disposition (DS Domain) - FIXED
 =========================================================*/


proc sort data=Raw.ds_raw out=ds_sorted;
    by USUBJID DSSTDTC;
run;

data SDTM.ds_final;
    /* identify the lenght*/
   
    length STUDYID $20 DOMAIN $2 DSTERM $200 DSDECOD $40 DSCAT $40 DSSTDTC $19;
   
    attrib STUDYID label="Study Identifier"
           DOMAIN label="Domain Abbreviation"
           DSSEQ length=8 label="Sequence Number"
           DSTERM label="Reported Term for the Disposition Event"
           DSDECOD label="Standardized Disposition Term"
           DSCAT label="Category for Disposition Event"
           DSSTDTC label="Start Date/Time of Disposition Event";

    set ds_sorted (rename=(DSSTDTC=raw_dsdtc));
    by USUBJID;

    STUDYID = "&studyid";
    DOMAIN = "DS";

    /* converting the date */
   
    if vtype(raw_dsdtc) = 'N' then DSSTDTC = put(raw_dsdtc, yymmdd10.);
    else DSSTDTC = raw_dsdtc;

    DSTERM = DSDECOD;
    DSCAT = "DISPOSITION EVENT";

    retain DSSEQ;
    if first.USUBJID then DSSEQ = 1;
    else DSSEQ + 1;

    drop raw_dsdtc;
run;

/*============================================
closing output diestintion to finalize sdtm phase 1 reports
​========================================================*/
ods pdf close;
ods excel close;

/* End of Clinical Data Pipeline: Phase I (Standardization) */
/* Next Phase: ADaM Dataset Creation and TFL Generation */

/* ========================================================================
   FINAL STEP: PRINTING SDTM DOMAINS FOR QUALITY REVIEW

  Printing Demographics (DM) - The foundation of all domains
 This table shows subject identification and basic characteristics
 =============================================================================*/

title1 "SDTM DM Domain: Subject Demographics";

proc print data=SDTM.dm_final noobs;
    var STUDYID USUBJID  RFSTDTC AGE SEX ;
run;

/* 2. Printing Adverse Events (AE) - Safety monitoring data */
/* We display AESEQ and AESTDTC to show successful sequencing and ISO dates */

title1 "SDTM AE Domain: Adverse Events Summary";

proc print data=SDTM.ae_final noobs;
    var USUBJID AESEQ AETERM  AESTDTC  AESER  AESEV;
run;

/* 3. Printing Vital Signs (VS) - Clinical measurements */

/* This demonstrates successful unit conversion (F to C / lb to kg) */
title1 "SDTM VS Domain: Vital Signs Measurements";

proc print data=SDTM.vs_final noobs;
    var USUBJID VSSEQ VSTESTCD VSORRES VSORRESU VSSTRESN VSSTRESU;
run;

/* 4. Printing Laboratory Results (LB) - Lab safety data */
/* Highlight LBNRIND to show the flagging of High/Low/Normal results */
title1 "SDTM LB Domain: Laboratory Results Analysis";

proc print data=SDTM.lb_final noobs;
    var LBTEST LBORRES LBORRESU LBNRLO LBNRHI LBDT USUBJID STUDYID DOMAIN LBSEQ
    LBSTRESU LBNRIND LBTESTCD;
run;

/* 5. Printing Exposure (EX) - Study drug administration */
/* Shows the standardized treatment names and dosing start dates */
title1 "SDTM EX Domain: Investigational Product Exposure";

proc print data=SDTM.ex_final noobs;

    var USUBJID EXSEQ EXTRT EXDOSE EXSTDTC;
run;
/*==================================================
 6. FINAL REPORT: SDTM Disposition (DS)
 =========================================================*/

title1 "Project: BEL-2026-041 - Human Clinical Trial";
title2 "SDTM Domain: DS (Disposition Data) - Final Standardized Output";

proc print data=SDTM.ds_final noobs;

run;

/*==================================================
 14. SDTM MAPPING: Vital Signs (VS Domain)

 Sorting  vital signs data by subject and test to ensure correct squence for
 VISIT/VSSEQ
 =========================================================*/


proc sort data=Raw.vs_raw out=vs_sorted;
    by USUBJID VSTEST;
run;


data SDTM.vs_final;
    set vs_sorted;
    by USUBJID;

    attrib STUDYID length=$20 label="Study Identifier"
           DOMAIN length=$2 label="Domain Abbreviation"
           VSSEQ length=8 label="Sequence Number"
           VSTESTCD length=$8 label="Vital Signs Test Short Code"
           VSSTRESN length=8 label="Numeric Result (Std Units)"
           VSSTRESU length=$10 label="Standard Units"
           VSDTC label="Date/Time of Measurements"; /*  add date for SDTM */

    STUDYID = "&studyid";
    DOMAIN = "VS";

    /* setting the short code for the scan */
   
    if VSTEST = 'Temp' then VSTESTCD = 'TEMP';
    else if VSTEST = 'Weight' then VSTESTCD = 'WEIGHT';
    else VSTESTCD = substr(upcase(strip(VSTEST)),1,8);

    /* converting standard units*/
    if VSTEST = 'Temp' then do;
        if VSORRESU = 'F' then VSSTRESN = (VSORRES - 32) * 5/9;
        else VSSTRESN = VSORRES;
        VSSTRESU = 'C';
    end;
    else if VSTEST = 'Weight' then do;
        if VSORRESU = 'lb' then VSSTRESN = VSORRES * 0.4535;
        else VSSTRESN = VSORRES;
        VSSTRESU = 'kg';
    end;
    else VSSTRESN = VSORRES;

    /* sequence numbering*/
    retain VSSEQ;
    if first.USUBJID then VSSEQ = 1;
    else VSSEQ + 1;
run;

/*************************************************************************
*************************************************************************
/* ========================================================================
   17. DATA QUALITY COMPLIANCE: Automated Edit Checks & Query Generation
   ======================================================================== */


/* STEP 1: Modified Join to ensure RFSTDTC is captured correctly */


proc sql;
    create table work.master_check_table as
    select
        d.USUBJID,
        d.SEX,d.AGE,
        put(d.RFSTDTC, yymmdd10.) as RFSTDTC,
        /* to convert the numric to character YYYY-MM-DD */
        a.AEPT, a.AESTDTC, a.AETERM, a.AESER,
        v.VSTESTCD, v.VSSTRESN,v.VSDTC,
        l.LBTEST, l.LBORRES, l.LBNRIND, l.LBDT,
        e.EXDOSE,e.EXSTDTC,e.EXENDTC,s.DSDECOD ,s.DSSTDTC
    from SDTM.dm_final d
    left join SDTM.ae_final a on d.USUBJID = a.USUBJID
    left join SDTM.vs_final v on d.USUBJID = v.USUBJID
    left join SDTM.lb_final l on d.USUBJID = l.USUBJID
    left join SDTM.ex_final e on d.USUBJID = e.USUBJID
    left join SDTM.ds_final s on d.USUBJID= s.USUBJID;
quit;


/* STEP 2: Execute Clinical Logic and Date Consistency Checks */

data work.all_queries_raw;
    set work.master_check_table;
    length Cat $25 Sev $15 Desc $120 QUERYFL $1;
    QUERYFL = "Y";

    /* Helper Variables for Date Calculations */
    _dt_rf = input(RFSTDTC, ?? yymmdd10.);
    _dt_ae = input(AESTDTC, ?? yymmdd10.);
        _dt_ae = input(AESTDTC, ?? yymmdd10.);    /*date of AE */
    _dt_ex_st = input(EXSTDTC, ?? yymmdd10.); /*start date of treatment */
    _dt_ex_en = input(EXENDTC, ?? yymmdd10.); /*end date of treatment*/
    _dt_ds = input(DSSTDTC, ?? yymmdd10.);/*start date dispostion event*/
    _dt_vs = input(VSDTC, ?? yymmdd10.);
    if vtype(LBDT)='N' then _dt_lb = LBDT; else _dt_lb = input(LBDT, ?? yymmdd10.);
    _today = date();
   
   
    if _dt_vs ne . and _dt_rf ne . and _dt_vs < _dt_rf then do;
        Cat="Date Consistency";
        Desc="LOGIC ERROR: Vital Signs (VS) measured before Study Entry";
        Sev="Moderate";
        output;
    end;
 

    /* A. Medical Logic: Male Pregnancy */
    if SEX='M' and AEPT='Pregnancy' then do;
        Cat="Medical Logic"; Desc="LOGIC ERROR: Male subject reported with Pregnancy"; Sev="CRITICAL"; output;
    end;

    /* B. Demographics: Unrealistic Age */
    if AGE > 100 then do;
        Cat="Demographics"; Desc="CRITICAL: Age is unrealistic ("||strip(put(AGE, 3.))||")"; Sev="High"; output;
    end;

    /* C. Exposure: Invalid Dose */
    if EXDOSE = 0 and EXDOSE ne . then do;
        Cat="Exposure"; Desc="INVALID DOSE: 0mg dose detected"; Sev="High"; output;
    end;

    /* D. Vital Signs: Extreme Temperature */
    if VSTESTCD='TEMP' and VSSTRESN >= 45 then do;
        Cat="Vital Signs"; Desc="CRITICAL: Extreme Temperature detected ("||strip(put(VSSTRESN, 4.1))||" C)"; Sev="CRITICAL"; output;
    end;

    /* E. Laboratory: High Results (Critical Values) */
    if LBNRIND='HIGH' then do;
        Cat="Laboratory"; Desc="ABNORMALITY: "||cats(LBTEST)||" is High ("||cats(LBORRES)||")"; Sev="Moderate"; output;
    end;

    /* F. Safety: Serious Adverse Event Alert */
    if AESER='Y' then do;
        Cat="Safety Alert"; Desc="SAE ALERT: Serious Event Reported (Action Required)"; Sev="CRITICAL"; output;
    end;

    /* G. Date Integrity: Future or Missing Dates */
    if AETERM ne "" and AESTDTC = "" then do;
        Cat="Date Error"; Desc="DATA ERROR: Missing date in AE domain"; Sev="High"; output;
    end;
    if _dt_ae > _today and _dt_ae ne . then do;
        Cat="Date Error"; Desc="LOGIC ERROR: Future date detected ("||strip(AESTDTC)||")"; Sev="High"; output;
    end;

    /* H. Date Consistency: Event Before Study Start */
    if _dt_ae ne . and _dt_rf ne . and _dt_ae < _dt_rf then do;
        Cat="Date Consistency"; Desc="LOGIC ERROR: AE started before Study Entry"; Sev="High"; output;
    end;
    if _dt_lb ne . and _dt_rf ne . and _dt_lb < _dt_rf then do;
        Cat="Date Consistency"; Desc="LOGIC ERROR: Lab test done before Study Entry"; Sev="Moderate"; output;
    end;

    keep USUBJID Cat Desc Sev QUERYFL;
run;

/* STEP 3: Remove Duplicates and Final Formatting */

proc sort data=work.all_queries_raw out=Query.Final_Clinical_Queries nodupkey;
    by USUBJID Cat Desc;
run;

/* STEP 4: Professional Report Generation with Sequence Number (obs="No.") */

title1 "Project: BEL-2026-041 - Human Clinical Trial";
title2 "Data Quality Audit - Comprehensive Summary Report";

/* This part ensures the sequence column "No." appears clearly */

proc print data=Query.Final_Clinical_Queries obs="No.";
    label USUBJID = "Subject ID"
          Cat = "Query Category"
          Sev = "Severity Level"
          Desc = "Error Description"
          QUERYFL = "Flag";
run;
title;

/* Starting the Analysis Phase (ADaM) */

ods pdf file="&root/Output/Analysis_Data_Model_Report.pdf" style=Pearl;
ods excel file="&root/Output/Analysis_Data_Model_Report.xlsx";

title1 "Phase II: ADaM Dataset Creation and Validation";


/*ADAM*/

%let root = /home/u64371687/nadia_clinical_project;
libname Raw "&root/Raw_data"; /* Source Data */
libname SDTM "&root/SDTM_data"; /* Tabulation Data */
libname QUERY "&root/QUERY"; /* Data Quality Checks */
libname ADam "&root/ADam"; /* Analysis Data */

/*************************************************************************
* PROJECT: end to end clinical data standerdiztion  and reporting pipeline
* PROGRAM NAME: 02_ADaM_ADSL_Setup.sas
* DESCRIPTION: Creation of Analysis Dataset Subject Level (ADSL)
* METHOD: PROC SQL for Efficiency and Traceability
*************************************************************************
/* STEP 1: PREPARE EXPOSURE LIMITS (FIRST AND LAST DOSE) */

proc sql;
    create table work.ex_limits as
    select USUBJID,EXTRT,
           min(input(EXSTDTC,  yymmdd10.)) as TRTSDT format=yymmdd10. label="Treatment Start Date",
           max(input(EXENDTC,  yymmdd10.)) as TRTEDT format=yymmdd10. label="Treatment End Date"
    from SDTM.ex_final
    group by USUBJID,EXTRT;
quit;

/* STEP 2: BUILD ADSL USING PROC SQL LEFT JOIN */

proc sql;
    create table ADaM.adsl as
    select
   
        dm.*,
        ex.TRTSDT,
        ex.TRTEDT,
        ex.EXTRT as TRT01P length=20 label="Planned Treatment for Period 01",
        ds.DSDECOD as DSSTATUS label="Disposition Status",
        input(ds.DSSTDTC,  yymmdd10.) as RFENDT format=yymmdd10. label="Subject Reference End Date",
       
        /* Planned Treatment Group */
       
 /*take the drug  name dirctly from exposure*/

        
       
        /* Safety Population Flag */
       
        case when ex.TRTSDT is not missing then "Y" else "N" end as SAFFL length=1 label="Safety Population Flag"
       
    from SDTM.dm_final as dm
    left join work.ex_limits as ex on dm.USUBJID = ex.USUBJID
    left join SDTM.ds_final as ds on dm.USUBJID = ds.USUBJID;
quit;


title "ADaM ADSL: Including Treatment and Disposition Info";

proc print data=ADaM.adsl noobs;

    var USUBJID TRT01P TRTSDT TRTEDT DSSTATUS RFENDT SAFFL;
run;
title;



/* STEP 1: PREPARE DATA FOR MERGING */

proc sort data=SDTM.ae_final out=ae_sorted; by USUBJID; run;

proc sort data=ADaM.adsl out=adsl_sorted; by USUBJID; run;

/* STEP 2: MERGE AE AND ADSL USING DATA STEP */

data ADaM.adae;
    merge ae_sorted (in=a)
          adsl_sorted (in=b keep=USUBJID TRTSDT TRTEDT TRT01P SAFFL);
    by USUBJID;
   
    if a and b; /* Keep records that exist in both */

    attrib ASTDT length=8 format=yymmdd10. label="Analysis Start Date"
           TRTEMFL length=$1 label="Treatment Emergent Analysis Flag";

    /* Convert AE Start Date to Numeric */
    ASTDT = input(AESTDTC, ?? yymmdd10.);

    /* LOGIC FOR TRTEMFL:
       AE occurs on or after First Dose AND (before Last Dose + 30 days or any other rule) */
    if ASTDT ne . and TRTSDT ne . then do;
        if ASTDT >= TRTSDT then TRTEMFL = "Y";
        else TRTEMFL = "N";
    end;
    else TRTEMFL = "U"; /* Unknown if TRTSDT is missing */
run;

/* STEP 3: FINAL REPORT */

title1 "Project: BEL-2026-041 - Human Medicine Study";
title2 "ADaM ADAE: Treatment Emergent Analysis (TEAE)";

proc print data=ADaM.adae noobs label;
    var USUBJID AETERM ASTDT TRTSDT TRTEDT TRTEMFL TRT01P;
run;
title;

/* Table 1: Subject Disposition by Treatment Group */

title "Table 1: Summary of Subject Disposition (Safety Population)";

proc freq data=ADaM.adsl;
    /*we usedTRT01P with patients condition DSSTATUS*/
   
    tables TRT01P * DSSTATUS / norow nocol nopercent;
run;

/* Table 2: AE Severity by Treatment (Enhanced with Missing values) */

title "Table 2: Adverse Events Severity by Treatment Group";
proc freq data=ADaM.adae;

    tables TRT01P * AESEV / norow nocol nopercent missing;
run;


ods excel close;
ods pdf close;

%put NOTE: Project BEL-2026-041 is fully completed (Phases 1, 2, and 3).;


/* ========================================================================
   17. FINAL PHASE: CLINICAL VISUALIZATIONS & PROFESSIONAL REPORTING
   ======================================================================== */

/* --- A. Visualizations --- */

/* 1. Bar chart showing the distribution of Adverse Event severity per treatment group */
title "Figure 1: Incidence of Adverse Events by Treatment and Severity";
proc sgplot data=ADaM.adae;
    vbar TRT01P / group=AESEV groupdisplay=cluster
                  datalabel fillattrs=(transparency=0.2);
    yaxis label="Number of Adverse Events";
    xaxis label="Treatment Group";
    keylegend / title="Severity Level";
run;

/* 2. Box Plot to compare age distribution across treatment groups */
title "Figure 2: Distribution of Subject Age by Treatment Group";
proc sgplot data=ADaM.adsl;
    vbox AGE / category=TRT01P fillattrs=(color=CX85D1E1);
    yaxis label="Age (Years)";
    xaxis label="Treatment Group";
run;

/* 3. Pie chart illustrating final subject disposition status (from DS domain) */
title "Figure 3: Subject Disposition Status Summary";
proc sgpie data=ADaM.adsl;
   pie DSSTATUS / datalabeldisplay=(category percent)
                datalabelloc=outside;
run;


/* --- B. Final Report Export to Excel --- */

/* Define the final report output path and OS Excel destination */
ods excel file="&root/Final_Medical_Review_Report.xlsx"
    options(sheet_interval="table"
            embedded_titles="yes"
            sheet_name="Data Quality Queries");

/* Worksheet 1: Data Quality and Clinical Queries */
title1 "Table 1: Clinical Data Quality & Safety Queries";
proc print data=Query.Final_Clinical_Queries noobs label;
    var USUBJID Cat Desc Sev QUERYFL;
run;

/* Worksheet 2: Adverse Events (ADAE) Analysis */
ods excel options(sheet_name="Safety Analysis (ADAE)");
title1 "Table 2: Adverse Events Analysis (Treatment Emergent)";
proc print data=ADaM.adae noobs label;
    var USUBJID TRT01P AETERM AEPT ASTDT TRTSDT TRTEMFL;
run;

/* Worksheet 3: Subject Level Analysis (ADSL) Summary */
ods excel options(sheet_name="Subject Summary (ADSL)");
title1 "Table 3: Subject Level Analysis Summary";
proc print data=ADaM.adsl noobs label;
    var USUBJID SEX AGE COUNTRY TRT01P SAFFL;
run;

/* Worksheet 4: Treatment Exposure and Disposition Summary */
ods excel options(sheet_name="Treatment Exposure");
title1 "Table 4: Summary of Treatment Start and End Dates";
proc print data=ADaM.adsl noobs label;
    var USUBJID TRT01P TRTSDT TRTEDT DSSTATUS;
run;

/* Close Excel destination to save the file */
ods excel close;
title;

/* Final confirmation message in the SAS Log */

%put NOTE: ************************************************************;
%put NOTE: SUCCESS! Project BEL-2026-041 Phase I is now COMPLETE.;
%put NOTE: Your final report has been generated in the Output folder.;
%put NOTE: Generated on: %sysfunc(datetime(), datetime20.);
%put NOTE: ************************************************************;

