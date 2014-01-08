#!/tools/xgs/perl/5.8.5/bin/perl
use strict;
use warnings;

system("clear");
if (! defined $ENV{REL}){

print "\nPlease set directory name as setenv REL ** from which you want to filter the design (e.g. 14.2_0525).";
print "\nIf you want to check your REL ";

exit;
}

my $dir = "/proj/XCOtcRepo/ipv/epdIP";
print "Are you sure you want to filter the testcase for \n\nThe directory $ENV{REL} under $dir (enter y for yes or n for no ) : ";
my $response = <>; chomp ($response);

if ($response ne "y"){
print "\nPlease setenv REL ** to directory you want to filter.\n";
exit;
}


print "\nEnter LIST of IP's (e.g. ALL_IP, supply specific IP(s) name) : ";
my $fltr_type = <>; chomp($fltr_type);
print "\nPlease enter run type you want to filter test from (BVT, REGR, FOCUS): ";
my $run_type = <>;chomp($run_type);
print "\nPlease enter # of design you want to filter per family.\n(e.g.for vivado_static enter betn 2-6 for full set 400 per family ): ";
my $no_dsgn = <>;chomp($no_dsgn); #$no_dsgn = $no_dsgn -1;
#my $max_dsgn = $no_dsgn + 1;
print "\nPlease enter filter type (e.g. ST for  static or FULL for full set): ";
my $f_type = <>; chomp($f_type);

#-----------------------------------------------------------------------------------
#              Veribale Declaration
#-----------------------------------------------------------------------------------
# @a_family is array to for set of family, for which script can filter the testcase
my @a_family = ('virtex7','kintex7','artix7', 'virtex7l','kintex7l','artix7l', 'qvirtex7','qkintex7','qartix7');
my $range;  
my @dir_splt;
my $ip_dsgn =0;
my $hder =0; 
my $fltr_dir = "$ENV{REL}\_$run_type\_$f_type\_fltr";
print $fltr_dir = "$ENV{REL}\_$run_type\_$f_type\_fltr";

#-----------------------------------------------------------------------------------
#              Printing Messages
#-----------------------------------------------------------------------------------
my $over_dsgnmsg = "So we have selected $no_dsgn designs randomaly for this architecture.\n";

#-----------------------------------------------------------------------------------
#              Veribale Path, need to change as per user location
#-----------------------------------------------------------------------------------
my $tcases = "$dir/$ENV{REL}/$run_type/HEAD/dspIP";
my $crt_dir = `mkdir -p $dir/$fltr_dir/$run_type/HEAD/dspIP`; 
my $ips_path = "$dir/$fltr_dir/$run_type/HEAD/dspIP";

#----------------------------------------------------------------------------------------
#			Get all IP's from the directory 
#----------------------------------------------------------------------------------------

opendir (FLTRDIR, "$tcases") or die $!;
my @fltr_all_IP = readdir(FLTRDIR);

#-------------------------------------------------------------------------------------------

