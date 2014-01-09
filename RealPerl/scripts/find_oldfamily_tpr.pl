#!/usr/local/bin/perl 
#
#=======================================================
#
#       Created by HEMANG SHAH, IPV , Xilinx,Inc.
#       Last Modified: 08/27/2011
#
#=======================================================
#
#
### --- To generate tests from tpr files --- ###

system("clear");
$DEBUG='0';
my $PASS = '1';

print "\nEnter file name (e.g. core_vrsn ) : ";
$file = <>;
chomp($file);


$tpr_path = "/proj/ipco/users/hshah/ankit/Perforce/IP3_ankitko_ipdsp_regressions/DEV/hw";
$s_path = "/proj/ipco/users/hshah/ankit/scripts/Oldfmlyinfo/";

open (FILE,"$file") or die $!;
open (FILEW, ">>$s_path/tprinfo") or die $!;
#open (FILW,  ">> $s_path/nottpr.ls") or die $!;

#print FILW "Do not found newdevices.tpr and ver.tpr.";
while (<FILE>)
{
     $core = $_;
     chomp ($core);

     ($core_name, $core_ver) = ($core =~ /(\w+)\/(\w+)/i);
#print  "$core_ver: \n";
 $a = 0; $b = 0; $c = 0; $d = 0; $e = 0;
$nd_tpr = "$tpr_path/$core/test/$core_ver\_newdevices.tpr";
$vrsn_tpr = "$tpr_path/$core/test/$core_ver.tpr";
$foced_tpr = "$tpr_path/$core/test/$core_ver\_focused.tpr";
$BVT_TPR = "$tpr_path/$core/test/$core_ver\_bvt.tpr";
$daily_TPR = "$tpr_path/$core/test/$core_ver\_daily.tpr";
$focvivado_TPR = "$tpr_path/$core/test/$core_ver\_focused_vivado.tpr";

       if (-e "$nd_tpr") {
	       $oldfmlys = `egrep -v '^#' $nd_tpr |egrep -i "spartan*"  >> "$s_path/snew_$core_ver"`;
	       $oldfmlyv = `egrep -v '^#' $nd_tpr | egrep -w "virtex6l|virtex6|qvirtex6" >> "$s_path/vnew_$core_ver"`;
		if (-s "$s_path/snew_$core_ver" or -s  "$s_path/vnew_$core_ver"){
			
			 my $tprfile = "$core_ver\_newdevices.tpr";
			 #	 print  "$core_ver: ";
			 print FILEW $file_msg = "$tprfile contains non 7 series architecture(s).\n";
			 unlink "$s_path/snew_$core_ver" if -z "$s_path/snew_$core_ver";
			 unlink "$s_path/vnew_$core_ver" if -z "$s_path/vnew_$core_ver"; $a = 1;

		}
		else {unlink "$s_path/snew_$core_ver" and unlink "$s_path/vnew_$core_ver" }
       } 
       elsif (-e "$vrsn_tpr") {
     $oldfmlys = `egrep -v '^#' $vrsn_tpr |egrep -i "spartan*"  >> "$s_path/s$core_ver"`;
     $oldfmlyv = `egrep -v '^#' $vrsn_tpr | egrep -w "virtex6l|virtex6|qvirtex6" >> "$s_path/v$core_ver"`;

 
 	    if (-s "$s_path/s$core_ver" or -s "$s_path/v$core_ver"){
		 my $tprfile = "$core_ver.tpr";
		 #print  "$core_ver: ";
		 print FILEW $file_msg =  "$tprfile contains non 7 series architecture(s).\n";
		 unlink "$s_path/s$core_ver" if -z "$s_path/s$core_ver";
		 unlink "$s_path/v$core_ver" if -z "$s_path/v$core_ver";$a = 1;
        }

 	else {unlink "$s_path/s$core_ver" and unlink "$s_path/v$core_ver"}
 
    }

    else {
	    #print  "$core_ver: "; 
	print FILEW $file_msg = "$core_ver\_newdevices.tpr and"."$core_ver.tpr not found.\n";
   	 $a = 1;

   } 
	
     if (-e "$foced_tpr"){
      $b =0;
     }	

     else {
	     #	print  "$core_ver: ";
	$focus= "$core_ver\_focused.tpr"." not found.";
	print  FILEW "$focus\n"; $b = 1;
     }

	
     if(-e "$BVT_TPR"){
       $c = 0;           
     }

     else {
	     #print  "$core_ver: ";
	$bvt = "$core_ver\_bvt.tpr"." not found.";   
	print  FILEW "$bvt\n"; $c = 1;
     }
	 
	   if(-e "$daily_TPR"){
       $d = 0;           
     }

     else {
	     #print  "$core_ver: ";
	$bvt = "$core_ver\_daily.tpr"." not found.";   
	print FILEW  "$bvt\n"; $d = 1;
     }
	 
	   if(-e "$focvivado_TPR"){
       $e = 0;           
     }

     else {
	     #print  "$core_ver: ";
	$bvt = "$core_ver\_focused_vivado.tpr not found";

	print FILEW  "$bvt\n"; $e = 1;
     }

	 
	 
	if ($a or $b or $c or $d or $e){
	
	print FILEW "\n";print FILEW  "***" x (32);print FILEW "\n";
}

}


close(FILE);
