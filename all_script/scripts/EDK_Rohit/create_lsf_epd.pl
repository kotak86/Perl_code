#!/usr/local/bin/perl 
#
#=======================================================
#
#       Created by HEMANG SHAH, IPV, Xilinx,Inc.
#       Last Modified: June 03,2010
#
#=======================================================
#
#
### --- To create LSF files --- ###

system("clear");
$DEBUG='0';
$resub='0';
$wrapper = ();
$num ='0';
print $os = $ARGV[0];print "\n";
print $core = $ARGV[1];print "\n";
print $family = $ARGV[2];print "\n";
print $sim = $ARGV[3];print "\n";
print $site = $ARGV[4];print "\n";
print $supertest = $ARGV[5];print "\n";
print $REL = $ARGV[6];print "\n";

if (!defined $os || !defined $core || !defined $family || !defined $run_type || !defined $sim || !defined $site)
{print "Usage create_lsf.pl <file name> <platform lin/nt> <core name> <family> <core version : L or K > <run type : BVT or REGR> <simulator : isim, mti, ius> <site: XSJ, XCO> \n";exit;}

print $dir = "/proj/xtcRepo/ipv/epdIP/$REL/FOCUS/_TCASE/edkIP";
$dir_nt = "G:\\xtcRepo\\ipv\\dspIP\\$REL\\FOCUS\\_TCASE\\edkIP"; # Make sure the path is visible from all windows machine for LSF job #

if (!defined $REL)
{print "Please set build (\$REL).\n";exit;}

if (!defined $hwcosim){
  $hwcosim = 0; # Default is HW co-sim turned OFF
}

if ($supertest =~ /hrz/) {
    $super_test = "-SUPER_TESTSUITE REGRESSION_P1";
}
elsif ($supertest =~ /vdo/) {
    $super_test = "-SUPER_TESTSUITE REGRESSION_P2";
}
elsif ($supertest =~ /wrl/) {
    $super_test = "-SUPER_TESTSUITE REGRESSION_P3";
}
else {
    $super_test = "-SUPER_TESTSUITE NEW";
}

 $REL = "$ENV{REL}" ;
 $EDK_REL = "$ENV{EDK_REL}" ;

($rel_name, $bld) = ($REL =~ /(\w+)\_(\w+)/i);

if ($REL =~ /ids/) {
   $xlnx_path = "unified_install";
 }
 elsif ($REL =~ /^14.2_/) {
    $xlnx_path = "tda";
 }
 else {
   $xlnx_path = "default";
 }


if ($os =~ /lin/) {
			$wrapper = "lsf_wrapper_lin.csh";
}
elsif ($os =~ /nt\b/) {
		if ($supertest =~ /hrz/) {
      $wrapper = "bvt_hrz_lsf_wrapper_win.bat";
		}
 	elsif ($supertest =~ /vdo/) {
      $wrapper = "bvt_vdo_lsf_wrapper_win.bat";
 	}
 	elsif ($supertest =~ /wrl/) {
      $wrapper = "bvt_wrl_lsf_wrapper_win.bat";
 	}
}

 if ($run_type =~ /BVT/) {
     $typ = " ";
 }
 else {
     $typ = " ";
 }


 if ($sim =~ /isim/) {
     $sim_vendor = "-SIM_VENDOR xlnx";
 }
 elsif ($sim =~ /mti/) {
     if ($os =~ /lin/) {
         $sim_vendor = "-CADMAN_modelsim 10.1a -CADMAN_modelsim_pathtype default " ;
		 }
		 elsif ($os =~ /nt/) { 
         $sim_vendor = "-CADMAN_modelsim 10.1a -CADMAN_modelsim_pathtype default " ;
		 }

 }
 elsif ($sim =~ /ius/) {
     $sim_vendor = "-CADMAN_ius 11.1 -CADMAN_ius_pathtype default" ;
 }
 else {
    print "Please specify isim, mti or ius as simulator. \n";
		exit;
 }

   if (! -d "/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL") {
		 $cp = `mkdir -p /proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL`;
	 }

 if ($resub) {
    $run_type = "resub\_$run_type";
		{&resub_lsf}
 }
 else {
    {&lsf}
 }

