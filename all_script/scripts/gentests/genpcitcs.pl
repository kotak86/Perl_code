#!/tools/xgs/perl/5.8.5/bin/perl

# This script is used to create pci example testcases
# Author: Sasi Kumar

# usage:
# genpcitcs.pl -src /proj/xirsqa/pci/pci_64_66_core/release_pci_v3_151/pci_32_33_core -dest /proj/xirsqa/testCases/CNI/<branch>
#

# Use Library
use Getopt::Long;
use Term::ANSIColor;
system(clear);
title();
%sw = ();

# ----------------------------------------------
# Get the Commandline Options into the hash %sw
# ----------------------------------------------
$sucess = GetOptions ( \%sw, 'src=s', 'dest=s','verbose','help', 'override');

# exit if cmdline parsing failed
if (!$sucess)
{
	info(err,"Commandline parsing\n");
}
else
{
	info (i,"Switches Parsed Successfully\n");
	info (i,"----------------------------\n");
	while ( ($key,$val) = each %sw )
	{
		info(1, "$key : $val\n");
	}
	info (i,"----------------------------\n");
	
}

# print help if requested
if (defined $sw{help} )
{
	help();
	exit;
}

# check for mandatory args
# Error Out if the required options are missing
if ( not defined $sw{src} or not defined $sw{dest} )
{
	info (err,"Required arg missing\n\n");
	info (i,"For Help, use -help option\n");
	info (i,"Eg: $0 -help\n\n");
	exit; 
}


# Check the src & dest exists
if (! (-e "$sw{src}" ) )
{
	info (err,"Source dir \'$sw{src}\' doesn't exists\n");
	exit;
}

if (! (-e "$sw{dest}" ) )
{
	info (war,"Destination dir \'$sw{dest}\' doesn't exists\n");
	info (war,"creating \'$sw{dest}\' .....\n");
	`mkdir 	$sw{dest}`;
}
else
{
	if (! defined $sw{override})
	{
		info (err,"$sw{dest} already exists, please use -overide switch or specify diff dest dir\n");
		exit;
	}
	else
	{
		info (war,"-override switch specified\n");
	}
}



# ----------------------------------
# Actual Tcs Generation Starts here
# ----------------------------------
# check the src dir for examples
# FirstName will be release_pci_vx_xxx
# Secondnames are generated based on ncd/ucf file name 
$FirstName = GetTcsPrefix($sw{src});

