{⁄ƒƒƒC.I.A.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒverze 1.00ƒƒƒø
 ≥S timto souborem smi byt nakladano pouze v souladu s podminkami uvedenymi≥
 ≥v dokumentaci C.I.A. Pouzitim souboru potvrzujes, ze podminky akceptujes.≥
 ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ}
{$ifdef dpmi}
 {$define nt} {ma v protektu potlacit uvolnovani bloku konvencni pameti?}
{$endif}

Unit      Memo;
Interface {$i define.inc}
Uses      Chyby, Objects{$ifdef dpmi},WinApi,DPMI{$endif};
Function  Init:TError;
Procedure Done;

{
---------------------------------------------------------------------------
                            Sprava pameti
---------------------------------------------------------------------------
Snaha byla umoznit psat programy nezavisle na zpusobu spravy pameti.
Budes-li tedy alokovat pamet s pouzitim zdejsich rutin, bude tvuj program
prenositelny mezi temito pametovymi modely (nastavuje se v DEFINE.INC):

 PROTPAS
  - protected mod
  - alokace pameti se interne provadi pomoci: GetMem, WinApi, INT 31

 REALPAS
  - real mod
  - alokace pameti se interne provadi pomoci: GetMem, INT 21
  - na zacatku programu by melo byt neco jako ($M stack,hodne,hodne)

 REALDOS
  - real mod
  - alokace pameti se interne provadi pomoci: INT 21
  - na zacatku programu by tedy melo byt neco jako ($M stack,malo,malo)
  - pozor: New a Dispose zustavaji nepretizene, berou pamet z ^^^ ^^^^
  - tento model se hodi v pripade, ze tvuj program vola jine
    dosove programy a potrebuje pro ne hodne volne dosove pameti


---------------------------------------------------------------------------
                    Co se deje pri nedostatku pameti
---------------------------------------------------------------------------
Z minulosti jsi mozna zvykly na to, ze New a Getmem bud uspeji nebo hodi
runtime error a ukonci program. CiA pretezuje funkci GetMem, nase nova
funkce program nikdy neukonci, pri nedostatku pameti se nejprve pokusi
nejakou uvolnit (z cache) a kdyz se ani to nepodari, vrati nil.
New a system.GetMem se take pokouseji pamet uvolnit, ale pri neuspechu
ukonci program.


---------------------------------------------------------------------------
                        Operace s bloky pameti
---------------------------------------------------------------------------
Klasicke blokove presuny typu REP MOVSB lze az ctyrnasobne zrychlit pouzitim
zdejsich rutin zacinajicich na REP_.
K nazvoslovi:
 - Zacatek nazvu tvori prepis instrukce (instrukci), kde mezery nahrazuje
   podtrzitko, napr REP_STOSB.
 - Nasledovat muze jedno z
    _SI ...zarovnavej podle SI (zdrojova adresa)
    _DI ...zarovnavej podle DI (cilova adresa)
    _NA ...nezarovnavej
   Zarovnavani zvysuje pocatecni rezii,
   ale zrychluji smycku, takze se vyplaci pri praci s delsimi bloky.
 - Nasledovat muze _NZ (NoZero) coz znamena, ze CX nesmi byt nula.
 - Nasledovat muze _O (Overflow) nebo _NO (NoOverflow) coz znamena,
   ze offset smi/nesmi behem presunu pretect 64KB. Omezeni _NO vede
   ke zjednoduseni rutiny a tudiz zvyseni rychlosti.

}



{---------------------------------------------------------------------------
 Verejne typy a promenne.
 ---------------------------------------------------------------------------}

TYPE  PByte     = ^byte;
      PShort    = ^shortint;
      PWord     = ^word;
      PInt      = ^integer;
      PLong     = ^longint;
      PString   = ^string;
      PPtr      = ^pointer;
      TProc     = procedure;
      FBool     = function:boolean;
      PtrRec    = record Ofs,Seg:Word;end;
      Fuzzy     = (No,Dunno,Yes);

      TBytes    = array[0..65534] of byte;
      TWords    = array[0..32766] of word;
      TLongs    = array[0..16382] of longint;
      PBytes    = ^TBytes;
      PWords    = ^TWords;
      PLongs    = ^TLongs;

{---------------------------------------------------------------------------
 Trocha staticke pameti komukoliv k dispozici.
 Kdyz do ni neco ulozis, nemas zadnou zaruku ze to tam za chvili jeste bude.
 - freeptr ukazuje na 64K blok normalni pameti
 - dosfree ukazuje na 1K konvencni pameti
 - free* je kilove pole v datasegmentu
 ---------------------------------------------------------------------------}
Const freesize=65536;

Var   {pointer na 64KB blok volne pameti}
      freeofs:word;
      freeseg:word;
      freeptr:pointer absolute freeofs;

      {pointer na 1KB volne konvencni pameti}
      dosfree:pointer;
      dosfreeSeg:word;

      {1KB volne pameti v datasegmentu}
      freeL:array[0..256] of longint;
      freeP:array[0..256] of pointer absolute freeL;
      freeI:array[0..512] of integer absolute freeL;
      freeW:array[0..512] of word absolute freeL;
      freeC:array[0..1024] of char absolute freeL;
      freeB:array[0..1024] of byte absolute freeL;
      freeS:string absolute freeL;

      debugmem:boolean;          {debugovaci rezim: vypis hlasek o pameti}

      MakeRoom:FBool;

{---------------------------------------------------------------------------
 Nahrada systemovych zdroju pameti.
 ---------------------------------------------------------------------------}
FUNCTION  MemAvail:longint;
FUNCTION  MaxAvail:longint;
FUNCTION  GetMem(var p:pointer;bytes:longint):boolean;
PROCEDURE FreeMem(var p:pointer;bytes:longint);
FUNCTION  GetMemDos(var segment:word;var p:pointer;bytes:longint):boolean;
PROCEDURE FreeMemDos(var p:pointer;bytes:longint);
PROCEDURE Seg2Desc(var w:word);

{---------------------------------------------------------------------------
 Zakladni operace s bloky pameti.
 ---------------------------------------------------------------------------}
PROCEDURE REP_STOSB;
PROCEDURE REP_STOSW_o;
PROCEDURE REP_STOSW_no;
PROCEDURE REP_STOSD;
PROCEDURE REP_STOS_AX_DL_nz;
PROCEDURE REP_STOS_AX_DH_nz;
PROCEDURE REP_STOS3_nz;
PROCEDURE REP_MOVSB_na;
PROCEDURE REP_MOVSB_si;
PROCEDURE REP_MOVSB_di;
PROCEDURE REP_MOVSB_si_nz;
PROCEDURE REP_MOVSB_di_nz;
PROCEDURE REP_MOVSW_na;
PROCEDURE REP_MOVSW_si;
PROCEDURE REP_MOVSW_di;
PROCEDURE REP_MOVS3_na;
PROCEDURE REP_MOVS3_si;
PROCEDURE REP_MOVS3_di;
PROCEDURE REP_MOVSD_na;
PROCEDURE REP_MOVSD_si;
PROCEDURE REP_MOVSD_di;
PROCEDURE REP_MOVSB_back;
PROCEDURE REP_MOVSB_ADD_SI_3;
PROCEDURE REP_MOVSB_ADD_DI_3;
PROCEDURE REP_MOVS_1_nz_t;
PROCEDURE REP_MOVS_2_nz_t;
PROCEDURE REP_MOVS_3_nz_t;
PROCEDURE REP_MOVS_4_nz_t;
PROCEDURE ResizeCX2DX_1_nz;
PROCEDURE ResizeCX2DX_2_nz;
PROCEDURE ResizeCX2DX_3_nz;
PROCEDURE ResizeCX2DX_4_nz;
PROCEDURE ResizeCX2DX_1_nz_t;
PROCEDURE ResizeCX2DX_2_nz_t;
PROCEDURE ResizeCX2DX_3_nz_t;
PROCEDURE ResizeCX2DX_4_nz_t;
PROCEDURE ExpandCH_AL;
PROCEDURE ExpandCH_AX;
PROCEDURE ExpandCH_CLAX;
PROCEDURE ExpandCH_EAX;
PROCEDURE ExpandAH_AL;
PROCEDURE ExpandAH_BX;
PROCEDURE Move(var src,dest;bytes:word);
PROCEDURE Xchg(var a,b;bytes:word);
PROCEDURE XchgB(var a,b:byte);
PROCEDURE XchgS(var a,b:shortint);
PROCEDURE XchgW(var a,b:word);
PROCEDURE XchgI(var a,b:integer);
PROCEDURE XchgL(var a,b:longint);
PROCEDURE FillByte(blok:pointer;bytes:longint;value:byte);
PROCEDURE FillWord(blok:pointer;words:longint;value:word);
FUNCTION  CmpBlock(blok1,blok2:pointer;bytes:word):boolean;
FUNCTION  CmpByte(blok:pointer;val:byte;bytes:word):boolean;
FUNCTION  CmpWord(blok:pointer;val:word;words:word):boolean;

