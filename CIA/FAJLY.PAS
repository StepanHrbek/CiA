{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 2.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}

Unit      Fajly;
Interface {$i define.inc}
Uses      Chyby,Memo, Dos,Objects,Strings, {$ifdef dpmi}DPMI,{$endif} Stringy,Sys;
Function  Init:TError;
Procedure Done;

{
 ---------------------------------------------------------------------------
                                Koncepce
 ---------------------------------------------------------------------------

 Vsechny funkce na praci s disky jsou nazvane dskXXXX.
 Vsechny funkce na praci s adresari jsou nazvane dirXXXX.
 Vsechny funkce na praci se soubory jsou nazvane fileXXXX.

 Zadna funkce nevraci chybovy kod, pouze boolean jak to dopadlo.
 Presny popis chyb predavaji procedure ReportErr z unity chyby.

 Kdekoliv se mluvi o adresari, rozumi se tim string koncici znakem : ci \.

 Nektere funkce maji parametr flags, kterym si muzes prizpusobit jejich
 chovani vlastnim potrebam.

 Pokud funkce operuje s vice soubory a v prubehu nastane chyba,
 zalezi zda flags+globflags obsahuje
   fileIgnoreErr - ignorovat chybu a pokracovat v operaci na dalsich souborech
   fileStopIfErr - ukoncit celou operaci
   else          - zeptat se co delat (dialog),podle toho i nastavit globflags

 ---------------------------------------------------------------------------
                             Registr formatu
 ---------------------------------------------------------------------------
 V registru formatu je ulozen seznam formatu(typu souboru)a jejich vlastnosti.
 Registr vznika za behu a kdykoliv lze zaregistrovat nove formaty.

 Funkce fileIs(name) vraci vlastnosti souboru name.
 Tak naprilad fileIs('bagr.gif') vrati isLoadable+isGraphics+isFixedSize.

 Funkce fileFind(name,flags) se podiva na soubor name. Pokud ho nenajde,
 zkousi k name pripojovat zaregistrovane pripony (podle poradi registrace)
 dokud soubor nenajde. Zkousi jen pripony tech formatu, jejichz
 flags se kryji s flags zadanymi parametrem.
 Napr. fileFind('bagr',isLoadable+isGraphics)
 hleda jen graficke obrazky bagru, ne animace bagru nebo texty o bagru.

 Funkce fileMask(flags) vraci masku zahrnujici vsechny soubory se vsemi
 zadanymi flagy. Pokud jsou zaregistrovany formaty TGA, GIF, FLI a TXT,
 fileMask(isLoadable+isGraphics) vrati '*.TGA;*.GIF'.

 Registr lze dale rozvijet jako to cini napriklad unita Loadery, ktera
 si do nej pro kazdy format uklada jeste pointery na loader, writer apod.
}


Var       ReadOnlyMod:boolean;              {readonly rezim, potlaceni zapisu na disk}
          DeviceExists:boolean;             {ma fce fileExists uspet na device (prn, lpt1...)?}
          globflags:word;                   {globalni flagy, fce je mohou samy na pokyn uzivatele menit}
Type      FileStr=string[13];               {13.znak kvuli pripadnemu pouziti Str2Pc}

{disky}
Type      dskType=(dskNone,dskFloppy,dskHard,dskNet,dskCdrom);
FUNCTION  dskList:string;                   {vrati seznam dostupnych disku velkymi pismeny}
FUNCTION  dskName(dsk:char):FileStr;        {vrati jmeno drivu}
{$ifdef dosmem}
FUNCTION  dskSerialNumber(dsk:char):longint;{vrati seriove cislo disku}
{$endif}
FUNCTION  dskId(dsk:char):dskType;          {vrati typ disku}
FUNCTION  dskReady(dsk:char):boolean;       {vrati jestli je disk ready}
FUNCTION  dskBoot:char;                     {vrati bootovaci disk}
FUNCTION  dskCur:char;                      {vrati aktualni disk}
FUNCTION  dskExists(dsk:char):boolean;      {vrati zda disk existuje}
FUNCTION  dskCheck(dsk:char):boolean;       {vrati zda disk existuje a kdyz ne, ohlasi chybu}
FUNCTION  dskChange(dsk:char):boolean;      {zmeni aktualni disk}
FUNCTION  dskChangeIsSafe(dsk:char):boolean;{vrati jestli probehne dskChange(dsk) bez vynucene interakce s uzivatelem}
FUNCTION  dskSelectFantom(dsk:char):boolean;{vybere logicky disk}
FUNCTION  dskFantoms:string;                {seznam "Fantom"-disku¯}
FUNCTION  dskRemovable(dsk:char):Fuzzy;     {vrati jestli je disk vymenitelny}
FUNCTION  dskRemote(dsk:char):Fuzzy;        {vrati jestli je disk vzdaleny}

{adresare}
FUNCTION  dirExe:DirStr;                    {vrati adresar s nasim exe programem}
FUNCTION  dirCur:DirStr;                    {vrati aktualni adresar aktualniho disku}
FUNCTION  dirCurAt(dsk:char):DirStr;        {vrati aktualni adresar specifikovaneho disku}
FUNCTION  dirTemp:DirStr;                   {vrati pracovni adresar}
FUNCTION  dirWriteable(dir:DirStr):boolean; {vrati zda je ready pro zapis}
FUNCTION  dirMake(dir:DirStr):boolean;      {vytvori adresar}
FUNCTION  dirExists(dir:PathStr):boolean;   {vrati zda adresar existuje}
FUNCTION  dirChange(dir:DirStr):boolean;    {zmeni aktualni adresar}
FUNCTION  dirCopy(flags:word;srcdir:PathStr;destdir:DirStr):boolean;{zkopiruje adresar}
FUNCTION  dirMove(flags:word;srcdir:PathStr;destdir:DirStr):boolean;{presune adresar}
FUNCTION  dirDelete(flags:word;dir:DirStr):boolean;                 {smaze adresar}
PROCEDURE dirGetSize(flags:word; path:PathStr; maska:FileStr; var size1,size2:LongInt); {spocte velikost obsahu adresare}

{soubory}
Const     fileOverwrite   =1;               {prepsat cilovy soubor pokud existuje}
          fileIgnoreRO    =2;               {ignorovat readonly atribut}
          fileNoUndelete  =4;               {mazat soubory tak, aby nesly undeletnout}
          fileWithSubDirs =8;               {aplikovat i na podadresare}
          fileStopIfErr   =16;              {po chybe stopnout akci}
          fileIgnoreErr   =32;              {pokracovat v akci i pres chyby}
                                            {jinak se pta zda skoncit ci pokracovat}
          _fileInner      =64;              {flag pro interni pouziti}

Type      TFileExists=Function(name:PathStr):boolean;
Type      TFileStream=Function(name:PathStr):PStream;
Type      TFileGetSize=Function(name:PathStr;var size:longint):boolean;
FUNCTION  dos_fileExists(name:PathStr):boolean;
FUNCTION  dos_fileReadStream(name:PathStr):PStream;
FUNCTION  dos_fileCreateStream(name:PathStr):PStream;
FUNCTION  dos_fileGetSize(name:PathStr;var size:longint):boolean;

VAR       fileExists:TFileExists;           {vrati zda soubor existuje}
VAR       fileReadStream:TFileStream;       {vrati stream pro cteni souboru}
VAR       fileCreateStream:TFileStream;     {vytvori stream zapisujici do souboru}
VAR       fileGetSize:TFileGetSize;         {zjisti velikost souboru}
FUNCTION  fileCopy(flags:word;src,dest:PathStr):boolean;{zkopiruje soubor}
FUNCTION  fileMove(flags:word;src,dest:PathStr):boolean;{presune soubor}
FUNCTION  fileDelete(flags:word;name:PathStr):boolean;{smaze soubor}
FUNCTION  fileGetAttr(name:PathStr;var attr:integer):boolean;{zjisti atributy souboru}
FUNCTION  fileSetAttr(name:PathStr;attr:byte):boolean;{nastavi atributy souboru}
FUNCTION  fileNameValid(name:PathStr):boolean;{zjisti jestli soubor muze byt vytvoren (nebo prepsan)}
FUNCTION  fileSize(name:PathStr):longint;   {vraci velikost souboru, -1 pri selhani}
FUNCTION  fileAttr(name:PathStr):integer;   {vraci atributy souboru, -1 pri selhani}
FUNCTION  fileLoad(name:PathStr;s:PStream;var p:pointer;var datasize,freesize:longint):boolean;{nahraje soubor do pameti}
FUNCTION  fileSave(flags:word;name:PathStr;p:pointer;size:longint):boolean;{ulozi soubor na disk}
FUNCTION  fileLoadPchar(name:PathStr;s:PStream;var p:pchar):boolean;{nahraje soubor do pcharu}
FUNCTION  fileSavePchar(flags:word;name:PathStr;p:pchar):boolean;{ulozi pchar na disk}

FUNCTION  filesCopy(flags:word;srcfiles:PathStr;destdir:DirStr):boolean;{zkopiruje soubory dane maskou}
FUNCTION  filesMove(flags:word;srcfiles:PathStr;destdir:DirStr):boolean;{presune soubory dane maskou}
FUNCTION  filesDelete(flags:word;files:PathStr):boolean;{smaze soubory dane maskou}

