#*      MIDASTPU.MAK
#*
#* Make script for MIDAS Sound System Borland Pascal real mode units
#*
#* Copyright 1995 Petteri Kangaslampi and Jarno Paananen
#*
#* by D.Ment:
#*  problem with echo \b detected and fixed
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
ECHOBCDIR = \\\bc
 # echo v MS-DOSu 7 interpretuje \\ jako \ a \b jako backspace i b ??
LIBDIR = \bc\lib
PCDIR = \bp
ASMDIR = \tasm
CIADIR = \cia


# Compilers and options:

CC = $(BCDIR)\bin\bcc
CCOPTS = -c -3 -G- -ml -O1 -I\$(ECHOBCDIR)\include -D__BPREAL__
PC = $(PCDIR)\bin\bpc
PCOPTS = /$G+ /$X+ /CD /GS /Q /D__BPREAL__ /U$(PCDIR)\units /U$(CIADIR) /I$(CIADIR)
ASM = $(ASMDIR)\tasm
ASMOPTS = -UT310 -ml -m9 -d__BPREAL__


!ifdef CUTDOWN
ASMOPTS = $(ASMOPTS) -dNOLOADERS -dNOCMDNAMES -dNOEMS -dCUTDOWN
CCOPTS = $(CCOPTS) -DNOLOADERS -DNOCMDNAMES -DNOEMS -DCUTDOWN
PCOPTS = $(PCOPTS) /DNOLOADERS /DNOCMDNAMES /DNOEMS /DCUTDOWN
!endif


all : ccopts asmopts midas.tpu mconfig.tpu mparser.tpu mm.tpu

ccopts :
        echo $(CCOPTS) > ccopts

asmopts :
        echo $(ASMOPTS) > asmopts


midas.tpu : midas.pas errors.tpu mglobals.tpu mmem.tpu mfile.tpu \
        sdevice.tpu mplayer.tpu s3m.tpu modp.tpu mtm.tpu timer.tpu \
        mutils.tpu ems.tpu vu.tpu vgatext.tpu
        $(PC) midas.pas $(PCOPTS)

mparser.tpu : mparser.pas mparser.obj midas.tpu mutils.tpu mmem.tpu \
        mGlobals.tpu Errors.tpu
        $(PC) mparser.pas $(PCOPTS)

mparser.obj : mparser.c midas.h
        $(CC) @ccopts mparser.c

mconfig.tpu : mconfig.pas mconfig.obj midas.tpu sdevice.tpu mutils.tpu \
        vgatext.tpu mfile.tpu mmem.tpu
        $(PC) mconfig.pas $(PCOPTS)

mconfig.obj : mconfig.c midas.h
        $(CC) @ccopts mconfig.c

mm.tpu : mm.pas mm.obj midas.tpu mmem.tpu
        $(PC) mm.pas $(PCOPTS)

mm.obj : mm.c midas.h
        $(CC) @ccopts mm.c



mutils.tpu : mutils.pas mutils.obj
        $(PC) mutils.pas $(PCOPTS)

mutils.obj : mutils.asm lang.inc mutils.inc
        $(ASM) @asmopts mutils.asm



errors.tpu : errors.pas
        $(PC) errors.pas $(PCOPTS)

mglobals.tpu : mglobals.pas
        $(PC) mglobals.pas $(PCOPTS)

mmem.tpu : mmem.pas errors.tpu
        $(PC) mmem.pas $(PCOPTS)


ems.tpu : ems.pas mmem.tpu errors.tpu ems.obj
        $(PC) ems.pas $(PCOPTS)

ems.obj : ems.asm lang.inc errors.inc ems.inc mmem.inc
        $(ASM) @asmopts ems.asm


dma.tpu : dma.pas dma.obj mmem.tpu errors.tpu mglobals.tpu
        $(PC) dma.pas $(PCOPTS)

dma.obj : dma.asm lang.inc errors.inc dma.inc mmem.inc
        $(ASM) @asmopts dma.asm


sdevice.tpu : sdevice.pas errors.tpu mmem.tpu mutils.tpu mglobals.tpu \
        dsm.tpu dma.tpu ems.tpu gus.obj pas.obj wss.obj sb.obj nsnd.obj
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


