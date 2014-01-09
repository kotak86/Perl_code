#!/usr/bin/perl
use strict;
use warnings;

my $file = "core_implemented_testinst_wrapper_rst.files";
my $nfile = "add_files.tcl";
my $find_it = "soft_reset.vhd";
my $apend = "read_vhdl -library";
open CHK, "$file" or die $!;
open APEND, ">>$nfile" or die $!;
while ($_ = <CHK>){

 if ($_ =~ m/$find_it/){
    my $modify = $_;
    my @temp = split /pcores\//, $modify;
    my @ftemp = split /\/hdl/, $temp[1];
    my $core = "$ftemp[0]";
      if($_ =~ m/^$core/){
        print APEND "$apend $_";
      }
      else{
        print APEND "$apend $core$_";
      }
 }
 else {
  print APEND $_;

 }   

  
	
 }
