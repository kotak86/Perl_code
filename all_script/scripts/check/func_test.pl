#!/tools/xgs/perl/5.8.5/bin/perl
use strict;
#use warnings;
use File::stat;
#use Time::localtime;
use Date::Calc qw(Delta_Days);
use POSIX ();


sub diff_check {
my $file_sj = "xsj_dirfiles.lst";
my $file_rmt = shift;
my $rmt_name = uc($file_rmt); 
my $rmt = substr($rmt_name, 1, 2); 
my $rmtrpt = $rmt."_diff.rpt";
my $err_rpt = "\n\nFor detail error report, please read file ".$rmtrpt." at /home/ankitko/Desktop/check/.\n\nThanks\nAnkit Kotak\n";
my $cnt =0;


open "handle", $file_sj or die $!;	
open "R_HAND", $file_rmt or die $!;
open RPT, ">$rmtrpt" or die $!;
my @sj_list  = <handle>;		
my @rmt_list  = <R_HAND>;
my $rmtcnt = $#rmt_list+1;		
my $sjcnt = $#sj_list+1;			
my @cmp_sj; 
my @disp_sj;
my @cmp_rmt; 
my @disp_rmt;
my @extra_dirfile;
my $takeele;
	
	if ($sjcnt < $rmtcnt){

		print RPT "The total # of file & Directory inside the IR Servers are more than the XSJ Server";
		exit	
	}
			
			

	for (my $i=0; $i<=$rmtcnt; $i++){	
		my $line_rmt = $rmt_list[$i];

		my @di_info = split /\s+/, $line_rmt;
		
		my $fname  = $di_info[0]." " x (30-length($di_info[0])); 
		my $prmisn = $di_info[1]. "\t";
		my $size   = $di_info[7]."\t\t";                    	 
		my $day    = $di_info[2]." ";
		my $mnth   = $di_info[3]." ";		     	   	 
		my $date   = $di_info[4]."\t";
		my $year   = $di_info[6]."\t";		       	 	 
		my $atime  = $di_info[5]." ";
	
		my $displ_rmt = ($fname . $prmisn. $size. $day. $mnth. $date. $year.$atime);
		my $cmp_rmf =  ($fname. $prmisn. $size);

		push(@cmp_rmt, $cmp_rmf); 
		push(@disp_rmt, $displ_rmt); 

	}

	

	for (my $i=0; $i<=$sjcnt; $i++){
		
		my $line_sj = $sj_list[$i];
		my @di_info = split /\s+/, $line_sj;
		my $fname  = $di_info[0]." " x (30-length($di_info[0])); 	
		my $prmisn = $di_info[1]. "\t";
		my $size   = $di_info[7]."\t\t";                    	 
		my $day    = $di_info[2]." ";
		my $mnth   = $di_info[3]." ";		     	   	
		my $date   = $di_info[4]."\t";
		my $year   = $di_info[6]."\t";		       	 	 
		my $atime  = $di_info[5]." ";
	
		my $displ_sj = ($fname . $prmisn. $size. $day. $mnth. $date. $year.$atime);
		my $cmp_sjf =  ($fname. $prmisn. $size);

		push (@cmp_sj, $cmp_sjf); 
		push (@disp_sj, $displ_sj); 

	}	

	print RPT "\n\nThis error report is generated on ". localtime(time) ." from San Jose.\n\n";
	for (my $k=0; $k<=$sjcnt+2; $k++){
		
	   if($cmp_rmt[$k] ne $cmp_sj[$k]){
		$cnt = $cnt+1;
		print RPT "\n";
		print RPT "*" x (96-length);
		print RPT "\n";
		print RPT "Below file of ".$rmt. " server does not match with SJ Server";
		print RPT "\n".$rmt ." Server: ".$disp_rmt[$k]."\nSJ Server: ".$disp_sj[$k]."\n";
		print RPT "*" x (96-length);
		print RPT "\n\n";
			

		}

	    else {

			#print "Matched. \n";
		}


	}
		
	if ($cnt != 0){
		print RPT $cnt . " file(s) of ".$rmt." server do not matched with SJ server. \n";

		close RPT;


	 open (SENDMAIL, "|/usr/lib/sendmail -oi -t -odq") or die "Can't fork for sendmail: $!\n";
    	 print SENDMAIL "From:Ankit Kotak<ankitko\@xilinx.com> \n";
    	 print SENDMAIL "To:<ankit.kotak\@xilinx.com> <hemang.shah\@xilinx.com>\n";
    	 print SENDMAIL "Subject:".$rmt . " Server Mismatch Notification\n";
   	 print SENDMAIL "Hello ".$rmt. " Admin,\n\n";
    	 print SENDMAIL $cnt. " file(s) of ".$rmt." server do not matched with SJ server.";
	 print SENDMAIL $err_rpt;
    
    	 close(SENDMAIL) or warn "sendmail didn't close nicely";
	 0;

	}

}


&diff_check("xhd_dirfiles.lst");
&diff_check("xco_dirfiles.lst");
&diff_check("xdc_dirfiles.lst");
&diff_check("xap_dirfiles.lst");
