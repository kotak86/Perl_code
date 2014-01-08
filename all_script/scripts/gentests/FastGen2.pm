package FastGen2;

BEGIN
{
    print "load FastGen2 module...\n";
}


#use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


require Exporter;
require DynaLoader;
require AutoLoader;

#use gentests;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '1.00';

bootstrap FastGen2 $VERSION;


my %radix_prefix = ('2' => 'b',
		    '8' => 'ox',
		    '10' => '',
		    '16' => 'hx');

# generate a random seed for use during the duration of the time the
# module is loaded
GenSeedFast();


sub integer
{
     return $_[0] if ref $_[0] eq 'FastGen2';
     my $clean = $_[0];
     $clean =~ s/^\+//;
     $clean =~ s/[ _]//g;

     # check that only numbers are passed in
     if ($clean !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$clean is not a valid integer.", 70, "FastGen2::integer");
     }

     return string_to_integer("$clean");
}

sub float
{
     return $_[0] if ref $_[0] eq 'FastGen2';
     my $clean = $_[0];
     $clean =~ s/^\+//;
     $clean =~ s/[ _]//g;

     # check that only numbers are passed in
     if ($clean !~ /^[+-]?\d+(\.\d+)?$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$clean is not a valid float.", 70, "FastGen2::float");
     }

     return string_to_float("$clean");
}



#-----------------------------------------------------------------------------
# Computationally intensive elements of gentests that work
# faster in C
#-----------------------------------------------------------------------------

# Generate an array of $num_gen, between 0 and $diff, only
# in base 10
# if the difference is 1, an array of the minimum value is
# returned
# if $with_zero is 1, every other number will be 0
sub GenData
{
     my ($num_gen, $diff, $min, $with_zero, $type, $ux) = @_;
     my @ret;

#     print "GEN: $num_gen DIFF: $diff MIN: $min WZ: $with_zero TYPE: $type UX: $ux\n";

     # check the number of taps is valid
     if ($num_gen <= 0)
     {
	  gentests::err($gentests::CURRENT_LINE_NUMBER, "the number of taps must be >=1.", 70, "FastGen2::GenData");
     }

     if ($with_zero !~ /^[01]$/)
     {
	  gentests::err($gentests::CURRENT_LINE_NUMBER, "the last value can only be 0 or 1.", 70, "FastGen2::GenData");
     }

     if ($type eq "int")
     {
	  @ret = GenDataFast(integer($num_gen), integer($diff), integer($min), $with_zero);
     }
     else
     {
	  @ret = GenDataFastFloat(integer($num_gen), float($diff), float($min), $with_zero);
     }

#     print "RETURN: @ret\n";
     return @ret;
}



