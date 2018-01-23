/* --------------------------------------------------------- */
/* */
/* The macro CLUSPERM randomly permutes observations and */
/* does a cluster analysis for each permutation. */
/* The arguments are as follows: */
/* */
/* data data set name */
/* var list of variables to cluster */
/* id id variable for proc cluster */
/* method clustering method (and possibly other options) */
/* nperm number of random permutations. */
/* */
/* --------------------------------------------------------- */

%macro CLUSPERM(data, var, id, method, nperm);
/*CREATE TEMPORARY DATASET WITH RANDOM NUMBERS*/
data _temp_;
		set &data;
		array _random_ _random_1-_random_&nperm;
		do over _random_;
				_random_=ranuni(654321);
		end;
run;
/*PERMUTE AND CLUSTER THE DATA*/
%do n=1 %to &nperm;
proc sort data=_temp_(keep=_random_&n &var &id) out=_perm_;
		by _random_&n;
run;

proc cluster  method=&method noprint outtree=_tree_&n; 
		var &var;
		id &id;
run;
%end;
%mend;

%CLUSPERM(data=&input_data., method=&my_method., var=Q24_:, id=QNO,nperm=10);

%macro PLOTPERM(stat, nclus, nperm);
/*CONCATENATE THE TREE DATA SETS FOR 20 OR FEWER CLUSTERS*/
	data _plot_;
		set %do n=1 %to &nperm;_tree_&n(in=_in_&n)  %end; ; 
		if _ncl_ <= &nclus;
		%do n=1 %to &nperm;
				if _in_&n then _perm_=&n;
		%end; 
		label _perm_ ="permutation number";
		keep _ncl_ &stat  _perm_ ;
	run;

	proc plot;
			plot (&stat)*_ncl_=_perm_ /vpos=26;
			title2 'symbol is value of _perm_';
	run;
%mend;
%PLOTPERM(stat=_: ,nclus=10, nperm=10);

%macro treeperm(var,id,nclus,nperm,meanfmt);
%do n=1 %to &nperm;
		proc tree data=_tree_&n noprint out=_out_&n(drop=clusname rename=(cluster=_clus_&n)) nclusters=&nclus;
				copy &var;
				id &id;
		run;
		proc sort data=_out_&n;
				by &id &var;
		run;
%end;
data _merge_;
		merge %do n=1 %to &nperm; _out_&n %end; ;
		by &id &var;
		length all_clus $ %eval(&nperm*3);
		%do n=1 %to &nperm;
				substr(all_clus,%eval(1+(&n-1)*3),3)=put(_clus_&n,3.);
		%end;
run;
proc sort ; by _clus_:;run;
proc print;
		var &var;
		id &id;
		by all_clus notsorted;
run;
proc tabulate order=data formchar='                     ';
		class all_clus;
		var &var;
		table all_clus, n='FREQ'*f=5. mean*f=&meanfmt*(&var) /
				rts=%eval(&nperm*3+1);
run;
%mend;

%CLUSPERM(data=&input_data., method=&my_method., var=Q24_1-Q24_3, id=QNO,nperm=9);
%PLOTPERM(stat=_PSF_ _PST2_ _CCC_,nclus=10, nperm=9);
%treeperm(var=Q24_1-Q24_3, id=QNO,nperm=9,nclus=5,meanfmt=10.1);
