#!/usr/bin/perl

#my @a = ('3','1','2','4','44');
my @a = (3,1,2,4,44);
my @b = (23,44,1,4);
#my @b = ('23','44','1','4');

my @res;
foreach my $tmp1 (@a)
{
    foreach my $tmp2 (@b)
    {
        push @res, $tmp1 if ($tmp1 == $tmp2);
    }

}

print "Common values @res\n";
