#!/usr/bin/perl

package MyModule;
	use strict;
	use warnings;
	use File::stat;
	require Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw(GetFiles FindWw RemWwPerm CheckUid Display_msg Usage );
	my $Pmission	 = undef;
	my $OCT_Pmission = undef; 
	my $file		 = undef;
	my $f_uid 		 = undef;
	my @file_list	 = ();
	my $verbose		 = 0;
	my $User_ID	     = undef;
	my $fmode	     = undef;
	my $header       = 0;
	my $status	     = 0;

sub GetFiles{
	
	my $dir;
	my @files;
	my $Isdir;
	my $Checkfile;
	
	$dir = shift;
	$dir = $1 if($dir=~/(.*)\/$/);
	@files = glob("$dir/*");
				
	foreach $Checkfile (@files){
		$Isdir = 0;
		$Isdir = 1 if -d $Checkfile;
		$Isdir	? (GetFiles($Checkfile)) : (push (@file_list, $Checkfile)); 		
	}
	
	return (@file_list);
}

sub FindWw { 					

	my $flag = 0; 
	my @Getbit;

	$file = shift;	
	$Pmission 	  = stat($file)->mode & 07777; 	
	$OCT_Pmission = sprintf "%o", $Pmission; 
	@Getbit = split//, $OCT_Pmission; 
	
	if ($Getbit[2] == 7 or $Getbit[2] == 2 or $Getbit[2] == 3 or $Getbit[2] == 6){ 
		return $flag = 1; 
	} 	
}

sub RemWwPerm { 				
    
	$file 	 = shift;
	$verbose = shift;
	$User_ID = shift;
	
	$Pmission 	  = stat($file)->mode & 07777; 
	$OCT_Pmission = sprintf "%o", $Pmission;
	$f_uid        = stat($file)->uid;
	$fmode        = $OCT_Pmission - 2;	
	Display_msg($User_ID);	  
	chmod oct($fmode) , $file; 	
}

sub CheckUid { 					
	
	$file 	  = shift; 
	$User_ID  = shift;
	$f_uid    = stat($file)->uid;
				
	return $status = 1, if ($f_uid == $User_ID);	
}

sub Display_msg{

	#$User_ID = shift; 
	
	if (($header == 0) && ($verbose == 1)){
	
		print "FILENAME", " " x(35-length("FILENAME")), 
			  "CURRENT FILE PERMISSION\t",
			  "FILE PERMISSION CHANGETO"; 
			  ($User_ID) ? print "\t USER ID\n" : print "\n";      
			  $header = 1;
	}
	
	if ($verbose == 1){
		print $file," " x(40-length($file)), 
		      $OCT_Pmission, " " x(35 -length($OCT_Pmission)), 
		      $fmode        , " " x(22-length($fmode)) ;
			 ($User_ID) ? print "$f_uid \n" : print "\n";
			  
			
	}	
}

sub Usage {

print<<EOF;

$0 script is use to locate the world writable permission from the given diretorie(s)/file(s) and 
remove the world writable permission without altering user or group permission.
Search & permission change can also possible for specific UID, passed as an command-line argument.

$0 uses MyModule.pm developed by Ankit Kotak
Please see below usage for detail reference.     

USAGE:
Script can take three options.

Options:

	--verbose : Optional. Print All the file for which world writable permission 
		    has been removed.
			
	--dir	  : Can specifiy any number of diretories & files followd by space
		    E.g. $0 --dir Dir1 Dir2 file1 file 2 
			
	--uid	  : To Restrict the change for specific user id(s), supply file uid(s) followed by space
		    E.g. $0 --dir Dir1 file1 Dir2 --uid UserID_1  UserID_2  UserID_3
				
	Example:
	
	perl $0 --verbose --dir Dir1 Dir2 file1 --uid UserID_1
	perl $0 --dir Dir1 Dir2 file1 --uid UserID_1 UserID_2 --verbose

EOF

}

1;