sub fltr_core{
 my @cores = @_;
 foreach $_ (@cores) {
     my $crt_dir = "$_"; 
     next if $crt_dir eq "." or $crt_dir eq "..";
     my $ipdir = `mkdir -p $ips_path/$crt_dir/family_report`;
     my $ip = "$ips_path/$crt_dir";
     my $iprpt = "$ips_path/$crt_dir/family_report";
     my $total =0; 
     my $cutr = 0; 
     my $family;
     #-------------------------------------------------------
     #             Opeining File
     #-------------------------------------------------------

     open RPT,">>$ips_path/fltr_rpt_detail" or die $!;
     open SRPT,">>$ips_path/fltr_rpt_sort" or die $!;
     open BRPT,">>$ips_path/fltr_rpt_brief" or die $!;

     my $crtIP_path = "$tcases/$crt_dir";
     my $def_dir = "$tcases/$crt_dir/DEFAULT_FAMILY";
 
     
     # will copy commen_files folder & *xml files to the fltr tc ip fldr.
     my $cop_fnf = `cp -r $crtIP_path/common_files $ip; cp -r $crtIP_path/*.xml $ip`;

     print "\n$crt_dir\n";
     print RPT "IP :$crt_dir\n";
     print SRPT "IP :$crt_dir\n";
     
     print "Family"." " x(30)."\# of desing found". " " x(15)."\# of desing Picked\n";
     print RPT "Family"." " x(30)."\# of desing found". " " x(15)."\# of desing Picked\n";	
     print SRPT "Family"." " x(30)."\# of desing found". " " x(15)."\# of desing Picked\n"; 
     
     if($hder == 0){
     print BRPT "Name of IP"." " x(25). "No\. of Design(s) found\n"; $hder+=1
     }

     foreach $family(@a_family){
     my @fmly_tc; 
     my $num; 
     my @family_dsgn; 
     my $rndm_num;
     my $fname = $family."_tc";	

	if(-d "$def_dir"){
	    print "$family\n";
	    my $getdsgn = `cd $def_dir; grep -w "'$family'" */input/*.xco >>$iprpt/$fname`;
	  	if(-z "$iprpt/$fname"){
			$num = 0; 
			print "\nIP $crt_dir: Do not found any design for $fname family.\n";
			print RPT "$family"." " x(40-length($family)).($num)." " x(37-length($num)).($num)."\n";
			unlink("$iprpt/$fname");
		}  
		
		if (-e "$iprpt/$fname"){
		
			open LIST, "$iprpt/$fname" or die $!; 
			print @family_dsgn = <LIST> ;  $range = $#family_dsgn ; 
			#my $rndm_num; 
			$num = $range +1; `mkdir $ip/$family`;
			#`rm -rf $fmly_rpt/$fname`;		
		
			if($num > 0 && $num <= $no_dsgn){
                		$total = $total + $num;
				print "\nWe found total ".$num." tc for $family architecture.\n";
		        	print RPT "$family"." " x(45-length($family)).($num)." " x(40-length($num)).($num)."\n"; 
	        		print SRPT "$family"." " x(45-length($family)).($num)." " x(40-length($num)).($num)."\n"; 		
				foreach(@family_dsgn){
		    			@dir_splt = split /\//, $_;
		    			print "This is for $family: $dir_splt[0] \n";
		    			`cp -r $def_dir/$dir_splt[0] $ip/$family`; 	     
				}  
                	}	

			elsif($num > $no_dsgn){
				$cutr = $cutr + $no_dsgn;
				print RPT "$family"." " x(45-length($family)).($num). " " x(40 -length($num)). "$no_dsgn\n";		
				print SRPT "$family"." " x(45-length($family)).($num). " " x(40 -length($num))."$no_dsgn\n";
				print "\nWe found total ".($range+1)." designs for $family architecture.\n$over_dsgnmsg";

		    		for(my $i=0; $i < $no_dsgn; $i++){
			    		$rndm_num = int(rand($range));
			    		@dir_splt = split /\//, $family_dsgn[$rndm_num];
			    		print "This is for $family: $dir_splt[0] \n";
			    		`cp -r $def_dir/$dir_splt[0] $ip/$family`;
		    			splice(@family_dsgn,$rndm_num,1); $range--;
 	           		}
	        	
			}		
	      
		}
	
	}
	
	
	elsif(-d "$crtIP_path/$family"){
	     opendir(I_FAMILY, "$crtIP_path/$family/") or die $!;
	     while($_ = readdir(I_FAMILY)){
		   next if $_ eq "." or $_ eq ".."; push (@family_dsgn, $_);
	     }
					
	     $range = $#family_dsgn; print "\n"; 
	     $num = $range+1;
	     if ($num<=$no_dsgn){
		  $total = $total + $num; 
		  print RPT "$family"." " x(40-length($family)).($num)." " x(37-length($num)).($num)."\n";      
		  print SRPT "$family"." " x(40-length($family)).($num)." " x(37-length($num)).($num)."\n"; 
		  `cp -r $crtIP_path/$family $ip/`;	
	     }	
		    
	     else{
		$cutr = $cutr + $no_dsgn;
		print RPT "$family"." " x(40-length($family)).($num). " " x(37 -length($num)). "$no_dsgn\n";      
		print SRPT "$family"." " x(40-length($family)).($num). " " x(37 -length($num)). "$no_dsgn\n";
		`mkdir $ip/$family`;
		for(my $i=0; $i < $no_dsgn; $i++){
			$rndm_num = int(rand($range));
	        	print "This is for $family: $family_dsgn[$rndm_num] \n";
	 		`cp -r $crtIP_path/$family/$family_dsgn[$rndm_num] $ip/$family/`;
			splice(@family_dsgn,$rndm_num,1);$range--;
	        }
	     
	     } 
				
	}

			
	else {
 	     $num = 0; 
	     print "\nDo not found any design for filteration for this $family.\n";
	     print RPT "$family"." " x(45-length($family)).($num)." " x(40-length($num)).($num)."\n";      
	}
     }
        
      print "\nIP $crt_dir: We found total ".($total+$cutr)." testcase for this architecture.";
      print RPT "\nIP $crt_dir: We found total ".($total+$cutr)." testcase for this architecture.";
      print SRPT "\nIP $crt_dir: We found total ".($total+$cutr)." testcase for this architecture.";
      print BRPT "$crt_dir"." "x(34 -length $crt_dir). ":". " "x(15).($total+$cutr)."\n";
	
      print "\n";print "***" x (32);print "\n";
      print RPT "\n";print RPT "***" x (32);print RPT "\n";
      print SRPT "\n";print SRPT "***" x (32);print SRPT "\n";$ip_dsgn += $total+$cutr;

 }

my $finalmsg ="\nFilteration done for all the IP with maximum $no_dsgn designs for each family. Genrated total $ip_dsgn designs.\n";

print $finalmsg;
print RPT $finalmsg;
print SRPT $finalmsg;
print BRPT $finalmsg;

my $change_permission =  `chmod -R 777 $dir/$fltr_dir`;
print "Permission chnage to 777 for the directory $fltr_dir under $dir";
}


if($fltr_type eq "ALL_IP"){
   &fltr_core(@fltr_all_IP);
  
}

else {

 my @fltr_ip = split / /, $fltr_type;
 &fltr_core(@fltr_ip);
}





