

>-----Original Message-----
>From: Jennifer Baldwin [mailto:Jennifer.Baldwin@xilinx.com]
>Sent: Friday, March 23, 2012 12:30 PM
>To: Hemang Shah
>Subject:
>
>#-----------------------------------------------------------
># Vivado v2012.1.OR0 (64-bit)
># Built by jenny on Tue Mar 13 09:11:19 MDT 2012
># Start of session at: Fri Mar 23 13:08:09 2012
># Process ID: 26663
># Log file: /proj/xcohdstaff/jenny/work1/HEAD/test/vivado.log
># Journal file: /proj/xcohdstaff/jenny/work1/HEAD/test/vivado.jou
>#-----------------------------------------------------------
>open_project diskless.tcl
>get_parts
>set parts [get_parts xc7v*]
>puts $parts
>set parts [get_parts xa7a100tcsg324]
>report_property $parts
>set parts [get_parts xa7a100tcsg324*]
>set parts [get_parts]
>foreach part $parts {report_property $part}
>get_property dsp [get_parts]
>get_property dsps [get_parts]
>get_property dsps [get_parts xa7a100tcsg324*]
>get_parts -filter {dsps >= 240}
>get_parts -filter {dsps >= 100}
>get_parts -filter {dsps >= 100 && luts > 1000}
>get_parts -filter {dsps >= 100 && luts > 100}
>get_parts -filter {luts > 100}
>report_property $part
>puts $part
>set parts [get_parts xc7v*]
>list_property $parts
>list_property [lindex $parts 0]
>get_parts -filter {dsps >= 100 && lut_elements > 100}
>get_parts -filter {dsps >= 100 && lut_elements > 1000}
>get_parts -filter {dsps >= 100 && lut_elements > 8000}
>get_parts -filter {dsps >= 100 && lut_elements > 8000 && family =~
>kintex7}
>set kintex_parts [get_parts -filter {dsps >= 100 && lut_elements > 8000
>&& family =~ kintex7}]
>report_property [lindex $kintex_parts 10]
>history
>pwd
