#!/usr/local/bin/perl
use warnings;
use strict;
use XML::Simple;
use Data::Dumper;
my $file_parse = "c_accum_bip_fabric_47865_1.xci";
my $family = "MODELPARAM_VALUE.C_XDEVICEFAMILY";
my $ip_name = "spirit:name=";
my $ip_vrsn = "spirit:version=";

open FILEPARSE,"$file_parse" or die $!;
print "file open";
while ($_ = <FILEPARSE>){
#print $_;
if ( ($_ =~ m/$family/) or  ($_ =~ m/$ip_name/) or ($_ =~ m/$ip_vrsn/) ){
 print $_;

}

}


#my %mnth     =  (Jan =>"01", Feb =>"02", Mar =>"03", May =>"05", Apr =>"04", Jun=>"06",
#                 Jul=>"07", Aug=>"08", Sep=>"09", Oct=>"10", Nov=>"11", Dec=>"12");
#my $mth_no   = $mnth{$dte_splt[1]}; # map the corresponding # accroding to month

my  %dsp_cores = (
      "ACCUMULATOR" => 'c_accum',
      "ADDER_SUBTRACTER" => 'c_addsub',
      "BINARY_COUNTER" => 'c_counter_binary',
      "CIC_COMPILER" => 'cic_compiler',
      "COMPLEX_MULTIPLIER" => 'cmpy',
      "CORDIC" => 'cordic',
      "RAM-BASED_SHIFT_REGISTER" => 'c_shift_ram',
      "DDS_COMPILER" => 'dds_compiler',
      "DISCRETE_FOURIER_TRANSFORM" => 'dft',
      "DIVIDER_GENERATOR" => 'div_gen',
      "DVB_S2_FEC_ENCODER" => 'dvb_s2_fec_encoder',
      "FIR_COMPILER" => 'fir_compiler',
      "FLOATING-POINT" => 'floating_point',
      "3GPP_LTE_MIMO_DECODER" => 'lte_3gpp_mimo_decoder',
      "MULTIPLIER" => 'mult_gen',
      "PEAK_CANCELLATION_CREST_FACTOR_REDUCTION" => 'pc_cfr',
      "MOTION_ADAPTIVE_NOISE_REDUCTION" => 'v_manr',
      "VIDEO_TIMING_CONTROLLER" => 'v_tc',
      "DEFECTIVE_PIXEL_CORRECTION" => 'v_spc',
      "DSP48_MACRO" => 'xbip_dsp48_macro',
      "MULTIPLY_ACCUMULATOR" => 'xbip_multaccum',
      "MULTIPLY_ADDER" => 'xbip_multadd',
      "FAST_FOURIER_TRANSFORM" => 'xfft',
      "3GPPLTE_TURBO_DECODER" => 'tcc_decoder_3gpplte',
      "3GPPLTE_TURBO_ENCODER" => 'tcc_encoder_3gpplte',
      "CONVOLUTION_ENCODER" => 'convolution',
      "REED-SOLOMON_DECODER" => 'rs_decoder',
      "REED-SOLOMON_ENCODER" => 'rs_encoder',
      "VITERBI_DECODER" => 'viterbi',
      "IMAGE_CHARACTERIZATION" => 'v_ic',
      "INTERLEAVER/DE-INTERLEAVER" => 'sid',
      "LTE_DL_CHANNEL_ENCODER" => 'lte_dl_channel_encoder',
      "VIDEO_SCALER" => 'v_scaler',
      "DUC_DDC_COMPILER" => 'duc_ddc_compiler',
      "LTE_RACH_DETECTOR" => 'lte_rach_detector',
      "3GPP_LTE_CHANNEL_ESTIMATOR" => 'lte_3gpp_channel_estimator',
      "LTE_FAST_FOURIER_TRANSFORM" => 'lte_fft',
      "COLOR_CORRECTION_MATRIX" => 'v_ccm',
      "CHROMA_RESAMPLER" => 'v_cresample',
      "RGB_TO_YCRCB_COLOR-SPACE_CONVERTER" => 'v_rgb2ycrcb',
      "YCRCB_TO_RGB_COLOR-SPACE_CONVERTER" => 'v_ycrcb2rgb',
      "DIGITAL_PRE-DISTORTION" => 'dpd',
      "VIDEO_DIRECT_MEMORY_ACCESS" => 'v_vdma',
      "VIDEO_ON_SCREEN_DISPLAY" => 'v_osd',
      "GAMMA_CORRECTION" => 'v_gamma',
      "COLOR_FILTER_ARRAY_INTERPOLATION" => 'v_cfa',
      "IMAGE_STATISTICS" => 'v_stats',
      "IMAGE_NOISE_REDUCTION" => 'v_noise',
      "IMAGE_EDGE_ENHANCEMENT" => 'v_enhance');
