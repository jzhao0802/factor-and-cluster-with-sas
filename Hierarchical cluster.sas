%let clus_no=3;
%let try=2;
*%let seed=123456;
%let seed=4521;
*%let seed=56432;
%let input_data=fac_out.facout1; *input data name;
%let outtree_data=tree1; *output data name;
%let var_list=factor:;  *variables for clustering;
%let resp_id=QNO_new; *respondent ID;
%let my_method=ward; *see SAS help for more alternative methods;

libname Fac_out "D:\Zhao Jie\working materials\factor and cluster\factor output";
libname clus_out "D:\Zhao Jie\working materials\factor and cluster\cluster output";


/*random order using random seed and normal function*/
data &input_data._new_&try.;
set &input_data.;
seed=&seed.;
rnd_num=rannor(seed);
run;
proc sort data=&input_data._new_&try. out=&input_data._new_&try._sort;
by rnd_num;
run;
data &input_data._new_sort_&try.;
set &input_data._new_&try._sort;
QNO_new=_N_;
run;

proc cluster data=&input_data._new_sort_&try.  Outtree=clus_out.&outtree_data._&try.
 Method=&my_method.   
simple 
/*trim=10 */
/*K=2*/
/*RMSSTD _RMSSTD_ _FREQ_ */
/*comes from fastclus's output*/
;
var &var_list. ;
ID &resp_id. 
;
run;

data clus_out.Hclus_&clus_no.seg_&try._clusmeans;
set clus_out.&outtree_data._&try.;
if _name_ in ("CL8", "CL4","CL3");
run;

proc sql;
create table clus_out.&outtree_data._&try._addQNO as
		select a.*, b.QNO
		from clus_out.&outtree_data._&try. a, &input_data._new_sort_&try. b
		where a.QNO_new=b.QNO_new;
quit;

proc tree data=clus_out.&outtree_data._&try.  horizontal;run;

proc tree data=clus_out.&outtree_data._&try._addQNO  noprint out=clus_out.hcluster_out_&try.  nclusters=3;
id QNO_new;
copy factor: QNO;
run;

proc sort data=clus_out.hcluster_out_&try. out=clus_out.hcluster_out_&try._sort;
by cluster;
run;
proc print label uniform data=clus_out.hcluster_out_&try._sort;
id QNO_new;
var factor:;
format factor: 1.;
by cluster;
run;

/*summerize the accordance after change the obs order*/
proc sql;
create table clus_out.accor as
	select a.*, b.cluster as cluster2, c.cluster as cluster3
	from clus_out.hcluster_out_1 a , clus_out.hcluster_out_2 b, clus_out.hcluster_out_3 c
	where a.QNO=b.QNO=c.QNO;
quit;

data clus_out.qc1;
set clus_out.accor;
if cluster ne cluster2 or cluster ne cluster3 or cluster2 ne cluster3;
run;
