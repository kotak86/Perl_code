#!/usr/local/bin/perl
use warnings;
use strict;
#sub resub_case{
my $REL      = $ARGV[0];
my $REL_dir  = $REL."_rodin";
my $dir      = "/proj/ipco/users/hshah/ankit/lsf/ankitko_lsf/$REL_dir";
my $dir_RV   = "/proj/ipco/users/hshah/ankit/lsf/ankitko_lsf";
my $or_case  = "$dir/$ARGV[1]";  
my $ex_case  = "$dir_RV/$ARGV[2]"; 
my $wrt_file = "resub_".$ARGV[1];
my $etcase;
my @or_case; my @et_case;
my $i; my $j;

my $rpl_cnt;# gives the new count of resubmit case


open ORG, $or_case or die $!;
open (EXC, $ex_case) or die $!;

open RESUB, "> $dir/$wrt_file" or die $!;
@or_case = <ORG>;
my @re_test;
while (<EXC>)
{	$etcase = $_;
	# Remove if string has any word charecter in the begining
	# followed by space or sting founds one or more space at the end of the string. 
	$etcase =~ s/(^\w+\s+)|(\s+$)//g; $etcase = "/$etcase/";
	push(@et_case, $etcase); 
	}
#print RESUB $#et_case+1;print RESUB "\n";print RESUB $#or_case-7;print RESUB "\n";
for($i=0; $i <= $#et_case; $i++){
	for($j=5; $j <= $#or_case-1; $j++){
	       	if(($or_case[$j] =~ m|$et_case[$i]|)){
		
		    #  print "Or case $j $or_case[$j] not match with $i $et_case[$i]";		
			
		     push(@re_test, $or_case[$j]);			

		}
		

        }
}	
$rpl_cnt = $#et_case+1;

#for(@et_case) {print RESUB $_ ."\n";}  

print RESUB "#!/bin/csh\n";
foreach(@or_case){
	
		if($_=~ m@^\#BSUB@ |$_ =~ m @^set@){
			$_ =~ s/1-\d+/1-$rpl_cnt/;
			print  RESUB $_;
		}
	
} 



foreach(@re_test){
  print  RESUB $_;}
 
 print RESUB ");\n";
 print RESUB "$or_case[$#or_case]";
								  




