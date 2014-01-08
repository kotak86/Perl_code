#!/usr/bin/perl
use strict;
use warnings;
use Spreadsheet::WriteExcel;
    
my $workbook   = Spreadsheet::WriteExcel->new("bshifter_timing_analysis.xls");
my $worksheet  = $workbook->add_worksheet('bshifter_timing_analysis');
my $list_of_reports =  "/home/ankitko/ankit/barrelshifter/list";	
my $row = 0;
open LIST,  $list_of_reports or die $!;	
my @array_reports = <LIST>;


foreach my $rpt(@array_reports){
	
	my $file =  $rpt;
	my $design_name1 = $file;	my @d_name = split /\//, $design_name1;  $d_name[$#d_name] =~ s/\_timing\_report\.rpt//g; chomp($d_name[$#d_name]);
	my $design_name = $d_name[$#d_name];
	my $capture_data = 0 ;
	
	my @logic_delay;
	my @net_delay;
	my @all_delay ;
	my @delay ;
	my $slack;
	my $i =0;
	my $j =0;


	 my $format = $workbook->add_format();
		$format->set_bold();
		$format->set_color('red');
		$format->set_align('center');


		$worksheet->set_column('A:C', 25); 
		$worksheet->set_column('D:I', 10);
		$worksheet->set_column('J:J', 16);
		$worksheet->set_column('K:L', 32); 
		$worksheet->set_column('M:M', 16); 
		$worksheet->set_column('N:O', 32); 
		$worksheet->set_column('P:P', 16);
		$worksheet->set_column('Q:R', 32); 	
		
		
		$worksheet->write(0,0,"DESIGN NAME", $format);   
		$worksheet->write(0,1,"START PT", $format);		
		$worksheet->write(0,2,"END PT", $format);  
		$worksheet->write(0,3,"CLOCK", $format);
		$worksheet->write(0,4,"SLACK", $format);
		$worksheet->write(0,5,"P DELAY", $format);   
		$worksheet->write(0,6,"% L DELAY", $format);   
		$worksheet->write(0,7,"% N DELAY", $format);		
		$worksheet->write(0,8,"# L LEVEL", $format);  
		$worksheet->write(0,9,"TOP DELAY", $format);
		$worksheet->write(0,10,"START PT", $format);		
		$worksheet->write(0,11,"END PT", $format);
		$worksheet->write(0,12,"2 nd DELAY", $format);   
		$worksheet->write(0,13,"START PT", $format);		
		$worksheet->write(0,14,"END PT", $format);
		$worksheet->write(0,15,"3 rd DELAY", $format);	
		$worksheet->write(0,16,"START PT", $format);		
		$worksheet->write(0,17,"END PT", $format);
	   
		open FILE, $file or die "can't open $!";
		my @lines = <FILE>;
		foreach (@lines){
			
			if ($_ =~ /Slack/){
				my @line = split /:/, $_;
				$line[1] =~ s/\s+//g;
				$slack = $line[1];
				$capture_data = 1;
				$i++ ; $row++
			
			}
			
			if ($capture_data) {
				
				if ($_ =~ /Slack|Source|Destination|Data Path Delay|net|Prop_|Setup_|Logic Levels|Requirement/){
					
					if ($_ =~ /Source:/){ 
						$worksheet->write($row,0, "$design_name"."[$i]"); # 0 => Col A ; row = 1,..
						my @line = split/:/, $_;
						$line[1] =~ s/\s+//g;
						chomp($line[1]);
						$worksheet->write($row,1,$line[1]); # 1=> col B; row = 1, ..
							
					}
					
					if ($_ =~ /Destination:/){ 
						my @line = split/:/, $_; 
						$line[1] =~ s/\s+//g;
						chomp($line[1]);
						$worksheet->write($row,2,$line[1]); # 2 => col C; row = 1,...
						
					}
					
					if ($_ =~ /Requirement:/){ 
						my @line = split/:/, $_; 
						$line[1] =~ s/\s+//g;
						chomp($line[1]);
						$worksheet->write_number($row,3,$line[1]); # 3 => col D; row = 1,...
						$worksheet->write_number($row,4,$slack); # 4 => col E; row = 1,...
					}
						
					if ($_ =~ /\bData Path Delay\b/){ 
						my @line1 = split/:/, $_;
						chomp($line1[1]); 
						my @line = split /\s+/, $line1[1]; $line[4] =~ s/\(|\)//g;$line[7] =~ s/\(|\)//g;
						$worksheet->write_number($row,5,$line[1]);	
						$worksheet->write_number($row,6,$line[4]);	# 5, 6, 7 => col F, G, H
						$worksheet->write_number($row,7,$line[7]);	
					}
					
						if ($_ =~ /Logic Levels:/){ 
						my @line1 = split/:/, $_; 
						my @line = split/\s+/, $line1[1]; 
						$line[1] =~ s/\s+//g;
						chomp($line[1]); 
						$worksheet->write($row,8,$line[1]);		#8 => col I, row = 1,...				
					}
					
					if($_ =~ /\bnet\b/){
						my @line = split /\s+/, $_;
						chop($line[2]); 
						$lines[$j+1] =~ s/\s+/ /g;
						my @end_pt = split / /,$lines[$j+1]; 
						$end_pt[$#end_pt] =~ s/\s+//g;
						my $st_pt  = $line[$#line];
						my $End_pt = $end_pt[3];
						my $n_delay = "$line[4](N)-$line[2]) $st_pt  $End_pt";
						push (@net_delay, $n_delay); 	
					}

					elsif($_ =~ /Prop_|Setup_/){
						my @line = split /\s+/, $_;
						$lines[$j-1] =~ s/\s+/ /g;
						my @st_pt = split / /,$lines[$j-1];
						my $st_pnt = $st_pt[$#st_pt];
						my $end_pt = $line[$#line];
						my $l_delay = "$line[4](L) $st_pnt  $end_pt";
						push (@logic_delay, $l_delay); 	
					}

				}
			
				elsif($_ =~ /slack/){

					$capture_data = 0; 					
					@all_delay = (@net_delay, @logic_delay);
					@delay = reverse sort @all_delay;
					
					for(my $t=0, my $col =9; $t<3; $t++){
						my @delay_st = split / /, $delay[$t];
						$worksheet->write($row,$col++,$delay_st[0]); #9, 10, 11 => col J, K, L for first delay
						$worksheet->write($row,$col++,$delay_st[1]); #12,13,14  => col M, N, O for 2 nd delay
						$worksheet->write($row,$col++,$delay_st[3]); # 15, 16, 17 => col P, Q, R
						
					
					}
					@logic_delay = ();
					@net_delay = ();
					@all_delay = ();
					@delay = ();
					
				}

			}

			$j++;
	}
	
	$i = 0; $row++; close FILE;
	
}
close LIST;		