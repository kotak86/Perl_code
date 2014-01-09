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

release_checked_in:
!subbld XML

FASTGEN_FILES = FastGen2.dll FastGen2.dll_20031128 FastGen2.exp_20021213 FastGen2.lib FastGen2.lib_20031128 FastGen2.bs FastGen2.dll_20021213 FastGen2.exp FastGen2.exp_20031128 FastGen2.lib_20021213

!O primary
!ReleaseFiles release_checked_in executable $(FASTGEN_FILES) \
     { release_directory = "bin/Arizona/bin/gentests/blib/nt"; }