sub resub_lsf {
  print" Info: The file \"resub_list\" must be under same path as this script\n";
  open (resub,"./resub_list");
	while (<resub>) 
	{
    $case = $_;
    chomp ($case);
    print "$case\n" if $DEBUG;

	  opendir(DIR,"$dir/$core");
  	@arch = readdir(DIR);
  	closedir(DIR);
  	
  	foreach $arch (@arch)
  	{
  	   if (($arch =~ /^\./) || ($arch =~ /common_files/) || ($arch =~ /xml/) || ($arch =~ /save/) )
  	   {
  	      $arch = ();
  	      next;
  	   }
  	   else {
          if (-e "$dir/$core/$arch/$case") {
  	         open (lsf1,">>/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_try_$os");
  	 		    print lsf1 "$dir/$core/$arch/$case/input \\\n";
  	         close(lsf1); 
  	         $num++;
  	         $case = ();
  	         next;
          }
          else {
             next;
          }
  	   }
  	}
		open (FILE,"/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_try_$os");
		while (<FILE>) 
		{
		  $line = $_;
		  push @tcases_list, $line;
		}
		close(FILE);
		
		$rm_tmp = `rm -rf /proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_try_$os`;
		
		open (lsf,">/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_$os");
		  print lsf "#!/bin/csh\n";
		  print lsf "#BSUB -J $core\[1-$num\]%25\n";
		  print lsf "#BSUB -eo /proj/xtools/testRunner/logs/ankitko/%J_%I.err\n";
		  print lsf "#BSUB -oo /proj/xtools/testRunner/logs/ankitko/%J_%I.txt\n";
		  print lsf "set a = (\\\n";
		  if ($os =~ /lin/) {
		     foreach $tcases_list (@tcases_list) {
		        print lsf "$tcases_list";
		     }
			}
			## windows support not implemented yet ##
		  elsif ($os =~ /nt/) {
			   if ($hwcosim =~ /1/) {
				     if ($family =~ /virtex5/) {
		             print lsf "-c \"G:\\ipco\\users\\$ENV{USER}\\lsf\\$ENV{USER}_lsf\\$REL\\$run_type\_$core\_$family\_$wrapper $dir_nt\\$core\\$family\\$tcase\\input\" -p winxp,winvista -m xsjhshah-v32:2101 -pri  \" 0\" \n";
					   }
					   elsif ($family =~ /spartan3adsp/) {
		             print lsf "-c \"G:\\ipco\\users\\$ENV{USER}\\lsf\\$ENV{USER}_lsf\\$REL\\$run_type\_$core\_$family\_$wrapper $dir_nt\\$core\\$family\\$tcase\\input\" -p winxp,winvista -m xsj-hshah:2101 -pri  \" 0\" \n";
					   }
				 }
					else {
		         print lsf "-c \"G:\\ipco\\users\\$ENV{USER}\\lsf\\$ENV{USER}_lsf\\$REL\\$run_type\_$core\_$family\_$wrapper $dir_nt\\$core\\$family\\$tcase\\input\" $plat $arch -pri  \" 0\" \n";
				  }
			}
			## end of windows support ##
		
		  print lsf ");\n";
		  print lsf "/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_$wrapper \$a\[\$LSB_JOBINDEX\];\n";
		  close(lsf);
  }
}