dsm.tpu : dsm.pas dsm.obj errors.tpu mglobals.tpu mmem.tpu ems.tpu
        $(PC) dsm.pas $(PCOPTS)

dsm.obj : dsm.asm lang.inc errors.inc mglobals.inc dsm.inc mmem.inc \
        sdevice.inc
        $(ASM) @asmopts dsm.asm


timer.tpu : timer.pas timer.obj errors.tpu mglobals.tpu ems.tpu
        $(PC) timer.pas $(PCOPTS)

timer.obj : timer.asm errors.inc mglobals.inc lang.inc timer.inc sdevice.inc \
        ems.inc
        $(ASM) @asmopts timer.asm


mplayer.tpu : mplayer.pas
        $(PC) mplayer.pas $(PCOPTS)


s3m.tpu : s3m.pas s3m.obj s3mload.obj errors.tpu mglobals.tpu mmem.tpu \
        mplayer.tpu sdevice.tpu mfile.tpu mutils.tpu ems.tpu
        $(PC) s3m.pas $(PCOPTS)

s3m.obj : s3m.asm lang.inc errors.inc mglobals.inc s3m.inc mplayer.inc \
        sdevice.inc mmem.inc ems.inc
        $(ASM) @asmopts s3m.asm

s3mload.obj : s3mload.c mtypes.h errors.h mglobals.h mmem.h sdevice.h \
        mplayer.h s3m.h lang.h file.h mutils.h ems.h
        $(CC) @ccopts s3mload.c


modp.tpu : modp.pas mod.obj modload.obj errors.tpu mglobals.tpu mmem.tpu \
        mplayer.tpu sdevice.tpu mfile.tpu mutils.tpu ems.tpu
        $(PC) modp.pas $(PCOPTS)

mod.obj : mod.asm lang.inc errors.inc mglobals.inc mod.inc mplayer.inc \
        sdevice.inc mmem.inc ems.inc
        $(ASM) @asmopts mod.asm

modload.obj : modload.c mtypes.h errors.h mglobals.h mmem.h sdevice.h \
        mplayer.h mod.h lang.h file.h mutils.h ems.h
        $(CC) @ccopts modload.c


mtm.tpu : mtm.pas mtm.obj mtmload.obj errors.tpu mglobals.tpu mmem.tpu \
        mplayer.tpu sdevice.tpu mfile.tpu mutils.tpu ems.tpu
        $(PC) mtm.pas $(PCOPTS)

mtm.obj : mtm.asm lang.inc errors.inc mglobals.inc mtm.inc mplayer.inc \
        sdevice.inc mmem.inc ems.inc
        $(ASM) @asmopts mtm.asm

mtmload.obj : mtmload.c mtypes.h errors.h mglobals.h mmem.h sdevice.h \
        mplayer.h mtm.h lang.h file.h mutils.h ems.h
        $(CC) @ccopts mtmload.c


mfile.tpu : mfile.pas file.obj errors.tpu mmem.tpu rawfile.tpu
        $(PC) mfile.pas $(PCOPTS)

file.obj : file.c lang.h mtypes.h errors.h mmem.h file.h rawfile.h
        $(CC) @ccopts file.c


rawfile.tpu : rawfile.pas asmrfile.obj errors.tpu mmem.tpu
        $(PC) rawfile.pas $(PCOPTS)

asmrfile.obj : asmrfile.asm lang.inc errors.inc rawfile.inc mmem.inc
        $(ASM) @asmopts asmrfile.asm


vu.tpu : vu.pas vu.obj errors.tpu mmem.tpu
        $(PC) vu.pas $(PCOPTS)

vu.obj : vu.asm lang.inc errors.inc vu.inc mmem.inc sdevice.inc
        $(ASM) @asmopts vu.asm


vgatext.tpu : vgatext.pas vgatext.obj
        $(PC) vgatext.pas $(PCOPTS)

vgatext.obj : vgatext.asm lang.inc vgatext.inc
        $(ASM) @asmopts vgatext.asm
