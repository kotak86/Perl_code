#!/usr/local/bin/perl

#=======================================================
#
#       Created by HEMANG SHAH, IPV, Xilinx,Inc.
#       Last Modified: August 23,2011
#
#=======================================================
#
#
### --- To create client file snippet for perforce --- ###

system("clear");
$DEBUG = 1;
$file = $ARGV[0];

open (client,"./$file");
  while (<client>)
  {
    $core = $_;
    chomp ($core);

    ($word1, $word2) = ($core =~ /(\w+)\/(\w+)/i);

    print "Core name is : $word1 , Core version is : $word2  \n" if $DEBUG;

		open (Write, ">>my_p4client");
		  print Write "\/\/IP3\/DEV\/hw\/$word1\/\* \/\/IP3_$ENV{USER}_vid_regressions\/DEV\/hw\/$word1\/\* \n";
		  print Write "\/\/IP3\/DEV\/hw\/$word1\/$word2\/... \/\/IP3_$ENV{USER}_vid_regressions\/DEV\/hw\/$word1\/$word2\/... \n";
	  close(Write);
  }
close(client);