foreach $lang (verilog, vhdl)
{
	splice @guidefiles;
	splice @ucffiles;
	splice @allFilesPrefix;
	undef %Hncd;
	undef %Hucf;
	my $langcode;
	$langcode = "vl" if ($lang eq "verilog");
	$langcode = "vd" if ($lang eq "vhdl");
	
	# check example exists in the src path, if exists then collect the information
	if (-e "$sw{src}/$lang/example")
	{
		info (i,"$lang example\(s\) found\n");
		opendir(DIR,"$sw{src}/$lang/src/guide");
			@guidefiles = grep { /\.ncd/ && -f "$sw{src}/$lang/src/guide/$_"} readdir(DIR);
		closedir(DIR);
		
		opendir(DIR,"$sw{src}/$lang/src/ucf");
			@ucffiles = grep { /\.ucf/ && -f "$sw{src}/$lang/src/ucf/$_"} readdir(DIR);
		closedir(DIR);
	
		$nguidefiles = scalar @guidefiles;
		$nucffiles   = scalar @ucffiles;
	
		info (i,"Guide Files : $nguidefiles\n"); 
		info (i,"UCF   Files : $nucffiles\n"); 
	
		%Hncd = map { RmExt($_) => $_} @guidefiles;
		%Hucf = map { RmExt($_) => $_} @ucffiles;
		
		@SecondNames = sort keys %{{ map {$_ => 1 } keys %Hncd,keys %Hucf }} ;
	
		%Hdevice = map { $_ => GetDev($_)} @SecondNames;
		%Hfamily = map { $_ => GetFam($_)} values %Hdevice;
		
		print "Number of tcs: " , scalar @SecondNames, "\n";
		
	}
	else
	{
		info(err,"No $lang Example Design Found in src\n");
		next;
	}
	

print '-' x 100, "\n";
printf "%-50s | %-25s | %-20s\n", "TcsName", "UCF", "NCD";
print '-' x 100, "\n";

# Start Creating testcase
foreach $SecondName (@SecondNames)
{
	$tcsname = $FirstName . "_". $SecondName . "_" . $langcode . "_" ;
	
	if (defined $Hncd{$SecondName})
	{
		$tcsname = $tcsname . "g";
	}		
	
	if (defined $Hucf{$SecondName})
	{
		$tcsname = $tcsname . "u";
	}
	
	printf "%-50s | %-25s | %-25s \n", $tcsname, $Hucf{$SecondName},$Hncd{$SecondName};

	$tcsFamily = $Hfamily{$Hdevice{$SecondName}};
	
	# Make tcs dir
	`mkdir -p $sw{dest}/$tcsFamily/$tcsname/pci`;
	
	# Copy example, some filters can be added to copy only the required files??
	`cp -R $sw{src}/$lang/* $sw{dest}/$tcsFamily/$tcsname/pci/.`;
	
	
	# Do the required changes in the following files in destination
	ChangeNcdInfo("$sw{dest}/$tcsFamily/$tcsname/pci","$Hncd{$SecondName}");
	ChangeUcfInfo("$sw{dest}/$tcsFamily/$tcsname/pci","$Hucf{$SecondName}");
	ChangeSynInfo("$sw{dest}/$tcsFamily/$tcsname/pci", "$Hdevice{$SecondName}");
	FixDoFile("$sw{dest}/$tcsFamily/$tcsname/pci",$lang);
	AddTopSw("$sw{dest}/$tcsFamily/$tcsname/pci");
	updatePing("$sw{dest}/$tcsFamily/$tcsname/pci",$lang);
	
	#cfg file need to be updated for these families
	if ($tcsFamily =~ /virtex2$|virtex2p$|spartan3$|virtex4$/)
	{
		UpdateCFG("$sw{dest}/$tcsFamily/$tcsname/pci",$lang);
	}
	
	# check whether this testcase uses GCLK/RCLK
	$UcfName = $Hucf{$SecondName};
	$UcfName =~ s/\.ucf//;
	my ($dev,$bits,$fr) = split (/_/, $UcfName);
	$fr =~ s/(\D)/_$1/;
	my ($freq,$refclk) = split (/_/, $fr);
	#print "$dev :: $bits bits :: $fr MHz :: $refclk \n";
	
	fixStimulus("$sw{dest}/$tcsFamily/$tcsname/pci",$lang,$freq);
	
	# correct the delay buffer value in cfg
	if (($tcsFamily eq 'virtex2p') && ($freq == '66'))
	{
		#print "=> v2p tcs with 66 Mhz -- Updating delay buffer\n";
		updateDelay("$sw{dest}/$tcsFamily/$tcsname/pci", $lang, "0001");
	}
	
	if (($tcsFamily eq 'virtex4') && ($refclk eq 'r'))
	{
		#print "=> v4 tcs with RCLK -- Updating delay buffer\n";
		updateDelay("$sw{dest}/$tcsFamily/$tcsname/pci", $lang, "1000");
	}
	
	
			

	if ($fr =~ /\D/) #capture if the $fr contains r|g eg: 33r,33g,66r,66g
	{
		
		#print "=>>> yes ref clk\n";
		#get the wrapper file information for this fr & clk 
		opendir(DIR,"$sw{dest}/$tcsFamily/$tcsname/pci/src/wrap");
			@wrappers = grep { /$freq/ && /$refclk/ && -f "$sw{dest}/$tcsFamily/$tcsname/pci/src/wrap/$_"} readdir(DIR);
		closedir(DIR);
		
		if (scalar @wrapper > 1)
		{
			#print "WARNING: there are more than matched file @wrapper, propably wrong testcase generation\n"
			info (war, "There are more than matched file @wrapper, propably wrong testcase generation\n");
		}
		else
		{
			#print "replace with this wrapper\n";
			$ext = "v"  if ($lang eq "verilog");
			$ext = "vhd" if ($lang eq "vhdl");
			`cp $sw{dest}/$tcsFamily/$tcsname/pci/src/xpci/pcim_lc.$ext $sw{dest}/$tcsFamily/$tcsname/pci/src/xpci/pcim_lc.$ext.old`;
			`cp $sw{dest}/$tcsFamily/$tcsname/pci/src/wrap/$wrappers[0] $sw{dest}/$tcsFamily/$tcsname/pci/src/xpci/pcim_lc.$ext`;
			
			fixPrjFile("$sw{dest}/$tcsFamily/$tcsname/pci",$lang);
			updatePingfilesRclk("$sw{dest}/$tcsFamily/$tcsname/pci",$lang);
		}
	}
	
}
print '-' x 100, "\n";
}
# ------- END -------










