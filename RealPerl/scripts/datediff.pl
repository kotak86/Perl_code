 #!/usr/bin/perl
    use strict;
    use warnings;
    use Date::Calc qw(Delta_Days);

    #  0    	1    	2     	3     	4    	5     	     6     7          8 
    (my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) = localtime(time);


print localtime(time); print "\n";

my @array = qw(sec min hour mday mon year wday yday isdst);


    my @tday = (localtime)[5,4,3]; print "The array \@tday is @tday\n";
    my @today = (localtime)[0,1,2,3,4,5,6,7,8]; 
	print "The array \@today is @today\n"; 
	my $i = 0; 
     foreach (@today){
	print "The $array[$i] is\t $_\n";
	$i++;
	}

    print $tday[0] += 1900; print "\n";
    $tday[1]++;print $tday[1];print "\n";

    my @birthday = (1986, 4, 3);

    my $days = Delta_Days(@birthday, @tday);

    print "I am $days days old\n";

    exit 0;
