#!/tools/xgs/perl/5.8.5/bin/perl
# #!/devl/perl/5.6.1/bin/perl


# $Header: /devl/xcs/repo/env/Misc/TestAutomationTools/Arizona/svauto/bin/gentests/Attic/gentests.pl,v 1.1.2.10 2007/12/07 16:17:28 liamb Exp $

#########################################################################
#                                                                       #
#     This is a program used to interpret coregen .tpr files and to     #
#     automatically generate batfiles in the correct input directory.   #
#                                                                       #
#     Modules used: gentests.pm, createBat.pm                           #
#     Input files: .tpr file, simFlow.txt, flow.txt                     #
#                                                                       #
#     Author: Eamonn Ryan & Christophe Brotelande,XIR SQA               #
#     Date:   March 1999.                                               #
#                                                                       #
#########################################################################

BEGIN
{
my $path;
my $path2;
if ($^O =~ /win/i) {
    $path = "G:\\xtools\\svauto2\\bin\\gentests\\blib\\nt";
    $path2 = "G:\\xtools\\svauto2\\bin\\gentests\\";
} elsif ($^O =~ /sol/i) {
    $path = "/proj/xtools/svauto2/bin/gentests/blib/sol";
    $path2 = "/proj/xtools/svauto2/bin/gentests/";
} else {
	$path = "/proj/xtools/svauto2/bin/gentests/blib/lin";
    $path2 = "/proj/xtools/svauto2/bin/gentests/";
}
unshift @INC, $path;
unshift @INC, $path2;

# Enable running from a sandbox
use FindBin ;
my $pAlt = $FindBin::Bin ;
unshift( @INC, $pAlt ) if $pAlt !~ /xtools.svauto/ && -f "${pAlt}/gentests.pm" ;

}

# so all files are created 666 and directores 777 by default
umask 0000;

use strict;
no strict 'vars';
#use lib './blib/lin';
use gentests;
use NCopy;
use FastGen2;


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
local $REMOVE_ALL = 0;
local $USE_FILENAME = 0;


# this is an array of all flowoptions that have been set on the command line,
# and apply to ALL tpr files run in the session.
local %UNIVERSAL_FLOWOPTS;

local %filerev ;
local $bpath ;

# the number of tests to calculate.  -1 means calculate all tests
local $NO_TO_CALC = -1;

# new filename for the regenerated testcase
local $REGENERATE_NAME = 'unset';
# whether to keep the module name the same of not when regenerating
local $KEEP_MODULE_NAME = 0;

# whether to exit straight away on exit, or move onto the next TPR
local $KEEP_GOING = 0;

# Prefix to be applied to names of generated tests
local $PREFIX_NAME = "" ;

# Flag to prevent deletion of existing tests
local $KEEP_EXISTING_TESTS = 0; # by default overwriting is permitted

# Name of repository branch which tests will be written to
local $REPBRANCH = "HEAD" ;


#-----------------------------------------------------------------------------
# MAIN
#-----------------------------------------------------------------------------
{
    # start the timer
    my $start = (times)[0];

    $bpath = $FindBin::Bin ;
    print "\n\nbin = $bpath\n" ;
    my $fver ;
    KFILE:
    for my $kfile ( 'gentests.pl', 'gentests.pm' ) {
       $fver = "unknown" ;
       open( KF, "$bpath/$kfile" ) or $fver = "file-not-found" ;
       next KFILE if $fver eq "file-not-found" ;
       my @lines = <KF> ;
       close KF ;
       KFLINE:
       for my $ln (@lines) {
          next KFLINE unless $ln =~ /\$header\s*:.*${kfile}\s*,v\s*(\S.*)\s+\S+\s+Exp\s*\$/i ;
          $fver = $1 ; last KFLINE ;
       }
    } continue {
       $filerev{$kfile} = $fver ;
       print "   $kfile, $fver\n" ;
    }

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

	print "The \@tpr_files is @tpr_files\n";


    # for each tpr file
    foreach my $tpr_file (@tpr_files)
    {
	print "my \$tpr_file is $tpr_file\n";
	# generate the testcases
	my $tpr_status = gentests::generate_tpr($tpr_file);

	print "The \$tpr_status os $tpr_status\n";
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
    printf ("Total CPU seconds for gentests.pl: %.2f secs\n", $end - $start);
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

		print "Your TPR is \@tpr is @tprs\n ";
		foreach (@tprs){
			print "This is \@tprs element $_\n";
		}
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
	elsif ($argv eq '-prefix_name')
	{
	    $PREFIX_NAME = pop(@args);
	}
	elsif ($argv eq '-repbranch')
	{
	    $REPBRANCH = pop(@args);
	}
	elsif ($argv eq '-regen_keep_mod')
	{
	    $KEEP_MODULE_NAME = 1;
	}
	elsif ($argv eq '-keep_existing_tests')
	{
	    $KEEP_EXISTING_TESTS = 1;
	}
	elsif ($argv eq '-remove_all')
	{
	    $REMOVE_ALL = 1;
	}
	elsif ($argv eq '-use_filename')
	{
	    $USE_FILENAME = 1;
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
        -remove_all :    remove all existing testcases in a module directory
		-use_filename
Examples:
        gentests.pl -f my_gentests.ini
        gentests.pl -fv run_bitgen 0 -fv BM BM_VLOG -fv COREGEN_OPTION '-i coregen.ini'
EOF

    exit 1;
}
