#!usr/bin/perl
use warnings;
use strict; 


print "Please enter the name of the file that contains list of core with it's version: "; 
my $file = <>;
chomp($file);

open CORVRSN, "$file" or die $!;
open CR_CRVRSN, ">>co_vrsn_ISE" or die $!;

while ($_ = <CORVRSN>){
  my @core = split /_v/, $_;
  
  my $core_covrsn = "$core[0]/$_";
  
 
  print CR_CRVRSN $core_covrsn;


}