#!/usr/bin/perl

package ManagePerm;

use File::Find;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(GetFiles FindWw RemWwPerm);

sub GetFiles { 
   my @file_list; 
   my $dir = shift;
   find( 
	sub { 
		(-f ) or return; 
		push @file_list, $File::Find::name; return @file_list;
	}, $dir); 
}

sub FindWw { 					#FindWw Method will find wrold writable files

	my $flag = 0; 
	my $get_info = stat($file); 
	my $perm = $get_info->mode; 
	my $permission = $perm & 0777; 
	my $oct_perm_str = sprintf "%o", $permission; 
	my @other = split//, $oct_perm_str; 
	
	if ($other[2] == 7 or $other[2] == 2 or $other[2] == 3 or $other[2] == 6){ 
		print "$file permission is $oct_perm_str & is world writable\n"; 
		$flag = 1; 
	} 	
}

sub RemWwPerm { 				# RemWwPerm Method will Remove wrold writable permission for the files
   if ($flag == 1){ 
		$other[2] = $other[2] - 2; 
		my $mode = "0$other[0]".$other[1].$other[2] ; 
		print "We are Changing file permission to $mode from $oct_perm_str \n"; 
		chmod oct($mode), $file; 
	}
}

1;

