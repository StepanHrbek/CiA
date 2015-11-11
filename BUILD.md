# Building CiA

- Get Turbo Pascal or Borland Pascal 7 with standard set of units.
  Turbo Pascal is sufficient for smaller projects, Borland Pascal is necessary
  for big ones. CiA was not tested with other compilers.
- Run BP.EXE, open "Options/Directories" and set
   - "Include Directories" to directory with CiA (e.g. \CIA)
   - "Unit Directories"    to CiA and Borland units (e.g. \CIA;\BP\UNITS)
   - "Object Directories"  to CiA (e.g. \CIA)
   Save settings (for example with "Options/Save as/BP.TP").
- You can configure BP for real or protected mode, both work.
- Now you can try running PR_*.PAS examples.

BTW, CiA does not suffer from famous Borland runtime error 200 on fast computers.


## Using Midas 0.40

- For audio, RAIN is recommended over Midas.
- If you really need Midas, you can get it from s2.org.
- Remove dpmi.*, timer.* from CiA.
- To fix Midas errors and add IFF+WAV support,
   overwrite Midas sources with our MIDASFIX.
- Write paths to compilers and CiA to MIDAS*.MAK files.
- Rebuild Midas with make.


## TB/BP specifics we use (what could break with other compiler)

- Evaluation order (ex: GetWord=GetByte shl 8+GetByte).
- Break preserves cycle variable.
- Layout of variables in memory.
- Stack direction on x86.
- Register passing of result.
- Ending procedures with ret.
- Objects, directives, absolute, asm.
- We suppose DF=0. If you set it, don't forget to clear it.
- We freely use FS and GS.
   When FS or GS is left with selector destroyed by FreeMem, Borland doesn't
   handle it well, it sometimes crashes under DPMI 0.9 (old Win NT).
   It's ok with DPMI 1.0. So we better clear FS and GS in our FreeMem.
   Unfortunately we can't rewrite Dispose, so risk exists here.
   Fortunately it's really only problem of very old Win NT.
