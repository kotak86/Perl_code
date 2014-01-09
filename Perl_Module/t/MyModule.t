#!/usr/bin/perl
use strict;
use warnings;
use MyModule;

use Test::More qw(no_plan);

use_ok ( 'MyModule'); #test #1
use_ok ( 'MyModule', 'GetFiles', 'FindWw', 'RemWwPerm', 'CheckUid', 'Display_msg', 'Usage' ); #test #2

#test 3 &4

can_ok ( 'MyModule', 'GetFiles', 'FindWw', 'RemWwPerm', 'CheckUid', 'Display_msg', 'Usage' ); #test #3
can_ok ( __PACKAGE__, 'GetFiles', 'FindWw', 'RemWwPerm', 'CheckUid', 'Display_msg', 'Usage'); #test #4

#  TestCases for testing functions
is(GetFiles('ScriptTest/'),16 , "GetFiles Good"); #test #5

is(FindWw('find_uid.pl'), 1, "FindWw Good" ); #test #6:    Provided file is world Writable files so it return 1;
isnt(FindWw('GetFiles.pl'), 0, "FindWw Good" ); #test #7: Provided file is not world Writable so it return 0;

is(RemWwPerm('find_uid.pl',1, '1434164'), 1, "RemWwPerm with Verbose" ); #test #8: Provided Given files world Writable
is(RemWwPerm('testModule.pl',0, '1434164'), 1, "RemWwPerm without Verbose" ); #test #9: Without verbose output

is(CheckUid('find_uid.pl', '1434164'),1, "CheckUid actual file UID");#test #10: with actual UID of the file
isnt(CheckUid('GetOpt.pl', '1434162'),1, "CheckUid wrong file UID");#test #11: with wrong UID of the file

