#!/tools/xgs/perl/5.8.5/bin/perl

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Cwd;
use Cwd 'abs_path';
use File::Find;
use File::Copy;
use MIME::Lite;

use  List::Util qw/shuffle/;  # To select the cases randomly 

my $opt_Build;
my $core_list;
my $opt_testDir;
my @test_list;
my $core_list;
my $tc_path;
my $edk_build;
my $ise_build;
my $rand_run =100;
my $filter_family;
my $job_limit;
my $BVT =0;
my $FOCUS =0;
my $REGR =0;

system(clear);
$user = getpwuid($<);

$ISE_BUILD = '14.2';
$EDK_BUILD = 'EDK_O.82';


#$ise_build = "$ISE_BUILD"."_"."$EDK_BUILD";#M.70b.0_EDK_MS3.70b";
$ise_build = "14.2_0516";# Change build name here
#$opt_testDir = '/proj/xtcRepo/ipv/rohitg/2012.1/edk';
$opt_testDir = '/proj/xtcRepo/ipv/epdIP/14.2_0516';
$core_list = '/home/ankitko/scripts/EDK_Rohit/2012.1_list';
$results_root = '/proj/xresults/arizona/ankitko';
# $results_root = '/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL\_edkIP';

$job_limit = 100;
$debug_mode =0;
$edk_path_type = "xfndry";
#$testsuit = "DSV_EPD_NEW_SIM";

@tag = split(/_/,$ise_build);

$testsuit = "IP_2012.1_12"."$tag[1]"; #IP_2012.1_yymmdd





&GetOptions(    'h|help'        => \$opt_Help,      
                'build=s'       => \$opt_Build,     
                'tag=s'         => \$opt_Tag,     
                'modelsim|m=s'  => \$opt_ModelSim,     
                'p|priority=i'  => \$opt_Priority,     
                'r|run=s'       => \$opt_Run,     
                'dir|td=s'      => \$opt_testDir,     
                'c=s'      	=> \$core_list,
                'ISE|ise=s'	=> \$ISE_BUILD,
                'EDK|edk=s'	=> \$EDK_BUILD,
                'rand|random=i' => \$rand_run,
                'f|family=s'    => \$filter_family,
                'job_limit=i'   => \$job_limit,
                'BVT|bvt=i'     => \$BVT,
                'FOCUS|focus=i' => \$FOCUS,
                'REGR|regr=i'   => \$REGR,
                'testsuit=s'    => \$testsuit
           ) ;

    	

if($BVT =~ 1) {
	print "(INFO ) : Running BVT tests \n";
	$opt_testDir = "$opt_testDir"."/BVT/_TCASE/edkIP";
}
elsif ($FOCUS =~ 1) {
	$opt_testDir = "$opt_testDir"."/FOCUS/_TCASE/edkIP";# <change path here>
}
elsif ($REGR =~ 1) {
	$opt_testDir = "$opt_testDir"."/REGR/_TCASE/edkIP";
}





&print_opts();

&Clean();
open(RD_CORELIST,"<$core_list") or die "Can't open file $core_list for reading ";

	  @cores = <RD_CORELIST>;
	  close RD_CORELIST;
	
 foreach $core(@cores) {
	chomp($core);
	$tc_path = "$opt_testDir\/$core";
	#$lsf_wrapper_file   = "lsf_wrapper_lin_no_netlist".".csh";
	$lsf_wrapper_file   = "lsf_wrapper_lin".".csh";
	&lsf_wrapper_gen();
    	&lsf_job_gen(); 

 	print " (INFO) Testcases submitted on LSF\t $num_of_jobs\n";
}
system('chmod 777 *.csh');

 print"\t -- LSF COMMANDS --\n";
 foreach $core(@cores) {
 	chomp($core);
	$lsf_command = "bsub -q medium  <"." $core"."_lsf_array_file.lsf";
	print "$lsf_command \n";
 }

 &mail;
 system 'rm -f *.lst';


