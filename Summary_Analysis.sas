/* Clinical SAS: Basic Demographic Analysis */
proc means data=sashelp.class n mean std min max;
    var age height weight;
    title "Summary Statistics for Clinical Study Group";
run;