# ---------------------------------
# Sub routines used in this script
# ---------------------------------

sub updateDelay
{
	my ($dest,$lang,$value) = @_;
	my $bits;
	
	if ($lang eq "verilog")
	{
		open (CFG, "$dest/example/source/cfg_ping.v");
			@data = <CFG>;
		close(CFG);
		open (CFG, ">$dest/example/source/cfg_ping.v");

		#print "\n=> $dest/example/source/cfg_ping.v\n";
		foreach my $line (@data)
		{
			if ($line =~ /assign\s+CFG\[254:245\]\s+=\s+10\'b(\d+)\;/)
			{
				$bits = $1;
				$bits =~ s/(\d{6})(\d{4})/$1$value/; # replace the last 4 bits with the given value
				$line = "assign CFG[254:245] = 10'b$bits ;";
			}
			print CFG $line;
		}
		close(CFG);	
	}
	else
	{
		open (CFG, "$dest/example/source/cfg_ping.vhd");
			@data = <CFG>;
		close(CFG);
		open (CFG, ">$dest/example/source/cfg_ping.vhd");
		#print "\n=> $dest/example/source/cfg_ping.vhd\n";
		foreach my $line (@data)
		{
			if ($line =~ /cfg_int\(254\s+downto\s+245\)\s+\<=\s+\"(\d+)\"\;/)
			{
				$bits = $1;
				$bits =~ s/(\d{6})(\d{4})/$1$value/; # replace the last 4 bits with the given value
				$line = "cfg_int(254 downto 245) <= \"$bits\" ;";
			}
			print CFG $line;
		}
		close(CFG);	
	
	}
}












sub fixStimulus
{
	my ($dest,$lang,$freq) = @_;
	my $tclkh, $tclkl;
	#print "\tFixing stimulus \n";
	#print "\t$dest : $lang : $freq\n";

	if ($freq == 33)
	{
		$tclkh = 15;
		$tclkl = 15;
	}
	else
	{
		$tclkh = 7;
		$tclkl = 8;
	}
	
		
	if ($lang eq "vhdl")
	{
		open (STI,"$dest/example/source/stimulus.vhd");
			my @data = <STI>;
		close(STI);

		open (STI,">$dest/example/source/stimulus.vhd");
		foreach my $line (@data)
		{
			#print $line;
			$line =~ s/(constant\s*TCLKH\s*:\s*time\s*:=\s*)(\d+\s*)(ns)/$1 $tclkh $3/ig;
			$line =~ s/(constant\s*TCLKL\s*:\s*time\s*:=\s*)(\d+\s*)(ns)/$1 $tclkl $3/ig;
			#print "$1 : $2 : $3\n";
			print STI $line;
		}
		close(STI);
	}
	else
	{
		open (STI,"$dest/example/source/stimulus.v");
			my @data = <STI>;
		close(STI);

		open (STI,">$dest/example/source/stimulus.v");
		foreach my $line (@data)
		{
			$line =~ s/(parameter\s+TCLKH\s+=\s+)(\d+)/$1 $tclkh/g;
			$line =~ s/(parameter\s+TCLKL\s+=\s+)(\d+)/$1 $tclkl/g;
			print STI $line;
		}
		close(STI);
	}
	
	
	
	
}


# ----------------------------------------------------
# replaces pcim_top -> pcim_top_r in run_xst.prj file
# ----------------------------------------------------
sub fixPrjFile
{
	my ($dest,$lang) = @_;
	
	open (XLNX, "$dest/example/synthesis/run_xst.prj");
	my @data = <XLNX>;
	close(XLNX);
	
	open (XLNX, ">$dest/example/synthesis/run_xst.prj");
	foreach $line (@data)
	{
		$line =~ s/pcim_top/pcim_top_r/;
		print XLNX $line;
	}
	close(XLNX);
}

# ----------------------------------------------------
# updates ping files with _r
# ----------------------------------------------------
sub updatePingfilesRclk
{
	my ($dest,$lang) = @_;
	#print "Updating ping files ....\n";
	if ($lang eq "verilog")
	{
		# FUNC_SIM
		open (FUNCPING, "$dest/example/func_sim/ping_tb.f");
			@data = <FUNCPING>;
		close(FUNCPING);
		open (FUNCPING, ">$dest/example/func_sim/ping_tb.f");
		foreach my $line (@data)
		{
			$line =~ s/ping_tb\.v/ping_tb_r\.v/;
			$line =~ s/pcim_top\.v/pcim_top_r\.v/;
			print FUNCPING $line;
		}
		close(FUNCPING);
		
		# POST_SIM
		open (POSTPING, "$dest/example/post_sim/ping_tb.f");
			@data = <POSTPING>;
		close(POSTPING);
		open (POSTPING, ">$dest/example/post_sim/ping_tb.f");
		foreach my $line (@data)
		{
			$line =~ s/ping_tb\.v/ping_tb_r\.v/;
			$line =~ s/pcim_top\.v/pcim_top_r\.v/;
			print POSTPING $line;
		}
		close(POSTPING);
	}
	else
	{
		open (FUNCPING, "$dest/example/func_sim/ping.files");
			@data = <FUNCPING>;
		close(FUNCPING);
		open (FUNCPING, ">$dest/example/func_sim/ping.files");
		foreach my $line (@data)
		{
			$line =~ s/ping_tb\.vhd/ping_tb_r\.vhd/;
			$line =~ s/pcim_top\.vhd/pcim_top_r\.vhd/;
			print FUNCPING $line;
		}
		close(FUNCPING);
		
		# POST_SIM
		open (POSTPING, "$dest/example/post_sim/ping.files");
			@data = <POSTPING>;
		close(POSTPING);
		open (POSTPING, ">$dest/example/post_sim/ping.files");
		foreach my $line (@data)
		{
			$line =~ s/ping_tb\.vhd/ping_tb_r\.vhd/;
			$line =~ s/pcim_top\.vhd/pcim_top_r\.vhd/;
			print POSTPING $line;
		}
		close(POSTPING);	
	}
	
}


sub updatePing
{
	my ($dest,$lang) = @_;
	
	if ($lang eq "verilog")
	{
		open (PING, "$dest/example/post_sim/ping_tb.f");
			@data = <PING>;
		close(PING);
		open (PING, ">$dest/example/post_sim/ping_tb.f");
		foreach my $line (@data)
		{
			$line =~ s/\.\/pcim_top_routed\.v/\.\.\/xilinx\/pcim_top_routed\.v/;
			print PING $line;
		}
		close(PING);	
	}
	else
	{
		open (PING, "$dest/example/post_sim/ping.files");
			@data = <PING>;
		close(PING);
		open (PING, ">$dest/example/post_sim/ping.files");
		foreach my $line (@data)
		{
			$line =~ s/\.\/pcim_top_routed\.vhd/\.\.\/xilinx\/pcim_top_routed\.vhd/;
			print PING $line;
		}
		close(PING);	
	
	}
}


# ----------------------------------------------------
# sets the cfg[251] to 1
# ----------------------------------------------------
sub UpdateCFG
{
	my ($dest,$lang) = @_;
	my @data;
	
	if ($lang eq "verilog")
	{
		open (CFG, "$dest/example/source/cfg_ping.v");
			@data = <CFG>;
		close(CFG);
		open (CFG, ">$dest/example/source/cfg_ping.v");
		foreach my $line (@data)
		{
			$line =~ s/assign\s+CFG\[254:245\]\s+=\s+10\'b\d+\;/assign CFG\[254:245\] = 10\'b0001000000\;/;
			print CFG $line;
		}
		close(CFG);	
	}
	else
	{
		open (CFG, "$dest/example/source/cfg_ping.vhd");
			@data = <CFG>;
		close(CFG);
		open (CFG, ">$dest/example/source/cfg_ping.vhd");
		foreach my $line (@data)
		{
			$line =~ s/cfg_int\(254\s+downto\s+245\)\s+\<=\s+\"\d+\"\;/cfg_int\(254 downto 245\) \<= \"0001000000\"\;/;
			print CFG $line;
		}
		close(CFG);	
	
	}
}


sub AddTopSw
{
	my ($dest) = @_;
	
	open (CMD, "$dest/example/synthesis/run_xst.cmd");
		my @data = <CMD>;
	close(CMD);

	open (CMD, ">$dest/example/synthesis/run_xst.cmd");
	foreach my $line (@data)
	{
		$line =~ s/-ifn /-top pcim_top -ifn /g;
		print CMD $line;
	}
	close(CMD);
}


sub FixDoFile
{
	my ($dest,$lang) = @_;
	
	# Func_sim do file
	open (DO, "$dest/example/func_sim/modelsim.do");
		my @data = <DO>;
	close(DO);
	
	open (DO, ">$dest/example/func_sim/modelsim.do");
		print DO "onerror \{quit -f\}\n";
		print DO "onbreak \{quit -f\}\n";
		print DO @data;
		print DO "quit -f\n";
	close(DO);
	
	# post_sim do file
	open (DO, "$dest/example/post_sim/modelsim.do");
		my @data = <DO>;
	close(DO);
	
	open (DO, ">$dest/example/post_sim/modelsim.do");
		print DO "onerror \{quit -f\}\n";
		print DO "onbreak \{quit -f\}\n";
		print DO @data;
		print DO "quit -f\n";
	close(DO);
}


sub GetFam
{
	my ($dev) = @_;

	if ($dev =~ /^2s(\d+)e/)
	{
		return spartan2e;
	}
	elsif ($dev =~ /^2s(\d+)/)
	{
		return spartan2;
	}
	elsif ($dev =~ /^3s(\d+)e/)
	{
		return spartan3e;
	}
	elsif ($dev =~ /^3s(\d+)/)
	{
		return spartan3;
	}
	elsif ($dev =~ /^2vp(\d+)/)
	{
		return virtex2p;
	}
	elsif ($dev =~ /^2v(\d+)/)
	{
		return virtex2;
	}
	elsif ($dev =~ /^v(\d+)e/)
	{
		return virtexe;
	}
	elsif ($dev =~ /^v(\d+)/)
	{
		return virtex;
	}
	elsif ($dev =~ /^4v(sx|fx|lx)(\d+)/)
	{
		return virtex4;
	}
	else
	{
		info(war,"$dev is unknown family\n");
		return UNKNOWN;
	}
}


sub GetDev
{
	my ($secondname) = @_;
	my @tmp = split (/_/, $secondname);
	return $tmp[0];	
}


# ===========================================
# Help Message
# ===========================================
sub help 
{
system(clear);
title();
print <<endhelp;
This Script Creates the PCI testcases 
 IN the specified dest dir
 FROM the given src dir

Mandatory Switches:
-------------------
-src <source dir>
-dest <destination dir>

Other Switches:
---------------
-help 
-override

endhelp
}


sub title
{
    if (!(defined $ENV{SILENT})) {
        print "***********************************************\n";
        print "\/ /\\/  \n";
        print "\\ \\     Xilinx Inc\n";
        print "\/ \/     PCI Testcase Generator\n";
        print "\\\_\\/\\   All Rights Reserved\n";
        print "**********************************************\n";
    }
}


# ******************************************
# input    : Level,Message
# return   : NONE
# function : Prints info to the stdout
#            if not SILENT Mode
# ******************************************
sub info
{
    my ($level,$msg) = @_;
    if ($level eq "err") {print color ("red"), "ERROR: $msg", color ("reset");return;}
    if (! (defined $ENV{SILENT}) ) {
        if ($level eq "war") {print color ("blue"), "\tWarning: $msg", color ("reset");}
        else { print "$msg"; }
    }
}

# ******************************************
# Removes File Extension
# ******************************************
sub RmExt 
{
	my ($a ) = @_;
	$a =~ s/\.\S+//;
	return $a;
}


# ===========================================
# Get TestCase Prefix
# ===========================================
sub GetTcsPrefix
{
	my ($mypath) = @_;
	my @list = split (/\//, $mypath);
	my $prefix2 = pop(@list);
	my $prefix1 = pop(@list);
	
	$prefix1 =~ s/release_//;
	$prefix = $prefix1 . "_" . $prefix2;
	return $prefix;
}


# ===========================================
# Change NCD File info in run_xilinx scripts
# ===========================================
sub ChangeNcdInfo
{
	my ($destdir,$ncdfile) = @_;
	#print "--> $destdir,$ncdfile \n";
	
	foreach $file ('run_xilinx', 'run_xilinx.bat')
	{
		#print "--> $file\n";
		open (XLNX, "$destdir/example/xilinx/$file");
			@data = <XLNX>;
		close(XLNX);
	
		open (XLNX, ">$destdir/example/xilinx/$file");
		if ($ncdfile ne "")
		{
			foreach $line (@data)
			{
				#$line =~ s/\/guide\/(\w+).ncd/\/guide\/$ncdfile/;
				$line =~ s/-gf (.*)(\/|\\)(\w+).ncd/-gf ${1}${2}$ncdfile/;
				print XLNX $line;
			}
		}
		else
		{
			# $ncdfile is blank, so remove -gf & -gm option
			foreach $line (@data)
			{
				$line =~ s/-gf (.*)(\/|\\)(\w+)\.ncd//;
				$line =~ s/-gm (\S+)//;
				print XLNX $line;
			}
		}
		close(XLNX);
	}
}


# ===========================================
# Change ucf File info in run_xilinx scripts
# ===========================================
sub ChangeUcfInfo
{
	my ($destdir,$ucffile) = @_;
	#print "--> $destdir,$ucffile \n";
	
	foreach $file ('run_xilinx', 'run_xilinx.bat')
	{
		splice @data;
		open (XLNX, "$destdir/example/xilinx/$file");
			@data = <XLNX>;
		close(XLNX);
	
		open (XLNX, ">$destdir/example/xilinx/$file");
		if ($ucffile ne "")
		{
			foreach $line (@data)
			{
				$line =~ s/-uc (.*)(\/|\\)(\w+).ucf/-uc ${1}${2}$ucffile/;
				print XLNX $line;
			}
		}
		else
		{
			# $ncdfile is blank, so rmove -uc option
			foreach $line (@data)
			{
				$line =~ s/-uc (\S+)//;
				print XLNX $line;
			}
		}
		close(XLNX);
	}
}


sub ChangeSynInfo
{
	my($destdir,$dev) = @_;

	#remove any leading zeros in device part as xst doesn't regco it
	$dev =~ s/(s|vp|fx|sx|lx|v)0/$1/i;

	open (XLNX, "$destdir/example/synthesis/run_xst.cmd");
	my @data = <XLNX>;
	close(XLNX);
	
	open (XLNX, ">$destdir/example/synthesis/run_xst.cmd");
	foreach $line (@data)
	{
		$line =~ s/-p(\s+)(([a-zA-Z0-9-])+)/-p $dev /;
		print XLNX $line;
	}
	close(XLNX);
	
}
