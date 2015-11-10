#*      MIDASTPP.MAK
#*
#* Make script for MIDAS Sound System Borland Pascal protected mode units
#*
#* Copyright 1995 Petteri Kangaslampi and Jarno Paananen
#*
#* by D.Ment:
#*  fix: NOEMS added to cc/pc/asmopts
#*  some include directories added to work with CiA
#*
#* This file is part of the MIDAS Sound System, and may only be
#* used, modified and distributed under the terms of the MIDAS
#* Sound System license, LICENSE.TXT. By continuing to use,
#* modify or distribute this file you indicate that you have
#* read the license and understand and accept it fully.
#*



# Compiler directories:

BCDIR = \bc
LIBDIR = \bc\lib
PCDIR = \bp
ASMDIR = \tasm
CIADIR = \cia


# Compilers and options:

CC = $(BCDIR)\bin\bcc
CCOPTS = -c -3 -G- -ml -O1 -I$(BCDIR)\include -D__BPPROT__ -DNOEMS
PC = $(PCDIR)\bin\bpc
PCOPTS = /$G+ /$X+ /CP /GS /Q /D__BPPROT__ /DNOEMS /U$(PCDIR)\units /U$(CIADIR) /I$(CIADIR)
ASM = $(ASMDIR)\tasm
ASMOPTS = -UT310 -ml -m9 -d__BPPROT__ -dNOEMS


!ifdef CUTDOWN
ASMOPTS = $(ASMOPTS) -dNOLOADERS -dNOCMDNAMES -dCUTDOWN
CCOPTS = $(CCOPTS) -DNOLOADERS -DNOCMDNAMES -DCUTDOWN
PCOPTS = $(PCOPTS) /DNOLOADERS /DNOCMDNAMES /DCUTDOWN
!endif


all : ccopts asmopts midas.tpp mconfig.tpp mparser.tpp mm.tpp

ccopts :
        echo $(CCOPTS) > ccopts

asmopts :
        echo $(ASMOPTS) > asmopts


midas.tpp : midas.pas errors.tpp mglobals.tpp mmem.tpp mfile.tpp \
        sdevice.tpp mplayer.tpp s3m.tpp modp.tpp mtm.tpp timer.tpp \
        mutils.tpp vu.tpp vgatext.tpp
        $(PC) midas.pas $(PCOPTS)

mparser.tpp : mparser.pas mparser.obj midas.tpp mutils.tpp mmem.tpp \
        mGlobals.tpp Errors.tpp
        $(PC) mparser.pas $(PCOPTS)

mparser.obj : mparser.c midas.h
        $(CC) @ccopts mparser.c

mconfig.tpp : mconfig.pas mconfig.obj midas.tpp sdevice.tpp mutils.tpp \
        vgatext.tpp mfile.tpp mmem.tpp
        $(PC) mconfig.pas $(PCOPTS)

mconfig.obj : mconfig.c midas.h
        $(CC) @ccopts mconfig.c

mm.tpp : mm.pas mm.obj midas.tpp mmem.tpp
        $(PC) mm.pas $(PCOPTS)

mm.obj : mm.c midas.h
        $(CC) @ccopts mm.c



mutils.tpp : mutils.pas mutils.obj
        $(PC) mutils.pas $(PCOPTS)

mutils.obj : mutils.asm lang.inc mutils.inc
        $(ASM) @asmopts mutils.asm



errors.tpp : errors.pas
        $(PC) errors.pas $(PCOPTS)

mglobals.tpp : mglobals.pas
        $(PC) mglobals.pas $(PCOPTS)

mmem.tpp : mmem.pas errors.tpp
        $(PC) mmem.pas $(PCOPTS)

dpmi.tpp : dpmi.pas errors.tpp dpmi.obj
        $(PC) dpmi.pas $(PCOPTS)

dpmi.obj : dpmi.asm lang.inc errors.inc dpmi.inc
        $(ASM) dpmi.asm @asmopts


dma.tpp : dma.pas dma.obj mmem.tpp errors.tpp mglobals.tpp dpmi.tpp
        $(PC) dma.pas $(PCOPTS)

dma.obj : dma.asm lang.inc errors.inc dma.inc mmem.inc
        $(ASM) @asmopts dma.asm


sdevice.tpp : sdevice.pas errors.tpp mmem.tpp mutils.tpp mglobals.tpp \
        dsm.tpp dma.tpp dpmi.tpp gus.obj pas.obj wss.obj sb.obj nsnd.obj
        $(PC) sdevice.pas $(PCOPTS)

gus.obj : gus.asm lang.inc mglobals.inc sdevice.inc mmem.inc mglobals.inc \
        errors.inc mutils.inc
        $(ASM) @asmopts gus.asm

