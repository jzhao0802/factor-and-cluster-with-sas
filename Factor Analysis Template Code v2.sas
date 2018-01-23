
libname FaInput  "\\plyvnas01\statservices\CustomStudies\Primary Market Research\Big C\002 SAS Data";
libname FaOutput "D:\Zhao Jie\working materials\factor and cluster\factor output";
/*Example code for factor analysis*/
%let nf=3;  														/*!!!need to change!!!*/
%let flagging_point=0.3;  								/*!!!need to change!!!*/
%let YOUR_INPUT_DATA=FaInput.Data_for_Seg; 							/*!!!need to change!!!*/
%let YOUR_OUTPUT_DATA=; 							/*!!!need to change!!!*/
%let YOUR_VARIALBES_FOR_FA=;  				/*!!!need to change!!!*/

/*1. factor analysis with principle component method and roation method=VARIMAX*/
PROC FACTOR DATA=&YOUR_INPUT_DATA.  
METHOD=PRINCIPAL   NFACTORS=&nf.  
MINEIGEN=0 SIMPLE  CORR  SCREE  EIGENVECTORS   /*PREPLOT  NPLOT=&nf.*/  MSA  SCORE  FLAG=&flagging_point.
ROTATE=VARIMAX
OUT=&YOUR_OUTPUT_DATA.;   
VAR &YOUR_VARIALBES_FOR_FA.;   
run;



/*2. factor analysis with principle component method and roation method=VARIMAX*/
PROC FACTOR DATA=&YOUR_INPUT_DATA.  
METHOD=PRINCIPAL   NFACTORS=&nf.  
MINEIGEN=0 SIMPLE  CORR  SCREE  EIGENVECTORS   /*PREPLOT  NPLOT=&nf.*/  MSA  SCORE  FLAG=&flagging_point.
PREROTATE=VARIMAX
ROTATE=PROMAX
OUT=&YOUR_OUTPUT_DATA.;   
VAR &YOUR_VARIALBES_FOR_FA.;   
run;


/*3. factor analysis with common factor method and rotation method=Promax*/
PROC FACTOR DATA=&YOUR_INPUT_DATA.  
PRIORS=SMC  NFACTORS=&nf.    
MINEIGEN=0 SIMPLE  CORR  SCREE  EIGENVECTORS   /*PREPLOT  NPLOT=&nf.*/   MSA  SCORE  FLAG=&flagging_point.
PREROTATE=VARIMAX /*actually default prerotate method for ROTATE=PROMAX is VARIMAX*/
ROTATE=PROMAX
OUT=&YOUR_OUTPUT_DATA.;   
VAR &YOUR_VARIALBES_FOR_FA.;  
run;


/*4. factor analysis with common factor method and rotation method=direct oblique*/
PROC FACTOR DATA=&YOUR_INPUT_DATA.   
PRIORS=SMC  NFACTORS=&nf.    
MINEIGEN=0 SIMPLE  CORR  SCREE  EIGENVECTORS   /*PREPLOT  NPLOT=&nf.*/   MSA  SCORE  FLAG=&flagging_point.
ROTATE=OBLIMIN  TAU=0 /*NOTE: TAU=0 is default value for ROTATE=OBLIMIN*/
OUT=&YOUR_OUTPUT_DATA.;   
VAR &YOUR_VARIALBES_FOR_FA.;   
run;