{formaty souboru}
Const     isAnything  =0;      {jakekoliv soubory (parametr fci fileMask a fileFind)}
          isUnknown   =0;      {neznamy soubor (vraceno fci fileIs)}
          isLoadable  =1 shl 0;{do bitmapy nahratelne soubory (JPG,TXT,3DS..)}
          isPlayable  =1 shl 1;{prehratelne soubory (FLI,WAV,MOD...)}
          isExecutable=1 shl 2;{spustitelne soubory (EXE...)}
          isSound     =1 shl 3;{zvukove soubory (WAV,MOD...)}
          isSample    =1 shl 4;{samply (WAV...)}
          isModule    =1 shl 5;{moduly (MOD...)}
          isGraphics  =1 shl 6;{graficke soubory (JPG,FLI,3DS...)}
          isTextmode  =1 shl 7;{textmodove soubory (TXT...)}
          isFixedSize =1 shl 8;{neskalovatelne soubory (JPG,TXT,FLI,3DS..)}
          isScalable  =1 shl 9;{skalovatelne soubory (3DS...)}
          isLanguage  =1 shl 10;{podporovane jazyky (CZ,ENG...)}
          isFont      =1 shl 11;{fonty (FN...)}
          isScript    =1 shl 12;{skripty (SCR...)}
          isHypertext =1 shl 13;{hypertextove dokumenty}

PROCEDURE fileRegister(aext:ExtStr;aflags:word); {zaregistruje format. flags je soucet konstant isXXXX}
FUNCTION  fileMask(flags:word):string;           {vraci masku zahrnujici vsechny formaty se zadanymi flagy}
FUNCTION  fileFind(name:PathStr;flags:word):PathStr;{hleda soubor ve formatu se zadanymi flagy}
FUNCTION  fileIs(name:PathStr):word;             {vraci flagy zadaneho souboru}

 {toto je v interface pouze kvuli unite Loadery}
 Var       Formats:TCollection;
 Type      PFormatItem=^TFormatItem;
           TFormatItem=object(TObject)
                ext         :ExtStr;
                flags       :word;
               end;
 FUNCTION  fileGetFormat(name:PathStr):PFormatItem;

{PathSlice}
Const     psExp       =128;                     { expanze chybejicich casti }
          psLow       =256;                     { prevod na mala pismena    }
          psDisk      =1;                            { C                    }
          psColon     =2;                            { : jen kdyz disk<>''  }
          psDir       =4;                            { \GFX\SEA12           }
          psSlash     =8;                            { \                    }
          psRootSlash =512;                          { \ jen kdyz dir=root  }
          psName      =16;                           { SEA                  }
          psPoint     =32;                           { . jen kdyz ext<>''   }
          psForcePoint=1024;                         { .                    }
          psExt       =64;                           { EXE                  }
          psPascalDir =psDir+psRootSlash;            { \GFX\SEA12           }
          psPascalPath=psDisk+psColon+psPascalDir;   { C:\GFX\SEA12         }
          psPath      =psDisk+psColon+psDir+psSlash; { C:\GFX\SEA12\        }
          psFile      =psName+psPoint+psExt;         { SEA.EXE              }
          psAll       =psPath+psFile;                { C:\GFX\SEA12\SEA.EXE }

FUNCTION  PathSlice(path:PathStr;slice:word):PathStr;

FUNCTION  PathAbsolute(path:PathStr):boolean;   {vraci jetli je cesta absolutni nebo relativni}

{PCK}
FUNCTION  PCK_Init(name:PathStr): boolean;      {otevre PCK soubor}
PROCEDURE PCK_Close;                            {zavre PCK soubor}
PROCEDURE PCK_Open(var f:file;name:PathStr);    {otevre soubor uvnitr aktualniho PCK}

{ostatni}
FUNCTION  CallCommand(command:string):boolean;  {provede dosovy prikaz}
FUNCTION  GetVerify:boolean;                    {zjisti rezim verifikace}
PROCEDURE SetVerify(mode:boolean);              {nastavi rezim verifikace}

var       _dlgChoice:FUNCTION(popisek,tlacitka:string):word;{interni zalezitost}


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{---------------------------------------------------------------------------
 Pomocna fce, ktera nam usnadni zareagovani na neuspesnou akci.
 Success=jak akce dopadla ve skutecnosti.
 Kdyz flagy rikaji ignorovat chyby, vzdy vratime true.
 Kdyz flagy rikaji stopnout pri chybe, vratime to co jsme dostali.
 Jinak se zeptame uzivatele a podle toho i nastavime globflags.
 ---------------------------------------------------------------------------}
FUNCTION dlgContMsg(flags:word;msg:string):boolean;
begin
 dlgContMsg:=true;
 if (flags+globflags) and fileIgnoreErr=0 then begin
   if (flags+globflags) and fileStopIfErr=0 then
    if @_dlgChoice<>nil then
     case _dlgChoice(msg,_(_msgContAlwStopAlw)) of
      1:flags:=flags or fileIgnoreErr;
      2:globflags:=globflags or fileIgnoreErr;
      0,
      3:flags:=flags or fileStopIfErr;
      4:globflags:=globflags or fileStopIfErr;
      end;
   if (flags+globflags) and fileStopIfErr<>0 then dlgContMsg:=false;
   end;
end;

FUNCTION dlgCont(flags:word;success:boolean):boolean;
begin
 dlgCont:=success or dlgContMsg(flags,_(_msgChybaBehemAkce));
end;

FUNCTION ReadOnlyErr:boolean;
begin
 ReadOnlyErr:=ReadOnlyMod;
 if ReadOnlyMod then begin
   if globflags and fileIgnoreErr=0 then ReportErr(_(_erReadOnly));
   end;
end;

