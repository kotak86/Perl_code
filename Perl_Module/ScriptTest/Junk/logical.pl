use warnings;
use strict;


my $ankit = 4;
my $kotak = 3;

my $ans = $ankit & $kotak;
print "\$ans is $ans\n";
$ans = $kotak & $ankit;

print "\$ans is $ans\n";

my $answer = $ankit && $kotak;

print "\$answer is $ans\n";
 $answer = $kotak && $ankit;

print "\$answer is $ans\n";
1000000110110110
0001111001100001
---------------------
0000000000100000