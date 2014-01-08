#! cd .
#============================================================ -*- Makefile -*-
# Subsystem root makefile for Misc/BuildTools
#
#

default:
	@$(ECHO) No target specified -- building nothing

!m PERL_LIBRARIES = *.pm
!m PERL_FILES = *.pl
OTHER_FILES = gentests_readme

!O primary
!ReleaseFiles release_checked_in file $(PERL_FILES) \
     { release_directory = "bin/Arizona/bin/gentests/hide"; }

!O primary
!ReleaseFiles release_checked_in file $(PERL_LIBRARIES) \
     { release_directory = "bin/Arizona/bin/gentests/hide"; }

!O primary
!ReleaseFiles release_checked_in file $(OTHER_FILES) \
     { release_directory = "bin/Arizona/bin/gentests/hide"; }
