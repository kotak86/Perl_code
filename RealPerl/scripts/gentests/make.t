#! cd .
#============================================================ -*- Makefile -*-
# Subsystem root makefile for Misc/BuildTools
#
#

default:
	@$(ECHO) No target specified -- building nothing

release_checked_in:
!subbld blib hide

!ReleaseType executable { \
compressed = 'no'; \
permissions = 0555; \
}

!m PERL_LIBRARIES = *.pm
!m PERL_FILES = *.pl

!O primary
!ReleaseFiles release_checked_in executable $(PERL_FILES) \
     { release_directory = "bin/Arizona/bin/gentests"; }

!O primary
!ReleaseFiles release_checked_in file $(PERL_LIBRARIES) \
     { release_directory = "bin/Arizona/bin/gentests"; }
