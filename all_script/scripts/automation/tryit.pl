#!usr/bin/perl
use strict;
use warnings;
my $file = "/proj/ipco/users/hshah/ankit/scripts/automation/";

open HAN, "$file/2012.2_dspIP" or die $!;
while(<HAN>){
	
if ($_ =~ /REGR/){
`/usr/bin/perl -p -i -e "s/REGR/FOCUS/" $file/2012.2_dspIP`;

}	

elsif($_ =~ /FOCS/){

`/usr/bin/perl -p -i -e "s/FOCS/FOCUS/" $file/2012.2_dspIP`;

}
}