sub GenCamData
{
     my ($num_gen, $diff, $min, $base, $width) = @_;
     my @ret;
     my $position;

     # check the number of taps is valid
     if ($num_gen <= 5)
     {
	  gentests::err($gentests::CURRENT_LINE_NUMBER, "the number of taps must be >=5.", 70, "FastGen2::GenCamData");
     }

     my $split = int ($num_gen / 4);
     my $case_1 = rand $split;
     my $case_2 = rand $split;
     my $case_3 = rand $split;

     # create an array with a random list of positions
     my @places = (0..($num_gen-1));
     my @pos_pool;
     push @pos_pool, splice @places, rand @places, 1 while @pos_pool < $num_gen;

     # generate a random pool of valid integers
     my @rand_pool = GenDataFast(integer($num_gen), integer($diff), integer($min), 0);

     # convert them all to the required base
     foreach (@rand_pool)
     {
	  $_ = FastGen2::DectoBase($_, $base, $width);
	  # remove the type
	  s/^(b|hx)//;
     }

     # push a few random numbers into the mix
     for (my $i = 0; $i < $case_1; $i++)
     {
	  $position = pop @pos_pool;
	  $ret[$position] = pop @rand_pool;
     }

#     print "STAGE 1: @ret\n";

     # push a few random numbers into more than one place
     for (my $i = 0; $i < $case_2; $i++)
     {
	  my $value = pop @rand_pool;

	  for (my $j = 0; $j < 2; $j++)
	  {
	       $position = pop @pos_pool;
	       $ret[$position] = $value;
	  }
     }

#     print "STAGE 2: @ret\n";

     # push a few values in, which contain X's.
     for (my $i = 0; $i < $case_3; $i++)
     {
	  my @bits;
	  my $found = 0;
	  $position = pop @pos_pool;

	  # number of bits to replace.  Limit to max half
	  for (my $i = 0; $i < (rand (int ($width/2)))+1; $i++)
	  {
	       if ($base == 2)
	       {
		    $bits[$i] = (int rand ($width-1))+1;
	       }
	       elsif ($base == 16)
	       {
		    $bits[$i] = (int rand (($width/4)-1))+1;
	       }
	  }

	  while (@rand_pool && !$found)
	  {
	       my $rand_value = pop @rand_pool;

	       foreach my $bit (@bits)
	       {
		    substr($rand_value, $bit, 1) = 'X';
	       }

	       foreach my $existing (@ret)
	       {
		    if (!$existing)
		    {
			 next;
		    }

		    my $tmp = $existing;

		    foreach my $bit (@bits)
		    {
			 substr($tmp, $bit, 1) = 'X';
		    }

		    if ($rand_value !~ $tmp)
		    {
			 $ret[$position] = $rand_value;
			 $found = 1;
			 last;
		    }
	       }
	  }

	  if (!$found)
	  {
	       gentests::err($gentests::CURRENT_LINE_NUMBER, "could not find a unique bit pattern. Try running gentests again.", 70, "FastGen2::GenCamData");
	  }
     }

#     print "STAGE 3: @ret\n";

     # put the type back on the beginning of the number
     my $prefix;
     if ($base == 2)
     {
	  $prefix = "b";
     }
     elsif ($base == 16)
     {
	  $prefix = "hx";
     }

     foreach my $num (@ret)
     {
	  $num = $prefix . $num;
     }

     # finally fill all the rest of the positions with U's
     foreach my $pos (@pos_pool)
     {
	  my $no_pad = $width;

	  if ($base == 16)
	  {
	       my $extra = 0;

	       if (($no_pad % 4) != 0 )
	       {
		    $extra = 1;
	       }

	       $no_pad = int($width/4) + $extra;
	  }

	  $ret[$pos] = 'U' x $no_pad;
     }

#     print "LAST: @ret\n";
     return @ret;
}



# this routine will call GenData and then change the returned
# array into a comma seperated list.
# This is needed to have a consistent interface when the user
# writes custom perl modules, but do not use within gentests
# as it absolutely KILLS performance!!!
sub GenList
{
     my @ret = FastGen2::GenData(@_);
     my $ret_string;
     my $i;

     for ($i=0;$i<$#ret;$i++)
     {
	  $ret_string = $ret_string.$ret[$i].",";
     }

     $ret_string = $ret_string.$ret[$i];

     return $ret_string;
}


#-----------------------------------------------------------------------------
# Base conversion functions
#-----------------------------------------------------------------------------

# Convert a decimal number to any base from 2-32.  If a width
# is given, it will also pad the number with 0's, when positive.
sub DectoBase
{
     my ($num, $base, $width) = @_;

     # if $num is a U or an X, just return the same value
     # same of base 10.
     if (($base == 10) or ($num =~ /^(U|X)$/))
     {
	  return $num;
     }
     # if no width is specified
     if (!$width)
     {
	  $width = -1;
     }

     # need to have a width if using negative numbers
     if ($num =~ /^-/ && $width == -1)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "when using negative values, a width must be specified.", 70, "FastGen2::DectoBase");
     }

     return $radix_prefix{$base}.DectoBaseFast($num, $base, $width);
}


