#!/usr/bin/perl

use strict;
use warnings;
use ExecCmd;

use Test::More;

use_ok ( 'ExecCmd' );
use_ok ( 'ExecCmd', 'display_output' );

#can_ok() - to test that the subroutines can be called using module's namespace
can_ok ( 'ExecCmd', 'execute_cmd' );

#can_ok() - if its exported then it would be available in main namespace.
can_ok ( __PACKAGE__, 'execute_cmd' );


#accessing via module's namespace
#ExecCmd::execute_cmd();

#if exported to main namespace,
#execute_cmd();

#my $object->execute_cmd();

can_ok (my $object, 'execute_cmd' );


isa_ok($object, 'ExecCmd');

isa_ok($object, 'ExeCmd');


is(is_exist("/bin/df"), 1, "Test the existence of /bin/df");

#ok 6 - Test the existencce of file /bin/df

#not ok 6 - Test the existence of /bin/df
#   Failed test 'Test the existence of /bin/df'
#   at ./test.t line 18.
#          got: '0'
#     expected: '1'


isnt(is_exist("/bin/wine"), 1, "Test the non-existencce of file /bin/wine");

#ok 7 - Test the non-existencce of file /bin/wine


like (execute_cmd("df"), qr|/dev/sda7|, "Test the partition /dev/sda7 is mounted");

#ok 8 - Test the partition /dev/sda7 is mounted


unlike (execute_cmd("df"), qr|100%|, "Test that no partition is 100% full");


