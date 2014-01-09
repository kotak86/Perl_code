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
my @mjr_rng = (14 .. 24); 
my @min_rng = (1..5); 
my $min; 
my $mjr;
my $REL;
my $sub_info ="submission_info";
my $dir_chk = "/proj/xbuilds/";
my $wkly_bld = "/proj/XCOtcRepo/ipv/automation/build.txt";
#my $script_dir = "/proj/ipco/users/hshah/ankit/scripts/automation"; # Change to your local path #
my $script_dir = "/proj/xtcRepo/ipv/automation/scripts"; # Change to your local path #
#my $wkly_bld = "$script_dir/build.txt";
my $dsparg_list = "$script_dir/2012.2_dspIP";
my $edkarg_list = "$script_dir/2012.2_edkIP";
my $crtlsf_dsp = "$script_dir/create_lsf_rodin_dspip.pl";
my $crtlsf_edk = "$script_dir/create_lsf_rodin_epdip.pl";
my $lsf_loc = "/proj/ipco/users/hshah/lsf/$ENV{USER}_lsf";



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
            my $msg = $_[0];
	    my $build = $_[1];
	    my $rv_link = $_[2]; my $ip = $_[3]; uc($ip);
            my $msgdf  = "Directory ".$REL." not found.\n";
	    my $sign   = "\n\nThanks & Regards\nAnkit Kotak\nIP Verification Engineer \nXilinx Inc, San Jose\nDesk: +1 408 879 7704\nCell: +1 201 668 1920";
	    open (SENDMAIL,"|/usr/lib/sendmail -oi -t -odq")or die"Can't fork for sendmail: $!\n";
            print SENDMAIL "From:Ankit Kotak<ankit.kotak\@xilinx.com>\n";
            print SENDMAIL "To:<ankit.kotak\@xilinx.com> <hshah\@xilinx.com> <saurabh\@xilinx.com>\n";
            print SENDMAIL "Subject: $ip IP Jobs are submitted for build ".$build. "\n";
            print SENDMAIL "Hello Admin,\n\n";
            print SENDMAIL $msg;
 	    print SENDMAIL "$rv_link";
 	    print SENDMAIL $sign;
            close(SENDMAIL) or warn "sendmail didn't close nicely";
            0; }
#----------------------------------------------------------------------------------------------
#  Check for ids** build in build.txt
#-----------------------------------------------------------------------------------------------------------

sub chek_rel{
   $REL = $_[0]; my $file = $_[1]; my $crt_lsf = $_[2];  my $lsfarg_list = $_[3]; my $ip_type = $_[4]; my $lsf_dir; 
   my $submited_file = "$script_dir/$sub_info/$REL\_submitd_$ip_type";
   my $remove_cnt_file;

    if($ip_type eq "dsp"){ $lsf_dir = "$REL\_dsp"; }
    else{ $lsf_dir = "$REL\_edk"; }

    unless(-e "$submited_file"){
        opendir (DCHECK, "$dir_chk") or die $!;
	while($_ = readdir(DCHECK)){
	   if($_ eq $REL){
	      $cntd = $cntd+1;
	      print "$REL found.\n\n";
	          if (-e "$dir_chk/$REL/$file") {
		     print "$REL directory & $file found for build at $dte_splt[3].\n";
			if ($REL =~ /^ids/) {
                                $remove_cnt_file = `rm -rf $script_dir/../ta/$ip_type.txt`;
                        } else {
                                $remove_cnt_file = `rm -rf $script_dir/../tda/$ip_type.txt`;
                        }

			open (FILE,"$lsfarg_list") or die $!;
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
			     my $mytask = `source /group/xcofarm/lsf/conf/profile.lsf;bsub -q medium -P ip_ipv_regressions -R "rusage[mem=16000]" -R "select[type==X86_64 && os==lin]" < $lsf_loc/$lsf_dir/$linf`;
                             print "$ip_type: Jobs are submitted for $linf \n\n";
        		  }
                           close(LINFILE);
			   
        		   open DFE, ">$submited_file" or die $!;
        		   print DFE "Job submitted for build $REL ";
        		   print "job_submitted & file $REL\_submitd_$ip_type created at $script_dir/$sub_info .\n";
       
			  my $result = "http://xcorvprod/sfprojects/RV/web/view/showexp?Site=CO%3B%3BIN&Build=$REL&OSName=&Family=&Core=&Status=&UserName=hshah;;saurabh&SuperSuite=&TestSuite=&Flow=&Device=&TestcaseName=&ErrorStr=&CRNum=&Notes=&fromdate=&todate=&daterange=&RunAgain=RunAgain&formName=expform&formurl=showexp&table_data=&userId=hshah";
                           &suc_mail("Jobs are submitted for build $REL.\n", $REL, $result,$ip_type);






                   }
		    
	    }
 		
         }
	
   }

}

#---------------------------------------------------------------------------------------------------------------------------

open WKBLD, "$wkly_bld" or die $!;

 while (<WKBLD>){
 $REL = $_; chomp($REL); my $file = "ta-info.txt";
 &chek_rel($REL,$file,$crtlsf_dsp,$dsparg_list,"dsp") ;

}


foreach $mjr (@mjr_rng){

    foreach $min (@min_rng){
	$REL = "$mjr\.$min\_$mth_no$dte_splt[2]";chomp($REL);
        my $file = "tda-info.txt";
# 	 &chek_rel($REL,$file, $crtlsf_dsp, $dsparg_list, "dsp");
#	 &chek_rel($REL,$file, $crtlsf_edk, $edkarg_list, "edk");

   }
}










