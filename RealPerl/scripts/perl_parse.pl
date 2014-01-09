#!usr/bin/perl
#use warnings;
use strict;
use XML::Simple;
use Data::Dumper;
my $file_parse = "c_accum_bip_fabric_47865_1.xci";
#my $file_parse = "data.xml";

my $xml = new XML::Simple;

my $data = $xml->XMLin("$file_parse");
my  %dsp_cores = (
 'c_accum'					=>	"ACCUMULATOR", 
 'c_addsub'					=>	"ADDER_SUBTRACTER", 
 'c_counter_binary'			=>	"BINARY_COUNTER", 
 'cic_compiler'				=>	"CIC_COMPILER", 
 'cmpy'						=>  "COMPLEX_MULTIPLIER", 
 'cordic'					=>	"CORDIC",
 'c_shift_ram'	    		=>	"RAM-BASED_SHIFT_REGISTER", 
 'dds_compiler'				=>	 "DDS_COMPILER", 
 'dft'						=>	 "DISCRETE_FOURIER_TRANSFORM",
 'div_gen'					=>	 "DIVIDER_GENERATOR", 
 'dvb_s2_fec_encoder'		=>	 "DVB_S2_FEC_ENCODER", 
 'fir_compiler'				=>	 "FIR_COMPILER", 
 'floating_point'			=>	 "FLOATING-POINT", 
 'lte_3gpp_mimo_decoder'	=>	 "3GPP_LTE_MIMO_DECODER",
 'mult_gen'					=>	 "MULTIPLIER", 
 'pc_cfr'					=>	 "PEAK_CANCELLATION_CREST_FACTOR_REDUCTION",
 'v_manr'					=>	 "MOTION_ADAPTIVE_NOISE_REDUCTION", 
 'v_tc'						=>	 "VIDEO_TIMING_CONTROLLER", 
 'v_spc'					=>	 "DEFECTIVE_PIXEL_CORRECTION",
 'xbip_dsp48_macro'			=>	 "DSP48_MACRO", 
 'xbip_multaccum'			=>	 "MULTIPLY_ACCUMULATOR",
 'xbip_multadd'				=>	 "MULTIPLY_ADDER", 
 'xfft'						=>	 "FAST_FOURIER_TRANSFORM",
 'tcc_decoder_3gpplte'		=>	 "3GPPLTE_TURBO_DECODER", 
 'tcc_encoder_3gpplte'		=>	 "3GPPLTE_TURBO_ENCODER", 
 'convolution'				=>	 "CONVOLUTION_ENCODER", 
 'rs_decoder'				=>	 "REED-SOLOMON_DECODER", 
 'rs_encoder'				=>	 "REED-SOLOMON_ENCODER", 
 'viterbi'					=>	 "VITERBI_DECODER", 
 'v_ic'						=>	 "IMAGE_CHARACTERIZATION",
 'sid'						=>	 "INTERLEAVER/DE-INTERLEAVER",
 'lte_dl_channel_encoder'	=>	 "LTE_DL_CHANNEL_ENCODER", 
 'v_scaler'					=>	 "VIDEO_SCALER", 
 'duc_ddc_compiler'			=>	 "DUC_DDC_COMPILER", 
 'lte_rach_detector'		=>	 "LTE_RACH_DETECTOR",
 'lte_fft'					=>	 "LTE_FAST_FOURIER_TRANSFORM",
 'v_ccm'					=>	 "COLOR_CORRECTION_MATRIX", 
 'v_cresample'				=>	 "CHROMA_RESAMPLER", 
 'v_rgb2ycrcb'				=>	 "RGB_TO_YCRCB_COLOR-SPACE_CONVERTER",
 'v_ycrcb2rgb'				=>	 "YCRCB_TO_RGB_COLOR-SPACE_CONVERTER",
 'dpd'						=>	 "DIGITAL_PRE-DISTORTION",
 'v_vdma'					=>	 "VIDEO_DIRECT_MEMORY_ACCESS",
 'v_osd'					=>	 "VIDEO_ON_SCREEN_DISPLAY",
 'v_gamma'					=>	 "GAMMA_CORRECTION",
 'v_cfa'					=>	 "COLOR_FILTER_ARRAY_INTERPOLATION",
 'v_stats'					=>	 "IMAGE_STATISTICS",
 'v_noise'					=>	 "IMAGE_NOISE_REDUCTION", 
 'v_enhance'				=>	 "IMAGE_EDGE_ENHANCEMENT",
 'lte_3gpp_channel_estimator'	=> "3GPP_LTE_CHANNEL_ESTIMATOR", 
);


my $instances = $data->{"spirit:componentInstances"};
my $inst = $instances->{"spirit:componentInstance"};
my $com_vrsn = $inst->{"spirit:componentRef"}->{"spirit:version"};
my $IP = $inst->{"spirit:componentRef"}->{"spirit:name"};
my $compo =  $inst->{"spirit:configurableElementValues"}->{"spirit:configurableElementValue"}; 
my $family = "C_XDEVICEFAMILY";  my $core = $dsp_cores{$IP};
my $cmp; my $name; my@nme; my $cont;
my $file = "test.xco";

open XCO, ">$file" or die $!;

for (my $i=0; $i<200; $i++){
	 $cmp = $compo->[$i];
	 $name =  $cmp->{"spirit:referenceId"}; 
	if ($name =~ m/PARAM_VALUE/){
		$name =  $cmp->{"spirit:referenceId"};  @nme = split /\./, $name; 
	    $cont =  $cmp->{"content"};
		if ($nme[1] eq $family){
		print XCO  "\#Rule:--FAMILY eq '$cont'--";
		print XCO  "\nSELECT $core DEAULT_FAMILY Xilinx,_Inc. $com_vrsn";
		}
	}
}


for (my $i=0; $i<200; $i++){
	$cmp = $compo->[$i];
	$name =  $cmp->{"spirit:referenceId"}; 
	if ($name =~ m/\bPARAM_VALUE/){
	  $name =  $cmp->{"spirit:referenceId"}; @nme = split /\./, $name; 
	  $cont =  $cmp->{"content"}; chomp($nme[1]); chomp($cont);
	  print XCO  "\nCSET $nme[1] = $cont";
	}
}
 
print XCO "\nGENERATE";