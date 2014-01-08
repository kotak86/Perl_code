#!/tools/xgs/perl/5.8.5/bin/perl

#use warnings;
use strict;

#-----------------------------------------------------------------------------------------------
# 				Veriable declaration
#-----------------------------------------------------------------------------------------------
system("clear");
my $DEBUG = '1';
my $dir_date = localtime();
my %mnth     =  (Jan =>"01", Feb =>"02", Mar =>"03", May =>"05", Apr =>"04", Jun=>"06",
                 Jul=>"07", Aug=>"08", Sep=>"09", Oct=>"10", Nov=>"11", Dec=>"12");
my $cntd     = 0; 
my $cntf =0; 
my @mjr_rng = (14); 
my @min_rng = qw (3); 
#my @min_rng = (1..5);
my $min; 
my $mjr;
my $REL;
my $sub_info = "submission_info";
my $wkly_bld = "/proj/XCOtcRepo/ipv/automation/build.txt";
my $script_dir = "/proj/ipco/users/hshah/ankit/scripts/automation"; # Change to your local path #
#my $central_dir = "/proj/XCOtcRepo/ipv/automation/scripts"; # Change to your local path #
my $central_dir = "/proj/ipco/users/hshah/ankit/scripts/automation"; # Change to your local path #
#my $wkly_bld = "$script_dir/build.txt";
my $dsparg_list = "$script_dir/2012.2_dspIP";
my $edkarg_list = "$script_dir/2012.2_edkIP";
my $crtlsf_dsp = "$script_dir/create_lsf_rodin_dspip.pl";
my $crtlsf_edk = "$script_dir/create_lsf_rodin_epdip.pl";
my $lsf_loc = "/proj/ipco/users/hshah/lsf/$ENV{USER}_lsf";
my $update_xml = "$central_dir/auto_annotation";
#my $update_xml = "/proj/xtcRepo/ipv/automation/scripts/auto_annotation/";

#-------------------------------------------------------------------------------------------------
# 				Veriable Logic
#-------------------------------------------------------------------------------------------------

# Split localtime in date, month day etc.

my @dte_splt = split /\s+/, $dir_date;          # 0->day, 1->Month, 2->date, 3->time, 4->year


# Make date in two digit if it less then 10.

if ($dte_splt[2] < 10){
 $dte_splt[2] = "0$dte_splt[2]";}

# map the corresponding # accroding to month.
my $mth_no   = $mnth{$dte_splt[1]}; 

#------------------------------------------------------------------------------------------------
# Email Function
#------------------------------------------------------------------------------------------------

        sub suc_mail{
            my $sub = $_[0];
	    my $msg = $_[1];
	    my $rv_link = $_[2]; 
	    my $sign   = "\n\nThanks & Regards\nAnkit Kotak\nIP Verification Intern\nXilinx Inc, San Jose\nDesk: +1 408 879 7704\nCell: +1 408 228 7284";
	    open (SENDMAIL,"|/usr/lib/sendmail -oi -t -odq")or die"Can't fork for sendmail: $!\n";
            print SENDMAIL "From:Ankit Kotak<ankit.kotak\@xilinx.com>\n";
            print SENDMAIL "To:<ankit.kotak\@xilinx.com> <hshah\@xilinx.com>\n";
            print SENDMAIL "$sub\n";
            print SENDMAIL "Hello Admin,\n\n";
            print SENDMAIL $msg;
 	    print SENDMAIL "$rv_link";
 	    print SENDMAIL $sign;
            close(SENDMAIL) or warn "sendmail didn't close nicely";
            0; }

#-----------------------------------------------------------------------------------------------------------
# Function checl for the buid is ready or not
#----------------------------------------------------------------------------------------------------------e warnings;
sub chek_file{

        my $rodin_file = "status/modelsim_10.1a_Rodin-lin64";
        my $ise_file = "status/modelsim_10.1a_ISE-lin64";
        my $REL = $_[0];
        my $dir_I =  "/proj/xbuilds/clibs";
        my $dir_R = "/proj/xbuilds/clibs_rodin";
        my $I_state;
        my $R_state;
        my $cntd = 0;
        my $state; 
	my $st = 0;
        my $f_msg = "Build is fail for $REL at";
	my $mail_sub = "Subject: $REL fails for"; 

        opendir (ICHECK, $dir_I) or die "Could not open";
        while ($_ = readdir(ICHECK)){
                if ($_ eq $REL){
                        print "$REL found at $dir_I\n";
                        $cntd = $cntd + 1;
                        last;
                }
        }


        opendir (RCHECK, $dir_R) or die "could not open";
        while($_ = readdir(RCHECK)){
                if($_ eq $REL){
                        print "$REL found at $dir_R\n";
                        $cntd = $cntd + 1;
                        last;
                }
        }
        if ($cntd == 2){
                if((-e "$dir_I/$REL/$ise_file") && (-e "$dir_R/$REL/$rodin_file")){

                        print "Found : $dir_I/$REL/$ise_file\n";
                        print "Found : $dir_R/$REL/$rodin_file\n";

                        open(ISTATE, "$dir_I/$REL/$ise_file")or die $!;
                        open(RSTATE, "$dir_R/$REL/$rodin_file") or die $!;


                        while ($_ = <ISTATE>){
                                $I_state = $_ ;  chomp($I_state);
                                if($I_state ne "PASS"){
                                        my $sub = "$mail_sub ISE Compilation"; 
					my $msg = "$f_msg $dir_I/$REL/$ise_file";
					&suc_mail($sub, $msg);
                                        print "somethig is wrong";
                                }
                        }

                        while ($_ = <RSTATE>){
                                $R_state = $_; chomp ($R_state);
                                if($I_state ne "PASS"){
                                        my $sub =  "$mail_sub Rodin Compilation";
					my $msg = "$f_msg $dir_R/$REL/$rodin_file";
					&suc_mail($sub, $msg);
                                        print "Something is wrong";
                                }
                        }

                        if(($I_state eq "PASS") && ($R_state eq "PASS")){
                                $state = "PASS";$st = 1;

                        }

                        else{
                                $state = "FAIL"; $st = 0;

                        }

                }

        }

        else {
                print "Either $dir_I/$REL/$ise_file or $dir_R/$REL/$rodin_file do not found\n";
		$state = "FAIL"; $st = 0;

        }
        print "Final state is $state\n";
        return $st;
}

