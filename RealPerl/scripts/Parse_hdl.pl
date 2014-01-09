#!/usr/bin/perl

use warnings;
use strict;

my $parse_from = "/build/xfndry/HEAD/env/Databases/ip/hw";
my $file = "/proj/ipco/users/hshah/ankit/scripts";
open INFO,">>$file/0803_list" or die $!;
open TNFO,">>$file/0804_list" or die $!;
open CORE,">>$file/core_list" or die $!;
open PATH,">>$file/path_list" or die $!;

chdir($parse_from);

opendir(P_HDL, $parse_from)or die "Could not open $!";

while (my $ip = readdir(P_HDL)){

	next if $ip eq "." or $ip eq ".."; 	
	if(-d $ip){
		print TNFO "Directory is : $ip\n";
		opendir (C_HDL, "$parse_from/$ip") or die $!;
		chdir($ip);
		while (my $ip_vrsn = readdir(C_HDL)){
			next if $ip_vrsn eq "." or $ip_vrsn eq "..";
			if(-d $ip_vrsn){
				print TNFO "\t\t$ip_vrsn\n";
				
				if(-e "$parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.vhd"){
					print TNFO "Exits: $parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.vhd\n";
					print PATH "$parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.vhd\n";

				}
				
				
				elsif(-e "$parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.v"){
                                        print TNFO "Exits: $parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.v\n";
                                        print PATH "$parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.v\n";

                                }


                                elsif(-e "$parse_from/$ip/$ip_vrsn/hdl/src/vhdl/$ip_vrsn\.vhd"){
                                        print TNFO "Exits: $parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.vhd\n";
                                        print PATH "$parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.vhd\n";

                                }

                                elsif(-e "$parse_from/$ip/$ip_vrsn/hdl/src/verilog/$ip_vrsn\.v"){
                                       print TNFO "Exits: $parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.v\n";
                                       print PATH "$parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.v\n";

                                }

				else{
					print CORE "$ip/$ip_vrsn\n";
					print INFO "None of the Path works for $ip_vrsn\n";
					print INFO "Not Exits: $parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.vhd\n";
					print INFO "Not Exits: $parse_from/$ip/$ip_vrsn/hdl/$ip_vrsn\.v\n";
					print INFO "Not Exits: $parse_from/$ip/$ip_vrsn/hdl/src/vhdl/$ip_vrsn\.vhd\n";
					print INFO "Not Exits: $parse_from/$ip/$ip_vrsn/hdl/src/verilog/$ip_vrsn\.v\n";

				}


			}
		}
	}

	else{
		#print INFO "$ip is not a directory\n";
	}
	chdir($parse_from);

}





