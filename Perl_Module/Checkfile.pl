#!/usr/bin/perl 
use strict; 
use warnings; 
use MyModule; 
use Getopt::Long;

my $verbose = '';	# option variable with default value (false)
my @UsrID = ();	# option variable with default value (false)

my @get_dir = (); 
my @file_list; 
my @all_files;
my $get_files;
my $uid = '';
my $match_uid = '';
my $test = '';
my $task = '';
my $file = '';
GetOptions 
	('verbose' 		=> \$verbose, 
	 'uid:i{1,}' 	=> \@UsrID, 
	 'dir=s{1,}' 	=> \@get_dir
	) or Usage(), die ($!);
	
Usage(), if (!$verbose and !$uid and !@get_dir);

#print "FILENAME"." " x(35-length("FILENAME"))."CURRENT FILE PERMISSION\tFILE PERMISSION CHANGETO\t USRID \n", if ($verbose & @UsrID);
#print "FILENAME"." " x(35-length("FILENAME"))."CURRENT FILE PERMISSION\tFILE PERMISSION CHANGETO\n", if ($verbose & !@UsrID);		
		
if (@get_dir) {
    foreach $get_files (@get_dir) { 

		if($get_files and (-d $get_files)){
			@file_list = GetFiles($get_files); 
			push (@all_files, @file_list);
		}
	
		elsif($get_files and (-f $get_files)){
			@file_list = $get_files;
			push (@all_files, @file_list);
		}
	
		else {
			print "The dir/file name, \"$get_files\" not found.\nPlease Check the file or dir name.\n";
		}
	} 
}


	foreach $file (@all_files){ 
			
		if (@UsrID){
			foreach $uid(@UsrID){
				$match_uid = CheckUid($file, $uid);	
				$test = FindWw($file) , if $match_uid;
				$task = RemWwPerm($file, $verbose, $uid), if $test; last;
			
			}
		}	
		else{
			$test = FindWw($file);
			$task = RemWwPerm($file, $verbose), if $test;
		} 	
	}
	 
 
