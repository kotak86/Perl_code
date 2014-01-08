#! cd .
#============================================================ -*- Makefile -*-
# Subsystem root makefile for Misc/BuildTools
#
#
default:
	@$(ECHO) No target specified -- building nothing

!ReleaseType executable { \
compressed = 'no'; \
permissions = 0555; \
}


FASTGEN_FILES = FastGen2.bs FastGen2.so FastGen2.so_20031128

!O primary
!ReleaseFiles release_checked_in executable $(FASTGEN_FILES) \
     { release_directory = "bin/Arizona/bin/gentests/blib/lin"; }