#-------------------------------------------------------------------------------------------------------------------------------------------------------------#
sub lsf_wrapper_gen() {

open(LSF_WRAP,">./$lsf_wrapper_file") || die("Could Not Open $lsf_wrapper_file file");
my $cmd_string="#!/bin/csh -f \n"
                   ."  setenv HOME /home/$userid \n"
                   ."  setenv SHELL /usr/bin/csh \n"  
                   ."  setenv LSB_DEFAULTQUEUE medium \n" ; 
  
  my $cmd_string = "$cmd_string \n"
  ." if (`uname` == SunOS) then  
      # needed to get mti simulations working under sol 9 
      limit descriptors 1024 
 else if (`uname` == Linux) then 
 else 
     echo 'Unsupported OS';  
     exit 1; 
 endif \n \n";


print " (INFO) IDS BUILD\n";
$cmd_string = "$cmd_string"."/proj/xtools/svauto2/flows/xlnxIP/prod/xlnxIP.pl -tc \$argv[*] -SIMULATOR modelsim -CADMAN_xilinx_pathtype tda -CADMAN_xilinx $ise_build -LSF_OPTION \' -P ip_ipv_regressions -Lp ipreg_opt -R \"rusage[swemsimhdlsim=2:swesvverification=2:swemsimhdlmix=2]\" -R \"rusage[mem=3000]\" -R type=X86_64 -eo /proj/xtools/testRunner/logs/$user/\%J_\%I_xlnxIP.err -oo /proj/xtools/testRunner/logs/$user/\%J_\%I_xlnxIP.txt\'  -RESULTSROOT $results_root -CADMAN_modelsim 10.1a -RODIN_FLOW 1 -PLATGEN_OPTION  \'-intstyle vivado\' -FAMILY virtex7 -SUPER_TESTSUITE EDK -TESTSUITE $testsuit " ;

  print LSF_WRAP "$cmd_string \n "; 
  close LSF_WRAP;
}


#*******************************************************
# 	Creating lsf file (array of testcases)
#******************************************************
sub lsf_job_gen() {
 @find_rep_files = (); 	
 &FindtestDirectory("$tc_path");
 $num_of_jobs = 20;

 open (OUTFILE, ">"."$core"."_lsf_array_file.lsf") || die "unable to write"." $core"."_lsf_array_file.lsf" ;
 $line = "#!/bin/csh \n#BSUB -P ip_ipv_regressions -Lp ips_ipv_grp -R \"select[type==X86_64 && os==lin]\" -R \"rusage[mem=3000]\" -J $core"."_random"."\[1-$num_of_jobs\]\%$job_limit\n#BSUB -eo /proj/xtools/testRunner/logs/$user/\%J_\%I_xlnxIP.err\n#BSUB -oo /proj/xtools/testRunner/logs/$user/\%J_\%I_xlnxIP.txt\nset a = (\\\n";

   print OUTFILE ($line);

 foreach my $input_file (@test_list) {
  if ($input_file =~ /\/input/) {
  print OUTFILE "$input_file \\\n";
  }
 }
 print OUTFILE ');';
 print OUTFILE "\n";
 print OUTFILE "./$lsf_wrapper_file \$a[\$LSB_JOBINDEX]";
}

sub Clean () {

#system('rm -f *.lsf');
#system('rm -f *.csh');
system('rm -f *.lst');
system("rm -f /home/$user/lsf_logs/*");
print" (INFO) Deleting temp files \n";
}


#*******************************************************
# 	Filter testcases
#******************************************************

sub FindtestDirectory () {
	 @test_list = ();
	 @sample = ();
	 print " (INFO) Searching in $tc_path \n";
	 if (!(-d $tc_path)) {
	 print " (ERROR) $tc_path does not exixt\n";
	 }
	 else {
#	 print("PRINT TC PATH :$tc_path\n");
     &find(\&testDirectory, $tc_path);
     system ("ls $tc_path > ./list_of_test_$core.lst") ;
     open(LIST,"./list_of_test_$core.lst") || die("Could Not Open ./list_of_test_$core.lst  file"); 
 
	 my $last = $find_rep_files[0];
	 my @lines_of_lists = <LIST>;
	 @test_list = ();
#          print " LAST : $last\n";
	 foreach my $test (@find_rep_files) {
#          print " TEST : $test\n";
	 if (( !($test eq  $last)) &&($test =~ /\/input/)) {
        #  print "FOUND TEST : $test\n";
 	  if(($test =~ $filter_family)) {	# Family filter
           $last = $test;
          push (@test_list,$test)
          }
	 } 
 	 } 

    $find_rep_files_size = @test_list;

#   Random selection of testcases    
    if($BVT =~ 1) {
     $samples = 2;
     @sample = (shuffle(@test_list))[0..$samples-1];
    $temp_size = @sample;
    @test_list = ();
    @test_list = @sample;	
    print " (INFO) Number of BVT testcases\t\t $samples\n (INFO) Total number of testcases\t $find_rep_files_size\n";   
    }
    elsif($rand_run != 100) { 
    $samples = ($rand_run*$find_rep_files_size)/100;
    $samples = int($samples);
    @sample = (shuffle(@test_list))[0..$samples-1];
    $temp_size = @sample;
#    print "SIZE IS : $temp_size\n";
    @test_list = ();
    @test_list = @sample;	
    print " (INFO) Percentage of testcases\t\t $rand_run%\n (INFO) Total number of testcases\t $find_rep_files_size\n (INFO) Testcases to be Submitted\t $samples \n";  

    }
 }}

