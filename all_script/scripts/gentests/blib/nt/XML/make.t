#! cd .
#============================================================ -*- Makefile -*-
# Subsystem root makefile for Misc/BuildTools
#
#
default:
	@$(ECHO) No target specified -- building nothing

release_checked_in:
!subbld DOM

!m PERL_LIBRARIES = *.pm

!O primary
!ReleaseFiles release_checked_in file $(PERL_LIBRARIES) \
     { release_directory = "bin/Arizona/bin/gentests/blib/nt/XML"; }
