%let try=3;
%let input_data=clus_out.fast_3seg ; 
%let out_dir=clus_out;
%let noclus=3; *the maximum clusters that you want to get. it is to be used in the "maxc=" option;
%let p=1; 
%let max_iters=5000;
%let Ran_seed=1234;  *it is always an integer, needs to change every time;
*%let Ran_seed=1000;
*%let Ran_seed=61234;
%let var_list=factor: ; *specify variables for fast clustering (i.e. K-Means);
%let resp_id=QNO ; *ID of the respondents in survey;

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

proc fastclus data=faoutput.facout1 CLUSTER=seg&noclus._&try. maxc=&noclus least=&p. maxiter=&max_iters. List random=&Ran_seed replace=random
out=&out_dir..fast_&noclus.seg_&try.; 
   var  &var_list.; 
   ID &resp_id;
run;

/*statistics the diff*/
proc candisc data=&out_dir..fast_&noclus.seg_&try. out=Can_&try. noprint;
	class seg&noclus._&try. ;
	var factor:;
run;

ods PDF file="D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic\test2.gif";
*filename grfout "D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic\test.gif";
goptions reset =all dev=gif  gsfname=grfout gsfmode=replace;
proc gtestit ;
quit;
ods PDF close;


ods PDF file="D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic\test2.gif";
	legend1 frame cframe=ligr label=none cborder=black 
				position=center value=(justify=center);
	axis1 label=(angle=90 rotate=0)  minor=none;
	axis2 minor=none;

proc gplot data=can_&try.;
	plot can1*can2 =seg&noclus._&try./frame cframe=ligr
	       					legend=legend1 vaxis=axis1 haxis=axis2;
run;
ods pdf close;



/*modify the shape and color set for try3 for its accordance with the other 2 tries*/
data &out_dir..can_&try._test;
set can_&try.;
	length shape color $8.;
   if seg&noclus._&try.=2 then do; shape="club"; color="blue"; end; 
   if seg&noclus._&try.=3 then do; shape="diamond"; color="red"; end;
   if seg&noclus._&try.=1 then do; shape="spade"; color="green"; end;
run;


proc G3D data=&out_dir..can_&try.;
	scatter  factor1*factor2=factor3/
	color=color
	shape=shape
	size=2
	rotate=-36
	grid;
run;


ods html path="D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic" 
			 gpath="D:\Zhao Jie\working materials\factor and cluster\cluster output\graphic"
			 style=journal
			 file='fast_try3_test2.html';
			 
ods graphics / reset=all 
					imagename="cluster"
					outputfmt=gif
					imagemap=on;
proc G3D data=
/*	&out_dir..can_&try._test;*/
&out_dir..fast_&noclus.seg_&try._cmp_test;
	scatter  factor1*factor2=factor3/
	color=color
	shape=shape
	size=2
	rotate=-36
	grid;
run;


ods graphics off;
ods html off;



data  &out_dir..fast_&noclus.seg_&try._cmp;
set &out_dir..fast_&noclus.seg_&try.;
if seg&noclus._&try.=1 then do  seg&noclus._&try._cmp=3;end;
if seg&noclus._&try.=2 then do  seg&noclus._&try._cmp=1;end;
if seg&noclus._&try.=3 then do seg&noclus._&try._cmp=2;end;

run;

/*the accordance QC of the 3 fastclus result*/
proc sql;
create table clus_out.fast_123 as
		select  a.QNO, a.factor1,a.factor2, a.factor3, a.seg3_1, b.seg3_2, c.seg3_3_cmp
		from
		&out_dir..fast_&noclus.seg_1 a, &out_dir..fast_&noclus.seg_2 b, &out_dir..fast_&noclus.seg_3_cmp c
		where a.QNO=b.QNO=c.QNO;
quit;

data  clus_out.fast_accord_qc;
set  clus_out.fast_123;
if seg3_1 ne seg3_2 or seg3_1 ne seg3_3_cmp or seg3_2 ne seg3_3_cmp;
run;

data &out_dir..fast_&noclus.seg_3_cmp_test;
set &out_dir..fast_&noclus.seg_3_cmp;
	length shape color $8.;
   if seg&noclus._&try._cmp=1 then do; shape="club"; color="blue"; end; 
   if seg&noclus._&try._cmp=2 then do; shape="diamond"; color="red"; end;
   if seg&noclus._&try._cmp=3 then do; shape="spade"; color="green"; end;
run;
