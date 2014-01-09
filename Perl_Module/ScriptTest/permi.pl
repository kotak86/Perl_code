use strict;
use warnings;
use File::stat;
use Data::Dumper;

my $fpath   = "C:\\strawberry\\README.txt";
my $info    = stat($fpath);

 #print Dumper($info);

my $retMode = $info->mode;

print "1: Now \$retMode is $retMode\n";
$retMode = $retMode & 07777;
print "2: Now \$retMode is $retMode\n";

if ($retMode & 002) {
    print " Code comes here if World has write permission on the file\n";
	
}     
if ($retMode & 020) {
    # Code comes here if Group has write permission on the file
}
if ($retMode & 022) {
    # Code comes here if Group or World (or both) has write permission on the file
}
if ($retMode & 007) {
    # Code comes here if World has read, write *or* execute permission on the file
} 
if ($retMode & 006) {
    # Code comes here if World has read or write permission on the file
} 
if (($retMode & 007) == 007) {
    # Code comes here if World has read, write *and* execute permission on the file
} 
if (($retMode & 006) == 006) {
    # Code comes here if World has read *and* write permission on the file
}
if (($retMode & 022) == 022) {
    # Code comes here if Group *and* World both have write permission on the file
}
