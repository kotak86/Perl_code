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
#my $REGR =0;

system(clear);

if (! defined $ENV{XILINX} ){

print "set XILINX to cadman add -t xilinx -v current REL -p unified_install";
print "You can find latest version from : cadman listtools -t xilinx -p unified_install";
exit;
}

$user = getpwuid($<);
$USER_ = 'rohitg';

&GetOptions(

                'r=s'      	=> \$testDir,     
                'c=s'      	=> \$core_list,
                's=s'    	=> \$sandbox
           ) ;


$testDir = "14.3_0718";

$core_list = '/proj/ipco/users/hshah/ankit/scripts/EDK_Rohit/2012.2';

$sandbox = "IP3_ankitko_edkcore_regressions";

$TC_PATH = '/proj/XCOtcRepo/ipv/epdIP/'."$testDir";
print "$TC_PATH----";
$SANDBOX_PATH = '/proj/ipco/users/hshah/ankit/Perforce/'."$sandbox".'/DEV/hw';


system ("mkdir $TC_PATH/BVT");
system ("mkdir $TC_PATH/FOCUS");
#system ("mkdir $TC_PATH/REGR");


open(RD_CORELIST,"<$core_list") or die "Can't open file $core_list for reading ";

	  @cores = <RD_CORELIST>;
	  close RD_CORELIST;
	
 foreach $core(@cores) {
	chomp($core);
	@temp = split(/_v\d/,$core);
	$tpr_path = "$SANDBOX_PATH/"."$temp[0]"."/$core";
	print "$tpr_path\/verification\n ";
	if(-d "$tpr_path\/verification") {
	if (-e "$tpr_path/verification/automation/run_params.do" ) {
	print "(INFO) - Found run_params.do for core $core \n";
	chdir("$tpr_path/verification/automation");
	system("rm -f $tpr_path\/verification\/automation\/parameters.dat ");
	system ("$tpr_path\/verification\/automation\/run_params.do");
	}
	system("/proj/xtools/svauto2/bin/gentests/gentests.pl -d $TC_PATH/BVT $tpr_path\/verification\/automation/$core"."_bvt".".tpr");
	system("/proj/xtools/svauto2/bin/gentests/gentests.pl -d $TC_PATH/FOCUS $tpr_path\/verification\/automation/$core"."_focused".".tpr");
#	system("/proj/xtools/svauto2/bin/gentests/gentests.pl -d $TC_PATH/REGR $tpr_path\/verification\/automation/$core".".tpr");
	}
	elsif (-d "$tpr_path\/svg") {
	system("/proj/xtools/svauto2/bin/gentests/gentests.pl -d $TC_PATH/BVT $tpr_path\/svg\/$core"."_bvt".".tpr");
	system("/proj/xtools/svauto2/bin/gentests/gentests.pl -d $TC_PATH/FOCUS $tpr_path\/svg\/$core"."_focused".".tpr");
#	system("/proj/xtools/svauto2/bin/gentests/gentests.pl -d $TC_PATH/REGR $tpr_path\/svg\/$core".".tpr");
	}

}

	print "Copying files from EDKIPtest to edkIP -\n";



system ("cp -rf $TC_PATH/BVT/_TCASE/EDKIPtest/* $TC_PATH/BVT/_TCASE/edkIP/. ");
system ("cp -rf $TC_PATH/FOCUS/_TCASE/EDKIPtest/* $TC_PATH/FOCUS/_TCASE/edkIP/. ");
#system ("cp -rf $TC_PATH/REGR/_TCASE/EDKIPtest/* $TC_PATH/REGR/_TCASE/edkIP/. ");