{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ DISKY ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


FUNCTION ConvertLetter(dsk:char):byte; assembler;
{Zkonvertuje pismeno '@','A','b','C','d',.. na 0,1,2,3,..
 Pro neplatne pismeno vrati $FF. (pro potreby zdejsich funkci)}
asm   {ConvertLetter}
 mov  al,dsk
 cmp  al,'z'
 ja   @err
 cmp  al,'Z'
 jbe  @1
 sub  al,'a'-'A'
@1:
 cmp  al,'@'
 jb   @err
 sub  al,'@'
 and  al,1Fh
 jmp  @end
@err:
 mov  al,0FFh
@end:
end;  {ConvertLetter}

FUNCTION  dskName(dsk:char):FileStr;
var di:SearchRec;
begin
 FindFirst(dsk+':\*.*',VolumeID,di);
 if DosError=0 then dskName:=di.name else dskName:='';
end;

{$IFDEF DOSMEM}
{FUNCTION  dskSerialNumber(dsk:char):longint; assembler;
var dib:
 record
  level:word;
  serial:longint;
  name:array[1..11] of char;
  fattype:array[1..8] of char;
 end;
asm
 mov  bx,ss
 mov  dx,sp
 push ds
 mov  al,dsk
 push ax
 call ConvertLetter
 cmp  al,0FFh
 je   @end
 mov  ds,bx
 mov  bl,al
 mov  ax,6900h
 int  21h
 jc   @err
 mov  bx,dx
 mov  ax,ds:[bx+2]
 mov  dx,ds:[bx+4]
 jmp  @end
@err:
 xor  ax,ax
 xor  dx,dx
@end:
 pop  ds
end;}
{waclawova verze i pro protekt:}
FUNCTION dskSerialNumber(dsk:char):longint;
type PDiskSerNoInfo=^TDiskSerNoInfo;
     TDiskSerNoInfo=record
      Level:word;
      Serial:longint;
      Name:array[1..11] of char;
      FatType:array[1..8] of char;
     end;
var Info:PDiskSerNoInfo;
    Segment:word;
    {$ifdef dpmi}
    Regs:dpmiRealCallRegs;
    {$else}
    Regs:Registers;
    {$endif}
begin
 GetMemDos(Segment,pointer(Info),sizeof(TDiskSerNoInfo));
 {$ifdef dpmi}
 with Regs do begin
  rEAX:=$6900;
  rEBX:=ConvertLetter(dsk);
  rDS :=Segment;
  rEDX:=0;
  dpmiRealModeInt($21,@Regs);
 end;
 {$else}
 with Regs do begin
  AX:=$6900;
  BL:=ConvertLetter(dsk);
  DS:=Seg(Info^);
  DX:=Ofs(Info^);
  Intr($21,Regs);
 end;
 {$endif}
 if Regs.Flags and 1<>0 then Info^.Serial:=0;
 dskSerialNumber:=Info^.Serial;
 FreeMemDos(pointer(Info),sizeof(TDiskSerNoInfo));
end;
{$ENDIF DOSMEM}

{---------------------------------------------------------------------------
 Vrati vsechny instalovane disky ve stringu jako napr. ABCD.
 Vysledek je cachovany, protoze windows nt pri testovani existence a: kricej,
 ze v a: neni disketa. Tak at to delaj jen jednou... {* ma nekdo lepsi napad?
 ---------------------------------------------------------------------------}
FUNCTION dskListUncached:string; assembler;
asm   {dskList}
 mov  ah,19h
 int  21h
 push ax { v AL soucasny disk }
 les  di,@result
 push di
 inc  di
 mov  cx,'z'-'a'+1 { Projede se od A az po Z }
 mov  dx,0
@1:
 mov  ah,0Eh
 int  21h { ChDir disk v DL }
 {aktualni disk =}
 mov  ah,19h
 int  21h
 cmp  al,dl
 jne  @none {kdyz neni stejny}
  mov  al,dl
  add  al,'A'
  stosb
 @none:
 inc  dl
 loop @1
@konec:
 mov  ax,di
 pop  di
 sub  ax,di
 dec  ax
 stosb {nakonec delka stringu}
 pop  ax
 mov  ah,0Eh
 mov  dl,al
 int  21h {a ChDir na puvodni disk}
end;  {dskList}

var dskListCache:string[26];

FUNCTION dskList:string;
begin
 if dskListCache='-' then dskListCache:=dskListUncached;
 dskList:=dskListCache;
end;

{---------------------------------------------------------------------------
 Identifikuje zadany disk a vrati:
 dskNone   - Neznamy/Neexistuje
 dskFloppy - Disketa
 dskHard   - Hard disk
 dskNet    - Sitovy
 dskCdrom  - CD-ROM
 Pozn.: Jakz takz opravenej, ale presto ma jeste naky mouchy.
 ---------------------------------------------------------------------------}
FUNCTION dskId(dsk:char):dskType;
assembler;
var
 buf:string[ord('Z')-ord('A')];
 bufs,bufo:word;
 {$ifdef dpmi}
 regs:dpmiRealCallRegs;
 {$endif}
asm   {dskId}
 push sp            {ne prilis cistym zpusobem zjisti a ulozi adresu bufu}
 pop  ax
 add  ax,4
 mov  bufo,ax
 mov  ax,ss
 mov  bufs,ax
 mov  al,dsk        {testuje, jestli nebyl zadan blud}
 cmp  al,'A'        {dsk<'A'?}
 jl   @None
 cmp  al,'z'        {dsk>'z'?}
 jg   @None
 cmp  al,'a'        {dsk<'a'?}
 jl   @1
 sub  al,'a'-'A'    {zkonvertuje na velke pismeno}
@1:                 {dsk ma nyni urcite mensi ASCII kod nez male 'a'}
 cmp  al,'Z'        {dsk>'Z'?}
 jg   @None
 mov  dsk  ,al      {ulozime si osetrene pismeno disku}
{ifndef dpmi}
 mov  ax,0DADAh     {testujeme CD-ROM}
 push ax            {dame do stacku slovo $DADA}
 mov  ax,01100h
 int  2Fh
 pop  bx            {vyndame z trouby upecene slovo}
 {postreh: tato detekce cdrom nefunguje ve win2k}
(*{$else}
{*
Pod dpmi se to stale nepodarilo rozchodit.
Jde o vyse uvedenych 5 instrukci.
Pushnout neco, zavolat sluzbu a pak to popnout.
Pouzitim DPMI sluzby se ovsem zagulasuje stack, realova obsluha
uz se nedostane k nasemu pushi ani kdyz pozadame DPMI o kopirovani
30 wordu z naseho stacku do realmodoveho... zrejme uz nekopiruje
z realmodoveho zpatky do naseho nebo co. Ani kdyz nastavime pointer
na vlastni realovy stack, DADA nam na ADAD nezmeni.
 push ss                                 {regs.init}
 lea  ax,regs                            {}
 push ax                                 {}
 call dpmiRealCallRegs.Init              {}
 mov  word ptr regs.rEAX,01100h          {regs.AX=1100}
 les  bx,dosfree                         {dosfree[1000-2]=DADA}
 mov  word ptr [es:bx+1000-6],0DADAh     {}
 mov  word ptr [es:bx+1000-4],0DADAh     {}
 mov  word ptr [es:bx+1000-2],0DADAh     {}
 mov  word ptr [es:bx+1000+0],0DADAh     {jestlize rSS=0 a rSP=0, dpmi udela 30wordovy stack}
 mov  word ptr [es:bx+1000+2],0DADAh     {}
 mov  word ptr [es:bx+1000+4],0DADAh     {}
 mov  word ptr [es:bx+1000+6],0DADAh     {}
 mov  word ptr [es:bx+1000+8],0DADAh     {}
 mov  word ptr [es:bx+1000+10],0DADAh     {}
 mov  bx,dosfreeSeg                      {regs.SS:SP=@dosfree[1000-2]}
 mov  regs.rSS,bx                        {}
 mov  regs.rSP,1000                      {}
 push 2fh                                {dpmiRealModeIntStack(2F,regs,30)}
 push ss                                 {}
 lea  ax,regs                            {}
 push ax                                 {}
 push 30                                 {}
 call dpmiRealModeIntStack               {}
 mov  al,byte ptr regs.rEAX              {AL=regs.AL}
 les  bx,dosfree                         {BX=pop ze stacku}
 mov  bx,[es:bx+1000-2]                  {}
{$endif}*)
 cmp  bx,0ADADh     {zmenilo se na $ADAD?}
 jne  @3            {kdyz ne, pokracuje dal}
 cmp  al,0FFh       {kdyz zaroven neni ah=$FF, pokracuje dal}
 jne  @3
 mov  ax,1500h
 int  2Fh           {zjisti pocet CD-ROMek a pismeno disku prvni z nich}
 add  cl,'A'
 cmp  dsk,cl        {zkusi, jestli se %dsk nerovna pismenu prvni CD-ROMky}
 je   @Cdrom
 mov  cx,bx         {v cx je nyni pocet CD-ROMek}
 jcxz @None
 mov  bx,bufs       {nastavi adresu [es:bx] do buferu}
 mov  es,bx
 mov  bx,bufo
 mov  ax,150Dh
 int  2Fh           {naplni bufer pismeny}
@2:
 mov  al,es:[bx]    {cx-krat precte z buferu pismeno,}
 inc  bx
 add  al,'A'
 cmp  dsk,al        {porovna ho se zadanym diskem}
 je   @Cdrom        {a v pripade, ze se sobe rovnaj odskoci na @Cdrom}
 loop @2
@3:
 mov  bl,dsk
 sub  bl,'A'-1      {prevedeme pismeno disku na (0..vybrany,1..A,2..B atd.)}
 mov  ax,04409h     {test na sitovy disk}
 int  21h
 jc   @None         {kdyz je CarryFlag=1, pak nastala chyba}
 test dh,010h       {DH and $10 <> 0 ?}
 jnz  @Net
 mov  ax,04408h     {test na floppy a hard drive}
 int  21h
 jc   @None         {kdyz je CarryFlag=1, pak nastala chyba}
 cmp  al,0          {al = 0...Floppy,  1...HardDisk}
 je   @Floppy
 cmp  al,1
 jne  @None
 mov  al,dskHard
 jmp  @end
@CDROM:
 mov  al,dskCDROM
 jmp  @end
@Net:
 mov  al,dskNet
 jmp  @end
@Floppy:
 mov  al,dskFloppy
 jmp  @end
@None:
 mov  al,dskNone
@end:
end;  {dskId}

{---------------------------------------------------------------------------
 Vrati znak disku, z ktereho byl zavlecen system.
 Pozn: v DOSu verze<4 vraci vzdy C.
 ---------------------------------------------------------------------------}
FUNCTION dskBoot:char; assembler;
asm   {dskBoot}
 push 4000h
 call DosAtLeast
 cmp  al,false
 je   @err
 mov  ax,03305h
 int  21h
 mov  al,dl
 add  al,'A'-1
 jmp  @end
@err:
 mov  al,'C'
@end:
end;  {dskBoot}

{---------------------------------------------------------------------------
 Vraci jestli je disk pripraven k praci.
 ---------------------------------------------------------------------------}
FUNCTION dskReady(dsk:char):boolean;
var di:SearchRec;
begin {dskReady}
 if not dskCheck(dsk) then dskReady:=false else begin
   dskSelectFantom(dsk);
   FindFirst(dsk+':\*.*',AnyFile,di);
   dskReady:=DosError in [0,18]
   end;
end;  {dskReady}

{---------------------------------------------------------------------------
 Zmeni aktualni disk a presune se na jeho aktualni adresar.
 Vraci: 0-p(r)ovedeno, 1-neni treba,  2-neni ready/neexistuje, 3-chyba vstupu
 ---------------------------------------------------------------------------}
FUNCTION dskChanged(dsk:char):byte; assembler;
asm   {dskChanged}
 mov  dh,1      {dh v sobe nosi vysledek funkce}
 cmp  al,'@'
 je   @end
 mov  dh,3
 mov  al,dsk    {prevede 'A','b','C'.. na 0,1,2..}
 cmp  al,'z'
 ja   @end
 cmp  al,'A'
 jb   @end
 and  al,31
 cmp  al,'Z'-'A'+1{oprava: +1 aby uz nepovazoval z: za neplatny pismeno}
 ja   @end
 dec  al
 mov  dsk,al
 mov  dh,1
 mov  ah,19h
 int  21h
 cmp  al,dsk    {je dsk soucasny drive?}
 je   @end      {pokud ano, nemusime menit}
 mov  al,dsk
 add  al,'A'
 push ax
 call dskReady
 cmp  al,false
 je   @err
 mov  ah,0Eh
 mov  dl,dsk
 int  21h       {Changneme disk}
 mov  ah,19h
 int  21h       {Overime si, jestli se zmenil}
 mov  dh,0
 cmp  al,dl     {rovnaji se zadany a aktualni disk?}
 je   @end
@err:
 mov  dh,2
@end:
 mov  al,dh
end;  {dskChanged}

FUNCTION dskChange(dsk:char):boolean;
begin
 if not dskCheck(dsk) then dskChange:=false else begin
   dskSelectFantom(dsk);
   dskChange:=dskChanged(dsk) in [0,1];
   end;
end;

{---------------------------------------------------------------------------
 Vraci soucasny disk jako znak (velkym pismenem). Nikdy by nemela selhat.
 ---------------------------------------------------------------------------}
FUNCTION dskCur:char; assembler;
asm   {dskCur}
 mov  ah,19h
 int  21h
 add  al,'A'
end;  {dskCur}
{Reseni na jeden radek:
 dskCur:=Copy(fExpand('.\'),1,1);}

FUNCTION dskRemovable(dsk:char):Fuzzy; assembler;
{Vrati, jestli je disk vymenitelny.
 vstup: dsk='@'..aktualni, jinak pismeno disku
 Pro neplatne disky nebo v pripade chyby vraci 'nevim'.}
asm   {dskRemovable}
 push 0300h
 call DosAtLeast
 cmp  al,false
 je   @nevim
 mov  al,dsk
 push ax
 call ConvertLetter
 cmp  al,0FFh
 je   @nevim
 mov  bl,al
 mov  ax,4408h
 int  21h
 jc   @nevim
 cmp  al,0
 je   @ano
 cmp  al,1
 je   @ne
@nevim:
 mov  al,Dunno
 jmp  @end
@ano:
 mov  al,Yes
 jmp  @end
@ne:
 mov  al,No
@end:
end;  {dskRemovable}

FUNCTION dskRemote(dsk:char):Fuzzy; assembler;
{Vrati, jestli je disk vzdaleny (v siti).
 vstup: dsk='@'..aktualni, jinak pismeno disku
 Pro neplatne disky nebo v pripade chyby vraci 'nevim'.}
asm   {dskRemote}
 push 0302h
 call DosAtLeast
 cmp  al,false
 je   @nevim
 mov  al,dsk
 push ax
 call ConvertLetter
 cmp  al,0FFh
 je   @nevim
 mov  bl,al
 mov  ax,4409h
 int  21h
 jc   @nevim
 test dh,10h
 jnz  @ano
 jmp  @ne
@nevim:
 mov  al,Dunno
 jmp  @end
@ano:
 mov  al,Yes
 jmp  @end
@ne:
 mov  al,No
@end:
end;  {dskRemote}

FUNCTION dskCheckedFantom(dsk:char):byte;
{Nekdy muze vice logickych disku reprezentovat jeden disk fyzicky.
 (napr. A,B mohou reprezentovat jednu floppy mechaniku)
 Tato funkce vrati pro dany disk:
 0 - pokud fyzicky disk %dsk reprezentuje prave jeden logicky disk.
 1=A, 2=B, 3=C, ... 26=Z - cislo odpovidajici prave vybraneho logickeho
   disku (tzn. ze je jich vic nez jeden)
 0FFh - pokud tato funkce neni podporovana nebo nastala chyba
 pozn.: u sitovych disku a cdrom vraci permanentne 0FFh.
 vstup: %dsk='@'..soucasny, jinak pismeno disku.}
var   e:TError;
      b:byte;
      {$ifdef dpmi}
      RealModeRegs:dpmiRealCallRegs;
      {$endif}
label err_report;
begin
 dskCheckedFantom:=$ff;
 if not DosAtLeast($302) then exit;
 b:=ConvertLetter(dsk);
 if b=$ff then goto err_report;
 {$ifdef dpmi}
 with RealModeRegs do begin
   ClrRegs(RealModeRegs);
   rEAX:=$440e;
   rEBX:=b;
   e:=TError(dpmiRealModeInt($21,@RealModeRegs));
   if e<>erOk then begin ReportErr(_(e));exit;end;
   if flags and 1=1 then goto err_report;
   dskCheckedFantom:=byte(rEAX);
   end;
 {$else}
 asm
 mov  ax,0440Eh
 mov  bl,b
 int  21h          {INT 21h, Fn 44h, SubFn 0Eh}
 jc   err_report
 mov  @result,al
 end;
 {$endif}
 exit;
err_report:
{ ReportErr(_(_erCheckedFantomFail)+' '+dsk+':');}
end;  {dskCheckedFantom}

{vraci jestli probehne dskChange(dsk) bez vynucene interakce s uzivatelem}
FUNCTION dskChangeIsSafe(dsk:char):boolean;
var n:byte;
begin
 dskChangeIsSafe:=false;
 if not dskExists(dsk) then exit;
 dsk:=UpCase(dsk);
 if not (dsk in ['@'..'Z']) then exit;
 n:=dskCheckedFantom(dsk);
 if (n=0) or (chr(n+64)=dsk) or (n=255) then dskChangeIsSafe:=true;
end;

FUNCTION dskExists(dsk:char):boolean;
begin
 dskExists:=pos(Upcase(dsk),dskList)<>0;
end;

FUNCTION dskCheck(dsk:char):boolean;
begin
 if not dskExists(dsk) then begin
   ReportErr(_(_erDskNeexistuje)+' '+dsk+':');
   dskCheck:=false;
   end
 else
   dskCheck:=true;
end;

FUNCTION dskSelectFantom(dsk:char):boolean;
{Pokud je jednomu fyzickemu disku prirazeno vice disku logickych, pak
 pri presunu mezi nimi DOS napise na obrazovku (v jakemkoli rezimu)
 "Insert diskette for drive X: and press any key when ready"
 a vsechno zastavi, dokud neco nestisknete. Pokud zrovna pouzivate
 svuj handler klavesnice, tak muzete rovnou pocitac resetovat.
 A neco takoveho by se ve vasem prekrasnem multi-taskingovem,
 grafickem prostredi nemelo stat, nemyslite?
 Proto pouzijte tuto funkci, abyste predem vybrali zadany
 disk a aby to za Vas nemusel delat starostlivy DOS svym zpusobem..
 vstup: %dsk='@'..soucasny, jinak pismeno disku}
{$ifdef dpmi}
var   RealModeRegs:dpmiRealCallRegs;
      e:TError;
begin
 dskSelectFantom:=false;
 if dskCheck(dsk) then
  if not dskChangeIsSafe(dsk) then
   if DosAtLeast($302) then
    with RealModeRegs do begin
     ClrRegs(RealModeRegs);
     rEAX:=$440f;
     rEBX:=ord(upcase(dsk))-ord('@');
     e:=TError(dpmiRealModeInt($21,@RealModeRegs));
     if e<>erOk then begin ReportErr(_(e));exit;end;
     if flags and 1=1 then begin ReportErr(_(_erSelFantomFail)+' '+dsk+':');exit;end;
     dskSelectFantom:=true;
     end;
end;
{$else}
label err_report,err_noreport;
begin
 if not dskCheck(dsk) then goto err_noreport;
 asm   {dskSelectFantom}
  mov  al,dsk
  push ax
  call dskChangeIsSafe
  cmp  al,true
  je   @ok
  mov  al,dsk
  push ax
  call ConvertLetter
  cmp  al,0FFh
  je   err_report
  push ax
  push 0302h
  call DosAtLeast
  cmp  al,false
  je   err_noreport
  mov  ax,0440Fh
  pop  bx
  int  21h          {INT 21h, Fn 44h, SubFn 0Fh}
  jc   err_report
 @ok:
  mov  @result,1
 end;
 exit;
err_report:
 ReportErr(_(_erSelFantomFail)+' '+dsk+':');
err_noreport:
 dskSelectFantom:=false;
end;  {dskSelectFantom}
{$endif}

FUNCTION dskFantoms:string;
{Dava seznam "Fantom-disku" ve forme stringu. Pro verzi DOSu < 3.2 vrati ''.
 POZOR: Delka stringu zustava stejna, ale muze menit svuj obsah}
var
 disky,result:string[ord('Z')-ord('A')+1];
 i,dsk:byte;
begin {dskFantoms}
 disky:=dskList;
 result:='';
 if DosAtLeast($0302) then
  for i:=1 to length(disky) do
   begin
    dsk:=dskCheckedFantom(disky[i]);
    if (dsk in [1..ord('Z')-ord('A')+1]) and (chr(64+dsk)<>disky[i])
    then result:=result+disky[i];
   end;
 dskFantoms:=result
end;  {dskFantoms}

FUNCTION dskSectorSize(dsk:char):word; assembler;
asm
 mov  ah,036h
 mov  dl,[dsk]
 sub  dl,'A'-1
 int  21h
 mul  cx
end;


{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ PATHSLICE ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{---------------------------------------------------------------------------
 Ze zadane cesty k souboru vraci pouze zvolenou cast.
 Slice je soucet konstant psXXXX, udava ktere casti vracet.
 Vysledek je velkymi pismeny neni-li zadano psLow.
 Pri psExp expanduje pripadny chybejici disk a adresar.
 ---------------------------------------------------------------------------}
FUNCTION PathSlice(path:PathStr;slice:word):PathStr;
var   disk,slash:string[1];
      dir:DirStr;
      name:NameStr;
      ext:ExtStr;
begin
 {volitelne expanduje vstup}
 if (slice and psExp)=psExp then path:=fExpand(path);
 {roztrha vstup do disk,dir,slash,name,ext}
 fSplit(path,dir,name,ext);
 if (length(dir)>=2) and (dir[2]=':')
  then begin disk:=dir[1]; delete(dir,1,2) end
  else disk:='';
 if dir[length(dir)]='\'
  then begin slash:='\'; dec(dir[0]) end
  else slash:='';
 delete(ext,1,1);
 {spoji pozadovane casti do vysledku}
 path:='';
 if ((slice and psDisk      )>0) then path:=disk;
 if ((slice and psColon     )>0) and (disk<>'') then path:=path+':';
 if ((slice and psDir       )>0) then path:=path+dir;
 if ((slice and psSlash     )>0) or (((slice and psRootSlash)>0) and (dir='')) then path:=path+slash;
 if ((slice and psName      )>0) then path:=path+name;
 if ((slice and psForcePoint)>0) or (((slice and psPoint)>0) and not ((ext='') and ((slice and psFile)=psFile)))
                                 then path:=path+'.';
 if ((slice and psExt       )>0) then path:=path+ext;
 {prevede na velka/mala pismena}
 if ((slice and psLow       )>0) then PathSlice:=lcased(path)
                                 else PathSlice:=ucased(path);
end;

{---------------------------------------------------------------------------
 Vraci jestli je cesta absolutni, tj. jestli zacina \ nebo x:\.
 ---------------------------------------------------------------------------}
FUNCTION  PathAbsolute(path:PathStr):boolean;
begin
 PathAbsolute:=((length(path)>0) and (path[1]='\'))
   or ((length(path)>2) and (path[2]=':') and (path[3]='\'))
end;

{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ ADRESARE ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}



{---------------------------------------------------------------------------
 Vraci jestli jde do adresare zapisovat,
  konkretne zkousi atributy create+write+delete.
 ---------------------------------------------------------------------------}
FUNCTION dirWriteable(dir:DirStr): boolean;
begin {dirWriteable}
 dirWriteable:=false;
 dir:=FExpand(dir);
 DeStr2Pc(dir);
 if dskId(dir[0]) in [dskFloppy,dskHard,dskNet] then
   asm
    PUSH DS
    push ss
    pop ds
    {create temporary file}
    mov ah,5ah;mov cx,0;lea dx,dir;int 21h;jc @err
    {write to file}
    xchg bx,ax;mov ah,40h;inc cx;int 21h;jc @err
    {close file}
    mov ah,3eh;int 21h;jc @err
    {delete file}
    mov ah,41h;int 21h;jc @err
    {wow, ok}
    mov @result,true
    @err:
    POP DS
   end
end;  {dirWriteable}

{---------------------------------------------------------------------------
 Vraci adresar ve kterem je spusteny exe soubor.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 ---------------------------------------------------------------------------}
var dirExeCache:PathStr;
FUNCTION dirExe:DirStr;
begin
 dirExe:=dirExeCache;
end;

{---------------------------------------------------------------------------
 Vraci aktualni adresar na disku dsk.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 ---------------------------------------------------------------------------}
FUNCTION dirCurAt(dsk:char):DirStr; assembler;
{vrati soucasny adresar zadaneho disku vcetne cesty, zakoncene lomitkem.
 pokud dojde k chybe (spatny drajv nebo podobne), vrati prazdny retezec.
 To same dela procedura GetDir, ale ta pri chybe vraci retezec 'X:\',
 kteryzto muze byt platnym adresarem.
 dsk='@'-soucasny disk, jinak pismeno disku}
asm   {dirCurAt}
 push ds
 mov  al,[dsk]     {napred trochu kostrbata konverze 'A','b','Z','@' na 0,1,2..}
 cmp  al,'@'
 jb   @err
 je   @0
 cmp  al,'z'
 ja   @err
 cmp  al,'a'
 jb   @0
 sub  al,'a'-'A'
@0:
 cmp  al,'Z'
 ja   @err
 and  al,31
 mov  [dsk],al
 lds  si,@result
 add  si,4         {posune offset na pozici prvniho adresare}
 mov  ah,047h
 mov  dl,[dsk]
 int  21h
 jc   @err
 sub  si,3         {posune offset na pozici pismene disku}
 mov  al,[dsk]
 add  al,'A'-1
 cmp  [dsk],0
 ja   @1
 mov  ah,019h
 int  21h
 add  al,'A'
@1:
 mov  ds:[si],al
 inc  si
 mov  ax,'\:'
 mov  ds:[si],ax
 dec  si           {nyni zjisti delku stringu}
 mov  ah,0
 mov  cx,0FFh
@2:
 lodsb
 cmp  al,0
 je   @3
 inc  ah
 loop @2
@3:
 sub  si,2         {a nakonec vyresi zpetne lomitko}
 lodsb
 cmp  al,'\'
 je   @4
 mov  al,'\'
 mov  ds:[si],al
 inc  ah
@4:
 lds  si,@result
 mov  ds:[si],ah
 jmp  @end
@err:
 lds  si,@result
 mov  al,0
 mov  ds:[si],al
@end:
 pop  ds
end;  {dirCurAt}
{reseni na jeden radek:
 dirCurAt:=fExpand(dsk+':')}

{---------------------------------------------------------------------------
 Vraci aktualni adresar na aktualnim disku.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 ---------------------------------------------------------------------------}
FUNCTION dirCur:DirStr; assembler;
asm   {dirCur}
 les  di,@result
 push es
 push di
 push '@'
 call dirCurAt
 add  sp,4
end;  {dirCur}
{reseni na jeden radek:
 dirCur:=fExpand('')}

{---------------------------------------------------------------------------
 Vraci pracovni adresar.
 Vysledek je vzdy velkymi pismeny, expandovany a zakonceny lomitkem.
 Vzhledem k tomu ze ve standardnim tempu v NT s NTFS
  - nemame pravo exec
  - nemame pravo file scan
 pokousime se temto adresarum vyhnout.
 ---------------------------------------------------------------------------}
var dirTempCache:DirStr;

FUNCTION _dirTemp:DirStr;
var  st:PathStr;
     i:byte;
     Fre:LongInt;
     dsk:char;
     di:SearchRec;
begin
 {zkusi nacist temp z environmentu}
 st:=fExpand(GetEnv('temp'));
 if st='' then st:=fExpand(GetEnv('tmp'));
 if st='' then st:=fExpand(GetEnv('work'));
 if st[length(st)]<>'\' then st:=st+'\';
 FindFirst(st+'*.*',anyfile,di);{zjisti zda mame pravo file scan}
 if (doserror=0{mame file scan}) and (st<>'')
  and (dirExists(st) or (not ReadOnlyMod and dirMake(st)))
  and dirWriteable(st) then begin
   _dirTemp:=st;
   exit;
   end;
 {vymysli temp sam}
 st:=dskList;
 if length(st)<1 then
  begin
   st:=dirCur;
   if st='' then st:='C:\';
   _dirTemp:=st;
   exit
  end;
 Fre:=0;
 dsk:=#0;
 for i:=1 to length(st) do {mel by najit hadr s nejvetsim volnym mistem, ale at neprohledava zbytecne dlouho, >100MB bere hned}
  if (dskId(st[i])=dskHard) and
     (ReadOnlyMod or dirWriteable(st[i]+':\')) and
     (DiskFree(ord(st[i])-64)>Fre) then
   begin
    dsk:=st[i];
    fre:=DiskFree(ord(st[i])-64);
    if fre>100*1024*1024 then break;
   end;
 if dsk=#0 then dsk:=dskCur;
 _dirTemp:=dsk+':\';
 if not ReadOnlyMod and dirMake(dsk+':\TEMP\') then _dirTemp:=dsk+':\TEMP\';
end;

FUNCTION dirTemp:DirStr;
begin
 if dirTempCache='' then dirTempCache:=_dirTemp;
 dirTemp:=dirTempCache;
end;

FUNCTION dirExists(dir:PathStr):boolean;
var attr:word;
    f:file;
begin {dirExists}
 dir:=fExpand(getcore(dir));
 if (dir[0]+dir[2]=#2':') or (dir[0]+dir[2]+dir[3]=#3':\') then
  begin
   {existujici adresar na nepripravenem mediu = neexistujici adresar
   dirExists:=Pos(UpCase(dir[1]),dskList)>0;}
   dirExists:=dskReady(dir[1]);
   exit;
  end;
 if dir[length(dir)]='\' then dec(dir[0]);
 assign(f,dir);
 GetFAttr(f,attr);
 {existenci adresare nelze jako dosud testovat pomoci FindFirst,
  protoze ve w2k v adresari \WINNT\Temp neni NIC, ani . a ..,
  takze FindFirst zfailuje}
 dirExists:=(DosError=0) and (attr and Directory<>0);
end;  {dirExists}

FUNCTION dirMake(dir:DirStr):boolean;
var made:PathStr;
    f:file;
    attr:word;
begin {dirMake}
 dirMake:=false;
 made:='';
 while dir<>'' do begin
   made:=made+CutString(dir,'\');
   if (length(made)=1) or (length(made)>2) or (made[2]<>':') then begin
     assign(f,made);
     GetFAttr(f,attr);
     if (doserror<>0) or ((attr and directory)=0) then begin
       if ReadOnlyErr then exit;
       MkDir(made);
       if ioresult<>0 then begin ReportErr(_(_erNelzeVytvAdr)+' '+made+'.');exit;end;
       end;
     end;
   made:=made+'\';
   end;
 dirMake:=true;
end;  {dirMake}

FUNCTION dirChange(dir:DirStr):boolean;
begin {dirChange}
 dirChange:=false;
 {zakonci lomitkem adresare chybou volajiciho nezakonceny}
 if not (dir[length(dir)] in [':','\',#0]) then dir:=dir+'\';
 dskSelectFantom(Str2Char(Copy(fExpand(dir),1,1)));
 ChDir(PathSlice(dir,psPascalPath));
 if ioresult<>0
  then begin ReportErr(_(_erNelzeJitDoAdr)+' '+dir+'.');exit;end;
 dirChange:=true;
end;  {dirChange}

FUNCTION  dirCopy(flags:word;srcdir:PathStr;destdir:DirStr):boolean;
begin
 dirCopy:=filesCopy(flags,srcdir+'*.*',destdir);
end;

FUNCTION  dirMove(flags:word;srcdir:PathStr;destdir:DirStr):boolean;
begin
 dirMove:=filesMove(flags,srcdir+'*.*',destdir);
end;

FUNCTION  dirDelete(flags:word;dir:DirStr):boolean;
begin
 dirDelete:=filesDelete(flags,dir+'*.*');
end;

PROCEDURE dirGetSize(flags:word; path:PathStr; maska:FileStr; var size1,size2:LongInt);
{Zjist°, kolik zabira obsah adresare. V %size1 vraci, kolik soubory zabiraji
 logicky (soucet jejich velikosti) a v %size2 vraci, kolik soubory/adresare
 zabiraji fyzicky (zaokrouhluje na sektory smerem nahoru). %maska je souborova
 maska souboru, kterych se to ma tykat.}
var
 di:SearchRec;
 sector:word;
 hlp1,hlp2:LongInt;
begin {dirGetSize}
 size1:=0; size2:=0;
 path:=PathSlice(CutString(path,';'),psPascalPath);
 sector:=dskSectorSize(path[1]);
 if maska='' then maska:='*.*';
 FindFirst(path+'\'+maska,AnyFile-VolumeID,di);
 while (DosError=0) and (di.name[1]='.') do FindNext(di);
 while DosError=0 do
  begin
   if di.Attr and Directory=0
   then
    begin
     inc(size1,di.size);
     inc(size2,((di.size+sector-1) div sector)*sector)
    end
   else
    if flags and fileWithSubDirs<>0 then
     begin
      inc(size2,sector);
      dirGetSize(flags,path+'\'+di.name,maska,hlp1,hlp2);
      inc(size1,hlp1); inc(size2,hlp2);
     end;
   FindNext(di)
  end
end;  {dirGetSize}

{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ PCK ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


{ Nasledujou procedury pro praci s PCK souborem. Moc jsem to neupravoval,
  je to pres clipboard z diskmag.pas :), akorat jsem misto UpStr, dal
  UpCased, aby to slo uz na stringy.

  Neni tady nic, cim by se dal pck vytvorit. Ja to delal vesmes pres
  copy /b apod. Chtelo by to nejakou proceduru PCK_Create. }

const MaxIndex  = 1024;		{ Maximalni pocet fajlu v jednom PCK }
type
      Index      = record	{ Jeden index v zahlavi }
           Name  : ^String;	{ Jmeno fajlu }
           Start : Longint;	{ Startovni pozice v PCK }
           Size  : Longint;	{ Velikost }
      end;
      ListP      = Array[0..MaxIndex] of Index;	{ Seznam indexu }

var   Pocetfajlu : Word;
      List       : ^ListP;

      PCK_F      : File;

{---------------------------------------------------------------------------
 Vrati cislo indexu v seznamu.
 ---------------------------------------------------------------------------}
function GetIndex(Name:String):Word;
var I:Word;
begin;
  if (List=NIL) or (List^[0].Size=MaxIndex) then begin GetIndex:=0;exit;end;
  Name:=UpCased(Name);
  i:=1;
  while (i<=pocetfajlu) and (List^[i].Name^<>Name) do Inc(i);
  if List^[i].Name^=Name then GetIndex:=i else GetIndex:=0;
end;

{---------------------------------------------------------------------------
 Otevre fajl v PCK -> Naseekuje na jeho startovni pozici. Cist se muze uz
 normalne pres blockread.
 ---------------------------------------------------------------------------}
procedure PCK_Open(var f:File;Name:PathStr);
var I:Word;
begin;
  I:=GetIndex(Name);
  if i>0 then begin move(PCK_F,f,sizeof(f)); Seek(f,List^[i].Start); end;
end;

{---------------------------------------------------------------------------
 Otevre PCK soubor a pripravi fajllist.
 ---------------------------------------------------------------------------}
function PCK_Init(Name:PathStr):boolean;
var I,J:longint;s:string;
begin;
  Assign(PCK_F,Name);Reset(PCK_F,1);
  if (IOResult<>0) or (List<>NIL) then begin PCK_Init:=False;exit;end;
  BlockRead(PCK_F,pocetfajlu,2);
  if pocetfajlu>=MaxIndex then pocetfajlu:=MaxIndex-1;
  GetMem(pointer(List),(Pocetfajlu+1)*SizeOf(Index));
  List^[0].Size:=pocetfajlu;
  for i:=1 to pocetfajlu do begin
    BlockRead(PCK_F,s[0],1);BlockRead(PCK_F,s[1],Ord(s[0]));
    GetMem(pointer(List^[i].Name),length(s)+1);
    List^[i].Name^:=UpCased(s);			{ jde to na stringy :) }
    BlockRead(PCK_F,List^[i].Start,4);BlockRead(PCK_F,List^[i].Size,4);
  end;
end;

{---------------------------------------------------------------------------
 Zavre PCK, uvolni pamet.
 ---------------------------------------------------------------------------}
procedure PCK_Close;
var I:Word;
begin;
  if PocetFajlu > 0 then begin
    for i:=1 to PocetFajlu do FreeMem(pointer(List^[i].Name),length(List^[i].Name^)+1);
    FreeMem(pointer(List),(PocetFajlu+1)*SizeOf(Index));
    List:=NIL;
    System.Close(PCK_F);
  end;
  PocetFajlu:=0;
end;


{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ OSTATNI ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}


FUNCTION CallCommand(command:string):boolean;
begin
 CallCommand:=false;
 Swapvectors;
 Exec(getenv('COMSPEC'),command);
 Swapvectors;
 case doserror of
   0:   ;
   8:   begin ReportErr(_i(_erLowMem4Cmd,command));exit;end;
   else begin ReportErr(_i(_erBadCmd,command));exit;end;
   end;
 CallCommand:=true;
end;

PROCEDURE SetVerify(mode:boolean); assembler;
{Jako DOSovy prikaz VERIFY,
 zapne/vypne overovani uspesnosti pri zapisu na disk.
 Se zapnutou verifikaci je to bezpecnejsi, s vypnutou zase rychlejsi}
asm   {SetVerify}
 mov  ah,02Eh
 mov  al,mode
 int  21h
end;  {SetVerify}

FUNCTION  GetVerify:boolean; assembler;
{Zjisti rezim verifikace: true-zapnuta, false-vypnuta}
asm   {GetVerify}
 mov  ah,054h
 int  21h
end;  {GetVerify}

{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ SOUBORY ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

FUNCTION filePrepareForOverwriting(flags:word;name:PathStr):boolean;
begin
 filePrepareForOverwriting:=false;
 if ReadOnlyErr then exit;
 if fileExists(name) then begin
   if flags and fileOverwrite=0 then
    if not dlgContMsg(flags,_i(_erSoubJizExist,name))
     then exit;
   fileDelete(flags,name);
   end;
 filePrepareForOverwriting:=true;
end;

{---------------------------------------------------------------------------
 Nahraje soubor z disku do pameti. Velikost neni omezena na 64KB.
 Ma neprijemne hodne parametru, ale obcas se to hodi.

 pri s=nil
 ---------
  pracuje se souborem name

 pri s<>nil
 ----------
  pracuje se streamem s, ovsem v pripade chyby ohlasi tuto na souboru name

 pri p<>nil
 ----------
  P je pointer na blok pameti delky datasize+freesize.

 pri p=nil
 ---------
  Datasize musi byt 0.
  Do p se naalokuje blok pameti delky souboru + freesize.

 vystupy
 -------
  Do p^ se nahraje soubor filename.
  Promenne datasize a freesize se upravi tak, ze datasize=delka nahranych dat,
  freesize=volna pamet za daty.
  Vraci kod chyby, 0=ok.
 ---------------------------------------------------------------------------}

FUNCTION fileLoad(name:PathStr;s:PStream;var p:pointer;var datasize,freesize:longint):boolean;
 var  fsize           :longint;{velikost souboru}
      toload          :longint;{kolik bajtu jeste zbyva naloadovat}
      temptoload      :word;
      tempp           :^byte;
      pwasnil         :boolean;
      swasnil         :boolean;
label ende;
begin
  fileLoad:=false;
  pwasnil:=p=nil;
  swasnil:=s=nil;

 {otevre soubor}
  if s=nil then s:=fileReadStream(name);
  if s=nil then begin ReportErr(_(_erNelzeOtevSoub)+' '+name+'.');exit;end;

 {zjisti velikost}
  fsize:=s^.GetSize;

 {p=nil: naalokuje pamet}
 if p=nil then begin
   {$ifdef beta}
   if datasize<>0 then erBetaMsg('fileload datasize<>0');
   {$endif}
   datasize:=fsize;
   if not GetMem(p,datasize+freesize)
    then begin ReportErr(_(erLowMem)+' ('+name+')');goto ende;end;
   end
 {p<>nil: zkontroluje ze je dost pameti}
 else begin
   if fsize>datasize
    then begin ReportErr(_(_erFileTooBig)+' ('+name+'>'+stri(datasize)+'B)');goto ende;end;
   inc(freesize,datasize-fsize);
   datasize:=fsize;
   end;

 {nacte soubor}
 toload    :=fsize;
 tempp     :=p;
 while toload>0 do begin
   if PtrRec(tempp).Ofs=0 then temptoload:=65536-512
                          else temptoload:=65536-PtrRec(tempp).Ofs;
   if temptoload>toload then temptoload:=toload;

   {nacte kus souboru}
    s^.Read(tempp^,temptoload);
    if s^.status<>0 then begin
      ReportErr(_(_erNelzeCistSoub)+' '+name+'.');
      if pwasnil then FreeMem(p,datasize+freesize);
      goto ende;
      end;

   dec(toload,temptoload);
   inc(tempp,temptoload);
   if PtrRec(tempp).Ofs=0 then inc(PtrRec(tempp).Seg,selectorInc);
   end;

 {zavre soubor}
 fileLoad:=true;
ende:
 if swasnil then KillObj(s);
end;

FUNCTION fileSave(flags:word;name:PathStr;p:pointer;size:longint):boolean;
var   f:file;
      towrite,written:word;
begin
 fileSave:=false;
 if not filePrepareForOverwriting(flags,name) then exit;
 if ReadOnlyErr then exit;
 Assign(f,name);
 Rewrite(f,1);
 if ioresult<>0 then begin ReportErr(_(_erNelzeVytvSoub)+' '+name+'.');exit;end;
 while size>0 do begin
   if size>65535 then towrite:=32768 else towrite:=size;
   Blockwrite(f,p^,towrite,written);
   if (ioresult<>0) or (towrite<>written)
    then begin ReportErr(_(_erNelzePsatSoub)+' '+name+', '+_(_erAsiMaloMista));close(f);exit;end;
   dec(size,towrite);
   if size>0 then
    if PtrRec(p).Ofs=0
    then PtrRec(p).Ofs:=32768
    else p:=ptr(PtrRec(p).Seg+SelectorInc,0);
   end;
 Close(f);
 fileSave:=true;
end;

FUNCTION fileLoadPchar(name:PathStr;s:PStream;var p:pchar):boolean;
var datasize,freesize:longint;
    b:boolean;
begin
 p:=nil;
 datasize:=0;
 freesize:=1;
 b:=fileLoad(name,s,pointer(p),datasize,freesize);
 if b then PByte(Ptr(PtrRec(p).Seg,PtrRec(p).Ofs+datasize))^:=0;
 fileLoadPchar:=b;
end;

FUNCTION fileSavePchar(flags:word;name:PathStr;p:pchar):boolean;
begin
 fileSavePchar:=fileSave(flags,name,p,StrLen(p));
end;

FUNCTION dos_fileExists(name:PathStr):boolean;
var f:file;
    attr:word;
begin
 {existenci nelze testovat pomoci FindFirst napr kvuli adresari \WinNT\TEMP}
 assign(f,name);
 GetFAttr(f,attr);
 dos_fileExists:=(DosError=0) and (attr and (Directory+VolumeID)=0) and
   (DeviceExists or (attr and $40=0)){prinejmensim DOS 7 pro device vraci $40};
end;

FUNCTION dos_fileReadStream(name:PathStr):PStream;
var s:PBufStream;
begin
 New(s,Init(name,stOpenRead,8*1024));
 if (s<>nil) and ((s^.errorinfo<>0) or (s^.status<>0) or (s^.buffer=nil)) then KillObj(s);
 dos_fileReadStream:=s;
end;

FUNCTION dos_fileCreateStream(name:PathStr):PStream;
var s:PBufStream;
begin
 dos_fileCreateStream:=nil;
 if ReadOnlyErr then exit;
 New(s,Init(name,stCreate,8*1024));
 if (s<>nil) and (s^.status<>0) then KillObj(s);
 dos_fileCreateStream:=s;
end;

FUNCTION fileCopy(flags:word;src,dest:PathStr):boolean;
var p:pointer;
    fsrc,fdest:file;
    t:SearchRec;
    readen,written:word;
label 1;
begin
 fileCopy:=false;
 FindFirst(src,anyfile-directory-volumeid,t);
 if doserror<>0 then begin ReportErr(_(_erChybiSoub)+' '+src+'.');exit;end;
 assign(fsrc,src);
 FileMode:=0;
 reset(fsrc,1);
 FileMode:=2;
 if ioresult<>0 then begin ReportErr(_(_erNelzeOtevSoub)+' '+src+'.');exit;end;
 if not filePrepareForOverwriting(flags,dest) then exit;
 assign(fdest,dest);
 rewrite(fdest,1);
 if ioresult<>0 then begin ReportErr(_(_erNelzeVytvSoub)+' '+dest+'.');exit;end;
 repeat
  1:
  BlockRead(fsrc,freeptr^,65536-512,readen);
  if ioresult<>0 then begin ReportErr(_(_erNelzeCistSoub)+' '+src+'.');exit;end;
  if readen>0 then begin
    BlockWrite(fdest,freeptr^,readen,written);
    if (ioresult<>0) or (written<readen) then begin ReportErr(_(_erNelzePsatSoub)+' '+dest+', '+_(_erAsiMaloMista));exit;end;
    dec(t.size,written);
    {continue;}goto 1;
    {BP continue tady a ted kompiluje na jump ven za until!}
    end;
 until true;
 if t.size<>0 then begin ReportErr(_(_erNelzeCistCelySoub)+' '+src+'.');exit;end;
 close(fsrc);
 if ioresult<>0 then begin ReportErr(_(_erNelzeZavrSoub)+' '+src+'.');exit;end;
 SetFTime(fdest,t.time);
 if doserror<>0 then begin ReportErr(_(_erNelzeSetAttr)+' '+dest+'.');exit;end;
 close(fdest);
 if ioresult<>0 then begin ReportErr(_(_erNelzeZavrSoub)+' '+dest+'.');exit;end;
 fileCopy:=true;
end;

FUNCTION fileMove(flags:word;src,dest:PathStr):boolean;
var f:file;
begin
 fileMove:=false;
 if not filePrepareForOverwriting(flags,dest) then exit;
 Assign(f,src);
 Rename(f,dest);
 if ioresult<>0 then begin ReportErr(_(_erNelzePrejmSoub)+' '+src+' '+_(_na)+' '+dest+'.');exit;end;
 fileMove:=true;
end;

FUNCTION fileDelete(flags:word;name:PathStr):boolean;
var f:file;
begin
 fileDelete:=false;
 if not fileExists(name) then begin fileDelete:=true;exit;end;
 if ReadOnlyErr then exit;
 if (flags and fileIgnoreRO)>0 then fileSetAttr(name,0);
 Assign(f,name);
 if (flags and fileNoUndelete)>0 then begin Rewrite(f,1);Close(f);end;
 Erase(f);
 if ioresult<>0 then begin ReportErr(_(_erNelzeSmazSoub)+' '+name+'.');exit;end;
 fileDelete:=true;
end;

FUNCTION TopLvlOk(var flags:word;srcfiles:PathStr;destdir:DirStr;var destcreated:boolean):boolean;
begin
 TopLvlOk:=false;
 destcreated:=false;
 if flags and _fileInner=0 then begin
   if not dirExists(PathSlice(srcfiles,psPath)) then begin
     ReportErr(_i(_erChybiAdr,PathSlice(srcfiles,psPath)));
     exit;
     end;
   if not dirMake(destdir) then exit;
   destcreated:=true;
   flags:=flags or _fileInner;
   end;
 TopLvlOk:=true;
end;

FUNCTION RmDirOk(flags:word;files:PathStr):boolean;
{Smaze adresar kdyz je prazdny a v masce *.*. Vraci uspesnost.}
var di:SearchRec;
begin
 RmDirOk:=false;
 if PathSlice(files,psFile)='*.*' then begin
   FindFirst(files,AnyFile,di);
   while (doserror=0) and (di.name[1]='.') do FindNext(di);
   if doserror<>0 then begin
     RmDir(PathSlice(files,psPascalPath));
     if IOResult<>0 then
      if not dlgContMsg(flags,_(_erNelzeSmazAdr)+' '+PathSlice(files,psPascalPath)+'.')
       then exit;
     end;
   end;
 RmDirOk:=true;
end;

FUNCTION filesCopy(flags:word;srcfiles:PathStr;destdir:DirStr):boolean;
{Zkopiruje soubory zadane maskou do ciloveho adresare.}
var
 di:SearchRec;
 destcreated:boolean;
begin
 filesCopy:=false;
 if not TopLvlOk(flags,srcfiles,destdir,destcreated) then exit;
 FindFirst(srcfiles,AnyFile-VolumeID-Directory,di);
 while DosError=0 do begin
   if not destcreated then begin
     if not dirMake(destdir) then exit;
     destcreated:=true;
     end;
   if not dlgCont(flags,fileCopy(flags,PathSlice(srcfiles,psPath)+di.name,destdir+di.name))
    then exit;
   FindNext(di);
   end;
 if (flags and fileWithSubDirs<>0) then begin
   FindFirst(PathSlice(srcfiles,psPath)+'*.*',AnyFile-VolumeID,di);
   while DosError=0 do begin
     if (di.attr and Directory<>0) and (di.name[1]<>'.') then begin
       if not dlgCont(flags,filesCopy(flags,PathSlice(srcfiles,psPath)+
         di.name+'\'+PathSlice(srcfiles,psFile),destdir+di.name+'\'))
        then exit;
       end;
     FindNext(di);
     end;
   end;
 filesCopy:=true;
end;

FUNCTION filesMove(flags:word;srcfiles:PathStr;destdir:DirStr):boolean;
{Presune soubory zadane maskou do ciloveho adresare.}
var
 di:SearchRec;
 destcreated:boolean;
begin
 filesMove:=false;
 if not TopLvlOk(flags,srcfiles,destdir,destcreated) then exit;
 FindFirst(srcfiles,AnyFile-VolumeID-Directory,di);
 while DosError=0 do begin
   if not destcreated then begin
     if not dirMake(destdir) then exit;
     destcreated:=true;
     end;
   if not dlgCont(flags,fileMove(flags,PathSlice(srcfiles,psPath)+di.name,destdir+di.name))
    then exit;
   FindNext(di);
   end;
 if (flags and fileWithSubDirs<>0) then begin
   FindFirst(PathSlice(srcfiles,psPath)+'*.*',AnyFile-VolumeID,di);
   while DosError=0 do begin
     if (di.attr and Directory<>0) and (di.name[1]<>'.') then begin
       if not dlgCont(flags,filesMove(flags,PathSlice(srcfiles,psPath)+
         di.name+'\'+PathSlice(srcfiles,psFile),destdir+di.name+'\'))
        then exit;
       end;
     FindNext(di);
     end;
   end;
 if not RmDirOk(flags,srcfiles) then exit;
 filesMove:=true;
end;

FUNCTION filesDelete(flags:word;files:PathStr):boolean;
{Smaze soubory zadane maskou.}
var
 di:SearchRec;
begin
 filesDelete:=false;
 FindFirst(files,AnyFile-VolumeID-Directory,di);
 while DosError=0 do begin
   if not dlgCont(flags,fileDelete(flags,PathSlice(files,psPath)+di.name))
    then exit;
   FindNext(di);
   end;
 if (flags and fileWithSubDirs<>0) then begin
   FindFirst(PathSlice(files,psPath)+'*.*',AnyFile-VolumeID,di);
   while DosError=0 do begin
     if (di.attr and Directory<>0) and (di.name[1]<>'.') then begin
       if not dlgCont(flags,filesDelete(flags,PathSlice(files,psPath)+di.name+'\'+PathSlice(files,psFile)))
        then exit;
       end;
     FindNext(di);
     end;
   end;
 if not RmDirOk(flags,files) then exit;
 filesDelete:=true;
end;

FUNCTION dos_fileGetSize(name:PathStr;var size:longint):boolean;
var di:SearchRec;
begin
 dos_fileGetSize:=false;
 FindFirst(name,AnyFile-VolumeID,di);
 if (DosError<>0) or (di.Attr and Directory<>0) then begin
   ReportErr(_(_erNelzeGetSize)+' '+name+'.');
   size:=-1;
   exit;
   end;
 size:=di.Size;
 dos_fileGetSize:=true;
end;

FUNCTION fileGetAttr(name:PathStr;var attr:integer):boolean;
var di:SearchRec;
begin
 fileGetAttr:=false;
 FindFirst(name,AnyFile-VolumeID,di);
 if DosError<>0 then begin
   ReportErr(_(_erNelzeGetAttr)+' '+name+'.');
   attr:=-1;
   exit;
   end;
 attr:=di.Attr;
 fileGetAttr:=true;
end;

FUNCTION fileSetAttr(name:PathStr;attr:byte):boolean;
var f:file;
begin
 fileSetAttr:=false;
 if ReadOnlyErr then exit;
 Assign(f,name);
 SetFAttr(f,attr);
 if ioresult<>0 then begin ReportErr(_(_erNelzeSetAttr)+' '+name+'.');exit;end;
 fileSetAttr:=true;
end;

FUNCTION fileSize(name:PathStr):LongInt;
var size:longint;
begin
 fileGetSize(name,size);
 fileSize:=size;
end;

FUNCTION fileAttr(name:PathStr):integer;
var attr:integer;
begin
 fileGetAttr(name,attr);
 fileAttr:=attr;
end;

FUNCTION fileNameValid(name:PathStr):boolean; {Zjisti jestli soubor muze byt vytvoren (nebo prepsan)}
var di:SearchRec;
begin
 FindFirst(name,AnyFile-VolumeID-Directory,di);
 fileNameValid:=(DosError=18) or ((DosError=0) and (di.Attr and Directory=0));
end;


{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ FORMATY ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

{---------------------------------------------------------------------------
 Najde format pro zadany soubor.
 ---------------------------------------------------------------------------}
Function fileGetFormat(name:PathStr):PFormatItem;
var   myExt:ExtStr;
      D:DirStr;
      N:NameStr;
  function ExtMatch(p:PFormatItem):boolean;far;
  begin
   ExtMatch:=p^.ext=myExt;
  end;
begin
 FSplit(name,d,n,myExt);
 myExt:=UpCased(copy(myExt,2,3));
 fileGetFormat:=Formats.FirstThat(@ExtMatch);
end;

{---------------------------------------------------------------------------
 Zaregistruje formaat.
 ---------------------------------------------------------------------------}
Procedure fileRegister(aext:ExtStr;aflags:word);
var p:PFormatItem;
begin
 if fileGetFormat('a.'+aext)<>nil then Formats.Free(fileGetFormat('a.'+aext));
 New(p,Init);
 p^.ext         :=UpCased(aext);
 p^.flags       :=aflags;
 Formats.Insert(p);
end;

{---------------------------------------------------------------------------
 Vraci masku zahrnujici vsechny soubory se vsemi zadanymi flagy.
 Pokud jsou zaregistrovany loadery TGA, GIF, FLI a TXT,
  fileMask(isGraphics+isLoadable) vrati '*.TGA;*.GIF'.
 ---------------------------------------------------------------------------}
Function  fileMask(flags:word):string;
var st:string;
  procedure AddExt(p:PFormatItem);far;
  begin
   if p^.flags and flags=flags then begin
     if st<>'' then st:=st+';';
     st:=st+'*.'+p^.ext;
     end;
  end;
begin
 st:='';
 Formats.ForEach(@AddExt);
 fileMask:=st;
end;

{---------------------------------------------------------------------------
 Vraci jestli je soubor obrazek (zaregistrovaneho formatu).
 ---------------------------------------------------------------------------}
Function fileIs(name:PathStr):word;
var l:PFormatItem;
begin
 l:=fileGetFormat(name);
 if l=nil then fileIs:=isUnknown else fileIs:=l^.flags;
end;

{---------------------------------------------------------------------------
 Hleda obrazek daneho nazvu. Vstupem je bud nazev souboru nebo nazev
 bez koncovky, s teckou ci bez ni. Funkce zkousi dosazovat ruzne koncovky
 se vsemi zadanymi flagy. Poradi zkousenych formatu je dano poradim registrace.
 Vraci bud nazev nalezeneho obrazku nebo nic.
 ---------------------------------------------------------------------------}
Function fileFind(name:PathStr;flags:word):PathStr;
  function ExtFound(p:PFormatItem):boolean;far;
  begin
   fileFind:=name+p^.ext;
   ExtFound:=((p^.flags and flags)=flags) and fileExists(name+p^.ext);
  end;
begin
 if ((fileIs(name) and flags)=flags) and fileExists(name) then fileFind:=name
 else begin
   if name[length(name)]<>'.' then name:=name+'.';
   if Formats.FirstThat(@ExtFound)=nil then fileFind:='';
   end;
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='fajly';
var result:TError;

procedure UserInit;
 begin
  ReadOnlyMod      :=false;
  DeviceExists     :=false;
  globflags        :=0;
  Pocetfajlu       :=0;
  List             :=nil;
  _dlgChoice       :=nil;
  dskListCache     :='-';
  dirExeCache      :=PathSlice(paramstr(0),psExp+psPath);
  dirTempCache     :='';
  fileExists       :=dos_fileExists;
  fileReadStream   :=dos_fileReadStream;
  fileCreateStream :=dos_fileCreateStream;
  fileGetSize      :=dos_fileGetSize;
  if not Formats.Init(20,30) then begin result:=erLowMem;exit;end;
  fileRegister('EXE',isExecutable);
  fileRegister('COM',isExecutable);
  fileRegister('BAT',isExecutable);
  fileRegister('FN',isFont);
 end;

procedure UserDone;
 begin
  Formats.Done;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.