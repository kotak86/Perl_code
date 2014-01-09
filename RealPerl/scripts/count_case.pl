#!usr/bin/perl
use strict;
use warnings;


system("clear");
print "\nEnter Location of the directory (e.g. /proj/xtcRepo/ipv/dspIP/ids_14.1_P.15xc.0.0/REGR/HEAD/dspIP) : ";
my $location = <>;
chomp($location);
my $count =0;
opendir (FLTRDIR, "$location") or die $!;
my @IP_dir = readdir(FLTRDIR);


	foreach(@IP_dir){

		next if $_ eq "." or $_ eq ".."; 
			#print "$location/$_/DEFAULT_FAMILY/";
			
			if (-d "$location/$_/DEFAULT_FAMILY/"){
			$count = $count+1; if ($count < 10){$count = "0$count";}
			opendir (TESTDIR, "$location/$_/DEFAULT_FAMILY/") or die "Hi not found";
			my @testdir =  readdir(TESTDIR); 
			my $test_cnt = $#testdir-1;
			if ($test_cnt < 10)
			{$test_cnt = "00$test_cnt";} 
			
			elsif($test_cnt < 100)
			{$test_cnt = "0$test_cnt";}
			print "$count :$test_cnt inside $_/DEFAULT_DIRECTORY/ \n";   
			}

	}

