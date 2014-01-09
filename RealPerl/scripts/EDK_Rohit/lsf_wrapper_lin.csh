#!/bin/csh -f 
  setenv HOME /home/ankitko
  setenv SHELL /usr/bin/csh 
  setenv LSB_DEFAULTQUEUE medium 
 
 if (`uname` == SunOS) then  
      # needed to get mti simulations working under sol 9 
      limit descriptors 1024 
 else if (`uname` == Linux) then 
 else 
     echo 'Unsupported OS';  
     exit 1; 
 endif 
 
/proj/xtools/svauto2/flows/xlnxIP/prod/xlnxIP.pl -tc $argv[*] -SIMULATOR modelsim -CADMAN_xilinx_pathtype tda -CADMAN_xilinx 14.2_0516 -LSF_OPTION ' -P ip_ipv_regressions -Lp ipreg_opt -R "rusage[swemsimhdlsim=2:swesvverification=2:swemsimhdlmix=2]" -R "rusage[mem=3000]" -R "select[type==X86_64 && os==lin]" -eo /proj/xtools/testRunner/logs/ankitko/%J_%I_xlnxIP.err -oo /proj/xtools/testRunner/logs/ankitko/%J_%I_xlnxIP.txt '  -RESULTSROOT /proj/xresults/arizona/ankitko -CADMAN_modelsim 10.1a -RODIN_FLOW 1 -PLATGEN_OPTION  '-intstyle vivado' -FAMILY virtex7 -SUPER_TESTSUITE EDK -TESTSUITE IP_2012.1_120516  
 
