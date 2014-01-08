package gentests;


##############################################################################
#
# Author        : Christophe Brotelande (brotelan@xilinx.com)
#
# Maintained by : David Roth (droth@xilinx.com)
#
# Purpose       : Generate testcases for IP verification from tpr file
#
# Runs on Platforms [X]NT [X]Solaris [X]Linux []Others:
#
#
##############################################################################


BEGIN
{
    print "load gentests module...\n";
}

use FastGen2;
use cgdata;
use ReadMeFile;
use ipint_cfg;

use File::Path;
use File::Copy;
use NCopy;
use XML::DOM;


##DOC
#
# sub generate_tpr(<tpr_filename>)
#
# This opens and parses a .tpr file, calling CreateTest each time it comes upon
# an end statement which generates a test. CreateTest is not defined in this
# library.
#
##DOCEND

#-----------------------------------------------------------------------------
sub generate_tpr
#-----------------------------------------------------------------------------
{
    my ($tpr_file) = @_;
    my $RET_CODE = 7;
    my $SUB_NAME = "generate_tpr";

    # start the timer
    my $start = (times)[0];

    #-------------------------------------------------------------------------
    # GLOBAL VARIABLES
    #-------------------------------------------------------------------------
    # the number of tests calculated so far
    local $NO_OF_TESTS = 0;

    # the number of unique tests calculated, needed for correct XML counts
    local $NO_OF_NEW_TESTS = 0;

    # this gets set to true once the dir has been deleted.
    local $RM_EXISTING_TESTS_DONE = 0;

    # priority of all testcases related to a whole TPR
    local $GLOBAL_PRIORITY;
    # priority of all testcases in a begin/end block
    local $LOCAL_PRIORITY;

    local %VHT_PARAM = ();
    # a hash that stores the type of each parameter
    local %VHT_TYPE = ();

    # this keeps a track of every flow option which has been set in a tpr file, so they can
    # be unset again.
    local %GLOBAL_FLOWOPTS = ();
    # any comments that are associated with a flow option
    local %GLOBAL_FLOWOPTS_COMMENTS = ();

    # @TESTBENCHFILES contains a list of .vhd files which are to be modified to generate
    # testbench vhd files. This is set to "tb_{MODULNAME}".
    local @TESTBENCHFILES= ();
    local @TESTPACK= ();
    local %TESTPACK_VARS = ();

    # testpacks that need to be parameterised
    local @PARAM_TESTPACK = ();
    local @LOCAL_PARAM_TESTPACK = ();

    # testbench configuration files
    local @TB_CONF_FILES = ();
    local @LOCAL_TB_CONF_FILES = ();

    # extra libraries that need to be vmapped into the flow
    local @EXTRA_LIBRARIES = ();

    # This array will contain a list of files that will be copied in the test case
    # Those files needs to be located with the TPR file.
    local @COPYFILES=();
    # this array is the same as @COPYFILE, except that it is always local to a begin/end block
    local @LOCAL_COPYFILES=();

    # This array will contain a list of directories that will be copied in the test case
    # Those files needs to be located with the TPR file.
    local @COPYDIRS=();
    # this array is the same as @COPYDIR, except that it is always local to a begin/end block
    local @LOCAL_COPYDIRS=();

    # array of perl modules that contain perl code that will be called from within the tpr file.
    local @PERLMODULES=();
    # this is a list of all perl modules that are used in a gentests run.  It is used so that we can
    # check that no two TPR files use the same module name in a gentests run.  This is an issue because
    # if a perl module is loaded in perl, it can't be unloaded again.
    local @UNIVERSAL_PERMODULES=();

    #This array will contains all the different input variable names in the sequential order of the tpr file.
    #We need this array to evalute the variable values in the sequential order of the tpr file.
    #This array will be initialise for every begin-end block.
    local $VARIABLENB = 0;
    local @TEST_VARHASH = ();

    #This array will containt all INPUT names.  Needed to keep track of what is an input and what is not in VHT_PARAM
    local @INPUT_ARRAY=();

    #This array will containt all VARIABLE names, these are like INPUT declaration but they won't be written
    #in the core.bat file. VARIABLE are like  Intermidiate variables.
    local @VARIABLE_ARRAY=();

    # a list of all the coe files to generate
    local %COE_FILE_NAMES = ();
    # a list of all the export files to generate
    local %EXPORT_FILE_NAMES = ();
    # a list of all the mif files to generate
    local %MIF_FILE_NAMES = ();
    # a list of all paramaters related to a file
    local %GENERIC_FILE_PARAMS = ();

    # This array will contain all rules related to the core. This allow the user to handle for example family
    # dependency on core parameters (if the parameter create_rpm is true then virtex2 should not be used !)
    # each rule will be evaluated at test case generation and the information (conclusion) stored in the core.bat
    # file as comment, then used at run time by the script getArch.pl !!
    local @RULES_ARRAY=();

    local @SIM_OPTIONS=();

    # This hash is a list of environment variables that are set are written to a text file
    # to be set later in the flow
    local %ENV_VAR=();

    # evey filename that's truncated, needs to have a number added to the end to make sure it's
    # unique
    local $POST_TRUNC = 0;

    # Default values for variables
    local $iteration_no = 0;
    local $STATE='INIT'; #$STATE is used to decide whether we are within a BEGIN/END loop or not

    local $MODULE = 'unset';
    local $CORE_VERSION ='1.0';
    local $CORE_VENDOR = 'xlnx';

    local $XCO_CASE_SENSITIVE = 0 ;
    local $RANDTESTNUM = 2;
    local $IPFLOW = 'unset';
    local $MODULENAME = 'unset';
    local $FILENAME = 'unset';
    local $TCASE_PRIORITY = 'unset';

    # the local flow option values
    local %LOCAL_FLOWOPTS;
    local %LOCAL_FLOWOPTS_COMMENTS;

    # all details that will be written to the XML file
    local %XML_DETAILS;

    # all the array that need to be added to the flow files
    local %EXTRA_ARRAYS;

    # the filename of the current TPR
    local $CURRENT_TPR_FILE = $tpr_file;
    $CURRENT_TPR_FILE =~ s/^.*(\/|\\)//;

    # whether or not the lock file has already been set
    local $LOCK_SET = 0;

    # initialize the line counter
    local $LINE_NO = 0;

    # only need to check settings first time round
    local $REQUIRED_SETTINGS_CHECKED = 0;

    if (!-e $tpr_file)
    {
	err('--', "ERROR: $tpr_file does not exist", $RET_CODE, $SUB_NAME);
    }

    # check to see the filename is valid
    if ($tpr_file !~ /^(.*[\/\\])?[a-zA-Z0-9_\-]+\.(tpr|in)$/)
    {
	err('--', "$tpr_file is not a valid TPR filename.  Only alphanumerics, _ and - are allowed", $RET_CODE, $SUB_NAME);
    }

    local $TPRFILEDIR = $tpr_file;
    $TPRFILEDIR =~ s/([\/\\])?[a-zA-Z0-9_\-]+\.(tpr|in)//i;

    # if the dir name is blank, make it a . for current dir
    if ($TPRFILEDIR =~ /^\s*$/)
    {
	$TPRFILEDIR = ".";
    }

    local $COMMON_DATA_DIR = "";

    open(TPR, $tpr_file) || err('--',"TPR file $tpr_file cannot be opened.", , $RET_CODE, $SUB_NAME);

    print "Reading tpr file: $tpr_file\n";

    foreach (<TPR>)
    {
	$LINE_NO++;
	chomp();
	ReadTPRLine($_);
    }
    close TPR;


    # copy all the data files to a common directory
    write_common_data_files();

    # stop the timer
    my $end = (times)[0];

    printf ("Generated %d testcases in %.2f secs\n", $NO_OF_TESTS, $end - $start);
    print "\n\t\t\t********************\n\n";

    # write out an XML file detailing everything which was generated
    WriteXmlDetails();

    # get the repository branch
    my $repBranch = getRepBranch();

    # remove the lock
    gentests_lock("$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME/$CURRENT_TPR_FILE", 0);

    # tpr generated without problems
    return 0;
}



##DOC
#
# sub ReadTPRLine(<line>)
#
# This reads the string <line> and matches it against the different
# TPR file entries and applies it.
#
# NOTE:- All main pattern matching lines use capitals to make reading easier.
# All finite options are converted into lower case to make things easier.
#
##DOCEND

