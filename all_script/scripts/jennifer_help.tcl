Hi Ankit,

Get_parts is a tcl command built into Vivado.  It is not a stand-alone executable.

Start Vivado like this:
vivado -mode tcl
Then at the vivado prompt type get_parts, like this:
Vivado% get_parts -help
Here is an example of using get_parts with filtering:
Vivado% set parts [get_parts -filter "lut_elements > 8000 && family=~kintex7"]
This will report the properties on the first item in the $parts list that you get from the above command:
Vivado% report_property [lindex $parts 0]
This will get the number of DSPS from the property on all of the part objects from $parts
Vivado% get_property dsps $parts

Hope that helps.  Let me know if you run into more trouble.

Regards,
Jenny


 if($modify =~ m@\/pcores\/\w+\/hdl\/@){
	print"hi";print $modify;
	}
