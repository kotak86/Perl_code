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

FASTGEN_FILES = FastGen2.so FastGen2.so_20030124 FastGen2.so_20031128 FastGen2.bs FastGen2.so_20021213 FastGen2.so_20030306 libgmp.so.3 RRDs.so

!O primary
!ReleaseFiles release_checked_in executable $(FASTGEN_FILES) \
     { release_directory = "bin/Arizona/bin/gentests/blib/sol"; }
