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
my $dir_chk = "/proj/xbuilds/";
my $wkly_bld = "/proj/XCOtcRepo/ipv/automation/build.txt";
my $script_dir = "/proj/ipco/users/hshah/ankit/scripts/edkdsp_auto"; # Change to your local path #
my $dsparg_list = "$script_dir/lsfarg_vivado_tstatic";
my $edkarg_list = "$script_dir/edkip_lsf_arg";
my $crtlsf_dsp = "$script_dir/w_create_lsf_rodin_dspip.pl";
my $crtlsf_edk = "$script_dir/w_create_lsf_epd.pl";
my $lsf_loc = "/proj/ipco/users/hshah/ankit/lsf/ankitko_lsf";


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
	    my $rv_link = $_[2];
            my $msgdf  = "Directory ".$REL." not found.\n";
	    my $sign   = "\n\nThanks & Regards\nAnkit Kotak\nIP Verification Engineer \nXilinx Inc, San Jose\nDesk: +1 408 879 7704\nCell: +1 201 668 1920";
	    open (SENDMAIL,"|/usr/lib/sendmail -oi -t -odq")or die"Can't fork for sendmail: $!\n";
            print SENDMAIL "From:Ankit Kotak<ankit.kotak\@xilinx.com>\n";
            print SENDMAIL "To:<ankit.kotak\@xilinx.com> <hshah\@xilinx.com>\n";
#	    print SENDMAIL "To:<hshah\@xilinx.com>\n";
            print SENDMAIL "Subject: DSPIP & EDK IP Jobs are submitted for build ".$build. "\n";
            print SENDMAIL "Hello Admin,\n\n";
            print SENDMAIL $msg;
 	    print SENDMAIL "$rv_link";
 	    print SENDMAIL $sign;
            close(SENDMAIL) or warn "sendmail didn't close nicely";
            0; }
#----------------------------------------------------------------------------------------------




#------------------------------------------------------------------------------------------------
sub cretlsf_n_jobsubmit {
     my $crt_lsf = $_[0];  my $lsfarg_list = $_[1]; 
     open (FILE,"$lsfarg_list") or die $!;
     while (<FILE>){
          my $line = $_;
          chomp ($line);
          print "$crt_lsf lin $line $REL\n" if $DEBUG;
          my $run_lsf = `$crt_lsf lin $line $REL`;
     }
     close (FILE);
	print "lsf files created at : $lsf_loc/$REL\_rodin \n";
	`cd $lsf_loc/$REL\_rodin/; ls -d *job_lin >> $lsf_loc/$REL\_rodin/linfiles`;
	    open (LINFILE,"$lsf_loc/$REL\_rodin/linfiles") or die $!;
	    while (<LINFILE>){
            	my $linf = $_;
                chomp ($linf);
             	print "$linf\n" if $DEBUG;
				
				
		my $mytask = `source /group/xcofarm/lsf/conf/profile.lsf;bsub -q medium -P ip_ipv_regressions -R "rusage[mem=16000]" -R "select[type==X86_64 && os==lin]" < $lsf_loc/$REL\_rodin/$linf`;
		close(LINFILE);
				
}
				
	open DFE, ">$script_dir/$REL\_submitd" or die $!;
	print DFE "Job submitted for build $REL ";
	print "job_submitted file created & job are submitted \n";

	



}


#----------------------------------------------------------------------------------------------------------
#  Check for ids** build in build.txt
#-----------------------------------------------------------------------------------------------------------

sub chek_rel{
   $REL = $_[0];
   my $file = $_[1];
   
   unless(-e "$script_dir/$REL\_submitd"){
        opendir (DCHECK, "$dir_chk") or die $!;
	while($_ = readdir(DCHECK)){
	   if($_ eq $REL){
	      $cntd = $cntd+1;
	      print "$REL found.\n";
	          if (-e "$dir_chk/$REL/$file") {
		     print "$REL directory & $file found for build at $dte_splt[3].\n";
       #              &cretlsf_n_jobsubmit($crtlsf_dsp,$dsparg_list);
		     &cretlsf_n_jobsubmit($crtlsf_edk,$edkarg_list);
		     my $result = "http://xcorvprod/sfprojects/RV/web/view/showexp?Site=CO%3B%3BIN&Build=$REL&OSName=&Family=&Core=&Status=&UserName=ankitko&SuperSuite=NEW&TestSuite=&Flow=&Device=&TestcaseName=&ErrorStr=&CRNum=&Notes=&fromdate=&todate=&daterange=&RunAgain=RunAgain&formName=expform&formurl=showexp&table_data=&userId=hshah";
		     &suc_mail("Jobs are submitted for build $REL.\n", $REL, $result);

                   }
		    
	    }
 		
         }
	
   }

}


#---------------------------------------------------------------------------------------------------------------------------







open WKBLD, "$wkly_bld" or die $!;

 while (<WKBLD>){
 $REL = $_; chomp($REL); my $file = "ta-info.txt";
 &chek_rel($REL,$file);
 }


foreach $mjr (@mjr_rng){

    foreach $min (@min_rng){
	$REL = "$mjr\.$min\_$mth_no$dte_splt[2]";chomp($REL);
        #print "$REL\n";
        my $file = "tda-info.txt";
 	&chek_rel($REL,$file);
   }
}