{---------------------------------------------------------------------------
 Komfortni pointer na objekt libovolne delky (tj. i vetsi nez 64K)
 Dobre mi poslouzil pri vykradani microsoftich chaotickych fontu *.FON.
 ---------------------------------------------------------------------------}
Type      TPtr=object(TObject)
            p:pointer;
            constructor Init(ap:pointer);
            function    Plus(l:longint):pointer;
            procedure   Add(l:longint);
            function    GetByte:byte;
            function    ReadByte:byte;
            function    GetShort:shortint;
            function    ReadShort:shortint;
            function    GetChar:char;
            function    ReadChar:char;
            function    GetWord:word;
            function    ReadWord:word;
            function    GetInt:integer;
            function    ReadInt:integer;
            function    GetLong:longint;
            function    ReadLong:longint;
            function    CmpStr(st:string):boolean;
            procedure   GotoStr(st:string);
            procedure   GotoEop;
            procedure   GotoEos;
            procedure   AlignUp(a:word);
            procedure   AlignDown(a:word);
          end;

{---------------------------------------------------------------------------
 Kocka - objekt s vice zivoty.
 ---------------------------------------------------------------------------}
Type
      PCat=^TCat;
      TCat=object(TObject)
          lives         :byte;       {kolik zivotu ma tento objekt}
          constructor   Init;        {vytvori objekt s jednim zivotem}
          destructor    Done;virtual;{zrusi objekt s poslednim zivotem}
         end;

PROCEDURE KillCat(var cat);          {obj musi byt kocka, vezme ji jeden zivot}
FUNCTION  NewCat(var cat):PCat;      {obj musi byt kocka, da ji novy zivot}

{---------------------------------------------------------------------------
 Ostatni
 ---------------------------------------------------------------------------}
PROCEDURE KillObj(var obj);{obj musi byt PObject nebo potomek}
{$ifdef dpmi}
procedure ClrRegs(var r:dpmiRealCallRegs);
{$endif}

Type
      {Vychozi objekt pro flcPlayer, samplePlayer...}
      PPlayer=^TPlayer;
      TPlayer=object(TObject)
        stream         :PStream;
        constructor    Init(astream:PStream);
        function       Sync:boolean;virtual;
        destructor     Done;virtual;
       end;

      PPlaylist=^TPlaylist;
      TPlaylist=object(TCollection)
        procedure      Sync;
       end;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
                          IMPLEMENTATION
{‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹}

{---------------------------------------------------------------------------
 Nekolik kousku zkopirovanych z jinych unit za ucelem snizeni poctu uses.
 ---------------------------------------------------------------------------}
Type string11=string[11];
FUNCTION  Stri(num:longint):string11;
var st:string11;
begin
 str(num,st);
 stri:=st;
end;
FUNCTION  Ptr2Str(p:pointer):string11;
begin
 Ptr2Str:=stri(PtrRec(p).Seg)+':'+stri(PtrRec(p).Ofs);
end;
FUNCTION MaxI(x,y:integer):integer;inline($58/$5b/$3b/$d8/$7e/$01/$93);{pop ax;pop bx;cmp bx,ax;jle +1;xchg ax,bx}
FUNCTION MaxL(x,y:longint):longint;inline($66/$58/$66/$5b/$66/$3b/$d8/$7e/$02/$66/$93/ $66/$50/$59/$5a);
FUNCTION HiInt(l:longint):integer;inline($58/$58);
FUNCTION LoWord(l:longint):word;inline($66/$58);
FUNCTION MakeWord(hi,lo:byte):word;inline($58/$5a/$8a/$e2);
FUNCTION MinL(x,y:longint):longint;inline($66/$58/$66/$5b/$66/$3b/$c3/$7e/$02/$66/$93/ $66/$50/$59/$5a);


{---------------------------------------------------------------------------
 Vynuluje sadu realmodovych registru pro volani dpmi.
 ---------------------------------------------------------------------------}
{$ifdef dpmi}
procedure ClrRegs(var r:dpmiRealCallRegs);
begin
 fillchar(r,sizeof(r),0);
end;
{$endif}


{---------------------------------------------------------------------------
 Kocka a jeji zivoty.
 ---------------------------------------------------------------------------}
constructor TCat.Init;
begin
 inherited Init;
 lives:=1;
end;

destructor TCat.Done;
begin
 if lives<>1 then ReportErr(_(_erZabilsKocku)+' '+stri(lives)+'.');
 inherited Done;
end;

FUNCTION  NewCat(var cat):PCat;
var mycat:PCat absolute cat;
begin
 if mycat<>nil then inc(mycat^.lives);
 NewCat:=mycat;
end;

PROCEDURE KillCat(var cat);
var mycat:PCat absolute cat;
begin
 if mycat<>nil then
  if mycat^.lives=1 then mycat^.Free else dec(mycat^.lives);
 mycat:=nil;
end;


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ KONTROLY... ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

{$ifdef beta}
var minavail:longint;
const maxblox=1500;
type tblox=array[1..maxblox] of record p:pointer;l:longint;end;
var blox:^tblox;
    used:word;
    maxused:word;

procedure InitBlox;
begin
 New(blox);
 used:=0;
 maxused:=0;
end;

