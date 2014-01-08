#!/tools/xgs/perl/5.8.5/bin/perl
    use strict;
    use warnings;
    use Date::Calc qw(Delta_Days);
    use POSIX ();
    my $list_dir = "/proj/ipco/users/hshah/ankit/scripts/list_dir.ls";

      unless (-e "$list_dir"){
     	print "The file list_dir.ls not found at". "$list_dir/..";
            exit;
       }


    require $list_dir;

sub clean_dir {
    
     my $dir = shift;

    	my @tday = (localtime)[5,4,3]; print "The array \@tday is @tday\n";
    	my $flag = 0;
    	my $offset = shift;
	
	print "The offset is $offset\n";
    	print $tday[0] += 1900;  
    	$tday[1]++;
	
	my @preserve_list = @_;
	print "\nData to be preserved : @preserve_list\n";	
	if ($tday[1] < 10){
           $tday[1] = "0$tday[1]";
        }

        print $tday[1];

        if($tday[2] <10 ){
           $tday[2] = "0$tday[2]";

        }

	print $tday[2]; print "\n";
        print "Again The array \@tday is @tday\n";

	print $dir; print "\n";

	opendir(DIR, $dir) or die "could not open $!";
	my @dir = grep { !/^\.+$/ } 
	readdir(DIR);
	closedir(DIR);

	foreach (@dir)
	{

		foreach my $keep(@preserve_list){
			if ($_ eq $keep){
				print "The file or dir $_ exits in \@keep_safe array.\n";
				$flag = 1;
		
			}
		}

		if ($flag != 1) {
			my $file = "$dir/$_";
			my $mtime = (stat($file))[9];
		      	my $fd_date =  POSIX::strftime("%Y %m %d", localtime($mtime));
			my @fileordir_date = split / /, $fd_date;
	    		my $days = Delta_Days(@fileordir_date, @tday);
			if($days >  $offset){
			#	print "Last change:\t @fileordir_date date ";
				print "$_ is $days days old, hence to be removed.\n"; 
			#	my $task = `rm -rf $dir/$_`;
			}
		}
		$flag = 0;

	}



}