# -------------------------END of Function Check File------------------------------------------------------


#----------------------------------------------------------------------------------------------------------
#  Check for ids** build in build.txt
#-----------------------------------------------------------------------------------------------------------

sub chek_rel{
      $REL = $_[0];
   my $file = $_[1]; 
   my $crt_lsf = $_[2];  
   my $lsfarg_list = $_[3]; 
   my $ip_type = $_[4]; my $ip = uc($ip_type);
   my $lsf_dir; 
   my $submited_file; 
   my $mail_sub = "Subject: $ip IP Jobs are submitted for build ".$REL. "\n";
   my $mail_msg = "$ip IP Jobs are submitted for build $REL.\nYou can see the result at\n"; 
   my $partlist = "/proj/xbuilds/clibs_rodin/$REL/partlist.svg";
	if ($REL =~ /^ids/){
	$submited_file = "$script_dir/../ta/$REL\_$ip_type\.txt";
	print "$submited_file\n";	
   }	
   else {
	$submited_file = "$script_dir/../tda/$REL\_$ip_type\.txt";
   }

	

   if($ip_type eq "dsp"){ 
	$lsf_dir = "$REL\_dsp"; 
   }
   else{ 
	$lsf_dir = "$REL\_edk"; 
   }

   unless(-e "$submited_file"){
	if ((&chek_file($REL)) and (-e $partlist)){
		open (FILE,"$lsfarg_list") or die $!;
     		`rm -rf $lsf_loc/$lsf_dir/`;
	 	 while (<FILE>){
          	   	my $line = $_; chomp ($line);
          	   	print "$crt_lsf lin $line $REL\n\n" if $DEBUG;
          	   	my $run_lsf = `$crt_lsf lin $line $REL`;
		 }
				
     		 close (FILE);
        	 print "lsf files created at : $lsf_loc/$lsf_dir/ \n";
        	 `cd $lsf_loc/$lsf_dir/; ls -d *job_lin >> $lsf_loc/$lsf_dir/linfiles`;
		 open (LINFILE,"$lsf_loc/$lsf_dir/linfiles") or die $!;
           	 while (<LINFILE>){
                      my $linf = $_; chomp ($linf);
                      print "$linf\n\n" if $DEBUG;
#		      my $mytask = `source /group/xcofarm/lsf/conf/profile.lsf;bsub -q medium -P ip_ipv_regressions -R "rusage[mem=16000]" -R "select[type==X86_64 && os==lin]" < $lsf_loc/$lsf_dir/$linf`;
                      print "$ip_type: Jobs are submitted for $linf \n\n";
        	 }

                 close(LINFILE);
		 
		 print "$script_dir/$sub_info/$REL\_submitd_$ip_type";			   
        	 open DFE, ">$script_dir/$sub_info/$REL\_submitd_$ip_type" or die $!;
       		 print DFE "Job submitted for build $REL ";
                 print "job_submitted & file $REL\_submitd_$ip_type created at $script_dir/$sub_info .\n";
       
		 my $result = "http://xcorvprod/sfprojects/RV/web/view/showexp?Site=CO%3B%3BIN&Build=$REL&OSName=&Family=&Core=&Status=&UserName=hshah;;saurabh&SuperSuite=&TestSuite=&Flow=&Device=&TestcaseName=&ErrorStr=&CRNum=&Notes=&fromdate=&todate=&daterange=&RunAgain=RunAgain&formName=expform&formurl=showexp&table_data=&userId=hshah";
                 &suc_mail($mail_sub, $mail_msg, $result);

		
		  print my $xmlupdate = `/tools/xgs/perl/5.8.5/bin/perl /$update_xml/$file $REL $ip_type`;




	}
   
   }
   
}
#---------------------------------------------------------------------------------------------------------------------------

open WKBLD, "$wkly_bld" or die $!;

 while (<WKBLD>){
 $REL = $_; chomp($REL); my $file = "wklupdatexml.pl";
 &chek_rel($REL, $file, $crtlsf_dsp, $dsparg_list,"dsp") ;

}


foreach $mjr (@mjr_rng){

    foreach $min (@min_rng){
	$REL = "$mjr\.$min\_$mth_no$dte_splt[2]";chomp($REL);
	print $REL; my $file = "updatexml.pl";
 	 &chek_rel($REL, $file, $crtlsf_dsp, $dsparg_list, "dsp");
#	 &chek_rel($REL,$file, $crtlsf_edk, $edkarg_list, "edk");

   }
}










