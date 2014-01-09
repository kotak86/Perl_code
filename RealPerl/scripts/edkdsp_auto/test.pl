#!/tools/xgs/perl/5.8.5/bin/perl

#use warnings;
use strict;

my $a;




sub mult{

 my $ip =  $a*$b;print "the value of ip is $ip\n";


}

sub add {
  $a = $_[0]; $b = $_[1];
  my $pi = $a *4; print "The valuse of pi is $pi\n";
  &mult();  


}


&add(6,2);


tools/xint/prod/bin/buildComparison.pl  -c /proj/XCOtcRepo/ipv/automation/auto_annotation/fa.xml -a
