#!/tools/xgs/perl/5.8.5/bin/perl

use warnings;
use strict;

sub chek_file{

	my $rodin_file = "status/modelsim_10.1a_Rodin-lin64";
	my $ise_file = "status/modelsim_10.1a_ISE-lin64";
	my $REL = $_[0];
	my $dir_I =  "/proj/xbuilds/clibs";
	my $dir_R = "/proj/xbuilds/clibs_rodin";
	my $I_state;
	my $R_state;
	my $cntd = 0;
	my $state;
	my $f_msg = "Build is fail";

	opendir (ICHECK, $dir_I) or die "Could not open";
	while ($_ = readdir(ICHECK)){
		if ($_ eq $REL){
			print "$REL found at $dir_I\n";
			$cntd = $cntd + 1; 
			last;
		}
	}


	opendir (RCHECK, $dir_R) or die "could not open";
	while($_ = readdir(RCHECK)){
		if($_ eq $REL){
			print "$REL found at $dir_R\n";
			$cntd = $cntd + 1;
			last;
		}
	}
	if ($cntd == 2){
		if((-e "$dir_I/$REL/$ise_file") && (-e "$dir_R/$REL/$rodin_file")){
			
			print "Found : $dir_I/$REL/$ise_file\n"; 
			print "Found : $dir_R/$REL/$rodin_file\n";
			
			open(ISTATE, "$dir_I/$REL/$ise_file")or die $!;
			open(RSTATE, "$dir_R/$REL/$rodin_file") or die $!;
			

			while ($_ = <ISTATE>){
				$I_state = $_ ;  chomp($I_state);
				if($I_state ne "PASS"){
					#&suc_mail($f_msg, "$dir_I/$REL/$ise_file");
					print "somethig is wrong";
				}
			}
	
			while ($_ = <RSTATE>){
				$R_state = $_; chomp ($R_state);
				if($I_state ne "PASS"){
                      			#&suc_mail($f_msg, "$dir_R/$REL/$rodin_file");
					print "Something is wrong";
				}
			}
	
			if(($I_state eq "PASS") && ($R_state eq "PASS")){
				$state = "PASS"; 

			}

			else{
				$state = "FAIL";

			}

		}

	}

	else {
		print "Either $dir_I/$REL/$ise_file or $dir_R/$REL/$rodin_file do not found";

	}
	print "Final state is $state\n";
	return 1;	
}


if( &chek_file("14.3_0726")){

	print "here you go";


}
else {

	print "To go";

}
