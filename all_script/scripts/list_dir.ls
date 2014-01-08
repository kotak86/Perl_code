# Declare all your path here and put each variable in @dir_array array

my $dir_1 = "/proj/XCOresults/arizona/rodin/coregenIP";
my $dir_2 = "/proj/XCOresults/arizona/test/coregenIP";
my $dir_3 = "/proj/XCOresults/arizona/test/vivsim_xsim/coregenIP";
my $dir_4 = "/proj/XCOresults/arizona/test/vivsim_mti/coregenIP";

# List of files to be preserved separated by single space. One to one correspondent with $dir_xx dedclaration above.
my @pres_1 =  qw (ids_14.2_P.28xd.1.0 ids_14.3_P.37.0.0);
my @pres_2 =  qw (ids_14.3_P.37.0.1);
my @pres_3 =  qw (14.3_0813 14.3_0814 14.3_0815);
my @pres_4 =  qw (14.3_0813 14.3_0814 14.3_0815);

# Call subroutine clean_dir for EACH of the $dir_xx/@pres_xx combinaiton declaration above.

&clean_dir($dir_1, 5,  @pres_1);
&clean_dir($dir_2, 3,  @pres_2);
&clean_dir($dir_3, 4,  @pres_3);
&clean_dir($dir_4, 4,  @pres_4);

1;