procedure DoneBlox;
var i:integer;
begin
 {for i:=1 to used do BiosWriteln('Forgotten:'+Pc2Str(pchar(blox^[i].p)));{}
 Dispose(blox);
 if used<>0 then BiosWriteln(stri(used)+' blox still used.');
 if debug then BiosWriteln('Max used blox='+stri(maxused)+'.');
 if debug then BiosWriteln('Max used mem='+stri((memavail-minavail) shr 10)+'K');
end;

procedure AddBlock(p:pointer;l:longint);
var i:integer;
begin
 for i:=1 to used do
  if p=blox^[i].p then
   ReportErr('Kolize, '+ptr2str(p)+' uë existuje, oldsize='+stri(blox^[i].l)+', newsize='+stri(l)+'.');
 inc(used);
 if used>maxblox then erBetaMsg('Maxblox reached, increase it in memo.pas.');
 maxused:=maxL(used,maxused);
 blox^[used].p:=p;
 blox^[used].l:=l;
 {alloc it now!
 pbyte(p)^:=0;{}
end;

function RemoveBlock(p:pointer;l:longint):boolean;
var i:integer;
begin
 RemoveBlock:=false;
 for i:=1 to used do
  if p=blox^[i].p then begin
    if l<>blox^[i].l then begin
      ReportErr('Block size='+stri(blox^[i].l)+', you free '+stri(l)+', ptr='+ptr2str(p)+'.');
      exit;
      end;
    blox^[i]:=blox^[used];
    dec(used);
    RemoveBlock:=true;
    exit;
    end;
 ReportErr('You free bad block, ptr='+ptr2str(p)+'.');
end;

{$endif}

{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ NT BUG... ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}
{nekdy (pod Windows NT) neni vhodne uvolnovat konvencni pamet}
{takze tady se nepouzite bloky skladuji a kdyztak opet pouziji pozdeji}

{$ifdef nt}

const maxDosBlocks=1000;
type  TDosBlock=record segment:word;p:pointer;bytes:longint;used:boolean end;
      TDosBlocks=array[1..maxDosBlocks] of TDosBlock;
var   dosBlock:^TDosBlocks;
      dosBlocks:word;

function FindDosBlock(size:longint;var se:word;var pt:pointer):boolean;
var i:word;
begin
 for i:=1 to dosBlocks do
  with dosBlock^[i] do
   if not used and (bytes=size) then begin
     used:=true;
     se:=segment;
     pt:=p;
     FindDosBlock:=true;
     exit;
     end;
 FindDosBlock:=false;
end;

procedure LeaveDosBlock(pt:pointer);
var i:word;
begin
 for i:=1 to dosBlocks do
  with dosBlock^[i] do
   if pt=p then begin
     used:=false;
     exit;
     end;
end;

procedure AddDosBlock(size:longint;se:word;pt:pointer);
begin
 if dosBlocks=maxDosBlocks then erMsg(_(_erAlokujesMocBloku));
 inc(dosBlocks);
 with dosBlock^[dosBlocks] do begin
   used:=true;
   bytes:=size;
   segment:=se;
   p:=pt;
   end;
end;

{$endif}


{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ GETMEM... ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

{---------------------------------------------------------------------------
 Alokuje konvencni pamet. Jednotkou je 16B chunk.
 Vraci segment, pri neuspechu 0.
 ---------------------------------------------------------------------------}
FUNCTION GetConv16(bytes16:word):word;assembler;
 asm
     mov ah,48h;mov bx,bytes16;int 21h;
     jnc @ok;xor ax,ax;@ok:
 end;

{---------------------------------------------------------------------------
 Uvolnuje konvencni pamet a vynuluje ukazatel na ni.
 ---------------------------------------------------------------------------}
PROCEDURE FreeConv(var segment:word);assembler;
 asm
     les di,segment
     xor ax,ax
     xchg ax,[es:di]
     or ax,ax;jz @end
     mov es,ax;mov ah,49h;int 21h;
     @end:
 end;

{---------------------------------------------------------------------------
 Vraci maximalni naalokovatelne mnozstvi konvencni pameti v bajtech.
 ---------------------------------------------------------------------------}
FUNCTION GetMaxConv:longint;assembler;
 asm
     mov ah,48h;mov bx,0ffffh;int 21h;
     mov dx,bx;shr dx,12
     mov ax,bx;shl ax,4
 end;

{---------------------------------------------------------------------------
 Nahrada MemAvail.
 ---------------------------------------------------------------------------}
FUNCTION  MemAvail:longint;
begin
 {$ifdef realdos}
  MemAvail:=GetMaxConv;
 {$endif}
 {$ifdef realpas}
  MemAvail:=GetMaxConv+system.MemAvail;
 {$endif}
 {$ifdef protpas}
  MemAvail:=system.MemAvail;
 {$endif}
end;

{---------------------------------------------------------------------------
 Nahrada MaxAvail.
 ---------------------------------------------------------------------------}
FUNCTION  MaxAvail:longint;
begin
 {$ifdef realdos}
  MaxAvail:=GetMaxConv;
 {$endif}
 {$ifdef realpas}
  MaxAvail:=maxL(GetMaxConv,system.MaxAvail);
 {$endif}
 {$ifdef protpas}
  MaxAvail:=system.MaxAvail;
 {$endif}
end;

{---------------------------------------------------------------------------
 Alokace dosove pameti.
 Vraci uspesnost.
 ---------------------------------------------------------------------------}
FUNCTION  GetMemDos(var segment:word;var p:pointer;bytes:longint):boolean;
var   selector:word;
begin
 if debugmem then BiosWriteln(' AllocDos '+stri(bytes)+'.');
 {$ifdef dpmi}
  {$ifdef nt}
   if not FindDosBlock(bytes,segment,p) then
  {$endif}
  if erDumb(TError(dpmiAllocDosMem((bytes+15) div 16,@segment,@selector)))<>erOk
   then begin segment:=0;selector:=0;p:=nil;end
   else begin p:=ptr(selector,0);{$ifdef nt}AddDosBlock(bytes,segment,p);{$endif}end;
 {$else}
  system.GetMem(p,bytes);
  segment:=PtrRec(p).Seg;
 {$endif}
 if not dumb and (p=nil) then Halt(erLowDosMem);
 GetMemDos:=p<>nil;

 {$ifdef beta}
  if p<>nil then AddBlock(p,bytes);
 {$endif}
{ if debugMem then BiosWriteln('  Mem/MaxAvail='+stri(MemAvail)+'/'+stri(MaxAvail)+'.');}
end;

{---------------------------------------------------------------------------
 Uvolneni dosove pameti.
 ---------------------------------------------------------------------------}
PROCEDURE FreeMemDos(var p:pointer;bytes:longint);
var   selector:word;
begin
 if p<>nil then begin
   if debugmem then BiosWriteln(' FreeDos '+stri(bytes)+'.');

   {pro jistotu vynulujeme seg.registry, co kdyz obsahuji ruseny selektor}
   asm xor ax,ax;mov es,ax;db $8e,$e0{mov fs,ax};db $8e,$e8{mov gs,ax};end;

   {$ifdef beta}
   if RemoveBlock(p,bytes) then begin
   {$endif}
     {$ifdef dpmi}
      {$ifdef nt}
       leaveDosBlock(p);
      {$else}
       selector:=PtrRec(p).Seg;
       erDumb(TError(dpmiFreeDosMem(selector)));
      {$endif}
     {$else}
      system.FreeMem(p,bytes);
     {$endif}

     {$ifdef beta}
     end;
     {$endif}
   p:=nil;
   end;
end;

{---------------------------------------------------------------------------
 Prevede realmodovy segment na protektovy descriptor.
 ---------------------------------------------------------------------------}
PROCEDURE Seg2Desc(var w:word);
begin
 {$ifdef dpmi}
 erCheck(TError(dpmiSegmentDescriptor(w,@w)));
 {$endif}
end;



{---------------------------------------------------------------------
 HeapError filtr, nedovoli skoncit runtimem.
 ---------------------------------------------------------------------}
type THeapError=function(Size:Word):Integer;
var  GlobOldHeapError:pointer;
     GlobOldHeapErrorFunc:THeapError absolute GlobOldHeapError;
function NoHeapError(Size:Word):Integer;far;
begin
 if GlobOldHeapError=nil then NoHeapError:=1 else
  NoHeapError:=MaxI(GlobOldHeapErrorFunc(size),1{1 aby nikdy nehazel runtimy});
end;
{---------------------------------------------------------------------------
 Nahrada za systemovy GetMem.
 Lisi se timto:
  - pri neuspechu vzdy nastavi nil a vrati false
  - parametr p musi byt typu pointer
  - pokus o alokaci 0 bajtu je chyba (hlasi ji pouze betaverze)
 Alokovat vic jak 65520 se nedoporucuje, ale jde to.
 ---------------------------------------------------------------------------}
FUNCTION GetMem(var p:pointer;bytes:longint):Boolean;
var OldHeapError:pointer;
    OldHeapErrorFunc:THeapError absolute OldHeapError;
{var OldHeapError:THeapError;}
begin
 if debugmem then BiosWriteln(' Alloc '+stri(bytes)+'.');
 p:=nil;

 {$ifdef beta}
 if (bytes<1) then erBetaMsg('getmem(0)');
 {$endif}

 OldHeapError:=HeapError;
 GlobOldHeapError:=HeapError;
 HeapError:=@NoHeapError;

 repeat
  {$ifdef realdos}
   p:=ptr(GetConv16((bytes+15) div 16),0);
  {$endif}

  {$ifdef realpas}
   if bytes<65536
    then system.GetMem(p,bytes)                  {standardni alokace s pripadnym uvolnenim cache}
    else p:=ptr(GetConv16((bytes+15) div 16),0); {pouze pro vyjmecne situace, bez uvolnovani cache}
  {$endif}

  {$ifdef protpas}
   if bytes<65536
    then system.GetMem(p,bytes)                  {standardni alokace s pripadnym uvolnenim cache}
    else p:=GlobalAllocPtr(HeapAllocFlags,bytes);{pouze pro vyjmecne situace, bez uvolnovani cache}
  {$endif}
 until (p<>nil) or not MakeRoom;

 HeapError:=OldHeapError;

 if not dumb and (p=nil) then Halt(erLowMem);
 getmem:=p<>nil;

 {$ifdef beta}
 if p<>nil then AddBlock(p,bytes);
 minavail:=minL(minavail,MemAvail);
 {$endif}
{ if debugMem then BiosWriteln('  Mem/MaxAvail='+stri(MemAvail)+'/'+stri(MaxAvail)+'.');}
end;

{---------------------------------------------------------------------------
 Nahrada za systemovy FreeMem. Vynuluje pointer.
 ---------------------------------------------------------------------------}
PROCEDURE FreeMem(var p:pointer;bytes:longint);
begin
 if p<>nil then begin
   if debugmem then BiosWriteln(' Free '+stri(bytes)+'.');

   {pro jistotu vynulujeme seg.registry, co kdyz obsahuji ruseny selektor}
   asm xor ax,ax;mov es,ax;db $8e,$e0{mov fs,ax};db $8e,$e8{mov gs,ax};end;

   {$ifdef beta}
   if RemoveBlock(p,bytes) then
   {$endif}

   {$ifdef realdos}
     FreeConv(PtrRec(p).Seg);
   {$endif}

   {$ifdef realpas}
     if bytes<65536
      then system.FreeMem(p,bytes)
      else FreeConv(PtrRec(p).Seg);
   {$endif}

   {$ifdef protpas}
     if bytes<65536
      then system.FreeMem(p,bytes)
      else GlobalFreePtr(p);
   {$endif}

   p:=nil;
   end;
end;





{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ ASM RUTINY ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

{Popisky k rutinam jsou zkratkovite:

  align = si ...zarovnava podle si
          di ...zarovnava podle di
          no ...nezarovnava

  step = byte / word /dword ...v kazdem kroku zpracuje tak velke slovo

  overflow si=yes ... si smi uvnitr smycky pretect hranici 64KB
           di=no  ... di nesmi apod

  cx>0 ...vstupni cx musi byt nenulove

  meni eax ...zde je seznam registru ktere destruuje
}

{ align=di / step=dword / overflow si=no,di=yes / meni hornich 24bitu eax }
PROCEDURE REP_STOSB;assembler;
 asm
       cmp cx,32;jc @simple
       {fill eax}
       mov ah,al;push ax;push ax;db 66h;pop ax
       {zarovna DI na sudou}
       test di,1;jz @s1ok;stosb;dec cx;@s1ok:
       {zarovna DI na dablsudou}
       test di,2;jz @s2ok;stosw;sub cx,2;@s2ok:
       {dodela zbytek}
       push cx;shr cx,2;db 66h;rep stosw;pop cx;and cx,3
       @simple:
       rep stosb
       @end:
 end;

{ align=di / step=dword / overflow si=no,di=yes / meni hornich 16bitu eax }
PROCEDURE REP_STOSW_o;assembler;
 asm
       test di,1;jnz @licha

      @suda:
       {zarovna DI na dablsudou}
       test di,2;jz @s1ok
       jcxz @end{osetri pripad cx=0}
       stosw
       dec cx
       jz @end{osetri pripad cx=1}
       @s1ok:
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx;rep stosw
       ret

      @licha:
       {zarovna na sudou = ulozi pul wordu na lichou adresu}
       jcxz @end{osetri pripad cx=0}
       stosb
       xchg al,ah
       dec cx
       jz @last{osetri pripad cx=1}
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {zarovna DI na dablsudou}
       test di,2;jz @s2ok;stosw;dec cx;jz @last;@s2ok:
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx;rep stosw
       {ulozi posledni pulword na sudou adresu}
       @last:
       stosb

      @end:
 end;

{ align=di / step=dword / overflow si=yes,di=no / meni hornich 16bitu eax }
PROCEDURE REP_STOSW_no;assembler;
 asm
       cmp cx,16;jc @simple

       test di,1;jnz @licha

      @suda:
       {zarovna DI na dablsudou}
       test di,2;jz @s1ok;stosw;dec cx;@s1ok:
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx
      @simple:
       rep stosw
       ret

      @licha:
       {zarovna na sudou = ulozi pul wordu na lichou adresu}
       stosb
       xchg al,ah
       dec cx
       {fill eax}
       push ax;push ax;db 66h;pop ax
       {zarovna DI na dablsudou}
       test di,2;jz @s2ok;stosw;dec cx;@s2ok:
       {dodela zbytek}
       shr cx,1;db 66h;rep stosw;adc cx,cx;rep stosw
       {ulozi posledni pulword na sudou adresu}
       stosb

      @end:
 end;

{ REP STOS pro 3-bajtova slova (napr. truecolor pixel) }
{ Slovo je ulozene v AX/DL, AX/DH nebo v dolnich trech bajtech EAX }
{ provizorni / align=no / overflow si=no,di=no / cx>0 }
PROCEDURE REP_STOS_AX_DL_nz;assembler;
 asm
       @1:
       stosw
       mov [es:di],dl
       inc di
       loop @1
 end;
PROCEDURE REP_STOS_AX_DH_nz;assembler;
 asm
       @1:
       stosw
       mov [es:di],dh
       inc di
       loop @1
 end;
PROCEDURE REP_STOS3_nz;assembler;
 asm
       xchg al,dl
       db 66h;ror ax,8
       @1:
       mov [es:di],dl
       inc di
       stosw
       loop @1
       db 66h;rol ax,8
       xchg al,dl
 end;

{ provizorni / align=no / step=dword / overflow si=no,di=no }
PROCEDURE REP_STOSD;assembler;
 asm
       db 66h;rep stosw
 end;

{ align=no / step=word / overflow si=no,di=no }
PROCEDURE REP_MOVSB_na;assembler;
 asm
       shr cx,1
       rep movsw
       adc cx,cx
       rep movsb
 end;

{ align=si / step=dword / overflow si=yes,di=no }
PROCEDURE REP_MOVSB_si;assembler;
 asm
       cmp cx,16;jc @4
       test si,3
       jz @6
       @5:
       movsb
       test si,3
       loopnz @5
       @6:
       push cx
       shr cx,2
       db 66h;rep movsw
       pop cx
       and cx,3
       @4:
       rep movsb
 end;

{ align=di / step=dword / overflow si=no,di=yes }
PROCEDURE REP_MOVSB_di;assembler;
 asm
       cmp cx,16;jc @4
       test di,3
       jz @6
       @5:
       movsb
       test di,3
       loopnz @5
       @6:
       push cx
       shr cx,2
       db 66h;rep movsw
       pop cx
       and cx,3
       @4:
       rep movsb
 end;

{ align=si / step=word / overflow si=yes,di=no / cx>0 }
PROCEDURE REP_MOVSB_si_nz;assembler;
 asm
      test si,1
      jz @5
      movsb
      dec cx
      @5:
      shr cx,1
      rep movsw
      adc cx,cx
      rep movsb
 end;

{ align=di / step=word / overflow si=no,di=yes / cx>0 }
PROCEDURE REP_MOVSB_di_nz;assembler;
 asm
      test di,1
      jz @5
      movsb
      dec cx
      @5:
      shr cx,1
      rep movsw
      adc cx,cx
      rep movsb
 end;

{ align=no / step=dword / overflow si=no,di=no }
PROCEDURE REP_MOVSW_na;assembler;
 asm
       shr cx,1
       db 66h;rep movsw
       adc cx,cx
       rep movsw
 end;

{ align=si / step=dword / overflow si=no,di=yes }
PROCEDURE REP_MOVSW_si;assembler;
 asm
       add cx,cx
       jmp REP_MOVSB_si
 end;

{ align=di / step=dword / overflow si=yes,di=no }
PROCEDURE REP_MOVSW_di;assembler;
 asm
       add cx,cx
       jmp REP_MOVSB_di
 end;

{ align=no / step=dword / overflow si=no,di=no }
PROCEDURE REP_MOVS3_na;assembler;
 asm
       push ax
       mov ax,cx
       add cx,ax
       add cx,ax
       pop ax
       jmp REP_MOVSB_na
 end;

{ align=di / step=dword / overflow si=no,di=yes }
PROCEDURE REP_MOVS3_si;assembler;
 asm
       push ax
       mov ax,cx
       add cx,ax
       add cx,ax
       pop ax
       jmp REP_MOVSB_si
 end;

{ align=si / step=dword / overflow si=yes,di=no }
PROCEDURE REP_MOVS3_di;assembler;
 asm
       push ax
       mov ax,cx
       add cx,ax
       add cx,ax
       pop ax
       jmp REP_MOVSB_di
 end;

{ align=no / step=dword / overflow si=no,di=no }
PROCEDURE REP_MOVSD_na;assembler;
 asm
       db 66h;rep movsw
 end;

{ align=si / step=dword / overflow si=yes,di=no }
PROCEDURE REP_MOVSD_si;assembler;
 asm
       shl cx,2
       jmp REP_MOVSB_si
 end;

{ align=di / step=dword / overflow si=no,di=yes }
PROCEDURE REP_MOVSD_di;assembler;
 asm
       shl cx,2
       jmp REP_MOVSB_di
 end;

{ REP MOVSB pri nastavenem DF (si,di se pri presunu snizuji)}
{ provizorni / align=no / step=dword / overflow si=no,di=no}
PROCEDURE REP_MOVSB_back;assembler;
 asm
       shr cx,1;jnc @nomovsb;movsb;@nomovsb:jz @end;dec si;dec di
       shr cx,1;jnc @nomovsw;movsw;jz @end;@nomovsw:sub si,2;sub di,2
       db 66h;rep movsw
       @end:
 end;

{ REP (MOVSB;ADD SI,3) }
{ pouziti=kopirovani z packed bitmapy do unchained videopameti }
{ align=di / step=word / overflow si=yes,di=yes / meni ax,cx }
PROCEDURE REP_MOVSB_ADD_SI_3;assembler;
 asm
       cmp cx,20;jc @3
       test di,1
       jz @1
       movsb
       add si,3
       dec cx
       @1:
       push cx
       shr cx,4
       @2:
       mov al,[si   ];mov ah,[si+ 4];stosw{16x}
       mov al,[si+ 8];mov ah,[si+12];stosw
       mov al,[si+16];mov ah,[si+20];stosw
       mov al,[si+24];mov ah,[si+28];stosw
       mov al,[si+32];mov ah,[si+36];stosw
       mov al,[si+40];mov ah,[si+44];stosw
       mov al,[si+48];mov ah,[si+52];stosw
       mov al,[si+56];mov ah,[si+60];stosw
       add si,64
       loop @2
       pop cx
       and cx,15
       @3:
       shl cx,2
       neg cx
       add cx,offset @rep_done
       jmp cx
       movsb;add si,3;movsb;add si,3{20x}
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       movsb;add si,3;movsb;add si,3
       @rep_done:
 end;

{ REP (MOVSB;ADD DI,3) }
{ pouziti=kopirovani z unchained videopameti do packed bitmapy }
{ align=si / step=word / overflow si=yes,di=yes / meni ax,cx }
PROCEDURE REP_MOVSB_ADD_DI_3;assembler;
 asm
       cmp cx,20;jc @3
       test si,1
       jz @1
       movsb
       add di,3
       dec cx
       @1:
       push cx
       shr cx,4
       @2:
       lodsw;mov [es:di   ],al;mov [es:di+ 4],ah{16x}
       lodsw;mov [es:di+ 8],al;mov [es:di+12],ah
       lodsw;mov [es:di+16],al;mov [es:di+20],ah
       lodsw;mov [es:di+24],al;mov [es:di+28],ah
       lodsw;mov [es:di+32],al;mov [es:di+36],ah
       lodsw;mov [es:di+40],al;mov [es:di+44],ah
       lodsw;mov [es:di+48],al;mov [es:di+52],ah
       lodsw;mov [es:di+56],al;mov [es:di+60],ah
       add di,64
       loop @2
       pop cx
       and cx,15
       @3:
       shl cx,2
       neg cx
       add cx,offset @rep_done
       jmp cx
       movsb;add di,3;movsb;add di,3{20x}
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       movsb;add di,3;movsb;add di,3
       @rep_done:
 end;

{ REP (LODSB;if AL>0 then STOSB else INC DI) }
{ align=optional: pred volanim udelej TEST SI,1 nebo TEST DI,1 }
{ step=word / meni ax }
PROCEDURE REP_MOVS_1_nz_t;assembler;
 asm
      jz @5
      lodsb
      or al,al
      jz @3
      mov [es:di],al
      @3:
      inc di
      dec cx
      @5:
      shr cx,1
      jz @last
      PUSHF
   @1:
      lodsw
      or ax,ax
      jnz @2
 @nic:inc di
      inc di
      loop @1
      jmp @outro
      @2:
      or al,al
      jz @AH
      or ah,ah
      jz @AL
  @AX:stosw
      loop @1
      jmp @outro
  @AL:stosb
      inc di
      loop @1
      jmp @outro
  @AH:inc di
      mov al,ah
      stosb
      loop @1
  @outro:
      POPF
  @last:
      jnc @9
      lodsb
      or al,al
      jz @4
      stosb
      dec di
      @4:
      inc di
      @9:
 end;

{ step=byte / cx>0 / meni al
PROCEDURE REP_MOVS_1_nz_t;assembler;
 asm
      @1:
      lodsb
      or al,al
      jz @skip
      stosb
      loop @1
      ret
      @skip:
      inc di
      loop @1
 end;

{ step=word / cx>0 / meni ax }
PROCEDURE REP_MOVS_2_nz_t;assembler;
 asm
      @1:
      lodsw
      or ax,ax
      jz @skip
      stosw
      loop @1
      ret
      @skip:
      add di,2
      loop @1
 end;

{ step=tryte / cx>0 / meni ax
PROCEDURE REP_MOVS_3_nz_t;assembler;
 asm
      @1:
      lodsw
      or ax,ax
      jnz @copy
      cmp byte [si],0
      jnz @copy
      inc si
      add di,3
      loop @1
      ret
      @copy:
      stosw
      movsb
      loop @1
 end;

{ step=tryte / cx>0 / meni eax }
PROCEDURE REP_MOVS_3_nz_t;assembler;
 asm
      dec cx
      jz @last
     @notlast:
      db 66h;lodsw
      dec si
      db 66h;test ax,-1;dw 0ffh
      jz @skip
      stosw
      db 66h;shr ax,16
      stosb
      loop @notlast
      jmp @last
      @skip:
      add di,3
      loop @notlast
     @last:
      lodsw
      or ax,ax
      jnz @copy
      cmp byte [si],0
      jnz @copy
      inc si
      add di,3
      ret
      @copy:
      stosw
      movsb
 end;

{ step=dword / cx>0 / meni eax }
PROCEDURE REP_MOVS_4_nz_t;assembler;
 asm
      @1:
      db 66h;lodsw
      db 66h;or ax,ax
      jz @skip
      db 66h;stosw
      loop @1
      ret
      @skip:
      add di,4
      loop @1
 end;

{---------------------------------------------------------------------------
 CX pixelu z DS:SI namapuje do DX pixelu v ES:DI.
 _cislo v nazvu udava velikost pixelu v bajtech.
 _t v nazvu rika, ze se pixely 0 povazuji za pruhledne.
 _nz v nazvu znamena, ze CX ani DX nesmi byt 0.
 Pouziti: zoomovani textur.
 Meni EAX,BX,CX,DX,SI,DI.
 Pozn: nepocital jsem, jestli nedochazi u okraju k chybam, takze
  za 100% funkcnost nerucim. Ale tak nejak empiricky to funguje :)
 ---------------------------------------------------------------------------}
PROCEDURE ResizeCX2DX_1_nz;assembler;
 asm
      cmp cx,dx
      ja @smrskni   {cx>dx => smrskni}
      jz @nech      {cx=dx => nech}
      mov ax,cx
      add ax,ax
      cmp ax,dx
      jb @roztahni  {2*cx<dx => roztahni}

   @smrskni:{pouzitelne pro vse, vhodne pro dx<2*cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      dec dx
      xor bx,bx{bx=?}
      @3:
      movsb
      add bx,ax
      adc si,dx
      loop @3
      ret

   @nech:
      jmp REP_MOVSB_na

   @roztahni:{pouzitelne pro dx>cx, vhodne pro dx>2*cx}
      PUSH BP
      mov bp,cx
      mov bx,cx
      shr bx,1
      @1:
      sub bx,dx
      lodsb
      @2:
      stosb
      add bx,bp
      jnc @2
      loop @1
      POP BP
 end;

PROCEDURE ResizeCX2DX_2_nz;assembler;
 asm
      cmp dx,cx
      ja @roztahni  {cx<dx => smrskni}
      jz @nech      {cx=dx => nech}

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      dec dx
      add dx,dx
      xor bx,bx{bx=?}
      @3:
      movsw
      add bx,ax
      jnc @4
      add si,2
      @4:
      add si,dx
      loop @3
      ret

   @nech:
      jmp REP_MOVSW_na

   @roztahni:{pouzitelne pro dx>cx, vhodne pro dx>cx}
      PUSH BP
      mov bp,cx
      mov bx,cx
      shr bx,1
      @1:
      sub bx,dx
      lodsw
      @2:
      stosw
      add bx,bp
      jnc @2
      loop @1
      POP BP
 end;

PROCEDURE ResizeCX2DX_3_nz;assembler;
 asm
      cmp dx,cx
      ja @roztahni  {cx<dx => smrskni}
      jz @nech      {cx=dx => nech}

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      dec dx
      mov bx,dx;add dx,bx;add dx,bx
      xor bx,bx{bx=?}
      @3:
      movsw;movsb
      add bx,ax
      jnc @4
      add si,3
      @4:
      add si,dx
      loop @3
      ret

   @nech:
      jmp REP_MOVS3_na

   @roztahni:{pouzitelne pro dx>cx, vhodne pro dx>cx}
      PUSH BP
      mov bp,cx
      mov bx,cx
      shr bx,1
      @1:
      sub bx,dx
      lodsw;
      @2:
      stosw;movsb;dec si
      add bx,bp
      jnc @2
      inc si
      loop @1
      POP BP
 end;

PROCEDURE ResizeCX2DX_4_nz;assembler;
 asm
      cmp dx,cx
      ja @roztahni  {cx<dx => smrskni}
      jz @nech      {cx=dx => nech}

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      dec dx
      add dx,dx;add dx,dx
      xor bx,bx{bx=?}
      @3:
      db 66h;movsw
      add bx,ax
      jnc @4
      add si,4
      @4:
      add si,dx
      loop @3
      ret

   @nech:
      jmp REP_MOVSD_na

   @roztahni:{pouzitelne pro dx>cx, vhodne pro dx>cx}
      PUSH BP
      mov bp,cx
      mov bx,cx
      shr bx,1
      @1:
      sub bx,dx
      db 66h;lodsw
      @2:
      db 66h;stosw
      add bx,bp
      jnc @2
      loop @1
      POP BP
 end;

PROCEDURE ResizeCX2DX_1_nz_t;assembler;
 asm
      cmp cx,dx
      jz @nech

      PUSH BP
      jb @roztahni

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      dec dx
      xor bx,bx{bx=?}
      mov bp,ax
      jmp @5
      @3:
      add bx,bp
      adc si,dx
      @5:
      lodsb
      or al,al
      jz @4
      stosb
      loop @3
      jmp @end
      @4:
      inc di
      loop @3
      jmp @end

   @nech:
      jmp REP_MOVS_1_nz_t

   @roztahni:{pouzitelne a vhodne pro dx>cx}
      mov bp,cx
      mov bx,cx
      shr bx,1
     @1:
      sub bx,dx
      lodsb
      or al,al
      jz @0
     @2:
      stosb
      add bx,bp
      jnc @2
      loop @1
      jmp @end
     @0:
      inc di
      add bx,bp
      jnc @0
      loop @1

   @end:
      POP BP
 end;

PROCEDURE ResizeCX2DX_2_nz_t;assembler;
 asm
      cmp cx,dx
      jz @nech

      PUSH BP
      jb @roztahni

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      add dx,dx
      xor bx,bx{bx=?}
      mov bp,ax
      jmp @5
      @3:
      add bx,bp
      jc @5
      sub si,2
      @5:
      add si,dx
      lodsw
      or ax,ax
      jz @4
      stosw
      loop @3
      jmp @end
      @4:
      add di,2
      loop @3
      jmp @end

   @nech:
      jmp REP_MOVS_2_nz_t

   @roztahni:{pouzitelne a vhodne pro dx>cx}
      mov bp,cx
      mov bx,cx
      shr bx,1
     @1:
      sub bx,dx
      lodsw
      or ax,ax
      jz @0
     @2:
      stosw
      add bx,bp
      jnc @2
      loop @1
      jmp @end
     @0:
      add di,2
      add bx,bp
      jnc @0
      loop @1

   @end:
      POP BP
 end;

PROCEDURE ResizeCX2DX_3_nz_t;assembler;
 asm
      cmp cx,dx
      jz @nech

      PUSH BP
      jb @roztahni

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      mov bx,dx;add dx,bx;add dx,bx
      xor bx,bx{bx=?}
      mov bp,ax
      jmp @5
      @3:
      add bx,bp
      jc @5
      sub si,3
      @5:
      add si,dx
      lodsw
      or ax,ax
      jnz @6
      cmp byte [si],0
      jz @4
      @6:
      stosw
      movsb
      loop @3
      jmp @end
      @4:
      inc si
      add di,3
      loop @3
      jmp @end

   @nech:
      jmp REP_MOVS_3_nz_t

   @roztahni:{pouzitelne a vhodne pro dx>cx}
      mov bp,cx
      mov bx,cx
      shr bx,1
     @1:
      sub bx,dx
      lodsw
      or ax,ax
      jnz @2
      cmp byte [si],0
      jz @0
     @2:
      stosw
      movsb
      dec si
      add bx,bp
      jnc @2
      inc si
      loop @1
      jmp @end
     @0:
      add di,3
      add bx,bp
      jnc @0
      inc si
      loop @1

   @end:
      POP BP
 end;

PROCEDURE ResizeCX2DX_4_nz_t;assembler;
 asm
      cmp cx,dx
      jz @nech

      PUSH BP
      jb @roztahni

   @smrskni:{pouzitelne pro vse, vhodne pro dx<cx}
      xchg ax,cx
      mov cx,dx
      xor dx,dx
      div cx
      PUSH AX
      xor ax,ax
      div cx
      POP DX
      add dx,dx;add dx,dx
      xor bx,bx{bx=?}
      mov bp,ax
      jmp @5
      @3:
      add bx,bp
      jc @5
      sub si,4
      @5:
      add si,dx
      db 66h;lodsw
      db 66h;or ax,ax
      jz @4
      db 66h;stosw
      loop @3
      jmp @end
      @4:
      add di,4
      loop @3
      jmp @end

   @nech:
      jmp REP_MOVS_4_nz_t

   @roztahni:{pouzitelne a vhodne pro dx>cx}
      mov bp,cx
      mov bx,cx
      shr bx,1
     @1:
      sub bx,dx
      db 66h;lodsw
      db 66h;or ax,ax
      jz @0
     @2:
      db 66h;stosw
      add bx,bp
      jnc @2
      loop @1
      jmp @end
     @0:
      add di,4
      add bx,bp
      jnc @0
      loop @1

   @end:
      POP BP
 end;

{---------------------------------------------------------------------------
 Bajt z AH rozepise po bitech do [ES:DI] az [ES:DI+7].
 Nastavene bity barvou AL, prazdne bity nemeni.
 Po skonceni je DI o 8 vyssi.
 ---------------------------------------------------------------------------}
PROCEDURE ExpandAH_AL;assembler;
 asm
     add ah,ah;jnc @skipbit7;mov [es:di],al;@skipbit7:inc di
     add ah,ah;jnc @skipbit6;mov [es:di],al;@skipbit6:inc di
     add ah,ah;jnc @skipbit5;mov [es:di],al;@skipbit5:inc di
     add ah,ah;jnc @skipbit4;mov [es:di],al;@skipbit4:inc di
     add ah,ah;jnc @skipbit3;mov [es:di],al;@skipbit3:inc di
     add ah,ah;jnc @skipbit2;mov [es:di],al;@skipbit2:inc di
     add ah,ah;jnc @skipbit1;stosb;jnz @last;inc di;ret;@skipbit1:jz @end;inc di
     @last:stosb;ret
     @end:inc di;inc di
 end;

{---------------------------------------------------------------------------
 Bajt z DH rozepise po bitech do pole na [ES:DI].
 Nastavene bity barvou AL (resp. AX, DL&AX, EAX), prazdne bity nemeni.
 DI zvysi o velikost pole.
 ---------------------------------------------------------------------------}
PROCEDURE ExpandCH_AL;assembler;
 const size=1;
 asm
     test ch,ch;je @end
     test ch,80h;jz @0;mov [es:di+0*size],al;@0:
     test ch,40h;jz @1;mov [es:di+1*size],al;@1:
     test ch,20h;jz @2;mov [es:di+2*size],al;@2:
     test ch,10h;jz @3;mov [es:di+3*size],al;@3:
     test ch,08h;jz @4;mov [es:di+4*size],al;@4:
     test ch,04h;jz @5;mov [es:di+5*size],al;@5:
     test ch,02h;jz @6;mov [es:di+6*size],al;@6:
     test ch,01h;jz @7;mov [es:di+7*size],al;@7:
     @end:add di,8*size
 end;
PROCEDURE ExpandCH_AX;assembler;
 const size=2;
 asm
     test ch,ch;je @end
     test ch,80h;jz @0;mov [es:di+0*size],ax;@0:
     test ch,40h;jz @1;mov [es:di+1*size],ax;@1:
     test ch,20h;jz @2;mov [es:di+2*size],ax;@2:
     test ch,10h;jz @3;mov [es:di+3*size],ax;@3:
     test ch,08h;jz @4;mov [es:di+4*size],ax;@4:
     test ch,04h;jz @5;mov [es:di+5*size],ax;@5:
     test ch,02h;jz @6;mov [es:di+6*size],ax;@6:
     test ch,01h;jz @7;mov [es:di+7*size],ax;@7:
     @end:add di,8*size
 end;
PROCEDURE ExpandCH_EAX;assembler;
 const size=4;
 asm
     test ch,ch;je @end
     test ch,80h;jz @0;db 66h;mov [es:di+0*size],ax;@0:
     test ch,40h;jz @1;db 66h;mov [es:di+1*size],ax;@1:
     test ch,20h;jz @2;db 66h;mov [es:di+2*size],ax;@2:
     test ch,10h;jz @3;db 66h;mov [es:di+3*size],ax;@3:
     test ch,08h;jz @4;db 66h;mov [es:di+4*size],ax;@4:
     test ch,04h;jz @5;db 66h;mov [es:di+5*size],ax;@5:
     test ch,02h;jz @6;db 66h;mov [es:di+6*size],ax;@6:
     test ch,01h;jz @7;db 66h;mov [es:di+7*size],ax;@7:
     @end:add di,8*size
 end;
PROCEDURE ExpandCH_CLAX;assembler;
 const size=3;
 asm
     test ch,ch;je @end
     test ch,80h;jz @0;mov [es:di+0*size],ax;mov [es:di+0*size+2],cl;@0:
     test ch,40h;jz @1;mov [es:di+1*size],ax;mov [es:di+1*size+2],cl;@1:
     test ch,20h;jz @2;mov [es:di+2*size],ax;mov [es:di+2*size+2],cl;@2:
     test ch,10h;jz @3;mov [es:di+3*size],ax;mov [es:di+3*size+2],cl;@3:
     test ch,08h;jz @4;mov [es:di+4*size],ax;mov [es:di+4*size+2],cl;@4:
     test ch,04h;jz @5;mov [es:di+5*size],ax;mov [es:di+5*size+2],cl;@5:
     test ch,02h;jz @6;mov [es:di+6*size],ax;mov [es:di+6*size+2],cl;@6:
     test ch,01h;jz @7;mov [es:di+7*size],ax;mov [es:di+7*size+2],cl;@7:
     @end:add di,8*size
 end;

{---------------------------------------------------------------------------
 Bajt z AH rozepise po bitech do [ES:DI] az [ES:DI+7].
 Nastavene bity barvou BL, prazdne barvou BH.
 Po skonceni je DI o 8 vyssi.
 Meni AL,CX.
 ---------------------------------------------------------------------------}
PROCEDURE ExpandAH_BX;assembler;
 asm
     mov cx,9{pozor: obcas calluju ExpandAH_BX+3 tak nemenit prvni instrukci}
     add ah,ah
     jc @kreslit

    @mazat:
     dec cx
     jz @end
     mov al,bh
    @mazat_loop:
     stosb
     add ah,ah
     jc @kreslit
     loop @mazat_loop
     ret

    @kreslit:
     dec cx
     jz @end
     mov al,bl
    @kreslit_loop:
     stosb
     add ah,ah
     jnc @mazat
     loop @kreslit_loop

    @end:
 end;

{---------------------------------------------------------------------------
 Rychlejsi nahrada Move.
 Porovna jestli je cil na nizsi nebo vyssi adrese a podle toho se rozhodne
 jestli kopirovat od prvniho nebo od posledniho bajtu.
 Ale pozor, v ramci optimalizace nema segmentovou aritmetiku,
 pokud se segmenty zdroje a cile lisi, predpoklada ze se zdroj a cil
 neprekryvaji. Kdyby se prekryvaly (znacne nepravdepodobne), muze
 znicit presouvana data.
 ---------------------------------------------------------------------------}
PROCEDURE Move(var src,dest;bytes:word);assembler;
 asm
     mov cx,bytes;jcxz @end{nic kdyz se ma presunout 0 bajtu dlouhej kus}
     PUSH DS
     lds si,src
     les di,dest
     mov ax,ds;mov bx,es;cmp ax,bx;jnz @normalne
     cmp si,di;jz @done
     jb @pozpatku
    @normalne:
     call REP_MOVSB_di
     jmp @done
    @pozpatku:
     add si,cx;dec si
     add di,cx;dec di
     std
     call REP_MOVSB_back
     cld
    @done:
     POP DS
     @end:
 end;

{---------------------------------------------------------------------------
 Zcela neoptimalizovane ale moc uzitecne.
 Vymeni dva bloky.
 ---------------------------------------------------------------------------}
PROCEDURE Xchg(var a,b;bytes:word);assembler;
 asm
     PUSH DS
     lds si,a
     les di,b
     mov cx,bytes
     @1:
     mov al,[es:di]
     xchg al,[si]
     stosb
     inc si
     loop @1
     POP DS
 end;

{---------------------------------------------------------------------------
 Vymeni dve promenne zadaneho typu.
 ---------------------------------------------------------------------------}
PROCEDURE XchgB(var a,b:byte);assembler;
asm
 push ds
 les  di,a
 lds  si,b
 mov  al,[si]
 xchg al,[es:di]
 mov  [si],al
 pop  ds
end;

PROCEDURE XchgS(var a,b:shortint);assembler;
asm
 push ds
 les  di,a
 lds  si,b
 mov  al,[si]
 xchg al,[es:di]
 mov  [si],al
 pop  ds
end;

PROCEDURE XchgW(var a,b:word);assembler;
asm
 push ds
 les  di,a
 lds  si,b
 mov  ax,[si]
 xchg ax,[es:di]
 mov  [si],ax
 pop  ds
end;

PROCEDURE XchgI(var a,b:integer);assembler;
asm
 push ds
 les  di,a
 lds  si,b
 mov  ax,[si]
 xchg ax,[es:di]
 mov  [si],ax
 pop  ds
end;

PROCEDURE XchgL(var a,b:longint);assembler;
asm
 push ds
 les  di,a
 lds  si,b
 db 66h;mov ax,[si]
 db 66h;xchg ax,[es:di]
 db 66h;mov [si],ax
 pop ds
end;

{---------------------------------------------------------------------
 Vyplni blok zadanym bajtem. Pri preteceni segmentu se vrati na zacatek
 tehoz segmentu, tedy nelze vyplnit vice nez 64K.
 ---------------------------------------------------------------------}
PROCEDURE FillByte(blok:pointer;bytes:longint;value:byte);assembler;
 asm
      les di,blok
      mov al,value
      mov cx,word ptr bytes

      {osetreni delky nad 65535}
      mov bx,word ptr bytes+2
      cmp bx,0
      jz @doit
      test bx,8000h
      jnz @done{zaporny pocet}
      stosb
      mov cx,65535
      @doit:

      call REP_STOSB
      @done:
 end;

{---------------------------------------------------------------------
 Vyplni blok zadanym wordem. Pri preteceni segmentu se vrati na zacatek
 tehoz segmentu, tedy nelze vyplnit vice nez 64K.
 ---------------------------------------------------------------------}
PROCEDURE FillWord(blok:pointer;words:longint;value:word);assembler;
 asm
      les di,blok
      mov ax,value
      mov cx,word ptr words

      {osetreni bloku nad 65535 bajtu}
      cmp cx,32768
      jnb @full
      mov bx,word ptr words+2
      cmp bx,0
      jz @doit
      test bx,8000h
      jnz @done{zaporny pocet}
      @full:
      mov cx,32768
      @doit:

      call REP_STOSW_o
      @done:
 end;



{---------------------------------------------------------------------
 Maji dva bloky delky max 65535 bajtu shodny obsah ?
 ---------------------------------------------------------------------}
FUNCTION  CmpBlock(blok1,blok2:pointer;bytes:word):boolean;assembler;
 asm
      push ds
      lds si,blok1
      les di,blok2
      mov cx,bytes
      repe cmpsb
      mov al,1
      jz @same
      mov al,0
      @same:
      pop ds
 end;

{---------------------------------------------------------------------
 Je blok delky max 65535 bajtu vyplnen zadanym bajtem ?
 ---------------------------------------------------------------------}
FUNCTION  CmpByte(blok:pointer;val:byte;bytes:word):boolean;assembler;
 asm
      push ds
      les di,blok
      mov al,val
      mov cx,bytes
      repe scasb
      mov al,1
      jz @same
      mov al,0
      @same:
      pop ds
 end;

{---------------------------------------------------------------------
 Je blok delky max 32768 wordu vyplnen zadanym wordem ?
 ---------------------------------------------------------------------}
FUNCTION  CmpWord(blok:pointer;val:word;words:word):boolean;assembler;
 asm
      push ds
      les di,blok
      mov ax,val
      mov cx,words
      repe scasw
      mov al,1
      jz @same
      mov al,0
      @same:
      pop ds
 end;


constructor TPtr.Init(ap:pointer);         begin p        :=ap;end;
function    TPtr.Plus(l:longint):pointer;  begin inc(l,PtrRec(p).Ofs);
                                                 Plus     :=Ptr(PtrRec(p).Seg+SelectorInc*HiInt(l),LoWord(l));end;
procedure   TPtr.Add(l:longint);           begin p        :=Plus(l);end;
function    TPtr.GetByte:byte;             begin GetByte  :=PByte(p)^;end;
function    TPtr.ReadByte:byte;            begin ReadByte :=PByte(p)^;Add(1);end;
function    TPtr.GetShort:shortint;        begin GetShort :=PShort(p)^;end;
function    TPtr.ReadShort:shortint;       begin ReadShort:=PShort(p)^;Add(1);end;
function    TPtr.GetChar:char;             begin GetChar  :=PChar(p)^;end;
function    TPtr.ReadChar:char;            begin ReadChar :=PChar(p)^;Add(1);end;
function    TPtr.GetWord:word;             begin GetWord  :=MakeWord(PByte(Plus(1))^,GetByte);end;
function    TPtr.ReadWord:word;            begin ReadWord :=GetWord;Add(2);end;
function    TPtr.GetInt:integer;           begin GetInt   :=integer(GetWord);end;
function    TPtr.ReadInt:integer;          begin ReadInt  :=integer(ReadWord);end;
function    TPtr.GetLong:longint;          begin GetLong  :=ReadLong;Add(-4);end;
function    TPtr.ReadLong:longint;         begin ReadLong :=ReadInt*65536+ReadWord;end;
function    TPtr.CmpStr(st:string):boolean;begin for st[0]:=st[0] downto #1 do if st[length(st)]<>PChar(Plus(length(st)-1))^
                                                  then begin CmpStr:=false;exit;end;CmpStr:=true;end;
procedure   TPtr.GotoStr(st:string);       begin while not CmpStr(st) do Add(1);end;
procedure   TPtr.GotoEop;                  begin while PByte(p)^<>0 do Add(1);end;
procedure   TPtr.GotoEos;                  begin Add(PByte(p)^+1);end;
procedure   TPtr.AlignDown(a:word);        begin word(p):=word(p) div a*a;end;
procedure   TPtr.AlignUp(a:word);          begin word(p):=(word(p)+a-1) div a*a;end;


PROCEDURE KillObj(var obj);
var pp:PObject absolute obj;
begin
 if pp<>nil then begin
   Dispose(pp,Done);
   pp:=nil;
   end;
end;



{ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ TPLAYER ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ}

Constructor TPlayer.Init(astream:PStream);
begin
 inherited Init;
 stream:=astream;
 if (stream<>nil) and (stream^.Status<>stOK) then KillObj(stream);
 if stream=nil then Fail;
end;

Function TPlayer.Sync:boolean;
begin
end;

Destructor TPlayer.Done;
begin
 KillObj(stream);
 inherited Done;
end;

Procedure TPlaylist.Sync;
var   i:integer;
begin
 i:=0;
 while i<count do
  if PPlayer(items^[i])^.Sync then AtFree(i) else inc(i);
end;



function fakeMakeRoom:boolean;far;
begin
 fakeMakeRoom:=false;
end;


{∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞INIT/DONE∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞∞}

const unita='memo';
var result:TError;
    oldmem:longint;

procedure UserInit;
 begin
  oldmem:=memavail;
  MakeRoom:=fakeMakeRoom;
  {$ifdef beta}
  minavail:=MemAvail;
  InitBlox;
  {$endif}
  if not GetMem(freeptr,freesize) then result:=erLowMem else begin
    {$ifdef nt}
    dosBlocks:=0;
    New(dosBlock);
    if dosBlock=nil then result:=erLowMem else
    {$endif}
      begin
      if not GetMemDos(dosfreeSeg,pointer(dosfree),1024) then result:=erLowDosMem else
        exit;
      {$ifdef nt}
      Dispose(dosBlock);
      {$endif}
      end;
    FreeMem(freeptr,freesize);
    end;
  {$ifdef beta}
  DoneBlox;
  {$endif}
 end;

procedure UserDone;
 var i,used:word;
 begin
  FreeMemDos(pointer(dosfree),1024);
  {$ifdef nt}
  {$ifdef beta}
  used:=0;
  for i:=1 to dosBlocks do if dosBlock^[i].used then inc(used);
  if used>0 then BiosWriteln(stri(used)+'/'+stri(dosBlocks)+' '+_(_msgBlokuNeuvolneno));
  {$endif}
  Dispose(dosBlock);
  {$endif}
  FreeMem(freeptr,freesize);
  {$ifdef beta}
  DoneBlox;
  {$endif}
  if debug then begin
    BiosWriteln('Total mem='+stri(oldmem shr 10)+'K');
    BiosWriteln('Lost mem='+stri(oldmem-memo.memavail));
    end;
 end;

{$i initdone.inc}
{$ifdef autoinit}
BEGIN
 erCheck(Init);
{$endif}
END.