sub ReadTPRLine
{
     my ($line) = @_;
     my $common = 0;

     # strip all leading and ending white space to make matching easier
     $line =~ s/^\s+//g;
     $line =~ s/\s+$//g;

     # strip spaces from either side of the first = to make matching easier
     $line =~ s/\s*\=\s*/\=/;

     # We will allow # comments part way along lines, tough we won't tell anyone!.
     # If we come across one, just substitute it out and continue.
     # If this causes difficulty (ie someone want to use #'s in their files), just comment out
     if     ($line =~ /^\s*$/i)
     {
	  #It's a whitespace, so ignore it.
	  $common = 1;
     }

     elsif  ($line =~ /^#/)
     {
	  #It's a comment. The substitution above makes this obselete, but we will include it just incase.
	  $common = 1;
     }

     elsif  ($line =~ /^--/)
     {
	  $common = 1;
	  #It's a comment.
     }

     elsif  ($line =~ /^TESTBENCHFILES=(.*)$/i)
     {
	  my $temp = $1;
	  $temp =~ s/(\s+)//g;
	  @TESTBENCHFILES = InterpretFilenames($temp);

	  push @{$EXTRA_ARRAYS{'VHD_TBs'}}, @TESTBENCHFILES;

	  $main::DEBUG && print ("$LINE_NO:TESTBENCHFILES = @TESTBENCHFILES\n");
	  $common = 1;
     }

    elsif  ($line =~ /^RANDTESTNUM=(.*)$/i)
    {
      $RANDTESTNUM = $1;
      $main::DEBUG && print ("$LINE_NO:RANDTESTNUM = $RANDTESTNUM\n");
      $common = 1;
    }

    elsif  ($line =~ /^MODULE=(.*)$/i)
    {
      $MODULE = $1;
      $main::DEBUG && print ("$LINE_NO:MODULE = $MODULE\n");
      $common = 1;
    }

    elsif  ($line =~ /^CORE_VERSION=(.*)$/i)
    {
      $CORE_VERSION = $1;
      $main::DEBUG && print ("$LINE_NO:CORE_VERSION = $CORE_VERSION\n");
      $common = 1;
    }

    elsif  ($line =~ /^XCO_CASE_SENSITIVE=(.*)$/i)
    {
      $XCO_CASE_SENSITIVE = $1 =~ /on/i ? 1 : 0 ;
      my $logival = $XCO_CASE_SENSITIVE ? 'true (on)' : 'false (off)' ;
      $main::DEBUG && print ("$LINE_NO:CORE_VERSION = ${logival}\n");
      $common = 1;
    }

    elsif  ($line =~ /^CORE_VENDOR=(.*)$/i)
    {
      $CORE_VENDOR = $1;
      $main::DEBUG && print ("$LINE_NO:CORE_VENDOR = $CORE_VENDOR\n");
      $common = 1;
    }

    elsif ($line =~ /^SIM_OPTIONS=(.*)$/i)
    {
	push @SIM_OPTIONS, $1;
	$main::DEBUG && print ("$LINE_NO:SIM_OPTIONS = $1\n");
	$common = 1;
    }

    elsif ($STATE eq 'INIT' && $common != 1)
    {

    if ($line =~ /^flowoption\s+(\w+)=(.*)$/i)
    {
	 my $flowopt_name = uc($1);
	 my $flowopt_val = $2;

	 # anything after a # is a comment
	 my $comment;
	 ($flowopt_val, $comment) = split /#/, $flowopt_val;
	 $comment =~ s/^\s+//;
	 $comment =~ s/\s+$//;

	 $GLOBAL_FLOWOPTS{$flowopt_name} = $flowopt_val;
	 $GLOBAL_FLOWOPTS_COMMENTS{$flowopt_name} = $comment;

	 print "TPR Flow Option: $flowopt_name = $flowopt_val # $comment\n";
    }

    elsif ($line =~ /^priority\s*=\s*(\d+)\s*$/i)
    {
	 my $priority = $1;

	 if ($priority !~ /[1-3]/)
	 {
	      err($LINE_NO, "Priority $priority is not valid.  Only 1-3 allowed values.", 10);
	 }
	 else
	 {
	      $GLOBAL_PRIORITY = $priority;
	 }
    }

    elsif ($line =~ /^setenv\s+(\w+)=(.*)$/i)
    {
	 # env vars are case sensitive, so don't upper case them!
#	 my $env_name = uc($1);
	 my $env_name = $1;
	 my $env_val = $2;

	 $ENV_VAR{$env_name} = $env_val;
    }

    elsif  ($line =~ /^MODULE_NAME=(.*)$/i)
    {
      $MODULENAME= $1;
      $MODULENAME =~ s/\s*//g;

      $main::DEBUG && print("$LINE_NO:MODULENAME = $MODULENAME\n");
    }

    elsif  ($line =~ /^RULE\s*(.+\?.+)$/i)
    {
      push (@RULES_ARRAY,$1);
      $main::DEBUG && print("$LINE_NO:TPR rule = @RULES_ARRAY\n");
    }

    elsif  ($line =~ /^COPYFILES=(.+)$/i)
    {
      $temp = $1;
      $temp =~ s/(\s+)//g;
      @COPYFILES = InterpretFilenames($temp);
      $main::DEBUG && print("$LINE_NO:Copy files = @COPYFILES\n");
    }

    elsif  ($line =~ /^COPYDIRS=(.+)$/i)
    {
      $temp = $1;
      $temp =~ s/(\s+)//g;
      @COPYDIRS = InterpretFilenames($temp);
      $main::DEBUG && print("$LINE_NO:Copy dirs = @COPYDIRS\n");
    }

    elsif  ($line =~ /^WHATTODO=(.*)$/i)
    {
	my $whattodo = "\L$1";
	$whattodo =~ s/\s*$//;

	$IPFLOW = cgdata::getIPflow(lc $whattodo);

	$main::DEBUG && print ("$LINE_NO:WHATTODO = $whattodo\n");
    }

    elsif ($line =~ /^PERLMODULE=(.*)$/i)
    {
	 my $temp = $1;
	 $temp =~ s/(\s+)//g;
	 @PERLMODULES = InterpretFilenames($temp);

	 # check that a perl module hasn't already been used
	 foreach my $new_module (@PERLMODULES)
	 {
	      foreach my $existing_module (@UNIVERSAL_PERLMODULES)
	      {
		   if ($new_module eq $existing_module)
		   {
			err($LINE_NO, "There are two TPR files with the same perl module name.  This is not allowed.  One of the modules must be renamed.", 10);
		   }
	      }
	 }

	 # keep track of all perl modules that used
	 foreach (@PERLMODULES)
	 {
	      push @UNIVERSAL_PERLMODULES, $_;
	 }

	 $main::DEBUG && print("$LINE_NO:Perl Modules = @PERLMODULES\n");
    }

     elsif  ($line =~ /^TB_CONF_FILES=(.*)$/i)
     {
	  my $temp = $1;
	  $temp =~ s/\s+//g;

	  my $no_to_use = -1;
	  if ($temp =~ s/{(\d+)}//)
	  {
	      $no_to_use = $1;
	      $main::DEBUG && print ("$LINE_NO:TB_CONF_FILES using $no_to_use random TB_CONF files\n");
	  }

	  my @all = InterpretFilenames($temp);

	  if ($no_to_use == -1)
	  {
	      @TB_CONF_FILES = @all;
	  }
	  else
	  {
	      @TB_CONF_FILES = select_n_random_elements($no_to_use, @all);
	  }

	  $main::DEBUG && print ("$LINE_NO:TB_CONF_FILES = @TB_CONF_FILES\n");
	  $common = 1;
     }

    elsif  ($line =~ /^TESTPACK=(.*)$/i)
    {
      my $temp = $1;
      $temp =~ s/(\s+)//g;
      @TESTPACK = InterpretFilenames($temp);
      $main::DEBUG && print ("$LINE_NO:TESTPACK = @TESTPACK\n");
      $common = 1;
    }

    elsif  ($line =~ /^PARAMETERISE=(.*)$/i)
    {
      my $temp = $1;
      $temp =~ s/(\s+)//g;
      @PARAM_TESTPACK = InterpretFilenames($temp);
      $main::DEBUG && print ("$LINE_NO:TESTPACK = @PARAM_TESTPACK\n");
      $common = 1;
    }

    elsif  ($line =~ /^EXTRA_LIBRARIES=(.*)$/i)
    {
      my $temp = $1;
      @EXTRA_LIBRARIES = split /\s*,\s*/, $temp;
      push @{$EXTRA_ARRAYS{'EXTRA_LIBS'}}, @EXTRA_LIBRARIES;
      $main::DEBUG && print ("$LINE_NO:EXTRA_LIBRARIES = @EXTRA_LIBRARIES\n");
      $common = 1;
    }

    elsif ($line =~ /^BEGIN/i)
    {
      $STATE eq 'INIT' || &err($LINE_NO,"Nested BEGIN/END statements are not allowed.",10);
      $main::DEBUG && print ("BEGIN\n");
      $STATE = 'CASE';

      # check all the required setting are correct before generating first set of tests
      # should not happen hear, but recursion is not our friend!
      if (!$REQUIRED_SETTINGS_CHECKED)
      {
	  check_required_settings();
	  $REQUIRED_SETTINGS_CHECKED = 1;
      }
    }

    elsif ($line =~ /^END$/i)
    {
      &err($LINE_NO,"END without BEGIN",10);
    }

    elsif  ($line =~ /^STIMULUS=(.*)$/i)
    {
	warning($LINE_NO, "STIMULUS no longer used");
    }
    elsif  ($line =~ /^SIMULATE=(.*)$/i)
    {
	warning($LINE_NO, "SIMULATE no longer used");
    }

    elsif  ($line =~ /^HasOptionalPins=(.*)$/i)
    {
	warning($LINE_NO, "HasOptionalPins no longer used");
    }
    elsif  ($line =~ /^compvhd=(.*)$/i)
    {
	warning($LINE_NO, "compvhd no longer used");
    }
    else
    {
	warning($LINE_NO, "Unknown tpr entry: $line");
    }
  }
  # Within a BEGIN/END loop we only allow filename and input statements
  # Don't do a substitution on whitespace because input staements can have 2 parameter names
  # which must be supported even if we never use them.
  elsif ($STATE eq 'CASE' && $common != 1)
  {

       if ($line =~ /^FILENAME=(.*)$/i)
       {
	    $FILENAME=$1;
	    $FILENAME=~ s/\s*//g;

	    if ($main::REGENERATE_NAME ne "unset")
	    {
		$FILENAME = $main::REGENERATE_NAME;

		if (length($main::REGENERATE_NAME) > 35)
		{
		      warning ($LINE_NO, "filename $FILENAME must be less than 35 characters.  Truncating");

		      # first remove all vowels and underscores, and see how long it is after that
		      $FILENAME =~ s/[aeiou_]//gi;

		      if (length($FILENAME) > 35)
		      {
			   # it's still too long, so get more drastic!
			   # use the first 28 characters, and add some unique numbers to the end
			   $FILENAME = substr($FILENAME, 0, 28);
			   $FILENAME = $FILENAME . $POST_TRUNC;
			   $POST_TRUNC++;
		      }
		}
	    }
	    else
	    {
		 # the filename should now be less than 40 chars, so make sure the
		 # input is less than 30 chars to allow some scope for us to add stuff
		 if (length($FILENAME) > 30)
		 {
		      my $old_filename = $FILENAME;
		      warning ($LINE_NO, "filename $old_filename must be less than 30 characters.  Truncating");

		      # first remove all vowels and underscores, and see how long it is after that
		      $FILENAME =~ s/[aeiou_]//gi;
		      if (length($FILENAME) > 30)
		      {
			   # it's still too long, so get more drastic!
			   # use the first 28 characters, and add some unique numbers to the end
			   $FILENAME = substr($FILENAME, 0, 28);
			   $FILENAME = $FILENAME . $POST_TRUNC;
			   $POST_TRUNC++;
		      }
		 }

		 # now we have a testcase name less than 30, add a random 5 digit number to the end
		 $FILENAME = $FILENAME . (10_000 + int rand 90_000);
	    }

	    $main::DEBUG && print ("FILENAME set to $FILENAME\n");
       }


       elsif ($line =~ /^COE_FILE\s*\%(\w+)\s*=\s*(.*)$/i)
       {
	    my $key = $1;
	    my $value = $2;
	    $value =~ s/\s*//;

	    if (exists $COE_FILE_NAMES{$key})
	    {
		 warning($LINE_NO, "$key has already been defined\n");
	    }

	    $COE_FILE_NAMES{$key} = $value;

	    $main::DEBUG && print ("COE_FILE $key = $value\n");
       }

       elsif ($line =~ /^EXPORT_FILE\s*\%(\w+)\s*=\s*(.*)$/i)
       {
	    my $key = $1;
	    my $value = $2;
	    $value =~ s/\s*//;

	    if (exists $EXPORT_FILE_NAMES{$key})
	    {
		 warning($LINE_NO, "$key has already been defined\n");
	    }

	    $EXPORT_FILE_NAMES{$key} = $value;

	    $main::DEBUG && print ("EXPORT_FILE $key = $value\n");
       }

       elsif ($line =~ /^(float|int|string)?\s*MIF_FILE\s*[\$\%](\w+)\s*=\s*(.*)$/i)
       {
	    my $type = lc($1);
            my $casesens_name = $2 ;
	    my $param_name = lc($casesens_name);
	    my $param_vals = $3;

	    # check the type
	    if (!$type)
	    {
		 $type = "int";
	    }
	    elsif (($type ne "int") and ($type ne "float") and ($type ne "string"))
	    {
		 err($LINE_NO, "$type is an unknown type", 10);
	    }

	    if ($type ne "string")
	    {
		 $param_vals = lc($param_vals);
		 $param_vals =~ s/\s*//g;
	    }

	    # if the param has already been defined, but NOT in a mif file, flag a warning
	    if (!(exists $MIF_FILE_NAMES{$param_name}) && ($VHT_PARAM{$param_name}[0] != ''))
	    {
		 warning ($LINE_NO,"this parameter $param_name has been declared twice in the same begin/end block.");
	    }

	    $MIF_FILE_NAMES{$param_name} = $param_name . ".mif";

	    $TEST_VARHASH[$VARIABLENB]{casesens_name} = $casesens_name ;
	    $TEST_VARHASH[$VARIABLENB]{parameter_name} = $param_name;
	    $TEST_VARHASH[$VARIABLENB]{line_number} = $LINE_NO;
	    $VARIABLENB = $VARIABLENB + 1;
	    $VHT_TYPE{$param_name} = $type;

	    # split the ; seperated list
	    foreach my $point (split (/;/, $param_vals))
	    {
		 push @{$VHT_PARAM{$param_name}}, $point;
	    }

	    push @{$GENERIC_FILE_PARAMS{$param_name}}, $param_name;

	    $main::DEBUG && print ("MIF_FILE($VHT_TYPE{$param_name}): $param_name = $param_vals\n");
       }

       elsif ($line =~ /^(float|int|string)?\s*INPUT\s*([^=]+)=(.*)$/i)
       {
	    my $type = lc($1);
	    my $param_names = $2;
	    my $param_vals = $3;

	    # check the type
	    if (!$type)
	    {
		 $type = "int";
	    }
	    elsif (($type ne "int") and ($type ne "float") and ($type ne "string"))
	    {
		 err($LINE_NO, "$type is an unknown type", 10);
	    }

	    if ($type ne "string")
	    {
		 $param_vals =~ s/\s*//g;
		 $param_vals = $XCO_CASE_SENSITIVE ? lc_rhs($param_vals) : lc($param_vals)  ;
	    }

	    foreach my $param (split(/\s+/, $param_names))
	    {
		 $param=~s/^\$//;
		 $TEST_VARHASH[$VARIABLENB]{casesens_name}=$param;
		 $param=lc ($param);
		 $TEST_VARHASH[$VARIABLENB]{parameter_name}=$param;
		 $TEST_VARHASH[$VARIABLENB]{line_number}=$LINE_NO;
		 $VARIABLENB = $VARIABLENB + 1;
		 if ($VHT_PARAM{$param}[0] != '')
		 {
		      warning ($LINE_NO,"this parameter $param has been declared twice in the same begin/end block.");
		 }

		 $VHT_PARAM{$param}[0] = $param_vals;
		 push (@INPUT_ARRAY,$param);
		 $VHT_TYPE{$param} = $type;

		 # if the paramater is a coefficient_file, then add it to the hash
		 if ($param eq "coefficient_file")
		 {
		      $COE_FILE_NAMES{'coefficient_file'} = $param_vals;
		      $VHT_TYPE{$param} = "string";
		 }

		 $main::DEBUG && print ("INPUT($VHT_TYPE{$param}): $param = $param_vals\n");
	    }
       }

       elsif ($line =~ /^(float|int|string)?\s*VARIABLE\s*([^=]+)=(.*)$/i)
       {
	    my $type = lc($1);
	    my $param_names = $2;
	    my $param_vals = $3;

	    # check the type
	    if (!$type)
	    {
		 $type = "int";
	    }
	    elsif (($type ne "int") and ($type ne "float") and ($type ne "string"))
	    {
		 err($LINE_NO, "$type is an unknown type", 10);
	    }

	    if ($type ne "string")
	    {
		 $param_vals =~ s/\s*//g;
		 $param_vals = $XCO_CASE_SENSITIVE ? lc_rhs($param_vals) : lc($param_vals)  ;
	    }

	    foreach my $param (split(/\s+/, $param_names))
	    {
		 $param=~s/^\$//;
		 $param=lc ($param);
		 $TEST_VARHASH[$VARIABLENB]{parameter_name}=$param;
		 $TEST_VARHASH[$VARIABLENB]{line_number}=$LINE_NO;
		 $VARIABLENB = $VARIABLENB + 1;
		 if ($VHT_PARAM{$param}[0] != '')
		 {
		      warning ($LINE_NO,"this variable $param has been declared twice in the same begin/end block.");
		 }

		 $VHT_PARAM{$param}[0] = $param_vals;
		 push (@VARIABLE_ARRAY,$param);

		 $VHT_TYPE{$param} = $type;

		 $main::DEBUG && print ("VARIABLE($VHT_TYPE{$param}): $param = $param_vals\n");
	    }
       }

       elsif ($line =~ /^(float|int|string)?\s*COE_INPUT\s*\$(\w+)\s*=\s*(.*)$/i)
       {
#	    warning ('--', "The coe_input function is depreciated.");

	    my $type = lc($1);
            my $casesens_name = $2 ;
	    my $param_name = lc($casesens_name);
	    my $param_vals = $3;

	    # check the type
	    if (!$type)
	    {
		 $type = "int";
	    }
	    elsif (($type ne "int") and ($type ne "float") and ($type ne "string"))
	    {
		 err($LINE_NO, "$type is an unknown type", 10);
	    }

	    if ($type ne "string")
	    {
		 $param_vals = lc($param_vals);
		 $param_vals =~ s/\s*//g;
	    }

	    $TEST_VARHASH[$VARIABLENB]{casesens_name} = $casesens_name ;
	    $TEST_VARHASH[$VARIABLENB]{parameter_name} = $param_name;
	    $TEST_VARHASH[$VARIABLENB]{line_number} = $LINE_NO;
	    $VARIABLENB = $VARIABLENB + 1;
	    $VHT_TYPE{$param_name} = $type;

	    # split the ; seperated list
	    foreach my $point (split (/;/, $param_vals))
	    {
		 push @{$VHT_PARAM{$param_name}}, $point;
	    }

	    push @{$GENERIC_FILE_PARAMS{'coefficient_file'}}, $param_name;

	    $main::DEBUG && print ("COE_INPUT($VHT_TYPE{$param_name}): $param_name = $param_vals\n");
       }

       # this is for flowoptions that are local to the begin/end block
       elsif ($line =~ /^flowoption\s+(\w+)=(.*)$/i)
       {
	    my $flowopt_name = uc($1);
	    my $flowopt_val = $2;

	    # anything after a # is a comment
	    my $comment;
	    ($flowopt_val, $comment) = split /#/, $flowopt_val;
	    $comment =~ s/^\s+//;
	    $comment =~ s/\s+$//;

	    $LOCAL_FLOWOPTS{$flowopt_name} = $flowopt_val;
	    $LOCAL_FLOWOPTS_COMMENTS{$flowopt_name} = $comment;
       }

       elsif ($line =~ /^priority\s*=\s*(\d+)\s*$/i)
       {
	    my $priority = $1;

	    if ($priority !~ /[1-3]/)
	    {
		 err($LINE_NO, "Priority $priority is not valid.  Only 1-3 allowed values.", 10);
	    }
	    else
	    {
		 $LOCAL_PRIORITY = $priority;
	    }
       }

       # this is for copyfiles local to the begin/end block
       elsif ($line =~ /^COPYFILES=(.+)$/i)
       {
	    my $temp = $1;
	    $temp =~ s/(\s+)//g;
	    @LOCAL_COPYFILES = InterpretFilenames($temp);
	    $main::DEBUG && print("$LINE_NO:local copy files = @LOCAL_COPYFILES\n");
       }

       # this is for copydirs local to the begin/end block
       elsif ($line =~ /^COPYDIRS=(.+)$/i)
       {
	    my $temp = $1;
	    $temp =~ s/(\s+)//g;
	    @LOCAL_COPYDIRS = InterpretFilenames($temp);
	    $main::DEBUG && print("$LINE_NO:local copy dirs = @LOCAL_COPYDIRS\n");
       }

       # this is for testpacks local to the begin/end block
       elsif ($line =~ /^TESTPACK\s+\$(\w+)\s*=\s*(.*)$/i)
       {
	    my $testpack_var = $1;
	    my $testpacks = $2;
	    @{$TESTPACK_VARS{$testpack_var}} = InterpretFilenames($testpacks);
	    $main::DEBUG && print("$LINE_NO:local testpack vars = @{$TESTPACK_VARS{$testpack_var}}\n");
       }

       elsif  ($line =~ /^PARAMETERISE=(.*)$/i)
       {
	    my $temp = $1;
	    $temp =~ s/(\s+)//g;
	    @LOCAL_PARAM_TESTPACK = InterpretFilenames($temp);
	    $main::DEBUG && print ("$LINE_NO:local TESTPACK = @LOCAL_PARAM_TESTPACK\n");
       }

       elsif  ($line =~ /^TB_CONF_FILES=(.*)$/i)
       {
	   my $temp = $1;
	   $temp =~ s/\s+//g;

	   my $no_to_use = -1;
	   if ($temp =~ s/{(\d+)}//)
	   {
	       $no_to_use = $1;
	       $main::DEBUG && print ("$LINE_NO:local TB_CONF_FILES using $no_to_use random TB_CONF files\n");
	   }

	   my @all = InterpretFilenames($temp);

	   if ($no_to_use == -1)
	   {
	       @LOCAL_TB_CONF_FILES = @all;
	   }
	   else
	   {
	       @LOCAL_TB_CONF_FILES = select_n_random_elements($no_to_use, @all);
	   }

	   $main::DEBUG && print ("$LINE_NO:local TB_CONF_FILES = @LOCAL_TB_CONF_FILES\n");
       }

       # a variable which names the file to write the data to
       elsif ($line =~ /(float|int|string)?\s*\%(\w+)\s*(\$\w+)?\s*=(.*)/i)
       {
	    my $type = lc($1);
	    my $variable_filename = $2;
	    my $param_name = lc($3);
	    my $param_vals = $4;

	    $param_name =~ s/^\$//;

	    # check the type
	    if (!$type)
	    {
		 $type = "int";
	    }
	    elsif (($type ne "int") and ($type ne "float") and ($type ne "string"))
	    {
		 err($LINE_NO, "$type is an unknown type", 10);
	    }

	    if ($type ne "string")
	    {
		 $param_vals = lc($param_vals);
		 $param_vals =~ s/\s*//g;
	    }

	    # check a filename has been defined for this variable
	    my $found = 0;
	    if (exists $COE_FILE_NAMES{$variable_filename})
	    {
		 $found = 1;
	    }
	    elsif (exists $EXPORT_FILE_NAMES{$variable_filename})
	    {
		 $found = 1;
	    }

	    if (!$found)
	    {
		 err ($LINE_NO, "variable filename $variable_filename has had no file associated with it.", 10);
	    }

	    # the param value needs to be unique
	    if ($param_name eq "")
	    {
		 my $rand = (10_000 + int rand 90_000);
		 $param_name = "A_GENTESTS_NULL_PARAM" . "_" . $variable_filename . "_" . $param_vals . "_" . $rand;
	    }

	    $TEST_VARHASH[$VARIABLENB]{parameter_name} = $variable_filename."_FH_".$param_name;
	    $TEST_VARHASH[$VARIABLENB]{line_number} = $LINE_NO;
	    $VARIABLENB = $VARIABLENB + 1;
	    $VHT_TYPE{$variable_filename."_FH_".$param_name} = $type;

 	    # split the ; seperated list if not a string
	    if ($type eq "string")
	    {
		 push @{$VHT_PARAM{$variable_filename."_FH_".$param_name}}, $param_vals;
	    }
	    else
	    {
		 foreach my $point (split (/;/, $param_vals))
		 {
		      push @{$VHT_PARAM{$variable_filename."_FH_".$param_name}}, $point;
		 }
	    }

	    push @{$GENERIC_FILE_PARAMS{$variable_filename}}, $variable_filename."_FH_".$param_name;
	    $main::DEBUG && print ("VARIABLE FILE ($VHT_TYPE{$param_name}): $param_name = $param_vals\n");
       }

       elsif ($line =~ /END/i)
       {
	    $STATE eq 'CASE' || &err($LINE_NO,"END without BEGIN",10);
	    $FILENAME eq 'unset' && &err($LINE_NO,"BEGIN/END loop with no filename declaration\n",10);
	    local $TESTCASESNB = 0;

	    # this is probably not the best place to check for these values being set, as they
	    # only need to be checked one, instead of at every begin/end block.
	    # But with the current program flow, it is the most non intrusive place.
	    if ($IPFLOW eq 'unset')
	    {
		 err('--', "The WHATTODO option must be specified\n", 10);
	    }
	    # network flow specific check
	    # Don't perform this for netIP2test, I don't want to force people to have to provide TBP files
	    # when they're only running demo simulation.
	    elsif ($IPFLOW eq 'netIPtest')
	    {
		 if ((@TB_CONF_FILES + @LOCAL_TB_CONF_FILES) == 0)
		 {
		      err('--', "Must specify at least one tb_conf_files in the tpr.", 10);
		 }
	    }

	    my $repBranch = getRepBranch();

	    # create the repository if it doesn't exist
	    if (!-d "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME")
	    {
		 mkpath (["$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME"],0,0777) or
		      err ('--',"ERROR: cannot create the directory $main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME: $!",2);
	    }

	    # create a lock if there hasn't been
	    # one already set in this session
	    if (!$LOCK_SET)
	    {
		 gentests_lock("$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME/$CURRENT_TPR_FILE", 1);
	    }

	    my $xml_file = "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME/$CURRENT_TPR_FILE";
	    $xml_file =~ s/\.(in|tpr)/\.xml/i;

	    # this needs to be done here, as the IPFLOW env var needs to be set before it will work
	    if (!$RM_EXISTING_TESTS_DONE && (($GLOBAL_FLOWOPTS{'REGENERATED'} != 1) && ($main::UNIVERSAL_FLOWOPTS{'REGENERATED'} != 1)))
	    {
		my $tcase_root = "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME";

		if ($main::REMOVE_ALL)
		{
 		    print "Deleting all testcases in $tcase_root\n";
		    rmtree([$tcase_root]) or err('--', "Could not delete directory $tcase_root", 10);
		    # need to re-create the common files directory
		    mkpath([$COMMON_DATA_DIR]) or err('--', "Cannot create the dir $COMMON_DATA_DIR: $!", 2);
		}
		elsif (-e $xml_file)
		{
		      # read in the XML file to get a list of testcases to delete
		      my $parser = new XML::DOM::Parser;
		      my $doc = $parser->parsefile($xml_file);

		      print "Deleting old testcases for $CURRENT_TPR_FILE\n";
		      my $tcase_root = "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME";

		      my $total_count = 0;
		      for $priority_elem ($doc->getElementsByTagName("priority"))
		      {
			   my $priority_count = 0;
			   for $family_elem ($priority_elem->getElementsByTagName("family"))
			   {
				my $family = $family_elem->getAttributeNode("name")->getValue;

				my $family_count = 0;
				for my $tcase_elem ($family_elem->getElementsByTagName("tcase"))
				{
				     my $tcase = $tcase_elem->getAttributeNode("name")->getValue;
				     rmtree("$tcase_root/$family/$tcase", 0, 0) or err('--', "Could not delete directory $tcase_root/$family/$tcase", 10);
				     $family_elem->removeChild($tcase_elem);
				     $family_count++;
				}
				# update the tcase count
				$priority_count += $family_count;
				$family_count -= $family_elem->getAttributeNode("tcaseCount")->getValue;
				$family_elem->setAttribute("tcaseCount", $family_count);
			   }
			   # update the priority count
			   $total_count += $priority_count;
			   $priority_count -= $priority_elem->getAttributeNode("tcaseCount")->getValue;
			   $priority_elem->setAttribute("tcaseCount", $priority_count);
		      }
		      # update the total count
		      my $doc_element = $doc->getDocumentElement();
		      $total_count -= $doc_element->getAttributeNode("tcaseCount")->getValue;
		      $doc_element->setAttribute("tcaseCount", $total_count);

		      $doc->printToFile($xml_file);
		      print "done\n";
		      $doc->dispose;
		 }
		 $RM_EXISTING_TESTS_DONE = 1;
	    }

	    # calculate parameters value and testcases
	    if (($main::NO_TO_CALC == -1) || ($NO_OF_TESTS < $main::NO_TO_CALC))
	    {
		 print ("\tCreating Testcases for the block $FILENAME...\n");

		 # print out the flowoptions that have been set
		 foreach my $fo (keys %LOCAL_FLOWOPTS)
		 {
		      print "\t\tBEGIN/END Flow Option: $fo = $LOCAL_FLOWOPTS{$fo} # $LOCAL_FLOWOPTS_COMMENTS{$fo}\n";
		 }

		 # a number of functions have been depreciated.  Gentests should print
		 # a warning saying this, but only once per begin/end block, so keep a check
		 local $GENDATA_WARNING = 0;
		 local $COEFILE_WARNING = 0;

		 # do the real work!
		 CreateTest();

		 $GENDATA_WARNING = 0;
		 $COEFILE_WARNING = 0;

		 printf ("\tGenerated $TESTCASESNB testcases\n\n");
	    }

	    # unset the priority of the begin/end block
 	    undef $LOCAL_PRIORITY;

	    @TEST_VARHASH = ();
	    @INPUT_ARRAY = ();
	    @VARIABLE_ARRAY = ();
	    @LOCAL_COPYFILES = ();
	    @LOCAL_COPYDIRS = ();
	    @LOCAL_PARAM_TESTPACK = ();
	    %TESTPACK_VARS = ();
	    %COE_FILE_NAMES = ();
	    %EXPORT_FILE_NAMES = ();
	    %MIF_FILE_NAMES = ();
	    %GENERIC_FILE_PARAMS = ();
	    $VARIABLENB = 0;
	    $STATE='INIT';
	    $FILENAME = 'unset';
	    $TCASE_PRIORITY = 'unset';
	    $main::REGENERATE_NAME = 'unset';
	    %VHT_PARAM = ();	# blank all values in VHT_PARAM for the next begin/end block
	    %VHT_TYPE = ();     # blank all values in VHT_TYPE for the next begin/end block
       }

       else
       {
	    warning($LINE_NO, "Unknown tpr entry: $line");
       }
  }

  else
  {
    &err($LINE_NO,"Don't know whether I'm in CASE or INIT.",10);
  }
}

##DOC
#
# sub interpret_filenames(<filelist>)
#
# This takes a string of filenames, seperated by commas, and turns them into an
# array which is checked to make sure they all exist.
#
##DOCEND

sub InterpretFilenames
{
     my @files = split(/\s*,\s*/, $_[0]);
     my @expanded_files;

     # first go through all the files, and append the tpr directory to the filename,
     # and make sure all the slashes are right for each platform
     if ($^O =~ /^MSWin/)
     {
	  foreach my $file (@files)
	  {
	       $file = $TPRFILEDIR."\\$file";
	       $file =~ s/\//\\/g;
	  }
     }
     else
     {
	  foreach my $file (@files)
	  {
	       $file = $TPRFILEDIR."/$file";
	       $file =~ s/\\/\//g;
	  }
     }

     # now check that every file exists, and expand any wildcards
     foreach my $file (@files)
     {
	  # leave filenames which have $'s in them, as they
	  # will be expanded later
	  if ($file =~ /\$/)
	  {
	       push (@expanded_files, $file);
	  }
	  # expand any wildcards given
	  elsif ($file =~ /\*/)
	  {
	       foreach (glob $file)
	       {
		    push (@expanded_files, $_);
	       }
	  }
	  # otherwise check the files exists
	  elsif (-r $file)
	  {
	       push (@expanded_files, $file);
	  }
	  else
	  {
	       err($LINE_NO, "Could not find the file $file", 1);
	  }
     }
     return @expanded_files;
}


##DOC
#
# sub err (<string>)
#
# This function produces an error message composed of the following:-
#
# <tt>ERROR: line[$CURRENT_LINE_NO]\t<string>\n
#
# It then exits with a return value of 1 as default or the specify.
# Also prints out the calling routine name if specified.
#
##DOCEND

#-----------------------------------------------------------------------------
sub err
#-----------------------------------------------------------------------------
{
    my ($line_no, $error_message, $exit_value, $calling_sub) = @_;
    print "\n\nERROR ";
    $main::DEBUG && $calling_sub && print "in gentests::$calling_sub\t";
    print "TPR line[$line_no]\t$error_message\n\n";

    # write out the XML details, so we know what happened
    WriteXmlDetails();

    # remove the lock
    if ($LOCK_SET)
    {
	my $repBranch = getRepBranch();
	gentests_lock("$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME/$CURRENT_TPR_FILE", 0);
    }

    exit $exit_value;
}


sub warning
{
     my ($line_no, $warning_message) = @_;
     print "Warning: TPR line\[$line_no\]\t$warning_message\n";
}


##DOC
#
# sub CreateTest
#
# CreateTest is a recurssive sub-routine which administrate tests generation, sorting out parameterised
# values before calling write_test to do the actual testcase creation. The sub-routine will take care of
# evaluating RAND function or equations before to create the test case.
# CreateTest call itself for each value of the same parameter.
#
##DOCEND
sub CreateTest
{
     my %SAVED_VHT_PARAM;

     # copy the VHT_PARAM hash to a new backup hash
     foreach my $vht_key (keys %VHT_PARAM)
     {
	  foreach my $vht_i (0..$#{$VHT_PARAM{$vht_key}})
	  {
	       $SAVED_VHT_PARAM{$vht_key}[$vht_i] = $VHT_PARAM{$vht_key}[$vht_i];
	  }
     }

     # NOTE: the name of this variable must not be changed as other modules (FastGen) depend on it!!!
     $CURRENT_LINE_NUMBER = 0;
     my $counter = 0;
     my $ThisIsARecursiveCase = 0;

     for ($counter = 0;$counter<@TEST_VARHASH;$counter++)
     {
	  my $key = $TEST_VARHASH[$counter]{parameter_name};
	  $CURRENT_LINE_NUMBER = $TEST_VARHASH[$counter]{line_number};
	  my @vals;

	  if (($VHT_PARAM{$key}[0] =~ /,/ || $VHT_PARAM{$key}[0] =~ /^\[/i) && ($VHT_TYPE{$key} ne "string"))
	  {
	       # We are going to create an array with the different values of the parameter
	       # with &GenRandom if we have to deal with a random function, or just a split if it is a list.
	       # and call CreateTest again to deal with the following input statement(following input parameter)

	       # If it is a list of value we have to deal with, then
	       if ($VHT_PARAM{$key}[0] =~ /,/ &&
		   $VHT_PARAM{$key}[0] !~ /^\[rand:range:/i &&
		   $VHT_PARAM{$key}[0] !~ /^\[list/i &&
		   $VHT_PARAM{$key}[0] !~ /^\[.+\?/i) {
		    my @tmp_vals = split(/\s*,\s*/, $VHT_PARAM{$key}[0]);
		    my $array_elem = 0;
		    foreach (@tmp_vals)
		    {
			 $vals[$array_elem][0] = $_;
			 $array_elem++;
		    }
	       }

	       # new vector function, which depreciates the GenData and CoeFile functions
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[VECTOR:.*\]$/i)
	       {
		    @vals = &GenVector($VHT_PARAM{$key}[0], $VHT_TYPE{$key});
	       }

	       # If it is a random function that we have to deal with, then
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[RAND:.*\]({\d+})?$/i)
	       {
		    # pass the key here, as GenRandom make use of VHT_PARAM
		    @vals = &GenRandom($key);
	       }

	       # if it is a list+condition function
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[LIST.*\]$/i)
	       {
		    # pass the key here, as ListFunction make use of VHT_PARAM
		    @vals = &ListFunction($key);
	       }

	       # if it is a conversion function
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[Conv:.*\]$/i)
	       {
		    # one element is only ever returned
		    $vals[0][0] = &ConversionFunctions($VHT_PARAM{$key}[0]);
	       }

	       # if it is a width function
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[Width:.*\]$/i)
	       {
		    # one element is only ever returned
		    $vals[0][0] = &Width($VHT_PARAM{$key}[0]);
	       }

	       # if it is a if then else condition
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[.+\?.+:.+\]$/i)
	       {
		    # one element is only ever returned
		    $vals[0][0] = &IfThenElseFunction($VHT_PARAM{$key}[0]);
	       }

	       # if it is a perl routine to call
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[CALLPERL:.*\]$/i)
	       {
		    @vals = &CallPerl($VHT_PARAM{$key}[0]);
	       }

	       # THIS FUNCTION IS DEPRECIATED, USE GenVector
	       # if it is a gendata function.
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[GENDATA:.*\]$/i)
	       {
		    @vals = &GenData_depreciated($VHT_PARAM{$key}[0], $VHT_TYPE{$key});
	       }
	       # THIS FUNCTION IS DEPRECIATED, USE GenVector
	       # if it is a create coe file function
	       elsif ($VHT_PARAM{$key}[0] =~ /^\[CoeFile:.*\]$/i)
	       {
		    @vals = &CreateCoeFile_depreciated($VHT_PARAM{$key}[0], $VHT_TYPE{$key});
	       }
	       else
	       {
		    &err($CURRENT_LINE_NUMBER,"Unknown Value of function $VHT_PARAM{$key}[0] for the Variable $key", 10);
	       }

	       $ThisIsARecursiveCase = 1;
	       for $ind (0..$#vals)
	       {
		    $VHT_PARAM{$key} = $vals[$ind];
		    $iteration_no++;
		    $iteration_no > $main::IT_MAX && &err($CURRENT_LINE_NUMBER,"Iteration number in recursive loop exceded $main::IT_MAX. Please check .tpr file",20);
		    if (($main::NO_TO_CALC == -1) || ($NO_OF_TESTS < $main::NO_TO_CALC))
		    {
			 &CreateTest();
		    }
		    $iteration_no--;
	       }
	       last;
	  }
	  #We evaluate the value of the varaible if it's a parametrised variable by others variables
	  # ex : Port_Width = Address_Width ^ 13
	  if ($VHT_TYPE{$key} eq "string")
	  {
	       # just expand variables manually.  Need to do it this way,
	       # as going through CalcValue would make it considerable more
	       # complicated

	       # find all variables
	       my $line;
	       foreach my $word (split (/\s/, $VHT_PARAM{$key}[0]))
	       {
		    # if there is an escape character, just remove it
		    # and don't let any other processing happen on it
		    if ($word =~ s/^\\//)
		    {
			 # nop
		    }
		    # expand any variables
		    elsif ($word =~ /\$/)
		    {
			while ($word =~ m/\$\*?\{?(\w+)\}?/g)
			{
			    my $var = $1;

			    my $tmp_var;
			    foreach my $i (0..$#{$VHT_PARAM{$var}})
			    {
				my $v = $VHT_PARAM{$var}[$i];

				# remove any radix type from the number
				if ($v =~ /^b[01UX]+$/)
				{
				    $v =~ s/^b//ig;
				}
				elsif ($v =~ /^ox[0-7]+$/i)
				{
				    $v =~ s/^ox//ig;
				}
				# if the value is an hexadecimal nb get rid of the 'hx' in front of it
				elsif ($v =~ /^hx[0-9ABCDEFUX]+$/i)
				{
				    $v =~ s/^hx//ig;
				}

				if ($i < $#{$VHT_PARAM{$var}})
				{
				    $tmp_var .= "$v, ";
				}
				else
				{
				    $tmp_var .= "$v";
				}
			    }
			    $word =~ s/\$\*?\{?$var\}?/$tmp_var/;
			}
		    }
		    $line .= $word . " ";
	       }
	       # string the final space which is added by the code above
	       $line =~ s/\s$//;
	       $VHT_PARAM{$key}[0] = $line;
	  }
	  else
	  {
	       $VHT_PARAM{$key}[0] = &CalcValue($VHT_PARAM{$key}[0]);
	  }
     }

     # We've done the evalations and recursively called ourselves. Now for the "Simple" case.
     # Every parameters have now a value evaluated.
     if (! $ThisIsARecursiveCase)
     {
	  $main::DEBUG_OUT && print ("\nFor the testcase $FILENAME the core parameters are: ");

	  foreach $element (keys %VHT_PARAM)
	  {
	       $main::DEBUG_OUT && print "\n$element-> ";

	       # VHT_PARM is a hash of arrays, so parse each elements individually
	       foreach my $elem_cnt (0..$#{$VHT_PARAM{$element}})
	       {
		    # if it's a string don't touch it
		    if ($VHT_TYPE{$element} eq "string")
		    {
			 $main::DEBUG_OUT && print ("$VHT_PARAM{$element}[$elem_cnt] ");
			 next;
		    }

		    # if the value is an binary nb get rid of the 'b' in front of it
		    if ($VHT_PARAM{$element}[$elem_cnt] =~ /^b[01UX]+$/)
		    {
			if ($IPFLOW =~ /^EDK\w+test$/i)
			{
			    $VHT_PARAM{$element}[$elem_cnt] =~ s/^b/0b/ig;
			}
			else
			{
			    $VHT_PARAM{$element}[$elem_cnt] =~ s/^b//ig;
			}
		    }
		    # if the value is an octal nb get rid of the 'ox' in front of it
		    if ($VHT_PARAM{$element}[$elem_cnt] =~ /^ox[0-7]+$/)
		    {
			if ($IPFLOW =~ /^EDK\w+test$/i)
			{
			    $VHT_PARAM{$element}[$elem_cnt] =~ s/^ox/0/ig;
			}
			else
			{
			    $VHT_PARAM{$element}[$elem_cnt] =~ s/^ox//ig;
			}
		    }

		    # if the value is an hexadecimal nb get rid of the 'hx' in front of it
		    if ($VHT_PARAM{$element}[$elem_cnt] =~ /^hx[0-9ABCDEFUX]+$/i)
		    {
			if ($IPFLOW =~ /^EDK\w+test$/i)
			{
			    $VHT_PARAM{$element}[$elem_cnt] =~ s/^hx/0x/ig;
			}
			else
			{
			    $VHT_PARAM{$element}[$elem_cnt] =~ s/^hx//ig;
			}
		    }

		    # if the paramater is an int, truncate it
		    if ($VHT_TYPE{$element} eq "int")
		    {
			 # if it's a coefficient_file, don't strip everything after the .
 			 if ($element ne "coefficient_file")
 			 {
			      $VHT_PARAM{$element}[$elem_cnt] =~ s/\..*$//;
 			 }
		    }

		    # if a + sign is present remove it
		    # + sign are not always supported, in .coe file for example.
		    $VHT_PARAM{$element}[$elem_cnt] =~ s/\+//g;

		    $main::DEBUG_OUT && print ("$VHT_PARAM{$element}[$elem_cnt] ");
	       }
	  }

	  if ($main::UNIVERSAL_PRIORITY)
	  {
	       $TCASE_PRIORITY = $main::UNIVERSAL_PRIORITY;
	  }
	  elsif ($LOCAL_PRIORITY)
	  {
	       $TCASE_PRIORITY = $LOCAL_PRIORITY;
	  }
	  elsif ($GLOBAL_PRIORITY)
	  {
	       $TCASE_PRIORITY = $GLOBAL_PRIORITY;
	  }
	  else
	  {
	       $TCASE_PRIORITY = $main::DEFAULT_PRIORITY;
	  }

	  # OK, we now have all our data in %VHT_PARAM. We now want to create test
	  write_test();

	  # only allowed to generate 1000 test in one begin/end block.  Primarily to keep the appended
	  # number to max 3 digits, but it's also bad practice!
	  if ($TESTCASESNB >= 1000)
	  {
	       err ($CURRENT_LINE_NUMBER,"can only generate 1000 testcases in a single begin/end block.",10);
	  }

	  $NO_OF_TESTS++;
	  $TESTCASESNB++;
     }

     # probably not needed, but wipe VHT_PARAM before restoring just in case
     undef %VHT_PARAM;

     # restore the old paramaters
     foreach my $vht_key (keys %SAVED_VHT_PARAM)
     {
	  foreach my $vht_i (0..$#{$SAVED_VHT_PARAM{$vht_key}})
	  {
	       $VHT_PARAM{$vht_key}[$vht_i] = $SAVED_VHT_PARAM{$vht_key}[$vht_i];
	  }
     }
}



##DOC
#
# sub CalcValue(<formula>)
#
#The sub routine CalcValue is used to evaluate the expression $value by using the value of each parameters, and to calculate it.
#This subroutine is able to calculate as an example that kind of expression : (((Address_Width/2)+(Depth))-(Data_Width*2))
#
##DOCEND


sub CalcValue
{
  my ($value) = @_;

  # First step is to replace every parameter by its value
  while ($value =~ /\$([a-z0-9_]+)/)
  {
       my $var = $1;
      # we need to make sure that the parameter is correctly defined
      if (!$VHT_PARAM{$1})
      {
	  &err($CURRENT_LINE_NUMBER,"the \$$1 parameter value is not defined !!\n\t\$$1 cannot be replaced by its value in the expression: $value\n\tCheck the parameter's spelling or the statement order in the tpr file.",10);
      }

      $value =~ s/\$([a-z0-9_]+)/$VHT_PARAM{$1}[0]/ig;
  }

  if ($value =~ /[\(\)\=\<\>\!\|\&\*\+\-\%\/]+/ && $value !~ /^[\+-]\d+$/  && $value !~ /;/)
  {
    # before to evaluate this equation, we need to translate every binary and hexadecimal numbers in decimal.
    # the matching might need to be improved !!!!

    while ($value =~ /(hx[0-9abcdefABCDEF]+)/i)
    {
      my $decimal_value=0;

      $value=$`.HEXADECIMAL2DECIMAL.$';

      $decimal_value=FastGen2::HextoDec($1);

      $value =~ s/HEXADECIMAL2DECIMAL/$decimal_value/;
    }

    while ($value =~ /(ox[0-7]+)/i)
    {
      my $decimal_value=0;

      $value=$`.OCTAL2DECIMAL.$';

      $decimal_value=FastGen2::OcttoDec($1);

      $value =~ s/OCTAL2DECIMAL/$decimal_value/;
    }

    while ($value =~ /(b[01]+)/i)
    {
      my $decimal_value=0;

      $value=$`.BINARY2DECIMAL.$';

      $decimal_value=FastGen2::BintoDec($1);

      $value =~ s/BINARY2DECIMAL/$decimal_value/;
    }
    #eval the decimal equation

    $value= &eval_formula($value);
  }
  return $value;
}


##DOC
#
# sub eval_formula(formula)
#
#
##DOCEND


sub eval_formula
{
  my ($Formula)=@_;

  while ($Formula=~/\(/ )
  {
    #print ("loop eval_formula : $Formula\n");

    # some shortcuts in order to gain some CPU time

    if ( $Formula =~ /^1\|\|\(.*\)$/ )
    {
      $Formula=1;
      last;
    }

    if ( $Formula =~ /^0\&\&\(.*\)$/ )
    {
      $Formula=0;
      last;
    }

    # first, we need to evaluate (calculate) the KeyWord functions such as log or int.

    while ($Formula=~ /(log|int)\s*\(/i )
    {
      my $find=$';
      my $KeyWord=$1;
      $Formula=$`;

      my ($funct_attribute,$remain)=&KeyWordFunctionAttribute($find);
      $funct_attribute=~s/\)$//g;
      $funct_attribute=&CalcValue($funct_attribute);

      $main::DEBUG && print ("Evaluation of a KeyFunction $KeyWord with this attribute $funct_attribute...\n");

      if ($KeyWord=~/log/i)
      {
	   # log is not supported here yet, as it can result in floating point values
#        $funct_attribute = log($funct_attribute);
	   err($CURRENT_LINE_NUMBER, "The log function is not supported at present.\nUse the [WIDTH:x] function\n", 12);
      }
      elsif ($KeyWord=~/int/i)
      {
        $funct_attribute =~ s/\.\d*$//;
      }
      else { err($CURRENT_LINE_NUMBER,"This Function $KeyWord is not supported yet in the tpr syntax!",12); }

      $Formula=$Formula.'('.$funct_attribute.')'.$remain;

      $main::DEBUG && print ("New Formula after KeyFunction $KeyWord evaluation: $Formula\n");
    }

    $_=$Formula;

    $openPar = tr/\(/\(/;
    $closePar = tr/\)/\)/;

    if ($openPar != $closePar)
    {
      err ($CURRENT_LINE_NUMBER, "The formula $Formula is incorrect.", 1);
    }

    # target the first ) in the formula, keep everything after the first ) in $Formula
    /(.*?\))/;
    $Formula='ParBlock'."$'";

    # process the beginning of the formula, before )
    $_=$1;

    # Target the last ( and extract the (.*) block, and keep the rest in $Formula
    /(.*)(\(.*)/;
    $Formula="$1".$Formula;
    $ParBlock=$2;

    #eval the () block
    #print ("calculate $ParBlock, the new formula is $Formula\n");

    if ($ParBlock =~ /\((.*[a-zA-Z_]+.*)\)/ && $ParBlock !~ /[{}]/ && $ParBlock !~ /xor/)
    {
    # keep the () because it is a string
    # print "what gets {} : $equation\n";

      $Result = '{'."$1".'}';
    }
    else
    {
    $Result= &myeval ($ParBlock);
    }

    #replace the block by the result of its evaluation
    $Formula=~s/ParBlock/$Result/;
  }

  $Formula=&myeval($Formula);

return $Formula;
}


sub KeyWordFunctionAttribute
{
  my ($equation)=@_;
  my $openbrak=0;
  my $closebrak=0;

  my $infunction='';
  my $remain='';
  my $bool=0;

  my @dicot = split (//,$equation);

  foreach my $charact (@dicot)
  {
    if ($charact =~ /\(/ ) { $openbrak++; }
    elsif ($charact =~ /\)/ ) { $closebrak++; }

    if (!$bool) { $infunction=$infunction.$charact; }
    else { $remain = $remain.$charact; }

    if ($openbrak==$closebrak-1) {$bool=1;}
  }

  return ($infunction,$remain);
}


##DOC
#
# sub eval_formula(formula)
#
# have to deal for each operator !!
# i.e. : = - * / ** < > <= >= == != eq ne
##DOCEND
sub myeval
{
     my ($equation) = @_;

     $main::DEBUG_MYEVAL && print ("DEBUG: formule evaluation : $equation ->");

     $_ = $equation;
     $equation=~ s/\((.*)\)/$1/;
     $equation=~ s/\s*//;

     while ($equation !~ /^[+-]?\d+\.?\d*$/)
     {
	  # float power
	  if ($equation =~ /([+-]?\d+\.\d+)\*\*([+-]?\d+)/)
	  {
	       $equation="$`".'BlockExp'."$'";
	       my $expo=FastGen2::powerFloat($1,$2);
	       $equation=~s/BlockExp/$expo/;
	  }
	  # integer power
	  elsif ($equation =~ /([+-]?\d+)\*\*([+-]?\d+)/)
	  {
	       $equation="$`".'BlockExp'."$'";
	       my $expo=FastGen2::power($1,$2);
	       $equation=~s/BlockExp/$expo/;
	  }
	  # float multiply
	  elsif ($equation =~ /([+-]?\d+\.\d*)\*([+-]?\d+\.?\d*)/ ||
		 $equation =~ /([+-]?\d+\.?\d*)\*([+-]?\d+\.\d*)/)
	  {
	       $equation="$`".'BlockMul'."$'";
	       my $mult=FastGen2::multiplyFloat($1,$2);
	       $equation=~s/BlockMul/$mult/;
	  }
	  # integer multiply
	  elsif ($equation =~ /([+-]?\d+)\*([+-]?\d+)/)
	  {
	       $equation="$`".'BlockMul'."$'";
	       my $mult=FastGen2::multiply($1,$2);
	       $equation=~s/BlockMul/$mult/;
	  }
	  # float divide
	  elsif ($equation =~ /([+-]?\d+\.\d*)\/([+-]?\d+\.?\d*)/ ||
		 $equation =~ /([+-]?\d+\.?\d*)\/([+-]?\d+\.\d*)/)
	  {
	       $equation="$`".'BlockDiv'."$'";
	       my $div=FastGen2::divideFloat($1,$2);
	       $equation=~s/BlockDiv/$div/;
	  }
	  # integer divide
	  elsif ($equation =~ /([+-]?\d+)\/([+-]?\d+)/)
	  {
	       $equation="$`".'BlockDiv'."$'";
	       my $div=FastGen2::divide($1,$2);
	       $equation=~s/BlockDiv/$div/;
	  }
	  # modulus can only ever be int, but float value here
	  # as they'll be caught later on
	  elsif ($equation =~ /([+-]?\d+\.?\d*)%([+-]?\d+\.?\d*)/)
	  {
	       $equation="$`".'ModBlock'."$'";
	       my $Mod=FastGen2::modulus($1,$2);
	       $equation=~s/ModBlock/$Mod/;
	  }
	  # float add
	  elsif ($equation =~ /([+-]?\d+\.\d*)\+([+-]?\d+\.?\d*)/ ||
		 $equation =~ /([+-]?\d+\.?\d*)\+([+-]?\d+\.\d*)/)
	  {
	       $equation="$`".'BlockAdd'."$'";
	       my $add=FastGen2::addFloat($1,$2);
	       $equation=~s/BlockAdd/$add/;
	  }
	  # integer add
	  elsif ($equation =~ /([+-]?\d+)\+([+-]?\d+)/)
	  {
	       $equation="$`".'BlockAdd'."$'";
	       my $add=FastGen2::add($1,$2);
	       $equation=~s/BlockAdd/$add/;
	  }
	  # float subtract
	  elsif ($equation =~ /([+-]?\d+\.\d*)-([+-]?\d+\.?\d*)/ ||
		 $equation =~ /([+-]?\d+\.?\d*)-([+-]?\d+\.\d*)/)
	  {
	       $equation="$`".'BlockSub'."$'";
	       my $subs=FastGen2::subtractFloat($1,$2);
	       $equation=~s/BlockSub/$subs/;
	  }
	  # integer subtract
	  elsif ($equation =~ /([+-]?\d+)-([+-]?\d+)/)
	  {
	       $equation="$`".'BlockSub'."$'";
	       my $subs=FastGen2::subtract($1,$2);
	       $equation=~s/BlockSub/$subs/;
	  }
	  ###
	  # it does not matter if the following comparison functions
	  # are floats or ints
	  ###
	  elsif ($equation =~ /([+-]?\d+\.?\d*)<([+-]?\d+\.?\d*)/)
	  {
	       $equation="$`".'LESS'."$'";
	       my $less=FastGen2::less_than($1,$2);
	       $equation=~s/LESS/$less/;
	       $main::DEBUG && print ("< : $equation\n");
	  }
	  elsif ($equation =~ /([+-]?\d+\.?\d*)<=([+-]?\d+\.?\d*)/)
	  {
	       $equation="$`".'LESS_OR_EQ'."$'";
	       my $less_or_eq=FastGen2::less_than_or_eq($1,$2);
	       $equation=~s/LESS_OR_EQ/$less_or_eq/;
	       $main::DEBUG && print ("<= : $equation\n");
	  }
	  elsif ($equation =~ /([+-]?\d+\.?\d*)>([+-]?\d+\.?\d*)/)
	  {
	       $equation="$`".'GREATER'."$'";
	       my $greater=FastGen2::greater_than($1,$2);
	       $equation=~s/GREATER/$greater/;
	  }
	  elsif ($equation =~ /([+-]?\d+\.?\d*)>=([+-]?\d+\.?\d*)/)
	  {
	       $equation="$`".'GREATER_OR_EQ'."$'";
	       my $greater_or_eq=FastGen2::greater_than_or_eq($1,$2);
	       $equation=~s/GREATER_OR_EQ/$greater_or_eq/;
	  }
	  elsif ($equation =~ /([+-]?\d+\.?\d*)==([+-]?\d+\.?\d*)/)
	  {
	       $equation="$`".'EQUAL'."$'";
	       my $equal=FastGen2::equal_to($1,$2);
	       $equation=~s/EQUAL/$equal/;
	  }
	  elsif ($equation =~ /([+-]?\d+\.?\d*)!=([+-]?\d+\.?\d*)/)
	  {
	       $equation="$`".'NoEQUAL'."$'";
	       my $not_equal=FastGen2::not_equal_to($1,$2);
	       $equation=~s/NoEQUAL/$not_equal/;
	  }
	  elsif ($equation =~ /\{([0-9a-zA-Z_]+)\}eq\{([0-9a-zA-Z_]+)\}/)
	  {
	       $equation="$`".'EQ'."$'";

	       # we want a eq function case unsensitive

	       my $val1=uc($1);
	       my $val2=uc($2);

	       if (($val1)eq($val2))
	       {
		    $myeval_eq='1';
	       }
	       else
	       {
		    $myeval_eq='0';
	       }

	       $equation=~s/EQ/$myeval_eq/;
	  }

	  elsif ($equation =~ /\{([0-9a-zA-Z_]+)\}ne\{([0-9a-zA-Z_]+)\}/)
	  {
	       $equation="$`".'NE'."$'";

	       # we want a ne function case unsensitive

	       my $val1=uc($1);
	       my $val2=uc($2);

	       if (($val1)ne($val2))
	       {
		    $myeval_ne='1';
	       }
	       else
	       {
		    $myeval_ne='0';
	       }

	       $equation=~s/NE/$myeval_ne/;
	  }

	  elsif ($equation =~ /([+-]?\d+)\s*&&\s*([+-]?\d+)/)
	  {
	       $equation="$`".'AND'."$'";
	       $myeval_and=($1)&&($2);
	       $equation=~s/AND/$myeval_and/;
	  }

	  elsif ($equation =~ /([+-]?\d+)\s*\|\|\s*([+-]?\d+)/)
	  {
	       $equation="$`".'OR'."$'";
	       $myeval_or=($1)||($2);
	       $equation=~s/OR/$myeval_or/;
	  }

	  elsif ($equation =~ /(\d+)\s*xor\s*(\d+)/i)
	  {
	       $equation="$`".'XOR'."$'";

	       if ($1==$2)
	       {
		    $myeval_xor=0;
	       }
	       else
	       {
		    $myeval_xor=1;
	       }
	       # the perl xor function seems to be buggy !!!
	       #$myeval_xor=($1)xor($2);

	       $equation=~s/XOR/$myeval_xor/;
	  }
	  else
	  {
	       err($CURRENT_LINE_NUMBER, "This is not a correct formula: $equation", $RET_CODE, $SUB_NAME);
	  }
     }

     $main::DEBUG_MYEVAL && print (" $equation\n");

     return ($equation);
}


########################################################################################################
#
#			    RANDOM FUNCTIONS (GenVector, GenRandom, ...)
#
########################################################################################################


##DOC
# sub GenVector(<randomfunction>)
#
# routine to generate a list of vectors in any of the valid bases.  This routine depreciates the GenData
# and CreateCoeFile routines, which are kept for the moment to maintain compatibilty with old TPR files
#
##DOCEND

sub GenVector
{
    my ($function, $param_type) = @_;
    my $RET_CODE = 30;
    my $SUB_NAME = "GenVector";
    my @VectorData;
    my $num_args;
    my $u_and_x = 0;

    my $Type;
    my $Symmetry;
    my $Num_Taps;
    my $Min_Value;
    my $Max_Value;
    my $Radix;
    my $Width;
    my $No_Groups = 1;

    $main::DEBUG_VECTOR && print ("\n$SUB_NAME-> Formula: $function");

    # work out the filter type first, to know the format to parse
    if ($function =~ /^\[VECTOR:(.*?):(.*)\]$/i)
    {
	$Type = &CalcValue($1);
    }

    # find the number of arguments parsed to the function
    # just used as a check.
    $num_args = NumParams($function);


    ### NRZ FUNCTION FORMAT ###
    if ($Type =~ /^nrz$/i)
    {
	$main::DEBUG_VECTOR && print ("\n$SUB_NAME-> Function type: $Type");
	if ($num_args == 3 && $function =~ /^\[VECTOR:(.*):(.*):(.*)\]$/i)
	{
	    $Symmetry = $2;
	    $Num_Taps = $3;
	    $Symmetry = &CalcValue($Symmetry);
	    $Num_Taps = &CalcValue($Num_Taps);

	    # these are always the same for NRZ, so no need to make the user input them!
	    $Radix = 2;
	    $Min_Value = 0;
	    $Max_Value = 1;
	    $Width = 1;
	}
	else
	{
	    &err ($CURRENT_LINE_NUMBER, "$function is not properly defined", $RET_CODE, $SUB_NAME);
	}
    }
    ### OTHER FUNCTION FORMAT ###
    elsif ($Type =~ /^(basic|halfband|hilbert_transform|cam)$/i)
    {
	$main::DEBUG_VECTOR && print ("\n$SUB_NAME-> Function type: $Type");
	if ($num_args == 7 && $function =~ /^\[VECTOR:(.*):(.*):(.*):(.*):(.*):(.*):(.*)\]$/i)
	{
	    $Symmetry = $2;
	    $Num_Taps = $3;
	    $Min_Value = $4;
	    $Max_Value = $5;
	    $Radix = $6;
	    $Width = $7;

	    $Symmetry = &CalcValue($Symmetry);
	    $Num_Taps = &CalcValue($Num_Taps);
	    $Min_Value = &CalcValue($Min_Value);
	    $Max_Value = &CalcValue($Max_Value);
	    $Radix = &CalcValue($Radix);
	    $Width = &CalcValue($Width);
	}
	elsif ($num_args == 8 && $function =~ /^\[VECTOR:(.*):(.*):(.*):(.*):(.*):(.*):(.*):(.*)\]$/i)
	{
	    $Symmetry = $2;
	    $Num_Taps = $3;
	    $Min_Value = $4;
	    $Max_Value = $5;
	    $Radix = $6;
	    $Width = $7;
	    $No_Groups = $8;

	    $Symmetry = &CalcValue($Symmetry);
	    $Num_Taps = &CalcValue($Num_Taps);
	    $Min_Value = &CalcValue($Min_Value);
	    $Max_Value = &CalcValue($Max_Value);
	    $Radix = &CalcValue($Radix);
	    $Width = &CalcValue($Width);
	    $No_Groups = &CalcValue($No_Groups);
	}
	else
	{
	    &err($CURRENT_LINE_NUMBER, "$function is not properly defined", $RET_CODE, $SUB_NAME);
	}
    }
    else
    {
	&err($CURRENT_LINE_NUMBER, "$Type is not supported", $RET_CODE, $SUB_NAME);
    }

    $main::DEBUG_VECTOR && print ("\n$SUB_NAME-> Type: $Type Sym: $Symmetry Num_Taps: $Num_Taps Min: $Min_Value Max: $Max_Value Radix: $Radix Width: $Width");

    # calculate the upper limit for the random number
    my $Diff = GenRandRange($Min_Value, $Max_Value, $Radix, $Width, $param_type);

    # we need to know if the number of taps is odd or even
    my $Num_Taps_is = '';
    my $odd_taps = 1;
    if (($Num_Taps/2)==int($Num_Taps/2))
    {
	$odd_taps = 0; # even number of taps
    }

    # if there is symmetry, half the number of taps
    if ($Symmetry =~ /^symmetric$/i || $Symmetry =~ /^negative_symmetric$/i)
    {
	$Num_Taps = int($Num_Taps/2);

	# when using negative symmetry, make sure the negative number is no
	# greater than the positive number, ie -64 to 63 needs to be changed
	# to -63 to 63
	if ($Symmetry =~ /^negative_symmetric$/i)
	{
	    if ($Max_Value + $Min_Value != 0)
	    {
		$Min_Value = -$Max_Value;
		$Diff--;
	    }
	}
    }

    ## Not all the filter types support all the symmetries, so check that the
    ## requested combination is valid

    # cam options
    if ($Type =~ /^cam$/i)
    {
	 if ($Symmetry =~ /^negative_symmetric$/)
	 {
	      &err($CURRENT_LINE_NUMBER, "$Symmetry is not a valid symmetry for cam", $RET_CODE, $SUB_NAME);
	 }
    }

    # Halfband Options
    if ($Type =~ /^halfband$/i)
    {
	if ($odd_taps && int($Num_Taps/2) != $Num_Taps/2)
	{
	    if ($Symmetry !~ /^symmetric|negative_symmetric$/i)
	    {
		&err($CURRENT_LINE_NUMBER, "$Symmetry is not a valid symmetry for Halfband", $RET_CODE, $SUB_NAME);
	    }
	}
	else
	{
	    &err($CURRENT_LINE_NUMBER, "The Halfband accepts only every other odd value (3,7,11,15...) for the Number_of_Taps", $RET_CODE, $SUB_NAME);
	}
    }

    # Hilbert Transform options
    elsif ($Type =~ /^hilbert_transform$/i)
    {
	if ($odd_taps)
	{
	    if ($Symmetry !~ /^negative_symmetric$/i)
	    {
		&err($CURRENT_LINE_NUMBER, "$Symmetry is not a valid symmetry for Hilbert Transform", $RET_CODE, $SUB_NAME);
	    }
	}
	else
	{
	    &err($CURRENT_LINE_NUMBER, "The Hilbert Transform is only valid for odd Number_of_Taps.", $RET_CODE, $SUB_NAME);
	}
    }

    # Finally, generate the data
    for (0..$No_Groups-1)
    {
	my @coef_group = [GenVectorData($Num_Taps, $Diff, $Min_Value, $Radix, $Width, $Symmetry, $Type, $odd_taps, $param_type)];
	foreach $coef (@{$coef_group[0]})
	{
	    push @{$VectorData[0]}, $coef;
	}
    }

    $main::DEBUG_VECTOR && print ("\n$SUB_NAME-> VECTORS: @{$VectorData[0]}");

    return @VectorData;
}


##DOC
#
# sub GenRandom(<randomfunction>)
#
# The subroutine GenRandom generates random values for a parameter.
# It deals with different type of Random generation (integer, boolean,...)
# the return value is an array of $RANDTESTNUM random values chosen in accordance with the type and
# the data (max_value, min_value, formula, width)
#
##DOCEND

sub GenRandom
{
    my ($element) = @_;
    my $RET_CODE = 31;
    my $SUB_NAME = "GenRandom";
    my $function = $VHT_PARAM{$element}[0];

    my @randvalue;
    my $count = 1;

    $main::DEBUG && print ("\n$SUB_NAME-> Function: $function");

    $function =~ s/\s*//g;

    # This is the range random generator(can generate only between the different given elements)
    if ($function =~ /^\[RAND:RANGE:(.*)\]({\d+})?$/i)
    {
	my @word = split (/\s*,\s*/,$1);
	my $formula = '';
	my $indx = 0;
	my $Howmanyrdnb = $2;
	my $LocalRandtestNum = $RANDTESTNUM;

	if ($word[@word-1] =~ /:([^\]]*)$/i)
	{
	    $formula=$1;
	    $word[@word-1] =~s/:([^\]]*)$//;
	}

	$main::DEBUG && print ("range:@word\nformula:$formula\noccurances:$LocalRandtestNum\n");

	$Howmanyrdnb=~ s/[}|{]//g;

	if ($Howmanyrdnb != '')
	{
	    $LocalRandtestNum = $Howmanyrdnb;
	}

	for ($count=0;$count<$LocalRandtestNum;$count++)
	{

	    if ($formula =~ /^\s*$/)
	    {
		$indx = int(rand(@word));
	    }

	    else
	    {
		my $error = 1000;
		my $valid = 0;

		while (! $valid)
		{
		    $error || &err ($CURRENT_LINE_NUMBER,"The formula $formula is too restrictive, The Random value is impossible to generate", $RET_CODE, $SUB_NAME);

		    $valid = $formula;
		    $indx = int(rand(@word));

		    $VHT_PARAM{$element}[0] = &CalcValue($word[$indx]);
		    $valid = &CalcValue ($valid);                     #if the random value matches the formula expression then $formula = 1;
		    $error--;
		}
	    }
	    # only ever the first element.
	    $randvalue[$count][0] = $word[$indx];
	}
    }

    # This is the boolean random generator 0 or 1 TRUE or FALSE
    elsif ($function =~ /^\[RAND:BOOL_([W|N]):(.*)\]({\d+})?$/i)
    {
	my $type = $1;
	my $formule = $2;
	my $Howmanyrdnb = $3;
	my $bool = 0;

	my $LocalRandtestNum=$RANDTESTNUM;

	$Howmanyrdnb=~ s/[}|{]//g;

	if ($Howmanyrdnb != '')
	{
	    $LocalRandtestNum=$Howmanyrdnb;
	}

	for ($count=0;$count<$LocalRandtestNum;$count++)
	{
	    my $error = 1000;
	    my $valid = 0;

	    while (! $valid)
	    {
		$error || &err($CURRENT_LINE_NUMBER, "The formula $formula is too restrictive, The Random Value is impossible to generate", $RET_CODE, $SUB_NAME);

		$bool = int(rand(2));

		$valid = $formule;

		if ($type =~ /w/i)
		{
		    $bool && ($VHT_PARAM{$element}[0] = "TRUE");
		    $bool || ($VHT_PARAM{$element}[0] = "FALSE");
		}
		elsif ($type =~ /n/i)
		{
		     $VHT_PARAM{$element}[0] = $bool;
		}

		$valid = &CalcValue ($valid);                     #if the random value matches the formula expression then $formula = 1;
		$error = $error - 1;
	    }

	    if ($type =~ /w/i)
	    {
		$bool && ($randvalue[$count][0] = "TRUE");
		$bool || ($randvalue[$count][0] = "FALSE");
	    }
	    elsif ($type =~ /n/i)
	    {
		$randvalue[$count][0] = $bool;
	    }
	    else { &err($CURRENT_LINE_NUMBER, "The syntax of this random(boolean) expression is not correct $function", $RET_CODE, $SUB_NAME);}
	}
    }

    # This is the number (dec,bin,hex) random generator
    elsif ($function =~ /^\[RAND:(DEC|INT|HEX|BIN|OCT):([^:]*):([^:]*):([^:]*):?([^\[\]]*)?\]({\d+})?$/i)
    {
	#We evaluate all the parameters of the random command
	my $Radix = $1;
	my $Min_Val = $2;
	my $Max_Val = $3;
	my $formula = $4;
	my $Width = $5;
	my $Howmanyrdnb = $6;
	my $LocalRandtestNum = $RANDTESTNUM;

#	print ("radix:$Radix\nmin:$Min_Val\nmax:$Max_Val\nformule:$formula\nwidth:$Width\nocc:$Howmanyrdnb\n");

	$Howmanyrdnb=~ s/[}|{]//g;

	if ($Howmanyrdnb != '')
	{
	    $LocalRandtestNum=$Howmanyrdnb;
	}

	# calculate the value of min max and width
	$Min_Val = &CalcValue ($Min_Val);
	$Max_Val = &CalcValue ($Max_Val);
	$Width = &CalcValue($Width);
	# make the radix lowercase to match hash table
	$Radix = lc($Radix);

	# if width is not set, set it to -1
	if (!$Width)
	{
	    $Width = -1;
	}

	my $Diff = GenRandRange($Min_Val, $Max_Val, $main::RADIX_TRANS{$Radix}, $Width, $VHT_TYPE{$element});

	# floating point values are only supported with base 10, so
	# make sure that this is the case
	if (($VHT_TYPE{$element} eq "float") && ($main::RADIX_TRANS{$Radix} != 10))
	{
	     err ($CURRENT_LINE_NUMBER, "floating point values can only be base 10.", $RET_CODE, $SUB_NAME);
	}

	# all random numbers are calculated in decimal and then coverted to the required radix, after
	# they have met the condition of the formula
	for ($count=0;$count<$LocalRandtestNum;$count++)
	{
	    #generates a random value, evaluates the formula, and while the formula is false, find an other random value
	    my $error = 1000;
	    my $formeval = 0;

	    while (!$formeval)
	    {
		$error || &err ($CURRENT_LINE_NUMBER, "The formula $formula is too restrictive, The Random Value is impossible to generate", $RET_CODE, $SUB_NAME);

		# generate 1 rand value, in base 10.  Convert it later, after the check
		# against the formula has been done
		($randvalue[$count]) = [FastGen2::GenData(1, $Diff, $Min_Val, 0, $VHT_TYPE{$element})];
		$formeval = $formula;

		$VHT_PARAM{$element}[0] = $randvalue[$count][0];
		$formeval = &CalcValue ($formeval);                     #if the random value matches the formula expression then $formula = 1;
		$error = $error - 1;
	    }

	    # if here, a valid number has been found, so convert it to the required radix
	    if ($RANDIX_TRANS{$Radix} != 10)
	    {
		# randvalue is always [0] as only 1 value is ever generated
		$randvalue[$count][0] = FastGen2::DectoBase($randvalue[$count][0], $main::RADIX_TRANS{$Radix}, $Width);
	    }
	}
    }
    else
    {
	 &err($CURRENT_LINE_NUMBER, "The syntax of this random expression is not correct : $function", $RET_CODE, $SUB_NAME);
    }

    return @randvalue;
}

##DOC
#
# sub ListFunction
#
# This function will select all the valid value of the given list
# in accordance to the given formula
#
##DOCEND

sub ListFunction
{
    my ($element) = @_;
    my $RET_CODE = 32;
    my $SUB_NAME = "ListFunction";
    my $function = $VHT_PARAM{$element}[0];

    $main::DEBUG && print ("\n$SUB_NAME-> Function: $function");

    $function =~ s/\s*//g;
    my @truelist;

    if ($function =~ /^\[LIST:([^:]+):(.*)\]$/i)
    {
	my $equation=$2;
	my @list_elements=split (/,/,$1);

	my $array_elem = 0;
	foreach $item (@list_elements)
	{
	     $VHT_PARAM{$element}[0] = $item;
	    if (&CalcValue ($equation))
	    {
		# this has to be a 2d array for consistency
		$truelist[$array_elem][0] = $item;
		$array_elem++;
	    }
	}
    }
    else
    {
	&err ($CURRENT_LINE_NUMBER, "The syntax of the list function is incorrect. $listfunct", $RET_CODE, $SUB_NAME);
    }

    if (@truelist == 0)
    {
	&err ($CURRENT_LINE_NUMBER, "None of the element of the list is valid (does not match the equation). $listfunct", $RET_CODE, $SUB_NAME);
    }

    return @truelist;
}


##DOC
#
# sub ConversionFunctions
#
##DOCEND

sub ConversionFunctions
{
     my ($function) = @_;
     my $RET_CODE = 33;
     my $SUB_NAME = "ConversionFunctions";
     my $convertednb='';
     my $convtype;
     my $nbtoconv;
     my $Width;
     my $signed;
     my $ret;

     $main::DEBUG && print ("\n$SUB_NAME-> Function: $function");

     if ($function =~ /^\[conv:(dectobin|dectohex):(.*):(.*)\]$/i)
     {
	  $convtype = $1;
	  $nbtoconv = $2;
	  $Width = $3;

	  $nbtoconv = &CalcValue($nbtoconv);
	  $Width = &CalcValue($Width);

	  # Check the width isn't too small for the required number
	  my $max_number = FastGen2::subtract(FastGen2::power(2, $Width), 1);
	  if (FastGen2::greater_than($nbtoconv, $max_number))
	  {
	       &err($CURRENT_LINE_NUMBER, "$Width is not a big enough width for $nbtoconv.", $RET_CODE, $SUB_NAME);
	  }

	  # convert the number
	  if ($convtype =~ /^dectobin$/i)
	  {
	       $ret = FastGen2::DectoBase($nbtoconv, 2, $Width);
	  }
	  elsif ($convtype =~ /^dectohex$/i)
	  {
	       $ret = FastGen2::DectoBase($nbtoconv, 16, $Width);
	  }
     }
     elsif ($function =~ /^\[conv:(bintohex|hextobin):(.*)\]$/i)
     {
	  $convtype = $1;
	  $nbtoconv = $2;

	  $nbtoconv = &CalcValue($nbtoconv);

	  if ($convtype =~ /^bintohex$/i)
	  {
	       $ret = FastGen2::BintoHex($nbtoconv);
	  }
	  elsif ($convtype =~ /^hextobin$/i)
	  {
	       $ret = FastGen2::HextoBin($nbtoconv);
	  }
     }
     elsif ($function =~ /^\[conv:(bintodec|hextodec):(.*):(.*)\]$/i)
     {
	  $convtype = $1;
	  $nbtoconv = $2;
	  $signed = $3;

	  $nbtoconv = &CalcValue($nbtoconv);
	  $signed = &CalcValue($signed);

	  if ($convtype =~ /^bintodec$/i)
	  {
	       $ret = FastGen2::BintoDec($nbtoconv, $signed);
	  }
	  elsif ($convtype =~ /^hextodec$/i)
	  {
	       $ret = FastGen2::HextoDec($nbtoconv, $signed);
	  }
     }
     else
     {
	  &err($CURRENT_LINE_NUMBER, "Error in the Conversion Function, this convertion function is not correct : $function.", $RET_CODE, $SUB_NAME);
     }

     return $ret;
}


##DOC
#
# sub IfThenElseFunction
#
# This function will output a value in accordance to
# to given condition
#
##DOCEND

sub IfThenElseFunction
{
    my ($function) = @_;
    my $RET_CODE = 34;
    my $SUB_NAME = "IfThenElseFunction";
    # the output is a string containing the valid value
    my $ValidValue;

    $main::DEBUG && print ("\n$SUB_NAME-> Function: $function");

    if ($function =~ /^\[(.+)\?(\[.+\]):(.+)\]$/ || $function =~ /^\[(.+)\?([^:]+):(.+)\]$/)
    {
        my $Condition = $1;
        # value to output if the condition is true
        my $TrueValue = $2;
        # value to output if the condition is false
        my $FalseValue = $3;

        $main::DEBUG && print("\n$SUB_NAME-> IF ($Condition) then $TrueValue else $FalseValue\n");

        if (&CalcValue($Condition))
        {
            $ValidValue = $TrueValue;
        }
        else
        {
            $ValidValue = $FalseValue;
        }
    }
    else
    {
        &err ($CURRENT_LINE_NUMBER, "The syntax of the If Then Else statement is not correct, $ifthenelseStat", $RET_CODE, $SUB_NAME);
    }

    return $ValidValue;
}



##DOC
#
# sub Width
#
# This function returns the value of log(x)/log(2) without
# any decimal places.  Always rounding up.
#
##DOCEND

sub Width
{
     my ($function) = @_;
     my $RET_CODE = 35;
     my $SUB_NAME = "Width";
     my $number_points;

     $main::DEBUG && print ("\n$SUB_NAME-> Function: $function");

     if ($function =~ /^\[WIDTH:(.*)\]$/i)
     {
	  $number_points = $1;
	  $number_points = CalcValue($number_points);
     }
     else
     {
	  err($CURRENT_LINE_NUMBER, "$function is not properly defined\n", $RET_CODE, $SUB_NAME);
     }

     # Make sure that the number is a valid integer
     if ($number_points !~ /^[0-9]+$/)
     {
	  err($CURRENT_LINE_NUMBER, "$number_points needs to be an integer\n", $RET_CODE, $SUB_NAME);
     }

     # perform the calculation
     my $width = (log($number_points))/(log(2));

     # check the number wasn't too big
     if ($width eq "Infinity")
     {
	  err($CURRENT_LINE_NUMBER, "$number_points is too big\n", $RET_CODE, $SUB_NAME);
     }

     # if there are any decimal points, round the number up
     if ($width =~ s/\.(.*)$//)
     {
	  $width++;
     }

     return $width;
}


##DOC
#
# sub CallPerl
#
# This function will call a perl module written by the user
# from the tpr file.  It can only return a string
#
##DOCEND
sub CallPerl
{
     my ($function) = @_;
     my $RET_CODE = 36;
     my $SUB_NAME = "CallPerl";

     my $module;
     my $routine;
     my $arguments;
     my @evaluated_arguments;
     my @true_results;

     $main::DEBUG && print ("\n$SUB_NAME-> Function: $function");

     if ($function =~ /^\[CALLPERL:\s*(\w+)\s*:\s*(\w+)\s*(:.*)?\s*\]$/i)
     {
	  $module = $1;
	  $routine = $2;
	  $arguments =  $3;
	  # remove the leading : from the arguments
	  $arguments =~ s/^://;

	  # expand each variable to it's value
	  # and put it in the array of arguments
	  foreach my $var (split /:/, $arguments)
	  {
	      # find all variables in the string and expand them
	      foreach my $match ($var =~ m/\$(\w+)/g)
	      {
		  if (!defined $VHT_PARAM{$match})
		  {
		      err($CURRENT_LINE_NUMBER, "$match used undefined\n", $RET_CODE, $SUB_NAME);
		  }
		  elsif (@{$VHT_PARAM{$match}} > 1)
		  {
		      err($CURRENT_LINE_NUMBER, "can't pass array values into a perl module\n", $RET_CODE, $SUB_NAME);
		  }

		  $var =~ s/\$$match/$VHT_PARAM{$match}[0]/;
	      }

	      # expand any functions if necesary
	      $var = eval('$var');

	      # if there is only one element in the array, put it
	      # in as a scalar
	      push @evaluated_arguments, $var;
	  }
     }
     else
     {
	  err($CURRENT_LINE_NUMBER, "$function is not properly defined\n", $RET_CODE, $SUB_NAME);
     }

     # required so we can call routines which are variables at run time
     # when using strict mode
     no strict 'refs';

     # find the required module in the PERLMODULES array
     foreach my $full_mod_path (@PERLMODULES)
     {
	  # add a require for the module
	  if ($full_mod_path =~ $module)
	  {
	       require $full_mod_path;
	       last;
	  }
     }

     # call the users perl routine
     my @return_values = ($module . "::" . $routine) -> (@evaluated_arguments);

     # internally gentests uses a 2d array for speed, but the for the external perl modules,
     # we keep it 1d, and multiple values are separated by commas.  So this needs
     # be to parsed back to 2d.
     for my $i (0..$#return_values)
     {
	  $true_list[$i] = [split /,/, $return_values[$i]]; # true list is actually a 2d array
     }

     return @true_list;
}



##DOC
#
# This function is depreciated, use GenVector
# all it does now is reformat the function to be compatible with
# GenVector, and then calls it!
#
##DOCEND
sub CreateCoeFile_depreciated
{
    my ($function, $param_type) = @_;
    my $RET_CODE = 90;
    my $SUB_NAME = "CreateCoeFile_depreciated";
    my $vector_format;

    my $ListType;
    my $Symmetry;
    my $Radix;
    my $Min_Value;
    my $Max_Value;
    my $Number_of_Taps;
    my $Width;

    if (!$COEFILE_WARNING)
    {
	 warning ('--', "The CoeFile function is depreciated, use VECTOR instead");
	 $COEFILE_WARNING = 1;
    }



    $main::DEBUG && print ("\n$SUB_NAME-> Function: $function\n");

    # need to evaluate the type of filter so we know which format it is in
    my $filter_type;
    if ($function =~ /^\[CoeFile:(.*?):(.*)\]$/i)
    {
	$filter_type = &CalcValue($1);
    }

    if ($filter_type =~ /(basic|halfband|hilbert_transform)/)
    {
	if ($function =~ /^\[CoeFile:(.*):(.*):(.*):(.*):(.*):(.*):(.*)\]$/i)
	{
	    $ListType=$1;
	    $Symmetry=$2;
	    $Radix=$3;
	    $Min_Value=$4;
	    $Max_Value=$5;
	    $Number_of_Taps=$6;
	    $Width=$7;
	}
	else
	{
	    &err ($CURRENT_LINE_NUMBER, "$function is not properly defined", $RET_CODE, $SUB_NAME);
	}

	$vector_format = "[VECTOR:$ListType:$Symmetry:$Number_of_Taps:$Min_Value:$Max_Value:$Radix:$Width]";
    }
    elsif ($filter_type =~ /nrz/)
    {
	if ($function =~ /^\[CoeFile:(.*):(.*):(.*)\]$/i)
	{
	    $ListType=$1;
	    $Symmetry=$2;
	    $Number_of_Taps=$3;
	}
	else
	{
	    &err ($CURRENT_LINE_NUMBER, "$function is not properly defined", $RET_CODE, $SUB_NAME);
	}

	$vector_format = "[VECTOR:$ListType:$Symmetry:$Number_of_Taps]";
    }
    else
    {
	&err ($CURRENT_LINE_NUMBER, "$filter_type is not a valid filter", $RET_CODE, $SUB_NAME);
    }

    return &GenVector($vector_format, $param_type);
}



##DOC
#
# This function is depreciated, use GenVector
# all it does now is reformat the function to be compatible with
# GenVector, and then calls it!
#
##DOCEND
sub GenData_depreciated
{
    my ($function, $param_type) = @_;
    my $RET_CODE = 91;
    my $SUB_NAME = "GenData_depreciated";
    my $vector_format;

    my $Radix = '';
    my $Min_Value = 0;
    my $Max_Value = 1;
    my $Number_of_Taps = 1;
    my $Width = 1;

    if (!$GENDATA_WARNING)
    {
	 warning ('--', "The GenData function is depreciated, use VECTOR instead");
	 $GENDATA_WARNING = 1;
    }

    $main::DEBUG && print ("\n$SUB_NAME-> Function: $function\n");

    if ($function =~ /^\[GENDATA:(.*):(.*):(.*):(.*):(.*)\]$/i)
    {
	$Radix = $1;
	$Min_Value = $2;
	$Max_Value = $3;
	$Number_of_Taps = $4;
	$Width = $5;
    }
    else
    {
	err ($CURRENT_LINE_NUMBER, "$function is not properly defined.", $RET_CODE, $SUB_NAME);
    }

    # format the string
    $vector_format = "[VECTOR:basic:non_symmetric:$Number_of_Taps:$Min_Value:$Max_Value:$Radix:$Width]";

    return &GenVector($vector_format, $param_type);
}



##DOC
#
# sub write_test
#
# sub write_test checks whether a directory structure exists to put the test into, generating
# it if nessecary, then copies in the appropriate files and edits the testbench file template
# (.vht file) into a testbench .vhd file. It also writes in the core.bat file
#
##DOCEND

sub write_test
{
    my $tcase_name;
    my $family = 'DEFAULT_FAMILY';

    # set the family if defined
    if (my $tmp = get_flow_option("FAMILY"))
    {
	$family = $tmp;
    }

    # if the family is _all, then the familiy directory should be DEFAULT_FAMILY
    # instead of xxx_all.
    my $family_dir;
    if ($family =~ /_all$/ || $family =~ /\+/)
    {
	$family_dir = 'DEFAULT_FAMILY';
    }
    else
    {
	$family_dir = $family;
    }

    # make the testcase name unique
    if (($GLOBAL_FLOWOPTS{'REGENERATED'} == 1) || ($main::UNIVERSAL_FLOWOPTS{'REGENERATED'} == 1))
    {
	$tcase_name = $FILENAME;
    }
    else
    {
	$tcase_name = $FILENAME . "_" . $TESTCASESNB;
    }

    my $repBranch = getRepBranch();
    my $datadir = "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME/$family_dir/$tcase_name/input";

    # make the testcase directory structure
    my $new_testcase = create_tcase_dir($datadir);

    # dump all the data required to require to re-generate the testcase later
    # in a file.
    write_regen_data($datadir, $tcase_name, $MODULE, $CORE_VERSION, $MODULENAME);

    # create batch files which will help the user to run the test case
    # by hand
    write_batch_files($datadir, $tcase_name, $family);

    # create all required COE files
    foreach my $coe_file (keys %COE_FILE_NAMES)
    {
	write_coe_file($datadir, $COE_FILE_NAMES{$coe_file}, @{$GENERIC_FILE_PARAMS{$coe_file}});
    }

    # create all required EXPORT files
    foreach my $export_file (keys %EXPORT_FILE_NAMES)
    {
	write_export_file($datadir, $EXPORT_FILE_NAMES{$export_file}, $export_file, @{$GENERIC_FILE_PARAMS{$export_file}});
    }

    # create all required MIF files
    foreach my $mif_file (keys %MIF_FILE_NAMES)
    {
	my $proj_dir = get_flow_option("PROJ_DIR");
	if ($proj_dir eq "")
	{
	    $proj_dir = "proj";
	}

	write_mif_file("$datadir/$proj_dir/_tmp_", $MIF_FILE_NAMES{$mif_file}, @{$GENERIC_FILE_PARAMS{$mif_file}});
    }

    # Get rid off all the VARIABLE in VHT_PARAM before writeing the core.bat file
    foreach $intervariable (@VARIABLE_ARRAY)
    {
	delete ($VHT_PARAM{$intervariable});
    }

    # write out the paramater files depending on flow
    if ($IPFLOW =~  /^EDK\w+test$/i)
    {
	write_edk($datadir, $MODULE, $CORE_VERSION);
    }
    else
    {
	write_xco($datadir, $tcase_name, $family, $MODULE, $CORE_VERSION);

	# create the core.bat file, identical than testcase.xco
	copy("$datadir/$tcase_name.xco", "$datadir/core.bat") or err('--', "Could not create $datadir/core.bat", 2);
    }

    # write a README file if required
    if ($main::GENERATE_README)
    {
	write_readme($datadir, $tcase_name, $family, $IPFLOW);
    }

    # if the tcase is being  regenerated, copy the ipint.cfg
    if (-e $TPRFILEDIR."/ipint.cfg")
    {
	copy($TPRFILEDIR."/ipint.cfg", "$datadir/ipint.cfg") or err('--', "Could not create $datadir/core.bat", 2);
    }

    my %local_extra_arrays = %EXTRA_ARRAYS;

    # combine the testpacks with the variable testpacks in the
    # correct order
    my @ALL_TESTPACK;
    foreach my $tp (@TESTPACK)
    {
	my $file = $tp;
	# substitue any variable testcases
	if ($file =~ /\$(\w+)/)
	{
	    if (defined $TESTPACK_VARS{$1})
	    {
		push @ALL_TESTPACK, @{$TESTPACK_VARS{$1}};
	    }
	    else
	    {
		err('--', "Testpack variable defined but not initialised", 2)
	    }
	}
	else
	{
	    push @ALL_TESTPACK, $file;
	}
    }
    push @{$local_extra_arrays{'VHDL_TPs'}}, @ALL_TESTPACK;

    foreach my $file (@ALL_TESTPACK)
    {
	my $target_file = $file;
	$target_file =~ s/^(.*)(\/|\\)//;
	copy($file, "$COMMON_DATA_DIR/$target_file");
    }


    # combine all the testpacks that need to be parameterised
    my @ALL_PARAM_TESTPACK;
    push (@ALL_PARAM_TESTPACK, @PARAM_TESTPACK);
    push (@ALL_PARAM_TESTPACK, @LOCAL_PARAM_TESTPACK);
    push @{$local_extra_arrays{'VHDL_PTPs'}}, @ALL_PARAM_TESTPACK;
    foreach my $file (@LOCAL_PARAM_TESTPACK)
    {
	my $target_file = $file;
	$target_file =~ s/^(.*)(\/|\\)//;
	copy($file, "$COMMON_DATA_DIR/$target_file");
    }

    # combine all testbench config files
    my @ALL_CONF_FILES;
    push (@ALL_CONF_FILES, @TB_CONF_FILES);
    push (@ALL_CONF_FILES, @LOCAL_TB_CONF_FILES);
    push @{$local_extra_arrays{'VHD_TBs_CONF'}}, @ALL_CONF_FILES;
    foreach my $file (@LOCAL_TB_CONF_FILES)
    {
	my $target_file = $file;
	$target_file =~ s/^(.*)(\/|\\)//;
	copy($file, "$COMMON_DATA_DIR/$target_file");
    }

    foreach my $datafile (@LOCAL_COPYFILES)
    {
	#copy the file in the testcase
	copy ($datafile, $COMMON_DATA_DIR) or err('--', "Could not copy the file $datafile to $COMMON_DATA_DIR.", 2);
	$main::DEBUG && print ("LOCAL_COPYFILES: file $datafile copied to $COMMON_DATA_DIR.\n");
    }

    foreach my $d (@LOCAL_COPYDIRS)
    {
	# copy the file in the testcase
	if (-d $d)
	{
	    NCopy::copy (\1, $d, $COMMON_DATA_DIR) or err('--', "Could not copy the file $d to $COMMON_DATA_DIR", 2);
	    fix_all_permissions($COMMON_DATA_DIR);
	}
	else
	{
	    # remove the file portion and work
	    # out the target directory
	    my $target_dir;
	    if ($d =~ /(.*)(\/|\\)\S+$/)
	    {
		$target_dir = $1;
		$target_dir =~ s/$TPRFILEDIR(\/|\\)(\.\.)?(\/|\\)?//;
		$target_dir = $COMMON_DATA_DIR."/".$target_dir;
	    }

	    if (!-e $target_dir)
	    {
		mkpath ([$target_dir]) or err('--',"cannont create dir $target_dir: $!", 2);
	    }

	    NCopy::copy (\1, $d, $target_dir) or err('--', "Could not copy the file $d in $target_dir.", 2);
	    fix_all_permissions($target_dir);
	}

	$main::DEBUG && print ("COPYDIRS: file $d copied to $datadir.\n");
    }

    # write all flowoptions to the cfg file
    my $cfg_file = "$datadir/gentests.cfg";
    write_cfg_file($cfg_file, \%main::UNIVERSAL_FLOWOPTS, \%GLOBAL_FLOWOPTS, \%LOCAL_FLOWOPTS, \%local_extra_arrays, \%ENV_VAR);

    # add the details of the testcase to the xml file
    # but not if it's a regenerated testcase that already existed
    # this needs to stay at the end of create_test as nothing should go into this
    # array until the tcase has been created fully without error.
    if ($new_testcase)
    {
	$NO_OF_NEW_TESTS++;
	push @{$XML_DETAILS{$TCASE_PRIORITY}{$family_dir}}, $tcase_name;
    }
}


##DOC
#
# sub GenRandRange
#
# return the highest value that a random number can be
# also check the radix and width are valid
# and that only decimanl numbers have been used
#
##DOCEND
sub GenRandRange
{
     my ($min, $max, $radix, $width, $param_type) = @_;
     my $RET_CODE = 40;
     my $SUB_NAME = "GenRandRange";
     my $diff;

     $main::DEBUG_GNR && print "\n$SUB_NAME-> MIN:$min MAX:$max RADIX:$radix WIDTH:$width ---> ";

     # check that mix, max and width are all decimal numbers
     if ($min !~ /^[+-]?[0-9]+(\.[0-9]+)?$/)
     {
	  err($CURRENT_LINE_NUMBER, "$min is not a valid minimum value.  Only base 10 values allowed.", $RET_CODE, $SUB_NAME);
     }
     if ($max !~ /^[+-]?[0-9]+(\.[0-9]+)?$/)
     {
	  err($CURRENT_LINE_NUMBER, "$max is not a valid max value.  Only base 10 values allowed.", $RET_CODE, $SUB_NAME);
     }
     # -1 is a valid width as it means "no width"
     if (($width !~ /^\+?[0-9]+$/) && ($width != -1))
     {
	  err($CURRENT_LINE_NUMBER, "$width is not a valid width.  Only integer base 10 values allowed.", $RET_CODE, $SUB_NAME);
     }
     # check the radix, if specified
     if (($radix !~ /2|8|10|16/) && ($radix != -1))
     {
	  err($CURRENT_LINE_NUMBER, "$radix is not a valid radix. Only 2,8,10,16 are valid", $RET_CODE, $SUB_NAME);
     }

     # check the width is valid, if specified
     if ($width != -1)
     {
	  if ($width > $main::MAX_WIDTH)
	  {
	       err($CURRENT_LINE_NUMBER, "$width is too big ($main::MAX_WIDTH max).", $RET_CODE, $SUB_NAME);
	  }
	  # check the max number is not bigger than that obtainable with given width
	  # if it is bigger, set it to max width
	  my $upper_rand = FastGen2::power(2, $width);
	  $upper_rand = FastGen2::subtract($upper_rand, 1);
	  if (FastGen2::less_than($upper_rand, $max))
	  {
	       warning($CURRENT_LINE_NUMBER, "The max value ($max) is too big for the width ($width).  Setting max value to 2^$width-1 ($upper_rand)");
	       $max = $upper_rand;
	  }
     }

     # check the min value is not larger than the max value
     if (FastGen2::greater_than($min, $max))
     {
	  err($CURRENT_LINE_NUMBER, "The minumum value ($min) is larger than the max ($max) value.", $RET_CODE, $SUB_NAME);
     }

     if ($param_type eq "float")
     {
	  $diff = FastGen2::subtractFloat($max, $min);
     }
     else
     {
	  $diff = FastGen2::subtract($max, $min);
     }

     $main::DEBUG_GNR && print "DIFF:$diff";

     return $diff;
}

##DOC
#
# sub GenVectorData
#
# Generate a normal list of values in the required radix
# and the required symmetry
#
##DOCEND
sub GenVectorData
{
     my ($num_gen, $diff, $min, $radix, $width, $symmetry, $filter, $odd, $param_type) = @_;
     my $RET_CODE = 41;
     my $SUB_NAME = "GenVectorData";
     my @list;
     my @tmp_list;

     $main::DEBUG_GVD && print "\n$SUB_NAME-> NUM_GEN: $num_gen DIFF: $diff MIN: $min RADIX: $radix SYM: $symmetry FILTER: $filter TYPE: $param_type --> ";


     # floating point values are only supported with base 10, so
     # make sure that this is the case
     if (($param_type eq "float") && ($radix != 10))
     {
	  err ($CURRENT_LINE_NUMBER, "floating point values can only be base 10.", $RET_CODE, $SUB_NAME);
     }

     # the cam function only supports base 2 and 16
     if (($filter =~ /^cam$/) && ($radix !~ /^(2|16)$/))
     {
	  err ($CURRENT_LINE_NUMBER, "cam function must be base 2 or 16.", $RET_CODE, $SUB_NAME);
     }

     # whether to generate a list seperated with 0's or not.
     if ($filter =~ /^basic|nrz$/i)
     {
	  @list = FastGen2::GenData($num_gen, $diff, $min, 0, $param_type);
     }
     elsif ($filter =~ /^halfband|hilbert_transform$/)
     {
	  @list = FastGen2::GenData($num_gen, $diff, $min, 1, $param_type);
     }
     elsif ($filter =~ /^cam$/)
     {
	  @list = FastGen2::GenCamData($num_gen, $diff, $min, $radix, $width);
     }
     else
     {
	  err ($CURRENT_LINE_NUMBER, "$filter is not supported.", $RET_CODE, $SUB_NAME);
     }


     # if non_symmetric, just return the list after base conversion
     if ($symmetry =~ /^non_symmetric$/)
     {
	  if (($radix != 10) && ($filter ne "cam"))
	  {
	       for my $i (0..$#list)
	       {
		    $list[$i] = FastGen2::DectoBase($list[$i], $radix, $width);
	       }
	  }

	  $main::DEBUG_GVD && print "@list";
	  return @list;
     }

     # now create the required symetric list
     @tmp_list = reverse @list;

     # if negative sym, make second half negative
     if ($symmetry =~ /^negative_symmetric$/i)
     {
	  # if nrz, then instead of neg val, make 1=0 and 0=1
	  if ($filter =~ /^nrz$/i)
	  {
	       foreach my $val (@tmp_list)
	       {
		    if ($val == 0)
		    {
			 $val = 1;
		    }
		    elsif ($val == 1)
		    {
			 $val = 0;
		    }
		    else
		    {
			 err($CURRENT_LINE_NUMBER, "$val invalid.  $filter only supports 0 and 1 in the coe list.", $RET_CODE, $SUB_NAME);
		    }
	       }
	  }
	  else
	  {
	       foreach my $val (@tmp_list)
	       {
		    $val = FastGen2::OppSign($val);
	       }
	  }
     }

     # choose the middle value depending on filter type
     if ($odd)
     {
	  if ($filter =~ /^basic|nrz$/i)
	  {
	       # one random value
	       my ($rand_val) = FastGen2::GenData(1, $diff, $min, 0, $param_type);
	       push @list, $rand_val;
	  }
	  elsif ($filter =~ /^hilbert_transform$/)
	  {
	       # just zero
	       push @list, 0;
	  }
	  elsif ($filter =~ /^halfband$/)
	  {
	       my $rand_val = 0;
	       # the middle value can't be zero with halfband
	       do
	       {
		    ($rand_val) = FastGen2::GenData(1, $diff, $min, 0, $param_type);
	       } while ($rand_val == 0);

	       push @list, $rand_val;
	  }
     }

     # join the the two seperate lists
     push @list, @tmp_list;

     # convert to the required base
     if ($radix != 10)
     {
	  for my $i (0..$#list)
	  {
	       $list[$i] = FastGen2::DectoBase($list[$i], $radix, $width);
	  }
     }

     $main::DEBUG_GVD && print "@list";
     return @list;
}

##DOC
# sub number_params(<randomfunction>)
#
# routine to count the number of paramaters that are in a function.  Needed to work 
# work out what type of vector generation is being used.  Can handle nested functions
#
##DOCEND
sub NumParams
{
    my ($text) = @_;
    my $RET_CODE = 42;
    my $SUB_NAME = "NumParams";
    my $count = 0;
    my $inside = 0;

    # strip the fist [ and last ] from the line to ease matching
    $text =~ s/^\s*\[//;
    $text =~ s/\]\s*$//;

    # count the number of :'s while not in a nested function
    while ($text =~ m/(:|\[|\])/g)
    {
	if ($1 =~ /^\[$/) {
	    $inside++;
	}
	elsif ($1 =~ /^\]$/) {
	    $inside--;
	}
	elsif ($1 =~ /^:$/) {
	    if (!$inside){
		$count++;
	    }
	}
    }

    # check the make sure the text is balanced
    if ($inside != 0)
    {
	err($CURRENT_LINE_NUMBER, "function is not balanced", $RET_CODE, $SUB_NAME);
    }

    return $count;
}


#-----------------------------------------------------------------------------
sub getRepBranch
#-----------------------------------------------------------------------------
{
    my $branch = $ENV{'ROMS'};

    $branch =~ s/^.*[\\\/]([^\\\/]+)[\\\/]users[\\\/]att[\\\/]roms[\\\/]?$/$1/;

    if ($branch ne "HEAD")
    {
	$branch =~ s/_?(ROMS)?$//i;
	$branch .= "_TCASE";
    }

    return $branch;
}


#-----------------------------------------------------------------------------
sub create_tcase_dir
#-----------------------------------------------------------------------------
{
    my ($dir) = @_;

    my $new_testcase = 1;

    if (!-d $dir)
    {
	mkpath ([$dir]) or err('--', "Cannot create the directory $dir: $!", 2);
    }
    else
    {
	if (($GLOBAL_FLOWOPTS{'REGENERATED'} == 1) || ($main::UNIVERSAL_FLOWOPTS{'REGENERATED'} == 1))
	{
	    $new_testcase = 0;
	}
	rmtree ([$dir]) or err('--', "Cannot delete the directory $dir: $!", 2);
	mkpath ([$dir]) or err('--', "Cannot create the directory $dir. $!", 2);
    }

    return $new_testcase;
}


#-----------------------------------------------------------------------------
sub write_regen_data
#-----------------------------------------------------------------------------
{
    my ($dir, $tcase, $core_name, $core_version, $module) = @_;

    open FILE, "> $dir/regenerate.in" or err ('--', "Could not open file regen.in for writting: $!\n", 1);

    print FILE "# -*- mode: TPR; -*-\n";
    print FILE "\n# ----------GLOBAL SETTINGS---------- #\n";

    if ($main::KEEP_MODULE_NAME)
    {
	print FILE "module_name = $module\n";
    }
    else
    {
	$core_name =~ s/\W/_/g;
	$core_name = lc $core_name;
	$core_version = lc $core_version;
	print FILE "module_name = $core_name\_v$core_version\n";
    }

    print FILE "module = $MODULE\n";
    print FILE "core_version = $CORE_VERSION\n";
    print FILE "core_vendor = $CORE_VENDOR\n";
    print FILE "whattodo = ", cgdata::getWhattodo($IPFLOW), "\n";

    if (@COPYFILES)
    {
	my $file;

	print FILE "copyfiles = ";

	foreach my $cnt (0..($#COPYFILES-1))
	{
	    $file = $COPYFILES[$cnt];
	    $file =~ s/^.*(\/|\\)//;
	    print FILE "$file,";
	}
	$file = $COPYFILES[$#COPYFILES];
	$file =~ s/^.*(\/|\\)//;

	print FILE "$file\n";
    }

    if (@COPYDIRS)
    {
	my $dir;

	print FILE "copydirs = ";

	foreach my $cnt (0..($#COPYDIRS-1))
	{
	    $dir = $COPYDIRS[$cnt];
	    $dir =~ s/(\/|\\)$//;
	    $dir =~ s/^.*(\/|\\)//;
	    print FILE "$dir,";
	}
	$dir = $COPYDIRS[$#COPYDIRS];
	$dir =~ s/(\/|\\)$//;
	$dir =~ s/^.*(\/|\\)//;

	print FILE "$dir\n";
    }

    print FILE "\n# ----------FLOWOPTIONS---------- #\n";

    print FILE "flowoption REGENERATED = 1\n";

    print FILE "\n# ----------PARAMATERS---------- #\n";

    print FILE "begin\n";
    print FILE "filename = $tcase\n";


    foreach my $key (@INPUT_ARRAY)
    {
	if (!defined $VHT_PARAM{$key}[0])
	{
	    next;
	}

	# this is a hack!  When ther is more than one element, we can't
	# use a comman seperated list as that creates more testcases,
	# so use the string type instead so the rhs doesn't get evalulated
	if (@{$VHT_PARAM{$key}} == 1)
	{
	    if ($key ne "coefficient_file")
	    {
		print FILE "$VHT_TYPE{$key} input \$$key = $VHT_PARAM{$key}[0]\n";
	    }
	}
	else
	{
	    print FILE "string input \$$key = ";

	    foreach my $elem (0..$#{$VHT_PARAM{$key}}-1)
	    {
		print FILE "$VHT_PARAM{$key}[$elem],";
	    }
	    print FILE "$VHT_PARAM{$key}[$#{$VHT_PARAM{$key}}]\n";
	}
    }

    my $iter = 0;
    foreach my $coe_file (keys %COE_FILE_NAMES)
    {
	if (!$GLOBAL_FLOWOPTS{'REGENERATED'} && !$main::UNIVERSAL_FLOWOPTS{'REGENERATED'})
	{
	    print FILE "export_file \%${coe_file}_${iter} = $COE_FILE_NAMES{$coe_file}\n";

	    foreach my $param (0..$#{$GENERIC_FILE_PARAMS{$coe_file}})
	    {
		my $tmp = $GENERIC_FILE_PARAMS{$coe_file}[$param];
		my $var = $tmp;
		$var =~ s/^.*_FH_//;

		print FILE "string \%${coe_file}_${iter} \$$var = ";
		foreach my $elem (0..$#{$VHT_PARAM{$tmp}}-1)
		{
		    print FILE "$VHT_PARAM{$tmp}[$elem] ";
		}
		print FILE "$VHT_PARAM{$tmp}[$#{$VHT_PARAM{$tmp}}] ;\n";
	    }
	}
    }

    foreach my $export_file (keys %EXPORT_FILE_NAMES)
    {
	print FILE "export_file \%$export_file = $EXPORT_FILE_NAMES{$export_file}\n";

	foreach my $param (0..$#{$GENERIC_FILE_PARAMS{$export_file}})
	{
	    my $tmp = $GENERIC_FILE_PARAMS{$export_file}[$param];
	    my $var = $tmp;
	    $var =~ s/^.*_FH_//;

	    if ($var !~ /^A_GENTESTS_NULL_PARAM/)
	    {
		print FILE "$VHT_TYPE{$tmp} \%$export_file \$$var = @{$VHT_PARAM{$tmp}}\n";
	    }
	    else
	    {
		print FILE "$VHT_TYPE{$tmp} \%$export_file = @{$VHT_PARAM{$tmp}}\n";
	    }
	}
    }

    foreach my $mif_file (keys %MIF_FILE_NAMES)
    {
	# only ever need to take the first element, as there can only be one
	# param per mif file
	my $tmp = $GENERIC_FILE_PARAMS{$mif_file}[0];
	print FILE "$VHT_TYPE{$tmp} mif_file \%$mif_file = @{$VHT_PARAM{$tmp}}\n";
    }


    print FILE "end\n";

    close FILE;
}


#-----------------------------------------------------------------------------
sub write_stim_do
#-----------------------------------------------------------------------------
{
    my ($dir, $options_ref) = @_;

    open (STIMDO,">$dir/stim_mti.do") or err('--', "Cannot create the stim_mti.do file in $dir.", 2);

    foreach my $option (@$options_ref)
    {
	print STIMDO "$option\n";
    }

    print STIMDO ("run -all\n");
#    print STIMDO ("echo \"", "#" x 100, "\\n# VSIM MEMORY STATS\\n", "#" x 100, "\"\n");
#    print STIMDO ("mti_kcmd memstats\n");
    print STIMDO ("quit\n");
    close STIMDO;

    open (STIMDO,">$dir/stim_scirocco.do") or err('--', "Cannot create the stim_scirocco.do file in $dir.", 2);
    print STIMDO ("run\n");
    print STIMDO ("quit\n");
    close STIMDO;
}


#-----------------------------------------------------------------------------
sub write_batch_files
#-----------------------------------------------------------------------------
{
    my ($dir, $tcase, $family) = @_;

    # create the cshell file
    open (RUN, ">$dir/run.sh") or err('--',"Cannot create the run.sh file in $dir.", 2);
    print RUN <<EOF;
#!/bin/sh

echo "###################################################################################################"
echo "RUN THE TEST CASE USING RUNIPINT:"
echo 'NOTE: Make sure \$REL, \$MODELSIM_VER, environment variables are set in the current shell.'
echo 'NOTE:    REL is the Xilinx Tool version name (ex: E.26.1).'
echo 'NOTE:    MODELSIM_VER is the Modeltech version name (ex: 5.6b).'
echo 'NOTE: You can also specify a family with the environment variable \$RUNTIME_FAMILY.'
echo "###################################################################################################"
echo ""
echo "RUN ENVIRONMENT:"
if [ "\$REL" ]; then
   echo "    REL     : \$REL"
else
    echo 'ERROR: The Xilinx Tool version environment variable REL is not set.'
    exit 1
fi
if [ "\$MODELSIM_VER" ]; then
    echo "    MODELSIM_VER  : \$MODELSIM_VER"
else
    echo 'ERROR: The modeltech version environment variable MODELSIM_VER is not set.'
    exit 1
fi
if [ "\$CGREL" ]; then
    SANDBOX_VER=\$CGREL; export SANDBOX_VER
fi
if [ "\$SANDBOX_VER" ]; then
    sandbox=\$SANDBOX_VER
    echo "    SANDBOX_VER: \$SANDBOX_VER"
else
    sandbox=TURN_OFF; export SANDBOX_VER
fi
if [ ! "\$RUNTIME_FAMILY" ]; then
    RUNTIME_FAMILY=RandFam; export RUNTIME_FAMILY
fi
if [ ! "\$CADSET_GROUPFILE" ]; then
    if [ "\$CADSET_GROUPFILE_SUBSCRIBED" ]; then
        CADSET_GROUPFILE=\$CADSET_GROUPFILE_SUBSCRIBED; export CADSET_GROUPFILE
    fi
fi

FAMILY=; export FAMILY

\$ROMS/bin/runipint \$XIL_SITE \$REL \$RUNTIME_FAMILY \$sandbox \$MODELSIM_VER TURN_OFF TURN_OFF TURN_OFF TURN_OFF $MODULENAME $family $tcase
EOF

    close RUN;
    chmod 0777, "$dir/run.sh";

    # create the win .bat file
    open (RUN, ">$dir/run.bat") or err('--',"Cannot create the run.bat file in $datadir.",2);
    print RUN <<EOF;
\@echo off
echo ###################################################################################################
echo Execute the test case using runipint.
echo Make sure REL, MODELSIM_VER, environment variables are set in the current shell.
echo    REL is the Xilinx Tool version name (ex: E.26.1).
echo    MODELSIM_VER is the Modeltech version name (ex: 5.6b).

echo You can also specify a family with the environment variable RUNTIME_FAMILY.
echo ###################################################################################################

echo RUN ENVIRONMENT:
IF DEFINED REL echo     REL    : %REL%
IF NOT DEFINED REL echo ERROR: The Xilinx Tool version environment variable REL is not set.
IF DEFINED MODELSIM_VER echo     MTIREL  : %MODELSIM_VER%
IF NOT DEFINED MODELSIM_VER echo ERROR: The modeltech version environment variable MODELSIM_VER is not set.
IF NOT DEFINED CADSET_GROUPFILE set CADSET_GROUPFILE=%CADSET_GROUPFILE_SUBSCRIBED%
IF DEFINED CADSET_GROUPFILE echo CADSET_GROUPFILE : %CADSET_GROUPFILE%

echo RUN IPINT:
IF DEFINED RUNTIME_FAMILY %ROMS%\\bin\\runipint.bat %XIL_SITE% %REL% %RUNTIME_FAMILY% $MODULENAME $family $tcase
IF NOT DEFINED RUNTIME_FAMILY %ROMS%\\bin\\runipint.bat $Site %REL% RandFam $MODULENAME $family $tcase

EOF
    close RUN;
    chmod 0777, "$dir/run.bat";
}


#-----------------------------------------------------------------------------
sub write_xco
#-----------------------------------------------------------------------------
{
    my ($dir, $tcase, $family, $core_name, $core_version) = @_;

    open(XCO, ">$dir/$tcase.xco") or err('--', "Could not create $tcase.xco for writing:$!", 2);

    # under windows, still create unix files so ROMS doesn't puke!
    if ($^O =~ /^MSWin/)
    {
	binmode XCO;
    }

    # the default seperator for lists
    my $seperator = ",";

    # before createing the core batch file core.bat we need to eval TPR rules
    foreach my $rule (@RULES_ARRAY)
    {
	if ($rule =~ /^\s*(.+)\s*\?\s*([^:]+)\s*:?\s*(.*)\s*$/)
	{
	    my $condition = $XCO_CASE_SENSITIVE ? $1 : lc($1) ;
	    my $iftrue = $2;
	    my $else = $3;

	    # expand each variable
	    foreach ($condition =~ /\$([a-z0-9_]+)/ig)
	    {
		my $var = $_;
		my $combined;

		# we have to put the list together, as it's stored in an array
		# the string concat is OK here, as the strings will never be big
		# enough to see the big performance hit
		foreach my $elem (0..$#{$VHT_PARAM{$var}}-1)
		{
		    $combined = $combined . $VHT_PARAM{$var}[$elem] . $seperator;
		}
		$combined = $combined . $VHT_PARAM{$var}[$#{$VHT_PARAM{$var}}];

		# finally substitute the new list with the variable
		$condition =~ s/\$$var/$combined/ig;
	    }

	    if (eval($condition))
	    {
		print XCO "#Rule:--$iftrue--\n";
	    }
	    else
	    {
		print XCO "#Rule:--$else--\n";
	    }
	}
	else
	{
	    err('--', "The rule $rule declared in the tpr file is unvalid !!", 19);
	}
    }

    # remove the _all from any family names, as the core.bat file does not
    # support this
    $family =~ s/_all$//;

    print XCO "SELECT $core_name $family Xilinx,_Inc. $core_version\n";
    print XCO "CSET component_name = $tcase\n";

    foreach $key (keys %VHT_PARAM)
    {
	# check to see if the key has a value.  It is possible to have
	# no value when there are rules used with keys that don't exist in the begin/end block!
	if (!defined $VHT_PARAM{$key}[0])
	{
	    next;
	}

        my $xcokey = $key ;
        for my $i (0 .. $#TEST_VARHASH) {
             if ($TEST_VARHASH[$i]{'parameter_name'} eq $key
             && defined $TEST_VARHASH[$i]{'casesens_name'}) {
                $xcokey = $TEST_VARHASH[$i]{'casesens_name'} if $XCO_CASE_SENSITIVE ;
             }
        }

	print XCO "CSET $xcokey = ";
	# print out each element of the list, being careful not to add a seperator after the last element
	foreach my $elem (0..$#{$VHT_PARAM{$key}}-1)
	{
	    print XCO "$VHT_PARAM{$key}[$elem]$seperator";
	}
	# the last line has a \n instead of seperator
	print XCO "$VHT_PARAM{$key}[$#{$VHT_PARAM{$key}}]\n";
    }
    print XCO "GENERATE\n";

    close XCO;
}


#-----------------------------------------------------------------------------
sub write_edk
#-----------------------------------------------------------------------------
{
    my ($dir, $core_name, $core_version) = @_;

    open(EDK, ">$dir/ip_data.edk") or err('--', "Could not create ip_data.edk for writing:$!", 2);

    # under windows, still create unix files so ROMS doesn't puke!
    if ($^O =~ /^MSWin/)
    {
	binmode EDK;
    }

    print EDK "BEGIN $core_name\n";
    print EDK "PARAMETER HW_VER = $core_version\n";
    print EDK "PARAMETER INSTANCE = testinst\n";

    foreach $key (keys %VHT_PARAM)
    {
	# check to see if the key has a value.  It is possible to have
	# no value when there are rules used with keys that don't exist in the begin/end block!
	if (!defined $VHT_PARAM{$key}[0])
	{
	    next;
	}

	print EDK "PARAMETER ", uc($key), "= ";

	# print out each element of the list, being careful not to add a seperator after the last element
	foreach my $elem (0..$#{$VHT_PARAM{$key}}-1)
	{
	    print EDK "$VHT_PARAM{$key}[$elem]$seperator";
	}

	# the last line has a \n instead of seperator
	print EDK "$VHT_PARAM{$key}[$#{$VHT_PARAM{$key}}]\n";
    }

    print EDK "END\n";

    close EDK;
}


#-----------------------------------------------------------------------------
sub write_readme
#-----------------------------------------------------------------------------
{
    my ($dir, $tcase, $family, $flow) = @_;

    my $rmf = new ReadMeFile;
    # Turn on over-write mode (allow overwriting of existing ReadMe files)
    $rmf->setOverWriteON();

    $rmf->setFileDir($dir);

    # set some basic information
    $rmf->setTestCaseName($tcase);

    my $repBranch = getRepBranch();

    $rmf->setRepBranch($repBranch);

    $rmf->setFlowName($flow);

    $rmf->setFamily($family);

    $rmf->setAuthor("ipsvg");
    $rmf->setCoregenSpec("Y");
    $rmf->setRandomGenFlag("Y");
    $rmf->setSimulation("Y");
    $rmf->testCaseActivate("Y");
    $rmf->setAtsActiveFlag("N");
    $rmf->setSiteCode($ENV{'XIL_SITE'});

    if (!$rmf->writeFile())
    {
	print "ReadMe Write Failure:\n", $rmf->getErrMsg(), "\n";
	return 1;
    }
}


sub WriteXmlDetails
{
     my $SUB_NAME = "WriteXmlDetails";
     my $RET_CODE = 50;

     my $repBranch = getRepBranch();
     my $xml_file = $CURRENT_TPR_FILE;
     $xml_file =~ s/\.(tpr|in)$/\.xml/g;
     $xml_file = "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME/$xml_file";

     # check that the core directory exists.  If it doesn't, don't create
     # a XML, as no testcases were generated!
     if (!-e "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME")
     {
	  return 0;
     }


     my $doc;
     my $doc_element;

     # if the file already exists just read it in, otherwise
     # create a new xml file
     if (-e $xml_file)
     {
	  my $parser = new XML::DOM::Parser;
	  $doc = $parser->parsefile($xml_file);

	  # update the total number of tests
	  $doc_element = $doc->getDocumentElement();
	  my $no_tcases = $doc_element->getAttributeNode("tcaseCount")->getValue;
	  $no_tcases += $NO_OF_NEW_TESTS;
	  $doc_element->setAttribute("tcaseCount", $no_tcases);

	  # handle if the name or version of the core gets updated
	  $doc_element->setAttribute("coreName", $MODULE);
	  $doc_element->setAttribute("coreVersion", $CORE_VERSION);
     }
     else
     {
	  $doc = new XML::DOM::Document;
	  $doc->setXMLDecl($doc->createXMLDecl("1.0", "UTF-8", undef));

	  my $tmp = $doc->createElement("module");
	  $tmp->setAttribute("name", $MODULENAME);
	  $tmp->setAttribute("coreName", $MODULE);
	  $tmp->setAttribute("coreVersion", $CORE_VERSION);
	  $tmp->setAttribute("tcaseCount", $NO_OF_TESTS);

	  $doc_element = $doc->appendChild($tmp);
     }


     foreach my $level (keys %XML_DETAILS)
     {
	  # find the correspoding node in the xml tree
	  my $priority_node;
	  foreach my $node ($doc->getElementsByTagName("priority"))
	  {
	       # we have the right node
	       if (($node->getAttributeNode("level")->getValue) eq $level)
	       {
		    $priority_node = $node;
		    last;
	       }
	  }

	  # if the priority node wasn't found create it
	  if (!$priority_node)
	  {
	       my $new_node = $doc->createElement("priority");
	       $new_node->setAttribute("level", $level);
	       $new_node->setAttribute("tcaseCount", 0);
	       $priority_node = $doc_element->appendChild($new_node);
	  }

	  # count the number of new priority testcases
	  my $priority_count = 0;
	  foreach my $family (keys %{$XML_DETAILS{$level}})
	  {
	       $priority_count += @{$XML_DETAILS{$level}{$family}}
	  }
	  # add it to the total list of existing tcases
	  $priority_count += $priority_node->getAttributeNode("tcaseCount")->getValue;
	  $priority_node->setAttribute("tcaseCount", $priority_count);


	  # add in each family node
	  foreach my $family (keys %{$XML_DETAILS{$level}})
	  {
	       # find the correspoding node in the xml tree
	       my $family_node;
	       foreach my $node ($priority_node->getElementsByTagName("family"))
	       {
		    # we have the right node
		    if (($node->getAttributeNode("name")->getValue) eq $family)
		    {
			 $family_node = $node;
			 last;
		    }
	       }

	       # if the family node wasn't found create it
	       if (!$family_node)
	       {
		    my $new_node = $doc->createElement("family");
		    $new_node->setAttribute("name", $family);
		    $new_node->setAttribute("tcaseCount", 0);
		    $family_node = $priority_node->appendChild($new_node);
	       }

	       # the total no of new testcases for this family
	       my $family_count = @{$XML_DETAILS{$level}{$family}};
	       $family_count += $family_node->getAttributeNode("tcaseCount")->getValue;
	       $family_node->setAttribute("tcaseCount", $family_count);



	       # add in each testcase node
	       foreach my $tcase (@{$XML_DETAILS{$level}{$family}})
	       {
		    my $new_node = $doc->createElement("tcase");
		    $new_node->setAttribute("name", $tcase);
		    my $tcase_node = $family_node->appendChild($new_node);
	       }
	  }
     }

     $doc->printToFile($xml_file);
     $doc->dispose;
}


sub write_coe_file
{
     my ($dir, $filename, @paramaters) = @_;
     $filename = $dir . "/" . $filename;

     open COE, ">$filename" or err ('--', "Could not create coe file $filename: $!", 2);

     foreach my $param (@paramaters)
     {
	  if ($param !~ /^A_GENTESTS_NULL_PARAM/)
	  {
	      my $write_param = $param;
	      $write_param =~ s/^.*_FH_//;

	       print COE "$write_param = ";

	       # print out each element of the list, being careful not to add a seperator after the last element
	       # the seperator is a space with COE files
	       foreach my $elem (0..$#{$VHT_PARAM{$param}}-1)
	       {
		    print COE "$VHT_PARAM{$param}[$elem] ";
	       }

	       # the last element has a ;\n instead of space seperator
	       print COE "$VHT_PARAM{$param}[$#{$VHT_PARAM{$param}}];\n";

	       # get rid of this parameter in the hash $VHT_PARAM (must not be present in the core.bat file)
	       delete ($VHT_PARAM{$param});
	  }
	  else
	  {
	       close COE;
	       err ('--', "Can't have a coe value without a paramater key", 2);
	  }
     }

     close COE;
}


#-----------------------------------------------------------------------------
sub write_export_file
#-----------------------------------------------------------------------------
{
    my ($dir, $filename, $prefix, @paramaters) = @_;
    $filename = $dir . "/" . $filename;

    # work out the full dir and create it if necessary
    $dir = $filename;
    $dir =~ s/(\/|\\)[a-zA-Z0-9_\-\.]+$//;
    if (!-e $dir)
    {
	mkpath ([$dir],0,0777) or err ('--',"cannont create dir $dir: $!", 2);
    }

    open EXPORT, ">$filename" or err ('--', "Could not create export file $filename: $!", 2);

    foreach my $param (@paramaters)
    {
	if ($param =~ /${prefix}_FH_(.*)$/)
	{
	    my $name = $1;
	    if ($name =~ /^A_GENTESTS_NULL_PARAM/)
	    {
		print EXPORT "@{$VHT_PARAM{$param}}\n";
	    }
	    else
	    {
		print EXPORT "$name = @{$VHT_PARAM{$param}}\n";
	    }

	    # get rid of this parameter in the hash $VHT_PARAM (must not be present in the core.bat file)
	    delete ($VHT_PARAM{$param});
	}
	else
	{
	    print "\n\nERROR: this case should not happen!!!\n";
	}
    }

    close EXPORT;
}

sub write_mif_file
{
     my ($dir, $filename, @paramaters) = @_;
     $filename = $dir ."/" . $filename;

     # create the coregen proj dir where the mif files should
     # always be stored
     if (!-e "$dir")
     {
	  mkpath ([$dir],0,0777) || &err ('--',"cannont create dir $dir: $!",2);
     }

     open MIF, ">$filename" or err ('--', "Could not create mif file $filename: $!", 2);

     foreach my $param (@paramaters)
     {
	  if ($param !~ /^A_GENTESTS_NULL_PARAM/)
	  {
	       # the list in mif files is \n seperated
	       foreach my $elem (0..$#{$VHT_PARAM{$param}})
	       {
		    print MIF $VHT_PARAM{$param}[$elem], "\n";
	       }
	  }
	  else
	  {
	       close MIF;
	       err ('--', "Can't have a mif value without a paramater key", 2);
	  }

	  # get rid of this parameter in the hash $VHT_PARAM (must not be present in the core.bat file)
	  delete ($VHT_PARAM{$param});
     }

     close MIF;
}


#-----------------------------------------------------------------------------
sub write_cfg_file
#-----------------------------------------------------------------------------
{
    my ($cfg_file, $universal_opts_ref, $global_opts_ref, $local_opts_ref, $arrays_ref, $misc_envs_ref) = @_;

    # build up a complete list of options with the precedence (highest
    # to lowest) local, global, universal
    my %options;

    # need to read in existing cfg files
    my $cfg_exists = 0;
    my %settings;
    if (-e $TPRFILEDIR."/gentests.cfg")
    {
	$cfg_exists = 1;
	%settings = ipint_cfg::read_cfg($TPRFILEDIR."/gentests.cfg");

	foreach my $var (keys %{$settings{'SCALAR'}})
	{
	    $options{$var} = $settings{'SCALAR'}{$var};
	}
    }

    foreach my $var (keys %{$universal_opts_ref})
    {
	$options{$var} = $$universal_opts_ref{$var};
    }
    foreach my $var (keys %{$global_opts_ref})
    {
	$options{$var} = $$global_opts_ref{$var};
    }
    foreach my $var (keys %{$local_opts_ref})
    {
	$options{$var} = $$local_opts_ref{$var};
    }

    open CFG, ">$cfg_file" or err ("--", "Could not create $cfg_file: $!");

    print CFG "FlowConfig\n{\n";

    print CFG "\t# flow options\n";
    foreach my $var (keys %options)
    {
	print CFG "\t$var =$options{$var};\n";
    }

    print CFG "\n\t# misc env vars needed at run time\n";
    foreach my $var (keys %{$misc_envs_ref})
    {
	print CFG "\t$var =$$misc_envs_ref{$var};\n";
    }

    # there are a number of misc env vars that also need to be saved and
    # set at run time
    if (!exists $options{'MODULE'})
    {
	print CFG "\tMODULE =$MODULE;\n";
    }
    if (!exists $options{'CORE_VERSION'})
    {
	print CFG "\tCORE_VERSION =$CORE_VERSION;\n";
    }
    if (!exists $options{'MODULENAME'})
    {
	print CFG "\tMODULENAME =$MODULENAME;\n";
    }

    print CFG "\n\t# various array flow options\n";
    if ($cfg_exists)
    {
	print CFG "\n\tVHD_TBs_CONF\n\t{\n";
	foreach my $tb (@{$settings{'ARRAY'}{'VHD_TBs_CONF'}})
	{
	    print CFG "\t\titem =$tb;\n";
	}
	print CFG "\t}\n\n";

	print CFG "\n\tVHDL_PTPs\n\t{\n";
	foreach my $tb (@{$settings{'ARRAY'}{'VHDL_PTPs'}})
	{
	    print CFG "\t\titem =$tb;\n";
	}
	print CFG "\t}\n\n";

	print CFG "\n\tVHDL_TPs\n\t{\n";
	foreach my $tb (@{$settings{'ARRAY'}{'VHDL_TPs'}})
	{
	    print CFG "\t\titem =$tb;\n";
	}
	print CFG "\t}\n\n";

	print CFG "\n\tVHD_TBs\n\t{\n";
	foreach my $tb (@{$settings{'ARRAY'}{'VHD_TBs'}})
	{
	    print CFG "\t\titem =$tb;\n";
	}
	print CFG "\t}\n\n";
    }
    else
    {
	foreach my $arr (keys %{$arrays_ref})
	{
	    print CFG "\n\t$arr\n\t{\n";
	    foreach my $i (0..$#{$$arrays_ref{$arr}})
	    {
		my $tmp = $$arrays_ref{$arr}[$i];
		# strip out anything upto the TPR dir
#		$tmp =~ s/$TPRFILEDIR(\\|\/)(\.\.(\\|\/))?//;
		$tmp =~ s/^.*(\\|\/)//;

		print CFG "\t\titem =$tmp;\n";
	    }
	    print CFG "\t}\n";
	}
    }

    print CFG "}\n";

    close CFG;
}


#-----------------------------------------------------------------------------
sub write_common_data_files
#-----------------------------------------------------------------------------
{
    my @data_files;
    my $ncopy = NCopy->new('force_write' => 1);
    my $ncopy_recursive = NCopy->new('force_write' => 1, 'recursive' => 1);

    if (($GLOBAL_FLOWOPTS{'REGENERATED'} || $main::UNIVERSAL_FLOWOPTS{'REGENERATED'}) && -e $TPRFILEDIR."/gentests.cfg")
    {
	my %settings = ipint_cfg::read_cfg($TPRFILEDIR."/gentests.cfg");

	if (exists $settings{'ARRAY'}{'VHD_TBs'})
	{
	    foreach my $file (@{$settings{'ARRAY'}{'VHD_TBs'}})
	    {
		# use the _orig tb if it exists
 		if (-e $file."_orig")
 		{
		    $ncopy->copy($file."_orig", $COMMON_DATA_DIR."/".$file) or err('--', "Could not copy the $file to $COMMON_DATA_DIR", 2);
 		}
	    }
	}

	push @data_files, @{$settings{'ARRAY'}{'VHD_TBs_CONF'}};
	push @data_files, @{$settings{'ARRAY'}{'VHDL_TPs'}};
	push @data_files, @{$settings{'ARRAY'}{'VHDL_PTPs'}};
    }
    else
    {
	push @data_files, @TESTBENCHFILES;
	push @data_files, @TB_CONF_FILES;
	push @data_files, @TESTPACK;
	push @data_files, @PARAM_TESTPACK;
    }

    push @data_files, @COPYFILES;

    foreach my $file (@data_files)
    {
	# only copy non variable files
	if ($file !~ /\$/)
	{
	    $ncopy->copy($file, $COMMON_DATA_DIR) or err('--', "Could not copy the $file to $COMMON_DATA_DIR", 2);
	}
    }

    # copy files declared in the TPR file with the entry COPYDIRS
    foreach my $dir (@COPYDIRS)
    {
	if (-d $dir)
	{
	    $ncopy_recursive->copy($dir, $COMMON_DATA_DIR) or err ('--', "Could not copy the $dir to $COMMON_DATA_DIR", 2);
	}
	else
	{
	    # remove the file portion and work
	    # out the target directory
	    my $target_dir;
	    my $tfd = $TPRFILEDIR ;
	    $tfd =~ s/\\/\\\\/g if $^O =~ /^MSWin/ ; # Escape NT dir separators -liamb 4/jul/05
	    if ($dir =~ /(.*)(\/|\\)\S+$/)
	    {
		$target_dir = $1;
		$target_dir =~ s/${tfd}(\/|\\)(\.\.)?(\/|\\)?//;
		$target_dir = $COMMON_DATA_DIR."/".$target_dir;
	    }

	    if (!-e $target_dir)
	    {
		mkpath([$target_dir]) or err ('--',"cannont create dir $target_dir: $!", 2);
	    }

	    $ncopy_recursive->copy($dir, $target_dir) or err ('--', "Could not copy the file $dir in $target_dir.", 2);
	    fix_all_permissions($target_dir);
	}
    }

    fix_all_permissions($COMMON_DATA_DIR);

    # create the .do files for various supported simulators
    write_stim_do($COMMON_DATA_DIR, \@SIM_OPTIONS);
}


#-----------------------------------------------------------------------------
sub get_flow_option
#-----------------------------------------------------------------------------
{
    my ($flow_option) = @_;

    my $value = "";

    if (exists $LOCAL_FLOWOPTS{$flow_option})
    {
	$value = $LOCAL_FLOWOPTS{$flow_option};
    }
    elsif (exists $GLOBAL_FLOWOPTS{$flow_option})
    {
	$value = $GLOBAL_FLOWOPTS{$flow_option};
    }
    elsif (exists $main::UNIVERSAL_FLOWOPTS{$flow_option})
    {
	$value = $main::UNIVERSAL_FLOWOPTS{$flow_option};
    }

    return $value;
}


#-----------------------------------------------------------------------------
sub gentests_lock
#-----------------------------------------------------------------------------
{
    my ($tpr_file, $lock) = @_;

    my $lock_file = $tpr_file;
    $lock_file =~ s/\.(in|tpr)$/\.lock/i;
    
    my $poll = 0 ;

    my $wait_period = 0 ;
    my $max_period = 1800 ; # Max wait time = 30 mins (30 x 60 secs)

    if ($lock)
    {
	# if a lock file already exists wait until it's
	# deleted, as another process obviously has a lock!
	while (-e $lock_file)
	{
	    # CR 198584 fix
	    print( "gentests.pl locked.  Sleeping (", scalar(localtime), ")\n" ), $poll=1 unless $poll;
	    sleep 5;
	    $wait_period += 5 ;
	    if( $wait_period > $max_period ) {
	       print( "ERROR - Timeout (at ", scalar(localtime), ") whilst waiting for release of lock\n" ) ;
	       print( "        '${lock_file}' has been in place for more than ${max_period} secs\n" ) ;
	       print( "        Could this be due to an earlier gentests run which got killed\n" ) ;
	       print( "        (leaving its lockfile in place) ?  ..if so just delete this old\n" ) ;
	       print( "        lockfile & restart the gentest job.\n" ) ;
	       die "\n" ;
	    }
	}

        print( "gentests.pl lock released (", scalar(localtime), ")\n" ), if $poll;
	open LOCK, ">$lock_file" or err('--', "Could not create lock $lock_file: $!\n", 71);
	close LOCK;
	$LOCK_SET = 1;
    }
    else
    {
	unlink ($lock_file);
	$LOCK_SET = 0;
    }
}

#-----------------------------------------------------------------------------
sub fix_all_permissions
#-----------------------------------------------------------------------------
{
    my ($directory) = @_;

    my @queue = $directory;

    while (my $dir = shift @queue)
    {
	if (!opendir DH, $dir)
	{
	    err ($LINE_NO, "Could not open the directory $dir", 10);
	}

	while (my $dir_next = readdir DH)
	{
	    next if ($dir_next =~ /^\.{1,2}$/);
	    my $full_path = $dir.'/'.$dir_next;
	    push @queue, $full_path if (-d $full_path);

	    if (-d $full_path)
	    {
		chmod 0777, $full_path;
	    }
	    elsif (-f $full_path)
	    {
		chmod 0666, $full_path;
	    }
	}
	closedir DH;
    }
}


#-----------------------------------------------------------------------------
sub check_required_settings
#-----------------------------------------------------------------------------
{
    if ($MODULE eq "unset")
    {
	err("--", "MODULE not defined in TPR file", 500);
    }

    if ($MODULENAME eq "unset")
    {
	err("--", "MODULE_NAME not defined in TPR file", 500);
    }

    if ($IPFLOW eq "unset")
    {
	err("--", "WHATTODO not defined in TPR file", 500);
    }


    # check the correct TB versions are used
    foreach my $testbench (@{$EXTRA_ARRAYS{'VHD_TBs'}})
    {
	my $tb_ver = 1;

	open TB, $testbench or err("Could not check testbench $testbench: $!");

	foreach my $line (<TB>)
	{
	    if ($line =~ /^\s*--\s*TESTBENCH_TEMPLATE_VERSION\s*=\s*(\d+)/)
	    {
		$tb_ver = $1;
		last;
	    }
	}

	close TB;

	# check the options have been defined somewhere
	my $version_matches = 0;

	if (exists $LOCAL_FLOWOPTS{'TB_VER'})
	{
	    if ($tb_ver == $LOCAL_FLOWOPTS{'TB_VER'})
	    {
		$version_matches = 1;
	    }
	}
	elsif (exists $GLOBAL_FLOWOPTS{'TB_VER'})
	{
	    if ($tb_ver == $GLOBAL_FLOWOPTS{'TB_VER'})
	    {
		$version_matches = 1;
	    }
	}
	elsif (exists $main::UNIVERSAL_FLOWOPTS{'TB_VER'})
	{
	    if ($tb_ver == $main::UNIVERSAL_FLOWOPTS{'TB_VER'})
	    {
		$version_matches = 1;
	    }
	}
	elsif ($tb_ver == 1)
	{
	    # the flows default to V1 testbenches so this is OK
	    $version_matches = 1;
	}

	if (!$version_matches)
	{
	    err("--", "The TB_VER specified in the TPR does not match the testbench", 500);
	}
    }

    my $repBranch = getRepBranch();
    print "Using directory: $main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME\n";

    # create the common data dir, once we know all the settings
    $COMMON_DATA_DIR = "$main::REPOSITORY/$repBranch/$IPFLOW/$MODULENAME/common_files";

    if (!-e $COMMON_DATA_DIR)
    {
	mkpath([$COMMON_DATA_DIR]) or err('--', "Cannot create the dir $COMMON_DATA_DIR: $!", 2);
    }
}



#-----------------------------------------------------------------------------
sub select_n_random_elements
#-----------------------------------------------------------------------------
{
    my ($no_elements, @all) = @_;

    my @places = (0..$#all);
    my @pos_pool;
    push @pos_pool, splice @places, rand @places, 1 while @pos_pool < $no_elements;

    my @random_elements;
    for my $i (0..$no_elements-1)
    {
	push @random_elements, $all[$pos_pool[$i]];
    }

    return @random_elements;
}


#-----------------------------------------------------------------------------
sub lc_rhs 
#
# Takes the right-hand-side text of a tpr assignment, and lowercases all parts
# except any bareword/literal strings in it   ..this is so the barewords gets
# passed through to the xco with case preserved -a requirement for Coregen in
# Iron.
#
# LB  22/Jul/05
#
#-----------------------------------------------------------------------------
{
   my $rhs = shift ;
   $rhs =~ s/\s*//g ;
   
   my ($pefix, $vals, $pofix ) = ($rhs, "", "" ) ;

   # Extract value list from direct assignment
   if( $rhs =~ /^\$?\w+(,\$?\w+)*$/i ) {
      $pefix = "" ;  $vals  = $rhs ;  $pofix = "" ;
   }
   
   # Extract value list in RAND call
   if( $rhs =~ /^(\[rand:range:)(\$?\w+(,\$?\w+)*)(\W.*)$/i ) {
      $pefix = $1 ;  $vals  = $2 ;    $pofix = $4 ; 
   }
   
   # Preserve case of any bareword literals in value list
   my @lcvals ;
   for( split( ',', $vals )) {push( @lcvals, /^\$/ ? lc($_) : $_ )}
   
   return lc($pefix) . join( ',', @lcvals ) . lc($pofix) ;
}


1;
