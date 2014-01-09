package ipint_final_cfg;

#-----------------------------------------------------------------------------
# Author:     David Roth <droth@xilinx.com>
# Maintainer: David Roth <droth@xilinx.com>
#
# Description: a module used to read in phonix compatible cfg files and set
#              the envrionment accordingly
#
# Copied from:
# /proj/xtools/roms/ipa5_roms/users/att/roms/ulibs/ipint_cfg.pm
# Stephen Breslin, 31 Jan 06.
#
#-----------------------------------------------------------------------------


BEGIN
{
    print "load ipint_final_cfg module...\n";
}

use strict;
no strict 'refs';

#-----------------------------------------------------------------------------
sub set_env_from_cfg
#-----------------------------------------------------------------------------
{
    my ($file) = @_;

    # find which file to use
    my $cfg_file;
    if (-e "$ENV{'RUN'}/$file")
    {
	$cfg_file = "$ENV{'RUN'}/$file";
    }
    elsif (-e "$ENV{'UROMS'}/data/$file")
    {
	$cfg_file = "$ENV{'UROMS'}/data/$file";
    }
    elsif (-e "$ENV{'ROMS'}/data/$file")
    {
	$cfg_file = "$ENV{'ROMS'}/data/$file";
    }
    else
    {
	$cfg_file = 0;
    }

    # intentioanlly don't report an error if the
    # cfg file doesn't exist
    if ($cfg_file)
    {
	my %options = read_cfg($cfg_file);

	foreach my $type (keys %options)
	{
	    if ($type eq "SCALAR")
	    {
		foreach my $var (keys %{$options{$type}})
		{
		    # don't overwrite an already set flowoption with a random value
		    if ($options{$type}{$var} =~ /%$/)
		    {
			if (!exists $ENV{$var})
			{
			    $ENV{$var} = $options{$type}{$var};
			}
		    }
		    else
		    {
			$ENV{$var} = $options{$type}{$var};
		    }
		}
	    }
	    elsif ($type eq "ARRAY")
	    {
		foreach my $array (keys %{$options{$type}})
		{
		    foreach my $val (@{$options{$type}{$array}})
		    {
			push @{"ipint::$array"}, $val;
		    }
		}
	    }
	}
    }
}


#-----------------------------------------------------------------------------
sub read_cfg
#-----------------------------------------------------------------------------
{
    my ($cfg_file) = @_;

    open CFG, $cfg_file or die "ERROR: could not read cfg file $cfg_file: $!\n";

    my %statements;
    my $cfg_contents;

    while (my $line = <CFG>)
    {
	chomp $line;
	$line =~ s/\s*//;

	if ($line =~ /^#/ or $line =~ /^\s*$/)
	{
	    next;
	}

	# stip any dos line endings
	$line =~ s/\r//g;

	$cfg_contents .= $line;
    }
    close CFG;

    my %settings;
    my $block_name = "";
    foreach my $statement (split /(\w+)\s*{/, $cfg_contents)
    {
	if ($statement =~ /^\s*$/)
	{
	    next;
	}

  	if ($statement !~ /;/)
  	{
 	    $block_name = $statement;
  	}
 	else
 	{
#	    print "BLOCK: $block_name\n";

	    foreach my $line (split /;/, $statement)
	    {
		$line =~ /(\w+)\s*=(.*)/;
		my $key = $1;
		my $value = $2;

		if ($block_name eq "FlowConfig")
		{
 		    $settings{'SCALAR'}{$key} = $value;
#		    print "\tSCALAR: $key = $value\n";
		}
		elsif ($line =~ /}/)
		{
		    next;
		}
		else
		{
 		    push @{$settings{'ARRAY'}{$block_name}}, $value;
#		    print "\tARRAY: $block_name = $value\n";
		}
	    }
 	}
    }

    return %settings;
}

#-----------------------------------------------------------------------------
sub read_arizona_cfg
# New subroutine for Arizona regressions (Final.cfg).
#-----------------------------------------------------------------------------
{
    my ($cfg_file) = @_;
    my %settings;

    $main::DEBUG && print "ipint_final_cfg::read_arizona_cfg.\n";

    open CFG, $cfg_file or die "ERROR: could not read cfg file $cfg_file: $!\n";

    while (my $line = <CFG>)
    {
        # Skip comment or blank lines
	if ($line =~ /^#/ or $line =~ /^\s*$/)
	{
	    next;
	}

	# stip any dos line endings
	$line =~ s/\r//g;

	#$line =~ m/(\S+)\s+(\S+)\s*$/;
	$line =~ m/(\S+)\s+(\S)(.*)$/;       # Will also match param. settings such as "COREGEN_OPTION -J DSV_TEST=1"
	my $key = $1;
	my $value = $2.$3;
        $settings{$key} = $value;
    }
    close CFG;

    return %settings;
}

#-----------------------------------------------------------------------------
sub add_variable
#-----------------------------------------------------------------------------
{
    my ($cfg_file, $variable, $value) = @_;

    # find out if a value should be replaced rather than added
    my %settings;
    if (-e $cfg_file)
    {
	%settings = read_cfg($cfg_file);
    }

    my $new_variable = 1;
    if (exists $settings{'SCALAR'}{$variable})
    {
	 $new_variable = 0;
    }

    my @cfg_contents;
    if (-e $cfg_file)
    {
	open CFG, "$cfg_file" or die "ERROR: could not open $cfg_file: $!\n";
	my @cfg_contents = <CFG>;
	close CFG;
    }
    else
    {
	push @cfg_contents, "FlowConfig {\n";
	push @cfg_contents, "}\n";
    }

    open CFG, ">$cfg_file" or die "ERROR: could not open $cfg_file: $!\n";

    my $variable_added = 0;
    foreach my $line (@cfg_contents)
    {
	 if ($new_variable && !$variable_added && $line =~ /{/)
	 {
	      print CFG $line;
	      print CFG "$variable =$value;\n";
	      $variable_added;
	 }
	 elsif (!$new_variable && !$variable_added && $line =~ /^(\s*)$variable\s*=/)
	 {
	      print CFG "$1$variable =$value;\n";
	 }
	 else
	 {
	      print CFG $line;
	 }
    }

    close CFG;
}

#-----------------------------------------------------------------------------
sub read_variable
#-----------------------------------------------------------------------------
{
    my ($cfg_file, $variable) = @_;

    my %settings = read_cfg($cfg_file);

    my $value;
    if (exists $settings{'SCALAR'}{$variable})
    {
	 $value = $settings{'SCALAR'}{$variable};
    }
    else
    {
	 die "ERROR: variable $variable is not defined in config file $cfg_file\n";
    }

    return $value;
}

1;