sub wrap {

if ($os =~ /lin/) {
	open (wrap,">/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_$wrapper");
    print wrap "#!/bin/csh -f\n";
    print wrap "setenv HOME /proj/xtcRepo/ip/lsf/$ENV{USER}\n";
    print wrap "setenv SHELL /usr/bin/csh\n";
    print wrap "setenv LSB_DEFAULTQUEUE medium\n\n";
		print wrap "if \(\`uname\` == SunOS\) then\n";
		print wrap "limit descriptors 1024\n";
		print wrap "else if \(\`uname\` == Linux\) then\n";
		print wrap "else\n";
		print wrap "echo \"Unsupported OS\"\;\n";
		print wrap "exit 1\;\n";
		print wrap "endif\n\n";

#	 	$ts = "/proj/${site}tools/svauto2/flows/dspIP/dev_ipxact/dspIP.pl -CADMAN_xilinx $REL -CADMAN_xilinx_pathtype $xlnx_path  $sim_vendor $typ $super_test -RESULTSROOT_UNIX  /proj/xresults/arizona -SIM_TYPE routed  -ENV_XIL_NETGEN_REMOVE_GTXE1 1 -tc \$argv\[\*\] ";
	 	$ts = "/proj/xtools/svauto2/flows/xlnxIP/prod/xlnxIP.pl -tc \$argv\[\*\] -CADMAN_xilinx $REL -CADMAN_xilinx_pathtype $xlnx_path $sim_vendor -SIMULATOR modelsim -SUPER_TESTSUITE EDK -TESTSUITE IP_2012.2_12$bld  -RESULTSROOT /proj/xresults/arizona/ankitko -ENV_XIL_PAR_SS_DESIGN 1 -LSF_OPTION \' -P ip_ipv_regressions -q medium -R \"rusage\[mem=3000\]\" -R \"rusage\[swesvverification=2:swemsimhdlsim=2:swemsimhdlmix=2\]\" -oo /proj/xtools/testRunner/logs/ankitko/\%J_\%I.txt -eo /proj/xtools/testRunner/logs/ankitko/\%J_\%I.err -E /proj/xtools/cfs/lsf_validate.sh -Lp ipreg_opt \' -XIL32 0 -DEBUGLEVEL 1 -DEBUG_MODE 0  ";
		
		print wrap "$ts\n";
		$ts = ();
	close(wrap);
}
else {
 if (!-e "/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$wrapper") {
 	open (wrap,">/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$wrapper");
    print wrap "\@echo off\n";
    print wrap "set TMP=\%TEMP\%\n";
    print wrap "set HOME=C:\\\n";
    print wrap "set USER=$ENV{USER}\n";
		print wrap "set ROMS=\\\\ppdeng\\gdrive\\xtools\\roms\\null\\users\\att\\roms\n";
		print wrap "set ROMSCORE=\\\\ppdeng\\gdrive\\xtools\\roms\\null\\users\\att\\romscore\n";
		print wrap "set XIL_SITE=CO\n";
		print wrap "set SPTTOOLS=\\\\ppdeng\\gdrive\\xtools\\spttools\\null\\users\\att\\spttools\n";
		print wrap "set SPOOLER=\\\\ppdeng\\gdrive\\xtools\\spooler\n\n";
		print wrap "set LSB_DEFAULTQUEUE=medium_win\n\n";
		print wrap "REM net use G: \\\\ppdeng\\gdrive\n";
		print wrap "if not exist G: net use G: \\\\ppdeng\\gdrive \/persistent:no\n";
		print wrap "REM dir G:\n";
		print wrap "REM set Path=\.\;\%SystemRoot\%\\system32\;\%SystemRoot\%\;G:\\xgs\\perl\\5.8.5\\bin\;\%ROMS\%\\bin\;\%UROMSCORE\%\\bin\;\%ROMSCORE\%\\bin\;\%UTOOLS\%\\bin\\nt\;\%ROMS\%\\perl\\bin\n";
		print wrap "set\n\n";
		
    if ($hwcosim =~ /1/) {
       if ($family =~ /virtex5/i) {
	 				$ts = "G:\\xgs\\perl\\5.8.5\\bin\\perl G:\\xtools\\svauto2\\flows\\dspIP\\dev_ipxact\\dspIP.pl -CADMAN_xilinx $REL -CADMAN_xilinx_pathtype $xlnx_path  $sim_vendor $typ $super_test -RESULTSROOT_WIN  G:\\xresults\\arizona -SIM_TYPE routed -FAMILY virtex5 -HW_COSIM 1 -HW_BOARD ml506-jtag -ENV_XIL_NETGEN_REMOVE_GTXE1 1 -tc \%\* ";
       }
       elsif ($family =~ /spartan3adsp/i) {
	 				$ts = "G:\\xgs\\perl\\5.8.5\\bin\\perl G:\\xtools\\svauto2\\flows\\dspIP\\dev_ipxact\\dspIP.pl -CADMAN_xilinx $REL -CADMAN_xilinx_pathtype $xlnx_path  $sim_vendor $typ $super_test -RESULTSROOT_WIN  G:\\xresults\\arizona -SIM_TYPE routed -FAMILY spartan3adsp -HW_COSIM 1 -HW_BOARD ml506-jtag  -ENV_XIL_NETGEN_REMOVE_GTXE1 1 -tc \%\* ";
       }
    }
    else {
	 				$ts = "G:\\xgs\\perl\\5.8.5\\bin\\perl G:\\xtools\\svauto2\\flows\\dspIP\\dev_ipxact\\dspIP.pl -CADMAN_xilinx $REL -CADMAN_xilinx_pathtype $xlnx_path  $sim_vendor $typ $super_test -RESULTSROOT_WIN  G:\\xresults\\arizona -SIM_TYPE routed -ENV_XIL_NETGEN_REMOVE_GTXE1 1 -tc \%\* ";
    }
		print wrap "$ts\n";
		$ts = ();
	close(wrap);
	}
  else {
  }
}
}