# Convert a binary string to a decimal string
sub BintoDec
{
     my ($binum, $signed) = @_;

     # ignore Us and Xs
     if ($binum =~ /^(U|X)$/)
     {
	  return $binum;
     }

     # if not specified, assume not signed!
     if (!$signed)
     {
	  $signed = 0;
     }

     # check it really is a binary number
     if ($binum !~ /^b[0|1]+$/i)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$binum is not a binary number.", 70, "FastGen2::BintoDec");
     }

     $binum =~ s/^b//i;

     return integer_to_string(BintoDecFast($binum, $signed));
}

# Convert a binary string to a hex string
sub BintoHex
{
     my ($binum) = @_;

     # ignore Us and Xs
     if ($binum =~ /^(U|X)$/)
     {
	  return $binum;
     }

     if ($binum !~ /^b[0|1]+$/i)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$binum is not a binary number.", 70, "FastGen2::BintoHex");
     }

     $binum =~ s/^b//i;

     return $radix_prefix{16}.BintoHexFast($binum);
}

# Convert an octal string to a decimal string
sub OcttoDec
{
     my ($octnum, $signed) = @_;

     # if not specified, assume not signed!
     if (!$signed)
     {
	  $signed = 0;
     }

     # check it really is a oct number
     if ($octnum !~ /^ox[0-7]+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$octnum is not an octal number.", 70, "FastGen2::OcttoDec");
     }

     $octnum =~ s/^ox//i;

     return integer_to_string(OcttoDecFast($octnum, $signed));
}

# Convert a hex string to binary
sub OcttoBin
{
     my ($octnum) = @_;

     if ($octnum !~ /^ox[0-7]+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$octnum is not a octal number.", 70, "FastGen2::OcttoBin");
     }

     $octnum =~ s/^ox//;

     return $radix_prefix{2}.OcttoBinFast($octnum);
}


# Convert a hex string to a decimal string
sub HextoDec
{
     my ($hexnum, $signed) = @_;

     # ignore Us and Xs
     if ($hexnum =~ /^(U|X)$/)
     {
	  return $hexnum;
     }

     # if not specified, assume not signed!
     if (!$signed)
     {
	  $signed = 0;
     }

     # lower the case to ease matching in the C function
     $hexnum = lc $hexnum;

     if ($hexnum !~ /^hx[0-9a-z]+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$hexnum is not a hexidecimal number.", 70, "FastGen2::HextoDec");
     }

     $hexnum =~ s/^hx//;

     return integer_to_string(HextoDecFast($hexnum, $signed));
}

# Convert a hex string to binary
sub HextoBin
{
     my ($hexnum) = @_;

     # ignore Us and Xs
     if ($hexnum =~ /^(U|X)$/)
     {
	  return $hexnum;
     }

     # lower the case to ease matching in the C function
     $hexnum = lc $hexnum;

     if ($hexnum !~ /^hx[0-9a-z]+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$hexnum is not a hexidecimal number.", 70, "FastGen2::HextoBin");
     }

     $hexnum =~ s/^hx//;

     return $radix_prefix{2}.HextoBinFast($hexnum);
}

# return the number with opposite sign
# only works with base 10
sub OppSign
{
     my ($num) = @_;

     # for speed!
     if (($num == 0) or ($num =~ /^(U|X)$/))
     {
	  return $num;
     }

     if ($num =~ /^(\d+(\.\d+)?)/)
     {
	  $num = '-'.$1;
     }
     elsif ($num =~ /^-(.*)/)
     {
	  $num = $1;
     }
     elsif ($num =~ /^\+(.*)/)
     {
	  $num = '-'.$1;
     }
     else
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "Internal error.", 70, "FastGen2::OppSign");
     }

     return $num;
}


#-----------------------------------------------------------------------------
# Handy math functions that can be called within gentests.pm
# a string is always returned
#-----------------------------------------------------------------------------

# add two numbers of any size.
sub add
{
     my ($num1, $num2) = @_;

     if ($num1 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num1 must be a valid integer.", 70, "FastGen2::add");
     }
     if ($num2 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num2 must be a valid integer.", 70, "FastGen2::add");
     }

     return integer_to_string(addFast($num1, $num2));
}
sub addFloat
{
     my ($num1, $num2) = @_;
     return float_to_string(addFastFloat($num1, $num2));
}


