        proc iml symsize=4000 worksize=4000;
         %if %upcase(&testcalc)^=Y %then %do;
          reset noname; 
         %end;
         nocalc=0;
         everzero=0;
         edit &foldname var _all_;
         read all var {&yvars} into fy;
         fycnt=ncol(fy);
         fn=nrow(fy);
         %if %upcase(&testcalc)=Y %then %do;
          print fycnt fn;
         %end;
         %if %quote(&idvar)^= %then %do;
          read all var {&idvar} into fid;
         %end;
         %if &ccobscnt=0 %then %do;
          print "empty cluster solution method=&methnext";
          nocalc=1;
          %let noclstrs=1;
         %end;
         %else %do;
          edit &cmpclsnm var _all_;
          read all var {cluster};
          read all var {&yvars} into cy;
          cycnt=ncol(cy); * cycnt and fycnt will be equal;
          cn=nrow(cy);
          %if %upcase(&testcalc)=Y %then %do;
           print cycnt cn;
          %end;
          cluscnt=repeat(0,&inc,1);
          cprop=repeat(0,&inc,1);
          cmean=repeat(0,&inc,cycnt);
          pi=3.14159265358979;
         %end;
         cyind=(cy^=.);
         %if ^&noclstrs %then %do;
          * load the parameter estimates computed from the current fold
            complement for the mixture of &inc groups, multivariate
            normally distributed with possibly different mean vectors
            loaded into the variable cmean, possibly different
            probabilities for belonging to a group loaded into cprop,
            and possibly different variance vectors and correlation
            matrices loaded into cvar and ccorr&iclstr  
  
            variances are estimated using the usual average sums of
            squares approach summing over sets of observations and
            variables determined by the yvarnces and cvarnces settings 
  
            given the variance estimate that is used, the associated
            estimate of the correlation matrix (when the correlations
            are not treated as being constant) will maximize the 
            likelihood (the argument is similar to the one in Johnson &
            Wichern, Multivariate Statistics, Prentice Hall, 3rd ed.,
            1992 for the case of an unstructured covariance matrix with
            1 cluster), but the variance estimates (and the constant
            correlation estimate) need not be maximum likelihood
            estimates 
  
            when both yvarnces and ycorrs are set to DIFF and cvarnces
            and ccorrs are set either both to SAME or both to DIFF, 
            variance and correlation estimate maximize the likelihood
            (see Symons, 1981 referenced in the SAS Users Guide)
            at least when all the variance estimates are nonzero and
            all estimated correlation matrices are non-singular, but
            this may no longer hold for the other degenerate cases due
            to their special handling 
  
            even if nondegenerate estimates are possible for a cluster
            with degenerate standard covariance estimates through
            combining the data in that cluster with data from other
            clusters, this is not done to reduce the chance of 
            generating degenerate clusters in the selected cluster
            solution
          ;
          csumsqs=repeat(0,&inc,cycnt);
          csumcnt=repeat(0,&inc,cycnt);
          cvar=repeat(0,&inc,cycnt);
          do iclstr=1 to &inc;
           ind=(cluster=iclstr);
           cluscnt[iclstr]=ind[+];
           cprop[iclstr]=cluscnt[iclstr]/cn;
           do ivar=1 to cycnt;
            ind2=ind#cyind[,ivar];
            if ind2[+]>0 then do;
             cyhold=cy[loc(ind2),ivar];
             cmean[iclstr,ivar]=cyhold[+]/ind2[+];
            end;
           end;
           do ivar=1 to cycnt;
            ind2=ind#cyind[,ivar];
            if ind2[+]>0 then do;
             cyhold=cy[loc(ind2),ivar];
             diffy=cyhold-cmean[iclstr,ivar];
             csumsqs[iclstr,ivar]=(diffy#diffy)[+];
            end;
            csumcnt[iclstr,ivar]=ind2[+];
           end;
          end;
          pparmcnt=&inc-1; * # distinct cluster proportions;
          mparmcnt=cycnt*&inc; * # of distinct means;
          %if %upcase(&testcalc)=Y %then %do;
           print "before", csumsqs;
          %end;
          %if %upcase(&yvarnces)=SAME & %upcase(&cvarnces)=SAME %then %do;
           vparmcnt=1; * # distinct variances;
           ind=(csumcnt>0);
           cvarhold=csumsqs[+];
           cvarcnt=ind[+];
           if cvarcnt>0 then do;
            cvar[loc(ind)]=cvarhold/cvarcnt;
           end;
          %end;
          %else %if %upcase(&yvarnces)=SAME & %upcase(&cvarnces)=DIFF 
          %then %do;
           vparmcnt=&inc; * # distinct variances;
           %do iclstr=1 %to &inc;
            ind=(csumcnt[&iclstr,]>0);
            cvarhold=csumsqs[&iclstr,+];
            if ind[+]>0 then do;
             cvar[&iclstr,loc(ind)]=cvarhold/ind[+];
            end;
           %end;
          %end;
          %else %if %upcase(&yvarnces)=DIFF & %upcase(&cvarnces)=SAME 
          %then %do;
           vparmcnt=cycnt; * # distinct variances;
           do ivar=1 to cycnt;
            ind=(csumcnt[,ivar]>0);
            cvarcnt=csumcnt[+,ivar];
            cvarhold=csumsqs[+,ivar];
            if cvarcnt>0 then do;
             cvar[loc(ind),ivar]=cvarhold/cvarcnt;
            end;
           end;
          %end;
          %else %do; * the both DIFF case;
           vparmcnt=&inc*cycnt; * # distinct variances;
           do iclstr=1 to &inc;
            do ivar=1 to cycnt;
             if csumcnt[iclstr,ivar]>0 then do;
              cvar[iclstr,ivar]=csumsqs[iclstr,ivar]/csumcnt[iclstr,ivar];
             end;
            end;
           end;
          %end;
          cstd=cvar##0.5;
          nearzero=(cstd<&near0std);
          if nearzero[+]>0 then do;
           cstd[loc(nearzero)]=&near0std;
          end;
          prodcstd=repeat(1,&inc,1);
          overcstd=repeat(0,&inc,cycnt);
          do iclstr=1 to &inc;
           do ivar=1 to cycnt;
             prodcstd[iclstr]=prodcstd[iclstr]*cstd[iclstr,ivar];
             overcstd[iclstr,ivar]=1/cstd[iclstr,ivar];
           end;
          end;
          %if %upcase(&ycorrs)=ZERO %then %do;
           cparmcnt=0; * number of distinct correlations;
           %do iclstr=1 %to &inc;
             ccorr&iclstr=i(cycnt);
           %end;
          %end;
          %else %do;
           %do iclstr=1 %to &inc;
            ccorr0&iclstr=repeat(0,cycnt,cycnt);
            ccnt&iclstr=repeat(0,cycnt,cycnt);
            ind=(cluster=&iclstr);
            cyhold=cy[loc(ind),];
            do ivar1=1 to cycnt-1;
             do ivar2=ivar1+1 to cycnt;
              ind2=(cyhold[,ivar1]^=.)#(cyhold[,ivar2]^=.);
              * print ivar1 ivar2, ind2 cyhold, (ind2[+]);
              if ind2[+]>0 then do;
               diff1=(cyhold[loc(ind2),ivar1]
                          -cmean[&iclstr,ivar1]);
               zdiff1=diff1*overcstd[&iclstr,ivar1];
               diff2=(cyhold[loc(ind2),ivar2]
                          -cmean[&iclstr,ivar2]);
               zdiff2=diff2*overcstd[&iclstr,ivar2];
               ccorr0&iclstr[ivar1,ivar2]=(zdiff1#zdiff2)[+];
              end;
              ccnt&iclstr[ivar1,ivar2]=ind2[+];
             end;
            end;
            %if %upcase(&testcalc)=Y %then %do;
             print "before", ccorr0&iclstr;
            %end;
           %end;
           %if %upcase(&ycorrs)=SAME & %upcase(&ccorrs)=SAME %then %do;
            cparmcnt=1; * number of distinct correlations;
            ccorrhld=0;
            ccnthold=0;
            %do iclstr=1 %to &inc;
             ccorrhld=ccorrhld+ccorr0&iclstr[+];
             ccnthold=ccnthold+ccnt&iclstr[+];
            %end;
            if ccnthold>0 then do;
             ccorrhld=ccorrhld/ccnthold;
            end;
            else do;
             ccorrhld=0;
            end;
            %do iclstr=1 %to &inc;
             ccorr&iclstr=i(cycnt)+ccorrhld*(j(cycnt,cycnt)-diag(ind));
            %end;
           %end;
           %else %if %upcase(&ycorrs)=SAME & %upcase(&ccorrs)=DIFF 
           %then %do;
            cparmcnt=&inc; * number of distinct correlations;
            %do iclstr=1 %to &inc;
             ccorrhld=ccorr0&iclstr[+];
             ccnthold=ccnt&iclstr[+];
             if ccnthold>0 then do;
              ccorrhld=ccorrhld/ccnthold;
             end;
             else do;
              ccorrhld=0;
             end;
             ccorr&iclstr=i(cycnt)+ccorrhld*(j(cycnt,cycnt)-diag(ind));
            %end;
           %end;
           %else %if %upcase(&ycorrs)=DIFF & %upcase(&ccorrs)=SAME 
           %then %do;
            cparmcnt=cycnt*(cycnt-1)/2; * number of distinct correlations;
            ccorrhld=repeat(0,cycnt,cycnt);
            ccnthold=repeat(0,cycnt,cycnt);
            %do iclstr=1 %to &inc;
             ccorrhld=ccorrhld+ccorr0&iclstr;
             ccnthold=ccnthold+ccnt&iclstr;
            %end;
            ind=(ccnthold^=0);
            if ind[+]>0 then do;
             ccorrhld[loc(ind)]=ccorrhld[loc(ind)]/ccnthold[loc(ind)];
            end;
            %do iclstr=1 %to &inc;
             jind=j(cycnt,cycnt);
             ccorr&iclstr=ccorrhld#jind+i(cycnt)+(ccorrhld#jind)`;
            %end;
           %end;
           %else %do; * the both DIFF case;
            cparmcnt=&inc*cycnt*(cycnt-1)/2;
               * number of distinct correlations;
            %do iclstr=1 %to &inc;
             ccorrhld=repeat(0,cycnt,cycnt);
             ind=(ccnt&iclstr^=0);
             if ind[+]>0 then do;
              ccorrhld[loc(ind)]=ccorr0&iclstr[loc(ind)]/ccnt&iclstr[loc(ind)];
             end;
             jind=j(cycnt,cycnt);
             ccorr&iclstr=ccorrhld#jind+i(cycnt)+(ccorrhld#jind)`;
            %end;
           %end;
          %end;
          parmcnt=pparmcnt+mparmcnt+vparmcnt+cparmcnt;
          %if %upcase(&testcalc)=Y %then %do;
           print pparmcnt mparmcnt vparmcnt cparmcnt parmcnt;
          %end; 
          * it is possible in some cases, for example, when
            cvarnces=SAME and CCORRS=DIFF for correlation
            estimates to be distinctly less than -1 or
            distinctly > +1, but such cases will generate
            zero likelihood scores and so tend to not be selected

            it is also possible to get degenerate cases of exactly
            +1 or -1 which means associated pairs of y variables
            are treated as having values on an exact straight line
            these cases will also generate zero likelihood scores
            even for observations in the fold whose values for the 
            associated coordinates are on those lines
          ;
          %do iclstr=1 %to &inc;
           unitcorr&iclstr=0;
           ind=(ccorr&iclstr#(j(cycnt)-i(cycnt))<-1+1e-5);
           if ind[+]>0 then do;
            unitcorr&iclstr=1;
           end;
           ind=(ccorr&iclstr#(j(cycnt)-i(cycnt))>1-1e-5);
           if ind[+]>0 then do;
            unitcorr&iclstr=1;
           end;
          %end;
          %do iclstr=1 %to &inc;
           ccov&iclstr=diag(cstd[&iclstr,])*ccorr&iclstr*diag(cstd[&iclstr,]);
          %end;
          %if %upcase(&testcalc)=Y %then %do;
           print cluscnt cprop cmean cvar cstd prodcstd overcstd;
           %do iclstr=1 %to &inc;
            print unitcorr&iclstr ccorr&iclstr;
            print ccov&iclstr;  
           %end;
          %end;
          detval=repeat(.,&inc,1);
          %do iclstr=1 %to &inc;
           eignvals=eigval(ccorr&iclstr);
           nearzero=(eignvals<&near0eig); 
           if nearzero[+]>0 then do;
            eignvecs=eigvec(ccorr&iclstr);
            adjeigns=eignvals;
            adjeigns[loc(nearzero)]=&near0eig;
            ccorr&iclstr=eignvecs*diag(adjeigns)*eignvecs`;
            %if %upcase(&testcalc)=Y %then %do;
             print eignvals adjeigns "iclstr=&iclstr";
            %end;
            eignvals=adjeigns;
           end;
           ldetcrr=(log(eignvals))[+];
           detval[&iclstr]=exp(-ldetcrr/2);
           invccorr&iclstr=ginv(ccorr&iclstr);
           invccov&iclstr=
             diag(overcstd[&iclstr,])*invccorr&iclstr*diag(overcstd[&iclstr,]);
           invccovb&iclstr=ginv(ccov&iclstr);
           %if %upcase(&testcalc)=Y %then %do;
            print invccorr&iclstr;
            print invccov&iclstr;
            print invccovb&iclstr;
           %end;
          %end;
          %if %upcase(&testcalc)=Y %then %do;
           print detval;
          %end;
          * calculate contribution to LCV score for fold;
           clusdens=repeat(0,&inc,1);
           clusll=0;
           fyind=(fy^=.);
           nfy=fyind[+];
           do if=1 to fn;
            %do iclstr=1 %to &inc;
             diffy=(fy[if,loc(fyind[if,])]
                        -cmean[&iclstr,loc(fyind[if,])]);
             zdiffy=repeat(0,1,cycnt);
             zdiffy[1,loc(fyind[if,])]=
                     diffy#overcstd[&iclstr,loc(fyind[if,])];
              lhold=log(detval[&iclstr]/prodcstd[&iclstr]);
             %if %upcase(&testcalc)=Y %then %do;
              normval=-zdiffy*invccorr&iclstr*zdiffy`/2;
              hold1=zdiffy*invccorr&iclstr;
              print zdiffy hold1;
              print normval lhold "iclstr=&iclstr" if;
              print (exp(-zdiffy*invccorr&iclstr*zdiffy`/2+lhold))
                    (-zdiffy*invccorr&iclstr*zdiffy`/2+lhold);
             %end;
             clusdens[&iclstr]=exp(-zdiffy*invccorr&iclstr*zdiffy`/2+lhold);
             * zero density values increased to a small nonzero amount;
             clusdens[&iclstr]=max(clusdens[&iclstr],&mindens);
            %end;
            %if %upcase(&scretype)=EXPECTED %then %do;
             wgtddens=cprop#clusdens;
             cluswgts=wgtddens/wgtddens[+];
             %if %upcase(&testcalc)=Y %then %do;
              print cprop clusdens wgtddens cluswgts;
             %end;
             ind=(cluswgts>0);
             densterm=(cluswgts[loc(ind)]#log(wgtddens[loc(ind)]))[+];
            %end;
            %else %if %upcase(&scretype)=MIXTURE %then %do;
             densterm=log((cprop#clusdens)[+]);
            %end;
            %else %do; * so scretype is PREDICTD;
             densterm=log((cprop#clusdens)[<>]);
             * the following tended to favor singleton clusters
               because it ignores cprop and so is not recommended
             ;
             * densterm=log(clusdens[<>]);
            %end;
            clusll=clusll+densterm;
            %if %upcase(&testcalc)=Y %then %do;
             print if everzero densterm clusll clusdens;
            %end;
           end;
           clusll=clusll-nfy/2*log(2*pi); 
           %if %upcase(&testcalc)=Y %then %do;
            print everzero clusll "ifold" &ifold;
           %end; 
           %if %upcase(&BIC)=Y %then %do;
            %if %upcase(&usenmeas)=Y %then %do;
             clusll=clusll-parmcnt*log(nfy)/2;
            %end; 
            %else %do;
             clusll=clusll-parmcnt*log(fn)/2;
            %end; 
            %if %upcase(&testcalc)=Y %then %do;
             print "BIC" clusll parmcnt fn (log(fn)/2 nfy (log(nfy)/2);
            %end; 
           %end;
           * end of fold contribution computation;
          * end of unstructured multivariate normal scoring;
         %end;
         edit CLUS_lcvscr&inc var _all_;
         read all var _all_;
         %if %upcase(&testcalc)=Y %then %do;
          print "before" lcvvalue;
         %end;
         if ^nocalc then do;
          if ^everzero then do;
           %if %upcase(&BIC)=Y %then %do;
            bicvalue=-2*clusll;
            %if %upcase(&testcalc)=Y %then %do;
             print "BIC" bicvalue;
            %end;
            lcvvalue=lcvvalue+clusll/nfy;
           %end;
           %else %if &foldcnt>1 %then %do;
            lcvvalue=lcvvalue+clusll/&nmeas;
           %end;
           %else %do;
            lcvvalue=lcvvalue+clusll/nfy;
           %end;
          end;
          else do;
           lcvvalue=0;
          end;
         end;
         else do;
          lcvvalue=.;
         end;
         %if %upcase(&testcalc)=Y %then %do;
          print "after" lcvvalue;
         %end;
         replace all var {lcvvalue
                          %if %upcase(&BIC)=Y %then %do;
                           ,bicvalue
                          %end;
                         };
         call symput("evrzro&inc",compress(char(everzero)));
        quit;
        * end of not ever zero nor no clusters handling;
       %end;
       %else %if &noclstrs %then %do;
        proc iml;
         edit CLUS_lcvscr&inc var _all_;
         read all var _all_;
         %if %upcase(&testcalc)=Y %then %do;
          print "before" lcvvalue;
         %end;
         lcvvalue=.;
         %if %upcase(&testcalc)=Y %then %do;
          print "after" lcvvalue;
         %end;
         replace all var {lcvvalue};
        quit;
       %end;
       %if %upcase(&testcalc)^=Y %then %do;
        * if not deleted, it will not be replaced if ever empty;
        ods exclude all;
        ods results off;
        proc datasets library=work;
         delete &cmpclsnm;
        run;
