#!/devl/perl/5.6.1/bin/perl

#########################################################################
#                                                                       #
#     This is a program used to interpret coregen .tpr files and to     #
#     automatically generate batfiles in the correct input directory.   #
#                                                                       #
#     Modules used: gentests_steve.pm, createBat.pm                           #
#     Input files: .tpr file, simFlow.txt, flow.txt                     #
#
#     Copied from /proj/xtools/roms/ipa5_roms/users/att/roms/bin/gentests.pl
#     Stephen Breslin, 30 Jan 06.
#                                                                       #
#     Author: Eamonn Ryan & Christophe Brotelande,XIR SQA               #
#     Date:   March 1999.                                               #
#                                                                       #
#########################################################################

BEGIN
{
}

use lib $ENV{'USPTTOOLS'} ?
    ("$ENV{'USPTTOOLS'}/libs","$ENV{'SPTTOOLS'}/libs") : "$ENV{'SPTTOOLS'}/libs";

use lib $ENV{'UROMS'} ?
    ("$ENV{'UROMS'}/ulibs","$ENV{'ROMS'}/ulibs") : "$ENV{'ROMS'}/ulibs";

use lib "$ENV{'UTOOLS'}/plib";

# so all files are created 666 and directores 777 by default
umask 0000;

use strict;
no strict 'vars';
use gentests_steve;

#-------------------------------------------------------------------------
# CONSTANTS
#-------------------------------------------------------------------------
# translate words into required radix number
local %RADIX_TRANS = (
		   'bin' => '2',
		   'oct' => '8',
		   'dec' => '10',
		   'int' => '10',
		   'hex' => '16'
		  );

# the maximum width that can be specified in the TPR file
local $MAX_WIDTH = 1024;
# maximum iteration depth allowed. If this number is reached the program will end.
local $IT_MAX = 200;

#-------------------------------------------------------------------------
# DEBUGGING VARIABLES
#-------------------------------------------------------------------------
local $DEBUG_GNR = 0;
local $DEBUG_GVD = 0;
local $DEBUG = 0;
local $DEBUG_VECTOR = 0;
local $DEBUG_OUT = 0;
local $DEBUG_MYEVAL = 0;

#-------------------------------------------------------------------------
# GLOBAL VARIABLES
#-------------------------------------------------------------------------
local $REPOSITORY;
local $DEFAULT_PRIORITY = 2;
local $UNIVERSAL_PRIORITY;
local $GENERATE_README = 0;
local $REMOVE_ALL = 0;


# this is an array of all flowoptions that have been set on the command line,
# and apply to ALL tpr files run in the session.
local %UNIVERSAL_FLOWOPTS;

# the number of tests to calculate.  -1 means calculate all tests
local $NO_TO_CALC = -1;

# new filename for the regenerated testcase
local $REGENERATE_NAME = 'unset';
# whether to keep the module name the same of not when regenerating
local $KEEP_MODULE_NAME = 0;

# whether to exit straight away on exit, or move onto the next TPR
local $KEEP_GOING = 0;

# From command line. Needed for regresssion in order to extract correct module name.
# Regression scripts do not use TPR files (which contain module / TPR name) so need to use this method.
local $RESULTS_DIR = "";

# From command line. Needed for regresssion in order to copy over dirs. in common_files from original tescase area.
# Not ideal, as we are now reliant on the original testcase area exsiting, but getting this info from the sandbox area
# would be difficult, as the module names in the sandbox paths are different from the testcase or results area module names.
local $ORIG_TESTCASE_DIR = "";


#-----------------------------------------------------------------------------
# MAIN
#-----------------------------------------------------------------------------
{
    # start the timer
    my $start = (times)[0];

    # parse the command line args
    my @tpr_files = parse_args(@ARGV);

    # check that the repository has been set
    if (!$REPOSITORY)
    {
	print "ERROR: You need to specify where you want to create those testcases (REPOSITORY area).\n";
	print "       Use the -d option to set that directory.\n";
	usage();
    }

    # need to cd into the directory before checking it's existance
    # to ensure the automounts pick it up
    my $cwd = Cwd::cwd();
    chdir $REPOSITORY;
    chdir $cwd;

    # make sure that the repository exists and is writable
    if (!-d $REPOSITORY or !-w $REPOSITORY)
    {
	print "ERROR: The requested repository ($REPOSITORY) does not exists or is not writable.\n";
	exit 1;
    }

    print ("REPOSITORY: $REPOSITORY\n\n");
    print "\n\t\t\t********************\n\n";

    # for each tpr file
    foreach my $tpr_file (@tpr_files)
    {
	# generate the testcases
	my $tpr_status = gentests_steve::generate_tpr($tpr_file, $RESULTS_DIR, $ORIG_TESTCASE_DIR);

	# check the TPR generated correctly
	if ($tpr_status != 0)
	{
	    if ($KEEP_GOING)
	    {
		print "\nThe TPR $tpr_file had fatal errors and did not generate all its tests.\n";
	    }
	    else
	    {
		last;
	    }
	}
    }

    # stop the timer
    my $end = (times)[0];

    print "Testcase generation completed.\n";
    printf ("Total CPU seconds for gentests_steve.pl: %.2f secs\n", $end - $start);
    
}


