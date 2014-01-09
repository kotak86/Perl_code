
Please consider only below file for assignmenti; 

Checkfile.pl
MyModule.pl
t/MyModule.t
reset_demo
reset_test

Rest of the file are for test perpose.
-------------------------------------------------------------------------------------------------------------
Exercise #1 => Module which can locate all files in a specified directory and sub-directories that are world
               writeable remove the world write permission without altering the user or group permissions
Exercise #2 => Script which Use MyModule , can accept director(y|ies) from the command line
Exercise #4 => Script has option to run with the specific UID
-------------------------------------------------------------------------------------------------------------
Demo: Script which uses  MyModule

First of all run below command in Given (CPanel) directory.

chmod 766 reset_*

To run the Script with the Given Testsuite, Please run reset_demo file first as,

./reset_demo . Then run the script

Perl Checkfile.pl --- it will display the usage of script.

e.g. Perl Checkfile.pl --dir Dir1 Dir2 file1 --verbose --uid xxxx
	 Perl Checkfile.pl --dir Dir1 --verbose
	 Perl Checkfile.pl --dir Dir1
	 

-------------------------------------------------------------------------------------------------------------
Exercise #3 => How to Use Script:
-------------------------------------------------------------------------------------------------------------
Testscript(MyModule.t) to test  MyModule.pm file:
To test the Script with the Given Testsuite, Please run reset_demo file first as,

./reset_test

Open directory  t/MyModule.t file and make below changes:
For test #8, test #9, test #10 Provide, real file uid based on your system 
as last parameter for the function RemWwPerm() & CheckUid() respectively;

i.e. replace, '1434164' wiht any real file UID from your system
-------------------------------------------------------------------------------------------------------------

Please let me know if you have any question related to this assignment. 
You can reach me at 408 228 7284 0r kotak86@gmail.com

Thanks
Ankit Kotak