sub lsf {

opendir(DIR,"$dir/$core");
@arch = readdir(DIR);
closedir(DIR);

foreach $arch (@arch)
{
  if (($arch =~ /^\./) || ($arch =~ /common_files/) || ($arch =~ /xml/) || ($arch =~ /save/) )
  {
     $arch = ();
     next;
  }
  else
  {
     opendir(DIR,"$dir/$core/$arch");
		 print "$dir/$core/$arch\n";
     @tcases = readdir(DIR);
     closedir(DIR);
     
     foreach $tcases (@tcases)
     {
        if (($tcases =~ /^\./) || ($tcases =~ /list/))
        {
           $tcases = ();
           next;
        }
        else {
           open (lsf1,">>/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_try_$os");
					    if ($os =~ /lin/) {
					    	print lsf1 "$dir/$core/$arch/$tcases/input \\\n";
							}
							else {
					    	print lsf1 "$dir_nt\\$core\\$arch\\$tcases\\input";
							}
           close(lsf1); 
           $num++;
           $tcases = ();
           next;
        }
     }
		 next;
  }
@arch = ();
@tcases = ();
}
open (FILE,"/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_try_$os");
while (<FILE>) 
{
  $line = $_;
  push @tcases_list, $line;
}
close(FILE);

$rm_tmp = `rm -rf /proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_try_$os`;
	if ($os =~ /lin/) {
		open (lsf,">/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_lsf_job_$os");
		  print lsf "#!/bin/csh\n";
		 # print lsf "#BSUB -J $core\[1-3\]\n";
		 print lsf "#BSUB -J $core\[1-$num\]\n";
		  print lsf "#BSUB -eo /proj/xtools/testRunner/logs/$ENV{USER}/%J_%I.err\n";
		  print lsf "#BSUB -oo /proj/xtools/testRunner/logs/$ENV{USER}/%J_%I.txt\n";
		  print lsf "set a = (\\\n";
		  if ($os =~ /lin/) {
		     foreach $tcases_list (@tcases_list) {
	        print lsf "$tcases_list";
	     }
		}
		  print lsf ");\n";
		  print lsf "/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/$run_type\_$core\_$family\_$wrapper \$a\[\$LSB_JOBINDEX\];\n";
	close(lsf);
}

elsif ($os =~ /nt/) {
  foreach $tcases_list (@tcases_list) {
		open (lsf,">>/proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL/bvt_nt_lsf_jobs");
	   if ($hwcosim =~ /1/) {
		     if ($family =~ /virtex5/) {
         		print lsf "bsub -R \"select\[type==NTX86\]\" -Lp ipv -R \"rusage\[msimhdlmix=1:msimhdlsim=1\]\"  -P ip_ipv_regressions -J nt_bvt -E\"\\\\ppdeng\\gdrive\\xtools\\cfs\\lsf_validate.bat\" -q medium_win -eo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.err\" -oo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.txt\" \"\\\\ppdeng\\gdrive\\ipco\\users\\$ENV{USER}\\lsf\\$ENV{USER}_lsf\\$REL\\$wrapper $dir_nt\\$core\\$family\\$tcases_list\\input\" -m xsjhshah-v32:2101  " ;
			   }
			   elsif ($family =~ /spartan3adsp/) {
		         print lsf "bsub -R \"select\[type==NTX86\]\" -Lp ipv -R \"rusage\[msimhdlmix=1:msimhdlsim=1\]\" -P ip_ipv_regressions -J nt_bvt -E\"\\\\ppdeng\\gdrive\\xtools\\cfs\\lsf_validate.bat\" -q medium_win -eo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.err\" -oo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.txt\" \"\\\\ppdeng\\gdrive\\ipco\\users\\$ENV{USER}\\lsf\\$ENV{USER}_lsf\\$REL\\$wrapper $dir_nt\\$core\\$family\\$tcases_list\\input\" -m xsj-hshah:2101  " ;
			   }
		 }
			else {
    		     print lsf "bsub -R \"select\[type==NTX86\]\" -Lp ipv -R \"rusage\[msimhdlmix=1:msimhdlsim=1\]\" -P ip_ipv_regressions -J $REL\_nt_bvt -E\"\\\\ppdeng\\gdrive\\xtools\\cfs\\lsf_validate.bat\" -q medium_win -eo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.err\" -oo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.txt\" \"\\\\ppdeng\\gdrive\\ipco\\users\\$ENV{USER}\\lsf\\$ENV{USER}_lsf\\$REL\\$wrapper $tcases_list\" \n" ;
    		     print lsf "bsub -R \"select\[type==NTX64\]\" -Lp ipv -R \"rusage\[msimhdlmix=1:msimhdlsim=1\]\" -P ip_ipv_regressions -J $REL\_nt64_bvt -E\"\\\\ppdeng\\gdrive\\xtools\\cfs\\lsf_validate.bat\" -q medium_win -eo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.err\" -oo \"\\\\ppdeng\\gdrive\\xtools\\testRunner\\logs\\hshah\\%J.txt\" \"\\\\ppdeng\\gdrive\\ipco\\users\\$ENV{USER}\\lsf\\$ENV{USER}_lsf\\$REL\\$wrapper $tcases_list\" \n" ;
		  }
  	close(lsf);
		}
	}
}
{&wrap}

$permission = `chmod -R 755 /proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL`;
print "lsf files for $os created at : /proj/ipco/users/hshah/ankit/lsf/$ENV{USER}_lsf/$REL\n";
$os = ();
$core = ();
$family = ();
