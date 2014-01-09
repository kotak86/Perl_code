#! cd .
#============================================================ -*- Makefile -*-
# Subsystem root makefile for Misc/BuildTools
#
#
default:
	@$(ECHO) No target specified -- building nothing

!m PERL_LIBRARIES = *.pm
!m POD_FILES = *.pod

!O primary
!ReleaseFiles release_checked_in file $(PERL_LIBRARIES) \
     { release_directory = "bin/Arizona/bin/gentests/blib/nt/XML/DOM"; }

!O primary
!ReleaseFiles release_checked_in file $(POD_FILES) \
     { release_directory = "bin/Arizona/bin/gentests/blib/nt/XML/DOM"; }
