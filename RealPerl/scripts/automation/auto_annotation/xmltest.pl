#!/tools/xgs/perl/5.8.5/bin/perl
use strict;
#use warnings;

use XML::Simple;
my $xml_file = "/proj/xtcRepo/ipv/automation/scripts/auto_annotation/fa.xml";

my $xml = XMLin($xml_file, KeepRoot => 1, ForceArray => 1,);
my $cbld = $xml->{buildComparison}->[0]->{current_dataset}->[0]->{build};  # gives current build
my $rbld = $xml->{buildComparison}->[0]->{current_dataset}->[0]->{build} ; # Gives reference build
my $dir_date = localtime();
my %mnth     =  (Jan =>"01", Feb =>"02", Mar =>"03", May =>"05", Apr =>"04", Jun=>"06",
                 Jul=>"07", Aug=>"08", Sep=>"09", Oct=>"10", Nov=>"11", Dec=>"12");
my $cntd = 0;
my $cntf = 0;
#my @mjr_rng = (14 .. 24);
my @mjr_rng = qw (14);
my @min_rng = qw (3);
#my @min_rng = (1..5);
my $min = 3;
my $mjr =14;
my $REL;
my $script_dir = "/proj/XCOtcRepo/ipv/automation/scripts/submission_info";


#-------------------------------------------------------------------------------------------------
#                               Veriable Logic
#-------------------------------------------------------------------------------------------------

# Split localtime in date, month day etc.

my @dte_splt = split /\s+/, $dir_date;          # 0->day, 1->Month, 2->date, 3->time, 4->year


# Make date in two digit if it less then 10.

if ($dte_splt[2] < 10){
 $dte_splt[2] = "0$dte_splt[2]";}

# map the corresponding # accroding to month.
my $mth_no   = $mnth{$dte_splt[1]};

print $REL = "$mjr\.$min\_$mth_no$dte_splt[2]"; 
chomp($REL);
print "\n";

#-------------------------------------------------------------------------------------------------
#                               Veriable Logic
#-------------------------------------------------------------------------------------------------


if(-e "$script_dir/$REL\_submitd_dsp"){
        
        print "Update the current build\n";
	$rbld = $cbld;
	$cbld = $REL;


	print "Now reference bld is $rbld\n";
	print "Now current bld is $cbld\n";

}













$xml->{buildComparison}->[0]->{current_dataset}->[0]->{build} = $cbld;
$xml->{buildComparison}->[0]->{ref_dataset}->[0]->{build} = $rbld;

XMLout(
    $xml,
    KeepRoot => 1,
    NoAttr => 1,
    OutputFile => $xml_file,
);
