 use warnings;
 use strict;
 
 
 use File::stat;
 my $filename   = "C:\\strawberry\\README.txt";
 my $sb = stat($filename);
 my $permi = $sb->mode;
 print "My Permission is $permi\n";
 printf "File is %s, size is %s, perm %5d\n", $filename, $sb->size, $sb->mode & 07777;