#!/usr/bin/perl 
use strict; 
use warnings; 
use Data::Dumper;
my @file_list =();
my @all_file = ();
my $dir = $ARGV[0];


	sub GetFiles{
		
		my $dir = shift;
		my @files = glob("$dir/*");
		my $file;
		
		foreach $file (@files){
			my $Isdir = 0;
			$Isdir = 1, if -d $file;
			$Isdir	? (GetFiles($file)) : (push (@file_list, $file));			
		}
		my $file_list_cnt = $#file_list +1;
		return (@file_list);
	}
	
	
	if ($dir and (-d $dir)){
		@all_file = GetFiles($dir);
	}
	
	elsif ($dir and -f $dir){
		@all_file = $dir;
	}
	else {
	

	print<<EOF;
Please specify file(s) or diretorie(s).\n
E.g.1. Getfile.pl file1 file2 file3 or\n
E.g.2. Getfile.pl dir1 dir 2 dir3 or\n
E.g.3. Getfile.pl file1 dir 1 file2\n";
EOF
	}

 

print Dumper(@all_file);