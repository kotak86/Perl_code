#!/usr/bin/perl
use warnings;
use strict;


#my $a = { company => 'GSG', jobs => [ 'developer', 'ba', 'admin' ] }; 
#my $a = { company => 'GSG', jobs => [developer => {Ankit => 'Kotak', edu => 'MSEE', age => '27'}, 'ba', 'admin' ], GSG => 'Kotak' }; 

#answer the questions below (one answer per question): 1. What is the value of $a->{GSG} 
#print  $a->{company} ; print ("\n");
#print  $a->{jobs}->[2] ; print ("\n");
#print  $a->{jobs}[2] ; print ("\n");




#Given $a = { company => 'GSG' }; What is the output of a. $a->{company}, b. $a->{GSG}, and c. scalar(keys %$a)? 
#print 'Given $a = { company => 'GSG' }; What is the output of a. $a->{company}, b. $a->{GSG}, and c. scalar(keys %$a)?'; 
my $a = { company => 'GSG' , tech => "Perl" }; 

print '$a->{company} = '. $a->{company} . "\n"; 
print  $a->{GSG} ;print "\n"; 
print '$a->{tech} ='. $a->{tech} . "\n"; 
print 'scalar(keys %$a) = '. scalar (keys %$a). "\n";
