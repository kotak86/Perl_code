#!/usr/bin/perl

use strict;
use warnings;
use File::stat;

sub FindWw { 					

	my $flag = 0; 
	my $get_info;
	my $perm;
	my $Pmission;
	my @Getbit;
	my @check_uid;
	my $f_uid;
	
	my $file = shift;
	
	
	$get_info = stat($file); 
	$perm = $get_info->mode;
	$f_uid = $get_info->uid; 	
	$Pmission = $perm & 0777; 
	my $OCT_Pmission = sprintf "%o", $Pmission; 
	@Getbit = split//, $OCT_Pmission; 
	
	if ($Getbit[2] == 7 or $Getbit[2] == 2 or $Getbit[2] == 3 or $Getbit[2] == 6){ 
		print $file," " x(50-length($file))."\t\t$OCT_Pmission \t$f_uid\n";
		return $flag = 1; 
		
	} 	
}

my $check = $ARGV[0];

FindWw($check);