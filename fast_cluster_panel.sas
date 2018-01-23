%let try=2;
%let input_data=clus_out.fast_3seg ; 
%let out_dir=clus_out;
%let noclus=3; *the maximum clusters that you want to get. it is to be used in the "maxc=" option;
%let p=1; 
%let max_iters=5000;

*%let Ran_seed=1234;  *it is always an integer, needs to change every time;
*%let Ran_seed=1000;
%let Ran_seed=61234;

*%let Ran_seed=123456;  *it is always an integer, needs to change every time;
*%let Ran_seed=16509;
*%let Ran_seed=248;

%let var_list=factor: ; *specify variables for fast clustering (i.e. K-Means);
%let resp_id=QNO ; *ID of the respondents in survey;
libname FaOutput "D:\Zhao Jie\working materials\factor and cluster\factor output";
libname clus_out "D:\Zhao Jie\working materials\factor and cluster\cluster output";
/*

RANDOM=n 
specifies a positive integer as a starting value for the pseudo-random number generator for use with REPLACE=RANDOM. 
If you do not specify the RANDOM= option, the time of day is used to initialize the pseudo-random number sequence. 



REPLACE=FULL | PART | NONE | RANDOM 
specifies how seed replacement is performed, as follows: 

FULL 
requests default seed replacement as described in the section Background. 

PART 
requests seed replacement only when the distance between the observation and the closest seed is greater than the minimum distance between seeds. 

NONE 
suppresses seed replacement. 

RANDOM 
selects a simple pseudo-random sample of complete observations as initial cluster seeds. 




SEED=SAS-data-set 
specifies an input data set from which initial cluster seeds are to be selected. 
If you do not specify the SEED= option, initial seeds are selected from the DATA= data set. The SEED= data set must contain the same variables that are used in the data analysis. 


*/

/*set up the initial seed dataset--init_data in R*/ 
proc import out=&out_dir..init_data
datafile="D:\Zhao Jie\working materials\factor and cluster\init_data.csv"
dbms=CSV replace;
run;



proc fastclus data=faoutput.facout1 CLUSTER=seg&noclus._&try. maxc=&noclus least=&p. maxiter=&max_iters. List random=&Ran_seed replace=random
out=&out_dir..fast_&noclus.seg_&try._hcluspanel
/*seed=&out_dir..init_data*/
/*seed=&out_dir..fast_&noclus.seg_&try._clusmean*/
seed=clus_out.Hclus_&clus_no.seg_&try._clusmeans
outseed=&out_dir..fast_&noclus.seg_&try._hcluspanel_clusmean
; 
   var  &var_list.; 
   ID &resp_id;
run;

proc fastclus data=faoutput.facout1 CLUSTER=seg&noclus._panel maxc=&noclus least=&p. maxiter=&max_iters. /*List random=&Ran_seed*/ replace=random
out=&out_dir..fast_&noclus.seg_panel
seed=&out_dir..init_data
; 
   var  &var_list.; 
   ID &resp_id;
run;




proc candisc data=&out_dir..fast_&noclus.seg_&try._panel  out=&out_dir..Can_&try._panel noprint;
	class seg&noclus._&try. ;
	var factor:;
run;
data &out_dir..Can_&try._panel;
set &out_dir..Can_&try._panel;
	length shape color $8.;
   if seg&noclus._&try.=1 then do; shape="club"; color="blue"; end; 
   if seg&noclus._&try.=2 then do; shape="diamond"; color="red"; end;
   if seg&noclus._&try.=3 then do; shape="spade"; color="green"; end;
run;


/*ods PDF file="D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic\test2.gif";*/
*filename grfout "D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic\test.gif";
/*goptions reset =all dev=gif  gsfname=grfout gsfmode=replace;*/
/*proc gtestit ;*/
/*quit;*/
/*ods PDF close;*/

/*ods listing close;*/
ods PDF file="D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic\fast_panel_try1.pdf";
	legend1 frame cframe=ligr label=none cborder=black 
				position=center value=(justify=center);
	axis1 label=(angle=90 rotate=0)  minor=none;
	axis2 minor=none;

/*proc gplot data=can_&try._panel;*/
/*	plot can1*can2 =seg&noclus._&try./frame cframe=ligr*/
/*	       					legend=legend1 vaxis=axis1 haxis=axis2;*/
/*run;*/
	proc G3D data=
/*	&out_dir..can_&try._test;*/
&out_dir..Can_&try._panel
/*&out_dir..Can_&try._panel_cmp*/
;
	scatter  factor1*factor2=factor3/
	color=color
	shape=shape
	size=2
	rotate=-36
	noneedle
	grid;
run;


ods pdf close;

/*modify the shape and color set for try2 amd try3 for its accordance with try1*/
data  &out_dir..Can_&try._panel_cmp;
set &out_dir..Can_&try._panel;
if seg&noclus._&try.=3 then do  seg&noclus._&try._cmp=3;end;
if seg&noclus._&try.=1 then do  seg&noclus._&try._cmp=2;end;
if seg&noclus._&try.=2 then do seg&noclus._&try._cmp=1;end;

run;
data &out_dir..Can_&try._panel_cmp;
set &out_dir..Can_&try._panel_cmp;
	length shape color $8.;
   if seg&noclus._&try._cmp=1 then do; shape="club"; color="blue"; end; 
   if seg&noclus._&try._cmp=2 then do; shape="diamond"; color="red"; end;
   if seg&noclus._&try._cmp=3 then do; shape="spade"; color="green"; end;
run;

/*the accordance QC of the 3 fastclus result*/
proc sql;
create table clus_out.fast_can_123_panel as
		select  a.QNO, a.factor1,a.factor2, a.factor3, a.seg3_1, b.seg3_2_cmp, c.seg3_3_cmp
		from
		&out_dir..Can_1_panel a, &out_dir..Can_2_panel_cmp b, &out_dir..Can_3_panel_cmp c
		where a.QNO=b.QNO=c.QNO;
quit;

data  clus_out.fast_can_panel_accord_qc;
set  clus_out.fast_can_123_panel_test;
if seg3_1 ne seg3_2_cmp or seg3_1 ne seg3_3 or seg3_2_cmp ne seg3_3;
run;

proc sql;
create table clus_out.fast_can_123_panel_test as
		select  a.QNO, a.factor1,a.factor2, a.factor3, a.seg3_1, b.seg3_2_cmp, c.seg3_3
		from
		&out_dir..Can_1_panel a, &out_dir..Can_2_panel_cmp b, &out_dir..Can_3_panel c
		where a.QNO=b.QNO=c.QNO;
quit;

proc sql;
create table clus_out.Fast_HClusPanel_MeanCmp_&try. as
		select a.seg&noclus._&try., (a.factor1-b.factor1)/a.factor1 as factor1_diff, (a.factor2-b.factor2)/a.factor2 as factor2_diff, (a.factor3-b.factor3)/a.factor3 as factor3_diff
		from 
		&out_dir..fast_&noclus.seg_&try._clusmean a, &out_dir..fast_&noclus.seg_&try._hcluspanel_clusmean b
		where a.seg&noclus._&try.=b.seg&noclus._&try.;
quit;














