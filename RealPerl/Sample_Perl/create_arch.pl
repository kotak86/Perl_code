#!/usr/bin/perl

use strict;
use warnings;

my $input;
my $outdir;
my $help;

sub usage {
  print "usage: $0 -f file [-od outdir]\n";
  exit 1;
}

# Process Inputs
use Getopt::Long;
if ( GetOptions(
        "f=s" => \ $input,
        "od=s" => \ $outdir,
        "help|h" => \ $help,
        ) != 1 ) {
    usage ();
}

if ($help or !$input) {
  usage ();
  exit;
}

if (!$outdir) { $outdir = "\."; }

if (! -d $outdir && !mkdir($outdir,0755)) {
  die "Can't make directory $outdir: $!\n";
}
# End Process Inputs

my $clb_x;
my %arch_para;
my $arch_file;

#my $input =  "input_parameter.ls";
my %lut_hash = ("lut1"   => "LUT1 INV AND2B1L",
                            "lut2"   => "LUT2 LUT1 INV AND2B1L",
                                "lut3"   => "LUT3 LUT2 LUT1 INV AND2B1L",
                                "lut4"   => "LUT4 LUT3 LUT2 LUT1 INV AND2B1L",
                                "lut5"   => "LUT5 LUT4 LUT3 LUT2 LUT1 INV AND2B1L",
                                "lut6z5" => "RAM128X1D RAM128X1S RAM16X1D RAM256X1S RAM32M RAM32X1D RAM64M RAM64X1D RAM64X1S LUT6 SRL16 SRL16E SRLC16E SRLC32E RAM16X1S LUT6_2 RAM32X1S RAMD32 RAMS32",
                                "lut6z4" => "RAM128X1D RAM128X1S RAM16X1D RAM256X1S RAM32M RAM32X1D RAM64M RAM64X1D RAM64X1S LUT6 LUT5 SRL16 SRL16E SRLC16E SRLC32E RAM16X1S LUT6_2 RAM32X1S RAMD32 RAMS32",
                                "lut6z3" => "RAM128X1D RAM128X1S RAM16X1D RAM256X1S RAM32M RAM32X1D RAM64M RAM64X1D RAM64X1S LUT6 LUT5 LUT4 SRL16 SRL16E SRLC16E SRLC32E RAM16X1S LUT6_2 RAM32X1S RAMD32 RAMS32"
                                );


open FILE, $input or die $!;

        my @arch = <FILE> ;


        $arch[0] =~ s/\s//g;
        my @header = split /\,/, $arch[0];



        for (my $i = 1; $i <= $#arch ; $i++){

                $arch[$i] =~ s/\s+//g;

                my @a_parameter = split /\,/, $arch[$i];


                foreach my $key (@header){

                        my $val = shift (@a_parameter);
                        $arch_para{$key} = $val;
                }

                my $no_ff   = $arch_para{clb_x} * 16;
                my $no_muxf = $arch_para{clb_x} * 6;
                my $no_c4   = $arch_para{clb_x} * 2;
                my $in          = $arch_para{total_ipins} * $arch_para{ipin_x} ;
                my $out         = $arch_para{total_opins} * $arch_para{opin_x} ;
                $arch_file = $arch_para{name};
                open ARCH, ">$outdir/$arch_file\.hz" or die $!;
                print ARCH "HZArch cag sub dev\n";
                print ARCH "map carry4 0.04 : CARRY4\n";

                print ARCH "map $arch_para{L1_type}  $arch_para{L1_delay} : RAM128X1D RAM128X1S RAM16X1D RAM256X1S RAM32M RAM32X1D RAM64M RAM64X1D RAM64X1S LUT6 LUT5 LUT4 LUT3 LUT2 LUT1 INV  SRL16 SRL16E SRLC16E SRLC32E RAM16X1S LUT6_2 AND2B1L RAM32X1S RAMD32 RAMS32\n";

                if ($arch_para{L2_type} =~/lut/){
                        print ARCH "map $arch_para{L2_type} $arch_para{L2_delay} : $lut_hash{$arch_para{L2_type}}\n";
                }

                if ($arch_para{L3_type} =~ /lut/){
                        print ARCH "map $arch_para{L3_type} $arch_para{L3_delay} : $lut_hash{$arch_para{L3_type}}\n";
                }



                        print ARCH "\n";
                        print ARCH "map bram 100 : RAMB16_S9_S9 RAMB18E1 RAMB36E1 FIFO18E1 FIFO36E1\n";
                        print ARCH "map bufgmux 100 : BUFG BUFGP BUFHCE BUFGCTRL PLLE2_ADV BSCANE2 BUFIO BUFR BUFH BUFMR\n";
                        print ARCH "map dsp 100 : DSP48E1\n";
                        print ARCH "map ff 100 : FD FDC FDCE FDE FDP FDPE FDR FDRE FDS FDSE LD LDCE LDPE\n";
                        print ARCH "map rail 100 : GND VCC\n";
                        print ARCH "map mgt 100 : GTHE2_CHANNEL MMCME2_ADV GTXE2_CHANNEL GTX2E2_COMMON GTXE2_COMMON TRIMAC_GEN TRIMAC_GEN__1 TRIMAC_GEN__2 TRIMAC_GEN__3 PCIE_2_1 GTHE2_COMMON TRIMAC_GEN__4 TRIMAC_GEN__5 TRIMAC_GEN__6 TRIMAC_GEN__7 TRIMAC_GEN__8 TRIMAC_GEN__9 TRIMAC_GEN__10 TRIMAC_GEN__11 XADC\n";
                        print ARCH "map iob 100 : IBUF IBUFDS_GTE2 IBUFG IBUFGDS IBUFDS OBUF OBUFDS IOBUF OBUFT ODDR IDDR IDELAYE2 IDELAYCTRL DNA_PORT\n";
                        print ARCH "map muxf  0.02 : MUXF7 MUXF8\n";
                        print ARCH "\n";
                        print ARCH "ntime $arch_para{lint_delay} $arch_para{gint_delay} 0.000 -CASC CARRY*->CARRY* 0.01 MUX*->MUX* 0.001 LUT*->FD*,LD* 0.01 CARRY*->CARRY4 0.01\n";
                        print ARCH "\n";
                        print ARCH "tile CLBM -IN $in  -OUT $out lut6m $arch_para{LUT_1} ff $no_ff muxf $no_muxf carry4 $no_c4\n";
                        print ARCH "\n";

                if ($arch_para{ctrlset} == 1){
                        print ARCH "rule CtrlSet\n";
                }
                else {
                        print ARCH "# rule CtrlSet\n";
                }


                if ($arch_para{shr_pins} and $arch_para{shr1} and $arch_para{shr2}){
                print ARCH "rule shrpins shared=$arch_para{shr_pins} types=$arch_para{shr1}, $arch_para{shr2}\n"; }
				
				

                if($arch_para{csc1} and $arch_para{csc2}){
					if(!$arch_para{csc3}){
                        print ARCH "rule intCasc group=$arch_para{csc2}\{a\}, $arch_para{csc1}\{b\}  casc=a->b.I1;"; }


					else {

                        print ARCH "rule intCasc group=$arch_para{csc3}\{a\},$arch_para{csc2}\{b\},$arch_para{csc1}\{c\}  casc=a->b.I1;b->c.I2\n";

					}
				}

        close (ARCH);



        }