# subtract two numbers of any size.
sub subtract
{
     my ($num1, $num2) = @_;

     if ($num1 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num1 must be a valid integer.", 70, "FastGen2::subtract");
     }
     if ($num2 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num2 must be a valid integer.", 70, "FastGen2::subtract");
     }

     return integer_to_string(subtractFast($num1, $num2));
}
sub subtractFloat
{
     my ($num1, $num2) = @_;
     return float_to_string(subtractFastFloat($num1, $num2));
}


# multiply two numbers of any size
sub multiply
{
     my ($num1, $num2) = @_;

     if ($num1 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num1 must be a valid integer.", 70, "FastGen2::multiply");
     }
     if ($num2 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num2 must be a valid integer.", 70, "FastGen2::multiply");
     }

     return integer_to_string(multiplyFast($num1, $num2));
}
sub multiplyFloat
{
     my ($num1, $num2) = @_;
     return float_to_string(multiplyFastFloat($num1, $num2));
}

# divide two numbers of any size
sub divide
{
     my ($num1, $num2) = @_;

     if ($num1 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num1 must be a valid integer.", 70, "FastGen2::divide");
     }
     if ($num2 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num2 must be a valid integer.", 70, "FastGen2::divide");
     }

     return integer_to_string(divideFast($num1, $num2));
}
sub divideFloat
{
     my ($num1, $num2) = @_;
     return float_to_string(divideFastFloat($num1, $num2));
}

# raise a number to a power.  The number can be of any size,
# but the power must fit inside a long
sub power
{
     my ($num, $pow) = @_;

     # $pow can't be a negative number
     if ($pow =~ /^-/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "power($pow) must be a positive value.", 70, "FastGen2::power");
     }
     if ($num !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num must be a valid integer.", 70, "FastGen2::power");
     }
     if ($pow !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$pow must be a valid integer.", 70, "FastGen2::power");
     }

     return integer_to_string(powerFast($num, $pow));
}
sub powerFloat
{
     my ($num, $pow) = @_;

     # $pow can't be a negative number
     if ($pow =~ /^-/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "power($pow) must be a positive value.", 70, "FastGen2::powerFloat");
     }

     return float_to_string(powerFastFloat($num, $pow));
}

# obtain the modulus of two numbers.  A positive number is
# always returned
# only works with integers
sub modulus
{
     my ($num1, $num2) = @_;

     if ($num1 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num1 must be a valid integer.", 70, "FastGen2::modulus");
     }
     if ($num2 !~ /^[+-]?\d+$/)
     {
	  gentests::err ($gentests::CURRENT_LINE_NUMBER, "$num2 must be a valid integer.", 70, "FastGen2::modulus");
     }

     return integer_to_string(modulusFast($num1, $num2));
}


#-----------------------------------------------------------------------------
# Handy comparison functions
#-----------------------------------------------------------------------------
sub equal_to
{
     my ($num1, $num2) = @_;
     my $ret = compareFast($num1, $num2);

     if ($ret == 0)
     {
	  return 1;
     }
     return 0;
}

sub not_equal_to
{
     my ($num1, $num2) = @_;
     my $ret = compareFast($num1, $num2);

     if ($ret != 0)
     {
	  return 1;
     }
     return 0;
}

sub less_than
{
     my ($num1, $num2) = @_;
     my $ret = compareFast($num1, $num2);

     if ($ret < 0)
     {
	  return 1;
     }
     return 0;
}

sub less_than_or_eq
{
     my ($num1, $num2) = @_;
     my $ret = compareFast($num1, $num2);

     if ($ret <= 0)
     {
	  return 1;
     }
     return 0;
}

sub greater_than
{
     my ($num1, $num2) = @_;
     my $ret = compareFast($num1, $num2);

     if ($ret > 0)
     {
	  return 1;
     }
     return 0;
}

sub greater_than_or_eq
{
     my ($num1, $num2) = @_;
     my $ret = compareFast($num1, $num2);

     if ($ret >= 0)
     {
	  return 1;
     }
     return 0;
}



1;
__END__
