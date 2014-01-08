#!/usr/local/bin/perl 
#
#=======================================================
#
#       Created by HEMANG SHAH, IPV , Xilinx,Inc.
#       Last Modified: 08/27/2011
#
#=======================================================
#
#
### --- To generate tests from tpr files --- ###

system("clear");
$DEBUG='0';

#if ($ENV{XILINX} !=~ /^\/proj\/xbuilds/){
if (! defined $ENV{XILINX} ){

print "set XILINX to cadman add -t xilinx -v current REL -p unified_install";
print "You can find latest version from : cadman listtools -t xilinx -p unified_install";
exit;
}



print "\nEnter site code (e.g. XSJ, XCO etc. ) : ";
$site = <>;
chomp($site);

print "\nEnter file name (e.g. core_vrsn ) : ";
$file = <>;
chomp($file);

print "\nEnter run type (e.g. BVT, FOCUS, REGR, LONG) : ";
$run_type = <>;
uc($run_type);
chomp($run_type);

$dir = "/proj/${site}tcRepo/ipv/dspIP"; ## Testcase repository path ##
$tpr_path = "/proj/ipco/users/hshah/ankit/Perforce/IP3_ankitko_vid_regressions/DEV/hw";


print "$dir \n";

if (($run_type =~ /BVT/) || ($run_type =~ /REGR/) || ($run_type =~ /FOCUS/) || ($run_type =~ /LONG/))
{
}
else {
    print "run type is set to $run_type, which is invalid.\n";
    exit;
}

if (! -e "$dir/$ENV{REL}/$run_type") {
$mkcopy = `mkdir -p $dir/$ENV{REL}/$run_type `;
}

open (FILE,"$file");
while (<FILE>)
{
     $core = $_;
     chomp ($core);
     print "$core\n" if $DEBUG;

     ($core_name, $core_ver) = ($core =~ /(\w+)\/(\w+)/i);

		 $env = `cadman add -t gentests`;

     if ($run_type eq "BVT")
     {
       if (-e "$tpr_path/$core/test/$core_ver\_bvt.tpr") {
         $gentest = `cd $tpr_path/$core/test; /proj/xtools/svauto2/bin/gentests/gentests.pl -d $dir/$ENV{REL}/$run_type $core_ver\_bvt.tpr`;
			 } 
     }
     elsif ($run_type eq "REGR")
     {
       if (-e "$tpr_path/$core/test/$core_ver\_focused_vivado.tpr"){
	   $gentest =  `cd $tpr_path/$core/test; /proj/xtools/svauto2/bin/gentests/gentests.pl -d $dir/$ENV{REL}/$run_type $core_ver\_focused_vivado.tpr`;
	   
	   }
	   elsif (-e "$tpr_path/$core/test/$core_ver\_newdevices.tpr") {
         $gentest = `cd $tpr_path/$core/test; /proj/xtools/svauto2/bin/gentests/gentests.pl -d $dir/$ENV{REL}/$run_type $core_ver\_newdevices.tpr`;
			 } 
       elsif (-e "$tpr_path/$core/test/$core_ver.tpr") {
         $gentest = `cd $tpr_path/$core/test; /proj/xtools/svauto2/bin/gentests/gentests.pl -d $dir/$ENV{REL}/$run_type $core_ver.tpr`;
			 } 
     }
     elsif ($run_type eq "FOCUS")
     {
       if (-e "$tpr_path/$core/test/$core_ver\_focused.tpr") {
         $gentest = `cd $tpr_path/$core/test; /proj/xtools/svauto2/bin/gentests/gentests.pl -d $dir/$ENV{REL}/$run_type $core_ver\_focused.tpr`;
			 } 
     }
     elsif ($run_type eq "LONG")
     {
       if (-e "$tpr_path/$core/test/$core_ver\_long.tpr") {
         $gentest = `cd $tpr_path/$core/test; /proj/xtools/svauto2/bin/gentests/gentests.pl -d $dir/$ENV{REL}/$run_type $core_ver\_long.tpr`;
			 } 
     }

		 print "$gentest \n";

     $core = ();
     next;
}
close(FILE);