#-----------------------------------------------------------------------------
sub parse_args
#-----------------------------------------------------------------------------
{
    my (@args) = @_;
    @args = reverse (@args);

    # array containing tpr files we want to run
    my @tprs;
    my $ini_file;

    # process the command line
    while (my $argv = pop(@args))
    {
        $argv =~ s/\s*//g;

        if ($argv eq '-debug')
        {
	    $DEBUG = 1;
	    print ("Debug mode ...\n");
        }
        elsif ($argv eq '-debug_vector')
        {
	    $DEBUG_VECTOR = 1;
        }
        elsif ($argv eq '-res')
        {
	    $DEBUG_OUT = 1;
        }
        elsif ($argv eq '-form')
        {
	    $DEBUG_MYEVAL = 1;
        }
        elsif ($argv eq '-help' or $argv eq '-h')
        {
	    usage();
        }
        elsif ($argv eq '-d')
        {
	    $REPOSITORY = pop(@args);
	}
        elsif ($argv =~ /(\w+\.(tpr|in)$)/)
        {
	    push(@tprs, $argv);
        }
        elsif ($argv eq '-f')
        {
	    my $ini_file = pop(@args);

	    if (!-e $ini_file)
	    {
		print "ERROR: You need to give a valid .ini file. $ini_file does not exist !";
		exit 1;
	    }

	    @args = ();
	    @args = read_ini_file($ini_file);
        }
        elsif ($argv eq '-fv')
        {
	    my $flow_var = uc (pop (@args));
	    my $flow_val = pop (@args);

	    $UNIVERSAL_FLOWOPTS{$flow_var} = $flow_val;

	    print ("Global Flow Option: $flow_var = $flow_val\n");
        }
	elsif ($argv eq '-p')
	{
	    $UNIVERSAL_PRIORITY = pop(@args);

	    if ($UNIVERSAL_PRIORITY !~ /[1-3]/)
	    {
		print "ERROR: Priority $UNIVERSAL_PRIORITY is not valid.  Only 1-3 allowed values.";
		exit 1;
	    }
	}
        elsif ($argv eq '-kg')
        {
	    $KEEP_GOING = 1;
        }
	elsif ($argv eq '-num')
	{
	    $NO_TO_CALC = pop(@args);
	}
	elsif ($argv eq '-regen_name')
	{
	    $REGENERATE_NAME = pop(@args);
	}
	elsif ($argv eq '-regen_keep_mod')
	{
	    $KEEP_MODULE_NAME = 1;
	}
	elsif ($argv eq '-readme')
	{
	    $GENERATE_README = 1;
	}
	elsif ($argv eq '-remove_all')
	{
	    $REMOVE_ALL = 1;
	}
	# obsoleted commands, left here for compatibility
	elsif ($argv eq '-helpflow')
        {
	    print "-helpflow option is no longer supported\n";
        }
        elsif ($argv eq '-cgt')
        {
	    print "-cgt option is no longer supported\n";
        }
	elsif ($argv eq '-r')
	{
	    print "-r option is no longer supported\n";
	}
        elsif ($argv eq '-debug_coe')
        {
	    print "-debug_coe is no longer supported, use -debug_vector instead\n";
        }
	elsif ($argv eq '-results_dir')
	{
	    $RESULTS_DIR = pop(@args);
	}
	elsif ($argv eq '-orig_testcase_dir')
	{
	    $ORIG_TESTCASE_DIR = pop(@args);
	}
        else
        {
	    print "ERROR: The command $argv is not supported in the command line\n";
	    usage();
        }
    }

    if (@tprs == 0)
    {
	print "ERROR: You need to specify in the command line or the ini file a tpr file !";
	usage();
    }

    print "\n";

    return @tprs;
}


#-----------------------------------------------------------------------------
sub read_ini_file
#-----------------------------------------------------------------------------
{
    my ($ini_file) = @_;
    my @CMD;

    open (INIFILE, $ini_file) or die "Could not open the file $ini_file: $!\n";
    print ("\nReading ini file: $ini_file\n\n");

    foreach (<INIFILE>)
    {
	s/\n//;
	# strip anything after a # ie, it's a comment
	s/\#.*//;
	# strip out any 's which might be used in error
	s/\'//g;
	# do nothing if left with a blank line
	next if (/^\s*$/);

	# flow variables can't be sererated by word, as they can be
	# multi word values!
	if (/(-fv)\s+(\w+)\s+(.*)/)
	{
	    push @CMD, $1;
	    push @CMD, $2;
	    push @CMD, $3;
	}
	else
	{
	    push @CMD, split(/\s+/);
	}
    }

    close INIFILE;

    return reverse @CMD;
}


#-----------------------------------------------------------------------------
sub usage
#-----------------------------------------------------------------------------
{
    print <<EOF;
*********************************************************************************
               This tool generates testcases for IP verification.
http://xirweb/intranet/rd/software/sv/projects/ipsolutions/automation/index.shtml
*********************************************************************************

Command line options:
	-f <ini file> : will set arguments for gentests from this file, no other
                        options are valid with -f.
                        ---------------------
	-h : display the help dialog.
                        ---------------------
	-d <PATH>  : Repository path (where the testcases are created).
       		     Will override the current value of \$REPOSITORY.
	-num <NUM> : Generate the first <NUM> test cases.
	-fv <Flow variable name> <value>: Will set the flow variable to the given value.
                                          NOTE: when the value of a flow variable is
                                          more than on word, it must be in single quotes
        -p <NUM> : priority of testcases generated.
        -kg        : if there is a problem with a TPR, don't die, just move on to the next
        -regen_name <NAME> : new name for the regenerated testcase
        -regen_keep_mod : if used keep the module_name the same otherwise it will be changed to the
                          core name_version
        -readme :    generate a readme file
        -remove_all :    remove all existing testcases in a module directory
Examples:
        gentests.pl -f my_gentests.ini
        gentests.pl -fv run_bitgen 0 -fv BM BM_VLOG -fv COREGEN_OPTION '-i coregen.ini'
EOF

    exit 1;
}