#*******************************************************
#	Find testcases
#******************************************************
sub testDirectory () {
    my $Dir  = $File::Find::dir;
#    print ("FOUND TC PATH : $tc_path\n");
#    print ("FOUND TESTCASE : $Dir\n");
    if($Dir =~ /DEFAULT_FAMILY/i || $Dir =~ /virtex\dl/i || $Dir =~ /virtex\d/i || $Dir =~ /spartan3a|spartan|qspartan6|qvirtex6/i || $Dir =~ /spartan3a/i || $Dir =~ /kintex7/i || $Dir =~ /artix/i || $Dir =~ /artix\dl/i || $Dir =~ /aartix7/i ||$Dir =~ /zynq/i ) {
#    if($Dir =~ /virtex7l/i || $Dir =~ /virtex7/i || /kintex7l/i || $Dir =~ /kintex7/i || $Dir =~ /zynq/i ) {
#    print ("FOUND TESTCASE : $Dir\n");
    push (@find_rep_files,$Dir);
    }
    }

#*******************************************************
#	Send Email
#******************************************************

sub mail() {
    return (0) if ( defined( $config{silent} ) );

    my ( $sub, $body, $cc_id ) = @_;

    $mail_id = "$user";

    $cc_id = '' if ( not defined($cc_id) );

    if ( $mail_id =~ /airtel|bsnl|idea/i ) {
        `/bin/echo 'STATUS'|/bin/mail -s '$sub' '$mail_id $cc_id'`;
    }
    else {
        $results_link_1 =
                       "http://xirdub.xir.xilinx.com:7779/ResultsViewer/RequestHandler?action=&tableId=&activityID=Expanded&username=$user&site=IN&build=$ise_build&osname=All&users=$user&flows=EDKIP&family=All&status=All&testsuite=$testsuit&supersuite=All&error=&tcname=&cr=All&fromdate=&todate=&daterange=&sim=All&core=All";
        $results_link_2 =
                       "http://xcorvprod/sfprojects/RV/web/view/showexp?Site=IN%3B%3BCO&Build=$ise_build&OSName=&Family=&Status=&UserName=$user&SuperSuite=&TestSuite=$testsuit%3B%3BDSV_EPD_NEW_SIM&TestcaseName=&ErrorStr=&CRNum=&Notes=&fromdate=&todate=&daterange=&RunAgain=RunAgain&formName=expform&formurl=showexp&table_data=&userId=$user";
        my $msg = MIME::Lite->new(
            Subject => "Test for Build $ise_build submitted",

            From => $user,
            To   => $mail_id,
            cc   => $cc_id,
            Type => 'text/html',
            Data => "
  <div align=\"center\"><FONT color=\"\#ffffff\" size=\"+1\"><marquee behavior=\"alternate\" direction=\"right\" bgcolor=\"blue\" vspace=\"0\">This is an automatically generated e-mail!</MARQUEE></FONT></DIV> 
  <br>ISE build : \t\t $ise_build <br>
  <br>EDK build : \t\t $edk_build <br>
  <font color=\"red\" size=\"+1\">
  <b>
  <pre>$body</pre> <br><br></b>
  </font>
  <H4>
   <a href=\\\\xhd-filer3\\$user\\lsf_logs>Script Log</a><br><br>
  <a href=$results_link_1>Results viewer</a><br><br>
  <a href=$results_link_2>Results viewer_new</a><br><br>
  </H4>"
  );
        $msg->send();
    }
    print "An e-mail has been sen to $mail_id \n";
}

#*******************************************************
#      Test options
#******************************************************
sub print_opts() {
&title();

print"\n---------------- TEST OPTIONS ---------------------
 EDK BUILD\t\t$edk_build
 ISE BUILD\t\t$ise_build
 TEST DIR\t\t$opt_testDir
 CORE LIST\t\t$core_list
 TESTSUIT\t\t$testsuit
 FAMILY FILTER\t\t$filter_family
 TEST PERCENTAGE\t$rand_run
 JOB LIMIT\t\t$job_limit
 BVT      \t\t$BVT
-------------------------------------------------------\n\n";
}

#*******************************************************
#      Title
#******************************************************
sub title {
    print color ("yellow");
    if ( !( defined $ENV{SILENT} ) ) {
        print "***********************************************\n";
        print "\/ /\\/  \n";
        print "\\ \\     Xilinx Inc\n";
        print "\/ \/     EDK Test Submission Script\n";
        print "\\\_\\/\\   All Rights Reserved\n";
        print "**********************************************\n";
    }
    print color ("reset");
}

