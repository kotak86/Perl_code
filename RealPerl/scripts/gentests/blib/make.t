#! cd .
#============================================================ -*- Makefile -*-
# Subsystem root makefile for Misc/BuildTools
#
#

default:
	@$(ECHO) No target specified -- building nothing

release_checked_in:
!subbld lin sol nt
