#!/tools/xgs/perl/5.8.5/bin/perl

use warnings;
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
my $file = "tda-info.txt";
my $wkly_bld = "/proj/XCOtcRepo/ipv/automation/build.txt";
my $crt_file = "$REL\_submited";
my $file_exist = "/home/ankitko/scripts/auto_regr_dspip/$crt_file";
my $script_dir = "/home/ankitko/scripts/auto_regr_dspip"; # Change to your local path #
my $dsparg_list = "lsfarg_vivado_tstatic";
my $edkarg_list = "edkip_lsf_arg";
my $crtlsf_dsp = "w_create_lsf_rodin_dspip.pl";
my $crtlsf_edk = "w_create_lsf_epd.pl";

my $lsf_loc = "/proj/ipco/users/hshah/ankit/lsf/ankitko_lsf";
my $wkly_bld = "/proj/XCOtcRepo/ipv/automation/build.txt"; 


