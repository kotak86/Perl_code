#!/tools/xgs/perl/5.8.5/bin/perl
#use warnings;
use strict;

my $dir_date = localtime();
my @dte_splt = split /\s+/, $dir_date;          # 0->day, 1->Month, 2->date, 3->time, 4->year
if ($dte_splt[2] < 10) {$dte_splt[2] = "0$dte_splt[2]";}
my %mnth     =  (Jan =>"01", Feb =>"02", Mar =>"03", May =>"05", Apr =>"04", Jun=>"06",
                 Jul=>"07", Aug=>"08", Sep=>"09", Oct=>"10", Nov=>"11", Dec=>"12");
my $mth_no   = $mnth{$dte_splt[1]}; # map the corresponding # accroding to month
my $cntd     = 0; my $cntf =0; my @mjr_rng = (14 .. 24); my @min_rng = (1..5); my $min; my $mjr;
my $dir_name ;
my $file = "tda-info.txt";
my $REL;
#------------------------------------------------------------------------------------------------

        sub suc_mail{
            my $msg = $_[0];
	    my $build = $_[1];
	    my $rv_link = $_[2];
            my $msgdf  = "Directory ".$dir_name." not found.\n";
	    my $msgf   = "Directory ".$dir_name. " are there but File ".$file." do not found.\n";
	    #my $msgs   = "Directory: ".$dir_name." and\nFile: ".$file."\nare ready to use. \n";
	    my $sign   = "\n\nThanks & Regards\nAnkit Kotak\nIP Verification Engineer \nXilinx Inc, San Jose\nDesk: +1 408 879 7704\nCell: +1 201 668 1920";
	    open (SENDMAIL,"|/usr/lib/sendmail -oi -t -odq")or die"Can't fork for sendmail: $!\n";
            print SENDMAIL "From:Ankit Kotak<ankit.kotak\@xilinx.com>\n";
            print SENDMAIL "To:<ankit.kotak\@xilinx.com>\n";
	    #print SENDMAIL "To:<hshah\@xilinx.com>\n";
            print SENDMAIL "Subject:Jobs are submitted for EDK IP for  ".$build. "\n"; print SENDMAIL "Hello Admin,\n\n";
            print SENDMAIL $msg;
 	    print SENDMAIL "$rv_link";
 	    print SENDMAIL $sign;
            close(SENDMAIL) or warn "sendmail didn't close nicely";
            0; }
#----------------------------------------------------------------------------------------------



foreach $mjr (@mjr_rng){

        foreach $min (@min_rng){
	my $dir_name = "$mjr\.$min\_$mth_no$dte_splt[2]";
#	my $df_chk = $dir_name."\_exist";
	my $df_chk = "job_submitted";
	unless (-e "/home/ankitko/scripts/EDK_Rohit/$df_chk"){
	opendir (DCHECK, "/proj/xbuilds/") or die $!;
	        while($_ = readdir(DCHECK)){
		    if($_ eq $dir_name){
			$cntd = $cntd+1;
			print "$dir_name found.\n";
			if (-e "/proj/xbuilds/$dir_name/$file") {
			  
			  print "$file also found for $dir_name build at $dte_splt[3].\n";
			  $REL = $dir_name;
			 

			  system("clear");
			  my $DEBUG='1';
			  my $dir = "/home/ankitko/scripts/EDK_Rohit"; # Change to your local path #
			  my $fil = "lsf_arg_edkip";

               
        		  open (FILE,"$dir/$fil");
        		  while (<FILE>){
             			my $line = $_;
             			chomp ($line);
             			print "$line\n" if $DEBUG;
             			my $run_lsf = `$dir/w_create_lsf_epd.pl lin $line $REL`;
        		  }
        		close (FILE);

                        my $lsf_loc = "/proj/ipco/users/hshah/ankit/lsf/ankitko_lsf/$REL";
			print "lsf files created at : /proj/ipco/users/hshah/ankit/lsf/ankitko_lsf/$REL\n";
			
			`cd $lsf_loc; ls -d FOCUS*lin > linfiles`;
			
			 open (LINFILE,"$lsf_loc/linfiles") or die $!;
				
        		  while (<LINFILE>){
             			my $linf = $_;
             			chomp ($linf);
             			print "$linf\n" if $DEBUG;
             			`bsub -q medium -P ip_ipv_regressions -R "rusage[mem=32000]" -R "select[type==X86_64 && os==lin]" < /proj/ipco/users/hshah/ankit/lsf/ankitko_lsf/$REL/$linf`;
				open DFE, ">$dir/$df_chk" or die $!;
                                print DFE "Directory & files are ready to use";
				
				

				
        		  }
			  	my $result = "http://xcorvprod/sfprojects/RV/web/view/showexp?Site=CO%3B%3BIN&Build=$dir_name&OSName=&Family=&Core=&Status=&UserName=ankitko&SuperSuite=NEW&TestSuite=&Flow=&Device=&TestcaseName=&ErrorStr=&CRNum=&Notes=&fromdate=&todate=&daterange=&RunAgain=RunAgain&formName=expform&formurl=showexp&table_data=&userId=hshah";


				
				&suc_mail("EDK IP Jobs are submitted for build $dir_name.\n", $dir_name, $result);

						



			}

		     }



        	}




	}
}
}