pas.obj : pas.asm pas.inc lang.inc errors.inc sdevice.inc dsm.inc dma.inc
        $(ASM) @asmopts pas.asm

wss.obj : wss.asm lang.inc errors.inc sdevice.inc dsm.inc dma.inc
        $(ASM) @asmopts wss.asm

sb.obj : sb.asm lang.inc errors.inc sdevice.inc dsm.inc dma.inc
        $(ASM) @asmopts sb.asm

nsnd.obj : nsnd.asm lang.inc errors.inc sdevice.inc mmem.inc mglobals.inc
        $(ASM) @asmopts nsnd.asm


dsm.tpp : dsm.pas dsm.obj errors.tpp mglobals.tpp mmem.tpp dpmi.tpp
        $(PC) dsm.pas $(PCOPTS)

dsm.obj : dsm.asm lang.inc errors.inc mglobals.inc dsm.inc mmem.inc \
        sdevice.inc
        $(ASM) @asmopts dsm.asm


timer.tpp : timer.pas timer.obj errors.tpp mglobals.tpp
        $(PC) timer.pas $(PCOPTS)

timer.obj : timer.asm errors.inc mglobals.inc lang.inc timer.inc sdevice.inc \
        ems.inc
        $(ASM) @asmopts timer.asm


mplayer.tpp : mplayer.pas
        $(PC) mplayer.pas $(PCOPTS)


s3m.tpp : s3m.pas s3m.obj s3mload.obj errors.tpp mglobals.tpp mmem.tpp \
        mplayer.tpp sdevice.tpp mfile.tpp mutils.tpp
        $(PC) s3m.pas $(PCOPTS)

s3m.obj : s3m.asm lang.inc errors.inc mglobals.inc s3m.inc mplayer.inc \
        sdevice.inc mmem.inc ems.inc
        $(ASM) @asmopts s3m.asm

s3mload.obj : s3mload.c mtypes.h errors.h mglobals.h mmem.h sdevice.h \
        mplayer.h s3m.h lang.h file.h mutils.h ems.h
        $(CC) @ccopts s3mload.c


modp.tpp : modp.pas mod.obj modload.obj errors.tpp mglobals.tpp mmem.tpp \
        mplayer.tpp sdevice.tpp mfile.tpp mutils.tpp
        $(PC) modp.pas $(PCOPTS)

mod.obj : mod.asm lang.inc errors.inc mglobals.inc mod.inc mplayer.inc \
        sdevice.inc mmem.inc ems.inc
        $(ASM) @asmopts mod.asm

modload.obj : modload.c mtypes.h errors.h mglobals.h mmem.h sdevice.h \
        mplayer.h mod.h lang.h file.h mutils.h ems.h
        $(CC) @ccopts modload.c


mtm.tpp : mtm.pas mtm.obj mtmload.obj errors.tpp mglobals.tpp mmem.tpp \
        mplayer.tpp sdevice.tpp mfile.tpp mutils.tpp
        $(PC) mtm.pas $(PCOPTS)

mtm.obj : mtm.asm lang.inc errors.inc mglobals.inc mtm.inc mplayer.inc \
        sdevice.inc mmem.inc ems.inc
        $(ASM) @asmopts mtm.asm

mtmload.obj : mtmload.c mtypes.h errors.h mglobals.h mmem.h sdevice.h \
        mplayer.h mtm.h lang.h file.h mutils.h ems.h
        $(CC) @ccopts mtmload.c


mfile.tpp : mfile.pas file.obj errors.tpp mmem.tpp rawfile.tpp
        $(PC) mfile.pas $(PCOPTS)

file.obj : file.c lang.h mtypes.h errors.h mmem.h file.h rawfile.h
        $(CC) @ccopts file.c


rawfile.tpp : rawfile.pas asmrfile.obj errors.tpp mmem.tpp
        $(PC) rawfile.pas $(PCOPTS)

asmrfile.obj : asmrfile.asm lang.inc errors.inc rawfile.inc mmem.inc
        $(ASM) @asmopts asmrfile.asm


vu.tpp : vu.pas vu.obj errors.tpp mmem.tpp
        $(PC) vu.pas $(PCOPTS)

vu.obj : vu.asm lang.inc errors.inc vu.inc mmem.inc sdevice.inc
        $(ASM) @asmopts vu.asm


vgatext.tpp : vgatext.pas vgatext.obj
        $(PC) vgatext.pas $(PCOPTS)

vgatext.obj : vgatext.asm lang.inc vgatext.inc
        $(ASM) @asmopts vgatext.asm



