
use Getopt::Long;
use strict;
use warnings;
use Data::Dumper;

   my $verbose = '';	# option variable with default value (false)
   my $UsrID = 0;	# option variable with default value (false)
   my @dir =() ;
   
   
   
  GetOptions ('verbose' => \$verbose, 'uid:i' => \$UsrID, 'dir=s{1,}' =>\@dir);
  
  print "The value of \$verbose is " .$verbose ."\nThe value of \$UsrID is $UsrID \nThe value of \@dir is @dir \n";
 # print Dumper($UsrID);
 #print Dumper(@dir);
 
 foreach (@dir){
 
	print "$_\n";
 }

 print "no verbose \n", if !$verbose;