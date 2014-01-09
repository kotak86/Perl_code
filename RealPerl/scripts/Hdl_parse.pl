#!/tools/xgs/perl/5.8.5/bin/perl
use strict;
use warnings;

my $path_list = "/proj/ipco/users/hshah/ankit/scripts/path_list";
open PATH, $path_list or die $!;

open INFO, ">/proj/ipco/users/hshah/ankit/scripts/update_hdl.ls" or die $!;
"Family"." " x(30)."\# of desing found". " " x(15)."\# of desing Picked\n";

print INFO "CORE NAME"." "x(30)."UCASE PORT \@ LINE". " " x(20) ."AT LEAST 1 PORT DECLARED IN UPPER CASE\n";

while (my $cor_path =  <PATH>){

	my $frmt = 0;
        my @core = split /\//,$cor_path;
	my $infile   = $cor_path;
	my $p_start = 0;
	open HDL,$infile or die $!;
	my $mtch = "port map";
	my $Mtch = "PORT MAP";
	while ($_ = <HDL>){
		chomp($_);
		if($p_start == 0){
			if(($_ =~ /port\(/) or ($_ =~ /port \(/) or ($_ =~ /\bPort\(\b/) or ($_ =~ /\bPORT \(\b/)){

				$p_start = 1;
				if(($_ =~ /\bPort\(\b/) or ($_ =~ /\bPORT \(\b/)){
					print "The port keyword is used in Upper case as \n Found at $. $_\n";
					$frmt = 1; my $u_port_line = $.;
					print INFO "\n$core[9]"." " x(40-length($core[9]))."\($.\)"." "x(30 - length($core[9]));

				
				}
				else {
					print "Found at $. $_\n";
				}	
			}		
		
       		}
	
		if($p_start == 1){

			if((($_ =~ /\bin\b\s+|\bIN\b\s+/) or ($_ =~ /\bout\b\s+|\bOUT\b\s+/) or ($_ =~ /\binout\b\s+|\bINOUT\b\s+/)) and ($_ !~ /--/)){

			        my @line = split /:/, $_;
				if (($line[0] =~ /[A-Z]/g)) {

				print "Found at $. $_"; $_ =~ s/^\s+//;   $_ =~ s/\s+/ /g; 
				if (length($_) > 60){

					$_ = substr($_, 0, 70);

				}
				chomp($_);
				if ($frmt) {print INFO " "x(30 - length($core[9])). "\[$.\]  $_";}
				else {print INFO "\n".$core[9]." "x(75 -length($core[9])). "\[$.\] $_";}
				last;
				}
			}	
			elsif (($_ =~ /$mtch/)or ($_ =~ /$Mtch/)){
			print "Found at $. $_\n";
			$p_start = 0;
			}
			else{
			#	print "$_\n";
			}


		}

	}

	close(HDL);

}
