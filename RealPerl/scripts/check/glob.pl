#!usr/bin/perl
use strict;
use warnings;
use File::stat;
use Time::localtime;
use Cwd;

my $xhd = "/proj/XHDtools/svauto2/flows/xlnxIP/prod/";
my $xdc = "/proj/XDCtools/svauto2/flows/xlnxIP/prod/";
my $xsj = "/proj/XSJtools/svauto2/flows/xlnxIP/prod/";
my $xco = "/proj/XCOtools/svauto2/flows/xlnxIP/prod/";
my $xap = "/proj/XAPtools/svauto2/flows/xlnxIP/prod/";

sub get_list {

	my $dir =  $_[0];
	chdir($dir);
	my $cwd = getcwd();
	print "This is Cuurent Working Directory $cwd" ;
	my $server= $_[1];
	my $script  = "/proj/ipco/users/hshah/ankit/scripts/check";

	my @files = sort glob('*');
	print my $total = $#files + 1; print "\n"; 
	my $dec = $total;
	

	open LIST, "> $script/$server\_dirfiles.lst" or die $!;
	
foreach (@files) {
	my $dec = $dec-1;
	print LIST  $_, " " x (30-length($_));
        print LIST  "d" if -d $_;
       	print LIST  "r" if -r _;
       	print LIST  "w" if -w _;
       	print LIST  "x" if -x _;
       	print LIST  "o" if -o _;
       	print LIST  "\t";
	print LIST  ctime(stat($_)->mtime) ."\t";
       	print LIST  -s _ if -r _ and -f _;
        print LIST  "\n" if($dec!=0);
}
}


&get_list($xhd, "xhd");
&get_list($xap, "xap");
&get_list($xco, "xco");
&get_list($xdc, "xdc");
&get_list($xsj, "xsj");
