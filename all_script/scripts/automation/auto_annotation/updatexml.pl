#!/tools/xgs/perl/5.8.5/bin/perl
use strict;
#use warnings;

use XML::Simple;
use Data::Dumper;

my $script_dir = "/proj/ipco/users/hshah/ankit/scripts/automation";
my $xml_file = "$script_dir/auto_annotation/fa.xml";
my $REL = $ARGV[0]; chomp($REL);
my $ip = $ARGV[1]; chomp($ip);


print "The \$ARGV[0] is $ARGV[0]\n";
my $sub = "$script_dir/submission_info/$REL\_submitd\_$ip";

my $xml_dt = new XML::Simple;
my $data = $xml_dt->XMLin($xml_file);
my $crnt = $data->{"current_dataset"} -> {"build"};
print "Current Build is $crnt\n";

my $xml = XMLin(
    $xml_file,
    KeepRoot => 1,
    ForceArray => 1,
);


my $cbld = $xml->{buildComparison}->[0]->{current_dataset}->[0]->{build};  # gives the current build location
my $rbld = $xml->{buildComparison}->[0]->{ref_dataset}->[0]->{build}; # Gives the reference build location


my $REL = $ARGV[0]; chomp($REL);
my $ip = $ARGV[1]; chomp($ip);


#-------------------------------------------------------------------------------------------------
#                               Veriable Logic
#-------------------------------------------------------------------------------------------------


if(-e $sub){
	print "Regression runs for $REL, please update fa.xml\n";
	if ($crnt  ne $REL){
	$rbld = $cbld;
	$cbld = $REL;
	$xml->{buildComparison}->[0]->{current_dataset}->[0]->{build} = $cbld;
	$xml->{buildComparison}->[0]->{ref_dataset}->[0]->{build} = $rbld;
	

	XMLout(
	$xml,
    	KeepRoot => 1,
    	NoAttr => 1,
	NoEscape => 1,
    	OutputFile => $xml_file,);


	}
	else{
		print "fa.xml file do not need to update.\nReason: Release date is same as current date.";
	}


}

