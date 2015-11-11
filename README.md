# CiA

-  toolkit for Pascal DOS apps (16bit real or protected mode, 386+)
-  covers both low layers (memory, keyboard, mouse, graphics/text, scrolling..)
-  and a bit higher ones (loaders/players, fileselector and other dialogs...)
-  it does not touch audio (use http://github.com/StepanHrbek/RAIN for audio)
-  for examples, see pr_*.pas
-  for build instructions, see BUILD.md
-  for an example of CiA based app, see http://github.com/StepanHrbek/Machina

## Units overview

   UNIT    | DESCRIPTION
   --------|---------------------------------------------------------------
   Baby    | graphics for babies (can't be easier)
   Cache   | cache for objects
   CS      | codepage conversion
   Chyby   | error management
   DPMI    | DPMI services
   Fajly   | disks, files, PCK
   Flc*    | decoder/player FLI/FLC
   FnExpand| font editor support
   Fonty   | bitmap fonts (format FN)
   INI     | config files (format INI)
   Key     | keyboard handler
   Lang1   | 1 language built in
   Lang2   | 2 languages built in
   LangFile| any number of languages in files
   Ld*     | loaders of GIF/PCX/X/TGA/TXT
   Loadery | loading images (easily extensible)
   Memo    | memory management (universal for real+protected, blocks over 64KB)
   Mys     | mouse management
   Num     | numeric conversions
   Scrol   | scrolling engine from Deus ex Machina, any mode/any bitmap size
   Streamy | stream helpers
   Stringy | string management
   Sys     | system helpers (partial crt replacement, accurate time)
   Texty   | long text management
   Timer   | ray synchronization
   Tools   | various helpers
   VGA     | vga, vesa, bitmaps (universal for all modes, avoids VGA/VESA bugs)

   More detailed desriptions are inside units.
                                   

   OTHER FILE    | DESCRIPTION
   --------------|------------------------------------------------------------
   bit2scr.inc   | double include for vga.pas
   define.inc    | global $define for all units
   fn.pas        | separated font converter fn.exe
   gui1.inc      | interface GUI
   gui2.inc      | implementation GUI
   initdone.inc  | standard init/done include for all units
   lang.cz       | text file with Czech localization
   lang.eng      | text file with English localization
   lang-.inc     | identifiers of localized texts
   lang1.inc     | array of localized texts
   lang1inc.*    | generates lang1.inc
   modern.fn     | some proportional font
   moder_np.fn   | some non-proportional font
   pr*.*         | examples
   sbit2scr.inc  | double include for scrol.pas
   sele.inc      | dialogs fileselector and pathbrowser
   dpmi.*,timer.*| subset of Midas necessary when full Midas is not used
   midasfix\*.*  | bugfixes to apply when full Midas is used


## Unit dependencies

  <pre>
         timer               lang1/2
        /                   /
   chyby-----key-----sys--fajly-------------------
        \  (/)      /  \    \                     \
   dpmi--memo==stringy--mys--VGA---loadery--ldtga  \
           \     \  \         \           \         \
            \     \  cache-----fonty-------ldtxt     >-langfile,ini
             \     \            \         /         /
   streamy    \     cs,num       dialogy /         /
               \                /       /         /
                texty-----------------------------

  --- right one needs the left one
  (/) only in protected                     timer+ini+fonty--scrol--tools
  === both directions

  </pre>


## Conventions

-  Comments are not yet compiled into *.TPH help,
   so you can find main unit comment at the beginning of unit,
   variables are commented around their declaration,
   functions are commented around their implementation.
-  If there is code after the last "end", it could be
   candidates for inclusion into CiA, but it needs more testing.
-  Units after "uses" go in following order: Chyby, Memo,
   standard Borland units, other units.
-  Member procedures are 'Procedure', non-object ones are usually 'PROCEDURE'.
-  English is used for all new developments, amount of Czech can only decrease.
-  When procedure says 'Does not change registers', it's not 100%.
   AX changes if you enable stack checking and procedure uses stack
   (stack is used for parameters, local variables and for member procedures).
-  Comment {* marks place with unfinished work.
-  When speed is important, code is optimized for speed,
   otherwise for simplicity.
-  All Czech characters (in messages, fonts) use "Kamenickych" encoding
   https://en.wikipedia.org/wiki/Kamenick%C3%BD_encoding


## Commandline arguments

   Each unit can read its own parameters from commandline.
   Those considered 'own' are processed and marked in paramUsed array,
   so other units can ignore them.

   UNIT | COMMANDLINE          | DESCRIPTION
   -----|----------------------|----------------------------------------------
   Memo | file.swp [megabytes] | create swapfile of this size (default is 16)
   Chyby| :lang                | select language (default is eng)
   VGA  | +bits                | use only models with this # of bits per pixel
   VGA  |  bits                | use only -"-
   VGA  | -bits                | don't use -"- (where "4 bits" is textmode)
   VGA  | AxisRelLimit         | let only resolutions which pass this test
      
                   Axis  is X or Y
                   Rel   is one of
                             <
                             <=
                             =<
                             =
                             ==
                             !=
                             =>
                             >=
                             >
                             lt (Less Than)
                             eq (EQual to)
                             gt (Greater Than)
                             le (Less or Equal to)
                             ne (Not Equal to)
                             ge (Greater or Equal to)
                   Limit is number of pixels (chars in textmode)

     Note that < and > symbols have special meaning (redirection) in DOS.
     If you want to use them in parameter, enclose whole parameter into ""
      (it works under MS-DOS 7.00, not yet tested elsewhere).
     Examples: xlt800 "y<600"

